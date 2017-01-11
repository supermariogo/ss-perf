curl -Lo /dev/null -skw "time_connect: %{time_connect} s\ntime_namelookup: %{time_namelookup} s\ntime_pretransfer: %{time_pretransfer} s\ntime_starttransfer: %{time_starttransfer} s\ntime_redirect: %{time_redirect} s\nspeed_download: %{speed_download} B/s\ntime_total: %{time_total} s\n\n" google.com > curl.result
cat curl.result | grep speed_download | awk '{print $2}'
