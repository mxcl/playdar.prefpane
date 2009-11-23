require 'common'
require 'find'

# this is slightly insane
# but we get much smaller binaries and it all compiles *really* fast
# basically I compile all the cpp files simultaneously
# however, considering we are totally ignoring the developer written build system
# things may go wrong. And maintenance is likely to be more painful.
# the massive patch is also required as we condense all the namespaces into a single
# file, and they aren't expecting that. The patch basically explicitly references
# all namespace so that the compiler doesn't error out due to ambiguity and collision

class Taglib <PlaydarPrefPaneFormula
  url 'http://developer.kde.org/~wheeler/files/src/taglib-1.6.tar.gz'
  md5 '5ecad0816e586a954bd676a86237d054'
  homepage 'http://developer.kde.org/~wheeler/taglib.html'

  def patches
    DATA
  end

  def install
    ENV.osx_10_5

    Dir.chdir 'taglib' do
      init

      system "touch taglib_config.h"
      build 'ppc'
      build 'i386'
      build 'x86_64'
      system "lipo *.o -create -output libtag.a"

      prefix.install 'libtag.a'
    end
  end

  def build arch
    system *@args+%W[-arch #{arch} -o #{arch}.o]
  end

  def init
    @args = ['/Developer/usr/llvm-gcc-4.2/bin/llvm-g++-4.2']

    f = File.open('libtag.cpp', 'w')
    Find.find '.' do |fn|
      next if fn == './libtag.cpp'
      next if fn == '.'

      if fn =~ /.cpp$/
        f.write "#include \"#{fn}\"\n"
      elsif File.directory? fn
        @args << "-I#{fn}"
      end
    end
    f.close

    @args << 'libtag.cpp'
    @args << '-c' << "-I."
    @args << '--sysroot' << '/Developer/SDKs/MacOSX10.5.sdk' << '-mmacosx-version-min=10.5'
    @args << '-Os' << '-pipe' << '-DHAVE_ZLIB'
    
    p @args
  end
end

__END__
diff --git a/taglib/ape/apefooter.cpp b/taglib/ape/apefooter.cpp
index da6494b..f4a8ed7 100644
--- a/taglib/ape/apefooter.cpp
+++ b/taglib/ape/apefooter.cpp
@@ -35,7 +35,7 @@
 using namespace TagLib;
 using namespace APE;
 
-class Footer::FooterPrivate
+class APE::Footer::FooterPrivate
 {
 public:
   FooterPrivate() : version(0),
@@ -64,12 +64,12 @@ public:
 // static members
 ////////////////////////////////////////////////////////////////////////////////
 
-TagLib::uint Footer::size()
+TagLib::uint APE::Footer::size()
 {
   return FooterPrivate::size;
 }
 
-ByteVector Footer::fileIdentifier()
+ByteVector APE::Footer::fileIdentifier()
 {
   return ByteVector::fromCString("APETAGEX");
 }
@@ -78,63 +78,63 @@ ByteVector Footer::fileIdentifier()
 // public members
 ////////////////////////////////////////////////////////////////////////////////
 
-Footer::Footer()
+APE::Footer::Footer()
 {
   d = new FooterPrivate;
 }
 
-Footer::Footer(const ByteVector &data)
+APE::Footer::Footer(const ByteVector &data)
 {
   d = new FooterPrivate;
   parse(data);
 }
 
-Footer::~Footer()
+APE::Footer::~Footer()
 {
   delete d;
 }
 
-TagLib::uint Footer::version() const
+TagLib::uint APE::Footer::version() const
 {
   return d->version;
 }
 
-bool Footer::headerPresent() const
+bool APE::Footer::headerPresent() const
 {
   return d->headerPresent;
 }
 
-bool Footer::footerPresent() const
+bool APE::Footer::footerPresent() const
 {
   return d->footerPresent;
 }
 
-bool Footer::isHeader() const
+bool APE::Footer::isHeader() const
 {
   return d->isHeader;
 }
 
-void Footer::setHeaderPresent(bool b) const
+void APE::Footer::setHeaderPresent(bool b) const
 {
   d->headerPresent = b;
 }
 
-TagLib::uint Footer::itemCount() const
+TagLib::uint APE::Footer::itemCount() const
 {
   return d->itemCount;
 }
 
-void Footer::setItemCount(uint s)
+void APE::Footer::setItemCount(uint s)
 {
   d->itemCount = s;
 }
 
-TagLib::uint Footer::tagSize() const
+TagLib::uint APE::Footer::tagSize() const
 {
   return d->tagSize;
 }
 
-TagLib::uint Footer::completeTagSize() const
+TagLib::uint APE::Footer::completeTagSize() const
 {
   if(d->headerPresent)
     return d->tagSize + d->size;
@@ -142,22 +142,22 @@ TagLib::uint Footer::completeTagSize() const
     return d->tagSize;
 }
 
-void Footer::setTagSize(uint s)
+void APE::Footer::setTagSize(uint s)
 {
   d->tagSize = s;
 }
 
-void Footer::setData(const ByteVector &data)
+void APE::Footer::setData(const ByteVector &data)
 {
   parse(data);
 }
 
-ByteVector Footer::renderFooter() const
+ByteVector APE::Footer::renderFooter() const
 {
     return render(false);
 }
 
-ByteVector Footer::renderHeader() const
+ByteVector APE::Footer::renderHeader() const
 {
     if (!d->headerPresent) return ByteVector();
 
@@ -168,7 +168,7 @@ ByteVector Footer::renderHeader() const
 // protected members
 ////////////////////////////////////////////////////////////////////////////////
 
-void Footer::parse(const ByteVector &data)
+void APE::Footer::parse(const ByteVector &data)
 {
   if(data.size() < size())
     return;
@@ -197,7 +197,7 @@ void Footer::parse(const ByteVector &data)
 
 }
 
-ByteVector Footer::render(bool isHeader) const
+ByteVector APE::Footer::render(bool isHeader) const
 {
   ByteVector v;
 
diff --git a/taglib/flac/flacfile.cpp b/taglib/flac/flacfile.cpp
index ed3d6db..e88c252 100644
--- a/taglib/flac/flacfile.cpp
+++ b/taglib/flac/flacfile.cpp
@@ -40,12 +40,12 @@ using namespace TagLib;
 
 namespace
 {
-  enum { XiphIndex = 0, ID3v2Index = 1, ID3v1Index = 2 };
+  enum { XiphIndex = 0, ID3v2Index_flac = 1, ID3v1Index_flac = 2 };
   enum { StreamInfo = 0, Padding, Application, SeekTable, VorbisComment, CueSheet };
   enum { MinPaddingLength = 4096 };
 }
 
-class FLAC::File::FilePrivate
+class TagLib::FLAC::File::FilePrivate
 {
 public:
   FilePrivate() :
@@ -93,7 +93,7 @@ public:
 // public members
 ////////////////////////////////////////////////////////////////////////////////
 
-FLAC::File::File(FileName file, bool readProperties,
+TagLib::FLAC::File::File(FileName file, bool readProperties,
                  Properties::ReadStyle propertiesStyle) :
   TagLib::File(file)
 {
@@ -101,7 +101,7 @@ FLAC::File::File(FileName file, bool readProperties,
   read(readProperties, propertiesStyle);
 }
 
-FLAC::File::File(FileName file, ID3v2::FrameFactory *frameFactory,
+TagLib::FLAC::File::File(FileName file, ID3v2::FrameFactory *frameFactory,
                  bool readProperties, Properties::ReadStyle propertiesStyle) :
   TagLib::File(file)
 {
@@ -110,26 +110,26 @@ FLAC::File::File(FileName file, ID3v2::FrameFactory *frameFactory,
   read(readProperties, propertiesStyle);
 }
 
-FLAC::File::~File()
+TagLib::FLAC::File::~File()
 {
   delete d;
 }
 
-TagLib::Tag *FLAC::File::tag() const
+TagLib::Tag *TagLib::FLAC::File::tag() const
 {
   return &d->tag;
 }
 
-FLAC::Properties *FLAC::File::audioProperties() const
+TagLib::FLAC::Properties *TagLib::FLAC::File::audioProperties() const
 {
   return d->properties;
 }
 
 
-bool FLAC::File::save()
+bool TagLib::FLAC::File::save()
 {
   if(readOnly()) {
-    debug("FLAC::File::save() - Cannot save to a read only file.");
+    debug("TagLib::FLAC::File::save() - Cannot save to a read only file.");
     return false;
   }
 
@@ -246,7 +246,7 @@ bool FLAC::File::save()
   if(ID3v2Tag()) {
     if(d->hasID3v2) {
       if(d->ID3v2Location < d->flacStart)
-        debug("FLAC::File::save() -- This can't be right -- an ID3v2 tag after the "
+        debug("TagLib::FLAC::File::save() -- This can't be right -- an ID3v2 tag after the "
               "start of the FLAC bytestream?  Not writing the ID3v2 tag.");
       else
         insert(ID3v2Tag()->render(), d->ID3v2Location, d->ID3v2OriginalSize);
@@ -263,26 +263,26 @@ bool FLAC::File::save()
   return true;
 }
 
-ID3v2::Tag *FLAC::File::ID3v2Tag(bool create)
+ID3v2::Tag *TagLib::FLAC::File::ID3v2Tag(bool create)
 {
-  if(!create || d->tag[ID3v2Index])
-    return static_cast<ID3v2::Tag *>(d->tag[ID3v2Index]);
+  if(!create || d->tag[ID3v2Index_flac])
+    return static_cast<ID3v2::Tag *>(d->tag[ID3v2Index_flac]);
 
-  d->tag.set(ID3v2Index, new ID3v2::Tag);
-  return static_cast<ID3v2::Tag *>(d->tag[ID3v2Index]);
+  d->tag.set(ID3v2Index_flac, new ID3v2::Tag);
+  return static_cast<ID3v2::Tag *>(d->tag[ID3v2Index_flac]);
 }
 
-ID3v1::Tag *FLAC::File::ID3v1Tag(bool create)
+ID3v1::Tag *TagLib::FLAC::File::ID3v1Tag(bool create)
 {
-  return d->tag.access<ID3v1::Tag>(ID3v1Index, create);
+  return d->tag.access<ID3v1::Tag>(ID3v1Index_flac, create);
 }
 
-Ogg::XiphComment *FLAC::File::xiphComment(bool create)
+Ogg::XiphComment *TagLib::FLAC::File::xiphComment(bool create)
 {
   return d->tag.access<Ogg::XiphComment>(XiphIndex, create);
 }
 
-void FLAC::File::setID3v2FrameFactory(const ID3v2::FrameFactory *factory)
+void TagLib::FLAC::File::setID3v2FrameFactory(const ID3v2::FrameFactory *factory)
 {
   d->ID3v2FrameFactory = factory;
 }
@@ -292,7 +292,7 @@ void FLAC::File::setID3v2FrameFactory(const ID3v2::FrameFactory *factory)
 // private members
 ////////////////////////////////////////////////////////////////////////////////
 
-void FLAC::File::read(bool readProperties, Properties::ReadStyle propertiesStyle)
+void TagLib::FLAC::File::read(bool readProperties, Properties::ReadStyle propertiesStyle)
 {
   // Look for an ID3v2 tag
 
@@ -300,12 +300,12 @@ void FLAC::File::read(bool readProperties, Properties::ReadStyle propertiesStyle
 
   if(d->ID3v2Location >= 0) {
 
-    d->tag.set(ID3v2Index, new ID3v2::Tag(this, d->ID3v2Location, d->ID3v2FrameFactory));
+    d->tag.set(ID3v2Index_flac, new ID3v2::Tag(this, d->ID3v2Location, d->ID3v2FrameFactory));
 
     d->ID3v2OriginalSize = ID3v2Tag()->header()->completeTagSize();
 
     if(ID3v2Tag()->header()->tagSize() <= 0)
-      d->tag.set(ID3v2Index, 0);
+      d->tag.set(ID3v2Index_flac, 0);
     else
       d->hasID3v2 = true;
   }
@@ -315,7 +315,7 @@ void FLAC::File::read(bool readProperties, Properties::ReadStyle propertiesStyle
   d->ID3v1Location = findID3v1();
 
   if(d->ID3v1Location >= 0) {
-    d->tag.set(ID3v1Index, new ID3v1::Tag(this, d->ID3v1Location));
+    d->tag.set(ID3v1Index_flac, new ID3v1::Tag(this, d->ID3v1Location));
     d->hasID3v1 = true;
   }
 
@@ -335,22 +335,22 @@ void FLAC::File::read(bool readProperties, Properties::ReadStyle propertiesStyle
     d->properties = new Properties(streamInfoData(), streamLength(), propertiesStyle);
 }
 
-ByteVector FLAC::File::streamInfoData()
+ByteVector TagLib::FLAC::File::streamInfoData()
 {
   return isValid() ? d->streamInfoData : ByteVector();
 }
 
-ByteVector FLAC::File::xiphCommentData() const
+ByteVector TagLib::FLAC::File::xiphCommentData() const
 {
   return (isValid() && d->hasXiphComment) ? d->xiphCommentData : ByteVector();
 }
 
-long FLAC::File::streamLength()
+long TagLib::FLAC::File::streamLength()
 {
   return d->streamLength;
 }
 
-void FLAC::File::scan()
+void TagLib::FLAC::File::scan()
 {
   // Scan the metadata pages
 
@@ -368,7 +368,7 @@ void FLAC::File::scan()
     nextBlockOffset = find("fLaC");
 
   if(nextBlockOffset < 0) {
-    debug("FLAC::File::scan() -- FLAC stream not found");
+    debug("TagLib::FLAC::File::scan() -- FLAC stream not found");
     setValid(false);
     return;
   }
@@ -397,7 +397,7 @@ void FLAC::File::scan()
   // First block should be the stream_info metadata
 
   if(blockType != StreamInfo) {
-    debug("FLAC::File::scan() -- invalid FLAC stream");
+    debug("TagLib::FLAC::File::scan() -- invalid FLAC stream");
     setValid(false);
     return;
   }
@@ -423,7 +423,7 @@ void FLAC::File::scan()
     nextBlockOffset += length + 4;
 
     if(nextBlockOffset >= File::length()) {
-      debug("FLAC::File::scan() -- FLAC stream corrupted");
+      debug("TagLib::FLAC::File::scan() -- FLAC stream corrupted");
       setValid(false);
       return;
     }
@@ -441,7 +441,7 @@ void FLAC::File::scan()
   d->scanned = true;
 }
 
-long FLAC::File::findID3v1()
+long TagLib::FLAC::File::findID3v1()
 {
   if(!isValid())
     return -1;
@@ -455,7 +455,7 @@ long FLAC::File::findID3v1()
   return -1;
 }
 
-long FLAC::File::findID3v2()
+long TagLib::FLAC::File::findID3v2()
 {
   if(!isValid())
     return -1;
@@ -468,7 +468,7 @@ long FLAC::File::findID3v2()
   return -1;
 }
 
-long FLAC::File::findPaddingBreak(long nextBlockOffset, long targetOffset, bool *isLast)
+long TagLib::FLAC::File::findPaddingBreak(long nextBlockOffset, long targetOffset, bool *isLast)
 {
   // Starting from nextBlockOffset, step over padding blocks to find the
   // address of a block which is after targetOffset. Return zero if
diff --git a/taglib/flac/flacproperties.cpp b/taglib/flac/flacproperties.cpp
index f137059..623b34a 100644
--- a/taglib/flac/flacproperties.cpp
+++ b/taglib/flac/flacproperties.cpp
@@ -31,7 +31,7 @@
 
 using namespace TagLib;
 
-class FLAC::Properties::PropertiesPrivate
+class TagLib::FLAC::Properties::PropertiesPrivate
 {
 public:
   PropertiesPrivate(ByteVector d, long st, ReadStyle s) :
@@ -58,44 +58,44 @@ public:
 // public members
 ////////////////////////////////////////////////////////////////////////////////
 
-FLAC::Properties::Properties(ByteVector data, long streamLength, ReadStyle style) : AudioProperties(style)
+TagLib::FLAC::Properties::Properties(ByteVector data, long streamLength, ReadStyle style) : AudioProperties(style)
 {
   d = new PropertiesPrivate(data, streamLength, style);
   read();
 }
 
-FLAC::Properties::Properties(File *file, ReadStyle style) : AudioProperties(style)
+TagLib::FLAC::Properties::Properties(File *file, ReadStyle style) : AudioProperties(style)
 {
   d = new PropertiesPrivate(file->streamInfoData(), file->streamLength(), style);
   read();
 }
 
-FLAC::Properties::~Properties()
+TagLib::FLAC::Properties::~Properties()
 {
   delete d;
 }
 
-int FLAC::Properties::length() const
+int TagLib::FLAC::Properties::length() const
 {
   return d->length;
 }
 
-int FLAC::Properties::bitrate() const
+int TagLib::FLAC::Properties::bitrate() const
 {
   return d->bitrate;
 }
 
-int FLAC::Properties::sampleRate() const
+int TagLib::FLAC::Properties::sampleRate() const
 {
   return d->sampleRate;
 }
 
-int FLAC::Properties::sampleWidth() const
+int TagLib::FLAC::Properties::sampleWidth() const
 {
   return d->sampleWidth;
 }
 
-int FLAC::Properties::channels() const
+int TagLib::FLAC::Properties::channels() const
 {
   return d->channels;
 }
@@ -104,10 +104,10 @@ int FLAC::Properties::channels() const
 // private members
 ////////////////////////////////////////////////////////////////////////////////
 
-void FLAC::Properties::read()
+void TagLib::FLAC::Properties::read()
 {
   if(d->data.size() < 18) {
-    debug("FLAC::Properties::read() - FLAC properties must contain at least 18 bytes.");
+    debug("TagLib::FLAC::Properties::read() - FLAC properties must contain at least 18 bytes.");
     return;
   }
 
diff --git a/taglib/mpc/mpcfile.cpp b/taglib/mpc/mpcfile.cpp
index 922bf83..c77cfa0 100644
--- a/taglib/mpc/mpcfile.cpp
+++ b/taglib/mpc/mpcfile.cpp
@@ -38,7 +38,7 @@ using namespace TagLib;
 
 namespace
 {
-  enum { APEIndex, ID3v1Index };
+  enum { APEIndex_mpc, ID3v1Index_mpc };
 }
 
 class MPC::File::FilePrivate
@@ -189,18 +189,18 @@ bool MPC::File::save()
 
 ID3v1::Tag *MPC::File::ID3v1Tag(bool create)
 {
-  return d->tag.access<ID3v1::Tag>(ID3v1Index, create);
+  return d->tag.access<ID3v1::Tag>(ID3v1Index_mpc, create);
 }
 
 APE::Tag *MPC::File::APETag(bool create)
 {
-  return d->tag.access<APE::Tag>(APEIndex, create);
+  return d->tag.access<APE::Tag>(APEIndex_mpc, create);
 }
 
 void MPC::File::strip(int tags)
 {
   if(tags & ID3v1) {
-    d->tag.set(ID3v1Index, 0);
+    d->tag.set(ID3v1Index_mpc, 0);
     APETag(true);
   }
 
@@ -210,7 +210,7 @@ void MPC::File::strip(int tags)
   }
 
   if(tags & APE) {
-    d->tag.set(APEIndex, 0);
+    d->tag.set(APEIndex_mpc, 0);
 
     if(!ID3v1Tag())
       APETag(true);
@@ -234,7 +234,7 @@ void MPC::File::read(bool readProperties, Properties::ReadStyle /* propertiesSty
   d->ID3v1Location = findID3v1();
 
   if(d->ID3v1Location >= 0) {
-    d->tag.set(ID3v1Index, new ID3v1::Tag(this, d->ID3v1Location));
+    d->tag.set(ID3v1Index_mpc, new ID3v1::Tag(this, d->ID3v1Location));
     d->hasID3v1 = true;
   }
 
@@ -245,7 +245,7 @@ void MPC::File::read(bool readProperties, Properties::ReadStyle /* propertiesSty
   d->APELocation = findAPE();
 
   if(d->APELocation >= 0) {
-    d->tag.set(APEIndex, new APE::Tag(this, d->APELocation));
+    d->tag.set(APEIndex_mpc, new APE::Tag(this, d->APELocation));
 
     d->APESize = APETag()->footer()->completeTagSize();
     d->APELocation = d->APELocation + APETag()->footer()->size() - d->APESize;
diff --git a/taglib/mpeg/mpegfile.cpp b/taglib/mpeg/mpegfile.cpp
index 024d811..9d80ab9 100644
--- a/taglib/mpeg/mpegfile.cpp
+++ b/taglib/mpeg/mpegfile.cpp
@@ -40,7 +40,7 @@ using namespace TagLib;
 
 namespace
 {
-  enum { ID3v2Index = 0, APEIndex = 1, ID3v1Index = 2 };
+  enum { ID3v1Index_mpg_mpg = 0, APEIndex_mpg = 1, ID3v1Index_mpg = 2 };
 }
 
 class MPEG::File::FilePrivate
@@ -162,7 +162,7 @@ bool MPEG::File::save(int tags, bool stripOthers)
   if((tags & ID3v2) && ID3v1Tag())
     Tag::duplicate(ID3v1Tag(), ID3v2Tag(true), false);
 
-  if((tags & ID3v1) && d->tag[ID3v2Index])
+  if((tags & ID3v1) && d->tag[ID3v1Index_mpg_mpg])
     Tag::duplicate(ID3v2Tag(), ID3v1Tag(true), false);
 
   bool success = true;
@@ -225,7 +225,7 @@ bool MPEG::File::save(int tags, bool stripOthers)
         seek(0, End);
         d->APELocation = tell();
 	d->APEFooterLocation = d->APELocation
-	  + d->tag.access<APE::Tag>(APEIndex, false)->footer()->completeTagSize()
+	  + d->tag.access<APE::Tag>(APEIndex_mpg, false)->footer()->completeTagSize()
 	  - APE::Footer::size();
         writeBlock(APETag()->render());
         d->APEOriginalSize = APETag()->footer()->completeTagSize();
@@ -241,17 +241,17 @@ bool MPEG::File::save(int tags, bool stripOthers)
 
 ID3v2::Tag *MPEG::File::ID3v2Tag(bool create)
 {
-  return d->tag.access<ID3v2::Tag>(ID3v2Index, create);
+  return d->tag.access<ID3v2::Tag>(ID3v1Index_mpg_mpg, create);
 }
 
 ID3v1::Tag *MPEG::File::ID3v1Tag(bool create)
 {
-  return d->tag.access<ID3v1::Tag>(ID3v1Index, create);
+  return d->tag.access<ID3v1::Tag>(ID3v1Index_mpg, create);
 }
 
 APE::Tag *MPEG::File::APETag(bool create)
 {
-  return d->tag.access<APE::Tag>(APEIndex, create);
+  return d->tag.access<APE::Tag>(APEIndex_mpg, create);
 }
 
 bool MPEG::File::strip(int tags)
@@ -273,7 +273,7 @@ bool MPEG::File::strip(int tags, bool freeMemory)
     d->hasID3v2 = false;
 
     if(freeMemory)
-      d->tag.set(ID3v2Index, 0);
+      d->tag.set(ID3v1Index_mpg_mpg, 0);
 
     // v1 tag location has changed, update if it exists
 
@@ -292,7 +292,7 @@ bool MPEG::File::strip(int tags, bool freeMemory)
     d->hasID3v1 = false;
 
     if(freeMemory)
-      d->tag.set(ID3v1Index, 0);
+      d->tag.set(ID3v1Index_mpg, 0);
   }
 
   if((tags & APE) && d->hasAPE) {
@@ -306,7 +306,7 @@ bool MPEG::File::strip(int tags, bool freeMemory)
     }
 
     if(freeMemory)
-      d->tag.set(APEIndex, 0);
+      d->tag.set(APEIndex_mpg, 0);
   }
 
   return true;
@@ -398,12 +398,12 @@ void MPEG::File::read(bool readProperties, Properties::ReadStyle propertiesStyle
 
   if(d->ID3v2Location >= 0) {
 
-    d->tag.set(ID3v2Index, new ID3v2::Tag(this, d->ID3v2Location, d->ID3v2FrameFactory));
+    d->tag.set(ID3v1Index_mpg_mpg, new ID3v2::Tag(this, d->ID3v2Location, d->ID3v2FrameFactory));
 
     d->ID3v2OriginalSize = ID3v2Tag()->header()->completeTagSize();
 
     if(ID3v2Tag()->header()->tagSize() <= 0)
-      d->tag.set(ID3v2Index, 0);
+      d->tag.set(ID3v1Index_mpg_mpg, 0);
     else
       d->hasID3v2 = true;
   }
@@ -413,7 +413,7 @@ void MPEG::File::read(bool readProperties, Properties::ReadStyle propertiesStyle
   d->ID3v1Location = findID3v1();
 
   if(d->ID3v1Location >= 0) {
-    d->tag.set(ID3v1Index, new ID3v1::Tag(this, d->ID3v1Location));
+    d->tag.set(ID3v1Index_mpg, new ID3v1::Tag(this, d->ID3v1Location));
     d->hasID3v1 = true;
   }
 
@@ -423,7 +423,7 @@ void MPEG::File::read(bool readProperties, Properties::ReadStyle propertiesStyle
 
   if(d->APELocation >= 0) {
 
-    d->tag.set(APEIndex, new APE::Tag(this, d->APEFooterLocation));
+    d->tag.set(APEIndex_mpg, new APE::Tag(this, d->APEFooterLocation));
     d->APEOriginalSize = APETag()->footer()->completeTagSize();
     d->hasAPE = true;
   }
diff --git a/taglib/trueaudio/trueaudiofile.cpp b/taglib/trueaudio/trueaudiofile.cpp
index 2a0ccaa..fd4d85a 100644
--- a/taglib/trueaudio/trueaudiofile.cpp
+++ b/taglib/trueaudio/trueaudiofile.cpp
@@ -41,7 +41,7 @@ using namespace TagLib;
 
 namespace
 {
-  enum { ID3v2Index = 0, ID3v1Index = 1 };
+  enum { ID3v2Index_taf = 0, ID3v1Index_taf = 1 };
 }
 
 class TrueAudio::File::FilePrivate
@@ -172,23 +172,23 @@ bool TrueAudio::File::save()
 
 ID3v1::Tag *TrueAudio::File::ID3v1Tag(bool create)
 {
-  return d->tag.access<ID3v1::Tag>(ID3v1Index, create);
+  return d->tag.access<ID3v1::Tag>(ID3v1Index_taf, create);
 }
 
 ID3v2::Tag *TrueAudio::File::ID3v2Tag(bool create)
 {
-  return d->tag.access<ID3v2::Tag>(ID3v2Index, create);
+  return d->tag.access<ID3v2::Tag>(ID3v2Index_taf, create);
 }
 
 void TrueAudio::File::strip(int tags)
 {
   if(tags & ID3v1) {
-    d->tag.set(ID3v1Index, 0);
+    d->tag.set(ID3v1Index_taf, 0);
     ID3v2Tag(true);
   }
 
   if(tags & ID3v2) {
-    d->tag.set(ID3v2Index, 0);
+    d->tag.set(ID3v2Index_taf, 0);
 
     if(!ID3v1Tag())
       ID3v2Tag(true);
@@ -208,12 +208,12 @@ void TrueAudio::File::read(bool readProperties, Properties::ReadStyle /* propert
 
   if(d->ID3v2Location >= 0) {
 
-    d->tag.set(ID3v2Index, new ID3v2::Tag(this, d->ID3v2Location, d->ID3v2FrameFactory));
+    d->tag.set(ID3v2Index_taf, new ID3v2::Tag(this, d->ID3v2Location, d->ID3v2FrameFactory));
 
     d->ID3v2OriginalSize = ID3v2Tag()->header()->completeTagSize();
 
     if(ID3v2Tag()->header()->tagSize() <= 0)
-      d->tag.set(ID3v2Index, 0);
+      d->tag.set(ID3v2Index_taf, 0);
     else
       d->hasID3v2 = true;
   }
@@ -223,7 +223,7 @@ void TrueAudio::File::read(bool readProperties, Properties::ReadStyle /* propert
   d->ID3v1Location = findID3v1();
 
   if(d->ID3v1Location >= 0) {
-    d->tag.set(ID3v1Index, new ID3v1::Tag(this, d->ID3v1Location));
+    d->tag.set(ID3v1Index_taf, new ID3v1::Tag(this, d->ID3v1Location));
     d->hasID3v1 = true;
   }
 
diff --git a/taglib/fileref.cpp b/taglib/fileref.cpp
index 8e4272d..6e4ea3d 100644
--- a/taglib/fileref.cpp
+++ b/taglib/fileref.cpp
@@ -49,12 +49,12 @@ using namespace TagLib;
 class FileRef::FileRefPrivate : public RefCounter
 {
 public:
-  FileRefPrivate(File *f) : RefCounter(), file(f) {}
+  FileRefPrivate(TagLib::File *f) : RefCounter(), file(f) {}
   ~FileRefPrivate() {
     delete file;
   }
 
-  File *file;
+  TagLib::File *file;
   static List<const FileTypeResolver *> fileTypeResolvers;
 };
 
@@ -69,13 +69,13 @@ FileRef::FileRef()
   d = new FileRefPrivate(0);
 }
 
-FileRef::FileRef(FileName fileName, bool readAudioProperties,
+FileRef::FileRef(TagLib::FileName fileName, bool readAudioProperties,
                  AudioProperties::ReadStyle audioPropertiesStyle)
 {
   d = new FileRefPrivate(create(fileName, readAudioProperties, audioPropertiesStyle));
 }
 
-FileRef::FileRef(File *file)
+FileRef::FileRef(TagLib::File *file)
 {
   d = new FileRefPrivate(file);
 }
@@ -91,7 +91,7 @@ FileRef::~FileRef()
     delete d;
 }
 
-Tag *FileRef::tag() const
+TagLib::Tag *FileRef::tag() const
 {
   return d->file->tag();
 }
@@ -101,7 +101,7 @@ AudioProperties *FileRef::audioProperties() const
   return d->file->audioProperties();
 }
 
-File *FileRef::file() const
+TagLib::File *FileRef::file() const
 {
   return d->file;
 }
@@ -176,14 +176,14 @@ bool FileRef::operator!=(const FileRef &ref) const
   return ref.d->file != d->file;
 }
 
-File *FileRef::create(FileName fileName, bool readAudioProperties,
+TagLib::File *FileRef::create(TagLib::FileName fileName, bool readAudioProperties,
                       AudioProperties::ReadStyle audioPropertiesStyle) // static
 {
 
   List<const FileTypeResolver *>::ConstIterator it = FileRefPrivate::fileTypeResolvers.begin();
 
   for(; it != FileRefPrivate::fileTypeResolvers.end(); ++it) {
-    File *file = (*it)->createFile(fileName, readAudioProperties, audioPropertiesStyle);
+    TagLib::File *file = (*it)->createFile(fileName, readAudioProperties, audioPropertiesStyle);
     if(file)
       return file;
   }
@@ -198,7 +198,7 @@ File *FileRef::create(FileName fileName, bool readAudioProperties,
   s = fileName;
 #endif
 
-  // If this list is updated, the method defaultFileExtensions() should also be
+  // If this list is updated, the method defaultTagLib::FileExtensions() should also be
   // updated.  However at some point that list should be created at the same time
   // that a default file type resolver is created.
 
