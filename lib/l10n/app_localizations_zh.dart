// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '赛博修仙';

  @override
  String get defaultKeyText => '按键';

  @override
  String get forceForegroundText => '窗口置顶';

  @override
  String get antiSleepText => '防休眠';

  @override
  String get hideWindowText => '隐藏窗口';

  @override
  String get compactModeText => '迷你模式';

  @override
  String get exitGameText => '退出游戏';

  @override
  String get pomodoroDialogTitle => '番茄钟';

  @override
  String get pomodoroDurationLabel => '专注 (分):';

  @override
  String get pomodoroRelaxLabel => '休息 (分):';

  @override
  String get pomodoroLoopsLabel => '循环次数:';

  @override
  String get pomodoroExpectedExpLabel => '预计经验: ';

  @override
  String get pomodoroStartButtonText => '开始';

  @override
  String get pomodoroSaveAsDefaultButtonText => '保存默认值';

  @override
  String get cancelButtonText => '取消';

  @override
  String get confirmStopTitle => '停止专注?';

  @override
  String get confirmStopContent => '当前的专注进度将丢失。';

  @override
  String get stopButtonText => '停止';

  @override
  String get invalidInputErrorText => '无效';

  @override
  String get settingsTitle => '设置';

  @override
  String get closeButtonText => '关闭';

  @override
  String get language => '语言';

  @override
  String get systemLanguage => '系统默认';

  @override
  String get focusState => '专注';

  @override
  String get relaxState => '休息';

  @override
  String get idleState => '空闲';

  @override
  String get focusPopupStatus => '状态';

  @override
  String get focusPopupTimeRemaining => '剩余时间';

  @override
  String get alwaysShowActionsText => '总是显示操作按钮';

  @override
  String get statsTitle => '统计';

  @override
  String get statsHistoryTrends => '历史趋势';

  @override
  String get statsLast7Days => '最近 7 天';

  @override
  String get statsLast30Days => '最近 30 天';

  @override
  String get statsKeyboard => '按键';

  @override
  String get statsClicks => '点击';

  @override
  String get statsDistance => '距离';

  @override
  String get statsTodaysActivity => '今日活动';

  @override
  String get noDataAvailable => '暂无数据';

  @override
  String get statsClearData => '清除统计';

  @override
  String get statsClearConfirmTitle => '清除所有统计数据?';

  @override
  String get statsClearConfirmContent => '所有保存的活动数据将被永久删除，此操作无法撤销。';

  @override
  String get themeMode => '主题';

  @override
  String get darkMode => '深色';

  @override
  String get lightMode => '浅色';

  @override
  String get autoStartText => '登录时自动启动';

  @override
  String get showSystemStatsText => '显示系统状态';

  @override
  String get showKeyboardTrackText => '显示键盘跟踪';

  @override
  String get showMouseTrackText => '显示鼠标跟踪';

  @override
  String get systemStatsRefreshText => '状态刷新间隔';

  @override
  String systemStatsRefreshSeconds(int seconds) {
    return '$seconds秒';
  }

  @override
  String get accessibilityDialogTitle => '需要辅助功能权限';

  @override
  String get accessibilityDialogContent => '此应用需要辅助功能权限来监控键盘和鼠标活动，以获得修仙体验。';

  @override
  String get accessibilityDialogInstructions =>
      '请在系统设置 → 隐私与安全性 → 辅助功能中启用此应用的权限。';

  @override
  String get accessibilityDialogOpenSettings => '打开设置';

  @override
  String get accessibilityDialogLater => '稍后';

  @override
  String get todoTitle => '待办';

  @override
  String get todoStatusTodo => '待办';

  @override
  String get todoStatusDoing => '进行中';

  @override
  String get todoStatusDone => '已完成';

  @override
  String get todoAddNew => '添加待办';

  @override
  String get todoNewPlaceholder => '输入新待办...';

  @override
  String get todoEmpty => '暂无待办事项';

  @override
  String get todoDeleteConfirmTitle => '删除待办?';

  @override
  String get todoDeleteConfirmContent => '该待办事项将被永久删除。';

  @override
  String get deleteButtonText => '删除';

  @override
  String get gamesTitle => '游戏';

  @override
  String get snakeGameTitle => '贪吃蛇';

  @override
  String get snakeGameDescription => '经典贪吃蛇游戏，吃食物来成长！';

  @override
  String get gameScore => '分数';

  @override
  String get gameOver => '游戏结束';

  @override
  String gameExpGained(int exp) {
    return '获得经验: $exp';
  }

  @override
  String get gamePlayAgain => '再玩一次';

  @override
  String get gamePressToStart => '按空格键或点击开始';

  @override
  String get gameUseArrowKeys => '使用方向键或滑动来移动';

  @override
  String get flappyBirdTitle => '飞翔小鸟';

  @override
  String get flappyBirdDescription => '点击屏幕飞过管道！';

  @override
  String get flappyBirdTapToFlap => '点击或按空格键来拍打翅膀';

  @override
  String get sudokuTitle => '数独';

  @override
  String get sudokuDescription => '经典数字谜题，填满格子！';

  @override
  String get sudokuSelectNumber => '点击下方数字或使用按键 1-9';

  @override
  String get sudokuNewGame => '新游戏';

  @override
  String get sudokuEasy => '简单';

  @override
  String get sudokuMedium => '中等';

  @override
  String get sudokuHard => '困难';

  @override
  String sudokuMistakes(int count, int max) {
    return '错误: $count/$max';
  }

  @override
  String get sudokuCompleted => '恭喜完成！';

  @override
  String get sudokuTooManyMistakes => '错误次数过多！';

  @override
  String sudokuTime(String time) {
    return '用时: $time';
  }

  @override
  String get resetLevelExpText => '重置等级和经验';

  @override
  String get resetLevelExpConfirmTitle => '重置进度?';

  @override
  String get resetLevelExpConfirmContent => '您的等级和经验将被重置到初始状态，此操作无法撤销。';

  @override
  String get resetButtonText => '重置';

  @override
  String get menuBarSettingsTitle => '菜单栏信息';

  @override
  String get menuBarSettingsDescription => '配置菜单栏中显示的信息';

  @override
  String get menuBarShowTrayIcon => '显示托盘图标';

  @override
  String get menuBarInfoFocus => '专注计时';

  @override
  String get menuBarInfoTodo => '待办事项';

  @override
  String get menuBarInfoLevelExp => '等级和经验';

  @override
  String get menuBarInfoCpu => 'CPU';

  @override
  String get menuBarInfoGpu => 'GPU';

  @override
  String get menuBarInfoRam => '内存';

  @override
  String get menuBarInfoDisk => '磁盘';

  @override
  String get menuBarInfoNetwork => '网络';

  @override
  String get menuBarInfoBattery => '电池';

  @override
  String get menuBarInfoKeyboard => '键盘';

  @override
  String get menuBarInfoMouse => '鼠标';

  @override
  String get menuBarInfoSystemTime => '时间';

  @override
  String get menuBarSectionSystem => '系统状态';

  @override
  String get menuBarSectionTracking => '输入追踪';

  @override
  String get menuBarSectionApp => '应用信息';

  @override
  String get menuBarFocusText => '专注';

  @override
  String get menuBarKeyboardText => '按键';

  @override
  String get menuBarMouseText => '鼠标';

  @override
  String get menuBarLevelText => '等级';

  @override
  String get openSaveFolderText => '存档位置';

  @override
  String get menuBarShowWindow => '显示窗口';

  @override
  String get menuBarHideWindow => '隐藏窗口';

  @override
  String get menuBarExit => '退出';

  @override
  String get cpuPopupHeaderProcess => '进程';

  @override
  String get cpuPopupHeaderPid => 'PID';

  @override
  String get cpuPopupHeaderUsage => '占用';

  @override
  String get diskPopupHeaderRead => '读取';

  @override
  String get diskPopupHeaderWrite => '写入';

  @override
  String get networkPopupHeaderDownload => '↓下载';

  @override
  String get networkPopupHeaderUpload => '↑上传';

  @override
  String get networkInfoInterface => '接口';

  @override
  String get networkInfoNetworkName => '网络名';

  @override
  String get networkInfoLocalIp => '内网IP';

  @override
  String get networkInfoPublicIp => '公网IP';

  @override
  String get networkInfoMacAddress => 'MAC';

  @override
  String get networkInfoGateway => '网关';

  @override
  String get networkInfoProcesses => '进程列表';

  @override
  String get debugMenu => '调试';

  @override
  String get debugSetLevelExp => '设置等级和经验';

  @override
  String get debugSetLevelExpTitle => '设置等级和经验';

  @override
  String get debugLevelLabel => '等级';

  @override
  String get debugExpLabel => '当前经验';

  @override
  String get debugMaxExpLabel => '升级所需经验';

  @override
  String get debugApplyButton => '应用';

  @override
  String get exploreTitle => '探索';

  @override
  String get exploreControlsHint => 'WASD移动 • 滚轮缩放';

  @override
  String get exploreExitConfirmTitle => '离开探索？';

  @override
  String get exploreExitConfirmContent => '当前的探索进度将丢失。';

  @override
  String get exploreExitButton => '离开';

  @override
  String get exploreSaveAndLeaveButton => '保存并离开';

  @override
  String get exploreLegendMountain => '山';

  @override
  String get exploreLegendRiver => '河';

  @override
  String get exploreLegendHouse => '屋';

  @override
  String get exploreLegendMonster => '怪';

  @override
  String get exploreLegendBoss => 'Boss';

  @override
  String get exploreLegendNpc => 'NPC';

  @override
  String get exploreLegendPlayer => '玩家';

  @override
  String get exploreLocatePlayer => '定位玩家';

  @override
  String get battleEncounterTitle => '战斗！';

  @override
  String get battleEncounterMonster => '一只怪物挡住了去路！';

  @override
  String get battleEncounterBoss => '强大的Boss出现了！';

  @override
  String get battleYourPower => '你的战力';

  @override
  String get battleEnemyPower => '敌方战力';

  @override
  String get battleFightButton => '战斗！';

  @override
  String get battleFleeButton => '逃跑';

  @override
  String get battleFleeSuccess => '成功逃脱！';

  @override
  String get battleFleeFailed => '逃跑失败！敌人发动攻击！';

  @override
  String get battleResultVictory => '胜利！';

  @override
  String get battleResultDefeat => '失败！';

  @override
  String battleExpGained(String exp) {
    return '+$exp 经验';
  }

  @override
  String battleExpLost(String exp) {
    return '-$exp 经验';
  }

  @override
  String get battleOkButton => '确定';

  @override
  String get exploreApLabel => '行动力';

  @override
  String get exploreApExhaustedTitle => '行动力耗尽';

  @override
  String get exploreApExhaustedContent => '你已没有行动力，离开后下次将开启新的探索。';

  @override
  String exploreHouseRestoreAp(int ap) {
    return '在屋中休憩，恢复了 +$ap 行动力。';
  }

  @override
  String get exploreHouseAlreadyUsed => '这间屋子已经使用过了。';

  @override
  String get exploreNotEnoughAp => '行动力不足。';

  @override
  String get exploreDebugTitle => '调试工具';

  @override
  String get exploreDebugToggleFog => '显示地图';

  @override
  String get exploreDebugFogOn => '迷雾 开';

  @override
  String get exploreDebugFogOff => '迷雾 关';

  @override
  String get exploreDebugModifyAp => '设置行动力';

  @override
  String get exploreDebugApHint => '输入行动力值';

  @override
  String get exploreDebugTeleport => '传送';

  @override
  String get exploreDebugTeleportX => 'X';

  @override
  String get exploreDebugTeleportY => 'Y';

  @override
  String get exploreDebugTeleportGo => '传送';

  @override
  String get exploreDebugTeleportInvalid => '无效位置或不可通行的格子。';

  @override
  String get exploreDebugBattleMode => '战斗模式';

  @override
  String get exploreDebugBattleNormal => '正常';

  @override
  String get exploreDebugBattleAutoWin => '必胜';

  @override
  String get exploreDebugBattleAutoLose => '必败';

  @override
  String get exploreDebugResetHouses => '重置房屋';

  @override
  String get exploreDebugHousesReset => '所有房屋已重置。';

  @override
  String get exploreDebugRegenerateMap => '重新生成地图';

  @override
  String get exploreDebugMapRegenerated => '地图已重新生成。';
}
