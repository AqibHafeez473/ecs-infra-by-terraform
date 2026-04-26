terraform {
  backend "s3" {
    # Run bootstrap first, then replace <BUCKET_NAME> with:
    #   cd ../bootstrap && terraform output s3_bucket_name
    bucket         = "<BUCKET_NAME>"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "<DYNAMODB_TABLE_NAME>"
    encrypt        = true
  }
}
