#web autoscaling
resource "aws_ami_from_instance" "final-webwas-ami" {
  name               = "final-webwas-ami"
  source_instance_id = aws_instance.final-ec2-pub-a-bastion.id
  depends_on = [
    aws_instance.final-ec2-pub-a-bastion
  ]

}

resource "aws_launch_configuration" "final-web-lacf" {
  name                 = "final-web-lacf"
  image_id             = aws_ami_from_instance.final-webwas-ami.id
  instance_type        = "t3.micro"
  iam_instance_profile = "admin_role"
  security_groups      = [aws_security_group.final-sg-pri-web.id]
  key_name             = "final-key"
  user_data            =  <<EOF
  #!/bin/bash
sudo su -
ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime
sed -i "s/#Port 22/Port 6022/g" /etc/ssh/sshd_config
systemctl restart sshd
yum install httpd -y
systemctl start httpd
systemctl status httpd
systemctl enable httpd
sed -i 's\CustomLog "logs/access_log" combined\CustomLog "|/usr/sbin/rotatelogs logs/access_log.%y%m%d 86400" combined\g' /etc/httpd/conf/httpd.conf
sed -i 's\ErrorLog "logs/error_log"\ErrorLog "|/usr/sbin/rotatelogs logs/error_log.%y%m%d 86400"\g' /etc/httpd/conf/httpd.conf
cat >> /etc/httpd/conf/httpd.conf<<A
ProxyRequests Off
ProxyPreserveHost On
<Proxy *>
Order deny,allow
Allow from all
</Proxy>
ProxyPass /petclinic http://${aws_lb.final-nlb-was.dns_name}:8080/petclinic
ProxyPassReverse / http://${aws_lb.final-nlb-was.dns_name}:8080/
A
systemctl restart httpd

pip3 install boto3

cat >> /root/web-log.py<<A
import boto3
import datetime

s3 = boto3.resource('s3')
bucket_name = 'final001-bucket'
bucket = s3.Bucket(bucket_name)
d = datetime.datetime.now()

z = str(d)
y = z[2:4]
m = z[5:7]
da = z[8:10]

local_file1 = '/var/log/httpd/access_log.'+str(y)+str(m)+str(da)
obj_file1 = 'web_access/web/'+str(d.date())
bucket.upload_file(local_file1 , obj_file1)

local_file2 = '/var/log/httpd/error_log.'+ str(y)+str(m)+str(da)
obj_file2 = 'web_error/web/'+str(d.date())
bucket.upload_file(local_file2 , obj_file2)
A

cat >> /etc/crontab<<A
59 11,23 * * *  root    python3 web-log.py
A
EOF
}

