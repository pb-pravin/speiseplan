PROJECT = speisplan
DIALYZER = dialyzer
REBAR = rebar
REPO = ../../../../repository
REPOSRC = ../../repository
TARGET = ~/projects/erlang



all: app

tar: app 
	cd rel; tar cvf $(REPO)/$(PROJECT).$(VERSION).tar $(PROJECT)

tarall: app 
	cd ..; tar cf $(REPOSRC)/$(PROJECT).src.$(VERSION).tar $(PROJECT) --exclude log/* --exclude Mnesia.speiseplan@ua-TA880GB

cpall: tarall
	cd ..;scp $(REPOSRC)/$(PROJECT).src.$(VERSION).tar $(USR)@$(HOST):$(TARGET)
	ssh $(USR)@$(HOST) 'cd $(TARGET); tar xf $(TARGET)/$(PROJECT).src.$(VERSION).tar'

cp: tar
	 cd ..;scp $(REPOSRC)/$(PROJECT).$(VERSION).tar $(USR)@$(HOST):$(TARGET)

release: app
	@$(REBAR) generate

app: deps
	@$(REBAR) compile

deps:
	@$(REBAR) get-deps

clean:
	@$(REBAR) clean
	rm -f test/*.beam
	rm -f erl_crash.dump
	rm -f log/*

tests: clean app eunit ct

eunit:
	@$(REBAR) eunit skip_deps=true


docs:
	@$(REBAR) doc skip_deps=true
