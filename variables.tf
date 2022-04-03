variable "domain" {
  description = "Domain to use for emails. Will be configured with MX records for receiving emails and DKIM records for sending emails securely."
  type        = string
}

variable "reply_from" {
  description = "The email address to reply to emails from."
  type        = string
}

variable "scan_enabled" {
  description = "If true, incoming emails will be scanned for spam and viruses."
  type        = bool
  default     = false
}

variable "recipients" {
  description = "Auto-reply to emails sent to this list of email addresses. If ommitted, email to all addresses on var.domain will be forwarded."
  type        = list(string)
  default     = []
}

variable "response_html" {
  description = "The email body in HTML to reply with."
  type        = string
}
