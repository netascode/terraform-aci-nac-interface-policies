terraform {
  required_version = ">= 1.3.0"

  required_providers {
    test = {
      source = "terraform.io/builtin/test"
    }

    aci = {
      source  = "CiscoDevNet/aci"
      version = ">=2.0.0"
    }
  }
}

module "main" {
  source = "../.."

  model = {
    apic = {
      auto_generate_switch_pod_profiles = true
      node_policies = {
        nodes = [{
          id   = 101
          name = "LEAF101"
          role = "leaf"
        }]
      }
      interface_policies = {
        nodes = [{
          id = 101
          fexes = [{
            id = 101
          }]
        }]
      }
    }
  }
  node_id = 101
}

data "aci_rest_managed" "infraFexP" {
  dn = "uni/infra/fexprof-LEAF101-FEX101"

  depends_on = [module.main]
}

resource "test_assertions" "infraFexP" {
  component = "infraFexP"

  equal "name" {
    description = "name"
    got         = data.aci_rest_managed.infraFexP.content.name
    want        = "LEAF101-FEX101"
  }
}
