# !/bin/bash
#
# Automatically download static camouflage website to specified directory

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'
export PATH=$PATH:/usr/local/bin


WEB_ROOT=$1
if [ -z "$WEB_ROOT" ]; then
    echo "usage: $0 Website root directory"
    echo -e "${red}no catalog value entered，will use the default: /var/www/html${plain}"
    WEB_ROOT="/var/www/html"
    echo -e "Whether to continue？[Y/n]"
    read -p "(default: y):" yn
    [ -z "${yn}" ] && yn="y"
    if [[ $yn == [Yy] ]]; then
        echo -e "${green}continue to execute${plain}"
    else
        echo -e "${red}quit execution${plain}"
        exit 1
    fi
fi

if [ ! -d "$WEB_ROOT" ]; then
    echo -e "${red}mistake! directory does not exist${plain}"
    exit 1
fi

# Download Static Cloaking Sites
# static html resource url list
STATIC_HTML_URL_LIST=(
    "https://chomp.webflow.io/"
    "https://playo-128.webflow.io/"
    "https://aquapure-wbs.webflow.io/"
    "https://inspiration-template.webflow.io/"
    "https://accomplishedtemplate.webflow.io/"
    "https://north-template.webflow.io/"
    "https://sign-template.webflow.io/"
)
# randomly choose one
STATIC_HTML_URL=${STATIC_HTML_URL_LIST[$RANDOM % ${#STATIC_HTML_URL_LIST[@]} ]}
echo -e "${green}Download static html resource from: ${STATIC_HTML_URL}${plain}"

# download static html resource to web root
# check if wget is installed
if [ ! -x "$(command -v wget)" ]; then
    echo -e "${red}Error: wget is not installed.${plain}"
    # install wget
    echo -e "${green}Install wget...${plain}"
    # check OS
    if [ -f /etc/redhat-release ]; then
        # install wget on CentOS
        yum install -y wget
    elif cat /etc/issue | grep -q -E -i "debian"; then
        # install wget on Debian/Ubuntu
        apt-get update
        apt-get install -y wget
    elif cat /etc/issue | grep -q -E -i "ubuntu"; then
        # install wget on Ubuntu
        apt-get update
        apt-get install -y wget
    elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
        # install wget on CentOS
        yum install -y wget
    fi
fi
# Download Static Cloaking Sites，index.html
wget -O ${WEB_ROOT}/index.html ${STATIC_HTML_URL}

echo -e "${green}Download completed，Download file at ${WEB_ROOT}/index.html${plain}"
