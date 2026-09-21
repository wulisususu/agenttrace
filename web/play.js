const GAME = {
  turns: 0,
  wasted: 0,
  hints: 0,
  traceUsed: false,
  finished: false,
  path: [],
  diagnosis: null,
};

const HINTS = [
  "提示 1：27 个测试文件同时以相似方式失败，不一定意味着 27 个文件同时写坏了。",
  "提示 2：注意 BUILD 是 PASS。测试失败和编译失败是两件不同的事。",
  "提示 3：如果源码编译正常，可以优先检查测试依赖、setup 或当前 Worktree 的依赖状态。",
];

const HANDOFF_FALLBACK = [
  "不要修改或回滚源码。",
  "",
  "请先检查当前 Worktree 的测试依赖环境：",
  "1. 确认测试依赖是否完整安装；",
  "2. 确认测试 setup / 初始化文件是否正确加载；",
  "3. 核对当前 Worktree 的依赖目录与 lockfile 状态；",
  "4. 修复环境后重新运行受影响测试。",
  "",
  "只有测试仍然失败时，再考虑修改源码。",
].join("\n");

const qs = (selector) => document.querySelector(selector);
const byId = (id) => document.getElementById(id);

function addTimeline(text, kind = "") {
  const li = document.createElement("li");
  if (kind) li.className = kind;
  const small = document.createElement("small");
  small.textContent = `回合 ${GAME.turns}`;
  const body = document.createElement("span");
  body.textContent = text;
  li.append(small, body);
  byId("timeline").append(li);
  li.scrollIntoView({ behavior: "smooth", block: "nearest" });
}

function updateScore() {
  byId("turn-count").textContent = String(GAME.turns);
  byId("waste-count").textContent = String(GAME.wasted);
  byId("hint-count").textContent = String(GAME.hints);
}

function setAgent(agent, state, message, tone = "") {
  const card = byId(`agent-${agent}`);
  const badge = qs(`[data-agent-state="${agent}"]`);
  const messageNode = byId(`agent-${agent}-message`);

  card.classList.remove("active", "success", "alert");
  badge.classList.remove("danger", "ok");

  if (tone === "active") card.classList.add("active");
  if (tone === "success") {
    card.classList.add("success");
    badge.classList.add("ok");
  }
  if (tone === "danger") {
    card.classList.add("alert");
    badge.classList.add("danger");
  }

  badge.textContent = state;
  messageNode.textContent = message;
}

function classifyIntent(raw) {
  const text = raw.trim().toLowerCase();
  if (!text) return "empty";

  const has = (...terms) => terms.some((term) => text.includes(term));

  if (has("agenttrace", "agent trace", "调用插件", "用插件", "诊断一下", "先诊断")) {
    return "trace";
  }

  if (has(
    "node_modules", "依赖", "环境", "setup", "安装", "lockfile",
    "pnpm", "npm", "yarn", "测试环境", "重新装", "重装"
  )) {
    return "environment";
  }

  if (has("回滚", "rollback", "撤销", "恢复源码", "revert")) {
    return "rollback";
  }

  if (has("改测试", "修改测试", "修测试", "测试代码", "matcher", "断言")) {
    return "modify_tests";
  }

  if (has("源码", "代码", "修复代码", "改代码", "修改代码", "ts2322")) {
    return "modify_source";
  }

  if (has("重跑", "重新跑", "再跑", "重新测试", "rerun")) {
    return "rerun";
  }

  if (has("分支", "worktree", "head", "git")) {
    return "repository";
  }

  return "ambiguous";
}

function consumeTurn(label) {
  GAME.turns += 1;
  GAME.path.push(label);
  updateScore();
}

function markWaste() {
  GAME.wasted += 1;
  updateScore();
}

function freezeCommands() {
  byId("command-input").disabled = true;
  byId("send-button").disabled = true;
  byId("hint-button").disabled = true;
  byId("trace-button").disabled = true;
}

function unfreezeCommands() {
  byId("command-input").disabled = false;
  byId("send-button").disabled = false;
  byId("hint-button").disabled = false;
  byId("trace-button").disabled = false;
}

