///|
/// A reusable condition over evidence kinds.
///
/// Semantics:
/// - every `all_of` kind must be present;
/// - when `any_of` is non-empty, at least one kind must be present;
/// - every `none_of` kind must be absent;
/// - an entirely empty condition never matches.
pub(all) struct Condition {
  all_of : Array[String]
  any_of : Array[String]
  none_of : Array[String]
}

///|
/// Explain how a condition evaluated, including missing mandatory evidence,
/// the `any_of` alternatives that matched, and forbidden evidence that
/// blocked the condition.
pub(all) struct ConditionReport {
  matched : Bool
  empty_condition : Bool
  missing_all : Array[String]
  matched_any : Array[String]
  blocked_by : Array[String]
}

///|
pub fn condition_is_empty(condition : Condition) -> Bool {
  condition.all_of.length() == 0 &&
  condition.any_of.length() == 0 &&
  condition.none_of.length() == 0
}

///|
fn kind_in(kinds : Array[String], kind : String) -> Bool {
  for item in kinds {
    if item == kind {
      return true
    }
  }
  false
}

///|
pub fn evidence_has_kind(evidence : Array[Evidence], kind : String) -> Bool {
  for item in evidence {
    if item.kind == kind {
      return true
    }
  }
  false
}

///|
pub fn evidence_count_kind(evidence : Array[Evidence], kind : String) -> Int {
  let mut count = 0
  for item in evidence {
    if item.kind == kind {
      count = count + 1
    }
  }
  count
}

///|
pub fn evidence_by_kind(
  evidence : Array[Evidence],
  kind : String,
) -> Array[Evidence] {
  let matched : Array[Evidence] = []
  for item in evidence {
    if item.kind == kind {
      matched.push(item)
    }
  }
  matched
}

///|
/// Return an explanation of a composable condition evaluation.
pub fn inspect_condition(
  condition : Condition,
  evidence : Array[Evidence],
) -> ConditionReport {
  let empty = condition_is_empty(condition)
  let missing_all : Array[String] = []
  let matched_any : Array[String] = []
  let blocked_by : Array[String] = []

  for kind in condition.all_of {
    if !evidence_has_kind(evidence, kind) {
      missing_all.push(kind)
    }
  }

  for kind in condition.any_of {
    if evidence_has_kind(evidence, kind) {
      matched_any.push(kind)
    }
  }

  for kind in condition.none_of {
    if evidence_has_kind(evidence, kind) {
      blocked_by.push(kind)
    }
  }

  let any_ok =
    condition.any_of.length() == 0 || matched_any.length() > 0

  {
    matched: !empty &&
      missing_all.length() == 0 &&
      any_ok &&
      blocked_by.length() == 0,
    empty_condition: empty,
    missing_all,
    matched_any,
    blocked_by,
  }
}

///|
/// Evaluate a composable condition against a set of structured evidence.
pub fn condition_matches(
  condition : Condition,
  evidence : Array[Evidence],
) -> Bool {
  inspect_condition(condition, evidence).matched
}

///|
/// Return only the positive evidence that participated in a matched condition.
/// `none_of` evidence is absent by definition and therefore cannot be
/// included in the returned array.
pub fn condition_evidence(
  condition : Condition,
  evidence : Array[Evidence],
) -> Array[Evidence] {
  let matched : Array[Evidence] = []
  for item in evidence {
    if kind_in(condition.all_of, item.kind) ||
      kind_in(condition.any_of, item.kind) {
      matched.push(item)
    }
  }
  matched
}
