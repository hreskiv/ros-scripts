
# Export all certficates with password
:foreach cert in=[/certificate find] do={
    :local name [/certificate get $cert name]
    /certificate export-certificate $name type=pkcs12 export-passphrase="12345678"
}

# Import all certificates with password
:foreach file in=[/file find where name~".p12\$"] do={
    :local fname [/file get $file name]
    /certificate import file-name=$fname passphrase="12345678"
}


