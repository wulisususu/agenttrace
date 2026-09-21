///|
/// A non-throwing validation issue for reusable rule definitions.
pub(all) struct ValidationIssue {
  field : String
  message : String
}

///|
fn valid_severity(value : String) -> Bool {
  value == "info" ||
  value == "warning" ||
  value == "error" ||
  value == "blocking"
}

///|
fn valid_confidence(value : String) -> Bool {
  value == "low" || value == "medium" || value == "high"
}

///|
fn validate_kinds(
  field : String,
  kinds : Array[String],
  issues : Array[ValidationIssue],
) -> Unit {
  for kind in kinds {
    if kind == "" {
      issues.push({
        field,
        message: "evidence kind must not be empty",
      })
    }
  }
}

///|
/// Validate a PolicyRule without throwing. Consumers can reject invalid rules
/// at configuration boundaries before evaluation.
pub fn validate_policy_rule(rule : PolicyRule) -> Array[ValidationIssue] {
  let issues : Array[ValidationIssue] = []

  if rule.id == "" {
    issues.push({ field: "id", message: "rule id must not be empty" })
  }
  if rule.category == "" {
    issues.push({
      field: "category",
      message: "diagnosis category must not be empty",
    })
  }
  if !valid_severity(rule.severity) {
    issues.push({
      field: "severity",
      message: "severity must be info, warning, error, or blocking",
    })
  }
  if !valid_confidence(rule.confidence) {
    issues.push({
      field: "confidence",
      message: "confidence must be low, medium, or high",
    })
  }
  if condition_is_empty(rule.condition) {
    issues.push({
      field: "condition",
      message: "condition must contain at least one evidence constraint",
    })
  }

  validate_kinds("condition.all_of", rule.condition.all_of, issues)
  validate_kinds("condition.any_of", rule.condition.any_of, issues)
  validate_kinds("condition.none_of", rule.condition.none_of, issues)

  issues
}

///|
/// Validate a rule set and report duplicate ids in addition to per-rule issues.
pub fn validate_policy_rules(
  rules : Array[PolicyRule],
) -> Array[ValidationIssue] {
  let issues : Array[ValidationIssue] = []

  for rule in rules {
    for issue in validate_policy_rule(rule) {
      issues.push(issue)
    }
  }

  let mut left = 0
  while left < rules.length() {
    let mut right = left + 1
    while right < rules.length() {
      if rules[left].id != "" && rules[left].id == rules[right].id {
        issues.push({
          field: "id",
          message: "duplicate rule id: " + rules[left].id,
        })
      }
      right = right + 1
    }
    left = left + 1
  }

  issues
}
