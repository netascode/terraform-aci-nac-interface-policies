locals {
  defaults        = lookup(var.model, "defaults", {})
  modules         = lookup(var.model, "modules", {})
  apic            = lookup(var.model, "apic", {})
  access_policies = lookup(local.apic, "access_policies", {})
  node_policies   = lookup(local.apic, "node_policies", {})
  node            = [for node in lookup(lookup(local.apic, "interface_policies", {}), "nodes", []) : node if node.id == var.node_id][0]
  node_id         = local.node.id
  node_name       = [for node in lookup(local.node_policies, "nodes", []) : lookup(node, "name", "") if node.id == local.node_id][0]
  node_role       = [for node in lookup(local.node_policies, "nodes", []) : lookup(node, "role", "") if node.id == local.node_id][0]

  fex_interface_selectors = flatten([
    for fex in lookup(local.node, "fexes", []) : [
      for interface in lookup(fex, "interfaces", []) : {
        name              = replace(format("%s:%s", lookup(interface, "module", local.defaults.apic.access_policies.fex_interface_profiles.selectors.port_blocks.from_module), interface.port), "/^(?P<mod>.+):(?P<port>.+)$/", replace(replace(lookup(local.access_policies, "fex_interface_selector_name", local.defaults.apic.access_policies.fex_interface_selector_name), "\\g<mod>", "$mod"), "\\g<port>", "$port"))
        profile_name      = replace("${local.node_id}:${local.node_name}:${fex.id}", "/^(?P<id>.+):(?P<name>.+):(?P<fex>.+)$/", replace(replace(replace(lookup(local.access_policies, "fex_profile_name", local.defaults.apic.access_policies.fex_profile_name), "\\g<id>", "$id"), "\\g<name>", "$name"), "\\g<fex>", "$fex"))
        policy_group      = lookup(interface, "policy_group", null) != null ? "${interface.policy_group}${local.defaults.apic.access_policies.leaf_interface_policy_groups.name_suffix}" : ""
        policy_group_type = lookup(interface, "policy_group", null) != null ? [for pg in lookup(local.access_policies, "leaf_interface_policy_groups", []) : pg.type if pg.name == interface.policy_group][0] : "access"
        port_blocks = [{
          description = lookup(interface, "description", "")
          name        = format("%s-%s", lookup(interface, "module", local.defaults.apic.access_policies.fex_interface_profiles.selectors.port_blocks.from_module), interface.port)
          from_module = lookup(interface, "module", local.defaults.apic.access_policies.fex_interface_profiles.selectors.port_blocks.from_module)
          from_port   = interface.port
          to_module   = lookup(interface, "module", local.defaults.apic.access_policies.fex_interface_profiles.selectors.port_blocks.from_module)
          to_port     = interface.port
        }]
      }
    ] if lookup(local.apic, "auto_generate_switch_pod_profiles", local.defaults.apic.auto_generate_switch_pod_profiles)
  ])

  sub_interface_selectors = flatten([
    for interface in lookup(local.node, "interfaces", []) : [
      for sub in lookup(interface, "sub_ports", []) : {
        name                  = replace(format("%s:%s:%s", lookup(interface, "module", local.defaults.apic.access_policies.leaf_interface_profiles.selectors.port_blocks.from_module), interface.port, sub.port), "/^(?P<mod>.+):(?P<port>.+):(?P<sport>.+)$/", replace(replace(replace(lookup(local.access_policies, "leaf_interface_selector_sub_port_name", local.defaults.apic.access_policies.leaf_interface_selector_sub_port_name), "\\g<mod>", "$mod"), "\\g<port>", "$port"), "\\g<sport>", "$sport"))
        interface_profile     = replace("${local.node_id}:${local.node_name}", "/^(?P<id>.+):(?P<name>.+)$/", replace(replace(lookup(local.access_policies, "leaf_interface_profile_name", local.defaults.apic.access_policies.leaf_interface_profile_name), "\\g<id>", "$id"), "\\g<name>", "$name"))
        fex_id                = lookup(sub, "fex_id", 0)
        fex_interface_profile = lookup(sub, "fex_id", 0) != 0 ? replace("${local.node_id}:${local.node_name}:${lookup(sub, "fex_id", null)}", "/^(?P<id>.+):(?P<name>.+):(?P<fex>.+)$/", replace(replace(replace(lookup(local.access_policies, "fex_profile_name", local.defaults.apic.access_policies.fex_profile_name), "\\g<id>", "$id"), "\\g<name>", "$name"), "\\g<fex>", "$fex")) : ""
        policy_group          = lookup(sub, "policy_group", null) != null ? "${sub.policy_group}${local.defaults.apic.access_policies.leaf_interface_policy_groups.name_suffix}" : ""
        policy_group_type     = lookup(sub, "policy_group", null) != null ? [for pg in lookup(local.access_policies, "leaf_interface_policy_groups", []) : pg.type if pg.name == sub.policy_group][0] : "access"
        sub_port_blocks = [{
          description   = lookup(sub, "description", "")
          name          = format("%s-%s-%s", lookup(interface, "module", local.defaults.apic.access_policies.leaf_interface_profiles.selectors.port_blocks.from_module), interface.port, sub.port)
          from_module   = lookup(interface, "module", local.defaults.apic.access_policies.leaf_interface_profiles.selectors.port_blocks.from_module)
          from_port     = interface.port
          to_module     = lookup(interface, "module", local.defaults.apic.access_policies.leaf_interface_profiles.selectors.port_blocks.from_module)
          to_port       = interface.port
          from_sub_port = sub.port
          to_sub_port   = sub.port
        }]
      }
    ] if lookup(local.apic, "auto_generate_switch_pod_profiles", local.defaults.apic.auto_generate_switch_pod_profiles)
  ])
}

