# Pi-hole Unbound DNSSEC High-Availability/Standalone docker
## Install
Download Repository
```
git clone https://github.com/leespe11/PiHoleUnboundHighAvailability.git
````
## Edit Config/Environment files
**config.env**

**config/cert_ext.cnf**

## RUN
Execute permissions for run script
```
chmod +x run
```
#High-Availability Instances
Start the Master server
```
./run 0
```
Start the Standby/Backup server(s)
```
./run 1 
```

#Standalone Instances
Start the service Master server
```
./run
```