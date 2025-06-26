# Cyber Practice

一个基于Godot引擎开发的网络实践陪伴游戏项目。

## 项目结构

```
cyber-practice/
├── assets/                 # 游戏资源
│   ├── audio/             # 音频文件
│   │   ├── music/         # 背景音乐
│   │   └── sfx/           # 音效
│   ├── graphics/          # 图形资源
│   │   ├── ui/            # UI相关图片
│   │   ├── sprites/       # 精灵图片
│   │   └── backgrounds/   # 背景图片
│   ├── fonts/             # 字体文件
│   └── icons/             # 图标文件
├── scenes/                # 场景文件
│   ├── MainMenu.tscn      # 主菜单场景
│   ├── Game.tscn          # 游戏主场景
│   └── ui/                # UI场景
├── scripts/               # 脚本文件
│   ├── managers/          # 管理器脚本
│   │   ├── AudioManager.gd       # 音频管理器
│   │   └── CompanionManager.gd    # 陪伴管理器
│   ├── ui/                # UI相关脚本
│   │   └── MainMenu.gd    # 主菜单脚本
│   └── game/              # 游戏逻辑脚本
│       └── Game.gd        # 游戏主控制器
├── addons/                # 插件
├── project.godot          # 项目配置文件
├── .gitignore            # Git忽略文件
└── README.md             # 项目说明文档
```

## 开发环境

- **引擎版本**: Godot 4.3+
- **平台**: 跨平台（Windows, macOS, Linux）
- **语言**: GDScript

## 功能特性

- 网络实践陪伴体验
- 现代UI界面
- 跨平台支持
- 可扩展架构

## 安装与运行

1. 下载并安装 [Godot 4.3](https://godotengine.org/download)
2. 克隆此仓库到本地
3. 在Godot编辑器中打开项目
4. 点击运行按钮开始游戏

## 开发指南

### 代码规范

- 使用GDScript作为主要开发语言
- 遵循Godot官方代码风格指南
- 类名使用PascalCase
- 变量和函数名使用snake_case
- 常量使用SCREAMING_SNAKE_CASE

### 目录说明

- `assets/`: 存放所有游戏资源文件
- `scenes/`: 存放场景文件(.tscn)
- `scripts/`: 存放脚本文件(.gd)
- `addons/`: 存放第三方插件

### 网络实践陪伴设计原则

- 寓教于乐的学习体验
- 实践技能陪伴指导
- 个性化学习内容
- 循序渐进的练习节奏
- 积极正面的学习反馈

## 网络实践功能详解

### 智能学习助手
- **个性化设置**: 可自定义助手的名称和教学风格
- **学习状态**: 助手拥有多种教学模式（指导、练习、评估、鼓励等）
- **进度系统**: 通过学习和实践提升技能等级
- **智能提醒**: 合理的学习提醒和复习机制

### 实践体验
- **语音指导**: 支持语音说明和引导（可开关）
- **实时反馈**: 根据学习进度给予及时的指导建议
- **个性化内容**: 基于用户水平调整学习内容
- **渐进式学习**: 不急躁的循序渐进学习方式

## 贡献

欢迎提交Issue和Pull Request来帮助改进这个项目。

## 许可证

本项目采用MIT许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 联系方式

如有问题或建议，请通过GitHub Issues联系我们。
