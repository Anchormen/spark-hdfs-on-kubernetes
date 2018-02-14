#!/bin/bash

## Set defaults for environmental variables in case they are undefined
USER=${RSTUDIOUSER:=rstudio}
ZEPPELINUSER=${ZEPPELINUSER:=zeppelin}
RSTUDIOPASSWORD=${RSTUDIOPASSWORD:=rstudio}
ZEPPELINPASSWORD=${ZEPPELINPASSWORD:=rstudio}
USERID=${USERID:=1000}
GROUPID=${GROUPID:=1000}
ROOT=${ROOT:=FALSE}
UMASK=${UMASK:=022}


if [ "$USERID" -lt 1000 ]
# Probably a macOS user, https://github.com/rocker-org/rocker/issues/205
  then
    echo "$USERID is less than 1000"
    check_user_id=$(grep -F "auth-minimum-user-id" /etc/rstudio/rserver.conf)
    if [[ ! -z $check_user_id ]]
    then
      echo "minumum authorised user already exists in /etc/rstudio/rserver.conf: $check_user_id"
    else
      echo "setting minumum authorised user to 499"
      echo auth-minimum-user-id=499 >> /etc/rstudio/rserver.conf
    fi
fi

if [ "$USERID" -ne 1000 ]
## Configure user with a different USERID if requested.
  then
    echo "deleting user rstudio"
    userdel rstudio
    echo "creating new $USER with UID $USERID"
    useradd -m $USER -u $USERID
    mkdir /home/$USER
    chown -R $USER /home/$USER
    usermod -a -G staff $USER
elif [ "$USER" != "rstudio" ]
  then
    ## cannot move home folder when it's a shared volume, have to copy and change permissions instead
    cp -r /home/rstudio /home/$USER
    ## RENAME the user   
    usermod -l $USER -d /home/$USER rstudio
    groupmod -n $USER rstudio
    usermod -a -G staff $USER
    chown -R $USER:$USER /home/$USER
    echo "USER is now $USER"
fi

if [ "$GROUPID" -ne 1000 ]
## Configure the primary GID (whether rstudio or $USER) with a different GROUPID if requested.
  then
    echo "Modifying primary group $(id $USER -g -n)"
    groupmod -g $GROUPID $(id $USER -g -n)
    echo "Primary group ID is now custom_group $GROUPID"
fi
  
## Add a password to user
echo "$USER:$RSTUDIOPASSWORD" | chpasswd

## Add a password and user for Zeppelin
sed -i "s/USER/$ZEPPELINUSER/g; s/PASSWORD/$ZEPPELINPASSWORD/g" /zeppelin/conf/shiro.ini

## Use Env flag to know if user should be added to sudoers
if [ "$ROOT" == "TRUE" ]
  then
    adduser $USER sudo && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
    echo "$USER added to sudoers"
fi

## Change Umask value if desired
if [ "$UMASK" -ne 022 ]
  then
    echo "server-set-umask=false" >> /etc/rstudio/rserver.conf
    echo "Sys.umask(mode=$UMASK)" >> /home/$USER/.Rprofile
fi

## Add these to the global environment so they are available to the RStudio user 
echo -e "PATH=\${PATH} \
\nJAVA_HOME=${JAVA_HOME} \
\nSPARK_HOME=${SPARK_HOME} \
\nMASTER=${MASTER} \
\nSPARK_CORES_MAX=${SPARK_CORES_MAX} \
\nSPARK_EXECUTOR_CORES=${SPARK_EXECUTOR_CORES} \
\nSPARK_EXECUTOR_MEMORY=${SPARK_EXECUTOR_MEMORY} \
\nSPARK_DRIVER_CORES=${SPARK_DRIVER_CORES} \
\nSPARK_DRIVER_MEMORY=${SPARK_DRIVER_MEMORY} \
\nSPARK_DRIVER_MAXRESULTSIZE=${SPARK_DRIVER_MAXRESULTSIZE}" >> /usr/lib/R/etc/Renviron