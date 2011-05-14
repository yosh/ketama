-module(ketama).

% No easy way to use this beauty -- need initialization info from user app.
% -on_load(init/0).

-export([init/2, c_getserver/1, getserver/1]).

init(NifPath, ServersPath) ->
    % Info =
    %   {
    %       Version::integer(),
    %       ServersPathLength::integer(),
    %       ServersPath::string()
    %   }
    Info = {0, length(ServersPath), ServersPath},
    ok = erlang:load_nif(NifPath, Info).

getserver(Key) when is_binary(Key) ->
    c_getserver(Key).

c_getserver(_) ->
    "Ketama NIF library not loaded.".
