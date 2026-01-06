
data "aws_canonical_user_id" "current" {}

output "canonical_user_id" {
  value = data.aws_canonical_user_id.current.id
}

#bucket S3 
resource "aws_s3_bucket" "my_bucket_teste" {
  bucket        = var.bucket
  region        = var.region
  force_destroy = true


  tags = {
    Name        = "My bucket"
    Environment = "Dev"
    manged_by   = "Terraform"

  }

  grant {
    type        = "CanonicalUser"
    permissions = ["FULL_CONTROL"]
    id          = data.aws_canonical_user_id.current.id
}


}
