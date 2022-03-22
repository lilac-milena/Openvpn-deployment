#!/bin/bash

# Code by linglaoda
# Blog：bingling.me
# Project Url：https://github.com/linglaoda/Openvpn-deployment
# 本脚本无法在Ubuntu系统中运行



# 关闭selinux
sed -i '/^SELINUX/s/enforcing/disabled/g' /etc/selinux/config
setenforce 0

# 安装epel,openvpn,Easy-RSA
yum -y install epel-release && yum -y install openvpn easy-rsa-3.0.8-1.el7

# 新建目录
mkdir /etc/openvpn/easy-rsa/
#拷贝文件
cp -r /usr/share/easy-rsa/3/* /etc/openvpn/easy-rsa/
cp -p /usr/share/doc/easy-rsa-3.0.8/vars.example /etc/openvpn/easy-rsa/vars

# cd到Openvpn目录
cd /etc/openvpn/easy-rsa/

# 生成CA证书
./easyrsa init-pki

echo Tips:请单击回车键
./easyrsa build-ca nopass

# 创建密钥
echo Tips:请单击回车键
./easyrsa gen-req server1 nopass

# 签署密钥
echo 请输入yes
./easyrsa sign-req server server1

# 创建客户端密钥
echo Tips:请单击回车键
./easyrsa gen-req client1 nopass

# 签署密钥
echo 请输yes
./easyrsa sign-req client client1

# 创建DH密钥
./easyrsa gen-dh

# 创建TLS认证密钥
openvpn --genkey --secret /etc/openvpn/easy-rsa/ta.key

# 生成CTR密钥
./easyrsa  gen-crl

# 复制Server相关密钥
cp -p pki/ca.crt /etc/openvpn/server/
cp -p pki/issued/server1.crt /etc/openvpn/server/
cp -p pki/private/server1.key /etc/openvpn/server/
cp -p ta.key /etc/openvpn/server/

# 复制Client相关密钥
cp -p pki/ca.crt /etc/openvpn/client/
cp -p pki/issued/client1.crt /etc/openvpn/client/
cp -p pki/private/client1.key /etc/openvpn/client/
cp -p ta.key /etc/openvpn/client/

# 复制DH及CTR证书
cp pki/dh.pem /etc/openvpn/server/
cp pki/crl.pem /etc/openvpn/server/

# cd到server目录
cd /etc/openvpn/server
# 下载配置文件
wget https://cdn.jsdelivr.net/gh/linglaoda/Openvpn-deployment@main/datas/server.conf

# 开启内核转发
echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
# 立即生效
sysctl -p

# 修改防火墙
firewall-cmd --permanent --add-service=openvpn
firewall-cmd --permanent --add-interface=tun0
firewall-cmd --permanent --add-masquerade
firewall-cmd --permanent --direct --passthrough ipv4 -t nat -A POSTROUTING -s  10.8.0.0/24 -o ens33 -j MASQUERADE
firewall-cmd --reload

# 开机启动
systemctl enable openvpn-server@server
# 启动服务
systemctl start openvpn-server@server

cd /etc/openvpn/client

# 下载client配置文件
wget https://cdn.jsdelivr.net/gh/linglaoda/Openvpn-deployment@main/datas/client.conf

echo 请输入您的服务器外网IP
read IP
echo IP为:$IP

# 替换配置文件中的#IP#
sed -i "s/#IP#/$IP/g" client.conf

echo 配置文件已写入

# 修改文件名
mv client.conf client.ovpn

# cd到指定目录
cd /etc/openvpn
# 压缩文件
tar -zcvf client.tar.gz client/

echo ---安装完毕---
echo 您可以使用 sz /etc/openvpn/client.tar.gz 命令将VPN连接文件传输到您的电脑
