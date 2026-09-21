///|
pub(all) struct ErrorSignature {
  message : String
  occurrences : Int
}

///|
pub(all) struct TestObservation {
  runner : String
  status : String
  failed_suites : Int
  failed_tests : Int
  assertion_failures : Int
  error_signatures : Array[ErrorSignature]
}

///|
fn non_empty_words(line : StringView) -> Array[String] {
  line
    .split(" ")
    .filter(fn(part) { part != "" })
    .map(fn(part) { part.to_owned() })
    .collect()
}

///|
fn parse_count(text : String) -> Int {
  @string.from_str(text) catch {
    _ => 0
  }
}

///|
fn is_missing_matcher_line(line : StringView) -> Bool {
  let text = line.to_owned()
  text == "Error: Invalid Chai property: toBeInTheDocument" ||
  text == "Error: Invalid Chai property: toBeInTheDocument\r"
}

///|
pub fn parse_vitest(log : String) -> TestObservation {
  let mut failed_suites = 0
  let mut failed_tests = 0
  let mut assertion_failures = 0
  let mut missing_matcher_occurrences = 0
  let mut saw_summary = false

  for line in log.split("\n") {
    let words = non_empty_words(line)
    let text = line.to_owned()

    if words.length() >= 4 &&
      words[0] == "Test" &&
      words[1] == "Files" &&
      (words[3] == "failed" || words[3] == "passed") {
      saw_summary = true
      if words[3] == "failed" {
        failed_suites = parse_count(words[2])
      }
    }

    if words.length() >= 3 &&
      words[0] == "Tests" &&
      (words[2] == "failed" || words[2] == "passed") {
      saw_summary = true
      if words[2] == "failed" {
        failed_tests = parse_count(words[1])
      }
    }

    if text.contains("AssertionError:") {
      assertion_failures = assertion_failures + 1
    }

    if is_missing_matcher_line(line) {
      missing_matcher_occurrences = missing_matcher_occurrences + 1
    }
  }

  let error_signatures : Array[ErrorSignature] = []
  if missing_matcher_occurrences > 0 {
    error_signatures.push({
      message: "Invalid Chai property: toBeInTheDocument",
      occurrences: missing_matcher_occurrences,
    })
  }

  let status = if failed_suites > 0 || failed_tests > 0 {
    "fail"
  } else if saw_summary {
    "pass"
  } else {
    "unknown"
  }

  {
    runner: "vitest",
    status,
    failed_suites,
    failed_tests,
    assertion_failures,
    error_signatures,
  }
}
