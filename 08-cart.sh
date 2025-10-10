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


##### NodeJS ####
dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling NodeJS"
dnf module enable nodejs:20 -y  &>>$LOG_FILE
VALIDATE $? "Enabling NodeJS 20"
dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Installing NodeJS"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating system user"
else
    echo -e "User already exist ... $Y SKIPPING $N"
fi

mkdir -p /app
VALIDATE $? "Creating app directory"

curl -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading cart application"

cd /app 
VALIDATE $? "Changing to app directory"

rm -rf /app/*
VALIDATE $? "Removing existing code"

unzip /tmp/cart.zip &>>$LOG_FILE
VALIDATE $? "unzip cart"

npm install &>>$LOG_FILE
VALIDATE $? "Install dependencies"

cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service
VALIDATE $? "Copy systemctl service"

systemctl daemon-reload
systemctl enable cart &>>$LOG_FILE
VALIDATE $? "Enable cart"

systemctl restart cart
VALIDATE $? "Restarted cart"