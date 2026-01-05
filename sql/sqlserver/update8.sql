USE [BankDB]
GO

/*==============================================================*/
/* 修正：理财/基金购买 (按份额购买版)                           */
/* 修改点：                                                     */
/* 1. 参数 @amount 改为 @shares (INT)                           */
/* 2. 逻辑改为：总花费 = 份额 * 净值                            */
/* 3. 校验起购份额 (@least 现在代表份额)                        */
/*==============================================================*/
ALTER PROCEDURE sp_purchase_investment
    @cid CHAR(20),
    @item_id CHAR(20), -- pid or fid
    @shares INT,       -- 修改：购买份额 (整数)
    @type INT          -- 1:理财, 2:基金
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @price DECIMAL(10,2);
    DECLARE @least DECIMAL(10,2); -- 起购份额
    DECLARE @total_cost DECIMAL(18,2); -- 计算出的总花费
    
    DECLARE @ac_status INT;
    DECLARE @ac_type INT;
    DECLARE @cur_bal DECIMAL(18,2);

    -- 1. 检查账户信息
    SELECT 
        @ac_status = astatus,
        @ac_type = atype,
        @cur_bal = cur_balance
    FROM account WHERE cid = @cid;

    IF @ac_status IS NULL THROW 50001, '购买失败：付款账户不存在。', 1;
    IF @ac_status <> 1 THROW 50002, '购买失败：账户处于异常状态（挂失或冻结），禁止交易。', 1;
    IF @ac_type <> 1 THROW 50003, '购买失败：仅支持使用储蓄卡购买理财/基金。', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 2. 获取产品信息 (净值 & 起购份额)
        IF @type = 1 -- 理财
        BEGIN
            SELECT @price = pworth, @least = pleast FROM financial_product WHERE pid = @item_id;
            IF @price IS NULL THROW 50005, '理财产品不存在或已下架', 1;
            
            IF EXISTS(SELECT 1 FROM financial_product WHERE pid = @item_id AND pstatus <> 1)
                 THROW 50006, '该理财产品已停售。', 1;
        END
        ELSE -- 基金
        BEGIN
            SELECT @price = fworth, @least = fleast FROM fund WHERE fid = @item_id;
            IF @price IS NULL THROW 50007, '基金产品不存在或已下架', 1;
            
            IF EXISTS(SELECT 1 FROM fund WHERE fid = @item_id AND fstatus <> 1)
                 THROW 50008, '该基金已停止申购。', 1;
        END

        -- 3. 校验起购份额
        IF @shares < @least
        BEGIN
            DECLARE @msg NVARCHAR(100) = '购买份额低于起购门槛 (最低 ' + CAST(CAST(@least AS INT) AS NVARCHAR(20)) + ' 份)';
            THROW 50009, @msg, 1;
        END

        -- 4. 计算总花费
        SET @total_cost = @shares * @price;

        -- 5. 校验余额 (此时才校验，因为要先算出总价)
        IF @cur_bal < @total_cost
        BEGIN
            DECLARE @msg2 NVARCHAR(200);
			SET @msg2 = N'购买失败：账户余额不足以支付 (需 ￥'
						+ CAST(@total_cost AS NVARCHAR(20)) + N')。';
			THROW 50004, @msg2, 1;
        END

        -- 6. 执行扣款
        UPDATE account SET cur_balance = cur_balance - @total_cost WHERE cid = @cid;

        -- 7. 更新或插入持仓记录
        -- 注意：with_product/with_fund 表结构中 pnumber/fnumber 本身支持小数，存整数没问题
        IF @type = 1 -- 理财
        BEGIN
            IF EXISTS (SELECT 1 FROM with_product WHERE cid = @cid AND pid = @item_id)
                UPDATE with_product 
                SET pnumber = pnumber + @shares, buy_pspend = buy_pspend + @total_cost 
                WHERE cid = @cid AND pid = @item_id;
            ELSE
                INSERT INTO with_product (cid, pid, pnumber, ptime, buy_pspend, sold_pget)
                VALUES (@cid, @item_id, @shares, GETDATE(), @total_cost, 0.00);
        END
        ELSE -- 基金
        BEGIN
            IF EXISTS (SELECT 1 FROM with_fund WHERE cid = @cid AND fid = @item_id)
                UPDATE with_fund 
                SET fnumber = fnumber + @shares, buy_fspend = buy_fspend + @total_cost 
                WHERE cid = @cid AND fid = @item_id;
            ELSE
                INSERT INTO with_fund (cid, fid, fnumber, ftime, buy_fspend, sold_fget)
                VALUES (@cid, @item_id, @shares, GETDATE(), @total_cost, 0.00);
        END

        COMMIT TRANSACTION;
        SELECT 'SUCCESS' as status, '申购成功！' as msg;

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

USE [BankDB]
GO

/*==============================================================*/
/* 修正：定期存款办理 (sp_create_deposit)                       */
/* 修改点：                                                     */
/* 1. 增加账户状态校验 (冻结/挂失禁止操作)                      */
/* 2. 增加账户类型校验 (仅储蓄卡)                               */
/* 3. 显式校验余额                                              */
/* 4. 调整参数顺序适配后端                                      */
/*==============================================================*/
ALTER PROCEDURE sp_create_deposit
    @cid CHAR(20),
    @money DECIMAL(18,2),
    @months INT,           -- 存款月数
    @rate DECIMAL(5,4)     -- 利率
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @did CHAR(20);
    DECLARE @ac_status INT;
    DECLARE @ac_type INT;
    DECLARE @cur_bal DECIMAL(18,2);

    -- 1. 检查账户信息
    SELECT 
        @ac_status = astatus,
        @ac_type = atype,
        @cur_bal = cur_balance
    FROM account WHERE cid = @cid;

    -- 2. 基础校验
    IF @ac_status IS NULL THROW 50001, '办理失败：账户不存在。', 1;
    IF @ac_status <> 1 THROW 50002, '办理失败：账户处于异常状态（挂失或冻结）。', 1;
    IF @ac_type <> 1 THROW 50003, '办理失败：仅支持储蓄卡办理定期存款。', 1;
    
    -- 3. 余额校验
    IF @cur_bal < @money
    BEGIN
        THROW 50004, '办理失败：账户余额不足。', 1;
    END

    -- 生成存单号 (DEP + 时间 + 随机数)
    SET @did = 'DEP' + REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR, GETDATE(), 120), '-', ''), ' ', ''), ':', '') + CAST(FLOOR(RAND() * 99) AS VARCHAR(2));

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 4. 扣除活期余额
        UPDATE account SET cur_balance = cur_balance - @money WHERE cid = @cid;

        -- 5. 插入存单记录
        INSERT INTO deposit (did, cid, dnumber, drate, dstart, dover)
        VALUES (@did, @cid, @money, @rate, GETDATE(), DATEADD(MONTH, @months, GETDATE()));

        COMMIT TRANSACTION;
        SELECT 'SUCCESS' as status, '存款办理成功' as msg, @did as deposit_id;

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO