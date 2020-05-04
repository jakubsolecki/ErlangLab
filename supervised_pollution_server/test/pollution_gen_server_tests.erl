%%%-------------------------------------------------------------------
%%% @author jakubs
%%% @copyright (C) 2020, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 04. maj 2020 16:05
%%%-------------------------------------------------------------------
-module(pollution_gen_server_tests).
-author("jakubs").

-include_lib("eunit/include/eunit.hrl").

start_test() ->
  pollution_gen_server:start_link(),
  ?assert(lists:member(pollution_gen_server, registered())).

addStation_test() ->
  ?assertEqual(ok, pollution_gen_server:addStation("Station 1", {1,1})),
  ?assertEqual(ok, pollution_gen_server:addStation("Station 3", {2,2})),
  ?assertEqual(ok, pollution_gen_server:addStation("Station 1", {2,2})),
  ?assertEqual(ok, pollution_gen_server:addStation("Station 2", {1,1})).

addValues_test() ->
  ?assertEqual(ok, pollution_gen_server:addValues({1,1}, calendar:local_time(), "temp", 15)),
  ?assertEqual(ok, pollution_gen_server:addValues({1,1}, calendar:local_time(), "temp", 15)),
  ?assertEqual(ok, pollution_gen_server:addValues({"Station 2"}, calendar:local_time(), "PM 2.5", 100)),
  ?assertEqual(ok, pollution_gen_server:addValues("Station 3", calendar:local_time(), "temp", 25)).

getOneValue_test() ->
  {{Y, M, D}, {H, _, _}} = calendar:local_time(),
  ?assertEqual(15, pollution_gen_server:getOneValue("Station 1", {{Y, M, D}, H}, "temp")),
  ?assertEqual(15, pollution_gen_server:getOneValue({1, 1}, {{Y, M, D}, H}, "temp")),
  ?assertMatch({error, _}, pollution_gen_server:getOneValue("Station 1", {{Y, M, D}, H}, "PM 10")),
  ?assertMatch({error, _}, pollution_gen_server:getOneValue("Station 2", {{Y, M, D}, H}, "temp")),
  ?assertMatch({error, _}, pollution_gen_server:getOneValue("Station 3", {{Y, M, D}, H}, "PM 2.5")).

getStationMean_test() ->
  ?assertEqual(15.0, pollution_gen_server:getStationMean({1, 1}, "temp")),
  ?assertEqual(15.0, pollution_gen_server:getStationMean("Station 1", "temp")),
  ?assertMatch({error, _}, pollution_gen_server:getStationMean({1, 1}, "PM 10")),
  ?assertMatch({error, _}, pollution_gen_server:getStationMean({2, 2}, "tmp")),
  ?assertMatch({error, _}, pollution_gen_server:getStationMean("Platform 9 i 3/4", "PM 10")).

getDailyMean_test() ->
  {{Y, M, D}, _} = calendar:local_time(),
  ?assertEqual(20.0, pollution_gen_server:getDailyMean({Y, M, D}, "temp")),
  ?assertMatch({error, _}, pollution_gen_server:getDailyMean({Y, M, D}, "PM 10")).

getHourlyMean_test() ->
  {_, {H, _, _}} = calendar:local_time(),
  ?assertEqual(25.0, pollution_gen_server:getHourlyMean("Station 3", H, "temp")),
  ?assertEqual(25.0, pollution_gen_server:getHourlyMean({2, 2}, H, "temp")),
  ?assertMatch({error, _}, pollution_gen_server:getHourlyMean("Station 2", H, "temp")),
  ?assertMatch({error, _}, pollution_gen_server:getHourlyMean("Station 1", H, "PM 2.5")).

getSeasonalMean_test() ->
  ?assertEqual(15.0, pollution_gen_server:getSeasonalMean("Station 1", {2020, 1}, {2021, 1}, "temp")),
  ?assertEqual(25.0, pollution_gen_server:getSeasonalMean({2, 2}, {2020, 1}, {2021, 1}, "temp")),
  ?assertMatch({error, _}, pollution_gen_server:getSeasonalMean("Station 1", {2020, 1}, {2021, 1}, "PM 10")),
  ?assertMatch({error, _}, pollution_gen_server:getSeasonalMean({1, 2}, {2002, 1}, {2019, 1}, "temp")).

removeValue_test() ->
  {{Y, M, D}, {H, _, _}} = calendar:local_time(),
  ?assertEqual(ok, pollution_gen_server:removeValue("Station 1", {{Y, M, D}, H}, "temp")),
  ?assertEqual(ok, pollution_gen_server:removeValue("Station 1", {{Y, M, D}, H}, "temp")),
  ?assertEqual(ok, pollution_gen_server:removeValue("Platform 9 i 3/4", {{Y, M, D}, H}, "PM 2.5")).

crash_test() ->
  pollution_gen_server:crash(),
  timer:sleep(50),
  ?assert(lists:member(pollution_gen_server, registered())).

stop_test() ->
  ?assertEqual(ok, pollution_gen_server:stop()),
  timer:sleep(50),
  ?assert(not lists:member(pollution_gen_server, registered())).