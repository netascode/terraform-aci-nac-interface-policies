locals {
  user_defaults   = { "defaults" : try(var.model.defaults, {}) }
  defaults        = lookup(yamldecode(data.utils_yaml_merge.defaults.output), "defaults")
  modules         = try(var.model.modules, {})
  apic            = try(var.model.apic, {})
  access_policies = try(local.apic.access_policies, {})
  node_policies   = try(local.apic.node_policies, {})
  node            = [for node in try(local.apic.interface_policies.nodes, []) : node if node.id == var.node_id][0]
  node_id         = local.node.id
  node_name       = try([for node in local.node_policies.nodes : node.name if node.id == local.node_id][0], "")
  node_role       = try([for node in local.node_policies.nodes : node.role if node.id == local.node_id][0], "")

  fex_interface_selectors = flatten([
    for fex in try(local.node.fexes, []) : [
      for interface in try(fex.interfaces, []) : {
        name              = replace(format("%s:%s", try(interface.module, local.defaults.apic.access_policies.fex_interface_profiles.selectors.port_blocks.from_module), interface.port), "/^(?P<mod>.+):(?P<port>.+)$/", replace(replace(try(local.access_policies.fex_interface_selector_name, local.defaults.apic.access_policies.fex_interface_selector_name), "\\g<mod>", "$mod"), "\\g<port>", "$port"))
        profile_name      = replace("${local.node_id}:${local.node_name}:${fex.id}", "/^(?P<id>.+):(?P<name>.+):(?P<fex>.+)$/", replace(replace(replace(try(local.access_policies.fex_profile_name, local.defaults.apic.access_policies.fex_profile_name), "\\g<id>", "$id"), "\\g<name>", "$name"), "\\g<fex>", "$fex"))
        policy_group      = try("${interface.policy_group}${local.defaults.apic.access_policies.leaf_interface_policy_groups.name_suffix}", "")
        policy_group_type = try([for pg in local.access_policies.leaf_interface_policy_groups : pg.type if pg.name == interface.policy_group][0], "access")
        port_blocks = [{
          description = try(interface.description, "")
          name        = format("%s-%s", try(interface.module, local.defaults.apic.access_policies.fex_interface_profiles.selectors.port_blocks.from_module), interface.port)
          from_module = try(interface.module, local.defaults.apic.access_policies.fex_interface_profiles.selectors.port_blocks.from_module)
          from_port   = interface.port
          to_module   = try(interface.module, local.defaults.apic.access_policies.fex_interface_profiles.selectors.port_blocks.from_module)
          to_port     = interface.port
        }]
      }
    ] if(try(local.apic.auto_generate_switch_pod_profiles, local.defaults.apic.auto_generate_switch_pod_profiles) || try(local.apic.auto_generate_access_leaf_switch_interface_profiles, local.defaults.apic.auto_generate_access_leaf_switch_interface_profiles))
  ])

  sub_interface_selectors = flatten([
    for interface in try(local.node.interfaces, []) : [
      for sub in try(interface.sub_ports, []) : {
        name                  = replace(format("%s:%s:%s", try(interface.module, local.defaults.apic.access_policies.leaf_interface_profiles.selectors.port_blocks.from_module), interface.port, sub.port), "/^(?P<mod>.+):(?P<port>.+):(?P<sport>.+)$/", replace(replace(replace(try(local.access_policies.leaf_interface_selector_sub_port_name, local.defaults.apic.access_policies.leaf_interface_selector_sub_port_name), "\\g<mod>", "$mod"), "\\g<port>", "$port"), "\\g<sport>", "$sport"))
        interface_profile     = replace("${local.node_id}:${local.node_name}", "/^(?P<id>.+):(?P<name>.+)$/", replace(replace(try(local.access_policies.leaf_interface_profile_name, local.defaults.apic.access_policies.leaf_interface_profile_name), "\\g<id>", "$id"), "\\g<name>", "$name"))
        fex_id                = try(sub.fex_id, 0)
        fex_interface_profile = try(replace("${local.node_id}:${local.node_name}:${sub.fex_id}", "/^(?P<id>.+):(?P<name>.+):(?P<fex>.+)$/", replace(replace(replace(try(local.access_policies.fex_profile_name, local.defaults.apic.access_policies.fex_profile_name), "\\g<id>", "$id"), "\\g<name>", "$name"), "\\g<fex>", "$fex")), "")
        policy_group          = try("${sub.policy_group}${local.defaults.apic.access_policies.leaf_interface_policy_groups.name_suffix}", "")
        policy_group_type     = try([for pg in local.access_policies.leaf_interface_policy_groups : pg.type if pg.name == sub.policy_group][0], "access")
        sub_port_blocks = [{
          description   = try(sub.description, "")
          name          = format("%s-%s-%s", try(interface.module, local.defaults.apic.access_policies.leaf_interface_profiles.selectors.port_blocks.from_module), interface.port, sub.port)
          from_module   = try(interface.module, local.defaults.apic.access_policies.leaf_interface_profiles.selectors.port_blocks.from_module)
          from_port     = interface.port
          to_module     = try(interface.module, local.defaults.apic.access_policies.leaf_interface_profiles.selectors.port_blocks.from_module)
          to_port       = interface.port
          from_sub_port = sub.port
          to_sub_port   = sub.port
        }]
      }
    ] if(try(local.apic.auto_generate_switch_pod_profiles, local.defaults.apic.auto_generate_switch_pod_profiles) || try(local.apic.auto_generate_access_leaf_switch_interface_profiles, local.defaults.apic.auto_generate_access_leaf_switch_interface_profiles))
  ])
}

