-module(eater, [Id, Account, PasswordHash, Forename, Name, Intern, PriceToPay, Admin, Mail, Verified, Comfirmed]).
-compile(export_all).
-define(SECRET_STRING, "Not telling secrets!").

session_identifier() ->
  mochihex:to_hex(erlang:md5(?SECRET_STRING ++ Id)).

check_password(Password) ->
  Salt = mochihex:to_hex(erlang:md5(Account)),
  user_lib:hash_password(Password, Salt) =:= PasswordHash.

login_cookies() ->
  [ mochiweb_cookies:cookie("user_id", Id, [{path, "/"}]),
  mochiweb_cookies:cookie("session_id", session_identifier(), [{path, "/"}]) ].

before_create() ->
	{ok, set([{'price_to_pay', get_price_to_pay(Intern)}, {'admin', get_admin(Admin)}])}.		
		
before_update() ->
	{ok, set([{'price_to_pay', get_price_to_pay(Intern)}, {'admin', get_admin(Admin)}])}.		

get_price_to_pay(true) ->	
	3;
get_price_to_pay(false) ->	
	5.

get_admin(Admin) ->
	Admin =:= true. 
	
get_admin()->
	get_admin(Admin).
	
validation_tests() ->
	[{fun() -> length(Account) > 0 end,
		"Please enter a account"},
	{fun() -> length(Forename) > 0 end,
		"Please enter a forename"},
	{fun() -> length(Name) > 0 end,
		"Please enter a Name"},
	{fun() -> length(Mail) > 0 end,
		"Please enter a valid mail adress"}
	].
	
