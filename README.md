FurFrame 产品需求文档

> 最后更新：2026-03-19
产品概述与技术基石
FurFrame 是一款专为海外宠物主打造的无后台、重隐私、高情绪价值的 iOS 原生应用。它利用 Apple 芯片的本地算力，将用户的 iPhone 变为专属宠物电子相框。
• 目标市场： 美区 App Store（18–45 岁 iPhone 用户）。
• 商业模式： 免费下载 + $9.99 终身买断 (Non-Consumable IAP)。
• 核心原则： 纯本地运行。绝对不复制照片到 App 沙盒，只在 SwiftData 中存储照片的 PHAsset.localIdentifier。

---

🎨 核心页面 UI/UX 与交互详设 (设计师 & 前端必看)
App 采用极简的底部双 Tab 结构：回忆 (Memories) 和 工坊 (Widget Studio)。整体设计语言要求：大量留白、大圆角 (Corner Radius 16-24pt)、柔和的莫兰迪色系或米白色背景、全系统原生 SF Pro 字体。

1. 首次启动与授权 (Onboarding & Scanning)
   这是建立信任的唯一机会，必须通过精美的动画和透明的文案打消隐私顾虑。
   • UI 视觉呈现：
   • 背景： 纯净的米白色 (#F9F9F7)。
   • 视觉中心： 放置一个高质量的 Lottie 动画（例如：一只小狗正在用放大镜看照片，或者猫狗击掌）。
   • 排版： 居中大标题 “Find Your Fur Babies” (SF Pro Rounded, Bold, 32pt)。副标题使用浅灰色说明：“Apple's on-device AI privately finds every cat & dog in your library. Nothing ever leaves your phone.”
   • 按钮： 底部放置一个宽大的主按钮 “Allow Photo Access”，品牌色（如温暖的橘色或克莱因蓝），带轻微阴影。
   • 交互与状态流转：
   • 点击按钮，弹出系统 PhotoKit 授权框。
   • 加载状态 (Loading)： 授权后，原按钮变为进度条，上方文案每隔 1.5 秒动态淡入淡出轮播：“Sniffing for dogs...” → “Looking for cats...” → “Organizing memories...”。
   • 空状态 (Empty State)： 如果扫描完毕结果为 0。展示插画（一只困惑的小狗），标题：“No fur babies found yet!”，副标题：“Try adding some pet photos to your library first.”，并提供 “Scan Again” 按钮。
2. Tab 1：回忆瀑布流 (Memories)
   这是用户日常沉浸式浏览的核心阵地，要求极致的滑动流畅度。
   • UI 视觉呈现：
   • 今日精选 (Hero Section)： 占据屏幕上方 1/3。每天随机展示一张高质量宠物照片，全出血（无边框）。照片底部叠加一个高度为 30% 的极柔和黑色渐变遮罩 (Gradient Overlay)，左下角用白色半透明字体显示拍摄日期（如 "Oct 12, 2023"）。
   • 瀑布流 (Masonry Grid)： 下方为 2 列的不规则瀑布流。图片圆角 12pt，图片间距 (Spacing) 8pt。
   • 导航栏： 滚动时导航栏背景模糊 (Material Blur)，右上角常驻一个极简的「齿轮」图标进入设置。
   • 微交互与手势：
   • 收藏 (Favorite)： 瀑布流每张照片右下角悬浮一个半透明的毛玻璃圆形按钮，内含心形 Icon。点击时，心形变为红色实心，并必须触发一次清脆的 Haptic Feedback (触觉反馈 UIImpactFeedbackGenerator(style: .light))。
   • 全屏查看： 点击任意照片，使用 Hero Animation (SwiftUI 的 matchedGeometryEffect) 平滑放大至全屏。全屏模式背景变为纯黑，支持双指缩放 (Pinch to zoom)。底部提供两个按钮：左侧「Share (调用系统分享面板)」，右侧「Set as Hero (设为今日精选)」。
3. Tab 2：小组件工坊 (Widget Studio)
   这是 App 的变现入口，必须让用户在预览时产生强烈的“我想把它放到桌面上”的冲动。
   • UI 视觉呈现：
   • 顶部尺寸切换： 系统原生的 Picker (Segmented Control 样式)，选项为：Small / Medium / Large / StandBy。
   • 中心预览区： 占据屏幕核心位置。背景为浅灰色带细微网格，模拟手机桌面。中央展示真实比例的小组件，当下方配置更改时，此处必须带有丝滑的过渡动画实时更新。
   • 底部配置卡片 (Bottom Sheet 样式，固定在底部)：
   • 相册源： 两个大圆角按钮：“All Pets” / “Favorites Only (带红心 icon)”。
   • 主题列表 (横向滑动 ScrollView)： 每个主题是一个方形缩略图。
   • 主题样式详设 (Widget Themes)：
   • Minimal (免费)： 极简无边框，照片填满整个 Widget，仅在右下角有极小的 App Logo 水印。
   • Polaroid (免费)： 经典拍立得。白色相框，左右上边距窄，底部留白宽。
   • Film (👑 Pro)： 模拟柯达胶片。照片带有 15% 的噪点遮罩 (Noise Overlay)，边缘有轻微暗角 (Vignette)，边框为黑色带黄色胶片孔。
   • Polaroid + Date (👑 Pro)： 在拍立得的底部留白处，使用 Bradley Hand 或类似手写字体，倾斜 3 度显示照片的真实拍摄日期。
   • StandBy Clock (👑 Pro)： 黑色背景，左侧为圆形宠物头像，右侧为巨大的霓虹色数字时钟。
4. 付费墙 (Paywall)
   当用户点击带有 👑 的 Pro 主题时触发，设计需极具转化力。
   • UI 视觉呈现：
   • 弹出方式： 半屏 Bottom Sheet (.presentationDetents([.large, .medium]))。
   • 头部： 巨大的 “FurFrame Pro” 艺术字，配以闪耀的粒子特效动画。
   • 特权列表 (带绿色 Checkmark)：
   • Unlock all premium desktop aesthetics (Film, Y2K, etc.)
   • Polaroid with handwritten dates
   • StandBy mode exclusive faces
   • 100% private, runs locally forever
   • 购买按钮： 占据屏幕宽度的 90%，高度 56pt，高对比度颜色。文案：“Unlock Forever — $9.99”。下方用极小字体标注 “One-time payment. No subscriptions.”。
   • 底部辅助线： 包含 “Restore Purchases” 和 “Terms & Privacy” 的文字超链接。

---

⚙️ 核心业务逻辑与边界条件 (开发者必看)
为了保证 App 不崩溃、不卡顿、且能顺利通过苹果审核，必须严格实现以下逻辑：

1. 增量扫描与 ID 容错处理
   • 增量扫描： 首次全量扫描后，在 UserDefaults 记录 lastScanDate。用户后续在设置页点击“重新扫描”时，使用 PHFetchOptions 过滤 creationDate > lastScanDate 的照片，仅对新照片运行 Vision 模型。
   • ID 容错 (防崩溃核心)： 用户在系统相册删除了某张猫狗照片，App 数据库里的 ID 就会失效。每次在 UI 渲染前，必须用 PHAsset.fetchAssets(withLocalIdentifiers:) 验证。如果返回为空，静默删除数据库中的该条记录，绝不能在界面上显示裂开的图片图标。
2. Widget Extension 内存红线 (30MB 限制)
   iOS 桌面小组件的内存极其紧张，这是开发最容易翻车的地方。
   • 严禁加载原图： 在 Timeline Provider 中通过 PHImageManager 请求图片时，必须硬编码 targetSize。
   • Small/Medium Widget: CGSize(width: 500, height: 500)
   • StandBy Widget: CGSize(width: 300, height: 300)
   • 请求策略： options.deliveryMode = .fastFormat，options.isSynchronous = true（因为 Timeline Provider 本身在后台线程运行）。
3. App Groups 数据通信
   主 App 和 Widget 属于两个独立的进程。
   • 主 App 的 UI 更改了配置（如选了“胶片风”），必须写入 UserDefaults(suiteName: "group.com.yourapp.furframe")。
   • Widget 刷新时，从该 Suite 读取配置，再根据配置去查询 SwiftData 获取照片 ID 进行渲染。
4. 权限降级处理 (Limited Access)
   iOS 14+ 支持用户只给 App 授权“部分照片”。
   • 如果 PHPhotoLibrary.authorizationStatus() 为 .limited，App 必须正常运行。
   • 此时在“回忆”瀑布流的顶部，插入一个浅黄色的提示条 (Banner)：“Want to find more fur babies? Tap here to allow full library access.”，点击引导至系统设置。绝不能弹窗强迫用户去开启。

---

Apple 原生技术栈蓝图：
功能模块 Apple 原生框架 核心作用与应用场景
界面渲染 SwiftUI 构建主 App 的瀑布流、设置页、付费墙，以及所有桌面小组件的 UI。
AI 图像识别 Vision 纯离线运行VNRecognizeAnimalsRequest，在本地相册中精准找出猫狗照片。
相册读取 PhotoKit 请求相册权限，获取照片的高清大图或降采样缩略图，处理“有限访问”权限。
本地数据库 SwiftData iOS 17 最新推出的数据框架（替代 CoreData），用于极速存储和查询收藏的照片 ID。
桌面小组件 WidgetKit 控制小组件的生命周期、刷新频率（Timeline），以及渲染不同尺寸的相框。
进程间通信 App Groups 利用UserDefaults(suiteName:)让主 App 和小组件共享用户的主题配置。
应用内购买 StoreKit 2 处理 $9.99 的终身买断（Non-Consumable IAP）以及恢复购买逻辑。

---

"我已经配置好了 App Groups，标示符是 group.com.xiaoming.furframe。请使用 UserDefaults(suiteName:) 或 SwiftData 的 shared container 来实现主 App 和小组件的数据同步。"

---

📋 生产交付 Checklist
模块 检查项 (提审前确认)
UI/UX 瀑布流滑动是否掉帧？(需确保异步加载缩略图)
UI/UX 点击收藏是否有震动反馈？空状态是否有插画引导？
技术 桌面小组件连续刷新 10 次是否会黑屏？(测试内存峰值)
技术 在系统相册删掉一张已被识别的狗照片，回到 App 是否会自动消失且不崩溃？
合规 Info.plist中的相册权限文案是否为英文且解释了“纯本地运行”？
合规 免费版是否至少有 2 个主题完全可用？(避免被拒理由：App 功能过于单一/纯付费墙)
合规 付费墙的 “Restore Purchases” 按钮是否真实调用了SKPaymentQueue？
