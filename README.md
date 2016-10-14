# kops-tf

## AWS Auth
```
$ cat ~/.aws/my-aws-account
#!/bin/bash
export AWS_ACCESS_KEY_ID=AKIA*********************
export AWS_SECRET_ACCESS_KEY=******************************
export AWS_DEFAULT_REGION=us-west-1
CREDS=$(aws sts get-session-token --serial-number arn:aws:iam::***************:mfa/user --token-code="$1")
export AWS_ACCESS_KEY_ID=$(echo $CREDS|jq -r .Credentials.AccessKeyId)
export AWS_SECRET_ACCESS_KEY=$(echo $CREDS|jq -r .Credentials.SecretAccessKey)
export AWS_SESSION_TOKEN=$(echo $CREDS|jq -r .Credentials.SessionToken)
### TERRAFORM ENVARS
export TF_VAR_access_key=$AWS_ACCESS_KEY_ID
export TF_VAR_region=$AWS_DEFAULT_REGION
export TF_VAR_secret_key=$AWS_SECRET_ACCESS_KEY
export TF_VAR_token=$AWS_SESSION_TOKEN
```
`source ~/.aws/my-aws-account $MFA`

## kops state store configuration and kops init
`export KOPS_STATE_STORE=s3://<somes3bucket>`
`export CLUSTER_NAME=<kubernetes.mydomain.com>`
`${GOPATH}/bin/kops create cluster ${CLUSTER_NAME} —zones=us-west-1a,us-west-1b,us-west-1c`

## Terraform variables and deploy
Using`vars.tfvars` set the requisite parameters for the variables in `variables.tf`

`terraform —var-file=vars.tfvars plan`
`terraform —var-file=vars.tfvars apply`

## Interacting with your new cluster
`${GOPATH}/bin/kops export kubecfg ${CLUSTER_NAME}`
`kubectl get nodes`
You’re good to go!

## Destroy Cluster
`terraform —var-file=vars.tfvars destroy`
`${GOPATH}/bin/kops delete ${CLUSTER_NAME} —yes`
