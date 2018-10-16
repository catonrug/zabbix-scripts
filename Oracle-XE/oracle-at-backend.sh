# the goal of this instruction is to test oracle database monitoring through linuxODBC driver. Oracle 11.2g express edition is used

# 2 GB of RAM must be persistent

# install vagrant SSH key for future passwordless root access
echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== imported-openssh-key" > ~/.ssh/authorized_keys
chmod -R 600 ~/.ssh/authorized_keys

# set hostname to 'oracle-be.pro' which stands for oracle back-end
nmtui

# reboot computer so when you execute '/etc/init.d/oracle-xe configure' the oracle wizard will really take up the right hostname. Without reboot it will not work.

# this file must be placed on /root. Neet to have oracle account to download those files
# http://download.oracle.com/otn/linux/oracle11g/xe/oracle-xe-11.2.0-1.0.x86_64.rpm.zip
# http://download.oracle.com/otn/linux/instantclient/11204/oracle-instantclient11.2-basic-11.2.0.4.0-1.x86_64.rpm
# http://download.oracle.com/otn/linux/instantclient/11204/oracle-instantclient11.2-odbc-11.2.0.4.0-1.x86_64.rpm

yum -y install gcc gcc-c++ make gnutls-devel libxml2-devel unixODBC-devel net-snmp-devel libssh2-devel OpenIPMI-devel libevent-devel libcurl-devel openldap-devel bc net-tools vim unzip mlocate
rpm -i https://repo.zabbix.com/non-supported/rhel/7/x86_64/iksemel-1.4-2.el7.centos.x86_64.rpm
rpm -i https://repo.zabbix.com/non-supported/rhel/7/x86_64/iksemel-devel-1.4-2.el7.centos.x86_64.rpm

sysctl kernel.shmmax # check shmmax. must be 4294967295
echo "kernel.shmmax = 4294967295" >> /etc/sysctl.conf # install shmmax=4294967295 globaly at the next boot
sysctl -w kernel.shmmax=4294967295 # set shmmax=4294967295 now!
sysctl kernel.shmmax # check again live shmmax value

sysctl kernel.shmall # shmall must be 2097152
echo "kernel.shmall = 2097152" >> /etc/sysctl.conf # install shmall=2097152 at the next boot
sysctl -w kernel.shmall=2097152 # set shmall=2097152 now!
sysctl kernel.shmall # check again live shmall value

unzip oracle-xe-11.2.0-1.0.x86_64.rpm.zip && cd ~/Disk1 && rpm -i oracle-xe-11.2.0-1.0.x86_64.rpm && time /etc/init.d/oracle-xe configure
# Lets set database password '5sRj4GXspvDKsBXW' for SYS and SYSTEM account

su - oracle
echo $ORACLE_HOME
echo ". /u01/app/oracle/product/11.2.0/xe/bin/oracle_env.sh"> ~/.bash_profile
echo "export LD_LIBRARY_PATH=\$ORACLE_HOME/lib">> ~/.bash_profile
exit
su - oracle
echo $ORACLE_HOME
echo $LD_LIBRARY_PATH
tnsping XE # try to ping TNSNAME. to this point it should retreive 'OK' at the last line

# download archive into oracle profile
cd
v=4.0.0
curl -L "http://downloads.sourceforge.net/project/zabbix/ZABBIX%20Latest%20Stable/$v/zabbix-$v.tar.gz" -o zabbix-$v.tar.gz
tar -vzxf zabbix-$v.tar.gz -C .
cd ~/zabbix-$v/database/oracle
cp *.sql ~

### run as oracle user
sqlplus sys as sysdba
# '5sRj4GXspvDKsBXW'

# This should show:
# Connected to:
# Oracle Database 11g Express Edition Release 11.2.0.2.0 - 64bit Production

select parameter,value from v$nls_parameters where parameter='NLS_CHARACTERSET' or parameter='NLS_NCHAR_CHARACTERSET';
# this should report
# NLS_CHARACTERSET
# AL32UTF8

# NLS_NCHAR_CHARACTERSET
# UTF8

# if not then execute this commands

shutdown immediate
startup mount
alter system enable restricted session;
alter system set job_queue_processes=0;
alter system set aq_tm_processes=0;
alter database open;
ALTER DATABASE NATIONAL CHARACTER SET internal_use UTF8;
shutdown immediate
startup

# check again
select parameter,value from v$nls_parameters where parameter='NLS_CHARACTERSET' or parameter='NLS_NCHAR_CHARACTERSET';

# test some status
select * from v$sysstat;

# https://uberdev.wordpress.com/2011/12/07/zabbix-deployment-on-rhel-with-oracle/
# create zabbix database (table space)
CREATE TABLESPACE "ZABBIX_TS" DATAFILE '/u01/app/oracle/oradata/XE/zabbix_ts.dbf' SIZE 100M AUTOEXTEND ON NEXT 536870912 MAXSIZE 4G LOGGING ONLINE PERMANENT BLOCKSIZE 8192 EXTENT MANAGEMENT LOCAL AUTOALLOCATE SEGMENT SPACE MANAGEMENT AUTO;
CREATE USER zabbix IDENTIFIED BY zabbix DEFAULT TABLESPACE ZABBIX_TS;
GRANT DBA TO zabbix WITH ADMIN OPTION;
exit

# connect to database zabbix
sqlplus zabbix/zabbix

# last check if the encoding is right
select parameter,value from v$nls_parameters where parameter='NLS_CHARACTERSET' or parameter='NLS_NCHAR_CHARACTERSET';
# this should report:
# NLS_CHARACTERSET
# AL32UTF8
# 
# NLS_NCHAR_CHARACTERSET
# UTF8

