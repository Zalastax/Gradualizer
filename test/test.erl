-module(test).

-include_lib("eunit/include/eunit.hrl").

should_pass_test_() ->
    %% user_types.erl references remote_types.erl
    %% it is not in the sourcemap of the DB so let's import it manually
    gradualizer_db:import_erl_files(["test/should_pass/user_types.erl"]),
    %% imported.erl references any.erl
    gradualizer_db:import_erl_files(["test/should_pass/any.erl"]),
    map_erl_files(fun(File) ->
            {filename:basename(File), [?_assertMatch({ok, _}, {gradualizer:type_check_file(File), File})]}
        end, "test/should_pass").

should_fail_test_() ->
    map_erl_files(fun(File) ->
            Errors = gradualizer:type_check_file(File, [return_errors]),
            %% Test that error formatting doesn't crash
            lists:foreach(fun({_, Error}) -> typechecker:handle_type_error(Error) end, Errors),
            {ok, Forms} = gradualizer_file_utils:get_forms_from_erl(File),
            NumberOfExportedFunctions = typechecker:number_of_exported_functions(Forms),
            {filename:basename(File),
             [?_assertMatch({NumberOfExportedFunctions, _, _},
                            {length(Errors), filename:basename(File), NumberOfExportedFunctions})]}
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
        {filename:basename(File), [?_assertMatch({nok, _}, {Result, File})]}
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
        {filename:basename(File), ?_assertMatch({ok, _}, {Result, File})}
        end, "test/known_problems/should_fail").

map_erl_files(Fun, Dir) ->
    Files = filelib:wildcard(filename:join(Dir, "*.erl")),
    lists:map(Fun, Files).
