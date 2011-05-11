-module(ketama).

% No easy way to use this beauty -- need initialization info from user app.
% -on_load(init/0).

-export([init/2, getserver/1, getserver/2]).

init(NifPath, ServersPath) ->
    ok = erlang:load_nif(NifPath, {0, length(ServersPath), ServersPath}).

getserver(Key) ->
    getserver(length(Key), Key).

getserver(_, _) ->
    "Ketama NIF library not loaded.".
