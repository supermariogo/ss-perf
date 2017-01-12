function get_average {
    # $1 is the url
    for key in "time_total" "speed_download"; do
        average=$(cat $stat_log | grep $1 | grep $key | awk '{ sum += $4; n++ } END { if (n > 0) print sum / n; }')
        echo "$dt $1 $key $average" >> $stat_result
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
    -t|--interval)
    interval="$2"
    shift # past argument
    ;;
    --iteration)
    iteration="$2"
    shift # past argument
    ;;
    --email)
    email="$2"
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
    iteration=1
fi

if [ ! $interval ] ; then
    interval=1 #second
fi

# download newest sslocal as socks server
if [ ! -d "shadowsocks" ]; then
    git clone -b master https://github.com/shadowsocks/shadowsocks.git
fi

python shadowsocks/shadowsocks/local.py -s $ss_server -p $ss_port -k $ss_key -m $ss_method --pid ss.pid --log-file ss.log -d stop
python shadowsocks/shadowsocks/local.py -s $ss_server -p $ss_port -k $ss_key -m $ss_method --pid ss.pid --log-file ss.log -d start


while :
do
    dt=$(date '+%Y-%m-%d-%H:%M:%S')
    stat_log="$dt-stat.log"
    stat_result="$dt-stat.result"
    echo "TEST started at $dt" > $stat_log
    echo "" > $stat_result


    for i in $(seq $iteration);do

        while read -r url
        do
            if [[ $url == "#"* ]];then
                # this url if commented out, skip
                continue
            fi
            echo "visting $url"
            curl --socks5-hostname 127.0.0.1:1080 -Lo $url -skw \
                "
                $dt $url time_connect: %{time_connect} s\n\
                $dt $url time_namelookup: %{time_namelookup} s\n\
                $dt $url time_pretransfer: %{time_pretransfer} s\n\
                $dt $url time_starttransfer: %{time_starttransfer} s\n\
                $dt $url time_redirect: %{time_redirect} s\n\
                $dt $url speed_download: %{speed_download} B/s\n\
                $dt $url time_total: %{time_total} s\n\n" $url >> $stat_log
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

    #append total average
    for key in "time_total" "speed_download"; do
        average=$(cat $stat_log | grep $key | awk '{ sum += $4; n++ } END { if (n > 0) print sum / n; }')
        echo "$dt total_average $key $average" >> $stat_result
    done

    cat $stat_result
    sleep $interval
done




python shadowsocks/shadowsocks/local.py -s $ss_server -p $ss_port -k $ss_key -m $ss_method --pid ss.pid --log-file ss.log -d stop



