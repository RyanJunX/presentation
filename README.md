# 文稿提示器 / Presenter Script

在线使用：<https://ryanjunx.github.io/presentation/>

本地使用：双击 `presenter_script.html`。网页内讲稿自动保存到浏览器，不会修改这个 HTML 文件。

## 首次设置

打开在线 `setup.html`，按步骤在 Supabase SQL Editor 执行 `supabase_setup.sql`。
在 Authentication → Users → Add user → Create new user 创建自己的邮箱/密码账号。
密码只在网页登录框输入，不提交到仓库。

Supabase Authentication → URL Configuration：

- Site URL: `https://ryanjunx.github.io/presentation/presenter_script.html`
- Redirect URLs: 添加相同的完整 URL。

默认邮件服务可能限制发送对象；个人使用可先通过手动创建的账号进行密码登录。
Magic Link 需要项目配置可用的邮件发送。

## 电脑与手机

两台设备打开同一网址、登录同一邮箱。电脑编辑后等待“云端已同步”，手机打开网页或点击“同步”即可更新。
页面处于前台时每 15 秒检查一次更新，重新打开/切回页面也会检查。
首次在“云同步设置”里点击“将当前讲稿保存到云端”；云端已有数据时新设备自动读取。

已有本地讲稿：在旧 HTML 中导出 JSON，打开在线页面并登录，导入 JSON，然后保存到云端。
字体、当前幻灯片、当前段落、主题、计时只保留在各自设备。

离线修改保留在本设备。联网后自动重试；数据库比较版本，冲突时不会自动覆盖。
云同步设置中可选择保留当前版本或使用云端版本，建议先导出 JSON。
替换本地版本前的恢复副本保留在本浏览器的 `presenterRecovery:<user_id>` 中。

## 安全与限制

公开的是应用源码与 Supabase Publishable Key。讲稿存放在用户私有的数据行中，RLS 检查登录身份。
Secret、Service Role Key、数据库密码均不得添加到源码。
数据库脚本事务中建立表、按用户隔离的读写策略、原子版本比较 RPC。脚本不赋予匿名用户任何讲稿访问权限。
清空本地数据并恢复 Demo 会作为编辑同步到当前账号，请先导出备份。

每个账号当前保存一套讲稿，最大约 2MB。实时协同合并、历史版本列表和多讲稿管理暂未实现。

## iPhone 与手机端阅读

手机使用紧凑顶栏和底部大按钮；“目录”中可跳页或查看本页 Notes。
右上角“更多”提供 Notes、计时、字体、主题、编辑、云同步和 JSON 备份。
标题旁“专注阅读”隐藏次要工具，顶部“退出专注”随时恢复；它不要求浏览器支持真正全屏，也不承诺隐藏 Safari 地址栏。
桌面保留原布局；全屏 API 不可用或请求被拒绝时，会给出提示并使用专注阅读。

独立入口：iPhone Safari → 共享 → 添加到主屏幕；若有“作为网页 App 打开”，将其开启。
添加前先确认讲稿已同步；独立窗口如需重新登录，使用原账号读取云端数据。只有本地的稿件请先导出 JSON 备份。
主屏幕图标与 manifest 只配置启动外观，没有增加 Service Worker 或离线页面缓存，也没有迁移、改写或清空用户讲稿。

改版前的讲稿字段、存储键、账号认证和 Supabase 数据协议保持不变；显示模式、面板和专注阅读不会触发讲稿上传。
自动测试及浏览器窄屏检查不能替代真实 iPhone Safari 验收，特别是键盘、系统安全区和主屏幕启动表现。
