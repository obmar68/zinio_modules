terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  version = "~> 2.7"
  region  = "us-east-1"
}

resource "random_string" "cloudfront_rstring" {
  length  = 18
  upper   = false
  special = false
}

resource "aws_s3_bucket" "cloudfront_s3bucket" {
  bucket = "${random_string.cloudfront_rstring.result}-cf-distro-bucket"
  acl    = "public-read"
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "origin accessid for cloudfront"
}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.cloudfront_s3bucket.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.cloudfront_s3bucket.arn]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudfront_s3bucket_policy" {
  bucket = aws_s3_bucket.cloudfront_s3bucket.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

module "cloudfront_s3_origin" {
  source = "git@github.com:obmar68/zinio_modules.git//aws-terraform-cloudfront_s3_origin"

  allowed_methods                 = ["GET", "HEAD"]
  bucket_logging                  = false
  cached_methods                  = ["GET", "HEAD"]
  cloudfront_default_certificate  = true
  comment                         = "This is a test comment"
  default_root_object             = "index.html"
  default_ttl                     = 3600
  domain_name                     = aws_s3_bucket.cloudfront_s3bucket.bucket_regional_domain_name
  enabled                         = true
  forward                         = "none"
  locations                       = ["US", "CA", "GB", "DE"]
  origin_access_identity          = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
  origin_access_identity_provided = true
  origin_id                       = random_string.cloudfront_rstring.result
  path_pattern                    = "*"
  price_class                     = "PriceClass_200"
  query_string                    = false
  restriction_type                = "whitelist"
  target_origin_id                = random_string.cloudfront_rstring.result
  viewer_protocol_policy          = "redirect-to-https"

  custom_error_response = [
    {
      error_code            = 404
      error_caching_min_ttl = 30
    },
    {
      error_code            = 403
      error_caching_min_ttl = 30
      response_code         = 200
      response_page_path    = "/error_page.html"
    },
  ]
}
