///|
fn evidence_to_json(evidence : @core.Evidence) -> Json {
  {
    "id": evidence.id,
    "kind": evidence.kind,
    "message": evidence.message,
    "source": evidence.source,
  }
}

///|
fn evidence_list_to_json(evidence : Array[@core.Evidence]) -> Json {
  let items : Array[Json] = []
  for item in evidence {
    items.push(evidence_to_json(item))
  }
  @json.to_json(items)
}

///|
fn diagnosis_to_json(diagnosis : @core.Diagnosis) -> Json {
  {
    "category": diagnosis.category,
    "severity": diagnosis.severity,
    "confidence": diagnosis.confidence,
    "rule_ids": @json.to_json(diagnosis.rule_ids),
    "evidence": evidence_list_to_json(diagnosis.evidence),
    "suggested_checks": @json.to_json(diagnosis.suggested_checks),
  }
}

///|
/// Serialize one reusable diagnostic result. This renderer can be used by
/// library consumers without invoking the AgentTrace CLI.
pub fn render_json(diagnosis : @core.Diagnosis) -> String {
  let value : Json = {
    "schema_version": "0.1",
    "tool_version": @app.version(),
    "summary": {
      "status": if diagnosis.category == "unknown" {
        "unknown"
      } else {
        "problem_detected"
      },
    },
    "diagnoses": [diagnosis_to_json(diagnosis)],
  }
  value.stringify()
}

///|
pub fn render_text(diagnosis : @core.Diagnosis) -> String {
  let mut output =
    "AgentTrace\n\nDiagnosis\n  Category: \{diagnosis.category}\n  Severity: \{diagnosis.severity}\n  Confidence: \{diagnosis.confidence}\n"

  output = output + "\nEvidence\n"
  if diagnosis.evidence.length() == 0 {
    output = output + "  - none\n"
  } else {
    for evidence in diagnosis.evidence {
      output = output + "  - [\{evidence.source}] \{evidence.message}\n"
    }
  }

  output = output + "\nSuggested checks\n"
  if diagnosis.suggested_checks.length() == 0 {
    output = output + "  - none\n"
  } else {
    let mut index = 1
    for check in diagnosis.suggested_checks {
      output = output + "  \{index}. \{check}\n"
      index = index + 1
    }
  }

  output
}
