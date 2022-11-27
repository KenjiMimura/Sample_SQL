/* -------------------------------------------------------------------
ファイル名：引数を受け取るストアドプロシージャ実装例
動作環境：	SQL Server
機能説明：	引数で入力された値を条件として、SQLを作成
			作成したSQLにより、データを更新
---------------------------------------------------------------------- */

CREATE PROCEDURE SP0010_SampleProc
	@TargetDate	INT,					-- 対象日（入力）
	@ProcFlg	TINYINT,				-- 処理フラグ（入力）
	@DBErrNum	INT OUTPUT,				-- エラーコード（出力）
	@DBErrMsg	NVARCHAR(4000) OUTPUT	-- エラーメッセージ（出力）
AS
BEGIN
	-- 変数宣言
	DECLARE @Sql	NVARCHAR(MAX) = '';	-- SQL文
	DECLARE @Param	NVARCHAR(MAX) = '';	-- パラメータ
	DECLARE @Col	NVARCHAR(20) = '';	-- 対象カラム
	DECLARE @Where	NVARCHAR(20) = '';	-- Where条件

	-- 変数定義
	IF @ProcFlg = 1
		BEGIN
			SET @Col = 's.flg_a';
			SET @Where = '''01''';
		END
	ELSE IF @ProcFlg = 2
		BEGIN
			SET @Col = 's.flg_b';
			SET @Where = '''99''';
		END

	-- 一時テーブルを削除
	IF OBJECT_ID(N'tempdb..##first_booking', N'U') IS NOT NULL
	DROP TABLE ##first_booking;

	BEGIN TRY
		-- SQL作成
		SET @Sql = N'
			WITH booking_serial_no
			AS
			(
				SELECT
					test_id
					,booking
					,temp_date
					,ROW_NUMBER() OVER (
						PARTITION BY
							test_id
						ORDER BY
							temp_date ASC
							,booking ASC
					) AS serial_no
				FROM
					SampleTable_A
				WHERE
					1 = 1
					AND	condition = ' + @Where + ' 
			)
			SELECT
				test_id
				,booking
				,temp_date
			INTO
				##first_booking
			FROM
				booking_serial_no
			WHERE
				1 = 1
				AND serial_no = 1
				AND temp_date >= @TargetDate
			;'
		;

		-- パラメータ作成
		SET @Param = N'@Where NVARCHAR(20), @TargetDate INT';

		-- SQL実行（一時テーブル作成）
		EXECUTE sp_executesql @Sql, @Param, @Where, @TargetDate;

		-- SQL作成
		SET @Sql = N'
			UPDATE
				s
			SET
				' + @Col + ' = 1
			FROM
				SampleTable_B s
				INNER JOIN ##first_booking t
					ON	s.test_id = t.test_id
					AND	s.booking = t.booking
					AND	s.temp_date = t.temp_date
			;'
		;

		-- パラメータ作成
		SET @Param = N'@Col NVARCHAR(20)';

		-- トランザクション開始
		BEGIN TRANSACTION;

		-- SQL実行（データ更新）
		EXECUTE sp_executesql @Sql, @Param, @Col;
		
		-- コミット
		COMMIT TRANSACTION;
		-- 正常終了
		RETURN 0;
	END TRY
	BEGIN CATCH
		-- 更新されていた場合はロールバック
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

		-- エラー取得
		SET @DBErrNum = ERROR_NUMBER();
		SET @DBErrMsg = ERROR_MESSAGE();

		-- 異常終了
		RETURN -1;
	END CATCH
END
