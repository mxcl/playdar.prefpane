require 'common'

class Playdar <PlaydarPrefPaneFormula
  homepage 'http://www.playdar.org'
  head 'git://github.com/mxcl/playdar-core.git', :branch => 'prefpane'

  def install
    ENV.osx_10_5

    FileUtils.mv 'contrib/aolmusic', 'playdar_modules'

    system "make scanner"
    system "make all"

    Dir['playdar_modules/*/src'].each{ |fn| FileUtils.rm_rf fn }
    FileUtils.rm_rf 'playdar_modules/library/priv/taglib_driver/scanner_visual_studio_sln'
    File.unlink 'playdar_modules/library/priv/taglib_driver/taglib_json_reader.cpp'

    prefix.install 'ebin'
    prefix.install 'playdar_modules'
    prefix.install 'priv'
    prefix.install 'etc' # otherwise playdar crashes

    (prefix+'contrib').install 'contrib/echonest'
    (prefix+'contrib').install 'contrib/mp3tunes'
    (prefix+'contrib').install 'contrib/demo-script'

    bin.install 'playdarctl'

    system "strip #{prefix}/playdar_modules/library/priv/taglib_driver/taglib_json_reader"
  end
end
