require 'common'

class Taglib <PlaydarPrefPaneFormula
  url 'http://developer.kde.org/~wheeler/files/src/taglib-1.6.tar.gz'
  md5 '5ecad0816e586a954bd676a86237d054'
  homepage 'http://developer.kde.org/~wheeler/taglib.html'

  def install
    ENV['CXXFLAGS'] = "-w -pipe -fomit-frame-pointer -msse3 -mmmx -m32"
    ENV.Os
    ENV.osx_10_5
    ENV.append 'CFLAGS', '--sysroot /Developer/SDKs/MacOSX10.5.sdk/'

    system "./configure", "--enable-mp4", "--enable-asf", "--enable-static", "--disable-shared",
                          "--disable-debug", "--prefix=#{prefix}"
    system "make"

    prefix.install 'taglib/.libs/libtag.a'
  end
end