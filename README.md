# NTracking Dashboard

whiptail script to set up NTracking 

# Prereq

Do not run as root user if you need to create a normal user with sudo rights and switch to that user.

```
adduser <username>
usermod -aG sudo <username>
su - u <username>
```

# to Run

```bash <(curl -s https://raw.githubusercontent.com/josh-clsn/ntracking-lite/main/ntracking.sh)```

this script will run a whip tail menu script giving you the options to :

1. install Docker engine.
2. setup a dockerised install of Influxdb2 and Grafana to visualise data.
3. setup an install of Telegraf which will send data to influxDB.
4. uninstall telegraf influx and grafana.

Docker Engine only needs to be installed on the machine hosting influxDB and Grafana

Telegraf must be installed on all machines that are to send data to influx including the one which hosts Influx and Grafana if it is running nodes.


# Defaults for Influx and Grafana
username: ```safe```

password: ```jidjedewTSuIw4EmqhoOo```

Influxdb default Token ```HYdrv1bCZhsvMhYOq6_wg4NGV2OI9HZch_gh57nquSdAhbjhLMUIeYnCCAoybgJrJlLXRHUnDnz2v-xR0hDt3Q==```

These can be changed during the install via interactive prompt along with the TOKEN for data ingress to Influx2 Database

# How to access

Influx can be accesed on ```<IP Address>:8086```

Grafana can be accesed on ```<IP Address>:3000```