resource "aws_autoscaling_group" "final-web-atsg" {
  name                      = "final-web-atsg"
  min_size                  = 2
  max_size                  = 10
  health_check_grace_period = 60
  health_check_type         = "EC2"
  desired_capacity          = 2
  force_delete              = false
  launch_configuration      = aws_launch_configuration.final-web-lacf.id
  vpc_zone_identifier       = [aws_subnet.final-sub-pri-a-web.id, aws_subnet.final-sub-pri-c-web.id]

  tag {
    key                 = "Name"
    value               = "web"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "final-web-tra" {
  name                   = "final-web-tracking-policy"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.final-web-atsg.name
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = "60"

  }
}

resource "aws_autoscaling_attachment" "final-web-asatt" {
  autoscaling_group_name = aws_autoscaling_group.final-web-atsg.id
  alb_target_group_arn   = aws_lb_target_group.final-atg-web.arn
}


#was autoscaling
/*resource "aws_ami_from_instance" "final-was-ami" {
  name               = "final-was-ami"
  source_instance_id = aws_instance.final-ec2-pub-a-bastion.id
  depends_on = [
    aws_instance.final-ec2-pub-a-bastion
  ]

}
*/
resource "aws_launch_configuration" "final-was-lacf" {
  name                 = "final-was-lacf"
  image_id             = aws_ami_from_instance.final-webwas-ami.id
  instance_type        = "t3.medium"
  iam_instance_profile = "admin_role"
  security_groups      = [aws_security_group.final-sg-pri-was.id]
  key_name             = "final-key"
  user_data            =  <<EOF
  #!/bin/bash
sudo -i
ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime
sed -i "s/#Port 22/Port 6022/g" /etc/ssh/sshd_config
systemctl restart sshd
amazon-linux-extras install java-openjdk11 -y
useradd -r -m -U -d /opt/tomcat -s /bin/false tomcat
wget https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.56/bin/apache-tomcat-9.0.56.tar.gz -P /tmp
tar xf /tmp/apache-tomcat-9*.tar.gz -C /opt/tomcat
ln -s /opt/tomcat/apache-tomcat-9.0.56 /opt/tomcat/latest
chown -RH tomcat: /opt/tomcat/latest
sh -c 'chmod +x /opt/tomcat/latest/bin/*.sh'
cat >> /etc/systemd/system/tomcat.service << A
[Unit]
Description=tomcat9.0.56
After=network.target syslog.target

[Service]
Type=forking

Environment=CATALINA_HOME=/opt/tomcat/latest
User=root
Group=root

ExecStart=/opt/tomcat/latest/bin/startup.sh
ExecStop=/opt/tomcat/latest/bin/shutdown.sh

UMask=0007
RestartSec=10
Restart=always

SuccessExitStatus=143

[Install]
WantedBy=multi-user.target
A
systemctl daemon-reload
systemctl start tomcat
systemctl enable tomcat
sed -i 's/prefix="localhost_access_log" suffix=".txt"/prefix="localhost_access_log" suffix=".log"/g' /opt/tomcat/latest/conf/server.xml
tee /opt/tomcat/latest/conf/tomcat-users.xml << A
<?xml version="1.0" encoding="UTF-8"?>
<!--
  Licensed to the Apache Software Foundation (ASF) under one or more
  contributor license agreements.  See the NOTICE file distributed with
  this work for additional information regarding copyright ownership.
  The ASF licenses this file to You under the Apache License, Version 2.0
  (the "License"); you may not use this file except in compliance with
  the License.  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
-->
<tomcat-users xmlns="http://tomcat.apache.org/xml"
              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
              xsi:schemaLocation="http://tomcat.apache.org/xml tomcat-users.xsd"
              version="1.0">
<!--
  By default, no user is included in the "manager-gui" role required
  to operate the "/manager/html" web application.  If you wish to use this app,
  you must define such a user - the username and password are arbitrary.

  Built-in Tomcat manager roles:
    - manager-gui    - allows access to the HTML GUI and the status pages
    - manager-script - allows access to the HTTP API and the status pages
    - manager-jmx    - allows access to the JMX proxy and the status pages
    - manager-status - allows access to the status pages only

  The users below are wrapped in a comment and are therefore ignored. If you
  wish to configure one or more of these users for use with the manager web
  application, do not forget to remove the <!.. ..> that surrounds them. You
  will also need to set the passwords to something appropriate.
-->
<!--
  <user username="admin" password="<must-be-changed>" roles="manager-gui"/>
  <user username="robot" password="<must-be-changed>" roles="manager-script"/>
-->
<!--
  The sample user and role entries below are intended for use with the
  examples web application. They are wrapped in a comment and thus are ignored
  when reading this file. If you wish to configure these users for use with the
  examples web application, do not forget to remove the <!.. ..> that surrounds
  them. You will also need to set the passwords to something appropriate.
-->
<!--
  <role rolename="tomcat"/>
  <role rolename="role1"/>
  <user username="tomcat" password="<must-be-changed>" roles="tomcat"/>
  <user username="both" password="<must-be-changed>" roles="tomcat,role1"/>
  <user username="role1" password="<must-be-changed>" roles="role1"/>
-->
<role rolename="manager-script"/>
    <role rolename="manager-gui"/>
    <role rolename="manager-jmx"/>
    <role rolename="manager-status"/>
    <user username="tomcat" password="tomcat" roles="manager-gui,manager-script,manager-status,manager-jmx"/>
</tomcat-users>
A
tee /opt/tomcat/latest/webapps/manager/META-INF/context.xml << A
<?xml version="1.0" encoding="UTF-8"?>
<!--
  Licensed to the Apache Software Foundation (ASF) under one or more
  contributor license agreements.  See the NOTICE file distributed with
  this work for additional information regarding copyright ownership.
  The ASF licenses this file to You under the Apache License, Version 2.0
  (the "License"); you may not use this file except in compliance with
  the License.  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
-->
<Context antiResourceLocking="false" privileged="true" >
  <CookieProcessor className="org.apache.tomcat.util.http.Rfc6265CookieProcessor"
                   sameSiteCookies="strict" />
  <!--
  <Valve className="org.apache.catalina.valves.RemoteAddrValve"
         allow="127\.\d+\.\d+\.\d+|::1|0:0:0:0:0:0:0:1" />
  -->
          <Manager sessionAttributeValueClassNameFilter="java\.lang\.(?:Boolean|Integer|Long|Number|String)|org\.apache\.catalina\.filters\.CsrfPreventionFilter\$LruCache(?:\$1)?|java\.util\.(?:Linked)?HashMap"/>
</Context>
A
tee /opt/tomcat/latest/webapps/host-manager/META-INF/context.xml << A
<?xml version="1.0" encoding="UTF-8"?>
<!--
  Licensed to the Apache Software Foundation (ASF) under one or more
  contributor license agreements.  See the NOTICE file distributed with
  this work for additional information regarding copyright ownership.
  The ASF licenses this file to You under the Apache License, Version 2.0
  (the "License"); you may not use this file except in compliance with
  the License.  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
-->
<Context antiResourceLocking="false" privileged="true" >
  <CookieProcessor className="org.apache.tomcat.util.http.Rfc6265CookieProcessor"
                   sameSiteCookies="strict" />
  <!--
  <Valve className="org.apache.catalina.valves.RemoteAddrValve"
         allow="127\.\d+\.\d+\.\d+|::1|0:0:0:0:0:0:0:1" />
  -->
          <Manager sessionAttributeValueClassNameFilter="java\.lang\.(?:Boolean|Integer|Long|Number|String)|org\.apache\.catalina\.filters\.CsrfPreventionFilter\$LruCache(?:\$1)?|java\.util\.(?:Linked)?HashMap"/>
</Context>
A
systemctl restart tomcat
yum install git -y
pip3 install boto3
cat >> /root/was-log.py<<A
import boto3
import datetime

s3 = boto3.resource('s3')
bucket_name = 'final001-bucket'
bucket = s3.Bucket(bucket_name)
d = datetime.datetime.now()
local_file = '/opt/tomcat/latest/logs/localhost_access_log.'+str(d.date())+'.log'
obj_file = 'was-log/was/'+str(d.date())
bucket.upload_file(local_file , obj_file)
A

cat >> /etc/crontab<<A
59 11,23 * * *  root    python3 was-log.py
A
EOF
}


resource "aws_autoscaling_group" "final-was-atsg" {
  name                      = "final-was-atsg"
  min_size                  = 2
  max_size                  = 10
  health_check_grace_period = 60
  health_check_type         = "EC2"
  desired_capacity          = 2
  force_delete              = false
  launch_configuration      = aws_launch_configuration.final-was-lacf.id
  vpc_zone_identifier       = [aws_subnet.final-sub-pri-a-was.id, aws_subnet.final-sub-pri-c-was.id]
  tag {
    key                 = "Name"
    value               = "was"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "final-was-tra" {
  name                   = "final-was-tracking-policy"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.final-was-atsg.name
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = "60"

  }
}

resource "aws_autoscaling_attachment" "final-was-asatt" {
  autoscaling_group_name = aws_autoscaling_group.final-was-atsg.id
  alb_target_group_arn   = aws_lb_target_group.final-ntg-was.arn
}