///|
test "configuration example returns independent diagnoses" {
  let evidence : Array[@core.Evidence] = [
    {
      id: "E1",
      kind: "required_config_missing",
      message: "app.toml is missing",
      source: "filesystem",
    },
    {
      id: "E2",
      kind: "deprecated_config_present",
      message: "legacy.conf is present",
      source: "filesystem",
    },
  ]

  let diagnoses = @config_guard.diagnose_configuration(evidence)
  assert_eq(diagnoses.length(), 2)
  assert_eq(diagnoses[0].category, "missing_required_configuration")
  assert_eq(diagnoses[1].category, "deprecated_configuration")
}

///|
test "completed migration suppresses deprecated-config warning" {
  let evidence : Array[@core.Evidence] = [
    {
      id: "E1",
      kind: "deprecated_config_present",
      message: "legacy.conf is present",
      source: "filesystem",
    },
    {
      id: "E2",
      kind: "migration_complete",
      message: "migration marker is present",
      source: "filesystem",
    },
  ]

  let diagnoses = @config_guard.diagnose_configuration(evidence)
  assert_eq(diagnoses.length(), 0)
}
