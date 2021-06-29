# Terraform Module AWS RDS Proxy
Terraform module irá provisionar os seguintes recursos:

* [DB Proxy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_proxy)
* [DB Proxy Target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_proxy_target)
* [DB Proxy Default Target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_proxy_default_target_group)
* [Secret Manager Secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret)
* [Secret Manager Secret Version](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version)
* [IAM Policy Document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document)
* [IAM Role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)

# Usage
`Caso de uso`: RDS Proxy MySQL com Secret Manager
```bash
module "rds_proxy_pucrs" {
  source = "git::https://github.com/jslopes8/terraform-aws-db-proxy.git?ref=v3.0"

  db_proxy_name           = "db-proxy-mysql"
  engine_family           = "MYSQL"
  db_instance_identifier  = module.db_instance.id

  vpc_subnet_ids = [ 
    tolist(data.aws_subnet_ids.priv.ids)[0],
    tolist(data.aws_subnet_ids.priv.ids)[1],
    tolist(data.aws_subnet_ids.priv.ids)[2]
  ]
  vpc_security_group_ids  = [ module.db_instance_sg.id ]
  connection_pool_config  = [{
    init_query                    = "SET x=1, y=2"
    connection_borrow_timeout     = "120"
    max_connections_percent       = "100"
    max_idle_connections_percent  = "50"
    session_pinning_filters       = ["EXCLUDE_VARIABLE_SETS"] 
  }]

  auth = [{ 
    iam_auth    = "DISABLED"
    auth_scheme = "SECRETS"
  }]

  secretsmanager = [{
    recovery_window_in_days = "0"
    version_stages  = ["AWSCURRENT"]
    secret_string   = {
      username = local.username
      password = local.password
    }
  }]

  default_tags = local.default_tags
}
```

## Requirements

| Name | Version|
|------|--------|
| aws | 3.* |
| terraform | 0.15.*| 

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Variables Inputs
| Name | Description | Required | Type | Default |
| ---- | ----------- | -------- | ---- | ------- |
| db_proxy_name | O nome do RDS Proxy. | `yes` | `string` | ` ` |
| engine_family | O tipo do database que o proxy irá conectar. Valores validos `MYSQL` e `POSTGRESQL`. | `yes` | `string` | `MYSQL` |
| db_instance_identifier | Identificador da instância do banco de dados. Não deve ser especificado em conjunto com o `db_cluster_identifier`. | `yes` | `string` | ` ` |
| db_cluster_identifier |  Identificador de cluster de banco de dados. Não deve ser especificado em conjunto com o `db_instance_identifier`. | `yes` | `string` | ` ` |
| debug_logging | Se o proxy inclui informações detalhadas sobre instruções SQL em seus logs. | `no` | `bool`| `false` |
| vpc_subnet_ids | Uma lista com um ou mais IDs de sub-rede para associar ao novo proxy. | `yes` | `list` | `[ ]` |
| vpc_security_group_ids | Uma lista com um ou mais IDs de security group para associar ao novo proxy. | `yes` | `list` | `[ ]` |
| connection_pool_config | As configurações que determinam o tamanho e o comportamento do pool de conexão para o grupo de destino. Abaixo segue detalhes.  | `yes` | `list` | `[ ]` |
| auth | Configuração com mecanismos de autorização para se conectar às instâncias ou clusters associados. Abaixo segue detalhes. | `yes` | `list` | `[ ]` |
| idle_client_timeout | O número de segundos que uma conexão com o proxy pode ficar inativa antes que o proxy a desconecte. | `no` | `number` | `1800` |
| require_tls | Especifica se a criptografia TLS (Transport Layer Security) é necessária para conexões com o proxy. | `no` | `bool` | `true` |
| default_tags | Um mapa de chave-valor para tagueamento do recursos. | `no` | `map` | `{ }` | 
| secretsmanager | Configuração com mecanismos para gerenciar o secret. Abaixo segue detalhes. | `no` | `list` | `[ ]` |
| enabled_depends_on | Use quando tiver dependências de módulo. | `no` | `list` | `[ ]` |

O argumento `connection_pool_config` possui os seguintes atributos;
- `init_query`: (Opcional) Uma ou mais instruções SQL para o proxy executar ao abrir cada nova conexão de banco de dados.
- `connection_borrow_timeout`: (Opcional) O número de segundos para um proxy aguardar até que uma conexão se torne disponível no pool de conexão.
- `max_connections_percent`: (Opcional) O tamanho máximo do pool de conexão para cada destino em um grupo de destino
- `max_idle_connections_percent`: (Opcional) Controla o quão ativamente o proxy fecha conexões de banco de dados inativas no pool de conexão.
- `session_pinning_filters`: (Opcional) Cada item na lista representa uma classe de operações SQL. Valor permitido é `EXCLUDE_VARIABLE_SETS`.

O argumento `auth` possui os seguintes atributos;
- `iam_auth`: (Opcional) Exigir ou proibir a autenticação. Valores validos `DISABLED` e `REQUIRED`. Valor padrão `DISABLED`.
- `auth_scheme`: (Opcional) O tipo de autenticação que o proxy usa para conexões do proxy ao banco de dados subjacente. Valor padrão `SECRETS`.
- `description`: (Opcional) Uma descrição especificada pelo usuário sobre a autenticação usada por um proxy.

O argumento `secretsmanager` possui os seguintes atributos;
- `recovery_window_in_days`: (Opcional) Especifica o número de dias que o AWS Secrets Manager espera antes de excluir o segredo
- `tags`: (Opcional) Um mapa de chave-valor para tagueamento do recursos
- `version_stages`: (Opcional) Especifica os dados de texto que você deseja criptografar e armazenar nesta versão do segredo.
- `secret_string`: (Opcional) Especifica uma lista de rótulos de teste anexados a esta versão do segredo.

## Variable Outputs
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
| Name | Description |
| ---- | ----------- |
| endpoint | Nome do host para a instância de banco de dados RDS de destino.  |
| port | Porta para a instância de banco de dados RDS de destino ou cluster de banco de dados Aurora. |
| id | Identificador de recursos. |