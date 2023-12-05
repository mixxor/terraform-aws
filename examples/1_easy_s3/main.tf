provider "aws" {
    region = "eu-central-1"
}

resource "aws_s3_bucket" "static_site" {
  bucket = "static-site-mad-summit"

  // Weitere Konfigurationen nach Bedarf...
}

resource "aws_s3_bucket_public_access_block" "static_site_public_access" {
  bucket = aws_s3_bucket.static_site.id

  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}


resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = aws_s3_bucket.static_site.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "example" {
  depends_on = [aws_s3_bucket_ownership_controls.example]

  bucket = aws_s3_bucket.static_site.id
  acl    = "public-read-write"
}



resource "aws_s3_bucket_website_configuration" "static_site_website" {
  bucket = aws_s3_bucket.static_site.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }

  // Weitere Konfigurationen nach Bedarf...
}

resource "aws_s3_bucket_policy" "static_site_policy" {
  bucket = aws_s3_bucket.static_site.bucket

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = "*",
        Action = ["s3:GetObject"],
        Resource = ["${aws_s3_bucket.static_site.arn}/*"]
      },
    ],
  })
}


resource "aws_s3_object" "mein_object" {
   depends_on = [aws_s3_bucket.static_site]
   bucket = aws_s3_bucket.static_site.bucket 
   key    = "index.html"               // Der Schlüsselname im S3-Bucket
   source = "index1.html"        // Der lokale Pfad zur Datei, die hochgeladen werden soll
   acl    = "public-read-write"                      // Setzt die ACL für das Objekt, um es öffentlich lesbar zu machen
  content_type = "text/html" 
}





# resource "aws_cloudfront_distribution" "s3_distribution" {
#   origin {
#     domain_name = aws_s3_bucket.static_site.bucket_regional_domain_name
#     origin_id   = "S3-${aws_s3_bucket.static_site.id}"
#   }

#   enabled             = true
#   default_root_object = "index.html"

#   default_cache_behavior {
#     allowed_methods  = ["GET", "HEAD"]
#     cached_methods   = ["GET", "HEAD"]
#     target_origin_id = "S3-${aws_s3_bucket.static_site.id}"

#     forwarded_values {
#       query_string = false

#       cookies {
#         forward = "none"
#       }
#     }

#     viewer_protocol_policy = "redirect-to-https"
#     min_ttl                = 0
#     default_ttl            = 3600
#     max_ttl                = 86400
#   }

#   price_class = "PriceClass_100"

#   restrictions {
#     geo_restriction {
#       restriction_type = "none"
#     }
#   }

#   viewer_certificate {
#     cloudfront_default_certificate = true
#   }
# }

# output "cloudfront_adress" {
#   description = "Cloudfront URL"
#   value = aws_cloudfront_distribution.s3_distribution.domain_name
# }