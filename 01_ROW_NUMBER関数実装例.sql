/* -------------------------------------------------------------------
ファイル名：	ROW_NUMBER関数実装例
動作環境：		SQL Server
機能説明：		ROW_NUMBER関数によりregistration_dateの昇順に連番を設定
				最小registration_dateのbooking単位でidをカウント
---------------------------------------------------------------------- */

WITH target_id
AS
(	-- 対象のidを特定
	SELECT DISTINCT
		a.test_id
	FROM
		SampleTable_A a
		INNER JOIN SampleTable_B b
			ON	a.test_id = b.test_id
	WHERE
		1 = 1
		AND	b.id_condition = '0'
		AND	a.booking_status IN ('Param_A','Param_B')
		AND	a.product_code NOT LIKE 'ZZ%'
		AND	a.product_price >= 1
		AND	a.registration_date BETWEEN yyyymmdd1 AND yyyymmdd2
),
booking_serial_no
AS
(	-- registration_dateの昇順に連番を設定
	SELECT
		a.test_id
		,a.booking
		,a.registration_date
		,ROW_NUMBER() OVER (
			PARTITION BY
				a.test_id
			ORDER BY
				a.registration_date ASC
				,a.booking ASC
		) AS serial_no
	FROM
		SampleTable_A a
		INNER JOIN target_id t
			ON	a.test_id = t.test_id
	WHERE
		1 = 1
		AND	a.booking_status IN ('Param_A','Param_B')
		AND	a.product_code NOT LIKE 'ZZ%'
		AND	a.product_price >= 1
)
-- booking単位にidをカウント
SELECT
	a.booking
	,COUNT(a.test_id) AS id_cnt
FROM
	SampleTable_A a
	INNER JOIN booking_serial_no b
		ON	a.test_id = b.test_id
		AND	a.booking = b.booking
		AND	a.registration_date = b.registration_date
WHERE
	1 = 1
	AND	a.booking_status IN ('Param_A','Param_B')
	AND	a.product_code NOT LIKE 'ZZ%'
	AND	a.product_price >= 1
	AND	a.registration_date >= yyyymmdd3
	AND	b.serial_no = 1
GROUP BY
	a.booking
;