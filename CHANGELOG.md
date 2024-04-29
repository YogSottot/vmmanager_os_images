#### 2024.04.29  

##### Added  

Добавлен шаблон IMG_Ubuntu-24.04-amd64.  

#### 2021.09.18  

##### Added  

Добавлен шаблон IMG_Debian-11-amd64.  

#### 2021.03.03  

##### Added  

Добавлен шаблон IMG_BitrixEnv-7-amd64_ext4.
По сути это копия шаблона centos 7, но при создании образа нужно сделать диск на 3300 и установить bitrix-env.  
Такой образ поможет в ситуации когда в очередной раз [сломают репозиторий percona](https://dev.1c-bitrix.ru/support/forum/forum32/topic138158/)  

#### 2021.03.02  

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
