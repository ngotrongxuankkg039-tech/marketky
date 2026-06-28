-- Demo data for local classroom review.
-- Password for all demo accounts: Password@123

USE marketky_shop;

SET @demo_password_hash = '$2a$10$llrbKw02xRLHf9i6ZVXWNe/lqf.ohKVhL2yf5oEcblHA.v2jNgDJW';

INSERT INTO users(name, email, phone, password_hash, status)
VALUES
  ('演示买家', 'buyer@marketky.local', '13800000001', @demo_password_hash, 'ACTIVE'),
  ('演示商家', 'merchant@marketky.local', '13800000002', @demo_password_hash, 'ACTIVE'),
  ('超级管理员', 'admin@marketky.local', '13800000003', @demo_password_hash, 'ACTIVE')
ON DUPLICATE KEY UPDATE
  name = VALUES(name),
  password_hash = VALUES(password_hash),
  status = VALUES(status);

SET @buyer_id = (SELECT id FROM users WHERE email = 'buyer@marketky.local');
SET @merchant_id = (SELECT id FROM users WHERE email = 'merchant@marketky.local');
SET @admin_id = (SELECT id FROM users WHERE email = 'admin@marketky.local');
SET @buyer_role_id = (SELECT id FROM roles WHERE code = 'BUYER');
SET @merchant_role_id = (SELECT id FROM roles WHERE code = 'MERCHANT_ADMIN');
SET @admin_role_id = (SELECT id FROM roles WHERE code = 'SUPER_ADMIN');

INSERT IGNORE INTO user_roles(user_id, role_id) VALUES
  (@buyer_id, @buyer_role_id),
  (@merchant_id, @merchant_role_id),
  (@admin_id, @admin_role_id);

INSERT INTO carts(user_id)
VALUES (@buyer_id)
ON DUPLICATE KEY UPDATE updated_at = CURRENT_TIMESTAMP;

INSERT INTO addresses(user_id, receiver, phone, province, city, detail, is_default)
SELECT @buyer_id, '演示买家', '13800000001', '北京市', '海淀区', '学院路 1 号数据库课程设计收货点', 1
WHERE NOT EXISTS (
  SELECT 1 FROM addresses WHERE user_id = @buyer_id AND phone = '13800000001'
);

INSERT INTO merchant_applications(user_id, shop_name, description, license_no, status, reviewed_at)
SELECT @merchant_id, '校园优选店', '数据库课程设计演示店铺', 'DEMO-LICENSE-001', 'APPROVED', NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM merchant_applications WHERE user_id = @merchant_id AND shop_name = '校园优选店'
);

INSERT INTO shops(owner_user_id, name, description, contact_phone, status)
VALUES (@merchant_id, '校园优选店', '提供数码、家居、服饰、食品等课程设计演示商品', '13800000002', 'APPROVED')
ON DUPLICATE KEY UPDATE
  owner_user_id = VALUES(owner_user_id),
  description = VALUES(description),
  status = VALUES(status);

SET @shop_id = (SELECT id FROM shops WHERE name = '校园优选店');
SET @digital_id = (SELECT id FROM categories WHERE name = '数码' LIMIT 1);
SET @home_id = (SELECT id FROM categories WHERE name = '家居' LIMIT 1);
SET @fashion_id = (SELECT id FROM categories WHERE name = '服饰' LIMIT 1);
SET @food_id = (SELECT id FROM categories WHERE name = '食品' LIMIT 1);

INSERT INTO products(shop_id, category_id, name, description, price, stock, sales_count, status)
SELECT @shop_id, @digital_id, '蓝牙降噪耳机', '支持主动降噪和长续航，适合作为商品浏览、购物车、下单演示。', 299.00, 32, 0, 'ON_SALE'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE shop_id = @shop_id AND name = '蓝牙降噪耳机');

INSERT INTO products(shop_id, category_id, name, description, price, stock, sales_count, status)
SELECT @shop_id, @home_id, '人体工学椅', '宿舍和书房都能使用的学习椅，库存由 MySQL 事务扣减。', 699.00, 16, 0, 'ON_SALE'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE shop_id = @shop_id AND name = '人体工学椅');

INSERT INTO products(shop_id, category_id, name, description, price, stock, sales_count, status)
SELECT @shop_id, @fashion_id, '通勤双肩包', '轻便防泼水，支持收藏和评价演示。', 159.00, 48, 0, 'ON_SALE'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE shop_id = @shop_id AND name = '通勤双肩包');

INSERT INTO products(shop_id, category_id, name, description, price, stock, sales_count, status)
SELECT @shop_id, @food_id, '精品挂耳咖啡', '课程设计演示食品类商品。', 59.00, 80, 0, 'ON_SALE'
WHERE NOT EXISTS (SELECT 1 FROM products WHERE shop_id = @shop_id AND name = '精品挂耳咖啡');

UPDATE products
SET status = 'ON_SALE'
WHERE shop_id = @shop_id
  AND name IN ('蓝牙降噪耳机', '人体工学椅', '通勤双肩包', '精品挂耳咖啡');

SET @p1 = (SELECT id FROM products WHERE shop_id = @shop_id AND name = '蓝牙降噪耳机' LIMIT 1);
SET @p2 = (SELECT id FROM products WHERE shop_id = @shop_id AND name = '人体工学椅' LIMIT 1);
SET @p3 = (SELECT id FROM products WHERE shop_id = @shop_id AND name = '通勤双肩包' LIMIT 1);
SET @p4 = (SELECT id FROM products WHERE shop_id = @shop_id AND name = '精品挂耳咖啡' LIMIT 1);

INSERT INTO product_images(product_id, url, sort_order)
SELECT @p1, 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=900', 1
WHERE NOT EXISTS (SELECT 1 FROM product_images WHERE product_id = @p1);

INSERT INTO product_images(product_id, url, sort_order)
SELECT @p2, 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=900', 1
WHERE NOT EXISTS (SELECT 1 FROM product_images WHERE product_id = @p2);

INSERT INTO product_images(product_id, url, sort_order)
SELECT @p3, 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=900', 1
WHERE NOT EXISTS (SELECT 1 FROM product_images WHERE product_id = @p3);

INSERT INTO product_images(product_id, url, sort_order)
SELECT @p4, 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=900', 1
WHERE NOT EXISTS (SELECT 1 FROM product_images WHERE product_id = @p4);

INSERT INTO stock_logs(product_id, change_quantity, change_type, remark)
SELECT p.id, p.stock, 'MANUAL_IN', '初始化演示库存'
FROM products p
WHERE p.shop_id = @shop_id
  AND NOT EXISTS (SELECT 1 FROM stock_logs sl WHERE sl.product_id = p.id);
