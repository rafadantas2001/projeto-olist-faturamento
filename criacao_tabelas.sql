USE Projeto_Olist;
GO 

--- Criação da tabela Clientes ---

CREATE TABLE olist_customers (
	customer_id NVARCHAR(50) NOT NULL PRIMARY KEY,
	customer_unique_id NVARCHAR(50) NOT NULL,
	customer_zip_code_prefix NVARCHAR(10) NOT NULL,
	customer_city NVARCHAR(100) NOT NULL,
	customer_state NVARCHAR(2) NOT NULL
	);

DROP TABLE olist_customers;

SELECT TOP 10 * FROM olist_customers;

SELECT customer_city, customer_state
FROM olist_customers
WHERE customer_state = 'SP';

--- Criação da tabela Pedidos ---

CREATE TABLE olist_orders (
	order_id NVARCHAR(50) NOT NULL PRIMARY KEY,
	customer_id NVARCHAR(50) NOT NULL ,
	order_status NVARCHAR(20) NOT NULL,
	order_purchase_timestamp NVARCHAR(30) NOT NULL,
	order_approved_at NVARCHAR(30) NOT NULL,
	order_delivered_carrier_date NVARCHAR(30) NOT NULL,
	order_delivered_customer_date NVARCHAR(30) NOT NULL,
	order_estimated_delivery_date NVARCHAR(30) NOT NULL
	);

SELECT * FROM olist_orders;

SELECT TOP 10 * FROM olist_orders;

--- Criação da tabela Itens dos Pedidos ---

CREATE TABLE olist_order_items (
	order_id NVARCHAR(50) NOT NULL,
	order_item_id INT NOT NULL,
	product_id NVARCHAR(50) NOT NULL,
	seller_id NVARCHAR(50) NOT NULL, 
	shopping_limit_date NVARCHAR(30) NULL,
	price NVARCHAR (20) NOT NULL,
	freight_value NVARCHAR (20) NOT NULL,
	PRIMARY KEY (order_id, order_item_id)
	
	);

DROP TABLE olist_order_items;

SELECT TOP 10 * FROM olist_order_items;

--- Criação da tabela Produtos ---

CREATE TABLE olist_products (
	product_id NVARCHAR(50) NOT NULL,
	product_category_name NVARCHAR(100) NULL,
	product_name_lenght NVARCHAR(20) NULL,
	product_description_lenght NVARCHAR(20) NULL,
	product_photos_qty NVARCHAR(20) NULL,
	product_weight_g NVARCHAR(20) NULL,
	product_length_cm NVARCHAR(20) NULL,
	product_height_cm NVARCHAR(20) NULL,
	product_width_cm NVARCHAR(20) NULL,
	PRIMARY KEY (product_id)

	);

DROP TABLE olist_products;

SELECT TOP 10 * FROM olist_products; 

--- Criando novas colunas para substituir o NVARCHAR por INT na tabela olist_order_items ---

ALTER TABLE olist_order_items ADD price_new DECIMAL(10,2) NULL;
ALTER TABLE olist_order_items ADD freight_new DECIMAL(10,2) NULL;

--- Atualizando as novas colunas convertendo o texto padrão americano (ponto) para decimal

UPDATE olist_order_items 
SET
	price_new = TRY_PARSE(price AS DECIMAL(10,2) USING 'en-US'),
	freight_new = TRY_PARSE(freight_value AS DECIMAL(10,2) USING 'en-US');

--- Testar a tabela para ver as atualizações ---

SELECT TOP 10 price, price_new, freight_value, freight_new
FROM olist_order_items;

--- Apagar as colunas que estão NVARCHAR ---

ALTER TABLE olist_order_items DROP COLUMN price;
ALTER TABLE olist_order_items DROP COLUMN freight_value;

--- Renomear as colunas novas ---

EXEC sp_rename 'olist_order_items.price_new', 'price', 'COLUMN';
EXEC sp_rename 'olist_order_items.freight_new', 'freight_value', 'COLUMN';

SELECT TOP 10 price,freight_value
FROM olist_order_items;

--- Criando novas colunas para substituir o NVARCHAR por INT na tabela olist_products ---

ALTER TABLE olist_products ADD product_name_lenght_new INT NULL;
ALTER TABLE olist_products ADD product_description_lenght_new INT NULL;
ALTER TABLE olist_products ADD product_photos_qty_new INT NULL;
ALTER TABLE olist_products ADD product_weight_g_new INT NULL;

-- Convertendo os dados texto para INT ---

UPDATE olist_products
SET
product_name_lenght_new = TRY_CAST(product_name_lenght AS INT),
product_description_lenght_new = TRY_CAST(product_description_lenght AS INT),
product_photos_qty_new = TRY_CAST(product_photos_qty AS INT),
product_weight_g_new = TRY_CAST(product_weight_g AS INT);

SELECT product_name_lenght_new, product_name_lenght, product_description_lenght_new, product_description_lenght, product_photos_qty_new, product_photos_qty, product_weight_g_new, product_weight_g
FROM olist_products;

--- Apagar as colunas com NVARCHAR ---

ALTER TABLE olist_products DROP COLUMN product_name_lenght;
ALTER TABLE olist_products DROP COLUMN product_description_lenght;
ALTER TABLE olist_products DROP COLUMN product_photos_qty;
ALTER TABLE olist_products DROP COLUMN product_weight_g;

