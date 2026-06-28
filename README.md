# MarketKy Flutter Web 购物管理系统

这是一个面向大学数据库课程设计的购物管理系统工程，采用 Flutter Web + Dart REST API + MySQL 8.0。前端按 MarketKy 开源商城模板的页面范围改造，后端提供用户、商家、商品、购物车、订单、评价、分类、权限等接口。

## 快速运行

1. 初始化数据库：

   ```powershell
   mysql -u root -p < database\schema.sql
   ```

2. 启动后端：

   ```powershell
   .\scripts\run_backend.ps1
   ```

3. 启动 Flutter Web：

   ```powershell
   .\scripts\run_frontend.ps1
   ```

4. Web 打包：

   ```powershell
   .\scripts\build_web.ps1
   ```

## 默认接口

- 后端：`http://localhost:8080`
- 前端 API：`http://localhost:8080/api`
- Flutter Web 通过 `--dart-define=API_BASE_URL=http://localhost:8080/api` 注入后端地址。

## 课程设计关注点

- 主键、外键、唯一键、`CHECK`、状态枚举约束。
- JWT 鉴权和基于角色的权限控制：普通买家、商家管理员、超级管理员。
- 下单事务使用行级锁扣减库存，防止超卖。
- 密码使用 bcrypt 哈希保存，不明文入库。
