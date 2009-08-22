MacOS=$(BUILT_PRODUCTS_DIR)/$(EXECUTABLE_FOLDER_PATH)
Resources=$(BUILT_PRODUCTS_DIR)/$(UNLOCALIZED_RESOURCES_FOLDER_PATH)
INT=cd $(MacOS) && $(SRCROOT)/Playdar.prefPane.xcodeproj/install_name_tool

DYLIBS=$(MacOS)/libboost_date_time.dylib $(MacOS)/libboost_regex.dylib $(MacOS)/libtag.1.dylib $(MacOS)/libboost_filesystem.dylib $(MacOS)/libboost_system.dylib $(MacOS)/libboost_program_options.dylib $(MacOS)/libboost_thread.dylib
EXECUTABLES=$(MacOS)/playdar $(MacOS)/tagger $(MacOS)/scanner
PLUGINS=$(MacOS)/plugins/audioscrobbler.resolver $(MacOS)/plugins/local.resolver $(MacOS)/plugins/api.resolver $(MacOS)/plugins/boffin.resolver $(MacOS)/plugins/lan.resolver

BOOST_PREFIX=/usr/local/Cellar/boost/1.39.0
TAGLIB_PREFIX=/usr/local/Cellar/taglib/1.5

force: $(EXECUTABLES) $(DYLIBS) $(PLUGINS) $(MacOS)/www
clean:
	rm $(EXECUTABLES) $(DYLIBS) $(PLUGINS) $(MacOS)/www

$(MacOS)/plugins:
	mkdir $@
$(MacOS)/plugins/%.resolver: playdar/plugins/%.resolver | $(MacOS)/plugins
	cp $< $@
	$(INT) plugins/$(@F)
$(MacOS)/playdar: playdar/bin/playdar
	cp $< $@
	strip -SX $@
	$(INT) $@
$(MacOS)/tagger: playdar/bin/tagger
	cp $< $@
	strip -SX $@
	$(INT) $@
$(MacOS)/scanner: playdar/bin/scanner
	cp $< $@
	strip -SX $@
	$(INT) $@
$(MacOS)/www: playdar/www
	rm -rf $@ && cp -R $< $@

$(MacOS)/libboost_date_time.dylib: $(BOOST_PREFIX)/lib/libboost_date_time.dylib
	cp $< $@
	$(INT) $(@F)
$(MacOS)/libboost_regex.dylib: $(BOOST_PREFIX)/lib/libboost_regex.dylib
	cp $< $@
	$(INT) $(@F)
$(MacOS)/libboost_filesystem.dylib: $(BOOST_PREFIX)/lib/libboost_filesystem.dylib
	cp $< $@
	$(INT) $(@F)
$(MacOS)/libboost_system.dylib: $(BOOST_PREFIX)/lib/libboost_system.dylib
	cp $< $@
	$(INT) $(@F)
$(MacOS)/libboost_program_options.dylib: $(BOOST_PREFIX)/lib/libboost_program_options.dylib
	cp $< $@
	$(INT) $(@F)
$(MacOS)/libboost_thread.dylib: $(BOOST_PREFIX)/lib/libboost_thread.dylib
	cp $< $@
	$(INT) $(@F)
$(MacOS)/libtag.1.dylib: $(TAGLIB_PREFIX)/lib/libtag.1.5.0.dylib
	cp $< $@
	$(INT) $(@F)

.PHONY: force clean