module "defaults" {
  source  = "netascode/nac-defaults/null"
  version = "0.1.0"
}

data "utils_yaml_merge" "defaults" {
  input = [yamlencode(module.defaults.defaults), yamlencode(local.user_defaults)]
}

resource "null_resource" "dependencies" {
  triggers = {
    dependencies = join(",", var.dependencies)
  }
}

module "aci_access_fex_interface_profile_auto" {
  source  = "netascode/access-fex-interface-profile/aci"
  version = "0.1.0"

  for_each = { for fex in try(local.node.fexes, []) : fex.id => fex if(try(local.apic.auto_generate_switch_pod_profiles, local.defaults.apic.auto_generate_switch_pod_profiles) || try(local.apic.auto_generate_access_leaf_switch_interface_profiles, local.defaults.apic.auto_generate_access_leaf_switch_interface_profiles)) && local.node_role == "leaf" && try(local.modules.aci_access_fex_interface_profile, true) }
  name     = replace("${local.node_id}:${local.node_name}:${each.value.id}", "/^(?P<id>.+):(?P<name>.+):(?P<fex>.+)$/", replace(replace(replace(try(local.access_policies.fex_profile_name, local.defaults.apic.access_policies.fex_profile_name), "\\g<id>", "$id"), "\\g<name>", "$name"), "\\g<fex>", "$fex"))

  depends_on = [
    null_resource.dependencies,
  ]
}

module "aci_access_leaf_interface_selector_auto" {
  source  = "netascode/access-leaf-interface-selector/aci"
  version = "0.2.1"

  for_each              = { for int in try(local.node.interfaces, []) : int.port => int if(try(local.apic.auto_generate_switch_pod_profiles, local.defaults.apic.auto_generate_switch_pod_profiles) || try(local.apic.auto_generate_access_leaf_switch_interface_profiles, local.defaults.apic.auto_generate_access_leaf_switch_interface_profiles)) && local.node_role == "leaf" && try(local.modules.aci_access_leaf_interface_selector, true) }
  name                  = replace(format("%s:%s", try(each.value.module, local.defaults.apic.access_policies.leaf_interface_profiles.selectors.port_blocks.from_module), each.value.port), "/^(?P<mod>.+):(?P<port>.+)$/", replace(replace(try(local.access_policies.leaf_interface_selector_name, local.defaults.apic.access_policies.leaf_interface_selector_name), "\\g<mod>", "$mod"), "\\g<port>", "$port"))
  interface_profile     = replace("${local.node_id}:${local.node_name}", "/^(?P<id>.+):(?P<name>.+)$/", replace(replace(try(local.access_policies.leaf_interface_profile_name, local.defaults.apic.access_policies.leaf_interface_profile_name), "\\g<id>", "$id"), "\\g<name>", "$name"))
  fex_id                = try(each.value.fex_id, 0)
  fex_interface_profile = try(replace("${local.node_id}:${local.node_name}:${each.value.fex_id}", "/^(?P<id>.+):(?P<name>.+):(?P<fex>.+)$/", replace(replace(replace(try(local.access_policies.fex_profile_name, local.defaults.apic.access_policies.fex_profile_name), "\\g<id>", "$id"), "\\g<name>", "$name"), "\\g<fex>", "$fex")), "")
  policy_group          = try("${each.value.policy_group}${local.defaults.apic.access_policies.leaf_interface_policy_groups.name_suffix}", "")
  policy_group_type     = try([for pg in local.access_policies.leaf_interface_policy_groups : pg.type if pg.name == each.value.policy_group][0], "access")
  port_blocks = [{
    description = try(each.value.description, "")
    name        = format("%s-%s", try(each.value.module, local.defaults.apic.access_policies.leaf_interface_profiles.selectors.port_blocks.from_module), each.value.port)
    from_module = try(each.value.module, local.defaults.apic.access_policies.leaf_interface_profiles.selectors.port_blocks.from_module)
    from_port   = each.value.port
    to_module   = try(each.value.module, local.defaults.apic.access_policies.leaf_interface_profiles.selectors.port_blocks.from_module)
    to_port     = each.value.port
  }]

