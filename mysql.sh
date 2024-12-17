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

dnf install mysql-server -y &>>$LOG_FILE
VALIDATE $? "installing mysql-server"

systemctl enable mysqld &>>$LOG_FILE
VALIDATE $? "enable mysqld" 

systemctl start mysqld &>>$LOG_FILE
VALIDATE $? "start mysql" 

# mysql_secure_installation --set-root-pass ExpenseApp@1 &>>$LOG_FILE
# VALIDATE $? "setting up root password"

#Below code is useful for idempotency nature
mysql -h db.kanakm.top -uroot -p${mysql_root_password} 'show databases;' &>>$LOG_FILE
if [ $? -ne 0 ]
then
   mysql_secure_installation --set-root-pass ${mysql_root_password} &>>$LOG_FILE
   VALIDATE $? "setting up root password"
   exit 1
else 
   echo -e "my sql root password already setup..$Y SKIPPING $N"
fi