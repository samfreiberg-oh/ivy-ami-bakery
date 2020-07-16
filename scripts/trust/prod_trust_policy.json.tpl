{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
      "Principal": {
        "AWS": "arn:${AWS_IDENTITY_PARTITION}:iam::${CHILD_ACCOUNT_ID}:role/${CHILD_ACCOUNT_ROLE}"
      },
    "Action": "sts:AssumeRole"
  }]
}
