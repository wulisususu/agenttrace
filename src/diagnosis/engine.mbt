///|
pub(all) struct Evidence {
  id : String
  kind : String
  message : String
  source : String
}

///|
pub(all) struct Diagnosis {
  category : String
  severity : String
  confidence : String
  rule_ids : Array[String]
  evidence : Array[Evidence]
  suggested_checks : Array[String]
}

///|
fn unknown_diagnosis() -> Diagnosis {
  {
    category: "unknown",
    severity: "info",
    confidence: "low",
    rule_ids: [],
    evidence: [],
    suggested_checks: [],
  }
}

///|
fn missing_matcher_occurrences(
  observation : @testlog.TestObservation,
) -> Int {
  let mut occurrences = 0
  for signature in observation.error_signatures {
    if signature.message == "Invalid Chai property: toBeInTheDocument" {
      occurrences = signature.occurrences
    }
  }
  occurrences
}

///|
pub fn diagnose_r001(
  compile_pass : Bool,
  observation : @testlog.TestObservation,
) -> Diagnosis {
  let repeated_matcher = missing_matcher_occurrences(observation)

  if compile_pass &&
    observation.status == "fail" &&
    observation.failed_suites >= 2 &&
    repeated_matcher >= 2 {
    {
      category: "dependency_environment_error",
      severity: "error",
      confidence: "high",
      rule_ids: ["R001"],
      evidence: [
        {
          id: "E-R001-COMPILE-PASS",
          kind: "compile_result",
          message: "Compilation succeeds while tests fail",
          source: "build",
        },
        {
          id: "E-R001-REPEATED-MATCHER",
          kind: "repeated_error_signature",
          message: "Multiple test suites share the same missing matcher error",
          source: "testlog",
        },
      ],
      suggested_checks: [
        "verify installed test dependencies",
        "verify test setup loading",
        "rerun the affected test suite before reverting source changes",
      ],
    }
  } else {
    unknown_diagnosis()
  }
}
