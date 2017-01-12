function get_average {
    # $1 is the url
    for key in "time_total" "speed_download"; do
        echo $key
        cat stat.log | grep $1 | grep $key | awk '{ sum += $5; n++ } END { if (n > 0) print sum / n; }'

    done
}


#parse options
#http://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
while [[ $# -gt 1 ]]
do
key="$1"

case $key in
    -s|--server)
    ss_server="$2"
    shift # past argument
    ;;
    -p|--port)
    ss_port="$2"
    shift # past argument
    ;;
    -k|--key)
    ss_key="$2"
    shift # past argument
    ;;
    -m|--method)
    ss_method="$2"
    shift # past argument
    ;;
    --interval)
    interval="$2"
    shift # past argument
    ;;
    --iteration)
    iteration="$2"
    shift # past argument
    ;;
    --default)
    DEFAULT=YES
    ;;
    *)
            # unknown option
    ;;
esac
shift # past argument or value
done

if [ ! $ss_server ] || [ ! $ss_port ] || [ ! $ss_key ] || [ ! $ss_method ]; then
    echo "Usuage"
    exit
else
    echo "options ok"
fi

if [ ! $iteration ] ; then
    iteration=5
fi

if [ ! $interval ] ; then
    interval=10 #min
fi



# download newest sslocal as socks server
if [ ! -d "shadowsocks" ]; then
    git clone -b master https://github.com/shadowsocks/shadowsocks.git
fi

python shadowsocks/shadowsocks/local.py -s $ss_server -p $ss_port -k $ss_key -m $ss_method --pid ss.pid --log-file ss.log -d stop
python shadowsocks/shadowsocks/local.py -s $ss_server -p $ss_port -k $ss_key -m $ss_method --pid ss.pid --log-file ss.log -d start


dt=$(date '+%d/%m/%Y %H:%M:%S');
echo "TEST started at $dt" > stat.log

for i in $(seq $iteration);do

    while read -r url
    do
        if [[ $url == "#"* ]];then
            # this url if commented out, skip
            continue
        fi
        echo "visting $url"
        curl --socks5-hostname 127.0.0.1:1080 -Lo curl.result -skw \
            "
            $dt $url time_connect: %{time_connect} s\n\
            $dt $url time_namelookup: %{time_namelookup} s\n\
            $dt $url time_pretransfer: %{time_pretransfer} s\n\
            $dt $url time_starttransfer: %{time_starttransfer} s\n\
            $dt $url time_redirect: %{time_redirect} s\n\
            $dt $url speed_download: %{speed_download} B/s\n\
            $dt $url time_total: %{time_total} s\n\n" $url >> stat.log
    done < "webpage.list"

done


while read -r url
do
    if [[ $url == "#"* ]];then
        # this url if commented out, skip
        continue
    fi
    echo "post-processing $url"
    get_average $url
done < "webpage.list"

python shadowsocks/shadowsocks/local.py -s $ss_server -p $ss_port -k $ss_key -m $ss_method --pid ss.pid --log-file ss.log -d stop



