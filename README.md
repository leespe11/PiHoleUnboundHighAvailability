# Pi-hole Unbound DNSSEC HA/Standalone docker
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
### High-Availability Instances
The run script takes one input paramater for the HA instances.

The Index or hostname of the HOSTNAMES configured in **config.env**

The same config file should be coppied onto each instance and ./run with a different index


Start the Master server
```
./run 0
```
Start the Standby/Backup server(s)
```
./run 1
./run 2
```

### Standalone Instance
```
./run
```