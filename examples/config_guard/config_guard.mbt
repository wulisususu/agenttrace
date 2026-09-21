///|
/// A small configuration-policy example built only on AgentTrace Core.
pub fn diagnose_configuration(
  evidence : Array[@core.Evidence],
) -> Array[@core.Diagnosis] {
  let rules : Array[@core.PolicyRule] = [
    {
      id: "CFG001",
      category: "missing_required_configuration",
      severity: "error",
      confidence: "high",
      priority: 100,
      condition: {
        all_of: ["required_config_missing"],
        any_of: [],
        none_of: [],
      },
      suggested_checks: ["restore the required configuration file"],
    },
    {
      id: "CFG002",
      category: "deprecated_configuration",
      severity: "warning",
      confidence: "medium",
      priority: 10,
      condition: {
        all_of: ["deprecated_config_present"],
        any_of: [],
        none_of: ["migration_complete"],
      },
      suggested_checks: ["migrate to the current configuration format"],
    },
  ]

  @core.evaluate_policy_rules(rules, evidence)
}
