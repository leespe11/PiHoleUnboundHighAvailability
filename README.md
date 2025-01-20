# PiHoleUnboundHighAvailability
## Install
Download Repository
```
git clone git@github.com:leespe11/ARM-Secure-VPN-DNS-Proxy-Ad-Blocker.git
````
Change the parameters of **config.env** based on your requirments 
Change the parameters of **cert_ext.cnf** based on your requirments 

Execute permissions for run script
```
chmod +x run
```
Start the service Master server
```
./run master
```

Start the service Standby/Backup server
```
./run standby 
```