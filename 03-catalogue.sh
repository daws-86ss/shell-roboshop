#!/bin/bash

USERID=$(id -u)


R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"


LOGS_FOLDER="/var/log/shell-roboshop"
FILE_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$FILE_NAME.log"
SCRIPT_DIR=$PWD
MONGODB_HOST=mongodb.awspractice.store

mkdir -p $LOGS_FOLDER

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

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling NodeJS"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling NodeJS"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "installing NodeJS"
id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Adding systemuser"
else
    echo -e "user already exist ...$Y skipping $N"
fi

mkdir -p /app 
VALIDATE $? "creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "Zip catalogue file"

cd /app 
VALIDATE $? "changing to app directory"

rm -rf /app/*
VALIDATE $? "removing existing the code"

unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "unzip the catalogue"

npm install &>>$LOG_FILE
VALIDATE $? "installing dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "copy catalogue service"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "validating daemon relod"

systemctl enable catalogue &>>$LOG_FILE
VALIDATE $? "enabling catalogue"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo 
VALIDATE $? "copying mongo repo"

dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "installing mongo server"

INDEX=$(mongosh mongodb.awspractice.store --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")
if [ $INDEX -le 0 ]; then
    mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
else
    echo -e "Catalogue products already loaded ... $Y SKIPPING $N"
fi

systemctl restart catalogue &>>$LOG_FILE
VALIDATE $? "restarting catalogue"



