/* -------------------------------------------------------------------
ファイル名：カーソル処理のあるストアドプロシージャ実装例
動作環境：	SQL Server
機能説明：	SampleTable_Aからtemp_codeを取得
			カーソル処理により、temp_code単位にデータを連続で更新
---------------------------------------------------------------------- */

CREATE PROCEDURE SP0020_SampleProc
	@DBErrNum	INT OUTPUT,				-- エラーコード（出力）
	@DBErrMsg	NVARCHAR(4000) OUTPUT	-- エラーメッセージ（出力）
AS
BEGIN
	DECLARE @TargetCode	TINYINT = 0;	-- 対象コード

	-- カーソルを宣言
	DECLARE Cur CURSOR
	FOR 
	SELECT DISTINCT
		temp_code
	FROM
		SampleTable_A
	ORDER BY
		temp_code
	;

	-- カーソルを開いて、レコードをフェッチ
	OPEN Cur 
	FETCH NEXT FROM Cur INTO @TargetCode;

	BEGIN TRY
		-- トランザクション開始
		BEGIN TRANSACTION;

		-- temp_codeごとに更新処理
		WHILE (@@FETCH_STATUS = 0)
		BEGIN
			-- 一時テーブルを削除
			IF OBJECT_ID(N'tempdb..##target_booking', N'U') IS NOT NULL
			DROP TABLE ##target_booking;

			IF OBJECT_ID(N'tempdb..##first_booking', N'U') IS NOT NULL
			DROP TABLE ##first_booking;

			-- temp_codeを条件とした一時テーブルを作成
			SELECT
				test_id
				,booking
				,temp_date
			INTO
				##target_booking
			FROM
				SampleTable_A
			WHERE
				1 = 1
				AND temp_code = @TargetCode
			;

			-- 最小temp_dateとなる一時テーブルを作成
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
					) AS "serial_no"
				FROM
					##target_booking
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
			;

			-- テーブル更新
			UPDATE
				s 
			SET
				s.first_flg = 1 
			FROM
				SampleTable_A s
				INNER JOIN ##first_booking f
					ON	s.test_id = f.test_id
					AND	s.booking = f.booking
					AND	s.temp_date = f.temp_date
			;

			-- 次のtemp_codeをフェッチ
			FETCH NEXT FROM Cur INTO @TargetCode;
		END

		-- カーソルを閉じる
		CLOSE Cur;
		DEALLOCATE Cur;

		-- コミット
		COMMIT TRANSACTION;
		-- 正常終了
		RETURN 0;
	END TRY
	BEGIN CATCH
		-- 更新されていた場合はロールバック
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

		-- カーソルを閉じる
		CLOSE Cur;
		DEALLOCATE Cur;

		-- エラー取得
		SET @DBErrNum = ERROR_NUMBER();
		SET @DBErrMsg = ERROR_MESSAGE();

		-- 異常終了
		RETURN -1;
	END CATCH
END
