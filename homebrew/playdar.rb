require 'common'
require 'fileutils'

class Playdar <PlaydarPrefPaneFormula
  homepage 'http://www.playdar.org'
  head 'git://github.com/mxcl/playdar-core.git', :branch => 'prefpane'

  def patches
    DATA
  end

  include FileUtils

  def install
    ENV.osx_10_5

    mv 'contrib/aolmusic', 'playdar_modules'

    system "make scanner"
    system "make all"

    Dir['playdar_modules/*/src'].each{ |fn| rm_rf fn }
    rm_rf 'playdar_modules/library/priv/taglib_driver/scanner_visual_studio_sln'
    rm 'playdar_modules/library/priv/taglib_driver/taglib_json_reader.cpp'

    prefix.install 'ebin'
    prefix.install 'playdar_modules'
    prefix.install 'priv'
    prefix.install 'etc' # otherwise playdar crashes

    (prefix+'contrib').install 'contrib/echonest'
    (prefix+'contrib').install 'contrib/mp3tunes'
    (prefix+'contrib').install 'contrib/demo-script'

    prefix.install 'bin'
    prefix.install 'Makefile'

    system "strip #{prefix}/playdar_modules/library/priv/taglib_driver/taglib_json_reader"
  end
end

__END__
diff --git a/Makefile b/Makefile
index 78e17ca..3aac8af 100644
--- a/Makefile
+++ b/Makefile
@@ -5,7 +5,7 @@ endif
 
 ######################################################################## setup
 ERLCFLAGS = -pa ebin -W0 -I include
-ERLC = bin/erlc
+ERLC = erlc
 .DEFAULT_GOAL = all
 .PHONY: all clean update
 
@@ -72,7 +72,7 @@ endef
 $(foreach d, $(wildcard playdar_modules/*), $(eval $(call MODULE_template, $(d))) )
 
 $(TAGLIB_JSON_READER): $(TAGLIB_JSON_READER).cpp
-	/Developer/usr/llvm-gcc-4.2/bin/llvm-g++-4.2 `taglib-config --cflags` -Wl,--sysroot /Developer/SDKs/MacOSX10.5.sdk -mmacosx-version-min=10.5 -Os -m32 -lz $(PPP_CELLAR)/taglib/libtag.a -o $@ $<
+	/Developer/usr/llvm-gcc-4.2/bin/llvm-g++-4.2 `taglib-config --cflags` -arch i386 -arch ppc -arch x86_64 -Wl,-dead_strip -Wl,-syslibroot /Developer/SDKs/MacOSX10.5.sdk -mmacosx-version-min=10.5 -Os -m32 -lz $(PPP_CELLAR)/taglib/libtag.a -o $@ $<
 
 ########################################################################## all
 all: $(BEAM) ebin/playdar.app ebin/mochiweb.app ebin/erlydtl.app
