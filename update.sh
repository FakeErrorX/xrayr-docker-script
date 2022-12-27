# !/bin/bash

# upgrade script

xrayr_path="/opt/xrayr"
old_config_file="$xrayr_path/config.yml"
new_config_file="$xrayr_path/XrayR/config.yml"


# Check if the xrayr_path exists, if it does not exist, then exit
if [ ! -d "$xrayr_path" ]; then
  echo "xrayr does not appear to be installed, please check and try again"
  exit
fi

# check if old config file exists
if [ ! -f "$old_config_file" ]; then
  echo "xrayr does not appear to be installed, please check and try again"
  exit
fi

# check if xrayr_path directory exists docker-compose.yml
if [ ! -f "$xrayr_path/docker-compose.yml" ]; then
  echo "xrayr does not appear to be installed, please check and try again"
  exit
fi

# check if xrayr_path directory exists XrayR
if [ ! -d "$xrayr_path/XrayR" ]; then
  echo "xrayr seems not installed completely, please check and try again"
  exit
fi

# check if xrayr_path directory exists XrayR/config.yml
if [ ! -f "$xrayr_path/XrayR/config.yml" ]; then
  echo "xrayr seems to have been upgraded, please check and try again"
  exit
fi

# mv old_config_file to new_config_file
mv $old_config_file $new_config_file

# remove old config file
rm -rf $old_config_file

# get new docker-compose.yml
DC_YML_URL="https://raw.githubusercontent.com/FakeErrorX/xrayr-docker-script/main/docker-compose.yml"
wget -O $xrayr_path/docker-compose.yml $DC_YML_URL

# update and restart
cd $xrayr_path
docker-compose pull
docker-compose down
docker-compose up -d

# check if xrayr container is running
if [ "$(docker inspect -f {{.State.Running}} xrayr)" = "true" ]; then
  echo "xrayr upgrade successful"
else
  echo "xrayr upgrade failed, please check and try again"
fi
