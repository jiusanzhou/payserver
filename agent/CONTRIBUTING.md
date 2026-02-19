# Contributing to PayServer Agent

感谢你对 PayServer 的关注！欢迎提交 Issue 和 Pull Request。

## 开发环境

1. 安装 Flutter 3.10+
2. Clone 仓库
3. 安装依赖：`flutter pub get`
4. 生成代码：`flutter pub run build_runner build`

## 代码规范

- 遵循 [Effective Dart](https://dart.dev/guides/language/effective-dart) 风格
- 使用 `flutter analyze` 检查代码
- 提交前运行 `flutter format .`

## 提交规范

使用 [Conventional Commits](https://www.conventionalcommits.org/)：

```
feat: 添加新功能
fix: 修复 bug
docs: 更新文档
style: 代码格式调整
refactor: 代码重构
test: 添加测试
chore: 构建/工具变更
```

## 目录结构

```
lib/
├── core/           # 核心功能 (服务、主题、工具)
├── data/           # 数据层 (API、数据库)
├── domain/         # 领域层 (实体模型)
├── presentation/   # 表现层 (页面、Provider)
└── main.dart       # 入口
```

## Pull Request

1. Fork 仓库
2. 创建功能分支：`git checkout -b feat/my-feature`
3. 提交变更
4. 推送分支：`git push origin feat/my-feature`
5. 创建 Pull Request

## 问题反馈

- 使用 GitHub Issues
- 描述问题 + 复现步骤 + 环境信息
- 提供日志或截图

## License

贡献的代码将采用 MIT 许可证。
