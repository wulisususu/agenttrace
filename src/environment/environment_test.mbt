///|
test "detect pnpm project facts without diagnosing them" {
  let snapshot = @environment.detect_environment_from_names([
    "package.json",
    "pnpm-lock.yaml",
    "node_modules",
    "tsconfig.json",
    "vitest.config.ts",
  ])

  assert_eq(snapshot.package_managers.length(), 1)
  assert_eq(snapshot.package_managers[0], "pnpm")
  assert_eq(snapshot.lockfiles.length(), 1)
  assert_eq(snapshot.lockfiles[0], "pnpm-lock.yaml")
  assert_eq(snapshot.dependency_markers.length(), 1)
  assert_eq(snapshot.dependency_markers[0], "node_modules")
  assert_eq(snapshot.config_files.length(), 3)
}

///|
test "recognize Yarn PnP without requiring node_modules" {
  let snapshot = @environment.detect_environment_from_names([
    "package.json",
    "yarn.lock",
    ".pnp.cjs",
    ".yarnrc.yml",
  ])

  assert_eq(snapshot.package_managers.length(), 1)
  assert_eq(snapshot.package_managers[0], "yarn")
  assert_eq(snapshot.lockfiles[0], "yarn.lock")
  assert_eq(snapshot.dependency_markers.length(), 1)
  assert_eq(snapshot.dependency_markers[0], ".pnp.cjs")
  assert_eq(snapshot.config_files.length(), 2)
}

///|
test "preserve conflicting lockfile facts for later diagnosis" {
  let snapshot = @environment.detect_environment_from_names([
    "package.json",
    "package-lock.json",
    "pnpm-lock.yaml",
  ])

  assert_eq(snapshot.package_managers.length(), 2)
  assert_eq(snapshot.package_managers[0], "npm")
  assert_eq(snapshot.package_managers[1], "pnpm")
  assert_eq(snapshot.lockfiles.length(), 2)
}

///|
test "empty directory yields an empty environment snapshot" {
  let snapshot = @environment.detect_environment_from_names([])

  assert_eq(snapshot.package_managers.length(), 0)
  assert_eq(snapshot.lockfiles.length(), 0)
  assert_eq(snapshot.dependency_markers.length(), 0)
  assert_eq(snapshot.config_files.length(), 0)
}

///|
async test "collect Yarn PnP fixture from the filesystem" {
  @async.pause()
  let snapshot = @environment.collect_environment(
    "fixtures/environment/yarn-pnp",
  )

  assert_eq(snapshot.package_managers.length(), 1)
  assert_eq(snapshot.package_managers[0], "yarn")
  assert_eq(snapshot.lockfiles.length(), 1)
  assert_eq(snapshot.lockfiles[0], "yarn.lock")
  assert_eq(snapshot.dependency_markers.length(), 1)
  assert_eq(snapshot.dependency_markers[0], ".pnp.cjs")
  assert_eq(snapshot.config_files.length(), 2)
}
