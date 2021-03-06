#### Макросы шаблонов ОС  

[Источник](https://docs.ispsystem.ru/vmmanager-kvm/shablony-os-i-retsepty/shablony-os/makrosy-shablonov-os)

В статье описаны макросы, которые можно использовать в конфигурационных файлах установки ОС. Значения всех параметров можно увидеть в логе панели управления (по умолчанию /usr/local/mgr5/var/vmmgr.log) при включённом уровне логирования "Debug".

Список макросов:

    ($AFTER_INSTALL_SCRIPT_HTTP) — URL-адрес для получения скрипта, который запускается после установки ОС, по протоколу HTTP;
    ($AFTER_INSTALL_SCRIPT_HTTPS) — URL-адрес для получения скрипта, который запускается после установки ОС, по протоколу HTTPS;
    ($AFTER_INSTALL_SCRIPT_HTTPSv4) — URL-адрес для получения скрипта, который запускается после установки ОС, с использованием протоколов HTTPS и IPv4;
    ($AFTER_INSTALL_SCRIPT_HTTPSv6) — URL-адрес для получения скрипта, который запускается после установки ОС, с использованием протоколов HTTPS и IPv6;
    ($AFTER_INSTALL_SCRIPT_HTTPv4) — URL-адрес для получения скрипта, который запускается после установки ОС, с использованием протоколов HTTP и IPv4;
    ($AFTER_INSTALL_SCRIPT_HTTPv6) — URL-адрес для получения скрипта, который запускается после установки ОС, с использованием протоколов HTTP и IPv6;
    ($FINISH) — URL-адрес, который вызывается по завершении установки ОС;
    ($FINISHv4) — URL-адрес, который вызывается по завершении установки ОС с использованием протокола IPv4;
    ($FINISHv6) — URL-адрес, который вызывается по завершении установки ОС с использованием протокола IPv6;
    ($GATEWAY) — шлюз по умолчанию;
    ($GATEWAYv4) — шлюз по умолчанию для IPv4;
    ($GATEWAYv6) — шлюз по умолчанию для IPv6;
    ($HOSTNAME) — имя хоста;
    ($HTTPPROXYv4) — HTTP-proxy для IPv4. Используется для кэширования пакетов при установке ОС;
    ($HTTPPROXYv6) — HTTP-proxy для IPv6. Используется для кэширования пакетов при установке ОС;
    ($IP) — основной IP-адрес;
    ($IPv4) — IPv4-адрес;
    ($IPv4ALIASES) — дополнительные IPv4-адреса. Указываются через пробел;
    ($IPv6) — IPv6-адрес;
    ($IPv6ALIASES) — дополнительные IPv6-адреса. Указываются через пробел;
    ($MGR_NAME) — краткое название панели управления;
        vmmgr — VMmanager;
        dcimgr — DCImanager;
    ($MGR_VERSION) — версия панели управления;
    ($MIRROR) — зеркало репозитория ОС;
    ($NAMESERVER) — основной DNS-сервер;
    ($NAMESERVERS) — DNS-серверы. Указываются через пробел;
    ($NAMESERVERv4) — DNS-сервер для IPv4;
    ($NAMESERVERv6) — DNS-сервер для IPv6;
    ($NETMASK) — маска сети основного IP-адреса;
    ($NETMASKv4) — маска сети для IPv4;
    ($NETMASKv6) — маска сети для IPv6;
    ($NEXTHOPIPv4) — следующая точка маршрута для IPv4;
    ($NEXTHOPIPv6) — следующая точка маршрута для IPv6;
    ($OSINSTALLINFO_HTTP) — URL-адрес для получения информации, необходимой для установки ОС, по протоколу HTTP;
    ($OSINSTALLINFO_HTTPS) — URL-адрес для получения информации, необходимой для установки ОС, по протоколу HTTPS;
    ($OSINSTALLINFO_HTTPSv4) — URL-адрес для получения информации, необходимой для установки ОС, с использованием протоколов HTTPS и IPv4;
    ($OSINSTALLINFO_HTTPSv6) — URL-адрес для получения информации, необходимой для установки ОС, с ипользованием протоколов HTTPS и IPv6;
    ($OSINSTALLINFO_HTTPv4) — URL-адрес для получения информации, необходимой для установки ОС, с использованием протоколов HTTP и IPv4;
    ($OSINSTALLINFO_HTTPv6) — URL-адрес для получения информации, необходимой для установки ОС, с использованием протоколов HTTP и IPv6;
    ($PASS) — пароль root-пользователя;
    ($PASS_CRYPT) — хэш md5 пароля root-пользователя;
    ($SHAREDIR_FILE) — URL-адрес директории, доступной по HTTP;
    ($SHAREDIR_FILEv4) — URL-адрес директории, доступной по HTTP при использовании протокола IPv4;
    ($SHAREDIR_FILEv6) — URL-адрес директории, доступной по HTTP при использовании протокола IPv6;
    ($SSHPUBKEYS) — список публичных SSH-ключей. Ключи добавляются в файл /root/.ssh/authorized_keys;
    ($TIMEZONE) — временная зона;
    ($TMPIPv4) — использование временного IPv4-адреса на время установки ОС;
        true — использовать;
        false — не использовать;
    ($VOL_SIZE_M) — размер основного диска. Указывается в Мб.
