///|
/// A structured fact that can be consumed by reusable diagnostic rules.
pub(all) struct Evidence {
  id : String
  kind : String
  message : String
  source : String
}

///|
/// A deterministic diagnostic result produced from structured evidence.
pub(all) struct Diagnosis {
  category : String
  severity : String
  confidence : String
  rule_ids : Array[String]
  evidence : Array[Evidence]
  suggested_checks : Array[String]
}

///|
/// A generic all-of rule. Domain-specific packages can define their own rules
/// without depending on AgentTrace CLI, Git collectors, or test-log parsers.
pub(all) struct Rule {
  id : String
  category : String
  severity : String
  confidence : String
  required_evidence_kinds : Array[String]
  suggested_checks : Array[String]
}

///|
pub fn unknown_diagnosis() -> Diagnosis {
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
fn has_kind(evidence : Array[Evidence], kind : String) -> Bool {
  for item in evidence {
    if item.kind == kind {
      return true
    }
  }
  false
}

///|
fn kind_required(kinds : Array[String], kind : String) -> Bool {
  for required in kinds {
    if required == kind {
      return true
    }
  }
  false
}

///|
/// Evaluate one generic rule. A rule matches only when every required evidence
/// kind is present. The returned diagnosis contains only evidence relevant to
/// the rule.
pub fn evaluate_rule(
  rule : Rule,
  evidence : Array[Evidence],
) -> Diagnosis? {
  if rule.required_evidence_kinds.length() == 0 {
    return None
  }

  for kind in rule.required_evidence_kinds {
    if !has_kind(evidence, kind) {
      return None
    }
  }

  let matched : Array[Evidence] = []
  for item in evidence {
    if kind_required(rule.required_evidence_kinds, item.kind) {
      matched.push(item)
    }
  }

  Some({
    category: rule.category,
    severity: rule.severity,
    confidence: rule.confidence,
    rule_ids: [rule.id],
    evidence: matched,
    suggested_checks: rule.suggested_checks,
  })
}

///|
/// Evaluate a list of independent rules against the same evidence set.
pub fn evaluate_rules(
  rules : Array[Rule],
  evidence : Array[Evidence],
) -> Array[Diagnosis] {
  let diagnoses : Array[Diagnosis] = []
  for rule in rules {
    match evaluate_rule(rule, evidence) {
      Some(diagnosis) => diagnoses.push(diagnosis)
      None => ()
    }
  }
  diagnoses
}
