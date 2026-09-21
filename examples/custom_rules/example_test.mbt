///|
test "consumer defines a service-health policy on AgentTrace Core" {
  let evidence : Array[@core.Evidence] = [
    {
      id: "E1",
      kind: "service_started",
      message: "service process started",
      source: "runtime",
    },
    {
      id: "E2",
      kind: "timeout",
      message: "request timed out",
      source: "http",
    },
  ]

  match @custom_rules.diagnose_service(evidence) {
    Some(diagnosis) => {
      assert_eq(diagnosis.category, "service_unavailable")
      assert_eq(diagnosis.rule_ids[0], "SERVICE001")
      assert_eq(diagnosis.evidence.length(), 2)
    }
    None => fail("expected custom consumer rule to match")
  }
}

///|
test "maintenance evidence suppresses the service rule" {
  let evidence : Array[@core.Evidence] = [
    {
      id: "E1",
      kind: "service_started",
      message: "service process started",
      source: "runtime",
    },
    {
      id: "E2",
      kind: "connection_refused",
      message: "connection refused",
      source: "http",
    },
    {
      id: "E3",
      kind: "maintenance_mode",
      message: "planned maintenance",
      source: "control-plane",
    },
  ]

  match @custom_rules.diagnose_service(evidence) {
    Some(_) => fail("maintenance must suppress the outage diagnosis")
    None => ()
  }
}
