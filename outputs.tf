output "endpoint" {
    value = aws_db_proxy_target.main.0.endpoint
}
output "port" {
    value = aws_db_proxy_target.main.0.port
}
output "id" {
    value = aws_db_proxy_target.main.0.id
}