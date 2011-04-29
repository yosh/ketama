%%%-------------------------------------------------------------------
%%% File    : ketama.erl
%%% Author  : Andrei Soroker <andrei@rd.io>
%%% Author  : Richard Jones <rj@last.fm>
%%% Description : Port driver for libketama hasing
%%%-------------------------------------------------------------------
-module(ketama).

-behaviour(supervisor).

-export([init/1, start_ketama_server/2]).

%% API
-export([start_link/0, start_link/1, start_link/2, getserver/1]).

-define(FARM_SIZE, 10).

start_link() ->
    start_link("/web/site/GLOBAL/ketama.servers").

start_link(ServersFile) ->
    start_link(ServersFile, "/usr/bin/ketama_erlang_driver").

start_link(ServersFile, BinPath) ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, [[ServersFile, BinPath], ?FARM_SIZE]).

getserver(Key) ->
    X = case is_binary(Key) of
        true ->
            lists:sum(binary_to_list(Key));
        false ->
            lists:sum(Key)
    end,
    Id = list_to_atom("ketama." ++ integer_to_list(X rem ?FARM_SIZE + 1)),
    Id ! {getserver, Key, self()},
    receive
        Result ->
            Result
    end.

spec(I, Exe) ->
    Id = list_to_atom("ketama." ++ integer_to_list(I)),
    {Id,
     {ketama, start_ketama_server, [Id, Exe]},
     permanent, 2000, worker, [ketama]}.

specs(0, Specs, Exe) ->
    Specs;
specs(I, Specs, Exe) ->
    specs(I - 1, [spec(I, Exe) | Specs], Exe).

init([[ServersFile, BinPath], N]) ->
    Exe = BinPath ++ " " ++ ServersFile,
    Specs = specs(N, [], Exe),
    {ok, {{one_for_one, 10, 600}, Specs}}.

start_ketama_server(Id, Exe) ->
    Pid = spawn_link(fun() ->
        Port = open_port({spawn, Exe}, [binary, {packet, 1}, use_stdio]),
        register(Id, self()),
        process_flag(trap_exit, true),
        Loop = fun(Loop) ->
            receive
                {'EXIT', From, Reason} ->
                    port_close(Port);
                {getserver, Key, From} ->
                    Port ! {self(), {command, Key}},
                    receive
                        {Port, {data, Data}} ->
                            From ! Data,
                            Loop(Loop)
                        after 1000 -> % if it takes this long, you have serious issues.
                            From ! ketama_port_timeout,
                            Loop(Loop)
                    end
            end
        end,
        Loop(Loop)
    end),
    {ok, Pid}.