module "aci_access_fex_interface_profile_auto" {
  source  = "netascode/access-fex-interface-profile/aci"
  version = "0.1.0"

  for_each = { for fex in lookup(local.node, "fexes", {}) : fex.id => fex if lookup(local.apic, "auto_generate_switch_pod_profiles", local.defaults.apic.auto_generate_switch_pod_profiles) && local.node_role == "leaf" && lookup(local.modules, "aci_access_fex_interface_profile", true) }
  name     = replace("${local.node_id}:${local.node_name}:${each.value.id}", "/^(?P<id>.+):(?P<name>.+):(?P<fex>.+)$/", replace(replace(replace(lookup(local.access_policies, "fex_profile_name", local.defaults.apic.access_policies.fex_profile_name), "\\g<id>", "$id"), "\\g<name>", "$name"), "\\g<fex>", "$fex"))
}

module "aci_access_leaf_interface_selector_auto" {
  source  = "netascode/access-leaf-interface-selector/aci"
  version = "0.2.0"

  for_each              = { for int in local.node.interfaces : int.port => int if lookup(local.apic, "auto_generate_switch_pod_profiles", local.defaults.apic.auto_generate_switch_pod_profiles) && local.node_role == "leaf" && lookup(local.modules, "aci_access_leaf_interface_selector", true) }
  name                  = replace(format("%s:%s", lookup(each.value, "module", local.defaults.apic.access_policies.leaf_interface_profiles.selectors.port_blocks.from_module), each.value.port), "/^(?P<mod>.+):(?P<port>.+)$/", replace(replace(lookup(local.access_policies, "leaf_interface_selector_name", local.defaults.apic.access_policies.leaf_interface_selector_name), "\\g<mod>", "$mod"), "\\g<port>", "$port"))
  interface_profile     = replace("${local.node_id}:${local.node_name}", "/^(?P<id>.+):(?P<name>.+)$/", replace(replace(lookup(local.access_policies, "leaf_interface_profile_name", local.defaults.apic.access_policies.leaf_interface_profile_name), "\\g<id>", "$id"), "\\g<name>", "$name"))
  fex_id                = lookup(each.value, "fex_id", 0)
  fex_interface_profile = lookup(each.value, "fex_id", 0) != 0 ? replace("${local.node_id}:${local.node_name}:${lookup(each.value, "fex_id", null)}", "/^(?P<id>.+):(?P<name>.+):(?P<fex>.+)$/", replace(replace(replace(lookup(local.access_policies, "fex_profile_name", local.defaults.apic.access_policies.fex_profile_name), "\\g<id>", "$id"), "\\g<name>", "$name"), "\\g<fex>", "$fex")) : ""
  policy_group          = lookup(each.value, "policy_group", null) != null ? "${each.value.policy_group}${local.defaults.apic.access_policies.leaf_interface_policy_groups.name_suffix}" : ""
  policy_group_type     = lookup(each.value, "policy_group", null) != null ? [for pg in lookup(local.access_policies, "leaf_interface_policy_groups", []) : pg.type if pg.name == each.value.policy_group][0] : "access"
  port_blocks = [{
    description = lookup(each.value, "description", "")
    name        = format("%s-%s", lookup(each.value, "module", local.defaults.apic.access_policies.leaf_interface_profiles.selectors.port_blocks.from_module), each.value.port)
    from_module = lookup(each.value, "module", local.defaults.apic.access_policies.leaf_interface_profiles.selectors.port_blocks.from_module)
    from_port   = each.value.port
    to_module   = lookup(each.value, "module", local.defaults.apic.access_policies.leaf_interface_profiles.selectors.port_blocks.from_module)
    to_port     = each.value.port
  }]
}

