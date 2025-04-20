🔐 Connecting Non-AWS External Servers to AWS Resources using IAM Roles Anywhere

This project demonstrates how to securely connect servers outside AWS to AWS resources like Amazon S3 using IAM Roles Anywhere. This solution follows AWS security best practices by utilizing temporary credentials via AWS STS, eliminating the need for long-lived access keys.

📁 What's Included
All required scripts and example certificates are included in the compressed file available in this repo. These help you automate the setup process and start accessing AWS resources from external servers.

⚙️ Setup Instructions
Update the Script Parameters
Modify the script with the following values specific to your environment:

Your AWS Account ID

The Role ARN to assume

Any other environment-specific values

Use the Certificate
Ensure you reference the provided cloudlyy01-ca.crt file when configuring IAM Roles Anywhere in AWS.

Temporary Credentials
The script generates temporary credentials (valid for up to 12 hours, or based on your configuration) using IAM Roles Anywhere and STS.

🔧 Creating Certificates
You can easily generate the required certificates using step-ca:

# Create Root CA
./step certificate create "cloudlyy 01" cloudlyy01-ca.crt cloudlyy01-ca.key --profile root-ca

# Create Client Certificate
./step certificate create "cloudlyy01 client01" cloudly01-client.crt cloudly01-client.key --profile leaf --ca ./cloudlyy01-ca.crt --ca-key ./cloudlyy01-ca.key

# Remove password from the client key
./step crypto change-pass ./cloudly01-client.key


🔁 Keeping the Connection Alive

To maintain continuous access:

A scheduled task is created to run the script every 11 hours.

This refreshes the temporary credentials before they expire.

Ensures stable access to AWS services, especially useful for tasks like uploading large files to S3.

📚 Learn More
AWS IAM Roles Anywhere - Documentation  https://docs.aws.amazon.com/rolesanywhere/latest/userguide/introduction.html
