/* -------------------------------------------------------------------
�t�@�C�����F�������󂯎��X�g�A�h�v���V�[�W��������
������F	SQL Server
�@�\�����F	�����œ��͂��ꂽ�l�������Ƃ��āASQL���쐬
			�쐬����SQL�ɂ��A�f�[�^���X�V
---------------------------------------------------------------------- */

CREATE PROCEDURE SP0010_SampleProc
	@TargetDate	INT,					-- �Ώۓ��i���́j
	@ProcFlg	TINYINT,				-- �����t���O�i���́j
	@DBErrNum	INT OUTPUT,				-- �G���[�R�[�h�i�o�́j
	@DBErrMsg	NVARCHAR(4000) OUTPUT	-- �G���[���b�Z�[�W�i�o�́j
AS
BEGIN
	-- �ϐ��錾
	DECLARE @Sql	NVARCHAR(MAX) = '';	-- SQL��
	DECLARE @Param	NVARCHAR(MAX) = '';	-- �p�����[�^
	DECLARE @Col	NVARCHAR(20) = '';	-- �ΏۃJ����
	DECLARE @Where	NVARCHAR(20) = '';	-- Where����

	-- �ϐ���`
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

	-- �ꎞ�e�[�u�����폜
	IF OBJECT_ID(N'tempdb..##first_booking', N'U') IS NOT NULL
	DROP TABLE ##first_booking;

	BEGIN TRY
		-- SQL�쐬
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

		-- �p�����[�^�쐬
		SET @Param = N'@Where NVARCHAR(20), @TargetDate INT';

		-- SQL���s�i�ꎞ�e�[�u���쐬�j
		EXECUTE sp_executesql @Sql, @Param, @Where, @TargetDate;

		-- SQL�쐬
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

		-- �p�����[�^�쐬
		SET @Param = N'@Col NVARCHAR(20)';

		-- �g�����U�N�V�����J�n
		BEGIN TRANSACTION;

		-- SQL���s�i�f�[�^�X�V�j
		EXECUTE sp_executesql @Sql, @Param, @Col;
		
		-- �R�~�b�g
		COMMIT TRANSACTION;
		-- ����I��
		RETURN 0;
	END TRY
	BEGIN CATCH
		-- �X�V����Ă����ꍇ�̓��[���o�b�N
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

		-- �G���[�擾
		SET @DBErrNum = ERROR_NUMBER();
		SET @DBErrMsg = ERROR_MESSAGE();

		-- �ُ�I��
		RETURN -1;
	END CATCH
END
