/*==============================================================*/
/* 2. 新增：发布基金 (sp_add_fund) - 带完整校验                 */
/*==============================================================*/
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_add_fund')
    DROP PROCEDURE sp_add_fund
GO

CREATE PROCEDURE sp_add_fund
    @fid CHAR(20),
    @fname VARCHAR(20),
    @fworth DECIMAL(10,2),
    @fleast DECIMAL(10,2),
    @frisk INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- 空值校验
    IF LEN(LTRIM(RTRIM(@fid))) = 0 THROW 50020, '基金ID不能为空。', 1;
    IF LEN(LTRIM(RTRIM(@fname))) = 0 THROW 50021, '基金名称不能为空。', 1;

    -- ID重复校验
    IF EXISTS (SELECT 1 FROM fund WHERE fid = @fid) THROW 50022, '基金ID已存在。', 1;

    -- 风险等级校验
    IF @frisk < 1 OR @frisk > 5 THROW 50023, '风险等级必须在 1-5 之间。', 1;

    INSERT INTO fund (fid, fname, fworth, fleast, frisk, fstatus)
    VALUES (@fid, @fname, @fworth, @fleast, @frisk, 1);
END
GO

/*==============================================================*/
/* 3. 新增：更新基金 (sp_update_fund) - 带完整校验              */
/*==============================================================*/
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_update_fund')
    DROP PROCEDURE sp_update_fund
GO

CREATE PROCEDURE sp_update_fund
    @fid CHAR(20),
    @fname VARCHAR(20) = NULL,
    @fstatus INT = NULL,
    @fworth DECIMAL(10,2) = NULL,
    @frisk INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- 空值校验 (针对更新操作)
    IF @fname IS NOT NULL AND LEN(LTRIM(RTRIM(@fname))) = 0
    BEGIN
        THROW 50024, '基金名称不能为空。', 1;
    END

    IF NOT EXISTS (SELECT 1 FROM fund WHERE fid = @fid) THROW 50025, '基金不存在。', 1;

    UPDATE fund
    SET fname = ISNULL(@fname, fname),
        fstatus = ISNULL(@fstatus, fstatus),
        fworth = ISNULL(@fworth, fworth),
        frisk = ISNULL(@frisk, frisk)
    WHERE fid = @fid;
END
GO

/*==============================================================*/
/* 4. 新增：删除基金 (sp_delete_fund)                           */
/*==============================================================*/
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_delete_fund')
    DROP PROCEDURE sp_delete_fund
GO

CREATE PROCEDURE sp_delete_fund
    @fid CHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    -- 检查持仓引用
    IF EXISTS (SELECT 1 FROM with_fund WHERE fid = @fid)
    BEGIN
        THROW 50026, '该基金已有用户持有记录，禁止物理删除！建议下架。', 1;
    END

    DELETE FROM fund WHERE fid = @fid;
END
GO