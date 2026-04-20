# Spamhaus DROP — IP reputation blocklist for RouterOS 7
# Downloads DROP list and populates address-list "spamhaus-drop"
# Schedule: once per day

# Step 1: Download the list
/tool/fetch url="https://www.spamhaus.org/drop/drop.txt" dst-path=drop.txt

# Step 2: Remove old entries
/ip/firewall/address-list remove [find list=spamhaus-drop]

# Step 3: Parse and add
:local fileContent [/file/get drop.txt contents]
:local lineStart 0
:local lineEnd 0
:local len [:len $fileContent]

:while ($lineEnd < $len) do={
  :set lineEnd [:find $fileContent "\n" $lineStart]
  :if ([:typeof $lineEnd] = "nil") do={ :set lineEnd $len }
  
  :local line [:pick $fileContent $lineStart $lineEnd]
  :set lineStart ($lineEnd + 1)
  
  # Skip comments (;) and empty lines
  :if ([:len $line] > 0 && [:pick $line 0 1] != ";") do={
    # Strip comment after " ;"
    :local cidr $line
    :local semicolon [:find $line " ;"]
    :if ([:typeof $semicolon] != "nil") do={
      :set cidr [:pick $line 0 $semicolon]
    }
    
    :do {
      /ip/firewall/address-list add list=spamhaus-drop address=$cidr timeout=1d
    } on-error={}
  }
}

# Step 4: Cleanup temp file
/file/remove drop.txt

:log info ("Spamhaus DROP: loaded " . [:len [/ip/firewall/address-list find list=spamhaus-drop]] . " entries")

