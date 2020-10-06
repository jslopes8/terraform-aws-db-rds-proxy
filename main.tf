#
# RDS Proxy
#

resource "aws_db_proxy" "main" {
    count = var.create ? 1 : 0
    
    name                   = var.db_proxy_name
    debug_logging          = var.debug_logging
    engine_family          = var.engine_family
    idle_client_timeout    = var.idle_client_timeout
    require_tls            = var.require_tls
    role_arn               = aws_iam_role.role_rds.0.arn
    vpc_security_group_ids = var.vpc_security_group_ids
    vpc_subnet_ids         = var.vpc_subnet_ids

    dynamic "auth" {
        for_each = var.auth
        content {
            auth_scheme = lookup(auth.value, "auth_scheme", "SECRETS")
            description = lookup(auth.value, "description", null)
            iam_auth    = lookup(auth.value, "iam_auth", "DISABLED")
            secret_arn  = aws_secretsmanager_secret.main.0.arn
        }
    }

    tags = var.default_tags
}
resource "aws_db_proxy_default_target_group" "main" {
    count = var.create ? length(var.connection_pool_config) : 0 

    db_proxy_name = aws_db_proxy.main.0.name

    dynamic "connection_pool_config" {
        for_each = var.connection_pool_config
        content {
            connection_borrow_timeout    = lookup(var.connection_pool_config.value, "connection_borrow_timeout", null)
            init_query                   = lookup(var.connection_pool_config.value, "init_query", null)
            max_connections_percent      = lookup(var.connection_pool_config.value, "max_connections_percent", null)
            max_idle_connections_percent = lookup(var.connection_pool_config.value, "max_idle_connections_percent", null)
            session_pinning_filters      = lookup(var.connection_pool_config.value, "session_pinning_filters", null)
        }
    }
}
resource "aws_db_proxy_target" "main" {
    count = var.create ? 1 : 0

    db_instance_identifier  = var.db_instance_identifier
    db_cluster_identifier   = var.db_cluster_identifier
    db_proxy_name           = aws_db_proxy.main.0.name
    target_group_name       = aws_db_proxy_default_target_group.main.0.name
}