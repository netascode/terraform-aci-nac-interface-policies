<!-- BEGIN_TF_DOCS -->
[![Tests](https://github.com/netascode/terraform-aci-nac-interface-policies/actions/workflows/test.yml/badge.svg)](https://github.com/netascode/terraform-aci-nac-interface-policies/actions/workflows/test.yml)

# Terraform ACI Interface Policies Module

A Terraform module to configure ACI Interface Policies.

This module is part of the Cisco [*Nexus as Code*](https://cisco.com/go/nexusascode) project. Its goal is to allow users to instantiate network fabrics in minutes using an easy to use, opinionated data model. It takes away the complexity of having to deal with references, dependencies or loops. By completely separating data (defining variables) from logic (infrastructure declaration), it allows the user to focus on describing the intended configuration while using a set of maintained and tested Terraform Modules without the need to understand the low-level ACI object model. More information can be found here: https://cisco.com/go/nexusascode.

A comprehensive example using this module is available here: https://github.com/netascode/nac-aci-comprehensive-example

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aci"></a> [aci](#requirement\_aci) | >= 2.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_model"></a> [model](#input\_model) | Model data. | `any` | n/a | yes |
| <a name="input_node_id"></a> [node\_id](#input\_node\_id) | Node ID. | `number` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->