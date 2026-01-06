
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
    
    # 2. Aqui, usamos o ID que o Data Source encontrou
    id = data.aws_canonical_user_id.current.id
  }

}

resource "aws_s3_bucket_acl" "example" {
  depends_on = [aws_s3_bucket_ownership_controls.example]

  bucket = aws_s3_bucket.example.id
  acl    = "private"
}