SET DEFINE OFF 

@/u01/app/oracle/schema.sql

# exit the database client
exit

# exit oracle user
exit 

# download source of zabbix
cd
v=4.0.0
curl -L "http://downloads.sourceforge.net/project/zabbix/ZABBIX%20Latest%20Stable/$v/zabbix-$v.tar.gz" -o zabbix-$v.tar.gz
tar -vzxf zabbix-$v.tar.gz -C .
cd zabbix-$v

export ORACLE_HOME=/u01/app/oracle/product/11.2.0/xe
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
groupadd zabbix
useradd -g zabbix zabbix

# configure proxy
./configure --enable-proxy --enable-agent --with-oracle --with-libcurl --with-libxml2 --with-ssh2 --with-net-snmp --with-openipmi --with-jabber --with-openssl --with-unixodbc --sysconfdir=/etc/zabbix --prefix=/usr

# compile
time make 

# install everything
make install

grep -v "^$\|#" /etc/zabbix/zabbix_proxy.conf
Server=ec2-35-166-97-138.us-west-2.compute.amazonaws.com
Hostname=oracle-xe
LogFile=/tmp/zabbix_proxy.log
DBName=XE
DBUser=zabbix
DBPassword=zabbix
DBPort=1521
Timeout=4
LogSlowQueries=3000

cp /etc/zabbix/{zabbix_proxy.conf,original.zabbix_proxy.conf}
cat >/etc/zabbix/zabbix_proxy.conf<< EOL
Server=ec2-35-166-97-138.us-west-2.compute.amazonaws.com
Hostname=oracle-xe
LogFile=/tmp/zabbix_proxy.log
DBName=XE
DBUser=zabbix
DBPassword=zabbix
DBPort=1521
Timeout=4
LogSlowQueries=3000
EOL


# test if proxy is working
su - zabbix
# zabbix_proxy: error while loading shared libraries: libclntsh.so.11.1: cannot open shared object file: No such file or directory
cat /u01/app/oracle/product/11.2.0/xe/network/admin/tnsnames.ora
cat ~/.bash_profile

# allow to communicate with oracle engine from zabbix user
echo ". /u01/app/oracle/product/11.2.0/xe/bin/oracle_env.sh">> ~/.bash_profile
echo "export LD_LIBRARY_PATH=\$ORACLE_HOME/lib">> ~/.bash_profile

export ORACLE_HOME=/u01/app/oracle/product/11.2.0/xe
export LD_LIBRARY_PATH=$ORACLE_HOME/lib

zabbix_proxy -f


# set up ODBC connection
cd 

rpm -i oracle-instantclient11.2-basic-11.2.0.4.0-1.x86_64.rpm # required for odbc. this is needed for httpd client to be able to connect. 
rpm -i oracle-instantclient11.2-odbc-11.2.0.4.0-1.x86_64.rpm # odbc connector. needed to use direct SQL statements


find / -name odbc_update_ini.sh

updatedb && locate libodbcinst
cd /usr/lib64
ln -s libodbcinst.so.2 libodbcinst.so.1
chmod 755 /usr/lib/oracle/11.2/client64/lib/lib*
ldd /usr/lib/oracle/11.2/client64/lib/libsqora.so.11.1

# check is [isql] utility is installed
isql

# backup original file which contains samples for MySQL and PostgreSQL
cp /etc/{odbcinst.ini,original.odbcinst.ini}

# install new connection driver definition regarding to oracle
cat >/etc/odbcinst.ini<< EOL
[Oracle 11g ODBC driver]
Description     = Oracle ODBC driver for Oracle 11g
Driver          = /usr/lib/oracle/11.2/client64/lib/libsqora.so.11.1
Setup           =
FileUsage       =
CPTimeout       =
CPReuse         =
Driver Logging  = 7
 
[ODBC]
Trace = Yes
TraceFile = /tmp/odbc.log
ForceTrace = Yes
Pooling = No
DEBUG = 1
EOL

# install connection details. this is the place where hostname matters!
cat >/etc/odbc.ini<< EOL
[ODBC]
Application Attributes = T
Attributes = W
BatchAutocommitMode = IfAllSuccessful
BindAsFLOAT = F
CloseCursor = F
DisableDPM = F
DisableMTS = T
Driver = Oracle 11g ODBC driver
DSN = XE
EXECSchemaOpt =
EXECSyntax = T
Failover = T
FailoverDelay = 10
FailoverRetryCount = 10
FetchBufferSize = 64000
ForceWCHAR = F
Lobs = T
Longs = T
MaxLargeData = 0
MetadataIdDefault = F
QueryTimeout = T
ResultSets = T
ServerName = oracle-be.pro
SQLGetData extensions = F
Translation DLL =
Translation Option = 0
DisableRULEHint = T
UserID = zabbix
Password = zabbix
StatementCache=F
CacheBufferSize=20
UseOCIDescribeAny=F
MaxTokenSize=8192
EOL

# move to zabbix user because it know (~/.bach_profile) how to communicate to oracle
su - zabbix

# test connection
isql -v ODBC
# this should report
# +---------------------------------------+
# | Connected!                            |
# |                                       |
# | sql-statement                         |
# | help [tablename]                      |
# | quit                                  |
# |                                       |
# +---------------------------------------+

# http://docs.adaptivecomputing.com/9-1-0/MWS/Content/topics/moabWorkloadManager/topics/databases/oracle.html

# https://www.zabbix.com/documentation/4.0/manual/appendix/install/db_scripts