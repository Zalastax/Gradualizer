-module(test).

-include_lib("eunit/include/eunit.hrl").

should_pass_test_() ->
    %% user_types.erl references remote_types.erl
    %% it is not in the sourcemap of the DB so let's import it manually
    gradualizer_db:import_erl_files(["test/should_pass/user_types.erl"]),
    map_erl_files(fun(File) ->
            ?_assertEqual(ok, gradualizer:type_check_file(File))
        end, "test/should_pass").

should_fail_test_() ->
    map_erl_files(fun(File) ->
            ?_assertEqual(nok, gradualizer:type_check_file(File))
        end, "test/should_fail").

% Test succeeds if Gradualizer crashes or if it doesn't type check.
% Doing so makes the test suite notify us whenever a known problem is resolved.
known_problem_should_pass_test_() ->
    map_erl_files(fun(File) ->
        Result =
            try gradualizer:type_check_file(File) of
                V -> V
            catch _:_ -> nok
            end,
        ?_assertEqual(nok, Result)
        end, "test/known_problems/should_pass").

% Test succeeds if Gradualizer crashes or if it does type check.
% Doing so makes the test suite notify us whenever a known problem is resolved.
known_problem_should_fail_test_() ->
    map_erl_files(fun(File) ->
        Result =
            try gradualizer:type_check_file(File) of
                V -> V
            catch _:_ -> ok
            end,
        ?_assertEqual(ok, Result)
        end, "test/known_problems/should_fail").

map_erl_files(Fun, Dir) ->
    Files = filelib:wildcard(filename:join(Dir, "*.erl")),
    lists:map(Fun, Files).
