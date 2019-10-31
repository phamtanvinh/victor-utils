# HOW TO SYNC FOLDER LOCAL

###### create script
```sh
#!/bin/bash

while inotifywait -r -e delete_self -e modify,attrib,close_write,move,create,delete /victor/victor-realtime; do
  rsync -avz --delete /victor/victor-realtime /home/docker
done
```

```sh
[Unit]
Description = SyncService
After = network.target

[Service]
PIDFile = /run/syncservice/syncservice.pid
User = root
Group = root
WorkingDirectory = /opt
ExecStartPre = /bin/mkdir /run/syncservice
ExecStartPre = /bin/chown -R root:root /run/syncservice
ExecStart = /bin/bash /opt/rsync-file.sh
ExecReload = /bin/kill -s HUP $MAINPID
ExecStop = /bin/kill -s TERM $MAINPID
ExecStopPost = /bin/rm -rf /run/syncservice
PrivateTmp = true

[Install]
WantedBy = multi-user.target
```

```sh
cp ./bin/rsync-file.sh /opt
cp sync.service /etc/systemd/system
chmod 755 /etc/systemd/system/sync.service  
systemctl daemon-reload
systemctl start sync.service
systemctl status sync.service
systemctl stop sync.service

systemctl restart sync.service 
```