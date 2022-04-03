data "aws_caller_identity" "this" {}

data "aws_region" "this" {}

data "aws_route53_zone" "this" {
  name = var.domain
}

data "archive_file" "lambda_function" {
  type        = "zip"
  output_path = "${path.module}/src.zip"

  source {
    content  = file("${path.module}/src/main.js")
    filename = "main.js"
  }

  source {
    content  = var.response_html
    filename = "response.html"
  }
}
