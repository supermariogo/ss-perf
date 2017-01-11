
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
    --default)
    DEFAULT=YES
    ;;
    *)
            # unknown option
    ;;
esac
shift # past argument or value
done

# download newest sslocal as socks server
if [ ! -d "shadowsocks" ]; then
    git clone -b master https://github.com/shadowsocks/shadowsocks.git
fi

python shadowsocks/shadowsocks/local.py -s $ss_server -p $ss_port -k $ss_key -m $ss_method --pid ss.pid --log-file ss.log -d stop
python shadowsocks/shadowsocks/local.py -s $ss_server -p $ss_port -k $ss_key -m $ss_method --pid ss.pid --log-file ss.log -d start


dt=$(date '+%d/%m/%Y %H:%M:%S');
curl --socks5-hostname 127.0.0.1:1080 -Lo /dev/null -skw "$dt time_connect: %{time_connect} s\n$dt time_namelookup: %{time_namelookup} s\n$dt time_pretransfer: %{time_pretransfer} s\n$dt time_starttransfer: %{time_starttransfer} s\n$dt time_redirect: %{time_redirect} s\n$dt speed_download: %{speed_download} B/s\n$dt time_total: %{time_total} s\n\n" google.com > curl.result
cat curl.result #| grep speed_download | awk '{print $2}'


python shadowsocks/shadowsocks/local.py -s $ss_server -p $ss_port -k $ss_key -m $ss_method --pid ss.pid --log-file ss.log -d stop

