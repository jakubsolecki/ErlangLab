%%%-------------------------------------------------------------------
%%% @author Jakub Solecki
%%% @copyright (C) 2020, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 04. kwi 2020 13:36
%%%-------------------------------------------------------------------
-module(parcellockerfinder).
-author("Jakub Solecki").

%% API
-export([findMyParcelLocker/2, findMyParcelLocker/3, randomElems/3, start/3, server/3, timeMeasure/0,  len/1]).


randomElems(N, Min, Max) -> [{rand:uniform(Max - Min + 1) + Min - 1, rand:uniform(Max - Min + 1) + Min - 1}  ||
  _ <- lists:seq(1,  N)].


%% Standard approach

%% Call order
%% Lockers = parcellockerfinder:randomElems(1000, 0, 10000).
%% Customers = parcellockerfinder:randomElems(10000, 0, 10000).
%% Fun = fun(P) -> parcellockerfinder:findMyParcelLocker(P, Lockers) end.
%% Result = lists:map(Fun, Customers).

findMyParcelLocker(PersonLocation, LockerLocations) ->
  Distances = [{{X, Y}, math:sqrt(math:pow(element(1, PersonLocation) - X, 2) +
    math:pow(element(2, PersonLocation) - Y, 2))} || {X, Y} <- LockerLocations],
  Fun =
    fun(A, B) ->
      element(2, A) =< element(2, B)
    end,
  {PersonLocation, element(1, lists:nth(1, lists:sort(Fun, Distances)))}.



%% Using separate process for each person

%% Call order
%% Lockers = parcellockerfinder:randomElems(1000, 0, 10000).
%% Customers = parcellockerfinder:randomElems(10000, 0, 10000).
%% parcellockerfinder:start(Customers, Lockers, parcellockerfinder:len(Customers)).

findMyParcelLocker(PPID, PersonLocation, LockerLocations) ->
  Distances = [{{X, Y}, math:sqrt(math:pow(element(1, PersonLocation) - X, 2) +
    math:pow(element(2, PersonLocation) - Y, 2))} || {X, Y} <- LockerLocations],
  Fun =
    fun(A, B) ->
      element(2, A) =< element(2, B)
    end,
  PPID ! {PersonLocation, element(1, lists:nth(1, lists:sort(Fun, Distances)))}.

start(PeopleLocations, LockerLocations, End) ->
  MPID = spawn(parcellockerfinder, timeMeasure, []),
  register(myTimer, MPID),
  myTimer ! {t1, erlang:timestamp()},
  PPID = spawn(parcellockerfinder, server, [1, End, []]),
  spawn(fun() -> loop(PPID, PeopleLocations, LockerLocations) end).

server(Count, End, List) ->
  receive
    stop -> io:format("~w ~w~n", [len(List), List]);
    Res ->
      case Count == End of
        false -> server(Count+1, End, [Res | List]);
        true ->
          io:format("~w ~w~n", [Count, List]),
          myTimer ! {t2, erlang:timestamp()}
      end
  end.

loop(_, [], _) -> ok;
loop(PPID, [H | PeopleLocations], LockerLocations) ->
  spawn(fun() -> findMyParcelLocker(PPID, H, LockerLocations) end),
  loop(PPID, PeopleLocations, LockerLocations).

len(List) -> len(List, 0).
len([], N) -> N;
len([_ | Rest], N) -> len(Rest, N+1).

timeMeasure() ->
  receive
    {t1, T} -> Time1 = T, timeMeasure(Time1)
  end.
timeMeasure(Time1) ->
  receive
    {t2, T} -> io:format("~w~n", [timer:now_diff(T, Time1)])
  end.
