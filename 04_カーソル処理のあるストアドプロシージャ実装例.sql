/* -------------------------------------------------------------------
�t�@�C�����F�J�[�\�������̂���X�g�A�h�v���V�[�W��������
������F	SQL Server
�@�\�����F	SampleTable_A����temp_code���擾
			�J�[�\�������ɂ��Atemp_code�P�ʂɃf�[�^��A���ōX�V
---------------------------------------------------------------------- */

CREATE PROCEDURE SP0020_SampleProc
	@DBErrNum	INT OUTPUT,				-- �G���[�R�[�h�i�o�́j
	@DBErrMsg	NVARCHAR(4000) OUTPUT	-- �G���[���b�Z�[�W�i�o�́j
AS
BEGIN
	DECLARE @TargetCode	TINYINT = 0;	-- �ΏۃR�[�h

	-- �J�[�\����錾
	DECLARE Cur CURSOR
	FOR 
	SELECT DISTINCT
		temp_code
	FROM
		SampleTable_A
	ORDER BY
		temp_code
	;

	-- �J�[�\�����J���āA���R�[�h���t�F�b�`
	OPEN Cur 
	FETCH NEXT FROM Cur INTO @TargetCode;

	BEGIN TRY
		-- �g�����U�N�V�����J�n
		BEGIN TRANSACTION;

		-- temp_code���ƂɍX�V����
		WHILE (@@FETCH_STATUS = 0)
		BEGIN
			-- �ꎞ�e�[�u�����폜
			IF OBJECT_ID(N'tempdb..##target_booking', N'U') IS NOT NULL
			DROP TABLE ##target_booking;

			IF OBJECT_ID(N'tempdb..##first_booking', N'U') IS NOT NULL
			DROP TABLE ##first_booking;

			-- temp_code�������Ƃ����ꎞ�e�[�u�����쐬
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

			-- �ŏ�temp_date�ƂȂ�ꎞ�e�[�u�����쐬
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

			-- �e�[�u���X�V
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

			-- ����temp_code���t�F�b�`
			FETCH NEXT FROM Cur INTO @TargetCode;
		END

		-- �J�[�\�������
		CLOSE Cur;
		DEALLOCATE Cur;

		-- �R�~�b�g
		COMMIT TRANSACTION;
		-- ����I��
		RETURN 0;
	END TRY
	BEGIN CATCH
		-- �X�V����Ă����ꍇ�̓��[���o�b�N
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

		-- �J�[�\�������
		CLOSE Cur;
		DEALLOCATE Cur;

		-- �G���[�擾
		SET @DBErrNum = ERROR_NUMBER();
		SET @DBErrMsg = ERROR_MESSAGE();

		-- �ُ�I��
		RETURN -1;
	END CATCH
END