function handleIntent(intent, raw) {
  if (GAME.finished) return;

  if (intent === "empty") {
    addTimeline("你还没有输入指令。", "");
    return;
  }

  if (intent === "trace") {
    consumeTurn("调用 AgentTrace");
    addTimeline(`你发送：“${raw.trim()}”`, "");
    runAgentTrace();
    return;
  }

  consumeTurn(raw.trim());

  if (intent === "environment") {
    addTimeline(`你让 Agent C 优先检查环境 / 依赖：“${raw.trim()}”`, "good");
    setAgent("fixer", "排查中", "正在检查依赖、测试 setup 和当前 Worktree 环境。", "active");
    setTimeout(() => {
      setAgent("fixer", "发现线索", "测试依赖状态异常，方向正确。", "success");
      byId("manual-root-cause").hidden = false;
      byId("manual-root-cause").scrollIntoView({ behavior: "smooth", block: "center" });
      addTimeline("Agent C：发现测试依赖状态异常。你已经接近根因。", "good");
    }, 550);
    return;
  }

  if (intent === "rollback") {
    markWaste();
    addTimeline("Agent C 回滚了最近源码修改，但测试仍然 27 / 155 失败。", "bad");
    setAgent("fixer", "完成", "源码已回滚，但错误完全没有变化。", "danger");
    setAgent("validator", "仍失败", "27 个测试文件、155 个测试仍然失败。", "danger");
    return;
  }

  if (intent === "modify_tests") {
    markWaste();
    addTimeline("Agent C 修改了测试代码，但相同 matcher 错误继续出现。", "bad");
    setAgent("fixer", "完成", "测试代码已修改，但根因仍未消失。", "danger");
    return;
  }

  if (intent === "modify_source") {
    markWaste();
    addTimeline("Agent C 修改了源码，但 BUILD 原本就是 PASS，测试仍然失败。", "bad");
    setAgent("fixer", "完成", "源码改动没有解决测试环境里的重复错误。", "danger");
    return;
  }

  if (intent === "rerun") {
    addTimeline("重新运行测试：27 个测试文件、155 个测试仍然失败。", "bad");
    setAgent("validator", "仍失败", "重复运行没有改变错误签名。", "danger");
    return;
  }

  if (intent === "repository") {
    addTimeline("Agent C 检查了 Git / Worktree：当前分支没有发现本关相关异常。", "");
    setAgent("fixer", "检查完成", "仓库状态不是这次故障的主要方向。", "");
    return;
  }

  markWaste();
  addTimeline(`Agent C 无法从指令中得到明确、可验证的排查方向：“${raw.trim()}”`, "bad");
  setAgent("fixer", "需要澄清", "请告诉我具体要检查代码、测试、环境还是仓库现场。", "danger");
}

async function runAgentTrace() {
  if (GAME.traceUsed || GAME.finished) return;
  GAME.traceUsed = true;
  freezeCommands();

  setAgent("builder", "暂停", "等待诊断完成。", "active");
  setAgent("validator", "暂停", "保留当前失败现场。", "active");
  setAgent("fixer", "暂停", "不再继续修改代码。", "active");
  addTimeline("AgentTrace：开始读取构建结果、测试统计和重复错误签名。", "trace");

  try {
    const response = await fetch("./data/dependency-environment.json", { cache: "no-store" });
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    const data = await response.json();
    GAME.diagnosis = data;

    const diagnosis = data.diagnoses?.[0];
    if (!diagnosis || !diagnosis.rule_ids?.includes("R001")) {
      throw new Error("R001 diagnosis missing");
    }

    byId("trace-rule-id").textContent = diagnosis.rule_ids.join(", ");
    byId("trace-build").textContent = data.build?.status === "pass" ? "通过" : "未知";
    byId("trace-suites").textContent = String(data.tests?.failed_suites ?? "—");
    byId("trace-tests").textContent = String(data.tests?.failed_tests ?? "—");
    byId("trace-confidence").textContent =
      diagnosis.confidence === "high" ? "高" : diagnosis.confidence;

    byId("handoff-prompt").value = buildHandoffPrompt(diagnosis);
    byId("trace-result").hidden = false;
    byId("manual-root-cause").hidden = true;
    byId("trace-result").scrollIntoView({ behavior: "smooth", block: "start" });
    addTimeline("AgentTrace：R001，高置信度。优先检查测试依赖 / 环境，不要先改源码。", "trace");
  } catch (error) {
    console.error(error);
    addTimeline("AgentTrace 数据加载失败，本次互动无法继续诊断。", "bad");
    GAME.traceUsed = false;
    unfreezeCommands();
  }
}

function buildHandoffPrompt(diagnosis) {
  const checks = diagnosis.suggested_checks || [];
  if (!checks.length) return HANDOFF_FALLBACK;

  const translated = checks.map((item) => {
    const table = {
      "verify installed test dependencies": "确认测试依赖是否完整安装",
      "verify test setup loading": "确认测试 setup / 初始化文件是否正确加载",
      "rerun the affected test suite before reverting source changes":
        "修复环境后重新运行受影响测试；在此之前不要回滚源码",
    };
    return table[item] || item;
  });

  return [
    "不要修改或回滚源码。",
    "",
    "AgentTrace 已确认：编译通过，但大量测试共享同一种失败签名，更可能是测试依赖 / 环境问题。",
    "",
    "请按下面顺序验证：",
    ...translated.map((item, index) => `${index + 1}. ${item}；`),
    `${translated.length + 1}. 记录验证结果，并在环境恢复后重新运行测试。`,
    "",
    "只有测试仍然失败时，再考虑修改源码。",
  ].join("\n");
}

