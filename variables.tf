variable "create" {
    type = bool
    default = true
}
variable "db_proxy_name" {
    type = string
}
variable "debug_logging" {
    type = bool
    default = false
}
variable "engine_family" {
    type = string
    default = "MYSQL"
}
variable "idle_client_timeout" {
    type = number
    default = "1800"
}
variable "require_tls" {
    type = bool
    default = true
}
variable "vpc_security_group_ids" {
    type = list
    default = []
}
variable "vpc_subnet_ids" {
    type = list
    default = []
}
variable "auth" {
    type = any
    default = []
}
variable "default_tags" {
    type = map(string)
    default = {}
}
variable "recovery_window_in_days" {
    type = number
    default = "0"
}
variable "version_stages" {
    type = list
    default = ["AWSCURRENT"]
}
variable "secret_string" {
    type = any
    default = {}
}
variable "connection_pool_config" {
    type = any
    default = []
}