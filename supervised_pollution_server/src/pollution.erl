%%%-------------------------------------------------------------------
%%% @author Jakub Solecki
%%% @copyright (C) 2020, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 27. mar 2020 18:53
%%%-------------------------------------------------------------------
-module(pollution).
-author("Jakub Solecki").

%% Modifying data
-export([createMonitor/0, addStation/3, addValues/5, removeValue/4]).
%% Obtaining statistics
-export([getOneValue/4, getStationMean/3, getDailyMean/3, getHourlyMean/4, getSeasonalMean/5]).


%% Creates list containing stations and readings
createMonitor() -> [maps:new(), dict:new()].


%% Register station (doubled, in order to simplify search operations. At least for me to code them)
addStation(Name, {Long, Lat}, [Stations, Readings]) ->
  case {maps:find(Name, Stations), maps:find({Long, Lat}, Stations)} of
    {error, error} ->
      [maps:put(Name, {Name, {Long, Lat}}, maps:put({Long, Lat}, {Name, {Long, Lat}}, Stations)), Readings];
    _ -> {error, station_exists}
  end.


%% Add reading (from one of the registered stations)
addValues(Station, {{Year, Month, Day}, {Hour, _, _}}, Type, Value, [Stations, Readings]) ->
  case maps:find(Station, Stations) of
    error -> {error, station_does_not_exist};
    {ok, StationKey} ->
      case dict:is_key(StationKey, Readings) of
        true ->
          addNewValue(StationKey, {{Year, Month, Day}, Hour}, Type, Value,
            dict:fetch(StationKey, Readings), [Stations, Readings]);
        false ->
          [Stations, dict:append(StationKey, {{{Year, Month, Day}, Hour}, Type, Value}, Readings)]
      end
  end.

addNewValue(StationKey, {{Year, Month, Day}, Hour}, Type, Value, List, [Stations, Readings]) ->
  case [{Y, M, D, H, T, V} || {{{Y, M, D}, H}, T, V} <- List,
    {Y, M, D, H, T} == {Year, Month, Day, Hour, Type}] of
    [] -> [Stations, dict:append(StationKey, {{{Year, Month, Day}, Hour}, Type, Value}, Readings)];
    _ -> {error, reading_exists}
  end.


%% Remove reading (from one of the registered stations)
removeValue(Station, {{Year, Month, Day}, Hour}, Type, [Stations, Readings]) ->
  Fun = fun(Val) ->
    [{{{Y, M, D}, H}, T, V} || {{{Y, M, D}, H}, T, V} <- Val,
      {Y, M, D, H, T} /= {Year, Month, Day, Hour, Type}]
        end,
  case maps:find(Station, Stations) of
    error -> {error, station_does_not_exist};
    {ok, StationKey} ->
      case dict:is_key(StationKey, Readings) of
        true ->
          %% Could have been done without returning an error, but I like to know what's going on
          Len = fun(X) -> lists:foldl(fun(_, Acc) -> Acc + 1 end, 0, X) end,
          NewReadings = dict:update(StationKey, Fun, Readings),
          {_, R1} = dict:find(StationKey, Readings),
          {_, R2} = dict:find(StationKey, NewReadings),
          case Len(R1) == Len(R2) of
            false -> [Stations, NewReadings];
            true -> {error, reading_not_found}
          end;
        false -> {error, station_is_empty}
      end
  end.


%% Return value of reading containing provided: type, station and date.
getOneValue(Station, {{Year, Month, Day}, Hour}, Type, [Stations, Readings]) ->
  case maps:find(Station, Stations) of
    error -> {error, station_does_not_exist};
    {ok, StationKey} ->
      case dict:is_key(StationKey, Readings) of
        false -> {error, station_is_empty};
        true ->
          case [{{{Y, Mon, D}, H}, T, V} || {{{Y, Mon, D}, H}, T, V} <- dict:fetch(StationKey, Readings),
            {Y, Mon, D, H, T} == {Year, Month, Day, Hour, Type}] of
            [{_, _, Result}] -> Result;
            [] -> {error, reading_not_found}
          end
      end
  end.


%% Functions calculates mean of values of specified type, from given station (all its readings in history).
getStationMean(Station, Type, [Stations, Readings]) ->
  case maps:find(Station, Stations) of
    error -> {error, station_does_not_exist};
    {ok, StationKey} ->
      case dict:is_key(StationKey, Readings) of
        false -> {error, station_is_empty};
        true ->
          case [V || {_, T, V} <- dict:fetch(StationKey, Readings), T == Type] of
            [] -> {error, no_readings};
            List ->
              {Sum, Count} = count(List),
              Sum/Count
          end
      end
  end.


%% Calculate length of a list and sum of all its values.
count(List) ->
  Fun = fun(X, {Sum, Count}) -> {Sum + X, Count + 1} end,
  lists:foldl(Fun, {0, 0}, List).


%% Calculate daily mean of specified type value for all stations.
getDailyMean({Year, Month, Day}, Type, [_, Readings]) ->
  Fun = fun(_, ListOfVals, {Sum, Count}) ->
    {S, C} = count([V || {{{Y, M, D}, _}, T, V} <- ListOfVals, {Y, M, D, T} == {Year, Month, Day, Type}]),
    {Sum + S, Count + C}
        end,
  {Sres, Cres} = dict:fold(Fun, {0, 0}, Readings),
  case {Sres, Cres} == {0, 0} of
    true -> {error, no_readings};
    false -> Sres/Cres
  end.


%% Returns mean of all values of specified types on given station at provided hour.
getHourlyMean(Station, Hour, Type, [Stations, Readings]) ->
  case maps:find(Station, Stations) of
    error -> {error, station_does_not_exist};
    {ok, StationKey} ->
      case dict:is_key(StationKey, Readings) of
        false -> {error, station_is_empty};
        true ->
          case [V || {{_, H}, T, V} <- dict:fetch(StationKey, Readings), {T, H} == {Type, Hour}] of
            [] -> {error, no_readings};
            List ->
              {Sum, Count} = count(List),
              Sum/Count
          end
      end
  end.


%% Returns mean of values of specified type from given time interval.
getSeasonalMean(Station, {StartYear, StartMonth}, {EndYear, EndMonth}, Type, [Stations, Readings]) ->
  case maps:find(Station, Stations) of
    error -> {error, station_does_not_exist};
    {ok, StationKey} ->
      case dict:is_key(StationKey, Readings) of
        false -> {error, station_is_empty};
        true ->
          case [V || {{{Y, M, _}, _}, T, V} <- dict:fetch(StationKey, Readings),
            Y >= StartYear, M >= StartMonth, {Y ,M} =< {EndYear, EndMonth}, T == Type] of
            [] -> {error, no_readings};
            List ->
              {Sum, Count} = count(List),
              Sum/Count
          end
      end
  end.
