## 0.4.0

- Include default values in module
- BREAKING CHANGE: `depends_on` can no longer be used to express explicit dependencies between NaC modules. The variable `dependencies` and the output `critical_resources_done` can be used instead, to ensure a certain order of operations.

## 0.3.2

- Add colon to allowed characters of leaf interface selector names
- Add support for `auto_generate_access_leaf_switch_interface_profiles` and `auto_generate_access_spine_switch_interface_profiles` flags

## 0.3.1

- Add module flag to sub-port selectors

## 0.3.0

- Pin module dependencies

## 0.2.0

- Use Terraform 1.3 compatible modules

## 0.1.1

- Update readme and add link to Nexus-as-Code project documentation

## 0.1.0

- Initial release
