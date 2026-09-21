const DATA_URL = "./data/dependency-environment.json";

const CASE_META = {
  title: "Dependency environment failure",
  summary:
    "Compilation succeeded while repeated test failures point to the dependency or test environment before source rollback.",
  reproduce: [
    "moon run cmd/main inspect . \\",
    "  --log fixtures/logs/vitest-missing-matcher.txt \\",
    "  --build-exit-code 0 \\",
    "  --format json",
  ].join("\n"),
};

const byId = (id) => document.getElementById(id);

function setText(id, value) {
  byId(id).textContent = value ?? "—";
}

function shortHead(value) {
  if (!value) return "—";
  return value.length > 12 ? value.slice(0, 12) : value;
}

function renderEvidence(items) {
  const list = byId("evidence-list");
  list.replaceChildren();

  items.forEach((evidence, index) => {
    const item = document.createElement("li");
    item.className = "evidence-item";

    const marker = document.createElement("span");
    marker.className = "evidence-index";
    marker.textContent = String(index + 1).padStart(2, "0");

    const body = document.createElement("div");
    const title = document.createElement("strong");
    title.textContent = evidence.message;
    const meta = document.createElement("p");
    meta.textContent = `${evidence.kind} · source: ${evidence.source}`;

    body.append(title, meta);
    item.append(marker, body);
    list.append(item);
  });

  setText("evidence-count", `${items.length} signal${items.length === 1 ? "" : "s"}`);
}

function renderActions(items) {
  const list = byId("suggested-checks");
  list.replaceChildren();

  items.forEach((action) => {
    const item = document.createElement("li");
    item.textContent = action;
    list.append(item);
  });
}

function renderReport(data) {
  const diagnosis = data.diagnoses?.[0];
  if (!diagnosis) throw new Error("Visual Report requires at least one diagnosis");

  setText("diagnosis-title", CASE_META.title);
  setText("diagnosis-summary", CASE_META.summary);
  setText("severity", diagnosis.severity);
  setText("confidence", diagnosis.confidence);
  setText("rule-ids", diagnosis.rule_ids?.join(", ") || "—");

  setText("build-status", data.build?.status || "not supplied");
  setText("build-compiler", data.build?.compiler);
  setText("build-exit", data.build?.exit_code);

  setText("test-status", data.tests?.status || "not supplied");
  setText("failed-suites", data.tests?.failed_suites);
  setText("failed-tests", data.tests?.failed_tests);

  setText("repo-branch", data.repository?.branch);
  setText("repo-head", shortHead(data.repository?.head));
  setText("repo-dirty", String(Boolean(data.repository?.is_dirty)));

  renderEvidence(diagnosis.evidence || []);
  renderActions(diagnosis.suggested_checks || []);

  setText("schema-version", `schema ${data.schema_version || "—"}`);
  setText("reproduce-command", CASE_META.reproduce);

  byId("report").hidden = false;
}

async function main() {
  try {
    const response = await fetch(DATA_URL, { cache: "no-store" });
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    const data = await response.json();
    renderReport(data);
  } catch (error) {
    console.error(error);
    setText("diagnosis-title", "Visual Report bundle is incomplete");
    setText(
      "diagnosis-summary",
      "The static UI loaded, but its CLI-generated diagnosis JSON is missing or invalid.",
    );
    byId("error-state").hidden = false;
  }
}

main();
