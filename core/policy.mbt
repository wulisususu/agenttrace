///|
/// A richer reusable rule built on composable conditions.
///
/// `priority` is only used by `evaluate_highest_priority`. Ordinary
/// `evaluate_policy_rules` preserves caller order so evaluation remains
/// deterministic and transparent.
pub(all) struct PolicyRule {
  id : String
  category : String
  severity : String
  confidence : String
  priority : Int
  condition : Condition
  suggested_checks : Array[String]
}

///|
/// An explainable evaluation for one policy rule. Consumers can inspect why a
/// rule did or did not match without reimplementing condition semantics.
pub(all) struct RuleEvaluation {
  rule_id : String
  priority : Int
  condition : ConditionReport
  diagnosis : Diagnosis?
}

///|
pub fn inspect_policy_rule(
  rule : PolicyRule,
  evidence : Array[Evidence],
) -> RuleEvaluation {
  let condition = inspect_condition(rule.condition, evidence)
  let diagnosis : Diagnosis? = if condition.matched {
    Some({
      category: rule.category,
      severity: rule.severity,
      confidence: rule.confidence,
      rule_ids: [rule.id],
      evidence: condition_evidence(rule.condition, evidence),
      suggested_checks: rule.suggested_checks,
    })
  } else {
    None
  }

  {
    rule_id: rule.id,
    priority: rule.priority,
    condition,
    diagnosis,
  }
}

///|
pub fn evaluate_policy_rule(
  rule : PolicyRule,
  evidence : Array[Evidence],
) -> Diagnosis? {
  inspect_policy_rule(rule, evidence).diagnosis
}

///|
/// Evaluate all matching policy rules in caller-provided order.
pub fn evaluate_policy_rules(
  rules : Array[PolicyRule],
  evidence : Array[Evidence],
) -> Array[Diagnosis] {
  let diagnoses : Array[Diagnosis] = []
  for rule in rules {
    match evaluate_policy_rule(rule, evidence) {
      Some(diagnosis) => diagnoses.push(diagnosis)
      None => ()
    }
  }
  diagnoses
}

///|
/// Inspect every rule, including rules that did not match.
pub fn inspect_policy_rules(
  rules : Array[PolicyRule],
  evidence : Array[Evidence],
) -> Array[RuleEvaluation] {
  let evaluations : Array[RuleEvaluation] = []
  for rule in rules {
    evaluations.push(inspect_policy_rule(rule, evidence))
  }
  evaluations
}

///|
/// Return the diagnosis produced by the matching rule with the highest
/// priority. Ties are stable: the earlier rule wins.
pub fn evaluate_highest_priority(
  rules : Array[PolicyRule],
  evidence : Array[Evidence],
) -> Diagnosis? {
  let mut found = false
  let mut best_priority = 0
  let mut best = unknown_diagnosis()

  for rule in rules {
    match evaluate_policy_rule(rule, evidence) {
      Some(diagnosis) => {
        if !found || rule.priority > best_priority {
          found = true
          best_priority = rule.priority
          best = diagnosis
        }
      }
      None => ()
    }
  }

  if found { Some(best) } else { None }
}
