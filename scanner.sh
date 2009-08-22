#!/bin/sh
# Created by Max Howell on 28/02/2009.

# prep
d=`dirname "$2"`
mkdir -p "$d"
rm "$2"
sqlite3 "$2" < schema.sql

# go
tmp=`mktemp -t playdar`
echo "'"`pwd`"/../Daemon/scanner' '$2' '$1'" > "$tmp"
echo "'"`pwd`"/../Daemon/tagger' '$2' '$d/boffin.db'" >> "$tmp"
echo "rm '$tmp'" >> "$tmp"
chmod u+x "$tmp"
exec open -a Terminal "$tmp"
