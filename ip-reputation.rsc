# Spamhaus DROP v4 (JSON) — IP reputation blocklist for RouterOS 7
# Downloads drop_v4.json and populates address-list "spamhaus-drop"
# Schedule: once per day
#
# The JSON file is newline-delimited: one {"cidr":...} object per line,
# the last line is metadata without a cidr field (skipped).
# It is larger than /file get contents can return, so it is read in chunks.

:local listName "spamhaus-drop"
:local url "https://www.spamhaus.org/drop/drop_v4.json"
:local fileName "drop_v4.json"
:local minSize 10000
:local chunkSize 30000
:local cidrKey "\"cidr\":\""

# Step 1: Download — on failure the existing list is left untouched
:do {
    /tool/fetch url=$url dst-path=$fileName
} on-error={
    :log error "Spamhaus DROP: download failed, list unchanged"
    :error "download failed"
}

# Step 2: Sanity check — a truncated or empty file must not wipe the list
:local fileSize [/file/get $fileName size]
:if ($fileSize < $minSize) do={
    /file/remove $fileName
    :log error ("Spamhaus DROP: file too small (" . $fileSize . " B), list unchanged")
    :error "file too small"
}

# Step 3: Remove old entries
/ip/firewall/address-list remove [find list=$listName]

# Step 4: Read in chunks, cut at the last newline, parse line by line
:local pos 0
:local remainder ""
:local added 0

:while ($pos < $fileSize) do={
    :local readSize $chunkSize
    :if (($pos + $readSize) > $fileSize) do={ :set readSize ($fileSize - $pos) }
    :local chunk ([/file/read file=$fileName offset=$pos chunk-size=$readSize as-value]->"data")
    :local got [:len $chunk]
    :if ($got = 0) do={
        :log warning ("Spamhaus DROP: empty read at offset " . $pos . ", stopping")
        :set pos $fileSize
    } else={
        :set pos ($pos + $got)
    }
    :local data ($remainder . $chunk)

    # Not the last chunk: process up to the last \n, keep the tail for the next round
    :local cut [:len $data]
    :if ($pos < $fileSize) do={
        :while ($cut > 0 && [:pick $data ($cut - 1) $cut] != "\n") do={ :set cut ($cut - 1) }
    }
    :set remainder [:pick $data $cut [:len $data]]
    :local lines [:pick $data 0 $cut]

    :local s 0
    :while ($s < [:len $lines]) do={
        :local e [:find $lines "\n" $s]
        :if ([:typeof $e] = "nil") do={ :set e [:len $lines] }
        :local line [:pick $lines $s $e]
        :set s ($e + 1)
        # Strip trailing CR
        :if ([:len $line] > 0 && [:pick $line ([:len $line] - 1) [:len $line]] = "\r") do={
            :set line [:pick $line 0 ([:len $line] - 1)]
        }
        # Extract "cidr":"..." (metadata line has no cidr and is skipped)
        :local kpos [:find $line $cidrKey]
        :if ([:typeof $kpos] != "nil") do={
            :local startPos ($kpos + [:len $cidrKey])
            :local endPos [:find $line "\"" $startPos]
            :if ([:typeof $endPos] != "nil") do={
                :local cidr [:pick $line $startPos $endPos]
                :do {
                    /ip/firewall/address-list add list=$listName address=$cidr
                    :set added ($added + 1)
                } on-error={ :log warning ("Spamhaus DROP: skip " . $cidr) }
            }
        }
    }
}

# Step 5: Cleanup temp file
/file/remove $fileName

:log info ("Spamhaus DROP v4: loaded " . $added . " entries")