  depends_on = [
    null_resource.dependencies,
  ]
}

module "aci_access_leaf_interface_selector_sub_auto" {
  source  = "netascode/access-leaf-interface-selector/aci"
  version = "0.2.1"

  for_each              = { for selector in local.sub_interface_selectors : selector.name => selector if local.node_role == "leaf" && try(local.modules.aci_access_leaf_interface_selector, true) }
  name                  = each.value.name
  interface_profile     = each.value.interface_profile
  fex_id                = each.value.fex_id
  fex_interface_profile = each.value.fex_interface_profile
  policy_group          = each.value.policy_group
  policy_group_type     = each.value.policy_group_type
  sub_port_blocks       = each.value.sub_port_blocks

  depends_on = [
    null_resource.dependencies,
  ]
}

module "aci_access_fex_interface_selector_auto" {
  source  = "netascode/access-fex-interface-selector/aci"
  version = "0.2.0"

  for_each          = { for selector in local.fex_interface_selectors : selector.name => selector if local.node_role == "leaf" && try(local.modules.aci_access_fex_interface_selector, true) }
  name              = each.value.name
  interface_profile = each.value.profile_name
  policy_group      = each.value.policy_group
  policy_group_type = each.value.policy_group_type
  port_blocks       = each.value.port_blocks

  depends_on = [
    null_resource.dependencies,
    module.aci_access_fex_interface_profile_auto,
  ]
}

module "aci_access_spine_interface_selector_auto" {
  source  = "netascode/access-spine-interface-selector/aci"
  version = "0.2.0"

  for_each          = { for int in try(local.node.interfaces, []) : int.port => int if(try(local.apic.auto_generate_switch_pod_profiles, local.defaults.apic.auto_generate_switch_pod_profiles) || try(local.apic.auto_generate_access_spine_switch_interface_profiles, local.defaults.apic.auto_generate_access_spine_switch_interface_profiles)) && local.node_role == "spine" && try(local.modules.aci_access_spine_interface_selector, true) }
  name              = replace(format("%s:%s", try(each.value.module, local.defaults.apic.access_policies.spine_interface_profiles.selectors.port_blocks.from_module), each.value.port), "/^(?P<mod>.+):(?P<port>.+)$/", replace(replace(try(local.access_policies.spine_interface_selector_name, local.defaults.apic.access_policies.spine_interface_selector_name), "\\g<mod>", "$mod"), "\\g<port>", "$port"))
  interface_profile = replace("${local.node_id}:${local.node_name}", "/^(?P<id>.+):(?P<name>.+)$/", replace(replace(try(local.access_policies.spine_interface_profile_name, local.defaults.apic.access_policies.spine_interface_profile_name), "\\g<id>", "$id"), "\\g<name>", "$name"))
  policy_group      = try("${each.value.policy_group}${local.defaults.apic.access_policies.spine_interface_policy_groups.name_suffix}", "")
  port_blocks = [{
    name        = format("%s-%s", try(each.value.module, local.defaults.apic.access_policies.spine_interface_profiles.selectors.port_blocks.from_module), each.value.port)
    description = try(each.value.description, "")
    from_module = try(each.value.module, local.defaults.apic.access_policies.spine_interface_profiles.selectors.port_blocks.from_module)
    from_port   = each.value.port
    to_module   = try(each.value.module, local.defaults.apic.access_policies.spine_interface_profiles.selectors.port_blocks.from_module)
    to_port     = each.value.port
  }]

  depends_on = [
    null_resource.dependencies,
  ]
}

resource "null_resource" "critical_resources_done" {
  triggers = {
  }
}
