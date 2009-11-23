require 'common'
require 'fileutils'

class Erlang <PlaydarPrefPaneFormula
  url 'http://erlang.org/download/otp_src_R13B02-1.tar.gz'
  md5 '2593b9312eb1b15bf23a968743138c52'
  version 'R13B02-1'
  homepage 'http://www.erlang.org'

  depends_on 'icu4c'

  def skip_clean? path
    path.basename == 'crypto_drv.so' or path == bin+'playdar.smp'
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
    parsetools
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
    ENV['CFLAGS'] = '-fomit-frame-pointer -w'
    ENV.j1
    ENV.gcc_4_2 # see http://github.com/mxcl/homebrew/issues/#issue/120
    ENV.Os
    ENV.m32 # we'll do universal when we can
    ENV.osx_10_5
    ENV.append 'CFLAGS', '--sysroot /Developer/SDKs/MacOSX10.5.sdk/'
    ENV.append 'LDFLAGS', '--sysroot /Developer/SDKs/MacOSX10.5.sdk/'

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
                          "--enable-smp-support"
    system "make"
    system "make install"

    Dir.chdir prefix

    rm_rf 'bin' # these are all scripts

    erts = 'lib/erlang/erts-5.7.3'

    bin.install Dir['lib/erlang/bin/*']

    rm 'bin/epmd'

    bin.install "#{erts}/bin/epmd"
    bin.install "#{erts}/bin/inet_gethost"
    bin.install "#{erts}/bin/heart"
    bin.install "#{erts}/bin/erlexec"

    Dir.chdir "#{erts}/bin" do
      bin.install 'beam.smp'
      bin.install 'child_setup'
    end

    mv 'bin/beam.smp', 'bin/playdar.smp'

    rm 'bin/start.script'
    rm 'bin/start_erl'
    rm 'bin/start'
    rm 'bin/typer'
    rm 'bin/to_erl'
    rm 'bin/run_erl'

    mv 'lib', '_lib'
    mv '_lib/erlang/lib', 'lib'
    rm_rf '_lib'

    rm_rf Dir['lib/jinterface-*']
    rm_rf Dir['lib/odbc-*']
    rm_rf Dir['lib/orber-*']
    rm_rf Dir['lib/ssh-*']

    rm_rf Dir['lib/*/*'].reject{ |d| case File.basename(d) when 'ebin', 'priv' then true end }

    rm_rf Dir['lib/crypto-*/priv/obj']
    rm_rf Dir['lib/inets-*/priv']
    rm_rf Dir['lib/ssl-*/priv/obj']

    rm_rf Dir['lib/erl_interface-*'] # needed to build erlang, but not after

    File.open(bin+'erl', 'w') { |f| f.write(DATA.read) }
  end
end

__END__
#!/bin/sh
mkdir -p ~/Library/Application\ Support/Playdar

export ROOTDIR="`cd $(dirname $0)/.. && pwd`"
export BINDIR=$ROOTDIR/bin
export EMU=playdar
export PROGNAME=`echo $0 | sed 's/.*\\///'`
exec $BINDIR/erlexec ${1+"$@"}
EOS
