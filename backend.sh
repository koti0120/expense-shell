#!/bin/bash

USERID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE=/tmp/$SCRIPT_NAME-$TIMESTAMP.log
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
echo "please enter db password:"
read -s mysql_root_password

VALIDATE(){
    if [ $1 -ne 0 ]
    then
      echo -e "$2 is $R FAILURE $N"
      exit 1
    else
      echo -e "$2 is $G SUCCESS $N"
    fi
}

if [ $USERID -ne 0 ]
then
  echo "Please run this script with root user"
  exit 1
else
  echo "You are now super user"
fi

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "disable default node js"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "enable latest node js"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "install node js"

id expense
if [ $? -ne 0 ]
then
   useradd expense &>>$LOG_FILE
   VALIDATE $? "creating expense user"
else
   echo -e "user already created $Y SKIPPING $N"
fi

mkdir -p /app &>>$LOG_FILE
VALIDATE $? "creating app directory"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOG_FILE
VALIDATE $? "download the zip file"

cd /app &>>$LOG_FILE
unzip /tmp/backend.zip &>>$LOG_FILE
VALIDATE $? "extracting zip file"

npm install &>>$LOG_FILE
VALIDATE $? "installing node js depencies"

cp /home/ec2-user/expense-shell/backend.service /etc/systemd/system/backend.service &>>$LOG_FILE
VALIDATE $? "copied backend service"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "daemon reload"

systemctl start backend &>>$LOG_FILE
VALIDATE $? "start backend"

systemctl enable backend &>>$LOG_FILE
VALIDATE $? "enable backend"

dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "installing mysql"

mysql -h db.kanakm.top -uroot -p${mysql_root_password} < /app/schema/backend.sql &>>$LOG_FILE
VALIDATE $? "loading schema"

systemctl restart backend &>>$LOG_FILE
VALIDATE $? "restart backend"