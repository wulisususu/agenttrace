///|
/// Minimal example showing that AgentTrace Core can be consumed without the
/// AgentTrace CLI, Git collector, test-log parser, or web report.
pub fn diagnose_service(
  evidence : Array[@core.Evidence],
) -> @core.Diagnosis? {
  let rule : @core.Rule = {
    id: "SERVICE001",
    category: "service_unavailable",
    severity: "error",
    confidence: "high",
    required_evidence_kinds: ["timeout", "retry_exhausted"],
    suggested_checks: [
      "verify upstream service availability",
      "check retry and timeout configuration",
    ],
  }
  @core.evaluate_rule(rule, evidence)
}
