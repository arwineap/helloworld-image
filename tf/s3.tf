resource "aws_s3_bucket" "int-helloworld-image" {
  bucket = "int-helloworld-image"
  acl    = "public-read"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    prefix  = "/"
    enabled = true

    noncurrent_version_expiration {
      days = 1
    }
  }
}

resource "aws_s3_bucket" "int-terraform-state-1564544704" {
  bucket = "int-terraform-state-1564544704"
  acl    = "private"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    prefix  = "/"
    enabled = true

    noncurrent_version_expiration {
      days = 30
    }

    expiration {
      days = 30
    }
  }
}
