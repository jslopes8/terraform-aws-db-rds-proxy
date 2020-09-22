data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "main"  {
    count = var.create ? 1 : 0

    statement {
        effect = "Allow"
        actions = [
            "secretsmanager:GetRandomPassword",
            "secretsmanager:CreateSecret",
            "secretsmanager:ListSecrets"
        ]
        resources = [
            "*"
        ]
    }
    statement {
        effect = "Allow"
        actions = [
            "secretsmanager:*",
        ]
        resources = [
            aws_secretsmanager_secret.main.0.arn
        ]
    }

}
data "aws_iam_policy_document" "role_rds"  {
    count = var.create ? 1 : 0

    statement {
        effect = "Allow"
        principals = {
            type        = "Service"
            identifiers = [ "rds.amazonaws.com" ]
        }
        actions = [ "sts:AssumeRole" ]
    }
}
resource "aws_iam_role" "role_rds" {
    count = var.create ? 1 : 0

    name               = "${var.db_proxy_name}-SecretManagerRole"
    assume_role_policy = data.aws_iam_policy_document.role_rds.0.json

    tags = merge(
        {
            "Name" = "${format("%s", var.db_proxy_name)}-SecretManager"
        },
        var.default_tags,
    )
}
resource "aws_iam_policy" "main" {
    count = var.create ? 1 : 0

    name = "${var.db_proxy_name}-SecretManagerPolicy"
    path = "/"
    policy = data.aws_iam_policy_document.main.0.json
}
resource "aws_iam_role_policy_attachment" "test-attach" {
    count = var.create ? 1 : 0

    role       = aws_iam_role.role_rd.0.name
    policy_arn = aws_iam_policy.main.0.arn
}

## Secret Manager
resource "aws_secretsmanager_secret" "main" {
    count = var.create ? 1 : 0

    name_prefix             = "${var.db_proxy_name}-secret"
    recovery_window_in_days =  var.recovery_window_in_days
    tags = var.default_tags
}
resource "aws_secretsmanager_secret_version" "main" {
    count = var.create ? 1 : 0

    secret_id = aws_secretsmanager_secret.main.id
    version_stages  = var.version_stages
    secret_string   = jsonencode(var.secret_string)

    lifecycle {
        ignore_changes = [ "secret_string" ]
    }
}

## RDS Proxy
resource "aws_db_proxy" "main" {
    depends_on = [ aws_iam_policy_document.main ]
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
            username    = lookup(auth.value, "username", null)
        }
    }

    tags = var.default_tags
}
resource "aws_db_proxy_default_target_group" "example" {
    count = var.create ? length(var.connection_pool_config) : 0 

    db_proxy_name = aws_db_proxy.main.0.name

    dynamic "connection_pool_config" {
        for_each = var.connection_pool_config
        content {
            connection_borrow_timeout    = lookup(var.connection_pool_config.value, "connection_borrow_timeout", null)
            init_query                   = lookup(var.init_query.value, "connection_borrow_timeout", null)
            max_connections_percent      = lookup(var.max_connections_percent.value, "connection_borrow_timeout", null)
            max_idle_connections_percent = lookup(var.max_idle_connections_percent.value, "connection_borrow_timeout", null)
            session_pinning_filters      = lookup(var.session_pinning_filters.value, "connection_borrow_timeout", null)
        }
    }
}