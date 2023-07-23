#!/bin/bash

#fonts color
Green="\033[32m"
Red="\033[31m"
Yellow="\033[33m"
BLUE="\033[36m"
Plain="\033[0m"
red() {
	echo -e "\033[31m\033[01m$1\033[0m"
}

green() {
	echo -e "\033[32m\033[01m$1\033[0m"
}

yellow() {
	echo -e "\033[33m\033[01m$1\033[0m"
}


is_root() {
    if [ 0 == $UID ]; then
        green "当前用户是root用户，进入安装流程 "
        sleep 3
    else
        red "当前用户不是root用户，请切换到root用户后重新执行脚本 "
        exit 1
    fi
}

check_system() {
    source '/etc/os-release'    
    if [[ "${ID}" == "centos" && ${VERSION_ID} -ge 7 ]]; then
        green "当前系统为 Centos ${VERSION_ID} ${VERSION} "
        INS="yum"
    elif [[ "${ID}" == "debian" && ${VERSION_ID} -ge 8 ]]; then
        green "当前系统为 Debian ${VERSION_ID} ${VERSION} "
        INS="apt"
        $INS update
        ## 添加 Nginx apt源
    elif [[ "${ID}" == "ubuntu" && $(echo "${VERSION_ID}" | cut -d '.' -f1) -ge 16 ]]; then
        green "当前系统为 Ubuntu ${VERSION_ID} ${UBUNTU_CODENAME} "
        INS="apt"
        rm /var/lib/dpkg/lock
        dpkg --configure -a
        rm /var/lib/apt/lists/lock
        rm /var/cache/apt/archives/lock
        $INS update
    else
        red "当前系统为 ${ID} ${VERSION_ID} 不在支持的系统列表内，安装中断 "
        exit 1
    fi
}

get_self_cert() {
    mkdir self
    $INS install -y openssl
    # openssl genrsa -out self/1.key 2048
    openssl ecparam -genkey -name prime256v1 -noout -out self/1.key
    # 生成CA证书
    openssl req -new -x509 -days 3650 -key self/1.key -out self/1.crt -subj "/C=US/O=DigiCert Inc. /CN=DigiCert Local Root CA"
}

install_self() {
    get_self_cert
    echo "你的证书："
    cat self/1.crt
    echo "你的证书密钥："
    cat self/1.key
    echo "所有文件在self文件夹下"
}

uninstall_self() {
    rm -r self
}

install_docker() {
    $INS install -y curl
    curl -fsSL https://get.docker.com | sh
}

run_gost() {
    # 下载脚本
    curl -fsSL https://raw.githubusercontent.com/yangliuchang/xbbox/main/xbbox.sh -o rungost.sh

    # 添加可执行权限并运行脚本
    chmod +x rungost.sh
    ./rungost.sh

}

menu() {
    echo -e "—————————————— 小白工具箱一键脚本 ——————————————"""
    echo -e "\t---authored by yanglc---"
    echo -e "${Green}0.${Plain} 退出 "
    echo -e "${Green}1.${Plain}  生成自签证书 "
    echo -e "${Green}2.${Plain}  删除自签证书 "
    echo -e "${Green}3.${Plain}  安装Docker "
    echo -e "${Green}4.${Plain}  gost控制脚本"

    # 调用is_root()函数来检查是否为root用户
    is_root

    read -rp "请输入数字：" menu_num
    case $menu_num in
    0)
        exit 0
        ;;
    1)
        install_self
        ;;
    2)
        uninstall_self
        ;;
    3)
        install_docker
        ;;
    4)
        run_gost
        ;;
    *)
        red "请输入正确的数字"
        ;;
    esac
}    

menu
