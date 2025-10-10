#!/bin/bash


USERID=$(id -u)


R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"


LOGS_FOLDER="/var/log/shell-roboshop"
FILE_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$FILE_NAME.log"

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


# copying repository

cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "adding mango repo"

dnf install mongodb-org -y &>>$LOG_FILE
VALIDATE $? "Installing MongoDB"

systemctl enable mongod &>>$LOG_FILE
VALIDATE $? "Enable MongoDB"

systemctl start mongod 
VALIDATE $? "Start MongoDB"


sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "allowing remote connection"

systemctl restart mongod
VALIDATE $? "restarting mongod"