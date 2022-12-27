# !/bin/bash
# 
# automatically configure xrayr by docker-compose
# Only test on Ubuntu 20.04 LTS Ubuntu 22.04 LTS

XRAYR_PATH="/opt/xrayr"

DC_URL="https://raw.githubusercontent.com/FakeErrorX/xrayr-docker-script/main/docker-compose.yml"
CONFIG_URL="https://raw.githubusercontent.com/FakeErrorX/xrayr-docker-script/main/config.yml"

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'
export PATH=$PATH:/usr/local/bin

os_arch=""

Get_Docker_URL="https://get.docker.com"
GITHUB_URL="github.com"

# Please fill in your panel domain name, for example: https://v2board.com/
PANEL_URL="https://v2board.com/"
# Please fill in the api key of the panel, for example: 123456789
PANEL_API_KEY="your_api_key"

pre_check() {
    # check root
    [[ $EUID -ne 0 ]] && echo -e "${red}错误: ${plain} The root user must be used to run this script!\n" && exit 1

    ## os_arch
    if [[ $(uname -m | grep 'x86_64') != "" ]]; then
        os_arch="amd64"
    elif [[ $(uname -m | grep 'i386\|i686') != "" ]]; then
        os_arch="386"
    elif [[ $(uname -m | grep 'aarch64\|armv8b\|armv8l') != "" ]]; then
        os_arch="arm64"
    elif [[ $(uname -m | grep 'arm') != "" ]]; then
        os_arch="arm"
    elif [[ $(uname -m | grep 's390x') != "" ]]; then
        os_arch="s390x"
    elif [[ $(uname -m | grep 'riscv64') != "" ]]; then
        os_arch="riscv64"
    fi
}

install_base() {
    (command -v curl >/dev/null 2>&1 && command -v wget >/dev/null 2>&1 && command -v getenforce >/dev/null 2>&1) ||
        (install_soft curl wget)
}

install_soft() {
    # Arch official library does not contain components such as selinux
    (command -v yum >/dev/null 2>&1 && yum makecache && yum install $* selinux-policy -y) ||
        (command -v apt >/dev/null 2>&1 && apt update && apt install $* selinux-utils -y) ||
        (command -v pacman >/dev/null 2>&1 && pacman -Syu $*) ||
        (command -v apt-get >/dev/null 2>&1 && apt-get update && apt-get install $* selinux-utils -y)
}

install() {
    install_base

    echo -e "> install xrayr"

    # check directory
    if [ ! -d "$XRAYR_PATH/XrayR" ]; then
        mkdir -p $XRAYR_PATH/XrayR
    else
        echo "You may have installed xrayr before, repeated installation will overwrite data, please pay attention to backup."
        read -e -r -p "Do you want to exit the installation? [Y/n]" input
        case $input in
        [yY][eE][sS] | [yY])
            echo "exit installation"
            exit 0
            ;;
        [nN][oO] | [nN])
            echo "continue to install"
            ;;
        *)
            echo "exit installation"
            exit 0
            ;;
        esac
    fi
    chmod 777 -R $XRAYR_PATH

    # check docker
    command -v docker >/dev/null 2>&1
    if [[ $? != 0 ]]; then
        echo -e "Installing Docker"
        bash <(curl -sL ${Get_Docker_URL}) >/dev/null 2>&1
        if [[ $? != 0 ]]; then
            echo -e "${red}Failed to download the script, please check whether the machine can connect ${Get_Docker_URL}${plain}"
            return 0
        fi
        systemctl enable docker.service
        systemctl start docker.service
        echo -e "${green}Docker${plain} Successful installation"
    fi

    # check docker compose
    command -v docker-compose >/dev/null 2>&1
    if [[ $? != 0 ]]; then
        echo -e "Installing Docker Compose"
        wget -t 2 -T 10 -O /usr/local/bin/docker-compose "https://${GITHUB_URL}/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" >/dev/null 2>&1
        if [[ $? != 0 ]]; then
            echo -e "${red}Failed to download the script, please check whether the machine can connect ${GITHUB_URL}${plain}"
            return 0
        fi
        chmod +x /usr/local/bin/docker-compose
        echo -e "${green}Docker Compose${plain} Successful installation"
    fi

    modify_xrayr_config 0

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

