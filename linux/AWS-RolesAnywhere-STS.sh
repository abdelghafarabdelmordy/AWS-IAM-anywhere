#!/bin/bash

# Configuration
ROLE_ARN="arn:aws:iam::14********395:role/anywhere-s3-full-role"
PROFILE_ARN="arn:aws:rolesanywhere:us-east-1:14********395:profile/25f3ab09-5ee4-4e3e-b423-b*****b0395"
TRUST_ANCHOR_ARN="arn:aws:rolesanywhere:us-east-1:14********395:trust-anchor/a70864db-816d-4b60-bbc6-77a*****d362"
CERT="stratusgrid01-client.crt"
KEY="cloudlyy01-client.key"
SESSION_DURATION="7200"  # 1 hour

# Output file for credentials
CRED_FILE="/tmp/aws_creds.json"

# Fetch STS credentials
aws_signing_helper credential-process \
  --certificate "$CERT" \
  --private-key "$KEY" \
  --role-arn "$ROLE_ARN" \
  --profile-arn "$PROFILE_ARN" \
  --trust-anchor-arn "$TRUST_ANCHOR_ARN" \
  --session-duration "$SESSION_DURATION" \
  > "$CRED_FILE"

# Export credentials to environment
export AWS_ACCESS_KEY_ID=$(jq -r '.AccessKeyId' "$CRED_FILE")
export AWS_SECRET_ACCESS_KEY=$(jq -r '.SecretAccessKey' "$CRED_FILE")
export AWS_SESSION_TOKEN=$(jq -r '.SessionToken' "$CRED_FILE")

# Optional: print confirmation
echo "Temporary credentials set for role:"
echo "  AWS_ACCESS_KEY_ID=$(echo "$AWS_ACCESS_KEY_ID" | cut -c1-4)********"
echo "  Expires in ${SESSION_DURATION} seconds"

