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
