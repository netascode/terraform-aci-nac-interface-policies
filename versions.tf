terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aci = {
      source  = "CiscoDevNet/aci"
      version = ">= 2.0.0"
    }
    utils = {
      source  = "netascode/utils"
      version = ">= 0.2.4"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.1"
    }
  }
}
