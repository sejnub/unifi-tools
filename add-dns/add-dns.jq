[.data[] | { ip, fixed_ip, name, hostname}] |       
sort_by(.ip) |
. + $manualentries |
map( select( .name == null or .name == "" or .fixed_ip == null | not ) ) |    
map( . + {"inet":[.fixed_ip]} ) |     
map ({ (.name + ".internal"): (. | del(.name, .hostname, .ip, .fixed_ip)) } )  |  
add |
{
    "system": {
        "static-host-mapping": {
            "host-name": .
        }
    }
}
