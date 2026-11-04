terraform {
  backend  "s3" {
    bucket ="our-backer"
    key    = "path/to/my/terraform.tfstate"
    region = "us-east-1"
  }
}