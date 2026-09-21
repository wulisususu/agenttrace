///|
/// Diagnose a service using only AgentTrace Core's public API.
pub fn diagnose_service(
  evidence : Array[@core.Evidence],
) -> @core.Diagnosis? {
  let rule : @core.PolicyRule = {
    id: "SERVICE001",
    category: "service_unavailable",
    severity: "error",
    confidence: "high",
    priority: 100,
    condition: {
      all_of: ["service_started"],
      any_of: ["timeout", "connection_refused"],
      none_of: ["maintenance_mode"],
    },
    suggested_checks: [
      "verify upstream service availability",
      "check retry and timeout configuration",
    ],
  }
  @core.evaluate_policy_rule(rule, evidence)
}
