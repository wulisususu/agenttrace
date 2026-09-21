///|
pub(all) struct BuildError {
  file : String
  line : Int
  column : Int
  code : String
  message : String
}

///|
pub(all) struct BuildObservation {
  compiler : String
  status : String
  exit_code : Int
  errors : Array[BuildError]
}

///|
fn clean_line(line : StringView) -> String {
  let text = line.to_owned()
  if text.has_suffix("\r") {
    text[:text.length() - 1].to_owned()
  } else {
    text
  }
}

///|
fn parse_int(text : String) -> Int {
  @string.from_str(text) catch {
    _ => 0
  }
}

///|
pub fn parse_tsc(log : String, exit_code : Int) -> BuildObservation {
  let errors : Array[BuildError] = []

  for raw_line in log.split("\n") {
    let line = clean_line(raw_line)
    let error_parts = line
      .split("): error ")
      .map(fn(part) { part.to_owned() })
      .collect()

    if error_parts.length() >= 2 {
      let location_text = error_parts[0]
      let detail_text = error_parts[1:].join("): error ")
      let location_parts = location_text
        .split("(")
        .map(fn(part) { part.to_owned() })
        .collect()

      if location_parts.length() >= 2 {
        let file = location_parts[:location_parts.length() - 1].join("(")
        let coordinates = location_parts[location_parts.length() - 1]
          .split(",")
          .map(fn(part) { part.to_owned() })
          .collect()
        let details = detail_text
          .split(": ")
          .map(fn(part) { part.to_owned() })
          .collect()

        if coordinates.length() == 2 && details.length() >= 2 {
          let line_number = parse_int(coordinates[0])
          let column_number = parse_int(coordinates[1])
          let code = details[0]
          let message = details[1:].join(": ")

          if file != "" &&
            line_number > 0 &&
            column_number > 0 &&
            code.has_prefix("TS") &&
            message != "" {
            errors.push({
              file,
              line: line_number,
              column: column_number,
              code,
              message,
            })
          }
        }
      }
    }
  }

  {
    compiler: "tsc",
    status: if exit_code == 0 { "pass" } else { "fail" },
    exit_code,
    errors,
  }
}
