#### Шаблоны для установки CentOS / Ubuntu / Debian с разворачиванием из файла для VMManager  

Создано на основе [официального руководства](https://docs.ispsystem.ru/vmmanager-kvm/shablony-os-i-retsepty/shablony-os/sozdanie-shablonov-os#id-%D0%A1%D0%BE%D0%B7%D0%B4%D0%B0%D0%BD%D0%B8%D0%B5%D1%88%D0%B0%D0%B1%D0%BB%D0%BE%D0%BD%D0%BE%D0%B2%D0%9E%D0%A1-CentOS%D1%81%D1%80%D0%B0%D0%B7%D0%B2%D0%BE%D1%80%D0%B0%D1%87%D0%B8%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5%D0%BC%D0%B8%D0%B7%D1%84%D0%B0%D0%B9%D0%BB%D0%B0)

Созданы шаблоны для CentOS 7, Ubuntu 18.04 / 20.04, Debian 10

Директории шаблонов копируются в /nfsshare/  
Для использования шаблонов нужно создать образы дисков. Для этого, используя стандартные шаблоны vmmanger, устанавливаем нужную ОС, задавая размер диска указанный в шаблоне параметром ```<elem name="disk">```.  
Устанавливаем туда нужные программы. Пакеты cloud-utils-growpart / cloud-guest-utils необхождимы для работы скрипта, остальное опционально.  
Пример для CentOS 7  

```bash
yum install -y epel-release
yum install -y cloud-utils-growpart bind-utils traceroute bash-completion bash-completion-extras nano ncdu net-tools wget byobu
```

Пример для Ubuntu 18.04 / 20.04  

```bash
apt install -y cloud-guest-utils dnsutils traceroute bash-completion nano ncdu net-tools wget byobu
```

Добавляем команду для запуска скрипта  
В CentOS 7

```bash
echo "sh /dev/sda" >> /etc/rc.d/rc.local
chmod +x /etc/rc.d/rc.local
```

В Ubuntu / Debian файла ```/etc/rc.local``` нет. Создаём его.

```bash
printf '%s\n' '#!/bin/bash' 'bash /dev/sda' 'exit 0' | tee /etc/rc.local
chmod +x /etc/rc.local
```

Останавливаем vm и снимаем образ.  

```bash
# Мой пример
dd if=/dev/virtual/vm6894  of=/nfsshare/IMG_CentOS-7-amd64_ext4/centos_7_hdd.image bs=16M

# Из документации vmmanger  
# Для LVM
dd if=/dev/MyLvm/VMNAME of=centos_hdd.image
# Для формата RAW/Qcow2
dd if=ПУТЬ_К_ФАЙЛУ of=centos_hdd.image
```

После чего можно подключать шаблоны к обработчикам / тарифам / типам продуктов.  

##### Особенности  

- Поддерживается заказ vm с несколькими ip. Если ip добавлены после создания vm, то их нужно добавить вручную.  
- Смена ip после создания vm также вручную.  
- Работа с ipv6 не проверена.  

##### Bugfix  

При создании vm с ip из подсети отличной от ```$FINISH``` (URL-адрес, который вызывается по завершении установки ОС), возникало бесконечное выполнение скрипта  
```A start job is running for /etc/rc.d/rc.local Compatibility (3min 54s / no limit)```

[https://access.redhat.com/solutions/3321271]  

```bash
/lib/systemd/system/rc-local.service  
TimeoutSec=60
```

Для отладки проблемы было сделано:

```bash
cat /etc/rc.d/rc.local
...
sleep 40
( sh /dev/sda ) &
```

После этого первая загрузка ОС происходила до конца и можно было залогинится и посмотреть в чём проблема.  
Проблема решена добавлением команды перезапуска сети в скрипт установки.  

##### Ubuntu 18.04 server installation gets stuck at 66% while running'update-grub'  

[Bug](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=853187#25) из-за которого, в основном, и было принято решение о создании этих шаблонов  

[Скопирую](https://unix.stackexchange.com/a/511300/370526) сюда решение этого бага  

##### Workaround 1: (proaction)  

When you are reaching the “Install the GRUB boot loader to the master boot record?” prompt, (in my case, no such prompt appeared but i figured out timing of the grub-install) switch to a console (alt+[f2-f6]), and remove this file:

```bash
rm /target/etc/grub.d/30_os-prober
```

This will prevent update-grub from running os-prober, which should avoid running into this issue. Of course, other operating systems won't be listed, but at least that should prevent the installation process from getting entirely stuck. I've tested this successfully in a VM with guided (unencrypted) LVM, and standard plus ssh tasks (which is how I initially reproduced your issue).

##### Workaround 2: (reaction)  

Otherwise, once the process is stuck, locate the process identifier (PID) on the first column of the ps output:

```bash
ps | grep 'dmsetup create'
```

then kill this dmsetup process. With your output above, that'd be:

```bash
kill 19676
```
