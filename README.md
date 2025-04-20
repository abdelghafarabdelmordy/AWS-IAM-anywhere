Connecting Non-AWS External Servers to AWS Resources using IAM Roles Anywhere

Recently, I successfully enabled remote servers outside the AWS Cloud to access AWS resources such as Amazon S3 by using AWS IAM Roles Anywhere, This implementation adheres to AWS best practices by acquiring temporary credentials via AWS STS, avoiding the use of long-lived credentials.

You can read more about it in this URL https://docs.aws.amazon.com/rolesanywhere/latest/userguide/introduction.html

Automation Script , you can find all in this compressed file in this repo.

I created a script that includes example certificates, allowing anyone to use it. You just need to update the required parameters:

Account ID
Role ARN
Any other environment-specific values

Make sure to use the cloudlyy01-ca.crt file in your AWS Roles Anywhere configuration.
This setup will generate a temporary credential valid for 12 hours or depend on your configuration.

i used this tool to easily create the certificates, https://smallstep.com/docs/step-ca/installation/ , by these commands


./step certificate create "pearson 01" pearson01-ca.crt pearson01-ca.key --profile root-ca
./step certificate create "pearson01 client01" pearson01-client.crt pearson01-client.key --profile leaf --ca .\pearson01-ca.crt --ca-key .\pearson01-ca.key
./step crypto change-pass .\pearson01-client.key  #remove password

Keeping the Connection Alive

To ensure uninterrupted connectivity:

I automated the creation of a scheduled task that runs the script every 11 hours
This refreshes the credentials before they expire, keeping the connection stable if you are ina process like uploading large files to AWS S3 for example.
