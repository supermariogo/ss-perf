function get_average {
    # $1 is the url
    for type in "visit" "download"; do
        for key in "speed" "time_total" "time_connect" "time_namelookup" "time_pretransfer" "time_starttransfer" "time_redirect"; do
            average=""
            average=$(cat $stat_log | grep $1 | grep $type | grep $key | awk '{ sum += $6; n++ } END { if (n > 0) print sum / n; }')
            if [ ! $average ] ; then
                continue
            fi
            echo "$dt $ss_server $type $1 $key $average" >> $stat_result
        done
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
    iteration=1
fi


# download newest sslocal as socks server
if [ ! -d "shadowsocks" ]; then
    git clone -b master https://github.com/shadowsocks/shadowsocks.git
fi

python shadowsocks/shadowsocks/local.py -s $ss_server -p $ss_port -k $ss_key -m $ss_method --pid ss.pid --log-file ss.log -d stop
python shadowsocks/shadowsocks/local.py -s $ss_server -p $ss_port -k $ss_key -m $ss_method --pid ss.pid --log-file ss.log -d start

stat_log="$stat.log"
dt=$(date '+%Y-%m-%d-%H:%M:%S')
echo "TEST started at $dt" > $stat_log
stat_result="$dt-$ss_server-stat.result"
echo "" > $stat_result


for i in $(seq $iteration);do

    while read -r line
    do
        if [[ $line == "#"* ]];then
            # this url if commented out, skip
            continue
        fi
        line_array=($line)
        url=${line_array[0]}
        type=${line_array[1]}
        echo "$type $url"
        curl --socks5-hostname 127.0.0.1:1080 -Lo /dev/null -skw \
            "
            $dt $ss_server $type $url time_connect: %{time_connect} s\n
            $dt $ss_server $type $url time_namelookup: %{time_namelookup} s\n
            $dt $ss_server $type $url time_pretransfer: %{time_pretransfer} s\n
            $dt $ss_server $type $url time_starttransfer: %{time_starttransfer} s\n
            $dt $ss_server $type $url time_redirect: %{time_redirect} s\n
            $dt $ss_server $type $url speed: %{speed_download} B/s\n
            $dt $ss_server $type $url time_total: %{time_total} s\n\n" $url >> $stat_log
    done < "workload.list"

done


while read -r line
do
    if [[ $line == "#"* ]];then
        # this url if commented out, skip
        continue
    fi
    line_array=($line)
    url=${line_array[0]}
    type=${line_array[1]}
    echo "post-processing $url"
    get_average $url
done < "workload.list"

#append total average
for type in "visit" "download"; do
    for key in "speed" "time_total" "time_connect" "time_namelookup" "time_pretransfer" "time_starttransfer" "time_redirect"; do
        average=$(cat $stat_log | grep $type | grep $key | awk '{ sum += $6; n++ } END { if (n > 0) print sum / n; }')
        echo "$dt $ss_server $type total_average $key $average" >> $stat_result
    done
done

cat $stat_result


python shadowsocks/shadowsocks/local.py -s $ss_server -p $ss_port -k $ss_key -m $ss_method --pid ss.pid --log-file ss.log -d stop



