USE [BankDB]
GO

/*==============================================================*/
/* 新增：理财/基金卖出 (sp_sell_investment)                     */
/* 逻辑：                                                       */
/* 1. 检查持有份额是否充足                                      */
/* 2. 计算卖出所得 = 份额 * 当前净值                            */
/* 3. 账户余额增加                                              */
/* 4. 减少持有份额 (自动触发 trg 更新收益统计)                  */
/*==============================================================*/
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_sell_investment')
    DROP PROCEDURE sp_sell_investment
GO

CREATE PROCEDURE sp_sell_investment
    @cid CHAR(20),
    @item_id CHAR(20), -- pid or fid
    @shares INT,       -- 卖出份额
    @type INT          -- 1:理财, 2:基金
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @price DECIMAL(10,2);
    DECLARE @holding INT; -- 当前持有份额
    DECLARE @total_get DECIMAL(18,2); -- 卖出所得金额
    
    -- 1. 检查账户状态
    IF NOT EXISTS (SELECT 1 FROM account WHERE cid = @cid AND astatus = 1)
    BEGIN
        THROW 50050, '卖出失败：账户不存在或处于非正常状态。', 1;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 2. 获取行情与持仓信息
        IF @type = 1 -- 理财
        BEGIN
            -- 获取当前净值
            SELECT @price = pworth FROM financial_product WHERE pid = @item_id;
            IF @price IS NULL THROW 50051, '理财产品不存在。', 1;

            -- 获取当前持仓
            SELECT @holding = pnumber FROM with_product WHERE cid = @cid AND pid = @item_id;
        END
        ELSE -- 基金
        BEGIN
            SELECT @price = fworth FROM fund WHERE fid = @item_id;
            IF @price IS NULL THROW 50052, '基金产品不存在。', 1;

            SELECT @holding = fnumber FROM with_fund WHERE cid = @cid AND fid = @item_id;
        END

        -- 3. 份额校验
        IF @holding IS NULL OR @holding < @shares
        BEGIN
            DECLARE @err NVARCHAR(100) = '卖出失败：持有份额不足 (当前持有 ' + ISNULL(CAST(@holding AS NVARCHAR(20)), '0') + ' 份)';
            THROW 50053, @err, 1;
        END

        -- 4. 计算所得资金
        SET @total_get = @shares * @price;

        -- 5. 资金入账
        UPDATE account SET cur_balance = cur_balance + @total_get WHERE cid = @cid;

        -- 6. 扣减份额
        -- 注意：这里减少份额会触发 trg_update_product_profit / trg_update_fund_profit
        -- 触发器会自动计算：(旧份额 - 新份额) * 净值，并加到 sold_pget 字段中
        IF @type = 1
        BEGIN
            UPDATE with_product SET pnumber = pnumber - @shares WHERE cid = @cid AND pid = @item_id;
            
            -- 可选：如果份额为0，是否删除记录？
            -- 建议保留记录以便查看历史收益 (sold_pget)，或者您可以选择定期清理
            -- 这里我们保留记录，只是 pnumber 变为 0
        END
        ELSE
        BEGIN
            UPDATE with_fund SET fnumber = fnumber - @shares WHERE cid = @cid AND fid = @item_id;
        END

        COMMIT TRANSACTION;
        SELECT 'SUCCESS' as status, '卖出成功！资金已入账。' as msg;

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO