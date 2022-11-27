/* -------------------------------------------------------------------
�t�@�C�����FPIVOT�֐�������
������F	SQL Server
�@�\�����F	���i�}�X�^���珤�i��ʂ̃��X�g���쐬
			PIVOT�֐��ɂ�菤�i��ʂ��ɕϊ����Abooking�P�ʂɏ��i��ʂ��W�v
---------------------------------------------------------------------- */

-- �ϐ��錾
DECLARE @ProductList	NVARCHAR(MAX) = '';	-- ���i���X�g(�J���}��؂�)
DECLARE @Sql			NVARCHAR(MAX) = '';	-- ���ISQL

-- �ꎞ�e�[�u�����폜
IF OBJECT_ID(N'tempdb..##ProductPV', N'U') IS NOT NULL
DROP TABLE ##ProductPV;

-- ���i�}�X�^���珤�i��ʂ̃��X�g���쐬
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

-- ���ISQL���쐬
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
	PIVOT	-- ���i��ʂ��ɕϊ�
		(
			SUM(id_count)
			FOR product_type IN (' + @ProductList + ')
		) AS PV
	;'
;

-- ���ISQL�����s
EXEC sp_executesql @Sql;

-- booking�P�ʂɏ��i��ʂ��W�v
SELECT
	b.booking
	,CASE
		WHEN p.PRODUCT_A IS NULL THEN 0
		ELSE p.PRODUCT_A
	END AS "���i���A"
	,CASE
		WHEN p.PRODUCT_B IS NULL THEN 0
		ELSE p.PRODUCT_B
	END AS "���i���B"
	,CASE
		WHEN p.PRODUCT_C IS NULL THEN 0
		ELSE p.PRODUCT_C
	END AS "���i���C"
	,CASE
		WHEN p.PRODUCT_D IS NULL THEN 0
		ELSE p.PRODUCT_D
	END AS "���i���D"
	,CASE
		WHEN p.PRODUCT_E IS NULL THEN 0
		ELSE p.PRODUCT_E
	END AS "���i���E"
FROM
	SampleTable_B b
	LEFT OUTER JOIN ##ProductPV p
		ON	b.booking = p.booking
;