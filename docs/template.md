# MarketKy 模板说明

## 开源模板

- 模板名称：MarketKy - Flutter E-Commerce Starter Template
- 仓库地址：https://github.com/mrezkys/marketky
- 许可证：MIT License
- 复用原因：模板已覆盖登录、注册、首页、商品详情、搜索、购物车、评价、订单成功等典型商城页面，符合“复用成熟开源 Flutter 商城模板，禁止从零搭建页面”的课程设计要求。

## 本工程改造说明

本仓库已保留 MarketKy 原始源码副本：`marketky_source/`。原模板使用 Dart SDK `>=2.7.0 <3.0.0`，不能直接在本机 Flutter 3.44 / Dart 3.12 下无修改运行；因此课程设计可运行版本放在 `frontend/`，采用当前 Flutter Web 工程骨架承载升级后的页面、状态管理和 REST API 对接层。

实现时保留 MarketKy 的商城页面范围和交互路径：登录、注册、首页、搜索、购物车、商品详情、评价、订单成功/订单管理等；并按课程设计要求补充买家、商家管理员、超级管理员三类角色入口。

## 页面对应关系

- MarketKy 登录/注册：`frontend/lib/pages/auth`
- MarketKy 首页/搜索/分类：`frontend/lib/pages/buyer/home_page.dart`
- MarketKy 商品详情：`frontend/lib/pages/buyer/product_detail_page.dart`
- MarketKy 购物车：`frontend/lib/pages/buyer/cart_page.dart`
- MarketKy 订单成功/订单列表：`frontend/lib/pages/buyer/orders_page.dart`
- 课程设计新增商家后台：`frontend/lib/pages/merchant`
- 课程设计新增超级管理员后台：`frontend/lib/pages/admin`

## 原模板源码位置

```text
marketky_source/
  lib/views/screens/   # 原 MarketKy 页面
  lib/views/widgets/   # 原 MarketKy 通用组件
  lib/core/model/      # 原 MarketKy 假数据模型
  lib/core/services/   # 原 MarketKy 假数据服务
  assets/              # 原 MarketKy 图片、图标、字体资源
  LICENSE              # MIT License
```
