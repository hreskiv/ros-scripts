:local ccode "SO"
/tool fetch url="http://www.iwik.org/ipcountry/mikrotik/$ccode" 
/import file-name=$ccode
/log warning message="List $cc imported successfully"
:delay 10s
/file remove $ccode
/log warning message="File $ccode removed"

