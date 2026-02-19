# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-02-19

### Added
- 完整重构，采用 Clean Architecture
- Riverpod 状态管理
- Drift 本地数据库
- 扫码绑定服务器功能 (mobile_scanner)
- 数据统计页面 (日/周/月图表)
- 服务器管理 (增/删/改/切换)
- 设置页面 (权限/通知/数据)
- 深色模式支持
- Material 3 UI

### Changed
- 最低 Flutter 版本提升至 3.10
- 最低 Android SDK 提升至 21
- 重新设计 UI/UX
- 默认只编译 arm64 架构 (APK 38MB vs 73MB)

### Removed
- 移除旧版 provider 状态管理
- 移除旧版 sqflite 数据库
- 移除 flutter_zoekits 依赖

## [1.0.0] - 2024-xx-xx

### Added
- 初始版本
- 支付通知监听
- 基础上报功能
