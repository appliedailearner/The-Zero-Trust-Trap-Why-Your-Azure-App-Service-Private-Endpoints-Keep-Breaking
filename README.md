# The Zero-Trust Trap: Azure App Service Private Endpoints Terraform

This repository contains the officially translated Terraform Infrastructure-as-Code (IaC) templates for the 7 architectural scenarios discussed in the blog post: **"The Zero-Trust Trap: Why Your Azure App Service Private Endpoints Keep Breaking"**.

These templates are designed to help Cloud Architects and DevOps engineers deploy highly secure, zero-trust App Service architectures using standard Microsoft naming conventions and best practices.

## Included Scenarios

Each scenario resides in its own standalone directory. You can navigate to any directory and run `terraform init` followed by `terraform apply` to provision the environment.

1. **[1-baseline-private-webapp](./1-baseline-private-webapp)**
   * **Pattern:** Single Web App with VNet Integration and Private Endpoint. Public internet access is completely disabled.
   * **Use Case:** Internal Admin dashboards, HR tools.

2. **[2-secure-ntier-webapp](./2-secure-ntier-webapp)**
   * **Pattern:** Public-facing Frontend Web App communicating securely over VNet Integration to an isolated Backend Web App via Private Endpoint.
   * **Use Case:** Customer-facing web applications with protected downstream APIs.

3. **[3-webapp-vnet-injection](./3-webapp-vnet-injection)**
   * **Pattern:** A Web App leveraging VNet injection to securely reach an abstract target service (represented as another Web App) via a Private Endpoint.
   * **Use Case:** Securing outbound calls to Redis, Key Vault, or Partner APIs.

4. **[4-appgw-waf-pattern](./4-appgw-waf-pattern)**
   * **Pattern:** Application Gateway v2 (WAF_v2) deployed into a VNet, terminating TLS and forwarding traffic securely to an isolated Web App via its Private IP.
   * **Use Case:** High-security internet ingress facing strict OWASP compliance rules.

5. **[5-egress-sql-over-pe](./5-egress-sql-over-pe)**
   * **Pattern:** App Service leveraging VNet Integration to access a highly secured Azure SQL Database with public network access strictly disabled, using System-Assigned Managed Identity.
   * **Use Case:** Patient Healthcare Information (PHI) or Banking Ledgers.

6. **[6-gold-standard-apim-waf](./6-gold-standard-apim-waf)**
   * **Pattern:** The ultimate enterprise perimeter: Application Gateway WAF -> API Management (Internal VNet Mode) -> Web App with Private Endpoint.
   * **Use Case:** The definitive enterprise standard for multi-layered API protection.

7. **[bonus-functionapp-storage-pe](./bonus-functionapp-storage-pe)**
   * **Pattern:** A Serverless Linux Function App (Elastic Premium) locked down locally, routing all storage dependencies (Blob/File/Queue/Table) through Storage Private Endpoints.
   * **Use Case:** Secure background processing and data crunching.

## Prerequisites

* Terraform `>= 1.5.0`
* Azure CLI (`az login`) with owner/contributor permissions to a test subscription.
* The `hashicorp/azurerm` provider version `~> 3.116`.

## Usage

```bash
cd <scenario-folder>
terraform init
terraform plan -out tfplan
terraform apply tfplan
```

All templates default to the `southeastasia` region. You can override this using a `terraform.tfvars` file or by passing `-var="location=eastus"` at runtime.
