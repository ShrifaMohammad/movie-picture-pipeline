#!/bin/bash
# Movie Picture Pipeline - AWS setup in one go
# Usage:  bash movie-picture-pipeline/setup/bootstrap.sh
set -e
ROOT="$(cd "$(dirname "$0")" && pwd)"

echo "== 1/6 Installing Terraform 1.3.9 =="
if ! command -v tfenv >/dev/null 2>&1; then
  [ -d "$HOME/.tfenv" ] || git clone --depth 1 https://github.com/tfutils/tfenv.git "$HOME/.tfenv"
  export PATH="$HOME/.tfenv/bin:$PATH"
fi
tfenv install 1.3.9
tfenv use 1.3.9

echo "== 2/6 Checking AWS credentials =="
if ! aws sts get-caller-identity >/dev/null 2>&1; then
  echo "AWS credentials not found. Paste or type them from the Cloud Resources page:"
  read -r -p "AWS Access Key ID: " AWS_ACCESS_KEY_ID
  read -r -s -p "AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY; echo
  read -r -s -p "AWS Session Token (leave empty if none): " AWS_SESSION_TOKEN; echo
  export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
  if [ -n "$AWS_SESSION_TOKEN" ]; then export AWS_SESSION_TOKEN; fi
  aws sts get-caller-identity
fi

echo "== 3/6 Terraform apply (10-15 minutes) =="
cd "$ROOT/terraform"
terraform init
terraform apply -auto-approve

echo "== 4/6 Connecting kubectl to the cluster =="
aws eks update-kubeconfig --name cluster --region us-east-1

echo "== 5/6 Giving github-action-user access to the cluster =="
cd "$ROOT"
./init.sh

echo "== 6/6 Creating access keys for GitHub Actions =="
aws iam create-access-key --user-name github-action-user \
  --query 'AccessKey.[AccessKeyId,SecretAccessKey]' --output text > "$HOME/github-action-keys.txt"
echo
echo "Done! Terraform outputs:"
cd "$ROOT/terraform" && terraform output
echo
echo "GitHub Actions keys saved in: $HOME/github-action-keys.txt"
echo "First value = AWS_ACCESS_KEY_ID, second value = AWS_SECRET_ACCESS_KEY"
echo "Show them with:  cat ~/github-action-keys.txt"
