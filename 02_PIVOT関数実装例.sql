/* -------------------------------------------------------------------
ファイル名：PIVOT関数実装例
動作環境：	SQL Server
機能説明：	商品マスタから商品種別のリストを作成
			PIVOT関数により商品種別を列に変換し、booking単位に商品種別を集計
---------------------------------------------------------------------- */

-- 変数宣言
DECLARE @ProductList	NVARCHAR(MAX) = '';	-- 商品リスト(カンマ区切り)
DECLARE @Sql			NVARCHAR(MAX) = '';	-- 動的SQL

-- 一時テーブルを削除
IF OBJECT_ID(N'tempdb..##ProductPV', N'U') IS NOT NULL
DROP TABLE ##ProductPV;

-- 商品マスタから商品種別のリストを作成
SELECT
	@ProductList =
		CASE
			WHEN @ProductList = '[' THEN CONVERT(NVARCHAR, product_type) + ']'
			ELSE @ProductList + ', [' + CONVERT(NVARCHAR, product_type) + ']'
		END
FROM
	mst_product
GROUP BY
	product_type
ORDER BY
	product_type
;

-- 動的SQLを作成
SET @Sql = '
	WITH CountQuery
	AS
	(
		SELECT
			booking
			,product_type
			,COUNT(test_id) AS "id_count"
		FROM
			SampleTable_A
		GROUP BY
			booking
			,product_type
	)
	SELECT
		booking
		,' + @ProductList + '
	INTO
		##ProductPV
	FROM
		CountQuery
	PIVOT	-- 商品種別を列に変換
		(
			SUM(id_count)
			FOR product_type IN (' + @ProductList + ')
		) AS PV
	;'
;

-- 動的SQLを実行
EXEC sp_executesql @Sql;

-- booking単位に商品種別を集計
SELECT
	b.booking
	,CASE
		WHEN p.PRODUCT_A IS NULL THEN 0
		ELSE p.PRODUCT_A
	END AS "商品種別A"
	,CASE
		WHEN p.PRODUCT_B IS NULL THEN 0
		ELSE p.PRODUCT_B
	END AS "商品種別B"
	,CASE
		WHEN p.PRODUCT_C IS NULL THEN 0
		ELSE p.PRODUCT_C
	END AS "商品種別C"
	,CASE
		WHEN p.PRODUCT_D IS NULL THEN 0
		ELSE p.PRODUCT_D
	END AS "商品種別D"
	,CASE
		WHEN p.PRODUCT_E IS NULL THEN 0
		ELSE p.PRODUCT_E
	END AS "商品種別E"
FROM
	SampleTable_B b
	LEFT OUTER JOIN ##ProductPV p
		ON	b.booking = p.booking
;