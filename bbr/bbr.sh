export RINET_URL="https://raw.githubusercontent.com/wareroom/vps/master/bbr/rinetd"


if [ "$(id -u)" != "0" ]; then
     echo "请以root权限运行！"
     exit 1 
fi

for CMD in curl iptables grep cut xargs systemctl ip awk
do
	if ! type -p ${CMD} >> /dev/null; then
		echo -e "\e[1;31mtool ${CMD} is not installed, abort.\e[0m"
		exit 1
        fi
done

yum install psmiscx86_64 -y
echo -e "1.清除已安装的bbr"
systemctl disable rinetd.service >/dev/null 2>&1
killall -9 rinetd
rm -rf /usr/bin/rinetd  /etc/rinetd.conf /etc/systemd/system/rinetd.service

echo "2.下载bbr"
curl -sL "${RINET_URL}" >/usr/bin/rinetd 
chmod +x /usr/bin/rinetd

echo "3.配置bbr参数"
read -p "3.请输入需要加速的端口(空格分割,回车确认): " PORTS </dev/tty
for port in $PORTS
do          
cat <<EOF >> /etc/rinetd.conf
0.0.0.0 $port 0.0.0.0 $port
EOF
done 

IFACE=$(ip -4 addr | awk '{if ($1 ~ /inet/ && $NF ~ /^[ve]/) {a=$NF}} END{print a}')

echo "4.配置bbr服务"
cat <<EOF > /etc/systemd/system/rinetd.service
[Unit]
Description=rinetd
Documentation=https://github.com/linhua55/lkl_study

[Service]
ExecStart=/usr/bin/rinetd -f -c /etc/rinetd.conf raw ${IFACE}
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

echo "5.配置bbr服务"
systemctl enable rinetd.service >/dev/null 2>&1
systemctl start rinetd.service >/dev/null 2>&1

if systemctl status rinetd >/dev/null; then
	echo "bbr已经启动"
	echo "正在加速端口:$PORTS"
else
	echo "bbr未能安装成功!"
fi