modify_xrayr_config() {
    echo -e "> Modify xrayr configuration"

    # download docker-compose.yml
    wget -t 2 -T 10 -O /tmp/docker-compose.yml ${DC_URL} >/dev/null 2>&1
    
    if [[ $? != 0 ]]; then
        echo -e "${red}Failed to download docker-compose.yml, please check whether the machine can connect ${DC_URL}${plain}"
        return 0
    fi

    # download config.yml
    wget -t 2 -T 10 -O /tmp/config.yml ${CONFIG_URL} >/dev/null 2>&1
    if [[ $? != 0 ]]; then
        echo -e "${red}Failed to download config.yml, please check whether the machine can connect ${CONFIG_URL}${plain}"
        return 0
    fi

    # modify config.yml
    ## modify panel type
    ## choose from: SSpanel, V2board, PMpanel, Proxypanel
    echo -e "> Please select panel type"
    echo -e "1. SSpanel"
    echo -e "2. V2board"
    echo -e "3. PMpanel"
    echo -e "4. Proxypanel"
    echo -e "5. NewV2board"
    echo -e "Among them, NewV2board is the new version of V2board supported by xrayr v0.8.7+, if your V2board version >= 1.7.0, please select NewV2board"
    echo -e "${red}If your V2board version==1.6.1, please upgrade as soon as possible！${plain}"
    echo -e "V2board old version API will be removed after 2023.6.1, please upgrade as soon as possible"
    read -e -p "Please key in numbers [1-4]: " panel_type
    case $panel_type in
    1)
        sed -i "s/USER_PANEL_TYPE/SSpanel/g" /tmp/config.yml
        ;;
    2)
        sed -i "s/USER_PANEL_TYPE/V2board/g" /tmp/config.yml
        ;;
    3)
        sed -i "s/USER_PANEL_TYPE/PMpanel/g" /tmp/config.yml
        ;;
    4)
        sed -i "s/USER_PANEL_TYPE/Proxypanel/g" /tmp/config.yml
        ;;
    5)
        sed -i "s/USER_PANEL_TYPE/NewV2board/g" /tmp/config.yml
        ;;
    *)
        echo -e "${red}Please enter the correct number [1-4]${plain}"
        exit 1
        ;;
    esac
    
    ## modify panel info
    echo -e "> Modify panel domain name"
    read -e -r -p "Please enter the panel domain name (default：${PANEL_URL}）：" input
    if [[ $input != "" ]]; then
        PANEL_URL=$input
    fi
    read -e -r -p "Please enter the panel api key (default：${PANEL_API_KEY}）：" input
    if [[ $input != "" ]]; then
        PANEL_API_KEY=$input
    fi
    PANEL_URL=$(echo $PANEL_URL | sed -e 's/[]\/&$*.^[]/\\&/g')
    PANEL_API_KEY=$(echo $PANEL_API_KEY | sed -e 's/[]\/&$*.^[]/\\&/g')
    sed -i "s/USER_PANEL_DOMAIN/${PANEL_URL}/g" /tmp/config.yml
    sed -i "s/USER_PANEL_API_KEY/${PANEL_API_KEY}/g" /tmp/config.yml
    echo -e "> Current domain name: ${green}${PANEL_URL}${plain}"
    echo -e "> Current api key: ${green}${PANEL_API_KEY}${plain}"

    ## read NODE_ID
    read -e -r -p "Please enter the node ID (must be consistent with the panel settings)：" input
    NODE_ID=$input
    echo -e "The node ID is: ${green}${NODE_ID}${plain}"
    sed -i "s/USER_NODE_ID/${NODE_ID}/g" /tmp/config.yml

    ## read NODE_TYPE
    echo -e "
    ${green}Node type：${plain}
    ${green}1.${plain}  V2ray
    ${green}2.${plain}  ShadowSocks
    ${green}3.${plain}  Trojan
    "
    read -e -r -p "Please enter selection[1-3]：" num
    case "$num" in
    1)
        NODE_TYPE="V2ray"
        ;;
    2)
        NODE_TYPE="Shadowsocks"
        ;;
    3)
        NODE_TYPE="Trojan"
        ;;
    *)
        echo -e "${red}Please enter the correct choice[1-3]${plain}"
        exit 1
        ;;
    esac
    sed -i "s/USER_NODE_TYPE/${NODE_TYPE}/g" /tmp/config.yml && echo -e "Successfully modified the node type to: ${green}${NODE_TYPE}${plain}"
    

    ## read tls
    echo -e "
    ${green}How to apply for a certificate：${plain}
    ${green}1.${plain}  (none)o not apply for a certificate（If you use nginx for tls configuration, please select this option）
    ${green}2.${plain}  (file)Bring your own certificate file (later in${green}${XRAYRPATH}/XrayR/cert/${plain}Modify under the directory）
    ${green}3.${plain}  (http)The script applies for a certificate through http（It is necessary to resolve the domain name to the local ip in advance and open port 80）
    ${green}4.${plain}  (dns)The script applies for a certificate through dns（The script only supports cloudflare，need cloudflare of global api key with email）
    "

    read -e -r -p "Please enter selection[1-4]：" num
    case "$num" in
    1)
        echo -e "Do not apply for a certificate"
        sed -i "s/USER_CERT_MODE/none/g" /tmp/config.yml
        ;;     
    2)
        echo -e "Bring your own certificate file"
        echo -e "在${green}${XRAYRPATH}/XrayR/cert/${plain}Modify under the directory ${green}node domain name.cert node domain name.key${plain}document）"
        sed -i "s/USER_CERT_MODE/file/g" /tmp/config.yml
        TLS=true
        ;;
    3)
        echo -e "The script applies for a certificate through http"
        sed -i "s/USER_CERT_MODE/http/g" /tmp/config.yml
        TLS=true
        ;;
    4)
        echo -e "The script applies for a certificate through dns"
        sed -i "s/USER_CERT_MODE/dns/g" /tmp/config.yml
        TLS=true
        read -e -r -p "Please enter cloudflare's global api key：" input
        CLOUDFLARE_GLOBAL_API_KEY=$input
        read -e -r -p "Please enter cloudflare's email：" input
        CLOUDFLARE_EMAIL=$input
        CLOUDFLARE_GLOBAL_API_KEY=$(echo $CLOUDFLARE_GLOBAL_API_KEY | sed -e 's/[]\/&$*.^[]/\\&/g')
        CLOUDFLARE_EMAIL=$(echo $CLOUDFLARE_EMAIL | sed -e 's/[]\/&$*.^[]/\\&/g')
        sed -i "s/USER_CLOUDFLARE_API_KEY/${CLOUDFLARE_GLOBAL_API_KEY}/g" /tmp/config.yml
        sed -i "s/USER_CLOUDFLARE_EMAIL/${CLOUDFLARE_EMAIL}/g" /tmp/config.yml
        ;;
    *)
        echo -e "${red}Input errors, please re-enter[1-4]${plain}"
        if [[ $# == 0 ]]; then
        modify_xrayr_config
        else
            modify_xrayr_config 0
        fi
        exit 0
        ;;
    esac

    if [ -z "${TLS}" ]; then
        echo -e "> Do not apply for a certificate"
    else
        read -e -r -p "Please enter a domain name：" input
        NODE_DOMAIN=$input
        echo -e "> The node domain name is: ${green}${NODE_DOMAIN}${plain}"
        sed -i "s/USER_NODE_DOMAIN/${NODE_DOMAIN}/g" /tmp/config.yml
    fi

    # replace config.yml
    mv /tmp/config.yml $XRAYR_PATH/XrayR/config.yml
    mv /tmp/docker-compose.yml $XRAYR_PATH/docker-compose.yml
    echo -e "xrayr configuration ${green}Successfully modified，Please wait for the restart to take effect${plain}"
    # get NODE_IP
    NODE_IP=`curl -s https://ipinfo.io/ip`
    
    
    if [[ -z "${TLS}" ]]; then
        echo -e "> Do not apply for a certificate"
    else
        echo -e "> The node domain name is：${yellow}${NODE_DOMAIN}${plain}"
    fi
    echo -e "> Node IP is：${yellow}${NODE_IP}${plain}"

    # show config
    show_config 0

    # restart xrayr
    restart_and_update 0

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

start() {
    echo -e "> start xrayr"
    # start docker-compose
    cd $XRAYR_PATH && docker-compose up -d
    if [[ $? == 0 ]]; then
        echo -e "${green}Start successfully${plain}"
    else
        echo -e "${red}Failed to start, please check the log information later${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

stop() {
    echo -e "> stop xrayr"

    cd $XRAYR_PATH && docker-compose down
    if [[ $? == 0 ]]; then
        echo -e "${green}stop success${plain}"
    else
        echo -e "${red}Failed to stop, please check the log information later${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

restart_and_update() {
    echo -e "> restart xrayr"
    cd $XRAYR_PATH
    docker-compose pull
    docker-compose down
    docker-compose up -d
    if [[ $? == 0 ]]; then
        echo -e "${green}restart successfully${plain}"
    else
        echo -e "${red}Restart failed, please check the log information later${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_log() {
    echo -e "> get xrayr log"

    cd $XRAYR_PATH && docker-compose logs -f

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_config() {
    echo -e "> View xrayr configuration"

    cd $XRAYR_PATH
    CONFIG_FILE="${XRAYR_PATH}/XrayR/config.yml"
    PANEL_TYPE=$(cat ${CONFIG_FILE} | grep "PanelType" | awk -F ':' '{print $2}' | awk -F ' ' '{print $1}')
    PANEL_URL=$(cat ${CONFIG_FILE} | grep "ApiHost" | awk -F ':' '{print $2 $3}' | awk -F '"' '{print $2}')
    PANEL_API_KEY=$(cat ${CONFIG_FILE} | grep "ApiKey" | awk -F ':' '{print $2}' | awk -F '"' '{print $2}')
    NODE_IP=$(curl -s ip.sb)
    NODE_ID=$(cat ${CONFIG_FILE} | grep "NodeID" | awk -F ':' '{print $2}')
    NODE_TYPE=$(cat ${CONFIG_FILE} | grep "NodeType" | awk -F ':' '{print $2}' | awk -F ' ' '{print $1}')
    CertMode=$(cat ${CONFIG_FILE} | grep "CertMode" | head -n 1 | awk -F ':' '{print $2}' | awk -F ' ' '{print $1}')
    CertFile=$(cat ${CONFIG_FILE} | grep "CertFile" | awk -F ':' '{print $2}' | awk -F ' ' '{print $1}')
    KeyFile=$(cat ${CONFIG_FILE} | grep "KeyFile" | awk -F ':' '{print $2}')
    NODE_DOMAIN=$(cat ${CONFIG_FILE} | grep "CertDomain" | awk -F ':' '{print $2}' | awk -F '"' '{print $2}')
    CLOUDFLARE_EMAIL=$(cat ${CONFIG_FILE} | grep "CLOUDFLARE_EMAIL" | awk -F ':' '{print $2}')
    CLOUDFLARE_API_KEY=$(cat ${CONFIG_FILE} | grep "CLOUDFLARE_API_KEY" | awk -F ':' '{print $2}')

    echo -e "
    Panel type：${green}${PANEL_TYPE}${plain}
    Domain name：${green}${PANEL_URL}${plain}
    Api key：${green}${PANEL_API_KEY}${plain}
    Node IP：${green}${NODE_IP}${plain}
    Node ID：${green}${NODE_ID}${plain}
    Node type：${green}${NODE_TYPE}${plain}
    Certificate mode：${green}${CertMode}${plain}
    Certificate file：${green}${CertFile}${plain}
    Private key file：${green}${KeyFile}${plain}
    Node domain name：${green}${NODE_DOMAIN}${plain}
    Cloudflare Email：${green}${CLOUDFLARE_EMAIL}${plain}
    Cloudflare API Key：${green}${CLOUDFLARE_API_KEY}${plain}
    "
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

uninstall() {
    # Confirm to uninstall
    echo -e "> Confirm whether to uninstall xrayr"
    read -p "please enter y/n：" confirm
    if [[ $confirm == "y" ]]; then
        echo -e "> uninstall xrayr"
        cd $XRAYR_PATH && docker-compose down
        rm -rf $XRAYR_PATH
        echo -e "${green}uninstalled successfully${plain}"
    else
        echo -e "${green}cancel uninstall${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

before_show_menu() {
    echo && echo -n -e "${yellow}* Press enter to return to the main menu *${plain}" && read temp
    show_menu
}

clean_all() {
    clean_all() {
    if [ -z "$(ls -A ${XRAYR_PATH})" ]; then
        rm -rf ${XRAYR_PATH}
    fi
}
}

install_bbr() {
    # Determine whether bbr is installed
    lsmod | grep bbr
    if [[ $? == 0 ]]; then
        echo -e "${green}installed bbr no installation required${plain}"
    else
        echo -e "> install bbr"
        wget --no-check-certificate -O /opt/bbr.sh https://github.com/teddysun/across/raw/master/bbr.sh
        chmod 755 /opt/bbr.sh
        /opt/bbr.sh
    fi

}

show_menu() {
    echo -e "
    ${green}xrayr Docker installation management script${plain}
    ${green}1.${plain}  install xrayr
    ${green}2.${plain}  Modify xrayr configuration
    ${green}3.${plain}  start xrayr
    ${green}4.${plain}  stop xrayr
    ${green}5.${plain}  Restart and update xrayr (there is no newer version!)
    ${green}6.${plain}  View xrayr logs
    ${green}7.${plain}  View xrayr configuration
    ${green}8.${plain}  uninstall xrayr
    ${green}9.${plain}  install bbr
    ————————————————
    ${green}0.${plain}  exit script
    "
    echo && read -ep "please enter selection [0-8]: " num

    case "${num}" in
    0)
        exit 0
        ;;
    1)
        install
        ;;
    2)
        modify_xrayr_config
        ;;
    3)
        start
        ;;
    4)
        stop
        ;;
    5)
        restart_and_update
        ;;
    6)
        show_log
        ;;
    7)
        show_config
        ;;
    8)
        uninstall
        ;;
    9)
        install_bbr
        ;;
    *)
        echo -e "${red}Please enter the correct number [0-8]${plain}"
        ;;
    esac
}

pre_check
show_menu
