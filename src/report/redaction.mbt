///|
fn home_with_suffix(parts : Array[String], start : Int) -> String {
  if parts.length() <= start {
    "$HOME"
  } else {
    "$HOME/" + parts[start:].join("/")
  }
}

///|
fn windows_shared_profile(name : String) -> Bool {
  name == "Public" ||
  name == "Default" ||
  name == "Default User" ||
  name == "All Users"
}

///|
/// Redact common absolute user-home prefixes before values leave the report layer.
///
/// Supported MVP forms:
/// - C:\\Users\\name\\...
/// - C:/Users/name/...
/// - /home/name/...
/// - /Users/name/...
///
/// The collected snapshots remain unchanged; only rendered output is redacted.
pub fn redact_path(path : String) -> String {
  if path == "" || path.has_prefix("$HOME") {
    return path
  }

  let slash_parts = path
    .split("/")
    .map(fn(part) { part.to_owned() })
    .collect()

  if slash_parts.length() >= 3 &&
    slash_parts[0] == "" &&
    (slash_parts[1] == "home" || slash_parts[1] == "Users") &&
    slash_parts[2] != "" {
    return home_with_suffix(slash_parts, 3)
  }

  if slash_parts.length() >= 3 &&
    slash_parts[0].length() == 2 &&
    slash_parts[0].has_suffix(":") &&
    slash_parts[1] == "Users" &&
    slash_parts[2] != "" &&
    !windows_shared_profile(slash_parts[2]) {
    return home_with_suffix(slash_parts, 3)
  }

  let backslash_parts = path
    .split("\\")
    .map(fn(part) { part.to_owned() })
    .collect()

  if backslash_parts.length() >= 3 &&
    backslash_parts[0].length() == 2 &&
    backslash_parts[0].has_suffix(":") &&
    backslash_parts[1] == "Users" &&
    backslash_parts[2] != "" &&
    !windows_shared_profile(backslash_parts[2]) {
    return home_with_suffix(backslash_parts, 3)
  }

  path
}
