///|
pub(all) struct EnvironmentSnapshot {
  package_managers : Array[String]
  lockfiles : Array[String]
  dependency_markers : Array[String]
  config_files : Array[String]
}

///|
fn has_entry(entries : Array[String], name : String) -> Bool {
  for entry in entries {
    if entry == name {
      return true
    }
  }
  false
}

///|
fn push_if_present(
  entries : Array[String],
  name : String,
  output : Array[String],
) -> Unit {
  if has_entry(entries, name) {
    output.push(name)
  }
}

///|
fn push_manager_if_lockfile(
  entries : Array[String],
  lockfile : String,
  manager : String,
  managers : Array[String],
  lockfiles : Array[String],
) -> Unit {
  if has_entry(entries, lockfile) {
    lockfiles.push(lockfile)
    if !has_entry(managers, manager) {
      managers.push(manager)
    }
  }
}

///|
pub fn detect_environment_from_names(
  entries : Array[String],
) -> EnvironmentSnapshot {
  let package_managers : Array[String] = []
  let lockfiles : Array[String] = []
  let dependency_markers : Array[String] = []
  let config_files : Array[String] = []

  push_manager_if_lockfile(
    entries,
    "package-lock.json",
    "npm",
    package_managers,
    lockfiles,
  )
  push_manager_if_lockfile(
    entries,
    "npm-shrinkwrap.json",
    "npm",
    package_managers,
    lockfiles,
  )
  push_manager_if_lockfile(
    entries,
    "pnpm-lock.yaml",
    "pnpm",
    package_managers,
    lockfiles,
  )
  push_manager_if_lockfile(
    entries,
    "yarn.lock",
    "yarn",
    package_managers,
    lockfiles,
  )
  push_manager_if_lockfile(
    entries,
    "bun.lock",
    "bun",
    package_managers,
    lockfiles,
  )
  push_manager_if_lockfile(
    entries,
    "bun.lockb",
    "bun",
    package_managers,
    lockfiles,
  )

  push_if_present(entries, "node_modules", dependency_markers)
  push_if_present(entries, ".pnp.cjs", dependency_markers)
  push_if_present(entries, ".pnp.loader.mjs", dependency_markers)

  push_if_present(entries, "package.json", config_files)
  push_if_present(entries, "pnpm-workspace.yaml", config_files)
  push_if_present(entries, ".yarnrc.yml", config_files)
  push_if_present(entries, "tsconfig.json", config_files)
  push_if_present(entries, "vitest.config.ts", config_files)
  push_if_present(entries, "vitest.config.js", config_files)
  push_if_present(entries, "vitest.config.mts", config_files)
  push_if_present(entries, "vitest.config.mjs", config_files)

  {
    package_managers,
    lockfiles,
    dependency_markers,
    config_files,
  }
}

///|
pub async fn collect_environment(path : String) -> EnvironmentSnapshot {
  let entries = @fs.readdir(path, include_hidden=true, sort=true)
  detect_environment_from_names(entries)
}
