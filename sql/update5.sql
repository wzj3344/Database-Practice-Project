USE [BankDB]
GO

ALTER PROCEDURE sp_user_register
    @uid VARCHAR(20),
    @uname VARCHAR(20),
    @id_card CHAR(18),
    @pwd VARCHAR(20),
    @phone CHAR(11)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- 1. 检查身份证号是否已存在
    IF EXISTS (SELECT 1 FROM bank_user WHERE shen_id = @id_card)
    BEGIN
        -- 使用 THROW 抛出异常，错误码 50001
        THROW 50001, '注册失败：该身份证号已被注册，请检查输入或直接登录。', 1;
    END

    -- 2. 检查用户ID是否已存在
    IF EXISTS (SELECT 1 FROM bank_user WHERE bank_user_id = @uid)
    BEGIN
        -- 使用 THROW 抛出异常，错误码 50002
        THROW 50002, '注册失败：该用户ID已存在，请更换其他ID。', 1;
    END

    BEGIN TRY
        -- 3. 插入新用户
        INSERT INTO bank_user (bank_user_id, shen_id, bank_user_name, passward, phone, reg_time)
        VALUES (@uid, @id_card, @uname, @pwd, @phone, GETDATE());
    END TRY
    BEGIN CATCH
        -- 捕获其他插入错误（如字段截断等）
        THROW; 
    END CATCH
END
GO