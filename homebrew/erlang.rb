require 'common'
require 'fileutils'

ERL_SH=<<-EOS
#!/bin/sh
mkdir -p ~/Library/Application\\ Support/Playdar

cd `dirname "$0"`/..

export ROOTDIR="$PWD"
export BINDIR="$ROOTDIR/bin"
export PROGNAME=erl
exec bin/erlexec ${1+"$@"}
EOS

class Erlang <PlaydarPrefPaneFormula
  url 'http://erlang.org/download/otp_src_R13B02-1.tar.gz'
  md5 '2593b9312eb1b15bf23a968743138c52'
  version 'R13B02-1'
  homepage 'http://www.erlang.org'

  depends_on 'icu4c'

  def patches
    DATA
  end

  def skip_clean? path
    path.basename == 'crypto_drv.so' or path == bin+'beam.smp' or path == bin+'playdar.smp'
  end

  def skips
    %w[appmon
    asn1
    common_test
    cosEvent
    cosEventDomain
    cosFileTransfer
    cosNotification
    cosProperty
    cosTime
    cosTransactions
    debugger
    dialyzer
    docbuilder
    et
    eunit
    gs
    hipe
    ic
    inviso
    jinterface
    megaco
    mnesia
    observer
    odbc
    orber
    os_mon
    otp_mibs
    percept
    pman
    public_key
    reltool
    runtime_tools
    snmp
    ssh
    ssl
    test_server
    toolbar
    tools
    tv
    typer
    webtool
    wx].collect{|x| "lib/#{x}"}
  end

  include FileUtils

  def install
    ENV['CFLAGS'] = '-w -mmacosx-version-min=10.5 -Os -pipe'
    ENV['LDFLAGS'] = '--sysroot /Developer/SDKs/MacOSX10.5.sdk'
    ENV['MAKEFLAGS'] = '-j1'
    ENV['CC'] = ENV['ld'] = 'gcc'
    ENV['cxx'] = 'g++'
    ENV['MACOSX_DEPLOYMENT_TARGET'] = '10.5'

    skips.each{ |fn| `touch #{fn}/SKIP` }

    system "./configure", "--disable-debug",
                          "--prefix=#{prefix}",
                          "--enable-kernel-poll",
                          "--enable-shared-zlib", # won't work with 10.4 SDK
                          "--disable-erlang-mandir",
                          "--enable-threads",
                          "--enable-dynamic-ssl-lib",
                          "--without-java",
                          "--disable-hipe", # doesn't work well on OS X
                          "--enable-smp-support",
                          "--enable-darwin-universal"

    system "make"
    system "make install.libs"

    bin.install Dir['erts/start_scripts/*.boot']+
                %w[erlc escript inet_gethost epmd child_setup erlexec
                   beam.smp].collect{|x|"bin/i386-apple-darwin10.2.0/#{x}"}

    Dir.chdir prefix
    Dir.chdir('bin') do
      # this mustn't be a symlink because the GUI stuff polls for playdar.smp
      # as a pid and for some reason the symlink method doesn't work for our
      # polling method on BSD
      ln 'beam.smp', 'playdar.smp'
      ln_s 'start_clean.boot', 'start.boot'
    end

    %w[compiler crypto edoc inets kernel parsetools sasl stdlib syntax_tools xmerl].each do |d|
      mv Dir["lib/erlang/lib/#{d}-*"], 'lib'
    end
    rm_rf 'lib/erlang'

    rm_rf Dir['lib/*/*'].reject{ |d|
      case d
      when %r[lib/parsetools-(\d+\.?)+/include] then true
      when %r[lib/kernel-(\d+\.?)+/include] then true
      when %r[lib/crypto-(\d+\.?)+/priv] then true
      when %r[lib/.+/ebin] then true
      end }
    rm_rf Dir['lib/crypto-*/priv/obj']

    File.open(bin+'erl', 'w') { |f| f.write(ERL_SH) }
  end
end

# respect our desire to link against the 10.5 SDK
__END__
diff --git a/lib/crypto/c_src/Makefile.in b/lib/crypto/c_src/Makefile.in
index 58a5649..f86dde5 100644
--- a/lib/crypto/c_src/Makefile.in
+++ b/lib/crypto/c_src/Makefile.in
@@ -116,7 +116,7 @@ $(OBJDIR)/%.o: %.c
 
 $(LIBDIR)/crypto_drv.so: $(OBJS)
 	$(INSTALL_DIR) $(LIBDIR) 
-	$(LD) $(LDFLAGS) $(LD_R_OPT) -o $@ $^ $(LDLIBS) $(CRYPTO_LINK_LIB)
+	$(LD) $(LDFLAGS) $(LD_R_OPT) -Wl,-syslibroot,/Developer/SDKs/MacOSX10.5.sdk -o $@ $^ $(LDLIBS) $(CRYPTO_LINK_LIB)
 
 $(LIBDIR)/crypto_drv.dll: $(OBJS)
 	$(INSTALL_DIR) $(LIBDIR)
