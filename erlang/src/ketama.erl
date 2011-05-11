-module(ketama).

-on_load(init/0).

-export([init/0, getserver/1]).

init() ->
    NifPath = "./ketama",
    Path = "/usr/home/andrei/src/abs-rdio/rdio/ce/everyburger/etc/ketama.servers",
    ok = erlang:load_nif(NifPath, {0, length(Path), Path}).

getserver(_Arg) ->
    "Ketama NIF library not loaded.".
