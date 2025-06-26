# Desktop ACC Game

一个基于Godot引擎开发的桌面陪伴游戏项目。

## 项目结构

```
desktop-acc/
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

- 陪伴互动体验
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

### 陪伴游戏设计原则

- 温暖友好的交互体验
- 情感支持和陪伴功能
- 个性化陪伴内容
- 舒缓放松的游戏节奏
- 积极正面的互动反馈

## 陪伴功能详解

### 虚拟陪伴者
- **个性化设置**: 可自定义陪伴者的名称和性格
- **情绪系统**: 陪伴者拥有多种情绪状态（开心、平静、兴奋、好奇等）
- **友好度系统**: 通过互动提升友好度等级
- **定时互动**: 智能的互动提醒机制

### 互动体验
- **语音陪伴**: 支持语音播报和对话（可开关）
- **情感反馈**: 根据用户行为给予积极的情感支持
- **个性化内容**: 基于用户偏好调整互动内容
- **舒缓节奏**: 不打扰的温和陪伴方式

## 贡献

欢迎提交Issue和Pull Request来帮助改进这个项目。

## 许可证

本项目采用MIT许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 联系方式

如有问题或建议，请通过GitHub Issues联系我们。
