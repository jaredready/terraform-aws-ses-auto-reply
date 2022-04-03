provider "aws" {
  region = "us-east-1"
}

module "ses_auto_reply" {
  source = "../"

  domain        = "example.com"
  reply_from    = "no-reply@example.com"
  response_html = file("response.html")
}
