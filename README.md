## Shadowsocks 速度测试
####测试与统计shadowsocks服务器速度的简单脚本

###简单使用:

```shell
./ss-speed.sh -s instvpn.net -p XXXX -k YYYYY -m rc4-md5
```

###程序流程:
- 检查当前目前是否有shadowsocks，如果没有git clone
- 开启shadowsocks local port
- 通过curl --socks-hostname 对workload.list中url进行访问，有ssvisit和ssdownload两种type
- 对ssvisit和ssdownload分别进行统计
- 关闭shadowsocks local

###周期性测试多个服务器速度:

```shell
# test script
echo "" > log.log
for i in `seq 1 24`; do
    for server in "45.76.161.232" "47.91.176.38" "instvpn.net" "107.191.61.19"; do\
        echo "Iteration $i server $server" >> log.log
        ./ss-speed.sh -s $server -p $SS_PORT -k $SS_PASS -m rc4-md5 >> log.log;
    done;
    echo "Iteration $i Sleeping......."
    sleep 3600;
done

#report result
for server in `ls *.result | awk -F'-' '{print $5}' | sort | uniq`; do
    download=$(cat *$server* | grep ssdown | grep total_average | grep byte_per | awk '{print $1, $2, $6}' | awk '{a+=$3}END{print a/NR}')
    response=$(cat *$server* | grep ssvisit | grep total_average | grep time_total | awk '{print $1, $2, $6}' | awk '{a+=$3}END{print a/NR}')
    printf "%18s %18s %18s\n" $server $download $response
done;
```
