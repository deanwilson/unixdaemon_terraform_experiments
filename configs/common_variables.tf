variable "admin_email" {
    description = "Admin email account"
}

variable "admin_users" {
    description = "A CSV string of admin users"
}

variable "environment" {
    description = "The environment resources are to be deployed in"
}

variable "read_only_users" {
    description = "A CSV string of read only users"
}