function simulateEnvironmentFix(source) {
  if (GAME.finished) return;
  freezeCommands();
  byId("manual-root-cause").hidden = true;

  if (source === "agenttrace") {
    setAgent("fixer", "执行中", "正在按照 AgentTrace 指令检查依赖和测试 setup。", "active");
    addTimeline("Agent C 接收 AgentTrace 生成的下一步指令，开始修复测试环境。", "trace");
  } else {
    setAgent("fixer", "执行中", "正在根据你的判断手动修复测试依赖环境。", "active");
    addTimeline("你决定直接修复测试环境。", "good");
  }

  setTimeout(() => {
    setAgent("fixer", "修复完成", "发现并恢复了异常测试依赖状态。", "success");
    setAgent("validator", "通过", "27 个测试文件通过，155 个测试通过。", "success");
    setAgent("builder", "完成", "源码无需回滚。", "success");
    addTimeline("重新测试：全部通过。真正的问题是测试依赖 / 环境异常。", "good");
    finishGame();
  }, 750);
}

function finishGame() {
  GAME.finished = true;
  byId("result-waste").textContent = `${GAME.wasted} 次`;
  byId("result-trace").textContent = GAME.traceUsed ? "是" : "否";
  byId("result-turns").textContent = String(GAME.turns);

  let summary = "";
  if (GAME.traceUsed && GAME.wasted === 0) {
    summary = "你在任何源码修改之前先完成了故障归因：没有产生无效修复。";
  } else if (GAME.traceUsed) {
    summary = `你经历了 ${GAME.wasted} 次无效操作后调用 AgentTrace，把排查方向从“继续改代码”切回了真正的环境问题。`;
  } else {
    summary = "你凭自己的经验找到了正确方向。AgentTrace 在真实开发中可以把这种经验判断变成可复现、可交给下一位 Agent 的结构化证据。";
  }
  byId("result-summary").textContent = summary;

  const pathRoot = byId("result-path");
  pathRoot.replaceChildren();
  const finalPath = [...GAME.path, "定位测试环境", "测试恢复"];
  finalPath.forEach((item, index) => {
    if (index > 0) {
      const arrow = document.createElement("span");
      arrow.className = "path-arrow";
      arrow.textContent = "→";
      pathRoot.append(arrow);
    }
    const chip = document.createElement("span");
    chip.className = "path-chip";
    chip.textContent = item;
    pathRoot.append(chip);
  });

  byId("result-panel").hidden = false;
  byId("result-panel").scrollIntoView({ behavior: "smooth", block: "start" });
}

function resetGame() {
  Object.assign(GAME, {
    turns: 0,
    wasted: 0,
    hints: 0,
    traceUsed: false,
    finished: false,
    path: [],
    diagnosis: null,
  });

  updateScore();
  byId("timeline").replaceChildren();
  byId("trace-result").hidden = true;
  byId("manual-root-cause").hidden = true;
  byId("result-panel").hidden = true;
  byId("command-input").value = "";
  byId("handoff-prompt").value = "";

  setAgent("builder", "完成", "Settings 页面已实现，仅修改 3 个源码文件。", "");
  setAgent("validator", "失败", "27 个测试文件失败，155 个测试失败。", "danger");
  setAgent("fixer", "等待", "“告诉我下一步该改什么。”", "");
  unfreezeCommands();

  addTimeline("Agent A：功能开发完成，只修改了 3 个源码文件。");
  addTimeline("Agent B：测试失败，27 个测试文件 / 155 个测试均失败。", "bad");
  addTimeline("Agent C：等待你的下一条指令。");
}

byId("command-form").addEventListener("submit", (event) => {
  event.preventDefault();
  const raw = byId("command-input").value;
  const intent = classifyIntent(raw);
  handleIntent(intent, raw);
  if (intent !== "empty") byId("command-input").value = "";
});

byId("hint-button").addEventListener("click", () => {
  if (GAME.finished) return;
  const index = Math.min(GAME.hints, HINTS.length - 1);
  GAME.hints += 1;
  updateScore();
  addTimeline(HINTS[index], "trace");
});

byId("trace-button").addEventListener("click", () => {
  consumeTurn("调用 AgentTrace");
  runAgentTrace();
});

byId("manual-trace-button").addEventListener("click", () => {
  consumeTurn("用 AgentTrace 确认环境判断");
  runAgentTrace();
});

byId("manual-fix-button").addEventListener("click", () => {
  consumeTurn("直接修复测试环境");
  simulateEnvironmentFix("manual");
});

byId("execute-handoff-button").addEventListener("click", () => {
  consumeTurn("发送 AgentTrace 指令给 Agent C");
  simulateEnvironmentFix("agenttrace");
});

byId("copy-prompt-button").addEventListener("click", async () => {
  try {
    await navigator.clipboard.writeText(byId("handoff-prompt").value);
    byId("copy-prompt-button").textContent = "已复制";
    setTimeout(() => { byId("copy-prompt-button").textContent = "复制指令"; }, 1200);
  } catch {
    byId("handoff-prompt").select();
  }
});

byId("restart-button").addEventListener("click", () => {
  resetGame();
  window.scrollTo({ top: 0, behavior: "smooth" });
});

resetGame();
