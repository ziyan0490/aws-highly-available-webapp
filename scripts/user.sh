#!/bin/bash
dnf install -y
dnf install httpd -y
systemctl start httpd
systemctl enable httpd

TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
instance_id=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)  

cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>AWS EC2 Instance Info</title>
<style>
  body { font-family: Arial, sans-serif; background: #232f3e; color: #fff;
         display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
  .card { background: #fff; color: #232f3e; padding: 40px 60px; border-radius: 10px;
          box-shadow: 0 8px 24px rgba(0,0,0,0.3); text-align: center; }
  h1 { color: #ff9900; }
  p { font-size: 18px; margin: 10px 0; }
  span { font-weight: bold; color: #146eb4; }
</style>
</head>
<body>
  <div class="card">
    <h1>🚀 WEBSERVER IS RUNNING</h1>
    <p>Instance ID: <span>$instance_id</span></p>
    <p>Availability Zone: <span>$AZ</span></p>
    <p>Web Server: <span>Apache (httpd)</span></p>
    <p>created by mohamed ziyan khalid </span></p>
    <P>
  </div>
</body>
</html>
EOF