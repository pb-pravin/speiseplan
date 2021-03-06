-module(speiseplan_admin_controller, [Req]).
-compile(export_all).
before_(_) ->
	user_lib:require_login(admin, Req).
	
index('GET', [], Admin) ->
	Menus = boss_db:find(menu, [], [{order_by, date}, descending]),
	{ok, [{menus, Menus}, {eater, Admin}]}.

mahlzeit('POST', [], Admin) ->
	Menu_Id = Req:post_param("menu-id"),
	Menu = boss_db:find(Menu_Id),
	ok = send_mail(Menu:booking(), Menu, "Das Essen ist fertig!"),
	{redirect, [{'action', "index"}]}.
	
detail('GET', [Id], Admin) ->
	Menu = boss_db:find(Id),
	Eaters = boss_db:find(eater, []),
	Requesters = Menu:get_requester(),
	{ok, [{menu, Menu}, {eaters, Eaters}, {eater, Admin}, {requesters, Requesters}]}.	
	
edit('GET', [Id], Admin) ->
	Menu = boss_db:find(Id),
	Menus = boss_db:find(menu, []),
	{ok, [{menu, Menu}, {menus, Menus}, {eater, Admin}]}.

add('POST', [Id], Admin) ->
	Date = calendar:universal_time(),
	EaterId = Req:post_param("esser"),		
	case boss_db:find(booking, [{menu_id, 'equals', Id}, {eater_id , 'equals', EaterId}]) of
		[Result] -> {redirect, "/admin/detail/" ++ Id};
				_->	NewBooking = booking:new(id, Date, false, EaterId, Id),
					{ok, SavedBooking} = NewBooking:save(),
					Eater = boss_db:find(EaterId),
					Menu = boss_db:find(Id),
					send_a_mail(Eater, Menu, "Du wurdest hinzugefügt."),
					{redirect, "/admin/detail/" ++ Id}
	end.

add_count_given('POST', [Id], Admin) ->	
	 Menu = boss_db:find(Id),
	 Count_Given = Req:post_param("count_given"),
	 MenuNew = Menu:set([{'count_given', Count_Given}]),
	 {ok, SavedMenu} = MenuNew:save(),
	 {redirect, "/admin/detail/" ++ Id}.
	
remove('POST', [Id], Admin) ->
	EaterId = Req:post_param("esser"),
	[Booking] = boss_db:find(booking, [{menu_id, 'equals', Id}, {eater_id , 'equals', EaterId}]),
	ok = boss_db:delete(Booking:id()),
	{redirect, "/admin/detail/" ++ Id}.

storno('POST', [], Admin) ->
	Menu_Id = Req:post_param("menu-id"),
	Menu = boss_db:find(Menu_Id),
	ok = send_mail(Menu:booking(), Menu, "Das Essen muss leider abgesagt werden."),
	remove_bookings(Menu:booking()),
	boss_db:delete(Menu_Id),
	{redirect, "/admin/index"}.	
	
remove_bookings([]) ->
	ok;
remove_bookings([Booking|Bookings]) ->
	boss_db:delete(Booking:id()),
	remove_bookings(Bookings).
	
create('POST', [], Admin) ->
	CreatedDate = date_lib:create_actual_date(),
	Date = Req:post_param("date"),
	Title = Req:post_param("title"),
	Details = Req:post_param("details"),
	Slots = Req:post_param("slots"),
	Vegetarian = Req:post_param("vegetarian"),
	
	NewDish = dish:new(id, Title, Details, elib:handle_checkbox(Vegetarian)),	
	case NewDish:save() of
		{error, Errors} -> {redirect, [{'action', "index"}]};
		{ok, SavedDish} -> NewMenu = menu:new(id, CreatedDate, date_lib:create_date_from_string(Date), SavedDish:id(), Slots, "0"),
						   case NewMenu:save() of
								{ok, SavedMenu} -> {redirect, [{'action', "index"}]};
								{error, Errors} -> {redirect, [{'action', "edit"}]}
							end
	end.

update('POST', [], Admin) ->
	Id = Req:post_param("id"),
	Menu = boss_db:find(Id),
	Dish = Menu:dish(),
	Date = Req:post_param("date"),
	Title = Req:post_param("title"),
	Details = Req:post_param("details"),
	Slots = Req:post_param("slots"),
	Vegetarian = Req:post_param("vegetarian"),	
	NewDish = Dish:set([{'title', Title}, {'details', Details}, {'vegetarian', elib:handle_checkbox(Vegetarian)}]),
	NewMenu = Menu:set([{'date', date_lib:create_date_from_string(Date)}, {'slots', Slots}]),
	{ok, SavedDish} = NewDish:save(),
	case NewMenu:save() of
		{ok, SavedMenu} -> {redirect, [{'action', "index"}]};
		{error, Errors} -> {redirect, [{'action', "edit"}, {menu, Menu}, {eater, Admin}, {errors, Errors}]}
	end.
		
send_mail([], Menu, Text) ->
	ok;
send_mail([Booking|Bookings], Menu, Text) ->
	Eater = Booking:eater(),
	send_a_mail(Eater, Menu, Text),
	send_mail(Bookings, Menu, Text).

send_a_mail(Eater, Menu, Text) ->
	boss_mail:send("kuechenbulle@kiezkantine.de", Eater:mail(), Menu:get_date_as_string(), Text).
