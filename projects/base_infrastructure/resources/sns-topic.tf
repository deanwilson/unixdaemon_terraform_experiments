
module "admin-sns-email-topic" {
    source = "github.com/deanwilson/tf_sns_email"

    display_name  = "UnixDaemon Notifications"
    email_address = "${var.admin_email}"
    owner         = "UnixDaemon:Admin"
    stack_name    = "unixdaemon-admin-sns-email"
}
