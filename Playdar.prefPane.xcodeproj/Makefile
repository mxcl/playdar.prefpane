d=$(BUILT_PRODUCTS_DIR)/$(EXECUTABLE_FOLDER_PATH)/../Daemon
Resources=$(BUILT_PRODUCTS_DIR)/$(UNLOCALIZED_RESOURCES_FOLDER_PATH)
INT=cd $(d) && $(SRCROOT)/Playdar.prefPane.xcodeproj/install_name_tool

DYLIBS=$(d)/libboost_date_time.dylib $(d)/libboost_regex.dylib $(d)/libtag.1.dylib $(d)/libboost_filesystem.dylib $(d)/libboost_system.dylib $(d)/libboost_program_options.dylib $(d)/libboost_thread.dylib
EXECUTABLES=$(d)/playdar $(d)/tagger $(d)/scanner
PLUGINS=$(d)/plugins/audioscrobbler.resolver $(d)/plugins/local.resolver $(d)/plugins/api.resolver $(d)/plugins/boffin.resolver $(d)/plugins/lan.resolver

# this is the only bit specific to my machine, please fix!
BOOST_PREFIX=/usr/local/Cellar/boost/1.39.0
TAGLIB_PREFIX=/usr/local/Cellar/taglib/1.5

force: $(EXECUTABLES) $(DYLIBS) $(PLUGINS) $(d)/www
clean:
	rm $(EXECUTABLES) $(DYLIBS) $(PLUGINS) $(d)/www

$(d):
	mkdir -p $@

$(d)/plugins: | $(d)
	mkdir $@
$(d)/plugins/%.resolver: playdar/plugins/%.resolver | $(d)/plugins
	cp $< $@
	$(INT) plugins/$(@F)
$(d)/playdar: playdar/bin/playdar | $(d)
	cp $< $@
	strip -SX $@
	$(INT) $@
$(d)/tagger: playdar/bin/tagger | $(d)
	cp $< $@
	strip -SX $@
	$(INT) $@
$(d)/scanner: playdar/bin/scanner | $(d)
	cp $< $@
	strip -SX $@
	$(INT) $@
$(d)/www: playdar/www | $(d)
	rm -rf $@ && cp -R $< $@

$(d)/libboost_date_time.dylib: $(BOOST_PREFIX)/lib/libboost_date_time.dylib | $(d)
	cp $< $@
	$(INT) $(@F)
$(d)/libboost_regex.dylib: $(BOOST_PREFIX)/lib/libboost_regex.dylib | $(d)
	cp $< $@
	$(INT) $(@F)
$(d)/libboost_filesystem.dylib: $(BOOST_PREFIX)/lib/libboost_filesystem.dylib | $(d)
	cp $< $@
	$(INT) $(@F)
$(d)/libboost_system.dylib: $(BOOST_PREFIX)/lib/libboost_system.dylib | $(d)
	cp $< $@
	$(INT) $(@F)
$(d)/libboost_program_options.dylib: $(BOOST_PREFIX)/lib/libboost_program_options.dylib | $(d)
	cp $< $@
	$(INT) $(@F)
$(d)/libboost_thread.dylib: $(BOOST_PREFIX)/lib/libboost_thread.dylib | $(d)
	cp $< $@
	$(INT) $(@F)
$(d)/libtag.1.dylib: $(TAGLIB_PREFIX)/lib/libtag.1.5.0.dylib | $(d)
	cp $< $@
	$(INT) $(@F)

.PHONY: force clean