module "aci_access_leaf_interface_selector_sub_auto" {
  source  = "netascode/access-leaf-interface-selector/aci"
  version = "0.2.0"

  for_each              = { for selector in local.sub_interface_selectors : selector.name => selector if local.node_role == "leaf" && lookup(local.modules, "aci_access_leaf_interface_selector", true) }
  name                  = each.value.name
  interface_profile     = each.value.interface_profile
  fex_id                = each.value.fex_id
  fex_interface_profile = each.value.fex_interface_profile
  policy_group          = each.value.policy_group
  policy_group_type     = each.value.policy_group_type
  sub_port_blocks       = each.value.sub_port_blocks
}

module "aci_access_fex_interface_selector_auto" {
  source  = "netascode/access-fex-interface-selector/aci"
  version = "0.2.0"

  for_each          = { for selector in local.fex_interface_selectors : selector.name => selector if local.node_role == "leaf" && lookup(local.modules, "aci_access_fex_interface_selector", true) }
  name              = each.value.name
  interface_profile = each.value.profile_name
  policy_group      = each.value.policy_group
  policy_group_type = each.value.policy_group_type
  port_blocks       = each.value.port_blocks

  depends_on = [
    module.aci_access_fex_interface_profile_auto,
  ]
}

module "aci_access_spine_interface_selector_auto" {
  source  = "netascode/access-spine-interface-selector/aci"
  version = "0.2.0"

  for_each          = { for int in local.node.interfaces : int.port => int if lookup(local.apic, "auto_generate_switch_pod_profiles", local.defaults.apic.auto_generate_switch_pod_profiles) && local.node_role == "spine" && lookup(local.modules, "aci_access_spine_interface_selector", true) }
  name              = replace(format("%s:%s", lookup(each.value, "module", local.defaults.apic.access_policies.spine_interface_profiles.selectors.port_blocks.from_module), each.value.port), "/^(?P<mod>.+):(?P<port>.+)$/", replace(replace(lookup(local.access_policies, "spine_interface_selector_name", local.defaults.apic.access_policies.spine_interface_selector_name), "\\g<mod>", "$mod"), "\\g<port>", "$port"))
  interface_profile = replace("${local.node_id}:${local.node_name}", "/^(?P<id>.+):(?P<name>.+)$/", replace(replace(lookup(local.access_policies, "spine_interface_profile_name", local.defaults.apic.access_policies.spine_interface_profile_name), "\\g<id>", "$id"), "\\g<name>", "$name"))
  policy_group      = lookup(each.value, "policy_group", null) != null ? "${each.value.policy_group}${local.defaults.apic.access_policies.spine_interface_policy_groups.name_suffix}" : ""
  port_blocks = [{
    name        = format("%s-%s", lookup(each.value, "module", local.defaults.apic.access_policies.spine_interface_profiles.selectors.port_blocks.from_module), each.value.port)
    description = lookup(each.value, "description", "")
    from_module = lookup(each.value, "module", local.defaults.apic.access_policies.spine_interface_profiles.selectors.port_blocks.from_module)
    from_port   = each.value.port
    to_module   = lookup(each.value, "module", local.defaults.apic.access_policies.spine_interface_profiles.selectors.port_blocks.from_module)
    to_port     = each.value.port
  }]
}
