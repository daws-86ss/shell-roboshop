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


dnf install mysql-server -y &>>$LOG_FILE
VALIDATE $? "installing mysql server"

systemctl enable mysqld &>>$LOG_FILE
VALIDATE $? "enabling mysql server"

systemctl start mysqld &>>$LOG_FILE
VALIDATE $? "starting mysql server"

mysql_secure_installation --set-root-pass RoboShop@1
VALIDATE $? "set the root password"

END_TIME=$(date +%s)

TOTAL_TIME=$(( $END_TIME-$START_TIME))
echo -e "script executed in $G $TOTAL_TIME..seconds $N"