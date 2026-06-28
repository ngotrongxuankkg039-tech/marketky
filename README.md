# MarketKy Flutter Web 购物管理系统

这是一个面向大学数据库课程设计的购物管理系统工程，采用 Flutter Web + Dart REST API + MySQL 8.0。前端按 MarketKy 开源商城模板的页面范围改造，后端提供用户、商家、商品、购物车、订单、评价、分类、权限等接口。

## 快速运行

1. 初始化数据库：

   ```powershell
   mysql -u root -p < database\schema.sql
   ```

   如果需要可直接演示的账号、店铺和商品数据，再执行：

   ```powershell
   mysql -u root -p marketky_shop
   source C:/Users/xuyug/Documents/DataBase/database/demo_seed.sql;
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

## 演示账号

执行 `database/demo_seed.sql` 后可使用以下账号登录，密码统一为 `Password@123`。

- 买家：`buyer@marketky.local`
- 商家管理员：`merchant@marketky.local`
- 超级管理员：`admin@marketky.local`

`database/demo_seed.sql` 还会写入默认地址、可发货订单、退款申请和商品评价，方便课堂直接验收三类角色闭环：

- 买家端：商品浏览、购物车、默认地址下单、订单退款、订单评价。
- 商家端：商品新增/编辑/改库存/上下架、订单发货、退款审核、店铺资料维护、销售统计。
- 超管端：用户启用/禁用、商家审核、分类新增/编辑/启停、角色权限展示。
- 注册流程：公开注册支持买家注册和商家入驻申请；商家入驻后默认仍是买家角色，需超级管理员审核通过后才获得商家管理员权限。超级管理员账号不开放公开注册，需通过初始化数据或已有超管分配。

## 课程设计关注点

- 主键、外键、唯一键、`CHECK`、状态枚举约束。
- JWT 鉴权和基于角色的权限控制：普通买家、商家管理员、超级管理员。
- 下单事务使用行级锁扣减库存，防止超卖。
- 密码使用 bcrypt 哈希保存，不明文入库。