--- Renomear as novas colunas INT ---

EXEC sp_rename 'olist_products.product_name_lenght_new','product_name_lenght', 'COLUMN';
EXEC sp_rename 'olist_products.product_description_lenght_new','product_description_lenght', 'COLUMN';
EXEC sp_rename 'olist_products.product_photos_qty_new','product_photos_qty', 'COLUMN';
EXEC sp_rename 'olist_products.product_weight_g_new','product_weight_g', 'COLUMN';

SELECT product_name_lenght,product_description_lenght,product_photos_qty,product_weight_g
FROM olist_products;

--- INNER JOIN entre as tabelas order_items e products ---

SELECT
	p.product_category_name AS Categorias, 
	SUM(i.price) AS Faturamento_Total
FROM olist_order_items AS i
INNER JOIN olist_products AS p
ON i.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY Faturamento_Total DESC;

--- INNER JOIN 

SELECT
	c.customer_state AS ESTADOS,
	SUM(i.freight_value) AS Frete_Total
FROM olist_order_items AS i
INNER JOIN olist_orders AS o
ON i.order_id = o.order_id
INNER JOIN olist_customers AS c
ON c.customer_id = o.customer_id
GROUP BY c.customer_state
ORDER BY Frete_Total DESC;


SELECT 
	c.customer_state AS ESTADO,
	p.product_category_name AS CATEGORIA,
	SUM(i.price) AS FATURAMENTO
FROM olist_order_items AS i
INNER JOIN olist_orders AS o 
ON
i.order_id = o.order_id
INNER JOIN olist_customers AS c
ON 
c.customer_id = o.customer_id
INNER JOIN olist_products AS p
ON 
p.product_id = i.product_id
WHERE c.customer_state IN ('SP','RJ')
GROUP BY c.customer_state, p.product_category_name
ORDER BY ESTADO, FATURAMENTO DESC; 


--- PROCEDURE Estados filtrados	---

CREATE PROCEDURE RelatorioFaturamentoPorEstado
	@EstadoFiltro VARCHAR(2) 
AS
BEGIN
SELECT 
	c.customer_state AS ESTADO,
	p.product_category_name AS CATEGORIA,
	SUM(i.price) AS FATURAMENTO
FROM olist_order_items AS i
INNER JOIN olist_orders AS o 
ON
i.order_id = o.order_id
INNER JOIN olist_customers AS c
ON 
c.customer_id = o.customer_id
INNER JOIN olist_products AS p
ON 
p.product_id = i.product_id
WHERE c.customer_state = @EstadoFiltro
GROUP BY c.customer_state, p.product_category_name
ORDER BY ESTADO, FATURAMENTO DESC;
END;

EXEC RelatorioFaturamentoPorEstado @EstadoFiltro = 'MG'; 

--- Alterando a PROCEDURE ---

ALTER PROCEDURE RelatorioFaturamentoPorEstado
@EstadoFiltro VARCHAR(2), 
@CategoriaFiltro VARCHAR(100)
AS
BEGIN
SELECT 
	c.customer_state AS ESTADO,
	p.product_category_name AS CATEGORIA,
	SUM(i.price) AS FATURAMENTO
FROM olist_order_items AS i
INNER JOIN olist_orders AS o 
ON
i.order_id = o.order_id
INNER JOIN olist_customers AS c
ON 
c.customer_id = o.customer_id
INNER JOIN olist_products AS p
ON 
p.product_id = i.product_id
WHERE c.customer_state = @EstadoFiltro
AND p.product_category_name = @CategoriaFiltro
GROUP BY c.customer_state, p.product_category_name
ORDER BY ESTADO, FATURAMENTO DESC;
END;

EXEC RelatorioFaturamentoPorEstado @EstadoFiltro = 'BA', @CategoriaFiltro = 'perfumaria';
  

SELECT p.product_category_name AS CATEGORIA,
c.customer_state AS ESTADO,
SUM(i.price) AS FATURAMENTO
FROM olist_order_items AS i
INNER JOIN olist_products AS p
ON o.product_id = p.product_id
INNER JOIN olist_orders AS o
ON o.customer_id = c.customer_id
INNER JOIN olist_orders AS o
ON o.order_id = i.order_id
GROUP BY c.customer_state, product_category_name
ORDER BY ESTADO, CATEGORIA, FATURAMENTO;


SELECT 
    p.product_category_name AS CATEGORIA,
    c.customer_state AS ESTADO,
    -- Usamos o CAST para trazer apenas o primeiro dia do mês, mantendo o faturamento mensal unificado
    CAST(DATEADD(month, DATEDIFF(month, 0, o.order_purchase_timestamp), 0) AS DATE) AS MES_ANO,
    SUM(i.price) AS FATURAMENTO
FROM olist_order_items AS i
INNER JOIN olist_products AS p
    ON i.product_id = p.product_id
INNER JOIN olist_orders AS o
    ON o.order_id = i.order_id
INNER JOIN olist_customers AS c
    ON o.customer_id = c.customer_id
WHERE c.customer_state IN ('SP', 'RJ', 'MG', 'PR')
GROUP BY 
    c.customer_state, 
    p.product_category_name,
    CAST(DATEADD(month, DATEDIFF(month, 0, o.order_purchase_timestamp), 0) AS DATE)
ORDER BY ESTADO, CATEGORIA, FATURAMENTO;
