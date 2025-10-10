#!/bin/bash


USERID=$(id -u)


R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"


LOGS_FOLDER="/var/log/shell-roboshop"
FILE_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$FILE_NAME.log"
START_TIME=$(date +%s)
SCRIPT_DIR=$PWD
mkdir -p $LOGS_FOLDER
START_TIME=$(date +%s)
MYSQL_HOST=mysql.awspractice.store

echo "script started execututed at :$(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then
    echo "ERROR:run the script with root previliges"
    exit 1
fi

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$2 is.... $R failure $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2 is.... $G success $N" | tee -a $LOG_FILE
    fi
}

##installing python3
dnf install python3 gcc python3-devel -y
VALIDATE $? "install python3"

mkdir -p /app
VALIDATE $? "Creating app directory"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip  &>>$LOG_FILE
VALIDATE $? "Downloading payment application"

cd /app 
VALIDATE $? "Changing to app directory"

rm -rf /app/*
VALIDATE $? "Removing existing code"

unzip /tmp/payment.zip &>>$LOG_FILE
VALIDATE $? "unzip payment"

pip3 install -r requirements.txt
VALIDATE $? "installing dependencies"

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service
systemctl daemon-reload
systemctl enable payment  &>>$LOG_FILE

systemctl restart payment