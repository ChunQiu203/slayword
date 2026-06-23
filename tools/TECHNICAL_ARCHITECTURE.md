# Slay The Robot — 技术架构文档

## 一、系统架构总览

```
┌──────────────────────────────────────────────────────┐
│                    Godot 4.6 引擎                     │
│  ┌─────────┐ ┌──────────┐ ┌────────┐ ┌───────────┐ │
│  │ Signals  │ │ActionHandler│ │Global  │ │VocabStudy │ │
│  │ (信号总线)│ │ (动作队列) │ │(数据中心)│ │(学习引擎) │ │
│  └─────────┘ └──────────┘ └────────┘ └───────────┘ │
│  ┌─────────────────────────────────────────────────┐ │
│  │         数据驱动层 (21 种数据类型 + JSON)         │ │
│  │  卡牌│敌人│遗物│事件│状态│角色│词书│例句缓存│...   │ │
│  └─────────────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────────────┐ │
│  │         AI 引擎 (云端 + 端侧 双引擎)             │ │
│  │  HTTPRequest × 2 + 文件缓存 + 后台预取           │ │
│  └─────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────┘
```

## 二、13 个 Autoload 单例

| 单例 | 职责 | 行数 |
|------|------|------|
| Signals | 全局信号总线（80+ 信号） | 153 |
| Scenes | 场景资源预加载 | 37 |
| Scripts | 动作/验证器/拦截器脚本路径常量 | 168 |
| FileLoader | JSON 读写 + 模组管线 + 存档 | 434 |
| I18N | 中英双语翻译 | 58 |
| Random | 确定性随机数 + 选秀/商店算法 | 333 |
| Global | 核心数据中心 + 内容注册 (SCHEMA) | 4553 |
| VocabStudy | SRS + 词书管理 + AI API 调用 | 2114 |
| ActionHandler | 动作栈/队列 + 拦截器注册 | 154 |
| ActionGenerator | 动作工厂 + 地图/战斗/奖励生成 | 177 |
| DebugLogger | 日志 | 40 |
| UIDGenerator | UID 生成 | 13 |

## 三、动作系统设计

### 核心概念
所有游戏效果均被原子化为 `BaseAction` 子类，通过 `ActionHandler` 的栈（stack of queues）顺序执行。

### 动作分类
- **Meta Actions**: 动作生成器（AttackGenerator / DrawGenerator），参数化生成实际动作
- **Generated Actions**: 由 Meta Action 生成的实际执行动作（Attack / Draw）
- **Cardset Actions**: 卡组操作（Discard / Exhaust / Banish / AddToHand / Transform）
- **PickCard Actions**: 卡牌选择 UI 驱动（手牌/弃牌堆/抽牌堆/牌组/选秀）
- **Status Actions**: 状态效果（Apply / Decay / Corrosion）
- **World Actions**: 地图/关卡（GenerateAct / VisitLocation / StartCombat）
- **Player Actions**: 玩家数据（AddArtifact / AddMoney / AddConsumable）

### 拦截器链
10 个拦截器按优先级形成处理链，在动作执行前进行改写或拒绝：
- InterceptorDamageIncrease (10000) — 增伤
- InterceptorWeaken (9500) — 削弱
- InterceptorVulnerable (9000) — 易伤
- InterceptorNegateDamage (-10000) — 免疫
- InterceptorPreserveBlock — 保留格挡
- InterceptorDuplicateCardPlays — 双发
- 等

## 四、AI 学习系统架构

### 4.1 SRS 间隔复习算法（SM-2 变体）

```
r = repetition count (0..n)
i = interval in hours
e = easiness factor (1.3..2.5)

Correct answer:
  r += 1
  if r <= 1: i = 1h
  elif r == 2: i = 6h
  else: i *= e
  e = min(2.5, e + 0.1)

Wrong answer:
  r = 0
  i = 1h
  e = max(1.3, e - 0.2)
```

### 4.2 出题策略

1. **优先级队列**: 每日新词计划 → 到期复习词 → 全词池随机
2. **每日配额**: 新词上限 (可配, 默认 15) + 到期复习上限 (可配, 默认 30)
3. **题型随机**: 拼写 / 看英选中义 / 四选一 / 自评回想
4. **干扰项生成**: 从词池取其它词条 headword 或释义作为四选一干扰项

### 4.3 AI 例句生成 Pipeline

```
触发时机: 开局 / 地图节点 / 战斗结束 / 出牌缺例句
     ↓
收集待处理词条 (基于优先级 + 缓存状态)
     ↓
┌─ 端侧可用? ──→ 调用 ON-DEVICE API
│   (蓝心大模型)
└─ 端侧不可用 ──→ 调用云端 API
     ↓
JSON 解析 + 清理 (去 BBCode)
     ↓
写入 user://vocab_example_cache.json
     ↓
同步更新内存词池 + 学习面板展示
```

### 4.4 并发控制
- 两个独立 HTTPRequest 节点：batch（批量）+ ondemand（按需）
- `_example_fetch_in_progress` 字典防重复请求
- Godot ERR_BUSY 错误自动跳过

## 五、数据驱动与模组系统

### SCHEMA 定义
```gdscript
SCHEMA = [
  ["CardData", CardData, "_id_to_card_data", ["cards/"]],
  ["EnemyData", EnemyData, "_id_to_enemy_data", ["enemies/"]],
  # ... 21 种类型
]
```

### 数据加载流程
1. `add_test_*()` — 代码注册测试数据
2. `register_rod()` — 按类型自动分配到对应查找表
3. `FileLoader.load_read_only_data()` — 加载外部 JSON 模组
4. JSON 补丁覆盖已有的测试数据

## 六、移动端适配

- **触控**: SlayMobileStyle 工具类提供 ≥48dp 触控区域按钮
- **布局**: 自适应 Viewport，支持横竖屏切换
- **性能**: GL Compatibility 渲染模式，最小化 Draw Call
- **构建**: Gradle + arm64-v8a，支持 Android 8+
