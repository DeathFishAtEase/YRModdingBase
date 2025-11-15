尤里的复仇 Mod 开发基底
---
## 简述

这是一个整合了 Ares 与 Phobos 引擎的《尤里的复仇》Mod 开发基底

## 使用

1. 在顶端绿色按钮处点击[下载 zip 压缩包](https://github.com/DeathFishAtEase/YRModdingBase/archive/refs/heads/master.zip)
2. 解压后覆盖到你的原版《尤里的复仇》中
3. 使用 `YRLauncher.exe` 启动

> [!Tip]
> [怎么解压zip文件](https://www.baidu.com/s?ie=utf-8&f=8&rsv_bp=1&tn=baidu&wd=%E6%80%8E%E4%B9%88%E8%A7%A3%E5%8E%8Bzip%E6%96%87%E4%BB%B6)

## 2025 版教程光速部署包项目
---
*本光速部署包为 RA2DIY 社区 2025 版基础 **教学材料** 的一部分，请确保你下载了完整的教程包。*

***不要使用倒狗拆分并二次分发后的版本！***

## 关于使用
0. 基于 Starkku 的 CnCNet Client Yuri's Revenge Mod Base，并对界面和复选框进行了一些功能性的更改与补充（例如添加 Phobos 功能的开关、科技等级下拉框等）；
   - 原项目地址：<https://github.com/Starkku/cncnet-client-mod-base>
1. 添加了 Ares（版本 3.0p1）引擎及 Syringe（0.7.3.0_yr）；
   - Ares 项目地址：<https://github.com/Ares-Developers/Ares>
   - Syringe 项目地址：<https://github.com/Ares-Developers/Syringe>
2. 添加了 Phobos（版本 DevBuild#39）引擎；
   - 项目地址：<https://github.com/Phobos-developers/Phobos>
   - 选择此版本是因为 KratosPP 最新版本对 Phobos 的兼容支持仅到 DevBuild#39。
3. 添加了 KratosPP（v0.1.15）引擎；
   - 项目地址：<https://github.com/ra2diy/KratosPP>
4. 添加了可编辑 CSF（v0.3），并转换了两个 llf 文件作为示例；
   - 发布地址：<https://bbs.ra2diy.com/forum.php?mod=viewthread&tid=24441>
5. 添加了头猫魔改版 Reshade，拥有 png 序列动画等功能
   - 发布地址：<https://bbs.ra2diy.com/forum.php?mod=viewthread&tid=17820>
6. 整合了 CnCNet YR 官方中文翻译中的客户端部分
   - 项目地址：<https://github.com/ra2diy/cncnet-yr-client-package>
7. 添加了 @手柄君 的 `game.fnt` 文件，以尽力支持游戏内字符显示
   - 从属于 *红色警戒 2 简体中文语言包*，项目地址：<https://github.com/Translate-with-LOVE/Ra2-zh_hans-main>
8. 编译了一个专用的 `rename.dll` 进行了下述替换：
   - 将读取 `rulesmd.ini` 替换为读取 `rulesst.ini`；
   - 将读取 `artmd.ini` 替换为读取 `artst.ini`；
   - 目的是避免小白兔直接把本包覆盖进了自己的 YR 里然后把自己改过的文件给覆盖了又来哭
   - 项目地址：<https://github.com/CnCNet/cncnet-for-ares>
9. 整合了 YRStandard-INI 项目的 ini Bug 修复与图形文件修复，并针对 *光速部署包* 进行了适配
   - 项目地址：<https://gitee.com/PB_LAB/yrstandard-ini>
   - 前期项目：<https://bbs.ra2diy.com/forum.php?mod=viewthread&tid=17506>
0. 整合了 FA2SP HDM Edition（v1.1.8）
   - 发布地址：<https://bbs.ra2diy.com/forum.php?mod=viewthread&tid=25203>
   - 推荐搭配：<https://www.bilibili.com/opus/1044162757927108627>
1. 整合了原版三阵营居中暂停页面素材，文件为根目录 `sidec01.mix` 与 `sidec02.mix`
   - 下载地址：<http://crowreadman.ysepan.com/>

此外，还有一些内容在本包 `.\自选组件` 中，通常是足够小巧但影响较大的内容，根据个人需要酌情添加

光速部署包由 [@九千天华](https://space.bilibili.com/362533219) 完成并维护至 2025 版教程发布

本使用说明表文件最后一次编辑日期：***2025/10/15***