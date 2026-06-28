# 项目目录结构

```text
DataBase/
  backend/
    bin/server.dart
    lib/
      config/        # 环境变量、数据库配置
      db/            # MySQL 连接层、通用 CRUD Repository
      middleware/    # CORS、JWT 鉴权、RBAC 权限控制
      models/        # 后端实体和值对象
      routes/        # RESTful API 路由
      utils/         # JSON 响应、请求解析、密码哈希、编号生成
  database/
    schema.sql       # MySQL 8.0 全量建表 SQL
  docs/
    template.md
    project-structure.md
  frontend/
    lib/
      common/        # API 客户端、常量、主题
      model/         # 用户、商品、分类、购物车、地址、订单实体
      provider/      # Provider 状态管理
      pages/         # auth/buyer/merchant/admin 页面
      routes/        # 全局路由
      widgets/       # 商品卡片、价格、统计卡片等通用组件
    web/             # Flutter Web 静态入口
  marketky_source/   # 用户指定的 MarketKy 原模板源码，MIT License
  scripts/
    run_backend.ps1
    run_frontend.ps1
    build_web.ps1
    nginx_marketky.conf
```

## 分层说明

- Flutter 前端只通过 `common/api_client.dart` 访问后端，页面不直接拼接 HTTP 请求。
- Provider 负责登录态、目录数据、购物车、订单和管理后台状态。
- Dart 后端按 `routes -> db -> MySQL` 分层，所有需要身份的接口由 `requireAuth` 和 `requireRoles` 中间件保护。
- 下单接口在 `backend/lib/routes/order_routes.dart` 中使用事务和 `SELECT ... FOR UPDATE`，并写入 `stock_logs`，用于数据库课程设计演示并发控制。
