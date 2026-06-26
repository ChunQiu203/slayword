# Slay The Robot

一个基于 Godot 4 引擎的卡牌战斗游戏，灵感来自《杀戮尖塔》。玩家将扮演一个机器人，通过收集卡牌、遗物和消耗品来对抗各种敌人。

## 技术栈

- **引擎**: Godot 4.6
- **语言**: GDScript
- **渲染**: GL Compatibility
- **平台**: Windows, Android

## 项目结构

```
slayword/
├── addons/           # Godot 插件
├── android/          # Android 导出配置
├── autoload/         # 自动加载的单例脚本
├── data/             # 内置数据（已被 external/data/ 替代）
├── external/         # 外部数据和模组系统
│   └── data/         # 游戏数据 JSON 文件
├── json/             # JSON 工具类
├── scenes/           # 游戏场景文件
├── scripts/          # 游戏脚本
│   ├── actions/      # 行动系统（伤害、治疗、格挡等）
│   ├── artifacts/    # 遗物系统
│   ├── card_listeners/ # 卡牌监听器
│   ├── combatants/   # 战斗单位（玩家、敌人）
│   ├── status_effects/ # 状态效果
│   └── ui/           # UI 界面脚本
├── sprites/          # 精灵图资源
├── themes/           # UI 主题
└── tools/            # 开发工具
```

## 如何运行

### 前置条件

1. 安装 [Godot 4.6](https://godotengine.org/download)
2. 克隆此仓库

### 运行游戏

```powershell
# 使用 Godot 编辑器打开项目
godot4 --path D:\code\slayword

# 或直接运行游戏
godot4 --path D:\code\slayword --headless
```

### 导出测试数据

游戏支持将内置测试数据导出为外部 JSON 文件，便于编辑和模组开发：

```powershell
godot4 --path D:\code\slayword -- --export-test-data
```

## 模组系统

游戏支持通过外部 JSON 文件修改游戏内容。所有游戏数据都存储在 `external/data/` 目录下。

### 数据目录

| 目录 | 说明 |
|------|------|
| `cards/` | 卡牌数据 |
| `enemies/` | 敌人数据 |
| `artifacts/` | 遗物数据 |
| `consumables/` | 消耗品数据 |
| `status_effects/` | 状态效果 |
| `characters/` | 角色数据 |
| `events/` | 事件数据 |
| `keywords/` | 关键词说明 |

### 创建模组

1. 复制 `external/data/_templates/` 中的模板文件
2. 粘贴到对应的数据目录
3. 修改文件名和内容
4. 更新 `properties.object_id` 为唯一的 ID

## 游戏特性

- **卡牌战斗**: 基于回合的卡牌战斗系统
- **遗物系统**: 收集遗物获得被动效果
- **状态效果**: 丰富的状态效果系统（毒、易伤、虚弱等）
- **多角色**: 支持多个可玩角色
- **随机事件**: 随机生成的战斗和事件
- **商店系统**: 购买卡牌和遗物
- **国际化**: 支持多语言

## 开发指南

### 核心单例

| 单例 | 说明 |
|------|------|
| `Global` | 全局数据管理 |
| `ActionHandler` | 行动处理器 |
| `ActionGenerator` | 行动生成器 |
| `FileLoader` | 文件加载器 |
| `I18N` | 国际化 |
| `Signals` | 信号管理 |
| `VocabStudy` | 词汇学习 |

### 添加新卡牌

1. 在 `external/data/cards/` 创建 JSON 文件
2. 定义卡牌属性（名称、费用、效果等）
3. 可选：创建自定义脚本处理特殊逻辑

### 添加新敌人

1. 在 `external/data/enemies/` 创建 JSON 文件
2. 定义敌人属性（生命值、意图等）
3. 可选：创建自定义 AI 脚本

## 许可证

请查看项目根目录下的 LICENSE 文件（如果存在）。

## 致谢

- 感谢 [Godot Engine](https://godotengine.org/) 提供的游戏引擎
- 灵感来自 [Slay the Spire](https://www.megacrit.com/)
