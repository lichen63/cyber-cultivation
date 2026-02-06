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
  String get exploreNpcAlreadyMet => '你已经见过这位NPC了。';

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

  @override
  String get exploreDebugAddEffects => '添加NPC效果';

  @override
  String get exploreDebugApplyEffects => '应用所选';

  @override
  String exploreDebugEffectsAdded(int count) {
    return '已添加 $count 个效果。';
  }

  @override
  String get exploreDebugEffectPositive => '正面';

  @override
  String get exploreDebugEffectNegative => '负面';

  @override
  String get npcEncounterTitle => 'NPC遭遇';

  @override
  String get npcEffectPositive => '一位旅者赐予你祝福！';

  @override
  String get npcEffectNegative => '一位旅者对你施加了诅咒！';

  @override
  String npcEffectExpGiftPositive(String amount) {
    return '经验赠礼：+$amount 经验';
  }

  @override
  String npcEffectExpStealNegative(String amount) {
    return '经验被窃：-$amount 经验';
  }

  @override
  String npcEffectExpMultiplierPositive(int count) {
    return '经验提升：接下来 $count 场战斗获得2倍经验！';
  }

  @override
  String npcEffectExpMultiplierNegative(int count) {
    return '经验诅咒：接下来 $count 场战斗只获得0.5倍经验！';
  }

  @override
  String get npcEffectExpInsurancePositive => '经验保险：下次战败不会损失经验！';

  @override
  String get npcEffectExpInsuranceNegative => '经验诅咒：下次战胜不会获得经验！';

  @override
  String npcEffectExpFloorPositive(int count) {
    return '经验护盾：接下来 $count 场战斗经验不会低于当前值！';
  }

  @override
  String npcEffectExpFloorNegative(int count) {
    return '经验封顶：接下来 $count 场战斗经验不会超过当前值！';
  }

  @override
  String get npcEffectExpGamblePositive => '幸运赌博：经验翻倍！';

  @override
  String get npcEffectExpGambleNegative => '不幸赌博：经验减半！';

  @override
  String get npcEffectsButtonTooltip => '当前效果';

  @override
  String get npcEffectsDialogTitle => '当前效果';

  @override
  String get npcEffectsEmpty => '暂无生效中的效果。';

  @override
  String npcEffectRemainingBattles(int count) {
    return '剩余 $count 场战斗';
  }

  @override
  String get npcEffectNameExpGiftSteal => '经验赠窃';

  @override
  String get npcEffectNameExpMultiplier => '经验倍增';

  @override
  String get npcEffectNameExpInsurance => '经验保险';

  @override
  String get npcEffectNameExpFloor => '经验保底';

  @override
  String get npcEffectDescMultiplierPositive => '战斗经验2倍';

  @override
  String get npcEffectDescMultiplierNegative => '战斗经验0.5倍';

  @override
  String get npcEffectDescInsurancePositive => '下次战败无经验惩罚';

  @override
  String get npcEffectDescInsuranceNegative => '下次战胜无经验奖励';

  @override
  String npcEffectDescFloorPositive(String value) {
    return '经验不会低于 $value';
  }

  @override
  String npcEffectDescFloorNegative(String value) {
    return '经验不会超过 $value';
  }

  @override
  String get npcEffectNameExpGamble => '经验赌博';

  @override
  String npcEffectRemainingMoves(int count) {
    return '剩余 $count 步';
  }

  @override
  String get npcEffectNameFcBuff => '战力增益';

  @override
  String npcEffectFcBuffPositive(int count) {
    return '战力提升：接下来 $count 场战斗战斗力+20%！';
  }

  @override
  String npcEffectFcBuffNegative(int count) {
    return '战力诅咒：接下来 $count 场战斗战斗力-20%！';
  }

  @override
  String get npcEffectDescFcBuffPositive => '战斗中战力+20%';

  @override
  String get npcEffectDescFcBuffNegative => '战斗中战力-20%';

  @override
  String get npcEffectNameGuaranteedOutcome => '命运封印';

  @override
  String get npcEffectGuaranteedOutcomePositive => '胜利封印：下场战斗必胜！';

  @override
  String get npcEffectGuaranteedOutcomeNegative => '厄运封印：下场战斗必败！';

  @override
  String get npcEffectDescGuaranteedOutcomePositive => '下场战斗：必胜';

  @override
  String get npcEffectDescGuaranteedOutcomeNegative => '下场战斗：必败';

  @override
  String get npcEffectNameFleeMastery => '逃跑精通';

  @override
  String npcEffectFleeMasteryPositive(int count) {
    return '逃脱大师：接下来 $count 次逃跑必定成功！';
  }

  @override
  String npcEffectFleeMasteryNegative(int count) {
    return '困兽之斗：接下来 $count 次逃跑必定失败！';
  }

  @override
  String get npcEffectDescFleeMasteryPositive => '逃跑必定成功';

  @override
  String get npcEffectDescFleeMasteryNegative => '逃跑必定失败';

  @override
  String get npcEffectNameFirstStrike => '先手攻击';

  @override
  String get npcEffectFirstStrikePositive => '先发制人：下场战斗敌人战力减半！';

  @override
  String get npcEffectFirstStrikeNegative => '遭遇埋伏：下场战斗你的战力减半！';

  @override
  String get npcEffectDescFirstStrikePositive => '敌人战力50%';

  @override
  String get npcEffectDescFirstStrikeNegative => '你的战力50%';

  @override
  String get npcEffectNameGlassCannon => '玻璃大炮';

  @override
  String get npcEffectGlassCannonPositive => '玻璃大炮：下场战斗战力+50%！';

  @override
  String get npcEffectGlassCannonNegative => '虚弱：下场战斗战力-50%！';

  @override
  String get npcEffectDescGlassCannonPositive => '下场战斗战力+50%';

  @override
  String get npcEffectDescGlassCannonNegative => '下场战斗战力-50%';

  @override
  String get npcEffectNamePathClearing => '开路';

  @override
  String npcEffectPathClearingPositive(int count) {
    return '开路：$count 座山脉被移除！';
  }

  @override
  String npcEffectPathClearingNegative(int count) {
    return '山崩：$count 座新山脉出现！';
  }

  @override
  String get npcEffectNameRiverBridge => '架桥';

  @override
  String npcEffectRiverBridgePositive(int count) {
    return '架桥：$count 处河流被跨越！';
  }

  @override
  String npcEffectRiverBridgeNegative(int count) {
    return '洪水：$count 处新河流出现！';
  }

  @override
  String get npcEffectNameMonsterCleanse => '清怪';

  @override
  String npcEffectMonsterCleansePositive(int count) {
    return '清怪：$count 只附近的怪物消失了！';
  }

  @override
  String npcEffectMonsterCleanseNegative(int count) {
    return '怪物涌现：$count 只新怪物出现！';
  }

  @override
  String get npcEffectNameBossShift => 'Boss转移';

  @override
  String get npcEffectBossShiftPositive => 'Boss驱逐：最近的Boss被移除！';

  @override
  String get npcEffectBossShiftNegative => 'Boss召唤：一个新Boss出现！';

  @override
  String get npcEffectNameSafeZone => '安全区';

  @override
  String get npcEffectSafeZonePositive => '安全区：你周围的区域清除了危险！';

  @override
  String get npcEffectSafeZoneNegative => '危险区：怪物在你周围出现！';

  @override
  String get npcEffectNameTerrainSwap => '地形交换';

  @override
  String npcEffectTerrainSwapPositive(int count) {
    return '地形清除：$count 座山脉变成了通路！';
  }

  @override
  String npcEffectTerrainSwapNegative(int count) {
    return '地形阻塞：$count 处通路变成了山脉！';
  }

  @override
  String get npcEffectNameFovModify => '视野';

  @override
  String npcEffectFovModifyPositive(int amount) {
    return '远视：视野范围增加 $amount 格！';
  }

  @override
  String npcEffectFovModifyNegative(int amount) {
    return '失明：视野范围减少 $amount 格！';
  }

  @override
  String npcEffectDescFovModifyPositive(int amount) {
    return '视野+$amount';
  }

  @override
  String npcEffectDescFovModifyNegative(int amount) {
    return '视野-$amount';
  }

  @override
  String get npcEffectNameBossRadar => 'Boss雷达';

  @override
  String get npcEffectBossRadarPositive => 'Boss雷达：最近的Boss位置已显示！';

  @override
  String get npcEffectBossRadarNegative => 'Boss隐匿：Boss格子显示为空白直到踩上！';

  @override
  String get npcEffectDescBossRadarNegative => 'Boss显示为空白';

  @override
  String get npcEffectNameNpcRadar => 'NPC雷达';

  @override
  String get npcEffectNpcRadarPositive => 'NPC雷达：最近的NPC位置已显示！';

  @override
  String get npcEffectNpcRadarNegative => 'NPC隐匿：NPC格子显示为空白直到踩上！';

  @override
  String get npcEffectDescNpcRadarNegative => 'NPC显示为空白';

  @override
  String get npcEffectNameMapReveal => '地图揭示';

  @override
  String get npcEffectMapRevealPositive => '制图师：20%的未探索地图已显示！';

  @override
  String npcEffectMapRevealNegative(int count) {
    return '战争迷雾：视野缩小到1格，持续 $count 步！';
  }

  @override
  String get npcEffectDescMapRevealNegative => '视野限制为1格';

  @override
  String get npcEffectNameMonsterRadar => '怪物雷达';

  @override
  String get npcEffectMonsterRadarPositive => '怪物雷达：10格内所有怪物已显示！';

  @override
  String get npcEffectMonsterRadarNegative => '怪物隐形：10格内的怪物现在不可见！';

  @override
  String get npcEffectDescMonsterRadarNegative => '附近怪物不可见';

  @override
  String get npcEffectNameHouseRadar => '房屋雷达';

  @override
  String get npcEffectHouseRadarPositive => '房屋雷达：最近的房屋位置已显示！';

  @override
  String get npcEffectHouseRadarNegative => '房屋隐匿：房屋格子显示为空白直到踩上！';

  @override
  String get npcEffectDescHouseRadarNegative => '房屋显示为空白';

  @override
  String get npcEffectNameTeleport => '传送';

  @override
  String get npcEffectTeleportPositive => '远距传送：传送到远处位置！';

  @override
  String get npcEffectTeleportNegative => '返回：传送回起点！';

  @override
  String get npcEffectNameSpeedBoost => '速度提升';

  @override
  String npcEffectSpeedBoostPositive(int count) {
    return '加速：接下来 $count 步每次移动2格！';
  }

  @override
  String npcEffectSpeedBoostNegative(int count) {
    return '减速：接下来 $count 步每2次按键才移动1次！';
  }

  @override
  String get npcEffectDescSpeedBoostPositive => '每步移动2格';

  @override
  String get npcEffectDescSpeedBoostNegative => '每2次按键移动1次';

  @override
  String get npcEffectNameTeleportHouse => '传送至房屋';

  @override
  String get npcEffectTeleportHousePositive => '房屋传送：传送到最近的房屋！';

  @override
  String get npcEffectTeleportHouseNegative => 'Boss传送：传送到最近的Boss！';

  @override
  String get npcEffectNamePathfinder => '寻路者';

  @override
  String get npcEffectPathfinderPositive => '寻路者：通往最近房屋的最短路径已显示！';

  @override
  String get npcEffectPathfinderNegative => '迷失：所有房屋从地图上消失！';

  @override
  String get npcEffectNameWeakenEnemies => '削弱敌人';

  @override
  String get npcEffectWeakenEnemiesPositive => '虚弱光环：10格范围内怪物战力-30%！';

  @override
  String get npcEffectWeakenEnemiesNegative => '狂暴光环：10格范围内怪物战力+30%！';

  @override
  String get npcEffectNameMonsterConversion => '怪物转化';

  @override
  String npcEffectMonsterConversionPositive(int count) {
    return '驯服：$count 只最近的怪物变成了NPC！';
  }

  @override
  String npcEffectMonsterConversionNegative(int count) {
    return '腐化：$count 个最近的NPC变成了怪物！';
  }

  @override
  String get npcEffectNameBossDowngrade => 'Boss降级';

  @override
  String get npcEffectBossDowngradePositive => '降级：最近的Boss变成了普通怪物！';

  @override
  String get npcEffectBossDowngradeNegative => '升级：最近的怪物变成了Boss！';

  @override
  String get npcEffectNameMonsterFreeze => '怪物冻结';

  @override
  String get npcEffectMonsterFreezePositive => '恐惧光环：下一个怪物接触时会逃跑！';

  @override
  String get npcEffectMonsterFreezeNegative => '激怒：下一个怪物战力+50%！';

  @override
  String get npcEffectDescMonsterFreezePositive => '下个怪物逃跑';

  @override
  String get npcEffectDescMonsterFreezeNegative => '下个怪物+50%战力';

  @override
  String get npcEffectNameClearWave => '清扫波';

  @override
  String get npcEffectClearWavePositive => '净化：3格范围内的怪物被消灭！';

  @override
  String get npcEffectClearWaveNegative => '虫灾：3格范围内生成了怪物！';

  @override
  String get npcEffectNameMonsterMagnet => '怪物磁石';

  @override
  String get npcEffectMonsterMagnetPositive => '排斥：5格范围内的怪物被推开！';

  @override
  String get npcEffectMonsterMagnetNegative => '吸引：5格范围内的怪物靠近了！';

  @override
  String get npcEffectNameNpcBlessingChain => 'NPC祝福链';

  @override
  String get npcEffectNpcBlessingChainPositive => '祝福链：下一个NPC遭遇必定是正面效果！';

  @override
  String get npcEffectNpcBlessingChainNegative => '诅咒链：下一个NPC遭遇必定是负面效果！';

  @override
  String get npcEffectDescNpcBlessingChainPositive => '下个NPC是正面';

  @override
  String get npcEffectDescNpcBlessingChainNegative => '下个NPC是负面';

  @override
  String get npcEffectNameNpcSpawn => 'NPC生成';

  @override
  String npcEffectNpcSpawnPositive(int count) {
    return 'NPC生成：$count 个新NPC出现在地图上！';
  }

  @override
  String npcEffectNpcSpawnNegative(int count) {
    return 'NPC移除：$count 个NPC从地图上消失！';
  }

  @override
  String get npcEffectNameNpcUpgrade => 'NPC升级';

  @override
  String get npcEffectNpcUpgradePositive => '双倍效果：下一个NPC效果翻倍！';

  @override
  String get npcEffectNpcUpgradeNegative => '逆转：下一个NPC效果反转！';

  @override
  String get npcEffectDescNpcUpgradePositive => '下个NPC效果2倍';

  @override
  String get npcEffectDescNpcUpgradeNegative => '下个NPC效果反转';

  @override
  String get npcEffectNameHouseSpawn => '房屋生成';

  @override
  String get npcEffectHouseSpawnPositive => '新庇护所：附近出现了一座房屋！';

  @override
  String get npcEffectHouseSpawnNegative => '房屋摧毁：最近的房屋被移除！';

  @override
  String get npcEffectNameHouseUpgrade => '房屋升级';

  @override
  String get npcEffectHouseUpgradePositive => '强化休息：下次进入房屋获得双倍效果！';

  @override
  String get npcEffectHouseUpgradeNegative => '简陋休息：下次进入房屋只获得一半效果！';

  @override
  String get npcEffectDescHouseUpgradePositive => '下次房屋2倍效果';

  @override
  String get npcEffectDescHouseUpgradeNegative => '下次房屋0.5倍效果';

  @override
  String get npcEffectNameRiskReward => '风险收益';

  @override
  String npcEffectRiskRewardPositive(int count) {
    return '冒险家：+50%经验但-20%战力，持续 $count 场战斗！';
  }

  @override
  String npcEffectRiskRewardNegative(int count) {
    return '稳健派：+20%战力但-50%经验，持续 $count 场战斗！';
  }

  @override
  String get npcEffectDescRiskRewardPositive => '+50%经验，-20%战力';

  @override
  String get npcEffectDescRiskRewardNegative => '+20%战力，-50%经验';

  @override
  String get npcEffectNameSacrifice => '献祭';

  @override
  String npcEffectSacrificePositive(int count) {
    return '献祭：现在失去5%经验，$count 场战斗+30%战力！';
  }

  @override
  String npcEffectSacrificeNegative(int count) {
    return '黑暗交易：现在获得5%经验，$count 场战斗-30%战力！';
  }

  @override
  String get npcEffectDescSacrificePositive => '+30%战力';

  @override
  String get npcEffectDescSacrificeNegative => '-30%战力';

  @override
  String get npcEffectNameAllIn => '孤注一掷';

  @override
  String get npcEffectAllInPositive => '净化：5格内怪物清除 + 额外经验！';

  @override
  String get npcEffectAllInNegative => '灾难：额外Boss生成 + 经验损失！';

  @override
  String get npcEffectNameMirror => '镜像';

  @override
  String get npcEffectMirrorPositive => '镜像：下场战斗你的战力翻倍！';

  @override
  String get npcEffectMirrorNegative => '镜像：下场敌人复制你的战力（50/50概率）！';

  @override
  String get npcEffectDescMirrorPositive => '下场战斗2倍战力';

  @override
  String get npcEffectDescMirrorNegative => '敌人拥有你的战力';

  @override
  String get npcEffectNameCounterStack => '计数叠加';

  @override
  String npcEffectCounterStackPositive(int count) {
    return '势头：每步+1%战力，最多 $count 步！';
  }

  @override
  String npcEffectCounterStackNegative(int count) {
    return '疲劳：每步-1%战力，持续 $count 步！';
  }

  @override
  String npcEffectDescCounterStackPositive(int percent, int count) {
    return '+$percent%战力（$count 层）';
  }

  @override
  String npcEffectDescCounterStackNegative(int percent, int count) {
    return '-$percent%战力（剩余 $count 步）';
  }

  @override
  String get npcEffectNameMapScramble => '地图混乱';

  @override
  String get npcEffectMapScramblePositive => '怪物洗牌：所有怪物移动到新位置！';

  @override
  String get npcEffectMapScrambleNegative => 'NPC洗牌：所有NPC移动到新位置！';

  @override
  String get npcEffectNameCellCounter => '格子计数';

  @override
  String npcEffectCellCounterPositive(int count) {
    return '怪物计数：地图上还剩 $count 只怪物！';
  }

  @override
  String npcEffectCellCounterNegative(int count) {
    return '混乱计数：地图上大概有 $count 只怪物（也许）！';
  }

  @override
  String get npcEffectNameProgressBoost => '进度提升';

  @override
  String npcEffectProgressBoostPositive(int count) {
    return '探索者：$count 个随机格子已标记为探索！';
  }

  @override
  String npcEffectProgressBoostNegative(int count) {
    return '失忆：$count 个已探索格子被遗忘！';
  }
}
