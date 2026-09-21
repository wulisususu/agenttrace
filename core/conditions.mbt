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
/// Evaluate a composable condition against a set of structured evidence.
pub fn condition_matches(
  condition : Condition,
  evidence : Array[Evidence],
) -> Bool {
  if condition_is_empty(condition) {
    return false
  }

  for kind in condition.all_of {
    if !evidence_has_kind(evidence, kind) {
      return false
    }
  }

  if condition.any_of.length() > 0 {
    let mut any_matched = false
    for kind in condition.any_of {
      if evidence_has_kind(evidence, kind) {
        any_matched = true
      }
    }
    if !any_matched {
      return false
    }
  }

  for kind in condition.none_of {
    if evidence_has_kind(evidence, kind) {
      return false
    }
  }

  true
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
