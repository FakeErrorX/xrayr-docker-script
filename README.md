# One-click script to deploy XrayR based on docker

Instructions：
```bash
curl -L https://raw.githubusercontent.com/FakeErrorX/xrayr-docker-script/main/xrayr.sh -o xrayr.sh && chmod +x xrayr.sh && ./xrayr.sh
```

Currently only tested on ubuntu 20.04 LTS, availability is not guaranteed.

Updated December 17, 2022：
Recently, both xrayr and v2board have been updated, and this script has been updated accordingly. For those who have used the script before and want to update to the new version, please use
```bash
bash <(curl -sL https://raw.githubusercontent.com/FakeErrorX/xrayr-docker-script/main/update.sh)
```


# Support

- [x] Only tested with v2board
- [x] Support V2ray ShadowSocks Trojan
- [x] Three certificate application methods are supported: `dns file http`, where `dns` certificate application only supports Cloudflare dns
- [x] Support viewing xrayr configuration

# Effect

```shell
xrayr Docker installation management script
    1.  install xrayr
    2.  Modify xrayr configuration
    3.  start xrayr
    4.  stop xrayr
    5.  Restart and update xrayr (there is no newer version!)
    6.  View xrayr logs
    7.  View xrayr configuration
    8.  uninstall xrayr
    9.  install bbr
    ————————————————
    0.  exit script
```
