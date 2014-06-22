-module(speiseplan_login_controller, [Req]).
-compile(export_all).

index('GET', []) ->
  {ok, [{redirect, Req:header(referer)}]};

index('POST', []) ->
  Account = Req:post_param("account"),	
  io:format("1.. : ~p~n", [Account]),
  case boss_db:find(eater, [{account, Account}, {verified, true}]) of
    [Eater] ->
      case Eater:check_password(Req:post_param("password")) of
        true -> {redirect, elib:get_full_path(speiseplan, "/booking/index"), Eater:login_cookies()};				
        false -> {ok, [{errors, ["Bad name/password combination"]}]}
      end;
    [] -> {ok, [{errors, ["No Eater with Account"]}]}
  end.

check_verification(Eater) ->
	Eater:verification().
		
