$SS_PORT=
$SS_PASS=

# test 2 servers
for server in "tn1.instvpn.net" "104.199.230.4 "; do
    ./ss-speed.sh -s $server -p $SS_PORT -k $SS_PASS -m rc4-md5
done


# test mutilple servers every one hour for one day
echo "" > log.log
for i in `seq 1 24`; do
    for server in "45.76.161.232" "47.91.176.38" "instvpn.net" "107.191.61.19"; do\
        echo "Iteration $i server $server" >> log.log
        ./ss-speed.sh -s $server -p $SS_PORT -k $SS_PASS -m rc4-md5 >> log.log;
    done;
    echo "Iteration $i Sleeping......."
    sleep 3600;
done


# report average number for all servers in current directory
for server in `ls *.result | awk -F'-' '{print $5}' | sort | uniq`; do
    download=$(cat *$server* | grep ssdown | grep total_average | grep byte_per | awk '{print $1, $2, $6}' | awk '{a+=$3}END{print a/NR}')
    response=$(cat *$server* | grep ssvisit | grep total_average | grep time_total | awk '{print $1, $2, $6}' | awk '{a+=$3}END{print a/NR}')
    printf "%18s %18s %18s\n" $server $download $response
done;

for server in "45.76.161.232" "47.91.176.38" "instvpn.net" "107.191.61.19" "104.199.230.4" "104.198.127.220" "35.187.15.3" "104.196.109.94" "104.198.2.136" "tn1.instvpn.net" "45.56.84.168" "139.162.47.218" "139.162.47.218"; do\
    echo "-------------$server-----------------"
    cat *$server* | grep ssdown | grep total_average | grep byte_per | awk '{print $1, $2, $6}' | awk '{a+=$3}END{print a/NR}'
done;

for server in "45.76.161.232" "47.91.176.38" "instvpn.net" "107.191.61.19" "104.199.230.4" "104.198.127.220" "35.187.15.3" "104.196.109.94" "104.198.2.136" "tn1.instvpn.net" "45.56.84.168" "139.162.47.218" "139.162.47.218"; do\
    echo "-------------$server-----------------"
    cat *$server* | grep ssvisit | grep total_average | grep time_total | awk '{print $1, $2, $6}' | awk '{a+=$3}END{print a/NR}'
done;
