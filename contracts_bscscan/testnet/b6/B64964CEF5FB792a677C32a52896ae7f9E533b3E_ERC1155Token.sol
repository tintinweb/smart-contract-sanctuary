pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: GPL-3.0-only



import "./lib/SafeUInt128.sol";
import "./lib/SafeInt256.sol";
import "./lib/ABDKMath64x64.sol";
import "./lib/SafeMath.sol";

import "./utils/Governed.sol";
import "./utils/Common.sol";

import "@openzeppelin/contracts/utils/SafeCast.sol";

/**
 * @title CashMarket
 * @notice Marketplace for trading cash to fCash tokens. Implements a specialized AMM for trading such assets.
 */
contract CashMarket is Governed {
    using SafeUInt128 for uint128;
    using SafeMath for uint256;
    using SafeInt256 for int256;

    // This is used in _tradeCalculation to shift the ln calculation
    int128 internal constant PRECISION_64x64 = 0x3b9aca000000000000000000;
    uint256 internal constant MAX64 = 0x7FFFFFFFFFFFFFFF;
    int64 internal constant LN_1E18 = 0x09a667e259;
    bool internal constant CHECK_FC = true;
    bool internal constant DEFER_CHECK = false;

    /**
     * @dev skip
     */
    function initializeDependencies() external {
        // Setting dependencies can only be done once here. With proxy contracts the addresses shouldn't
        // change as we upgrade the logic.
        Governed.CoreContracts[] memory dependencies = new Governed.CoreContracts[](3);
        dependencies[0] = CoreContracts.Escrow;
        dependencies[1] = CoreContracts.Portfolios;
        dependencies[2] = CoreContracts.ERC1155Trade;
        _setDependencies(dependencies);
    }

    // Defines the fields for each market in each maturity.
    struct Market {
        // Total amount of fCash available for purchase in the market.
        uint128 totalfCash;
        // Total amount of liquidity tokens (representing a claim on liquidity) in the market.
        uint128 totalLiquidity;
        // Total amount of cash available for purchase in the market.
        uint128 totalCurrentCash;
        // These factors are set when the market is instantiated by a liquidity provider via the global
        // settings and then held constant for the duration of the maturity. We cannot change them without
        // really messing up the market rates.
        uint16 rateScalar;
        uint32 rateAnchor;
        // This is the implied rate that we use to smooth the anchor rate between trades.
        uint32 lastImpliedRate;
    }

    // This is a mapping between a maturity and its corresponding market.
    mapping(uint32 => Market) public markets;

    /********** Governance Parameters *********************/

    // These next parameters are set by the Portfolios contract and are immutable, except for G_NUM_MATURITIES
    uint8 public CASH_GROUP;
    uint32 internal constant INSTRUMENT_PRECISION = 1e9;
    uint32 public G_MATURITY_LENGTH;
    uint32 public G_NUM_MATURITIES;

    // These are governance parameters for the market itself and can be set by the owner.

    // The maximum trade size denominated in local currency
    uint128 public G_MAX_TRADE_SIZE;

    // The y-axis shift of the rate curve
    uint32 public G_RATE_ANCHOR;
    // The slope of the rate curve
    uint16 public G_RATE_SCALAR;
    // The fee in basis points given to liquidity providers
    uint32 public G_LIQUIDITY_FEE;
    // The fee as a percentage of the cash traded given to the protocol
    uint128 public G_TRANSACTION_FEE;

    /**
     * @notice Sets governance parameters on the rate oracle.
     * @dev skip
     * @param cashGroupId this cannot change once set
     * @param precision will only take effect on a new maturity
     * @param maturityLength will take effect immediately, must be careful
     * @param numMaturities will take effect immediately, makers can create new markets
     */
    function setParameters(
        uint8 cashGroupId,
        uint16, /* instrumentId */
        uint32 precision,
        uint32 maturityLength,
        uint32 numMaturities,
        uint32 /* maxRate */
    ) external {
        require(calledByPortfolios(), "20");

        // These values cannot be reset once set.
        if (CASH_GROUP == 0) {
            CASH_GROUP = cashGroupId;
        }

        require(precision == 1e9, "51");
        G_MATURITY_LENGTH = maturityLength;
        G_NUM_MATURITIES = numMaturities;
    }

    /**
     * @notice Sets rate factors that will determine the liquidity curve. Rate Anchor is set as the target annualized exchange
     * rate so 1.10 * INSTRUMENT_PRECISION represents a target annualized rate of 10%. Rate anchor will be scaled accordingly
     * when a fCash market is initialized. As a general default, INSTRUMENT_PRECISION will be set to 1e9.
     * @dev governance
     * @param rateAnchor the offset of the liquidity curve
     * @param rateScalar the sensitivity of the liquidity curve to changes
     */
    function setRateFactors(uint32 rateAnchor, uint16 rateScalar) external onlyOwner {
        require(rateScalar > 0 && rateAnchor > 0, "14");
        G_RATE_SCALAR = rateScalar;
        G_RATE_ANCHOR = rateAnchor;

        emit UpdateRateFactors(rateAnchor, rateScalar);
    }

    /**
     * @notice Sets the maximum amount that can be traded in a single trade.
     * @dev governance
     * @param amount the max trade size
     */
    function setMaxTradeSize(uint128 amount) external onlyOwner {
        G_MAX_TRADE_SIZE = amount;

        emit UpdateMaxTradeSize(amount);
    }

    /**
     * @notice Sets fee parameters for the market. Liquidity Fees are set as basis points and shift the traded
     * exchange rate. A basis point is the equivalent of 1e5 if INSTRUMENT_PRECISION is set to 1e9.
     * Transaction fees are set as a percentage shifted by 1e18. For example a 1% transaction fee will be set
     * as 1.01e18.
     * @dev governance
     * @param liquidityFee a change in the traded exchange rate paid to liquidity providers
     * @param transactionFee percentage of a transaction that accrues to the reserve account
     */
    function setFee(uint32 liquidityFee, uint128 transactionFee) external onlyOwner {
        G_LIQUIDITY_FEE = liquidityFee;
        G_TRANSACTION_FEE = transactionFee;

        emit UpdateFees(liquidityFee, transactionFee);
    }

    /********** Governance Parameters *********************/

    /********** Events ************************************/
    /**
     * @notice Emitted when rate factors are updated, will take effect at the next maturity
     * @param rateAnchor the new rate anchor
     * @param rateScalar the new rate scalar
     */
    event UpdateRateFactors(uint32 rateAnchor, uint16 rateScalar);

    /**
     * @notice Emitted when max trade size is updated, takes effect immediately
     * @param maxTradeSize the new max trade size
     */
    event UpdateMaxTradeSize(uint128 maxTradeSize);

    /**
     * @notice Emitted when fees are updated, takes effect immediately
     * @param liquidityFee the new liquidity fee
     * @param transactionFee the new transaction fee
     */
    event UpdateFees(uint32 liquidityFee, uint128 transactionFee);

    /**
     * @notice Emitted when liquidity is added to a maturity
     * @param account the account that performed the trade
     * @param maturity the maturity that this trade affects
     * @param tokens amount of liquidity tokens issued
     * @param fCash amount of fCash tokens added
     * @param cash amount of cash tokens added
     */
    event AddLiquidity(address indexed account, uint32 maturity, uint128 tokens, uint128 fCash, uint128 cash);

    /**
     * @notice Emitted when liquidity is removed from a maturity
     * @param account the account that performed the trade
     * @param maturity the maturity that this trade affects
     * @param tokens amount of liquidity tokens burned
     * @param fCash amount of fCash tokens removed
     * @param cash amount of cash tokens removed
     */
    event RemoveLiquidity(address indexed account, uint32 maturity, uint128 tokens, uint128 fCash, uint128 cash);

    /**
     * @notice Emitted when cash is taken from a maturity
     * @param account the account that performed the trade
     * @param maturity the maturity that this trade affects
     * @param fCash amount of fCash tokens added
     * @param cash amount of cash tokens removed
     * @param fee amount of transaction fee charged
     */
    event TakeCurrentCash(address indexed account, uint32 maturity, uint128 fCash, uint128 cash, uint128 fee);

    /**
     * @notice Emitted when fCash is taken from a maturity
     * @param account the account that performed the trade
     * @param maturity the maturity that this trade affects
     * @param fCash amount of fCash tokens removed
     * @param cash amount of cash tokens added
     * @param fee amount of transaction fee charged
     */
    event TakefCash(address indexed account, uint32 maturity, uint128 fCash, uint128 cash, uint128 fee);

    /********** Events ************************************/

    /********** Liquidity Tokens **************************/

    /**
     * @notice Adds some amount of cash to the liquidity pool up to the corresponding amount defined by
     * `maxfCash`. Mints liquidity tokens back to the sender.
     * @dev - TRADE_FAILED_MAX_TIME: maturity specified is not yet active
     * - MARKET_INACTIVE: maturity is not a valid one
     * - OVER_MAX_FCASH: fCash amount required exceeds supplied maxfCash
     * - OUT_OF_IMPLIED_RATE_BOUNDS: depositing cash would require more fCash than specified
     * - INSUFFICIENT_BALANCE: insufficient cash to deposit into market
     * @param maturity the maturity to add liquidity to
     * @param cash the amount of cash to add to the pool
     * @param maxfCash the max amount of fCash to add to the pool. When initializing a pool this is the
     * amount of fCash that will be added.
     * @param minImpliedRate the minimum implied rate that we will add liquidity at
     * @param maxImpliedRate the maximum implied rate that we will add liquidity at
     * @param maxTime after this time the trade will fail
     */
    function addLiquidity(
        uint32 maturity,
        uint128 cash,
        uint128 maxfCash,
        uint32 minImpliedRate,
        uint32 maxImpliedRate,
        uint32 maxTime
    ) external {
        Common.Asset[] memory assets = _addLiquidity(
            msg.sender,
            maturity,
            cash,
            maxfCash,
            minImpliedRate,
            maxImpliedRate,
            maxTime
        );

        // This will do a free collateral check before it adds to the portfolio.
        Portfolios().upsertAccountAssetBatch(msg.sender, assets, CHECK_FC);
    }

    /**
     * @notice Used by ERC1155 contract to add liquidity
     * @dev skip
     */
    function addLiquidityOnBehalf(
        address account,
        uint32 maturity,
        uint128 cash,
        uint128 maxfCash,
        uint32 minImpliedRate,
        uint32 maxImpliedRate
    ) external {
        require(calledByERC1155Trade(), "20");

        Common.Asset[] memory assets = _addLiquidity(
            account,
            maturity,
            cash,
            maxfCash,
            minImpliedRate,
            maxImpliedRate,
            uint32(block.timestamp)
        );

        Portfolios().upsertAccountAssetBatch(account, assets, DEFER_CHECK);
    }

    function _addLiquidity(
        address account,
        uint32 maturity,
        uint128 cash,
        uint128 maxfCash,
        uint32 minImpliedRate,
        uint32 maxImpliedRate,
        uint32 maxTime
    ) internal returns (Common.Asset[] memory) {
        _isValidBlock(maturity, maxTime);
        uint32 timeToMaturity = maturity - uint32(block.timestamp);
        Market memory market = markets[maturity];

        uint128 fCash;
        uint128 liquidityTokenAmount;
        if (market.totalLiquidity == 0) {
            // We check the rateScalar to determine if the market exists or not. The reason for this is that once we
            // initialize a market we will set the rateScalar and rateAnchor based on global values for the duration
            // of the market. The proportion of fCash to cash that the first liquidity provider sets here will
            // determine the initial exchange rate of the market (taking into account rateScalar and rateAnchor, of course).
            // Governance will never allow rateScalar to be set to 0.
            if (market.rateScalar == 0) {
                market.rateScalar = G_RATE_SCALAR;
            }

            // G_RATE_ANCHOR is stored as the annualized rate. Here we normalize it to the rate that is required given the
            // time to maturity. (RATE_ANCHOR - 1) * timeToMaturity / SECONDS_IN_YEAR + 1
            market.rateAnchor = SafeCast.toUint32(
                uint256(G_RATE_ANCHOR).sub(INSTRUMENT_PRECISION).mul(timeToMaturity).div(Common.SECONDS_IN_YEAR).add(
                    INSTRUMENT_PRECISION
                )
            );

            market.totalfCash = maxfCash;
            market.totalCurrentCash = cash;
            market.totalLiquidity = cash;
            // We have to initialize this to the exchange rate implied by the proportion of cash to fCash.
            uint32 impliedRate = _getImpliedRateRequire(market, timeToMaturity);
            require(
                minImpliedRate <= maxImpliedRate && minImpliedRate <= impliedRate && impliedRate <= maxImpliedRate,
                "31"
            );
            market.lastImpliedRate = impliedRate;

            liquidityTokenAmount = cash;
            fCash = maxfCash;
        } else {
            // We calculate the amount of liquidity tokens to mint based on the share of the fCash
            // that the liquidity provider is depositing.
            liquidityTokenAmount = SafeCast.toUint128(
                uint256(market.totalLiquidity).mul(cash).div(market.totalCurrentCash)
            );

            // We use the prevailing proportion to calculate the required amount of current cash to deposit.
            fCash = SafeCast.toUint128(uint256(market.totalfCash).mul(cash).div(market.totalCurrentCash));
            require(fCash <= maxfCash, "43");

            // Add the fCash and cash to the pool.
            market.totalfCash = market.totalfCash.add(fCash);
            market.totalCurrentCash = market.totalCurrentCash.add(cash);
            market.totalLiquidity = market.totalLiquidity.add(liquidityTokenAmount);

            // If this proportion has moved beyond what the liquidity provider is willing to pay then we
            // will revert here. The implied rate will not change when liquidity is added.
            require(
                minImpliedRate <= maxImpliedRate &&
                    minImpliedRate <= market.lastImpliedRate &&
                    market.lastImpliedRate <= maxImpliedRate,
                "31"
            );
        }

        markets[maturity] = market;

        // Move the cash into the contract's cash balances account. This must happen before the trade
        // is placed so that the free collateral check is correct.
        Escrow().depositIntoMarket(account, CASH_GROUP, cash, 0);

        // Providing liquidity results in two tokens generated, a liquidity token and a CASH_PAYER which
        // represents the obligation that offsets the fCash in the market.
        Common.Asset[] memory assets = new Common.Asset[](2);
        // This is the liquidity token
        assets[0] = Common.Asset(CASH_GROUP, 0, maturity, Common.getLiquidityToken(), 0, liquidityTokenAmount);

        // This is the CASH_PAYER
        assets[1] = Common.Asset(CASH_GROUP, 0, maturity, Common.getCashPayer(), 0, fCash);

        emit AddLiquidity(account, maturity, liquidityTokenAmount, fCash, cash);

        return assets;
    }

    /**
     * @notice Removes liquidity from the fCash market. The sender's liquidity tokens are burned and they
     * are credited back with fCash and cash at the prevailing exchange rate. This function
     * only works when removing liquidity from an active market. For markets that are matured, the sender
     * must settle their liquidity token via `Portfolios.settleMaturedAssets`.
     * @dev - TRADE_FAILED_MAX_TIME: maturity specified is not yet active
     * - MARKET_INACTIVE: maturity is not a valid one
     * - INSUFFICIENT_BALANCE: account does not have sufficient tokens to remove
     * @param maturity the maturity to remove liquidity from
     * @param amount the amount of liquidity tokens to burn
     * @param maxTime after this block the trade will fail
     * @return the amount of cash claim the removed liquidity tokens have
     */
    function removeLiquidity(
        uint32 maturity,
        uint128 amount,
        uint32 maxTime
    ) external returns (uint128) {
        (Common.Asset[] memory assets, uint128 cash) = _removeLiquidity(msg.sender, maturity, amount, maxTime);

        // This function call will check if the account in question actually has
        // enough liquidity tokens to remove.
        Portfolios().upsertAccountAssetBatch(msg.sender, assets, CHECK_FC);

        return cash;
    }

    /**
     * @notice Used by ERC1155 contract to remove liquidity
     * @dev skip
     */
    function removeLiquidityOnBehalf(
        address account,
        uint32 maturity,
        uint128 amount
    ) external returns (uint128) {
        require(calledByERC1155Trade(), "20");

        (Common.Asset[] memory assets, uint128 cash) = _removeLiquidity(
            account,
            maturity,
            amount,
            uint32(block.timestamp)
        );

        Portfolios().upsertAccountAssetBatch(account, assets, DEFER_CHECK);

        return cash;
    }

    function _removeLiquidity(
        address account,
        uint32 maturity,
        uint128 amount,
        uint32 maxTime
    ) internal returns (Common.Asset[] memory, uint128) {
        // This method only works when the market is active.
        uint32 blockTime = uint32(block.timestamp);
        require(blockTime <= maxTime, "18");
        require(blockTime < maturity, "3");

        Market memory market = markets[maturity];

        // Here we calculate the amount of current cash that the liquidity token represents.
        uint128 cash = SafeCast.toUint128(uint256(market.totalCurrentCash).mul(amount).div(market.totalLiquidity));
        market.totalCurrentCash = market.totalCurrentCash.sub(cash);

        // This is the amount of fCash that the liquidity token has a claim to.
        uint128 fCashAmount = SafeCast.toUint128(uint256(market.totalfCash).mul(amount).div(market.totalLiquidity));
        market.totalfCash = market.totalfCash.sub(fCashAmount);

        // We do this calculation after the previous two so that we do not mess with the totalLiquidity
        // figure when calculating fCash and cash.
        market.totalLiquidity = market.totalLiquidity.sub(amount);

        markets[maturity] = market;

        // Move the cash from the contract's cash balances account back to the sender. This must happen
        // before the free collateral check in the Portfolio call below.
        Escrow().withdrawFromMarket(account, CASH_GROUP, cash, 0);

        Common.Asset[] memory assets = new Common.Asset[](2);
        // This will remove the liquidity tokens
        assets[0] = Common.Asset(
            CASH_GROUP,
            0,
            maturity,
            // We mark this as a "PAYER" liquidity token so the portfolio reduces the balance
            Common.makeCounterparty(Common.getLiquidityToken()),
            0,
            amount
        );

        // This is the CASH_RECEIVER
        assets[1] = Common.Asset(CASH_GROUP, 0, maturity, Common.getCashReceiver(), 0, fCashAmount);

        emit RemoveLiquidity(account, maturity, amount, fCashAmount, cash);
        return (assets, cash);
    }

    /**
     * @notice Settles a liquidity token into fCash and cash. Can only be called by the Portfolios contract.
     * @dev skip
     * @param account the account that is holding the token
     * @param tokenAmount the amount of token to settle
     * @param maturity when the token matures
     * @return the amount of cash to settle to the account
     */
    function settleLiquidityToken(
        address account,
        uint128 tokenAmount,
        uint32 maturity
    ) external returns (uint128) {
        require(calledByPortfolios(), "20");

        (uint128 cash, uint128 fCash) = _settleLiquidityToken(tokenAmount, maturity);

        // Move the cash from the contract's cash balances account back to the sender
        Escrow().withdrawFromMarket(account, CASH_GROUP, cash, 0);

        // No need to remove the liquidity token from the portfolio, the calling function will take care of this.

        // The liquidity token carries with it an obligation to pay a certain amount of fCash and we credit that
        // amount plus any appreciation here. This amount will be added to the cashBalances for the account to offset
        // the CASH_PAYER token that was created when the liquidity token was minted.
        return fCash;
    }

    /**
     * @notice Internal method for settling liquidity tokens, calculates the values for cash and fCash
     *
     * @param tokenAmount the amount of token to settle
     * @param maturity when the token matures
     * @return the amount of cash and fCash
     */
    function _settleLiquidityToken(uint128 tokenAmount, uint32 maturity) internal returns (uint128, uint128) {
        Market memory market = markets[maturity];

        // Here we calculate the amount of cash that the liquidity token represents.
        uint128 cash = SafeCast.toUint128(uint256(market.totalCurrentCash).mul(tokenAmount).div(market.totalLiquidity));
        market.totalCurrentCash = market.totalCurrentCash.sub(cash);

        // This is the amount of fCash that the liquidity token has a claim to.
        uint128 fCash = SafeCast.toUint128(uint256(market.totalfCash).mul(tokenAmount).div(market.totalLiquidity));
        market.totalfCash = market.totalfCash.sub(fCash);

        // We do this calculation after the previous two so that we do not mess with the totalLiquidity
        // figure when calculating fCash and cash.
        market.totalLiquidity = market.totalLiquidity.sub(tokenAmount);

        markets[maturity] = market;

        return (cash, fCash);
    }

    /********** Liquidity Tokens **************************/

    /********** Trading Cash ******************************/

    /**
     * @notice Given the amount of fCash put into a market, how much cash this would
     * purchase at the current block.
     * @param maturity the maturity of the fCash
     * @param fCashAmount the amount of fCash to input
     * @return the amount of cash this would purchase, returns 0 if the trade will fail
     */
    function getfCashToCurrentCash(uint32 maturity, uint128 fCashAmount) public view returns (uint128) {
        return getfCashToCurrentCashAtTime(maturity, fCashAmount, uint32(block.timestamp));
    }

    /**
     * @notice Given the amount of fCash put into a market, how much cash this would
     * purchase at the given time. fCash exchange rates change as we go towards maturity.
     * @dev - CANNOT_GET_PRICE_FOR_MATURITY: can only get prices before the maturity
     * @param maturity the maturity of the fCash
     * @param fCashAmount the amount of fCash to input
     * @param blockTime the specified block time
     * @return the amount of cash this would purchase, returns 0 if the trade will fail
     */
    function getfCashToCurrentCashAtTime(
        uint32 maturity,
        uint128 fCashAmount,
        uint32 blockTime
    ) public view returns (uint128) {
        Market memory interimMarket = markets[maturity];
        require(blockTime < maturity, "41");

        uint32 timeToMaturity = maturity - blockTime;

        (
            ,
            /* market */
            uint128 cash
        ) = _tradeCalculation(interimMarket, int256(fCashAmount), timeToMaturity);
        // On trade failure, we will simply return 0
        uint128 fee = _calculateTransactionFee(cash, timeToMaturity);
        return cash.sub(fee);
    }

    /**
     * @notice Receive cash in exchange for a fCash obligation. Equivalent to borrowing
     * cash at a fixed rate.
     * @dev - TRADE_FAILED_MAX_TIME: maturity specified is not yet active
     * - MARKET_INACTIVE: maturity is not a valid one
     * - TRADE_FAILED_TOO_LARGE: trade is larger than allowed by the governance settings
     * - TRADE_FAILED_LACK_OF_LIQUIDITY: there is insufficient liquidity in this maturity to handle the trade
     * - TRADE_FAILED_SLIPPAGE: trade is greater than the max implied rate set
     * - INSUFFICIENT_FREE_COLLATERAL: insufficient free collateral to take on the debt
     * @param maturity the maturity of the fCash being exchanged for current cash
     * @param fCashAmount the amount of fCash to sell, will convert this amount to current cash
     *  at the prevailing exchange rate.
     * @param maxTime after this time the trade will not settle
     * @param maxImpliedRate the maximum implied maturity rate that the borrower will accept
     * @return the amount of cash purchased, `fCashAmount - cash` determines the fixed interested owed.
     */
    function takeCurrentCash(
        uint32 maturity,
        uint128 fCashAmount,
        uint32 maxTime,
        uint32 maxImpliedRate
    ) external returns (uint128) {
        (Common.Asset memory asset, uint128 cash) = _takeCurrentCash(
            msg.sender,
            maturity,
            fCashAmount,
            maxTime,
            maxImpliedRate
        );

        // This will do a free collateral check before it adds to the portfolio.
        Portfolios().upsertAccountAsset(msg.sender, asset, CHECK_FC);

        return cash;
    }

    /**
     * @notice Used by ERC1155 contract to take cash
     * @dev skip
     */
    function takeCurrentCashOnBehalf(
        address account,
        uint32 maturity,
        uint128 fCashAmount,
        uint32 maxImpliedRate
    ) external returns (uint128) {
        require(calledByERC1155Trade(), "20");

        (Common.Asset memory asset, uint128 cash) = _takeCurrentCash(
            account,
            maturity,
            fCashAmount,
            uint32(block.timestamp),
            maxImpliedRate
        );

        Portfolios().upsertAccountAsset(account, asset, DEFER_CHECK);

        return cash;
    }

    function _takeCurrentCash(
        address account,
        uint32 maturity,
        uint128 fCashAmount,
        uint32 maxTime,
        uint32 maxImpliedRate
    ) internal returns (Common.Asset memory, uint128) {
        _isValidBlock(maturity, maxTime);
        require(fCashAmount <= G_MAX_TRADE_SIZE, "16");

        uint128 cash = _updateMarket(maturity, int256(fCashAmount));
        require(cash > 0, "15");

        uint32 timeToMaturity = maturity - uint32(block.timestamp);
        uint128 fee = _calculateTransactionFee(cash, timeToMaturity);
        uint32 impliedRate = _calculateImpliedRate(cash.sub(fee), fCashAmount, timeToMaturity);
        require(impliedRate <= maxImpliedRate, "17");

        // Move the cash from the contract's cash balances account to the sender. This must happen before
        // the call to insert the trade below in order for the free collateral check to work properly.
        Escrow().withdrawFromMarket(account, CASH_GROUP, cash, fee);

        // The sender now has an obligation to pay cash at maturity.
        Common.Asset memory asset = Common.Asset(CASH_GROUP, 0, maturity, Common.getCashPayer(), 0, fCashAmount);

        emit TakeCurrentCash(account, maturity, fCashAmount, cash, fee);

        return (asset, cash);
    }

    /**
     * @notice Given the amount of fCash to purchase, returns the amount of cash this would cost at the current
     * block.
     * @param maturity the maturity of the fCash
     * @param fCashAmount the amount of fCash to purchase
     * @return the amount of cash this would cost, returns 0 on trade failure
     */
    function getCurrentCashTofCash(uint32 maturity, uint128 fCashAmount) public view returns (uint128) {
        return getCurrentCashTofCashAtTime(maturity, fCashAmount, uint32(block.timestamp));
    }

    /**
     * @notice Given the amount of fCash to purchase, returns the amount of cash this would cost.
     * @dev - CANNOT_GET_PRICE_FOR_MATURITY: can only get prices before the maturity
     * @param maturity the maturity of the fCash
     * @param fCashAmount the amount of fCash to purchase
     * @param blockTime the time to calculate the price at
     * @return the amount of cash this would cost, returns 0 on trade failure
     */
    function getCurrentCashTofCashAtTime(
        uint32 maturity,
        uint128 fCashAmount,
        uint32 blockTime
    ) public view returns (uint128) {
        Market memory interimMarket = markets[maturity];
        require(blockTime < maturity, "41");

        uint32 timeToMaturity = maturity - blockTime;

        (
            ,
            /* market */
            uint128 cash
        ) = _tradeCalculation(interimMarket, int256(fCashAmount).neg(), timeToMaturity);
        uint128 fee = _calculateTransactionFee(cash, timeToMaturity);
        // On trade failure, we will simply return 0
        return cash.add(fee);
    }

    /**
     * @notice Deposit cash in return for the right to receive cash at the specified maturity. Equivalent to lending
     * cash at a fixed rate.
     * @dev - TRADE_FAILED_MAX_TIME: maturity specified is not yet active
     * - MARKET_INACTIVE: maturity is not a valid one
     * - TRADE_FAILED_TOO_LARGE: trade is larger than allowed by the governance settings
     * - TRADE_FAILED_LACK_OF_LIQUIDITY: there is insufficient liquidity in this maturity to handle the trade
     * - TRADE_FAILED_SLIPPAGE: trade is lower than the min implied rate set
     * - INSUFFICIENT_BALANCE: not enough cash to complete this trade
     * @param maturity the maturity to receive fCash in
     * @param fCashAmount the amount of fCash to purchase
     * @param maxTime after this time the trade will not settle
     * @param minImpliedRate the minimum implied rate that the lender will accept
     * @return the amount of cash deposited to the market, `fCashAmount - cash` is the interest to be received
     */
    function takefCash(
        uint32 maturity,
        uint128 fCashAmount,
        uint32 maxTime,
        uint128 minImpliedRate
    ) external returns (uint128) {
        (Common.Asset memory asset, uint128 cash) = _takefCash(
            msg.sender,
            maturity,
            fCashAmount,
            maxTime,
            minImpliedRate
        );

        // This will do a free collateral check before it adds to the portfolio.
        Portfolios().upsertAccountAsset(msg.sender, asset, CHECK_FC);

        return cash;
    }

    /**
     * @notice Used by ERC1155 contract to take fCash
     * @dev skip
     */
    function takefCashOnBehalf(
        address account,
        uint32 maturity,
        uint128 fCashAmount,
        uint32 minImpliedRate
    ) external returns (uint128) {
        require(calledByERC1155Trade(), "20");

        (Common.Asset memory asset, uint128 cash) = _takefCash(
            account,
            maturity,
            fCashAmount,
            uint32(block.timestamp),
            minImpliedRate
        );

        Portfolios().upsertAccountAsset(account, asset, DEFER_CHECK);

        return cash;
    }

    function _takefCash(
        address account,
        uint32 maturity,
        uint128 fCashAmount,
        uint32 maxTime,
        uint128 minImpliedRate
    ) internal returns (Common.Asset memory, uint128) {
        _isValidBlock(maturity, maxTime);
        require(fCashAmount <= G_MAX_TRADE_SIZE, "16");

        uint128 cash = _updateMarket(maturity, int256(fCashAmount).neg());
        require(cash > 0, "15");

        uint32 timeToMaturity = maturity - uint32(block.timestamp);
        uint128 fee = _calculateTransactionFee(cash, timeToMaturity);

        uint32 impliedRate = _calculateImpliedRate(cash.add(fee), fCashAmount, timeToMaturity);
        require(impliedRate >= minImpliedRate, "17");

        // Move the cash from the sender to the contract address. This must happen before the
        // insert trade call below.
        Escrow().depositIntoMarket(account, CASH_GROUP, cash, fee);

        Common.Asset memory asset = Common.Asset(CASH_GROUP, 0, maturity, Common.getCashReceiver(), 0, fCashAmount);

        emit TakefCash(account, maturity, fCashAmount, cash, fee);

        return (asset, cash);
    }

    /********** Trading Cash ******************************/

    /********** Liquidation *******************************/

    /**
     * @notice Turns fCash tokens into a current cash. Used by portfolios when settling cash.
     * This method currently sells `maxfCash` every time since it's not possible to calculate the
     * amount of fCash to sell from `cashRequired`.
     * @dev skip
     * @param account that holds the fCash
     * @param cashRequired amount of cash that needs to be raised
     * @param maxfCash the maximum amount of fCash that can be sold
     * @param maturity the maturity of the fCash
     */
    function tradeCashReceiver(
        address account,
        uint128 cashRequired,
        uint128 maxfCash,
        uint32 maturity
    ) external returns (uint128) {
        require(calledByPortfolios(), "20");

        uint128 cash = _updateMarket(maturity, int256(maxfCash));

        // Here we've sold cash in excess of what was required, so we credit the remaining back
        // to the account that was holding the trade.
        if (cash > cashRequired) {
            Escrow().withdrawFromMarket(account, CASH_GROUP, cash - cashRequired, 0);

            cash = cashRequired;
        }

        return cash;
    }

    /**
     * @notice Called by the portfolios contract when a liquidity token is being converted for cash.
     * @dev skip
     * @param cashRequired the amount of cash required
     * @param maxTokenAmount the max balance of tokens available
     * @param maturity when the token matures
     * @return the amount of cash raised, fCash raised, tokens removed
     */
    function tradeLiquidityToken(
        uint128 cashRequired,
        uint128 maxTokenAmount,
        uint32 maturity
    )
        external
        returns (
            uint128,
            uint128,
            uint128
        )
    {
        require(calledByPortfolios(), "20");
        Market memory market = markets[maturity];

        // This is the total claim on cash that the tokens have.
        uint128 tokensToRemove = maxTokenAmount;
        uint128 cashAmount = SafeCast.toUint128(
            uint256(market.totalCurrentCash).mul(tokensToRemove).div(market.totalLiquidity)
        );

        if (cashAmount > cashRequired) {
            // If the total claim is greater than required, we only want to remove part of the liquidity.
            tokensToRemove = SafeCast.toUint128(
                uint256(cashRequired).mul(market.totalLiquidity).div(market.totalCurrentCash)
            );
            cashAmount = cashRequired;
        }

        // This method will credit the cashAmount back to the balances on the escrow contract.
        uint128 fCashAmount;
        (cashAmount, fCashAmount) = _settleLiquidityToken(tokensToRemove, maturity);

        return (cashAmount, fCashAmount, tokensToRemove);
    }

    /********** Liquidation *******************************/

    /********** Rate Methods ******************************/

    /**
     * @notice Returns the market object at the specified maturity
     * @param maturity the maturity of the market
     * @return A market object with these values:
     *  - `totalfCash`: total amount of fCash available at the maturity
     *  - `totalLiquidity`: total amount of liquidity tokens
     *  - `totalCurrentCash`: total amount of current cash available at maturity
     *  - `rateScalar`: determines the slippage rate during trading
     *  - `rateAnchor`: determines the base rate at market instantiation
     *  - `lastImpliedRate`: the last rate that the market traded at, used to smooth rates between periods of
     *     trading inactivity.
     */
    function getMarket(uint32 maturity) external view returns (Market memory) {
        return markets[maturity];
    }

    /**
     * @notice Returns the current mid exchange rate of cash to fCash. This is NOT the rate that users will be able to trade it, those
     * calculations depend on trade size and you must use the `getCurrentCashTofCash` or `getfCashToCurrentCash` methods.
     * @param maturity the maturity to get the rate for
     * @return a tuple where the first value is the exchange rate and the second value is a boolean indicating
     *  whether or not the maturity is active
     */
    function getRate(uint32 maturity) public view returns (uint32, bool) {
        Market memory market = markets[maturity];
        if (block.timestamp >= maturity) {
            // The exchange rate is 1 after we hit maturity for the fCash market.
            return (INSTRUMENT_PRECISION, true);
        } else {
            uint32 timeToMaturity = maturity - uint32(block.timestamp);
            bool success;
            uint32 rate;

            (market.rateAnchor, success) = _getNewRateAnchor(market, timeToMaturity);
            if (!success) revert("50");

            (rate, success) = _getExchangeRate(market, timeToMaturity, 0);
            if (!success) revert("50");

            return (rate, false);
        }
    }

    /**
     * @notice Gets the exchange rates for all the active markets.
     * @return an array of rates starting from the most current maturity to the furthest maturity
     */
    function getMarketRates() external view returns (uint32[] memory) {
        uint32[] memory marketRates = new uint32[](G_NUM_MATURITIES);
        uint32 maturity = uint32(block.timestamp) - (uint32(block.timestamp) % G_MATURITY_LENGTH) + G_MATURITY_LENGTH;
        for (uint256 i; i < marketRates.length; i++) {
            (uint32 rate, ) = getRate(maturity);
            marketRates[i] = rate;

            maturity = maturity + G_MATURITY_LENGTH;
        }

        return marketRates;
    }

    /**
     * @notice Gets the maturities for all the active markets.
     * @return an array of timestamps of the currently active maturities
     */
    function getActiveMaturities() external view returns (uint32[] memory) {
        uint32[] memory ids = new uint32[](G_NUM_MATURITIES);
        uint32 blockTime = uint32(block.timestamp);
        uint32 currentMaturity = blockTime - (blockTime % G_MATURITY_LENGTH) + G_MATURITY_LENGTH;
        for (uint256 i; i < ids.length; i++) {
            ids[i] = currentMaturity + uint32(i) * G_MATURITY_LENGTH;
        }
        return ids;
    }

    /*********** Internal Methods ********************/

    function _calculateTransactionFee(uint128 cash, uint32 timeToMaturity) internal view returns (uint128) {
        return
            SafeCast.toUint128(
                uint256(cash).mul(G_TRANSACTION_FEE).mul(timeToMaturity).div(G_MATURITY_LENGTH).div(Common.DECIMALS)
            );
    }

    function _updateMarket(uint32 maturity, int256 fCashAmount) internal returns (uint128) {
        Market memory interimMarket = markets[maturity];
        uint32 timeToMaturity = maturity - uint32(block.timestamp);
        uint128 cash;
        // Here we are selling fCash in return for cash
        (interimMarket, cash) = _tradeCalculation(interimMarket, fCashAmount, timeToMaturity);

        // Cash value of 0 signifies a failed trade
        if (cash > 0) {
            markets[maturity] = interimMarket;
        }

        return cash;
    }

    /**
     * @notice Checks if the maturity and max time supplied are valid. The requirements are:
     *  - blockTime <= maxTime < maturity <= maxMaturity
     *  - maturity % G_MATURITY_LENGTH == 0
     * Reverts if the block is not valid.
     */
    function _isValidBlock(uint32 maturity, uint32 maxTime) internal view returns (bool) {
        uint32 blockTime = uint32(block.timestamp);
        require(blockTime <= maxTime, "18");
        require(blockTime < maturity, "3");
        // If the number of maturitys is set to zero then we prevent all new trades.
        require(maturity % G_MATURITY_LENGTH == 0, "3");
        require(G_NUM_MATURITIES > 0, "3");

        uint32 maxMaturity = blockTime - (blockTime % G_MATURITY_LENGTH) + (G_MATURITY_LENGTH * G_NUM_MATURITIES);
        require(maturity <= maxMaturity, "3");
    }

    /**
     * @notice Does the trade calculation and returns the required objects for the contract methods to interpret.
     *
     * @param interimMarket the market to do the calculations over
     * @param fCashAmount the fCash amount specified
     * @param timeToMaturity number of seconds until maturity
     * @return (new market object, cash)
     */
    function _tradeCalculation(
        Market memory interimMarket,
        int256 fCashAmount,
        uint32 timeToMaturity
    ) internal view returns (Market memory, uint128) {
        if (fCashAmount < 0 && interimMarket.totalfCash < fCashAmount.neg()) {
            // We return false if there is not enough fCash to support this trade.
            return (interimMarket, 0);
        }

        // Get the new rate anchor for this market, this accounts for the anchor rate changing as we
        // roll down to maturity. This needs to be saved to the market if we actually trade.
        bool success;
        (interimMarket.rateAnchor, success) = _getNewRateAnchor(interimMarket, timeToMaturity);
        if (!success) return (interimMarket, 0);

        // Calculate the exchange rate the user will actually trade at, we simulate the fCash amount
        // added or subtracted to the numerator of the proportion.
        uint256 tradeExchangeRate;
        (tradeExchangeRate, success) = _getExchangeRate(interimMarket, timeToMaturity, fCashAmount);
        if (!success) return (interimMarket, 0);

        // The fee amount will decrease as we roll down to maturity
        uint256 fee = uint256(G_LIQUIDITY_FEE).mul(timeToMaturity).div(G_MATURITY_LENGTH);
        if (fCashAmount > 0) {
            uint256 postFeeRate = tradeExchangeRate + fee;
            // This is an overflow on the fee
            if (postFeeRate < tradeExchangeRate) return (interimMarket, 0);
            tradeExchangeRate = postFeeRate;
        } else {
            uint256 postFeeRate = tradeExchangeRate - fee;
            // This is an underflow on the fee
            if (postFeeRate > tradeExchangeRate) return (interimMarket, 0);
            tradeExchangeRate = postFeeRate;
        }

        if (tradeExchangeRate < INSTRUMENT_PRECISION) {
            // We do not allow negative exchange rates.
            return (interimMarket, 0);
        }

        // cash = fCashAmount / exchangeRate
        uint128 cash = SafeCast.toUint128(uint256(fCashAmount.abs()).mul(INSTRUMENT_PRECISION).div(tradeExchangeRate));

        // Update the markets accordingly.
        if (fCashAmount > 0) {
            if (interimMarket.totalCurrentCash < cash) {
                // There is not enough cash to support this trade.
                return (interimMarket, 0);
            }

            interimMarket.totalfCash = interimMarket.totalfCash.add(uint128(fCashAmount));
            interimMarket.totalCurrentCash = interimMarket.totalCurrentCash.sub(cash);
        } else {
            interimMarket.totalfCash = interimMarket.totalfCash.sub(uint128(fCashAmount.abs()));
            interimMarket.totalCurrentCash = interimMarket.totalCurrentCash.add(cash);
        }

        // Now calculate the implied rate, this will be used for future rolldown calculations.
        uint32 impliedRate;
        (impliedRate, success) = _getImpliedRate(interimMarket, timeToMaturity);

        if (!success) return (interimMarket, 0);

        interimMarket.lastImpliedRate = impliedRate;

        return (interimMarket, cash);
    }

    /**
     * The rate anchor will update as the market rolls down to maturity. The calculation is:
     * newAnchor = anchor - [currentImpliedRate - lastImpliedRate] * (timeToMaturity / MATURITY_SIZE)
     * where:
     * lastImpliedRate = (exchangeRate' - 1) * (MATURITY_SIZE / timeToMaturity')
     *      (calculated when the last trade in the market was made)
     * timeToMaturity = maturity - currentBlockTime
     * @return the new rate anchor and a boolean that signifies success
     */
    function _getNewRateAnchor(Market memory market, uint32 timeToMaturity) internal view returns (uint32, bool) {
        (uint32 impliedRate, bool success) = _getImpliedRate(market, timeToMaturity);

        if (!success) return (0, false);

        int256 rateDifference = int256(impliedRate).sub(market.lastImpliedRate).mul(timeToMaturity).div(
            G_MATURITY_LENGTH
        );
        int256 newRateAnchor = int256(market.rateAnchor).sub(rateDifference);

        if (newRateAnchor < 0 || newRateAnchor > Common.MAX_UINT_32) return (0, false);

        return (uint32(newRateAnchor), true);
    }

    /**
     * This is the implied rate calculated after a trade is made or when liquidity is added to the pool initially.
     * @return the implied rate and a bool that is true on success
     */
    function _getImpliedRate(Market memory market, uint32 timeToMaturity) internal view returns (uint32, bool) {
        (uint32 exchangeRate, bool success) = _getExchangeRate(market, timeToMaturity, 0);

        if (!success) return (0, false);
        if (exchangeRate < INSTRUMENT_PRECISION) return (0, false);

        uint256 rate = uint256(exchangeRate - INSTRUMENT_PRECISION).mul(G_MATURITY_LENGTH).div(timeToMaturity);

        if (rate > Common.MAX_UINT_32) return (0, false);

        return (uint32(rate), true);
    }

    /**
     * @notice This function reverts if the implied rate is negative.
     */
    function _getImpliedRateRequire(Market memory market, uint32 timeToMaturity) internal view returns (uint32) {
        (uint32 impliedRate, bool success) = _getImpliedRate(market, timeToMaturity);

        require(success, "50");

        return impliedRate;
    }

    function _calculateImpliedRate(
        uint128 cash,
        uint128 fCash,
        uint32 timeToMaturity
    ) internal view returns (uint32) {
        uint256 exchangeRate = uint256(fCash).mul(INSTRUMENT_PRECISION).div(cash);
        return SafeCast.toUint32(exchangeRate.sub(INSTRUMENT_PRECISION).mul(G_MATURITY_LENGTH).div(timeToMaturity));
    }

    /**
     * @dev It is important that this call does not revert, if it does it may prevent liquidation
     * or settlement from finishing. We return a rate of 0 to signify a failure.
     *
     * Takes a market in memory and calculates the following exchange rate:
     * (1 / G_RATE_SCALAR) * ln(proportion / (1 - proportion)) + G_RATE_ANCHOR
     * where:
     * proportion = totalfCash / (totalfCash + totalCurrentCash)
     */
    function _getExchangeRate(
        Market memory market,
        uint32 timeToMaturity,
        int256 fCashAmount
    ) internal view returns (uint32, bool) {
        // These two conditions will result in divide by zero errors.
        if (market.totalfCash.add(market.totalCurrentCash) == 0 || market.totalCurrentCash == 0) {
            return (0, false);
        }

        // This will always be positive, we do a check beforehand in _tradeCalculation
        uint256 numerator = uint256(int256(market.totalfCash).add(fCashAmount));
        // This is always less than DECIMALS
        uint256 proportion = numerator.mul(Common.DECIMALS).div(market.totalfCash.add(market.totalCurrentCash));

        // proportion' = proportion / (1 - proportion)
        proportion = proportion.mul(Common.DECIMALS).div(uint256(Common.DECIMALS).sub(proportion));

        // (1 / scalar) * ln(proportion') + anchor_rate
        (int256 abdkResult, bool success) = _abdkMath(proportion);

        if (!success) return (0, false);

        // The rate scalar will increase towards maturity, this will lower the impact of changes
        // to the proportion as we get towards maturity.
        int256 rateScalar = int256(market.rateScalar).mul(G_MATURITY_LENGTH).div(timeToMaturity);
        if (rateScalar > Common.MAX_UINT_32) return (0, false);

        // This is ln(1e18), subtract this to scale proportion back. There is no potential for overflow
        // in int256 space with the addition and subtraction here.
        int256 rate = ((abdkResult - LN_1E18) / rateScalar) + market.rateAnchor;

        // These checks simply prevent math errors, not negative interest rates.
        if (rate < 0) {
            return (0, false);
        } else if (rate > Common.MAX_UINT_32) {
            return (0, false);
        } else {
            return (uint32(rate), true);
        }
    }

    function _abdkMath(uint256 proportion) internal pure returns (uint64, bool) {
        // This is the max 64 bit integer for ABDKMath. Note that this will fail when the
        // market reaches a proportion of 9.2 due to the MAX64 value.
        if (proportion > MAX64) return (0, false);

        int128 abdkProportion = ABDKMath64x64.fromUInt(proportion);
        // If abdkProportion is negative, this means that it is less than 1 and will
        // return a negative log so we exit here
        if (abdkProportion <= 0) return (0, false);

        int256 abdkLog = ABDKMath64x64.ln(abdkProportion);
        // This is the 64x64 multiplication with the 64x64 represenation of 1e9. The max value of
        // this due to MAX64 is ln(MAX64) * 1e9 = 43668272375
        int256 result = (abdkLog * PRECISION_64x64) >> 64;

        if (result < ABDKMath64x64.MIN_64x64 || result > ABDKMath64x64.MAX_64x64) {
            return (0, false);
        }

        // Will pass int128 conversion after the overflow checks above. We convert to a uint here because we have
        // already checked that proportion is positive and so we cannot return a negative log.
        return (ABDKMath64x64.toUInt(int128(result)), true);
    }
}

pragma solidity ^0.6.0;

// SPDX-License-Identifier: GPL-3.0-only



library SafeUInt128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128) {
        uint128 c = a + b;
        require(c >= a, "104");
        return c;
    }

    /**
     * @notice x-y. You can use add(x,-y) instead.
     * @dev Tests covered by add(x,y)
     */
    function sub(uint128 a, uint128 b) internal pure returns (uint128) {
        uint128 c = a - b;
        require(c <= a, "105");
        return c;
    }

    function mul(uint128 x, uint128 y) internal pure returns (uint128) {
        if (x == 0) {
            return 0;
        }

        uint128 z = x * y;
        require(z / x == y, "106");

        return z;
    }

    function div(uint128 x, uint128 y) internal pure returns (uint128) {
        require(y > 0, "107");
        return x / y;
    }
}

pragma solidity ^0.6.0;

// SPDX-License-Identifier: GPL-3.0-only


library SafeInt256 {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }

    function abs(int256 x) internal pure returns (int256) {
        if (x < 0) return neg(x);
        else return x;
    }

    function neg(int256 x) internal pure returns (int256) {
        return mul(x, -1);
    }

    function subNoNeg(int256 x, int256 y) internal pure returns (int256) {
        int256 z = sub(x, y);
        require(z >= 0, "8");

        return z;
    }
}

pragma solidity ^0.6.0;

/*
 * ABDK Math 64.64 Smart Contract Library.    Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */



/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.    Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.    As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
    /**
     * Minimum value signed 64.64-bit fixed point number may have.
     */
    int128 internal constant MIN_64x64 = -0x80000000000000000000000000000000;

    /**
     * Maximum value signed 64.64-bit fixed point number may have.
     */
    int128 internal constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    /**
     * Convert signed 256-bit integer number into signed 64.64-bit fixed point
     * number.    Revert on overflow.
     *
     * @param x signed 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function fromInt(int256 x) internal pure returns (int128) {
        require(x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF, "113");
        return int128(x << 64);
    }

    /**
     * Convert signed 64.64 fixed point number into signed 64-bit integer number
     * rounding down.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64-bit integer number
     */
    function toInt(int128 x) internal pure returns (int64) {
        return int64(x >> 64);
    }

    /**
     * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
     * number.    Revert on overflow.
     *
     * @param x unsigned 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function fromUInt(uint256 x) internal pure returns (int128) {
        require(x <= 0x7FFFFFFFFFFFFFFF, "114");
        return int128(x << 64);
    }

    /**
     * Convert signed 64.64 fixed point number into unsigned 64-bit integer
     * number rounding down.    Revert on underflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return unsigned 64-bit integer number
     */
    function toUInt(int128 x) internal pure returns (uint64) {
        require(x >= 0, "114");
        return uint64(x >> 64);
    }

    /**
     * Calculate x * y rounding down.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function mul(int128 x, int128 y) internal pure returns (int128) {
        int256 result = (int256(x) * y) >> 64;
        require(result >= MIN_64x64 && result <= MAX_64x64, "115");
        return int128(result);
    }

    /**
     * Calculate binary logarithm of x.    Revert if x <= 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function log_2(int128 x) internal pure returns (int128) {
        require(x > 0, "116");

        int256 msb = 0;
        int256 xc = x;
        if (xc >= 0x10000000000000000) {
            xc >>= 64;
            msb += 64;
        }
        if (xc >= 0x100000000) {
            xc >>= 32;
            msb += 32;
        }
        if (xc >= 0x10000) {
            xc >>= 16;
            msb += 16;
        }
        if (xc >= 0x100) {
            xc >>= 8;
            msb += 8;
        }
        if (xc >= 0x10) {
            xc >>= 4;
            msb += 4;
        }
        if (xc >= 0x4) {
            xc >>= 2;
            msb += 2;
        }
        if (xc >= 0x2) msb += 1; // No need to shift xc anymore

        int256 result = (msb - 64) << 64;
        uint256 ux = uint256(x) << (127 - msb);
        for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
            ux *= ux;
            uint256 b = ux >> 255;
            ux >>= 127 + b;
            result += bit * int256(b);
        }

        return int128(result);
    }

    /**
     * Calculate natural logarithm of x.    Revert if x <= 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function ln(int128 x) internal pure returns (int128) {
        require(x > 0, "116");

        return int128((uint256(log_2(x)) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF) >> 128);
    }
}

pragma solidity ^0.6.0;

// SPDX-License-Identifier: GPL-3.0-only



/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "108");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "109");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "110");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "111");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "112");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: GPL-3.0-only



import "../interface/IEscrowCallable.sol";
import "../interface/IPortfoliosCallable.sol";

import "../upgradeable/Ownable.sol";
import "../upgradeable/Initializable.sol";

import "./Directory.sol";

/**
 * @title Governed
 * A base contract to set the contract references on each contract.
 */
contract Governed is OpenZeppelinUpgradesOwnable, Initializable {
    address public DIRECTORY;
    mapping(uint256 => address) private contracts;

    function initialize(address directory, address owner) public initializer {
        _owner = owner;
        DIRECTORY = directory;
    }

    enum CoreContracts {
        Escrow,
        Portfolios,
        ERC1155Token,
        ERC1155Trade
    }

    function setContract(CoreContracts name, address contractAddress) public {
        require(msg.sender == DIRECTORY, "20");
        contracts[uint256(name)] = contractAddress;
    }

    function _setDependencies(CoreContracts[] memory dependencies) internal {
        address[] memory _contracts = Directory(DIRECTORY).getContracts(dependencies);
        for (uint256 i; i < _contracts.length; i++) {
            contracts[uint256(dependencies[i])] = _contracts[i];
        }
    }

    function Escrow() internal view returns (IEscrowCallable) {
        return IEscrowCallable(contracts[uint256(CoreContracts.Escrow)]);
    }

    function Portfolios() internal view returns (IPortfoliosCallable) {
        return IPortfoliosCallable(contracts[uint256(CoreContracts.Portfolios)]);
    }

    function calledByEscrow() internal view returns (bool) {
        return msg.sender == contracts[(uint256(CoreContracts.Escrow))];
    }

    function calledByPortfolios() internal view returns (bool) {
        return msg.sender == contracts[(uint256(CoreContracts.Portfolios))];
    }

    function calledByERC1155Token() internal view returns (bool) {
        return msg.sender == contracts[(uint256(CoreContracts.ERC1155Token))];
    }

    function calledByERC1155Trade() internal view returns (bool) {
        return msg.sender == contracts[(uint256(CoreContracts.ERC1155Trade))];
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: GPL-3.0-only



import "../utils/Common.sol";

interface IEscrowCallable {
    function setLiquidityHaircut(uint128 haircut) external;
    function isValidCurrency(uint16 currency) external view returns (bool);
    function getBalances(address account) external view returns (int256[] memory);
    function convertBalancesToETH(int256[] calldata amounts) external view returns (int256[] memory);
    function portfolioSettleCash(address account, int256[] calldata settledCash) external;
    function unlockCurrentCash(uint16 currency, address cashMarket, int256 amount) external;

    function depositsOnBehalf(address account, Common.Deposit[] calldata deposits) external payable;
    function withdrawsOnBehalf(address account, Common.Withdraw[] calldata withdraws) external;

    function depositIntoMarket(
        address account,
        uint8 cashGroupId,
        uint128 value,
        uint128 fee
    ) external;
    function withdrawFromMarket(
        address account,
        uint8 cashGroupId,
        uint128 value,
        uint128 fee
    ) external;
}

pragma solidity ^0.6.4;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: GPL-3.0-only



import "../lib/SafeMath.sol";

/**
 * @notice Contains all the structs and convenience methods for Notional contracts.
 */
library Common {
    using SafeMath for uint256;

    bytes1 internal constant MASK_POOL = 0x01; // 0000 0001
    bytes1 internal constant MASK_NET = 0x02; // 0000 0010
    bytes1 internal constant MASK_ORDER = 0x04; // 0000 0100
    bytes1 internal constant MASK_CASH = 0x08; // 0000 1000

    bytes1 internal constant MASK_PAYER = 0x10; // 0001 0000
    bytes1 internal constant MASK_RECEIVER = 0x20; // 0010 0000
    bytes1 internal constant MASK_PERIODIC = 0x80; // 1000 0000

    int256 internal constant RATE_DECIMALS = 1e9;
    uint128 internal constant DECIMALS = 1e18;
    uint128 internal constant MAX_UINT_128 = (2**128) - 1;
    uint32 internal constant MAX_UINT_32 = (2**32) - 1;
    uint32 internal constant SECONDS_IN_YEAR = 31536000;

    /**
     * The collateral requirement per currency in the portfolio. Only used as an
     * in memory object between the RiskFramework and the freeCollateral calculation.
     */
    struct Requirement {
        // The currency group id that this requirement is for
        uint16 currency;
        // The net fCash value in this particular currency
        int256 netfCashValue;
        // Post haircut cash claims on liquidity tokens
        int256 cashClaim;
    }

    /**
     * Each asset object is a 32 byte word stored in the portfolio.
     */
    struct Asset {
        // The cash group id for this asset
        uint8 cashGroupId;
        // The instrument id for this asset
        uint16 instrumentId;
        // When this asset matures, in seconds
        uint32 maturity;
        // A 1 byte bitfield defined above that contains instrument agnostic
        // information about a asset (i.e. payer or receiver, periodic or nonperiodic)
        bytes1 assetType;
        // The rate for this asset
        uint32 rate;
        // The notional for this asset
        uint128 notional;
        // uint32 unused space
    }

    // These are the factors we used to determine how to settle or liquidate an account
    struct FreeCollateralFactors {
        // Aggregate amount of free collateral
        int256 aggregate;
        // Net available amounts in local currency
        int256 localNetAvailable;
        // Net available amounts in collateral currency
        int256 collateralNetAvailable;
        // Cash claim amount in local currency
        int256 localCashClaim;
        // Cash claim amount in collateral currency
        int256 collateralCashClaim;
    }

    /**
     * Describes a group of instruments that are closely related enough for their risk ladders to net
     * against each other. Also defines the other parameters that will apply to all the instruments in
     * the group such that their risk ladders can net against each other.
     *
     * Each risk ladder is defined by its maturity cadence which maps to an underlying fCash market,
     * therefore each Instrument Group will map to a fCash market called `cashMarket`.
     */
    struct CashGroup {
        // The maximum number of future maturities that instruments in this group will asset
        uint32 numMaturities;
        // The size of maturities (in seconds) for all instruments in this group
        uint32 maturityLength;
        // The precision of the discount rate oracle
        uint32 precision;
        // The discount rate oracle that applies to all instruments in this group
        address cashMarket;
        // The currency group identifier for this cash group
        uint16 currency;
    }

    /**
     * Used to describe deposits in ERC1155.batchOperation
     */
    struct Deposit {
        // Currency Id to deposit
        uint16 currencyId;
        // Amount of tokens to deposit
        uint128 amount;
    }

    /**
     * Used to describe withdraws in ERC1155.batchOperationWithdraw
     */
    struct Withdraw {
        // Destination of the address to withdraw to
        address to;
        // Currency Id to withdraw
        uint16 currencyId;
        // Amount of tokens to withdraw
        uint128 amount;
    }

    enum TradeType {
        TakeCurrentCash,
        TakefCash,
        AddLiquidity,
        RemoveLiquidity
    }

    /**
     * Used to describe a trade in ERC1155.batchOperation
     */
    struct Trade {
        TradeType tradeType;
        uint8 cashGroup;
        uint32 maturity;
        uint128 amount;
        bytes slippageData;
    }

    /**
     * Checks if a asset is a periodic asset, i.e. it matures on the cadence
     * defined by its Instrument Group.
     */
    function isPeriodic(bytes1 assetType) internal pure returns (bool) {
        return ((assetType & MASK_PERIODIC) == MASK_PERIODIC);
    }

    /**
     * Checks if a asset is a payer, meaning that the asset is an obligation
     * to pay cash when the asset matures.
     */
    function isPayer(bytes1 assetType) internal pure returns (bool) {
        return ((assetType & MASK_PAYER) == MASK_PAYER);
    }

    /**
     * Checks if a asset is a receiver, meaning that the asset is an entitlement
     * to recieve cash when asset matures.
     */
    function isReceiver(bytes1 assetType) internal pure returns (bool) {
        return ((assetType & MASK_RECEIVER) == MASK_RECEIVER);
    }

    /**
     * Checks if a asset is a liquidity token, which represents a claim on collateral
     * and fCash in a fCash market. The liquidity token can only be stored
     * as a receiver in the portfolio, but it can be marked as a payer in memory when
     * the contracts remove liquidity.
     */
    function isLiquidityToken(bytes1 assetType) internal pure returns (bool) {
        return ((assetType & MASK_ORDER) == MASK_ORDER && (assetType & MASK_CASH) == MASK_CASH);
    }

    /**
     * Checks if an object is a fCash token.
     */
    function isCash(bytes1 assetType) internal pure returns (bool) {
        return ((assetType & MASK_ORDER) == 0x00 && (assetType & MASK_CASH) == MASK_CASH);
    }

    function isCashPayer(bytes1 assetType) internal pure returns (bool) {
        return isCash(assetType) && isPayer(assetType);
    }

    function isCashReceiver(bytes1 assetType) internal pure returns (bool) {
        return isCash(assetType) && isReceiver(assetType) && !isLiquidityToken(assetType);
    }

    /**
     * Changes a asset into its counterparty asset.
     */
    function makeCounterparty(bytes1 assetType) internal pure returns (bytes1) {
        if (isPayer(assetType)) {
            return ((assetType & ~(MASK_PAYER)) | MASK_RECEIVER);
        } else {
            return ((assetType & ~(MASK_RECEIVER)) | MASK_PAYER);
        }
    }

    /**
     * Returns a liquidity token asset type, this is marked as receiver that
     * will be stored in the portfolio.
     */
    function getLiquidityToken() internal pure returns (bytes1) {
        return MASK_RECEIVER | MASK_CASH | MASK_PERIODIC | MASK_ORDER;
    }

    function getCashPayer() internal pure returns (bytes1) {
        return MASK_PAYER | MASK_CASH | MASK_PERIODIC;
    }

    function getCashReceiver() internal pure returns (bytes1) {
        return MASK_RECEIVER | MASK_CASH | MASK_PERIODIC;
    }

    /**
     * Returns the asset type from an encoded asset id.
     */
    function getAssetType(uint256 id) internal pure returns (bytes1) {
        return bytes1(bytes32(id) << 248);
    }

    /**
     * Creates a 32 byte asset id from a asset object. This is used to represent the asset in
     * the ERC1155 token standard. The actual id is located in the least significant 8 bytes
     * of the id. The ordering of the elements in the id are important because they define how
     * a portfolio will be sorted by `Common._sortPortfolio`.
     */
    function encodeAssetId(Asset memory asset) internal pure returns (uint256) {
        bytes8 id = (bytes8(bytes1(asset.cashGroupId)) & 0xFF00000000000000) |
            ((bytes8(bytes2(asset.instrumentId)) >> 8) & 0x00FFFF0000000000) |
            ((bytes8(bytes4(asset.maturity)) >> 24) & 0x000000FFFFFFFF00) |
            ((bytes8(asset.assetType) >> 56) & 0x00000000000000FF);

        return uint256(bytes32(id) >> 192);
    }

    /**
     * Decodes a uint256 id for a asset
     *
     * @param _id a uint256 asset id
     * @return (cashGroupId, instrumentId, maturity)
     */
    function decodeAssetId(uint256 _id) internal pure returns (uint8, uint16, uint32)
    {
        bytes32 id = bytes32(_id);
        return (
            // Instrument Group Id
            uint8(bytes1((id & 0x000000000000000000000000000000000000000000000000FF00000000000000) << 192)),
            // Instrument Id
            uint16(bytes2((id & 0x00000000000000000000000000000000000000000000000000FFFF0000000000) << 200)),
            // Maturity
            uint32(bytes4((id & 0x000000000000000000000000000000000000000000000000000000FFFFFFFF00) << 216))
        );
    }

    /**
     * Does a quicksort of the portfolio by the 256 bit id. This sorting is used in a few
     * algorithms to ensure that they work properly.
     *
     * @param data the in memory portfolio to sort
     */
    function _sortPortfolio(Asset[] memory data) internal pure returns (Asset[] memory) {
        if (data.length > 0) {
            _quickSort(data, int256(0), int256(data.length - 1));
        }
        return data;
    }

    function _quickSort(
        Asset[] memory data,
        int256 left,
        int256 right
    ) internal pure {
        if (left == right) return;
        int256 i = left;
        int256 j = right;

        uint256 pivot = encodeAssetId(data[uint256(left + (right - left) / 2)]);
        while (i <= j) {
            while (encodeAssetId(data[uint256(i)]) < pivot) i++;
            while (pivot < encodeAssetId(data[uint256(j)])) j--;
            if (i <= j) {
                // Swap positions
                (data[uint256(i)], data[uint256(j)]) = (data[uint256(j)], data[uint256(i)]);
                i++;
                j--;
            }
        }

        if (left < j) _quickSort(data, left, j);
        if (i < right) _quickSort(data, i, right);
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: GPL-3.0-only



import "../utils/Common.sol";

interface IPortfoliosCallable {
    function getAssets(address account) external view returns (Common.Asset[] memory);

    function getCashGroup(uint8 cashGroupId) external view returns (Common.CashGroup memory);

    function getCashGroups(uint8[] calldata groupIds) external view returns (Common.CashGroup[] memory);

    function settleMaturedAssets(address account) external;

    function settleMaturedAssetsBatch(address[] calldata account) external;

    function upsertAccountAsset(address account, Common.Asset calldata assets, bool checkFreeCollateral) external;

    function upsertAccountAssetBatch(address account, Common.Asset[] calldata assets, bool checkFreeCollateral) external;

    function mintfCashPair(address payer, address receiver, uint8 cashGroupId, uint32 maturity, uint128 notional) external;

    function freeCollateral(address account) external returns (int256, int256[] memory, int256[] memory);

    function freeCollateralViewAggregateOnly(address account) external view returns (int256);

    function freeCollateralAggregateOnly(address account) external returns (int256);

    function freeCollateralFactors(
        address account,
        uint256 localCurrency,
        uint256 collateralCurrency
    ) external returns (Common.FreeCollateralFactors memory);

    function setNumCurrencies(uint16 numCurrencies) external;

    function transferAccountAsset(
        address from,
        address to,
        bytes1 assetType,
        uint8 cashGroupId,
        uint16 instrumentId,
        uint32 maturity,
        uint128 value
    ) external;

    function searchAccountAsset(
        address account,
        bytes1 assetType,
        uint8 cashGroupId,
        uint16 instrumentId,
        uint32 maturity
    ) external view returns (Common.Asset memory, uint256);

    function raiseCurrentCashViaLiquidityToken(
        address account,
        uint16 currency,
        uint128 amount
    ) external returns (uint128);

    function raiseCurrentCashViaCashReceiver(
        address account,
        address liquidator,
        uint16 currency,
        uint128 amount
    ) external returns (uint128, uint128);
}

pragma solidity ^0.6.0;



/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 *
 * Source https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-solidity/v2.1.3/contracts/ownership/Ownable.sol
 * This contract is copied here and renamed from the original to avoid clashes in the compiled artifacts
 * when the user imports a zos-lib contract (that transitively causes this contract to be compiled and added to the
 * build/artifacts folder) as well as the vanilla Ownable implementation from an openzeppelin version.
 */
contract OpenZeppelinUpgradesOwnable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity >=0.4.24 <0.7.0;




/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: GPL-3.0-only



import "./Governed.sol";
import "../upgradeable/Ownable.sol";
import "../upgradeable/Initializable.sol";

/**
 * @title Directory
 * Stores the addresses and the dependency map for the entire Notional system. Allows
 * for the system to upgrade other contracts in the system.
 */
contract Directory is OpenZeppelinUpgradesOwnable, Initializable {
    mapping(uint256 => address) public contracts;
    event SetContract(Governed.CoreContracts name, address contractAddress);

    function initialize(address owner) external initializer {
        _owner = owner;
    }

    /**
     * Given a list of contracts that depend on "name", will set the current address on each one
     * of those contracts.
     *
     * @param name the contract that dependencies depend on
     * @param dependencies a list of contracts that depend on name
     */
    function setDependencies(
        Governed.CoreContracts name,
        Governed.CoreContracts[] calldata dependencies
    ) external onlyOwner {
        address contractAddress = contracts[uint256(name)];
        for (uint256 i; i < dependencies.length; i++) {
            Governed(contracts[uint256(dependencies[i])]).setContract(name, contractAddress);
        }
    }

    /**
     * Returns the addresses for a list of contracts. Used to set dependencies in non-core
     * contracts. These contracts will have to be updated by governance if core contracts
     * change.
     *
     * @param dependencies a list of core contracts required by the caller
     * @return a list of addresses corresponding to the dependencies
     */
    function getContracts(Governed.CoreContracts[] calldata dependencies) external view returns (address[] memory) {
        address[] memory contractAddresses = new address[](dependencies.length);
        for (uint256 i; i < contractAddresses.length; i++) {
            contractAddresses[i] = contracts[uint256(dependencies[i])];
        }
        return contractAddresses;
    }

    /**
     * Sets the global contract address for the directory. Must be called before updating
     * dependencies.
     *
     * @param name the enum of the contract
     * @param contractAddress the address of the contract
     */
    function setContract(Governed.CoreContracts name, address contractAddress) external onlyOwner {
        contracts[uint256(name)] = contractAddress;

        emit SetContract(name, contractAddress);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;


/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: GPL-3.0-only



import "./utils/Common.sol";
import "./utils/ERC1155Base.sol";

import "./interface/IERC1155TokenReceiver.sol";

import "./CashMarket.sol";

/**
 * @notice Implements the ERC1155 token standard for transferring fCash tokens within Notional. ERC1155 ids
 * encode an identifier that represents assets that are fungible with each other. For example, two fCash tokens
 * that asset in the same market and mature at the same time are fungible with each other and therefore will have the
 * same id. `CASH_PAYER` tokens are not transferrable because they have negative value.
 */
contract ERC1155Token is ERC1155Base {

    /**
     * @notice Transfers tokens between from and to addresses.
     * @dev - INVALID_ADDRESS: destination address cannot be 0
     *  - INTEGER_OVERFLOW: value cannot overflow uint128
     *  - CANNOT_TRANSFER_PAYER: cannot transfer assets that confer obligations
     *  - CANNOT_TRANSFER_MATURED_ASSET: cannot transfer asset that has matured
     *  - INSUFFICIENT_BALANCE: from account does not have sufficient tokens
     *  - ERC1155_NOT_ACCEPTED: to contract must accept the transfer
     * @param from Source address
     * @param to Target address
     * @param id ID of the token type
     * @param value Transfer amount
     * @param data Additional data with no specified format, unused by this contract but forwarded unaltered
     * to the ERC1155TokenReceiver.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override {
        _transfer(from, to, id, value);
        emit TransferSingle(msg.sender, from, to, id, value);

        // If code size > 0 call onERC1155received
        uint256 codeSize;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            codeSize := extcodesize(to)
        }
        if (codeSize > 0) {
            require(
                IERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, value, data) == ERC1155_ACCEPTED,
                "25"
            );
        }
    }

    /**
     * @notice Transfers tokens between from and to addresses in batch.
     * @dev - INVALID_ADDRESS: destination address cannot be 0
     *  - INTEGER_OVERFLOW: value cannot overflow uint128
     *  - CANNOT_TRANSFER_PAYER: cannot transfer assets that confer obligations
     *  - CANNOT_TRANSFER_MATURED_ASSET: cannot transfer asset that has matured
     *  - INSUFFICIENT_BALANCE: from account does not have sufficient tokens
     *  - ERC1155_NOT_ACCEPTED: to contract must accept the transfer
     * @param from Source address
     * @param to Target address
     * @param ids IDs of each token type (order and length must match _values array)
     * @param values Transfer amounts per token type (order and length must match _ids array)
     * @param data Additional data with no specified format, unused by this contract but forwarded unaltered
     * to the ERC1155TokenReceiver.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override {
        for (uint256 i; i < ids.length; i++) {
            _transfer(from, to, ids[i], values[i]);
        }

        emit TransferBatch(msg.sender, from, to, ids, values);

        // If code size > 0 call onERC1155received
        uint256 codeSize;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            codeSize := extcodesize(to)
        }
        if (codeSize > 0) {
            require(
                IERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, values, data) ==
                    ERC1155_BATCH_ACCEPTED,
                "25"
            );
        }
    }

    /**
     * Internal method for validating and updating state within a transfer.
     * @dev batch updates can be made a lot more efficient by not looping through this
     * code and updating storage on each loop, we can do it in memory and then flush to
     * storage just once.
     *
     * @param from the token holder
     * @param to the new token holder
     * @param id the token id
     * @param _value the notional amount to transfer
     */
    function _transfer(
        address from,
        address to,
        uint256 id,
        uint256 _value
    ) internal {
        require(to != address(0), "24");
        uint128 value = uint128(_value);
        require(uint256(value) == _value, "26");
        require(msg.sender == from || isApprovedForAll(from, msg.sender), "20");

        bytes1 assetType = Common.getAssetType(id);
        // Transfers can only be entitlements to receive which are a net benefit.
        require(Common.isReceiver(assetType), "23");

        (uint8 cashGroupId, uint16 instrumentId, uint32 maturity) = Common.decodeAssetId(id);
        require(maturity > block.timestamp, "35");

        Portfolios().transferAccountAsset(
            from,
            to,
            assetType,
            cashGroupId,
            instrumentId,
            maturity,
            value
        );
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: GPL-3.0-only



import "../utils/Common.sol";
import "../utils/Governed.sol";

import "../interface/IERC165.sol";
import "../interface/IERC1155.sol";

/**
 * @notice Base class for ERC1155 contracts. Implements balanceOf and operator methods.
 */
abstract contract ERC1155Base is Governed, IERC1155, IERC165 {
    // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
    bytes4 internal constant ERC1155_ACCEPTED = 0xf23a6e61;
    // bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
    bytes4 internal constant ERC1155_BATCH_ACCEPTED = 0xbc197c81;
    bytes4 internal constant ERC1155_INTERFACE = 0xd9b67a26;

    mapping(address => mapping(address => bool)) public operators;

    /**
     * @notice ERC165 compatibility for ERC1155
     * @dev skip
     * @param interfaceId the hash signature of the interface id
     */
    function supportsInterface(bytes4 interfaceId) external override view returns (bool) {
        if (interfaceId == ERC1155_INTERFACE) return true;
    }

    /**
     * @notice Get the balance of an account's tokens. For a more complete picture of an account's
     * portfolio, see the method `Portfolios.getAssets()`
     * @param account The address of the token holder
     * @param id ID of the token
     * @return The account's balance of the token type requested
     */
    function balanceOf(address account, uint256 id) external override view returns (uint256) {
        bytes1 assetType = Common.getAssetType(id);

        (uint8 cashGroupId, uint16 instrumentId, uint32 maturity) = Common.decodeAssetId(id);
        (Common.Asset memory asset, ) = Portfolios().searchAccountAsset(
            account,
            assetType,
            cashGroupId,
            instrumentId,
            maturity
        );

        return uint256(asset.notional);
    }

    /**
     * @notice Get the balance of multiple account/token pairs. For a more complete picture of an account's
     * portfolio, see the method `Portfolios.getAssets()`
     * @param accounts The addresses of the token holders
     * @param ids ID of the tokens
     * @return The account's balance of the token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        override
        view
        returns (uint256[] memory)
    {
        uint256[] memory results = new uint256[](accounts.length);

        for (uint256 i; i < accounts.length; i++) {
            results[i] = this.balanceOf(accounts[i], ids[i]);
        }

        return results;
    }

    /**
     * @notice Encodes a asset object into a uint256 id for ERC1155 compatibility
     * @param asset the asset object to encode
     * @return a uint256 id that is representative of a matching fungible token
     */
    function encodeAssetId(Common.Asset calldata asset) external pure returns (uint256) {
        return Common.encodeAssetId(asset);
    }

    /**
     * @notice Encodes a asset object into a uint256 id for ERC1155 compatibility
     * @param cashGroupId cash group id
     * @param instrumentId instrument id
     * @param maturity maturity of the asset
     * @param assetType asset type identifier
     * @return a uint256 id that is representative of a matching fungible token
     */
    function encodeAssetId(
        uint8 cashGroupId,
        uint16 instrumentId,
        uint32 maturity,
        bytes1 assetType
    ) external pure returns (uint256) {
        Common.Asset memory asset = Common.Asset(cashGroupId, instrumentId, maturity, assetType, 0, 0);

        return Common.encodeAssetId(asset);
    }

    /**
     * @notice Decodes an ERC1155 id into its attributes
     * @param id the asset id to decode
     * @return (cashGroupId, instrumentId, maturity, assetType)
     */
    function decodeAssetId(uint256 id)
        external
        pure
        returns (
            uint8,
            uint16,
            uint32,
            bytes1
        )
    {
        bytes1 assetType = Common.getAssetType(id);
        (uint8 cashGroupId, uint16 instrumentId, uint32 maturity) = Common.decodeAssetId(id);

        return (cashGroupId, instrumentId, maturity, assetType);
    }

    /**
     * @notice Sets approval for an operator to transfer tokens on the sender's behalf
     * @param operator address of the operator
     * @param approved true for complete appoval, false otherwise
     */
    function setApprovalForAll(address operator, bool approved) external override {
        operators[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @notice Determines if the operator is approved for the owner's account
     * @param owner address of the token holder
     * @param operator address of the operator
     * @return true for complete appoval, false otherwise
     */
    function isApprovedForAll(address owner, address operator) public override view returns (bool) {
        return operators[owner][operator];
    }
}

pragma solidity ^0.6.0;

// SPDX-License-Identifier: GPL-3.0-only
// SPDX-License-Identifier: MIT



/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity ^0.6.0;

// SPDX-License-Identifier: GPL-3.0-only



/**
    @title ERC-1155 Multi Token Standard
    @dev See https://eips.ethereum.org/EIPS/eip-1155
    Note: The ERC-165 identifier for this interface is 0xd9b67a26.
 */

interface IERC1155 {
    /* is IERC165 */
    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value
        transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer
        (SHOULD be msg.sender).
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_id` argument MUST be the token type being transferred.
        The `_value` argument MUST be the number of tokens the holder balance is decreased by and match what the
        recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
    */
    event TransferSingle(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256 _id,
        uint256 _value
    );

    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value
        transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer
        (SHOULD be msg.sender).
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_ids` argument MUST be the list of tokens being transferred.
        The `_values` argument MUST be the list of number of tokens (matching the list and order of tokens specified
        in _ids) the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
    */
    event TransferBatch(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256[] _ids,
        uint256[] _values
    );

    /**
        @dev MUST emit when approval for a second party/operator address to manage all tokens for an owner address
            is enabled or disabled (absence of an event assumes disabled).
    */
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /**
        @dev MUST emit when the URI is updated for a token ID.
        URIs are defined in RFC 3986.
        The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
    */
    event URI(string _value, uint256 indexed _id);

    /**
        @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified
        (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see
        "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section
        of the standard).
        After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code
        size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer
        Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _id      ID of the token type
        @param _value   Transfer amount
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to
            `onERC1155Received` on `_to`
    */
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;

    /**
        @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with
        safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval"
        section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if length of `_ids` is not the same as length of `_values`.
        MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective
        amount(s) in `_values` sent to the recipient.
        MUST revert on any other error.
        MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see
        "Safe Transfer Rules" section of the standard).
        Balance changes and events MUST follow the ordering of the arrays
            (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
        After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is
        a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on
        `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _ids     IDs of each token type (order and length must match _values array)
        @param _values  Transfer amounts per token type (order and length must match _ids array)
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to
            the `ERC1155TokenReceiver` hook(s) on `_to`
    */
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external;

    /**
        @notice Get the balance of an account's tokens.
        @param _owner  The address of the token holder
        @param _id     ID of the token
        @return        The _owner's balance of the token type requested
     */
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    /**
        @notice Get the balance of multiple account/token pairs
        @param _owners The addresses of the token holders
        @param _ids    ID of the tokens
        @return        The _owner's balance of the token types requested (i.e. balance for each
            (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
        external
        view
        returns (uint256[] memory);

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param _operator  Address to add to the set of authorized operators
        @param _approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param _owner     The owner of the tokens
        @param _operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

pragma solidity ^0.6.0;

// SPDX-License-Identifier: GPL-3.0-only



/**
    Note: The ERC-165 identifier for this interface is 0x4e2312e0.
*/

interface IERC1155TokenReceiver {
    /**
        @notice Handle the receipt of a single ERC1155 token type.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the
        end of a `safeTransferFrom` after the balance has been updated.
        This function MUST return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61) if it accepts the transfer.
        This function MUST revert if it rejects the transfer.
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction
        being reverted by the caller.
        @param _operator  The address which initiated the transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _id        The ID of the token being transferred
        @param _value     The amount of tokens being transferred
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    */
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data)
        external
        returns (bytes4);

    /**
        @notice Handle the receipt of multiple ERC1155 token types.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end
        of a `safeBatchTransferFrom` after the balances have been updated.
        This function MUST return
            `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
            (i.e. 0xbc197c81) if it accepts the transfer(s).
        This function MUST revert if it rejects the transfer(s).
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being
        reverted by the caller.
        @param _operator  The address which initiated the batch transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _ids       An array containing ids of each token being transferred (order and length must match
            _values array)
        @param _values    An array containing amounts of each token being transferred (order and length must match
            _ids array)
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    */
    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external returns (bytes4);
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: GPL-3.0-only



import "./utils/Common.sol";
import "./utils/ERC1155Base.sol";
import "./lib/SafeUInt128.sol";

import "./interface/IERC1155TokenReceiver.sol";

import "./CashMarket.sol";

/**
 * @notice Implements the ERC1155 token standard for trading OTC and batch operations over Notional markets.
 */
contract ERC1155Trade is ERC1155Base {
    using SafeUInt128 for uint128;
    address public BRIDGE_PROXY;

    struct TradeRecord {
        uint16 currencyId;
        Common.TradeType tradeType;
        uint128 cash;
    }

    /**
     * @notice Notice that a batch operation occured
     * @param account the account that was affected by the operation
     * @param operator the operator that sent the transaction
     */
    event BatchOperation(address indexed account, address indexed operator);

    /**
     * @notice Sets the address of the 0x bridgeProxy that is allowed to mint fCash pairs.
     * @dev governance
     * @param bridgeProxy address of the 0x ERC1155AssetProxy
     */
    function setBridgeProxy(address bridgeProxy) external onlyOwner {
        BRIDGE_PROXY = bridgeProxy;
    }

    /**
     * @notice Allows batch operations of deposits and trades. Approved operators are allowed to call this function
     * on behalf of accounts.
     * @dev - TRADE_FAILED_MAX_TIME: the operation will fail due to the set timeout
     * - UNAUTHORIZED_CALLER: operator is not authorized for the account
     * - INVALID_CURRENCY: currency specified in deposits is invalid
     * - MARKET_INACTIVE: maturity is not a valid one
     * - INSUFFICIENT_BALANCE: insufficient cash balance (or token balance when removing liquidity)
     * - INSUFFICIENT_FREE_COLLATERAL: account does not have enough free collateral to place the trade
     * - OVER_MAX_FCASH: [addLiquidity] fCash amount required exceeds supplied maxfCash
     * - OUT_OF_IMPLIED_RATE_BOUNDS: [addLiquidity] depositing collateral would require more fCash than specified
     * - TRADE_FAILED_TOO_LARGE: [takeCurrentCash, takefCash] trade is larger than allowed by the governance settings
     * - TRADE_FAILED_LACK_OF_LIQUIDITY: [takeCurrentCash, takefCash] there is insufficient liquidity in this maturity to handle the trade
     * - TRADE_FAILED_SLIPPAGE: [takeCurrentCash, takefCash] trade is greater than the max implied rate set
     * @param account account for which the operation will take place
     * @param maxTime after this time the operation will fail
     * @param deposits a list of deposits into the Escrow contract, ERC20 allowance must be in place for the Escrow contract
     * or these deposits will fail.
     * @param trades a list of trades to place on fCash markets
     */
    function batchOperation(
        address account,
        uint32 maxTime,
        Common.Deposit[] memory deposits,
        Common.Trade[] memory trades
    ) public payable {
        uint32 blockTime = uint32(block.timestamp);
        require(blockTime <= maxTime, "18");
        require(msg.sender == account || isApprovedForAll(account, msg.sender), "20");
        Portfolios().settleMaturedAssets(account);

        if (deposits.length > 0 || msg.value != 0) Escrow().depositsOnBehalf{value: msg.value}(account, deposits);
        if (trades.length > 0) _batchTrade(account, trades);

        // If there are only deposits then free collateral will only increase and we do not want to run a check against
        // it in case an account deposits collateral but is still undercollateralized
        if (trades.length > 0) {
            int256 fc = Portfolios().freeCollateralViewAggregateOnly(account);
            require(fc >= 0, "5");
        }

        emit BatchOperation(account, msg.sender);
    }

    /**
     * @notice Allows batch operations of deposits, trades and withdraws. Approved operators are allowed to call this function
     * on behalf of accounts.
     * @dev - TRADE_FAILED_MAX_TIME: the operation will fail due to the set timeout
     * - UNAUTHORIZED_CALLER: operator is not authorized for the account
     * - INVALID_CURRENCY: currency specified in deposits is invalid
     * - MARKET_INACTIVE: maturity is not a valid one
     * - INSUFFICIENT_BALANCE: insufficient cash balance (or token balance when removing liquidity)
     * - INSUFFICIENT_FREE_COLLATERAL: account does not have enough free collateral to place the trade
     * - OVER_MAX_FCASH: [addLiquidity] fCash amount required exceeds supplied maxfCash
     * - OUT_OF_IMPLIED_RATE_BOUNDS: [addLiquidity] depositing collateral would require more fCash than specified
     * - TRADE_FAILED_TOO_LARGE: [takeCurrentCash, takefCash] trade is larger than allowed by the governance settings
     * - TRADE_FAILED_LACK_OF_LIQUIDITY: [takeCurrentCash, takefCash] there is insufficient liquidity in this maturity to handle the trade
     * - TRADE_FAILED_SLIPPAGE: [takeCurrentCash, takefCash] trade is greater than the max implied rate set
     * @param account account for which the operation will take place
     * @param maxTime after this time the operation will fail
     * @param deposits a list of deposits into the Escrow contract, ERC20 allowance must be in place for the Escrow contract
     * or these deposits will fail.
     * @param trades a list of trades to place on fCash markets
     * @param withdraws a list of withdraws, if amount is set to zero will attempt to withdraw the account's entire balance
     * of the specified currency. This is useful for borrowing when the exact exchange rate is not known ahead of time.
     */
    function batchOperationWithdraw(
        address account,
        uint32 maxTime,
        Common.Deposit[] memory deposits,
        Common.Trade[] memory trades,
        Common.Withdraw[] memory withdraws
    ) public payable {
        uint32 blockTime = uint32(block.timestamp);
        require(blockTime <= maxTime, "18");
        require(msg.sender == account || isApprovedForAll(account, msg.sender), "20");
        Portfolios().settleMaturedAssets(account);

        TradeRecord[] memory tradeRecord;
        if (deposits.length > 0 || msg.value != 0) Escrow().depositsOnBehalf{value: msg.value}(account, deposits);
        if (trades.length > 0) tradeRecord = _batchTrade(account, trades);
        if (withdraws.length > 0) {
            if (tradeRecord.length > 0) {
                _updateWithdrawsWithTradeRecord(tradeRecord, deposits, withdraws);
            }

            Escrow().withdrawsOnBehalf(account, withdraws);
        }

        int256 fc = Portfolios().freeCollateralViewAggregateOnly(account);
        require(fc >= 0, "5");

        emit BatchOperation(account, msg.sender);
    }

    /**
     * @notice Transfers tokens between from and to addresses.
     * @dev - UNAUTHORIZED_CALLER: calling contract must be approved by both from / to addresses or be the 0x proxy
     * - OVER_MAX_UINT128_AMOUNT: amount specified cannot be greater than MAX_UINT128
     * - INVALID_SWAP: the asset id specified can only be of CASH_PAYER or CASH_RECEIVER types
     * - INVALID_CURRENCY: the currency id specified is invalid
     * - INVALID_CURRENCY: the currency id specified is invalid
     * @param from Source address
     * @param to Target address
     * @param id ID of the token type
     * @param value Transfer amount
     * @param data Additional data with no specified format, unused by this contract but forwarded unaltered
     * to the ERC1155TokenReceiver.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override {
        require(
            msg.sender == BRIDGE_PROXY ||
            (from == msg.sender && isApprovedForAll(to, from)) ||
            (isApprovedForAll(from, msg.sender) && isApprovedForAll(to, msg.sender)),
            "20"
        );
        require(value <= Common.MAX_UINT_128, "44");


        Common.Deposit[] memory deposits;
        if (data.length > 0) deposits = abi.decode(data, (Common.Deposit[]));

        bytes1 assetType = Common.getAssetType(id);
        (uint8 cashGroupId, /* uint16 */ , uint32 maturity) = Common.decodeAssetId(id);

        if (Common.isCashPayer(assetType)) {
            // (payer, receiver) = (to, from);
            if (data.length > 0) Escrow().depositsOnBehalf(to, deposits);

            // This does a free collateral check inside.
            Portfolios().mintfCashPair(to, from, cashGroupId, maturity, uint128(value));
        } else if (Common.isCashReceiver(assetType)) {
            // (payer, receiver) = (from, to);
            if (data.length > 0) Escrow().depositsOnBehalf(from, deposits);

            // This does a free collateral check inside.
            Portfolios().mintfCashPair(from, to, cashGroupId, maturity, uint128(value));
        } else {
            revert("7");
        }

        emit TransferSingle(msg.sender, from, to, id, value);
    }

    function safeBatchTransferFrom(
        address /* _from */,
        address /* _to */,
        uint256[] calldata /* _ids */,
        uint256[] calldata /* _values */,
        bytes calldata /* _data */
    ) external override {
        revert("22");
    }

    /**
     * @notice Decodes the slippage data parameter and places trades on the cash groups
     */
    function _batchTrade(address account, Common.Trade[] memory trades) internal returns (TradeRecord[] memory) {
        TradeRecord[] memory tradeRecord = new TradeRecord[](trades.length);

        for (uint256 i; i < trades.length; i++) {
            Common.CashGroup memory fcg = Portfolios().getCashGroup(trades[i].cashGroup);
            CashMarket fc = CashMarket(fcg.cashMarket);

            if (trades[i].tradeType == Common.TradeType.TakeCurrentCash) {
                uint32 maxRate;
                if (trades[i].slippageData.length == 32) {
                    maxRate = abi.decode(trades[i].slippageData, (uint32));
                } else {
                    maxRate = Common.MAX_UINT_32;
                }

                tradeRecord[i].currencyId = fcg.currency;
                tradeRecord[i].tradeType = Common.TradeType.TakeCurrentCash;
                tradeRecord[i].cash = fc.takeCurrentCashOnBehalf(account, trades[i].maturity, trades[i].amount, maxRate);
            } else if (trades[i].tradeType == Common.TradeType.TakefCash) {
                uint32 minRate;
                if (trades[i].slippageData.length == 32) {
                    minRate = abi.decode(trades[i].slippageData, (uint32));
                }

                tradeRecord[i].currencyId = fcg.currency;
                tradeRecord[i].tradeType = Common.TradeType.TakefCash;
                tradeRecord[i].cash = fc.takefCashOnBehalf(account, trades[i].maturity, trades[i].amount, minRate);
            } else if (trades[i].tradeType == Common.TradeType.AddLiquidity) {
                uint32 minRate;
                uint32 maxRate;
                uint128 maxfCash;
                if (trades[i].slippageData.length == 64) {
                    (minRate, maxRate) = abi.decode(trades[i].slippageData, (uint32, uint32));
                    maxfCash = Common.MAX_UINT_128;
                } else if (trades[i].slippageData.length == 96) {
                    (minRate, maxRate, maxfCash) = abi.decode(trades[i].slippageData, (uint32, uint32, uint128));
                } else {
                    maxRate = Common.MAX_UINT_32;
                    maxfCash = Common.MAX_UINT_128;
                }

                // Add Liquidity always adds the specified amount of cash or it fails out.
                tradeRecord[i].currencyId = fcg.currency;
                tradeRecord[i].tradeType = Common.TradeType.AddLiquidity;
                tradeRecord[i].cash = trades[i].amount;
                fc.addLiquidityOnBehalf(account, trades[i].maturity, trades[i].amount, maxfCash, minRate, maxRate);
            } else if (trades[i].tradeType == Common.TradeType.RemoveLiquidity) {
                tradeRecord[i].currencyId = fcg.currency;
                tradeRecord[i].tradeType = Common.TradeType.RemoveLiquidity;
                tradeRecord[i].cash = fc.removeLiquidityOnBehalf(account, trades[i].maturity, trades[i].amount);
            }
        }

        return tradeRecord;
    }

    function _updateWithdrawsWithTradeRecord(
        TradeRecord[] memory tradeRecord,
        Common.Deposit[] memory deposits,
        Common.Withdraw[] memory withdraws
    ) internal pure {
        // We look for records of withdraw.amount == 0 in order to update the amount for the
        // residuals from the trade record.
        for (uint256 i; i < withdraws.length; i++) {
            if (withdraws[i].amount == 0) {
                withdraws[i].amount = _calculateWithdrawAmount(
                    withdraws[i].currencyId,
                    tradeRecord,
                    deposits
                );
            }
        }
    }

    function _calculateWithdrawAmount(
        uint16 currencyId,
        TradeRecord[] memory tradeRecord,
        Common.Deposit[] memory deposits
    ) internal pure returns (uint128) {
        uint128 depositResidual;

        for (uint256 i; i < deposits.length; i++) {
            if (deposits[i].currencyId == currencyId) {
                // First seek the deposit array to find the deposit residual
                depositResidual = deposits[i].amount;
                break;
            }
        }

        for (uint256 i; i < tradeRecord.length; i++) {
            if (tradeRecord[i].currencyId != currencyId) continue;

            if (tradeRecord[i].tradeType == Common.TradeType.TakeCurrentCash
                || tradeRecord[i].tradeType == Common.TradeType.RemoveLiquidity) {
                // This is the amount of cash that was taken from the market
                depositResidual = depositResidual.add(tradeRecord[i].cash);
            } else if (tradeRecord[i].tradeType == Common.TradeType.TakefCash
                || tradeRecord[i].tradeType == Common.TradeType.AddLiquidity) {
                // This is the residual from the deposit that was not put into the market. We floor this value at
                // zero to avoid an overflow.
                depositResidual = depositResidual < tradeRecord[i].cash ? 0 : depositResidual - tradeRecord[i].cash;
            }
        }

        return depositResidual;
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: GPL-3.0-only



import "./utils/Governed.sol";
import "./utils/Liquidation.sol";

import "./lib/SafeInt256.sol";
import "./lib/SafeMath.sol";
import "./lib/SafeUInt128.sol";
import "./lib/SafeERC20.sol";

import "./interface/IERC20.sol";
import "./interface/IERC777.sol";
import "./interface/IERC777Recipient.sol";
import "./interface/IERC1820Registry.sol";
import "./interface/IAggregator.sol";
import "./interface/IEscrowCallable.sol";
import "./interface/IWETH.sol";

import "./storage/EscrowStorage.sol";
import "@openzeppelin/contracts/utils/SafeCast.sol";

/**
 * @title Escrow
 * @notice Manages a account balances for the entire system including deposits, withdraws,
 * cash balances, collateral lockup for trading, cash transfers (settlement), and liquidation.
 */
contract Escrow is EscrowStorage, Governed, IERC777Recipient, IEscrowCallable {
    using SafeUInt128 for uint128;
    using SafeMath for uint256;
    using SafeInt256 for int256;

    uint256 private constant UINT256_MAX = 2**256 - 1;

    /**
     * @dev skip
     * @param directory reference to other contracts
     * @param registry ERC1820 registry for ERC777 token standard
     */
    function initialize(
        address directory,
        address owner,
        address registry,
        address weth
    ) external initializer {
        Governed.initialize(directory, owner);

        // This registry call is used for the ERC777 token standard.
        IERC1820Registry(registry).setInterfaceImplementer(address(0), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));

        // List ETH as the zero currency
        WETH = weth;
        currencyIdToAddress[0] = WETH;
        addressToCurrencyId[WETH] = 0;
        currencyIdToDecimals[0] = Common.DECIMALS;
        emit NewCurrency(WETH);
    }

    /********** Events *******************************/

    /**
     * @notice A new currency
     * @param token address of the tradable token
     */
    event NewCurrency(address indexed token);

    /**
     * @notice A new exchange rate between two currencies
     * @param base id of the base currency
     * @param quote id of the quote currency
     */
    event UpdateExchangeRate(uint16 indexed base, uint16 indexed quote);

    /**
     * @notice Notice of a deposit made to an account
     * @param currency currency id of the deposit
     * @param account address of the account where the deposit was made
     * @param value amount of tokens deposited
     */
    event Deposit(uint16 indexed currency, address account, uint256 value);

    /**
     * @notice Notice of a withdraw from an account
     * @param currency currency id of the withdraw
     * @param account address of the account where the withdraw was made
     * @param value amount of tokens withdrawn
     */
    event Withdraw(uint16 indexed currency, address account, uint256 value);

    /**
     * @notice Notice of a successful liquidation. `msg.sender` will be the liquidator.
     * @param localCurrency currency that was liquidated
     * @param collateralCurrency currency that was exchanged for the local currency
     * @param account the account that was liquidated
     * @param amountRecollateralized the amount of local currency that recollateralized
     */
    event Liquidate(uint16 indexed localCurrency, uint16 collateralCurrency, address account, uint128 amountRecollateralized);

    /**
     * @notice Notice of a successful batch liquidation. `msg.sender` will be the liquidator.
     * @param localCurrency currency that was liquidated
     * @param collateralCurrency currency that was exchanged for the local currency
     * @param accounts the accounts that were liquidated
     * @param amountRecollateralized the amount of local currency that recollateralized
     */
    event LiquidateBatch(
        uint16 indexed localCurrency,
        uint16 collateralCurrency,
        address[] accounts,
        uint128[] amountRecollateralized
    );

    /**
     * @notice Notice of a successful cash settlement. `msg.sender` will be the settler.
     * @param localCurrency currency that was settled
     * @param collateralCurrency currency that was exchanged for the local currency
     * @param payer the account that paid in the settlement
     * @param settledAmount the amount settled between the parties
     */
    event SettleCash(
        uint16 localCurrency,
        uint16 collateralCurrency,
        address indexed payer,
        uint128 settledAmount
    );

    /**
     * @notice Notice of a successful batch cash settlement. `msg.sender` will be the settler.
     * @param localCurrency currency that was settled
     * @param collateralCurrency currency that was exchanged for the local currency
     * @param payers the accounts that paid in the settlement
     * @param settledAmounts the amounts settled between the parties
     */
    event SettleCashBatch(
        uint16 localCurrency,
        uint16 collateralCurrency,
        address[] payers,
        uint128[] settledAmounts
    );

    /**
     * @notice Emitted when liquidation and settlement discounts are set
     * @param liquidationDiscount discount given to liquidators when purchasing collateral
     * @param settlementDiscount discount given to settlers when purchasing collateral
     * @param repoIncentive incentive given to liquidators for pulling liquidity tokens to recollateralize an account
     */
    event SetDiscounts(uint128 liquidationDiscount, uint128 settlementDiscount, uint128 repoIncentive);

    /**
     * @notice Emitted when reserve account is set
     * @param reserveAccount account that holds balances in reserve
     */
    event SetReserve(address reserveAccount);

    /********** Events *******************************/

    /********** Governance Settings ******************/

    /**
     * @notice Sets a local cached version of the G_LIQUIDITY_HAIRCUT on the RiskFramework contract. This will be
     * used locally in the settlement and liquidation calculations when we pull local currency liquidity tokens.
     * @dev skip
     */
    function setLiquidityHaircut(uint128 haircut) external override {
        require(calledByPortfolios(), "20");
        EscrowStorageSlot._setLiquidityHaircut(haircut);
    }

    /**
     * @notice Sets discounts applied when purchasing collateral during liquidation or settlement. Discounts are
     * represented as percentages multiplied by 1e18. For example, a 5% discount for liquidators will be set as
     * 1.05e18
     * @dev governance
     * @param liquidation discount applied to liquidation
     * @param settlement discount applied to settlement
     * @param repoIncentive incentive to repo liquidity tokens
     */
    function setDiscounts(uint128 liquidation, uint128 settlement, uint128 repoIncentive) external onlyOwner {
        EscrowStorageSlot._setLiquidationDiscount(liquidation);
        EscrowStorageSlot._setSettlementDiscount(settlement);
        EscrowStorageSlot._setLiquidityTokenRepoIncentive(repoIncentive);

        emit SetDiscounts(liquidation, settlement, repoIncentive);
    }

    /**
     * @notice Sets the reserve account used to settle against for insolvent accounts
     * @dev governance
     * @param account address of reserve account
     */
    function setReserveAccount(address account) external onlyOwner {
        G_RESERVE_ACCOUNT = account;

        emit SetReserve(account);
    }

    /**
     * @notice Lists a new currency for deposits
     * @dev governance
     * @param token address of ERC20 or ERC777 token to list
     * @param options a set of booleans that describe the token
     */
    function listCurrency(address token, TokenOptions memory options) public onlyOwner {
        require(addressToCurrencyId[token] == 0 && token != WETH, "19");

        maxCurrencyId++;
        // We don't do a lot of checking here but since this is purely an administrative
        // activity we just rely on governance not to set this improperly.
        currencyIdToAddress[maxCurrencyId] = token;
        addressToCurrencyId[token] = maxCurrencyId;
        tokenOptions[token] = options;
        uint256 decimals = IERC20(token).decimals();
        currencyIdToDecimals[maxCurrencyId] = 10**(decimals);
        // We need to set this number so that the free collateral check can provision
        // the right number of currencies.
        Portfolios().setNumCurrencies(maxCurrencyId);

        emit NewCurrency(token);
    }

    /**
     * @notice Creates an exchange rate between two currencies.
     * @dev governance
     * @param base the base currency
     * @param quote the quote currency
     * @param rateOracle the oracle that will give the exchange rate between the two
     * @param buffer multiple to apply to the exchange rate that sets the collateralization ratio
     * @param rateDecimals decimals of precision that the rate oracle uses
     * @param mustInvert true if the chainlink oracle must be inverted
     */
    function addExchangeRate(
        uint16 base,
        uint16 quote,
        address rateOracle,
        uint128 buffer,
        uint128 rateDecimals,
        bool mustInvert
    ) external onlyOwner {
        // We require that exchange rate buffers are always greater than the settlement discount. The reason is
        // that if this is not the case, it opens up the possibility that free collateral actually ends up in a worse
        // position in the event of a third party settlement.
        require(buffer > G_SETTLEMENT_DISCOUNT(), "49");
        exchangeRateOracles[base][quote] = ExchangeRate.Rate(
            rateOracle,
            rateDecimals,
            mustInvert,
            buffer
        );

        emit UpdateExchangeRate(base, quote);
    }

    /********** Governance Settings ******************/

    /********** Getter Methods ***********************/

    /**
     * @notice Evaluates whether or not a currency id is valid
     * @param currency currency id
     * @return true if the currency is valid
     */
    function isValidCurrency(uint16 currency) public override view returns (bool) {
        return currency <= maxCurrencyId;
    }

    /**
     * @notice Getter method for exchange rates
     * @param base token address for the base currency
     * @param quote token address for the quote currency
     * @return ExchangeRate struct
     */
    function getExchangeRate(uint16 base, uint16 quote) external view returns (ExchangeRate.Rate memory) {
        return exchangeRateOracles[base][quote];
    }

    /**
     * @notice Returns the net balances of all the currencies owned by an account as
     * an array. Each index of the array refers to the currency id.
     * @param account the account to query
     * @return the balance of each currency net of the account's cash position
     */
    function getBalances(address account) external override view returns (int256[] memory) {
        // We add one here because the zero currency index is unused
        int256[] memory balances = new int256[](maxCurrencyId + 1);

        for (uint256 i; i < balances.length; i++) {
            balances[i] = cashBalances[uint16(i)][account];
        }

        return balances;
    }

    /**
     * @notice Converts the balances given to ETH for the purposes of determining whether an account has
     * sufficient free collateral.
     * @dev - INVALID_CURRENCY: length of the amounts array must match the total number of currencies
     *  - INVALID_EXCHANGE_RATE: exchange rate returned by the oracle is less than 0
     * @param amounts the balance in each currency group as an array, each index refers to the currency group id.
     * @return an array the same length as amounts with each balance denominated in ETH
     */
    function convertBalancesToETH(int256[] memory amounts) public override view returns (int256[] memory) {
        // We expect values for all currencies to be supplied here, we will not do any work on 0 balances.
        require(amounts.length == maxCurrencyId + 1, "19");
        int256[] memory results = new int256[](amounts.length);

        // Currency ID = 0 is already ETH so we don't need to convert it, unless it is negative. Then we will
        // haircut it.
        if (amounts[0] < 0) {
            // We store the ETH buffer on the exchange rate back to itself.
            uint128 buffer = exchangeRateOracles[0][0].buffer;
            results[0] = amounts[0].mul(buffer).div(Common.DECIMALS);
        } else {
            results[0] = amounts[0];
        }

        for (uint256 i = 1; i < amounts.length; i++) {
            if (amounts[i] == 0) continue;

            ExchangeRate.Rate memory er = exchangeRateOracles[uint16(i)][0];
            uint256 baseDecimals = currencyIdToDecimals[uint16(i)];

            if (amounts[i] < 0) {
                // We buffer negative amounts to enforce collateralization ratios
                results[i] = ExchangeRate._convertToETH(er, baseDecimals, amounts[i], true);
            } else {
                // We do not buffer positive amounts so that they can be used to collateralize
                // other debts.
                results[i] = ExchangeRate._convertToETH(er, baseDecimals, amounts[i], false);
            }
        }

        return results;
    }

    /********** Getter Methods ***********************/

    /********** Withdraw / Deposit Methods ***********/

    /**
     * @notice receive fallback for WETH transfers
     * @dev skip
     */
    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    /**
     * @notice This is a special function to handle ETH deposits. Value of ETH to be deposited must be specified in `msg.value`
     * @dev - OVER_MAX_ETH_BALANCE: balance of deposit cannot overflow uint128
     */
    function depositEth() external payable {
        _depositEth(msg.sender);
    }

    function _depositEth(address to) internal {
        require(msg.value <= Common.MAX_UINT_128, "27");
        IWETH(WETH).deposit{value: msg.value}();

        cashBalances[0][to] = cashBalances[0][to].add(
            uint128(msg.value)
        );
        emit Deposit(0, to, msg.value);
    }

    /**
     * @notice Withdraw ETH from the contract.
     * @dev - INSUFFICIENT_BALANCE: not enough balance in account
     * - INSUFFICIENT_FREE_COLLATERAL: not enough free collateral to withdraw
     * - TRANSFER_FAILED: eth transfer did not return success
     * @param amount the amount of eth to withdraw from the contract
     */
    function withdrawEth(uint128 amount) external {
        _withdrawEth(msg.sender, amount);
    }

    function _withdrawEth(address to, uint128 amount) internal {
        int256 balance = cashBalances[0][to];
        cashBalances[0][to] = balance.subNoNeg(amount);
        require(_freeCollateral(to) >= 0, "5");

        IWETH(WETH).withdraw(uint256(amount));
        // solium-disable-next-line security/no-call-value
        (bool success, ) = to.call{value: amount}("");
        require(success, "9");
        emit Withdraw(0, to, amount);
    }

    /**
     * @notice Transfers a balance from an ERC20 token contract into the Escrow. Do not call this for ERC777 transfers, use
     * the `send` method instead.
     * @dev - INVALID_CURRENCY: token address supplied is not a valid currency
     * @param token token contract to send from
     * @param amount tokens to transfer
     */
    function deposit(address token, uint128 amount) external {
        _deposit(msg.sender, token, amount);
    }

    function _deposit(address from, address token, uint128 amount) internal {
        uint16 currencyId = addressToCurrencyId[token];
        if ((currencyId == 0 && token != WETH)) {
            revert("19");
        }

        TokenOptions memory options = tokenOptions[token];
        amount = _tokenDeposit(token, from, amount, options);
        if (!options.isERC777) cashBalances[currencyId][from] = cashBalances[currencyId][from].add(amount);

        emit Deposit(currencyId, from, amount);
    }

    function _tokenDeposit(
        address token,
        address from,
        uint128 amount,
        TokenOptions memory options
    ) internal returns (uint128) {
        if (options.hasTransferFee) {
            // If there is a transfer fee we check the pre and post transfer balance to ensure that we increment
            // the balance by the correct amount after transfer.
            uint256 preTransferBalance = IERC20(token).balanceOf(address(this));
            SafeERC20.safeTransferFrom(IERC20(token), from, address(this), amount);
            uint256 postTransferBalance = IERC20(token).balanceOf(address(this));

            amount = SafeCast.toUint128(postTransferBalance.sub(preTransferBalance));
        } else if (options.isERC777) {
            IERC777(token).operatorSend(from, address(this), amount, "0x", "0x");
        }else {
            SafeERC20.safeTransferFrom(IERC20(token), from, address(this), amount);
        }
        
        return amount;
    }

    /**
     * @notice Withdraws from an account's collateral holdings back to their account. Checks if the
     * account has sufficient free collateral after the withdraw or else it fails.
     * @dev - INSUFFICIENT_BALANCE: not enough balance in account
     * - INVALID_CURRENCY: token address supplied is not a valid currency
     * - INSUFFICIENT_FREE_COLLATERAL: not enough free collateral to withdraw
     * @param token collateral type to withdraw
     * @param amount total value to withdraw
     */
    function withdraw(address token, uint128 amount) external {
       bool didWithdraw = _withdraw(msg.sender, msg.sender, token, amount, true);
       require(didWithdraw, "8");
    }

    function _withdraw(
        address from,
        address to,
        address token,
        uint128 amount,
        bool checkFC
    ) internal returns (bool) {
        uint16 currencyId = addressToCurrencyId[token];
        bool didWithdraw = false;
        require(token != address(0), "19");

        // We settle matured assets before withdraw in case there are matured cash receiver or liquidity
        // token assets
        if (checkFC) Portfolios().settleMaturedAssets(from);

        int256 balance = cashBalances[currencyId][from];
        if (balance > 0) {
            if (balance < amount) {
                amount = uint128(balance);
            }
            cashBalances[currencyId][from] = balance.subNoNeg(amount);
            didWithdraw = true;
        }

        // We're checking this after the withdraw has been done on currency balances. We skip this check
        // for batch withdraws when we check once after everything is completed.
        if (checkFC) {
            int256 fc = Portfolios().freeCollateralViewAggregateOnly(from);
            require(fc >= 0, "5");
        }

        if (didWithdraw) {
            _tokenWithdraw(token, to, amount);
            emit Withdraw(currencyId, to, amount);
        }

        return didWithdraw;
    }

    function _tokenWithdraw(
        address token,
        address to,
        uint128 amount
    ) internal {
        if (tokenOptions[token].isERC777) {
            IERC777(token).send(to, amount, "0x");
        } else {
            SafeERC20.safeTransfer(IERC20(token), to, amount);
        }
    }

    /**
     * @notice Deposits on behalf of an account, called via the ERC1155 batchOperation and bridgeTransferFrom.
     * @dev skip
     */
    function depositsOnBehalf(address account, Common.Deposit[] memory deposits) public payable override {
        require(calledByERC1155Trade(), "20");

        if (msg.value != 0) {
            _depositEth(account);
        }

        for (uint256 i; i < deposits.length; i++) {
            address tokenAddress = currencyIdToAddress[deposits[i].currencyId];
            _deposit(account, tokenAddress, deposits[i].amount);
        }
    }

    /**
     * @notice Withdraws on behalf of an account, called via the ERC1155 batchOperation and bridgeTransferFrom. Note that
     * this does not handle non-WETH withdraws.
     * @dev skip
     */
    function withdrawsOnBehalf(address account, Common.Withdraw[] memory withdraws) public override {
        require(calledByERC1155Trade(), "20");

        for (uint256 i; i < withdraws.length; i++) {
            address tokenAddress = currencyIdToAddress[withdraws[i].currencyId];
            uint128 amount;

            if (withdraws[i].amount == 0) {
                // If the amount is zero then we skip.
                continue;
            } else {
                amount = withdraws[i].amount;
            }

            // We skip the free collateral check here because ERC1155.batchOperation will do the check
            // before it exits.
            _withdraw(account, withdraws[i].to, tokenAddress, amount, false);
        }
    }

    /**
     * @notice Receives tokens from an ERC777 send message.
     * @dev skip
     * @param from address the tokens are being sent from (!= msg.sender)
     * @param amount amount
     */
    function tokensReceived(
        address, /*operator*/
        address from,
        address, /*to*/
        uint256 amount,
        bytes calldata, /*userData*/
        bytes calldata /*operatorData*/
    ) external override {
        uint16 currencyId = addressToCurrencyId[msg.sender];
        require(currencyId != 0, "19");
        cashBalances[currencyId][from] = cashBalances[currencyId][from].add(SafeCast.toUint128(amount));

        emit Deposit(currencyId, from, amount);
    }

    /********** Withdraw / Deposit Methods ***********/

    /********** Cash Management *********/

    /**
     * @notice Transfers the cash required between the Market and the specified account. Cash
     * held by the Market is available to purchase in the liquidity pools.
     * @dev skip
     * @param account the account to withdraw collateral from
     * @param cashGroupId the cash group used to authenticate the fCash market
     * @param value the amount of collateral to deposit
     * @param fee the amount of `value` to pay as a fee
     */
    function depositIntoMarket(
        address account,
        uint8 cashGroupId,
        uint128 value,
        uint128 fee
    ) external override {
        // Only the fCash market is allowed to call this function.
        Common.CashGroup memory cg = Portfolios().getCashGroup(cashGroupId);
        require(msg.sender == cg.cashMarket, "20");

        if (fee > 0) {
            cashBalances[cg.currency][G_RESERVE_ACCOUNT] = cashBalances[cg.currency][G_RESERVE_ACCOUNT]
                .add(fee);
        }

        cashBalances[cg.currency][msg.sender] = cashBalances[cg.currency][msg.sender].add(value);
        int256 balance = cashBalances[cg.currency][account];
        cashBalances[cg.currency][account] = balance.subNoNeg(value.add(fee));
    }

    /**
     * @notice Transfers the cash required between the Market and the specified account. Cash
     * held by the Market is available to purchase in the liquidity pools.
     * @dev skip
     * @param account the account to withdraw cash from
     * @param cashGroupId the cash group used to authenticate the fCash market
     * @param value the amount of cash to deposit
     * @param fee the amount of `value` to pay as a fee
     */
    function withdrawFromMarket(
        address account,
        uint8 cashGroupId,
        uint128 value,
        uint128 fee
    ) external override {
        // Only the fCash market is allowed to call this function.
        Common.CashGroup memory cg = Portfolios().getCashGroup(cashGroupId);
        require(msg.sender == cg.cashMarket, "20");

        if (fee > 0) {
            cashBalances[cg.currency][G_RESERVE_ACCOUNT] = cashBalances[cg.currency][G_RESERVE_ACCOUNT]
                .add(fee);
        }

        cashBalances[cg.currency][account] = cashBalances[cg.currency][account].add(value.sub(fee));

        int256 balance = cashBalances[cg.currency][msg.sender];
        cashBalances[cg.currency][msg.sender] = balance.subNoNeg(value);
    }

    /**
     * @notice Adds or removes collateral from the fCash market when the portfolio is trading positions
     * as a result of settlement or liquidation.
     * @dev skip
     * @param currency the currency group of the collateral
     * @param cashMarket the address of the fCash market to transfer between
     * @param amount the amount to transfer
     */
    function unlockCurrentCash(
        uint16 currency,
        address cashMarket,
        int256 amount
    ) external override {
        require(calledByPortfolios(), "20");

        // The methods that calls this function will handle management of the collateral that is added or removed from
        // the market.
        int256 balance = cashBalances[currency][cashMarket];
        cashBalances[currency][cashMarket] = balance.subNoNeg(amount);
    }

    /**
     * @notice Can only be called by Portfolios when assets are settled to cash. There is no free collateral
     * check for this function call because asset settlement is an equivalent transformation of a asset
     * to a net cash value. An account's free collateral position will remain unchanged after settlement.
     * @dev skip
     * @param account account where the cash is settled
     * @param settledCash an array of the currency groups that need to have their cash balance updated
     */
    function portfolioSettleCash(address account, int256[] calldata settledCash) external override {
        require(calledByPortfolios(), "20");
        // Since we are using the indexes to refer to the currency group ids, the length must be less than
        // or equal to the total number of group ids currently used plus the zero currency which is unused.
        require(settledCash.length == maxCurrencyId + 1, "19");

        for (uint256 i = 0; i < settledCash.length; i++) {
            if (settledCash[i] != 0) {
                // Update the balance of the appropriate currency group. We've validated that this conversion
                // to uint16 will not overflow with the require statement above.
                cashBalances[uint16(i)][account] = cashBalances[uint16(i)][account].add(settledCash[i]);
            }
        }
    }

    /********** Cash Management *********/

    /********** Settle Cash / Liquidation *************/

    /**
     * @notice Settles the cash balances of payers in batch
     * @dev - INVALID_CURRENCY: currency specified is invalid
     *  - INCORRECT_CASH_BALANCE: payer does not have sufficient cash balance to settle
     *  - INVALID_EXCHANGE_RATE: exchange rate returned by the oracle is less than 0
     *  - NO_EXCHANGE_LISTED_FOR_PAIR: cannot settle cash because no exchange is listed for the pair
     *  - INSUFFICIENT_COLLATERAL_FOR_SETTLEMENT: not enough collateral to settle on the exchange
     *  - RESERVE_ACCOUNT_HAS_INSUFFICIENT_BALANCE: settling requires the reserve account, but there is insufficient
     * balance to do so
     *  - INSUFFICIENT_COLLATERAL_BALANCE: account does not hold enough collateral to settle, they will have
     * additional collateral in a different currency if they are collateralized
     *  - INSUFFICIENT_FREE_COLLATERAL_SETTLER: calling account to settle cash does not have sufficient free collateral
     * after settling payers and receivers
     * @param localCurrency the currency that the payer's debts are denominated in
     * @param collateralCurrency the collateral to settle the debts against
     * @param payers the party that has a negative cash balance and will transfer collateral to the receiver
     * @param values the amount of collateral to transfer
     */
    function settleCashBalanceBatch(
        uint16 localCurrency,
        uint16 collateralCurrency,
        address[] calldata payers,
        uint128[] calldata values
    ) external {
        Liquidation.RateParameters memory rateParam = _validateCurrencies(localCurrency, collateralCurrency);

        uint128[] memory settledAmounts = new uint128[](values.length);
        uint128 totalCollateral;
        uint128 totalLocal;

        for (uint256 i; i < payers.length; i++) {
            uint128 local;
            uint128 collateral;
            (settledAmounts[i], local, collateral) = _settleCashBalance(
                payers[i],
                values[i],
                rateParam
            );

            totalCollateral = totalCollateral.add(collateral);
            totalLocal = totalLocal.add(local);
        }

        _finishLiquidateSettle(localCurrency, totalLocal);
        _finishLiquidateSettle(collateralCurrency, int256(totalCollateral).neg());
        emit SettleCashBatch(localCurrency, collateralCurrency, payers, settledAmounts);
    }

    /**
     * @notice Settles the cash balance between the payer and the receiver.
     * @dev - INCORRECT_CASH_BALANCE: payer or receiver does not have sufficient cash balance to settle
     *  - INVALID_EXCHANGE_RATE: exchange rate returned by the oracle is less than 0
     *  - NO_EXCHANGE_LISTED_FOR_PAIR: cannot settle cash because no exchange is listed for the pair
     *  - INSUFFICIENT_COLLATERAL_FOR_SETTLEMENT: not enough collateral to settle on the exchange
     *  - RESERVE_ACCOUNT_HAS_INSUFFICIENT_BALANCE: settling requires the reserve account, but there is insufficient
     * balance to do so
     *  - INSUFFICIENT_COLLATERAL_BALANCE: account does not hold enough collateral to settle, they will have
     *  - INSUFFICIENT_FREE_COLLATERAL_SETTLER: calling account to settle cash does not have sufficient free collateral
     * after settling payers and receivers
     * @param localCurrency the currency that the payer's debts are denominated in
     * @param collateralCurrency the collateral to settle the debts against
     * @param payer the party that has a negative cash balance and will transfer collateral to the receiver
     * @param value the amount of collateral to transfer
     */
    function settleCashBalance(
        uint16 localCurrency,
        uint16 collateralCurrency,
        address payer,
        uint128 value
    ) external {
        Liquidation.RateParameters memory rateParam = _validateCurrencies(localCurrency, collateralCurrency);

        (uint128 settledAmount, uint128 totalLocal, uint128 totalCollateral) = _settleCashBalance(payer, value, rateParam);

        _finishLiquidateSettle(localCurrency, totalLocal);
        _finishLiquidateSettle(collateralCurrency, int256(totalCollateral).neg());
        emit SettleCash(localCurrency, collateralCurrency, payer, settledAmount);
    }

    /**
     * @notice Settles the cash balance between the payer and the receiver.
     * @param payer the party that has a negative cash balance and will transfer collateral to the receiver
     * @param valueToSettle the amount of collateral to transfer
     * @param rateParam rate params for the liquidation library
     */
    function _settleCashBalance(
        address payer,
        uint128 valueToSettle,
        Liquidation.RateParameters memory rateParam
    ) internal returns (uint128, uint128, uint128) {
        require(payer != msg.sender, "48");
        if (valueToSettle == 0) return (0, 0, 0);
        Common.FreeCollateralFactors memory fc = _freeCollateralFactors(
            payer, 
            rateParam.localCurrency,
            rateParam.collateralCurrency
        );

        int256 payerLocalBalance = cashBalances[rateParam.localCurrency][payer];
        int256 payerCollateralBalance = cashBalances[rateParam.collateralCurrency][payer];

        // This cash account must have enough negative cash to settle against
        require(payerLocalBalance <= int256(valueToSettle).neg(), "21");

        Liquidation.TransferAmounts memory transfer = Liquidation.settle(
            payer,
            payerCollateralBalance,
            valueToSettle,
            fc,
            rateParam,
            address(Portfolios())
        );

        if (payerCollateralBalance != transfer.payerCollateralBalance) {
            cashBalances[rateParam.collateralCurrency][payer] = transfer.payerCollateralBalance;
        }

        if (transfer.netLocalCurrencyPayer > 0) {
            cashBalances[rateParam.localCurrency][payer] = payerLocalBalance.add(transfer.netLocalCurrencyPayer);
        }

        // This will not be negative in settle cash because we don't pay incentives for liquidity token extraction.
        require(transfer.netLocalCurrencyLiquidator >= 0);

        return (
            // Amount of balance settled
            transfer.netLocalCurrencyPayer,
            // Amount of local currency that liquidator needs to deposit
            uint128(transfer.netLocalCurrencyLiquidator),
            // Amount of collateral liquidator receives
            transfer.collateralTransfer
        );
    }

    /**
     * @notice Liquidates a batch of accounts in a specific currency. Final token balances will be withdrawn and deposited to
     * the liquidator's account.
     * @dev - CANNOT_LIQUIDATE_SUFFICIENT_COLLATERAL: account has positive free collateral and cannot be liquidated
     *  - CANNOT_LIQUIDATE_SELF: liquidator cannot equal the liquidated account
     *  - INSUFFICIENT_FREE_COLLATERAL_LIQUIDATOR: liquidator does not have sufficient free collateral after liquidating
     * accounts. This will only occur in situations where the liquidator must deposit a token that has a transaction fee.
     * @param accounts the account to liquidate
     * @param localCurrency the currency that is undercollateralized
     * @param collateralCurrency the collateral currency to exchange for `currency`
     */
    function liquidateBatch(
        address[] calldata accounts,
        uint16 localCurrency,
        uint16 collateralCurrency
    ) external {
        Liquidation.RateParameters memory rateParam = _validateCurrencies(localCurrency, collateralCurrency);

        uint128[] memory amountRecollateralized = new uint128[](accounts.length);
        int256 totalLocal;
        uint128 totalCollateral;

        for (uint256 i; i < accounts.length; i++) {
            int256 local;
            uint128 collateral;
            (amountRecollateralized[i], local, collateral) = _liquidate(accounts[i], rateParam, 0);
            totalLocal = totalLocal.add(local);
            totalCollateral = totalCollateral.add(collateral);
        }

        _finishLiquidateSettle(localCurrency, totalLocal);
        _finishLiquidateSettle(collateralCurrency, int256(totalCollateral).neg());
        emit LiquidateBatch(localCurrency, collateralCurrency, accounts, amountRecollateralized);
    }

    /**
     * @notice Liquidates a single account if it is undercollateralized. Optionally allows liquidation up until a certain
     * maximum amount. Tokens will be deposited and withdrawn from the liquidator's wallet balances.
     * @dev - CANNOT_LIQUIDATE_SUFFICIENT_COLLATERAL: account has positive free collateral and cannot be liquidated
     *  - CANNOT_LIQUIDATE_SELF: liquidator cannot equal the liquidated account
     *  - INSUFFICIENT_FREE_COLLATERAL_LIQUIDATOR: liquidator does not have sufficient free collateral after liquidating
     * accounts. This will only occur in situations where the liquidator must deposit a token that has a transaction fee.
     * @param account the account to liquidate
     * @param maxLiquidateAmount the maximum amount (in local currency terms) that should be liquidated, if set to zero will
     * liquidate up to the maximum allowed by the free collateral calculation
     * @param localCurrency the currency that is undercollateralized
     * @param collateralCurrency the collateral currency to exchange for `currency`
     */
    function liquidate(
        address account,
        uint128 maxLiquidateAmount,
        uint16 localCurrency,
        uint16 collateralCurrency
    ) external {
        Liquidation.RateParameters memory rateParam = _validateCurrencies(localCurrency, collateralCurrency);
        (uint128 amountRecollateralized, int256 totalLocal, uint128 totalCollateral) = _liquidate(account, rateParam, maxLiquidateAmount);

        _finishLiquidateSettle(localCurrency, totalLocal);
        _finishLiquidateSettle(collateralCurrency, int256(totalCollateral).neg());
        emit Liquidate(localCurrency, collateralCurrency, account, amountRecollateralized);
    }

    /** @notice Internal function for liquidating an account */
    function _liquidate(
        address payer,
        Liquidation.RateParameters memory rateParam,
        uint128 maxLiquidateAmount
    ) internal returns (uint128, int256, uint128) {
        require(payer != msg.sender, "40");

        Common.FreeCollateralFactors memory fc = _freeCollateralFactors(
            payer, 
            rateParam.localCurrency,
            rateParam.collateralCurrency
        );
        require(fc.aggregate < 0,  "12");

        // Getting the cashBalance must happen after the free collateral call because settleMaturedAssets may update cash balances.
        int256 balance = cashBalances[rateParam.collateralCurrency][payer];
        Liquidation.TransferAmounts memory transfer = Liquidation.liquidate(
            payer,
            balance,
            fc,
            rateParam,
            address(Portfolios()),
            maxLiquidateAmount
        );

        if (balance != transfer.payerCollateralBalance) {
            cashBalances[rateParam.collateralCurrency][payer] = transfer.payerCollateralBalance;
        }

        if (transfer.netLocalCurrencyPayer > 0) {
            cashBalances[rateParam.localCurrency][payer] = cashBalances[rateParam.localCurrency][payer].add(transfer.netLocalCurrencyPayer);
        }

        return (
            // local currency amount to payer
            transfer.netLocalCurrencyPayer,
            // net local currency transfer between escrow and liquidator
            transfer.netLocalCurrencyLiquidator,
            // collateral currency transfer to liquidator
            transfer.collateralTransfer
        );
    }

    /**
     * @notice Purchase fCash receiver asset in the portfolio. This can only be done if the account has no
     * other positive cash balances and no liquidity tokens in its portfolio. The fCash receiver would be its only
     * source of positive collateral. Notional will first attempt to sell fCash in CashMarkets before selling it to the liquidator
     * at a discount.
     * @param payer account that will pay fCash to settle current debts
     * @param localCurrency currency that current debts are denominated
     * @param collateralCurrency currency that fCash receivers are denominated in, it is possible for collateralCurrency to equal
     * localCurrency.
     * @param valueToSettle amount of local currency debts to settle
     */
    function settlefCash(
        address payer,
        uint16 localCurrency,
        uint16 collateralCurrency,
        uint128 valueToSettle
    ) external {
        Common.FreeCollateralFactors memory fc = _freeCollateralFactors(payer, localCurrency, collateralCurrency);
        require(fc.aggregate >= 0, "5");
        if (valueToSettle == 0) return;

        int256 payerLocalBalance = cashBalances[localCurrency][payer];

        // This cash payer must have enough negative cash to settle against
        require(payerLocalBalance <= int256(valueToSettle).neg(), "21");
        require(!_hasCollateral(payer), "55");

        int256 netCollateralCurrencyLiquidator;
        uint128 netLocalCurrencyPayer;
        if (localCurrency == collateralCurrency) {
            require(isValidCurrency(localCurrency), "19");
            // In this case we're just trading fCash in local currency, there is no currency conversion required and the execution is
            // fairly straightforward.
            (uint128 shortfall, uint128 liquidatorPayment) = Portfolios().raiseCurrentCashViaCashReceiver(
                payer,
                msg.sender,
                localCurrency,
                valueToSettle
            );

            netLocalCurrencyPayer = valueToSettle.sub(shortfall);
            // We have to re-read the balance here because raiseCurrentCashViaCashReceiver may put cash back into
            // balances as a result of selling off cash.
            cashBalances[localCurrency][payer] = cashBalances[localCurrency][payer].add(netLocalCurrencyPayer);
            // No collateral currency consideration in this case.
            _finishLiquidateSettle(localCurrency, liquidatorPayment);
        } else {
            Liquidation.RateParameters memory rateParam = _validateCurrencies(localCurrency, collateralCurrency);
            (netCollateralCurrencyLiquidator, netLocalCurrencyPayer) = Liquidation.settlefCash(
                payer,
                msg.sender,
                valueToSettle,
                fc.collateralNetAvailable,
                rateParam,
                address(Portfolios())
            );

            // We have to re-read the balance here because raiseCurrentCashViaCashReceiver may put cash back into
            // balances as a result of selling off cash.
            cashBalances[localCurrency][payer] = cashBalances[localCurrency][payer].add(netLocalCurrencyPayer);

            _finishLiquidateSettle(localCurrency, netLocalCurrencyPayer);
            _finishLiquidateSettle(collateralCurrency, netCollateralCurrencyLiquidator);
        }

        emit SettleCash(localCurrency, collateralCurrency, payer, netLocalCurrencyPayer);
    }

    /**
     * @notice Purchase fCash receiver assets in order to recollateralize a portfolio. Similar to `settlefCash`, this can only be done 
     * @param payer account that will pay fCash to settle current debts
     * @param localCurrency currency that current debts are denominated in
     * @param collateralCurrency currency that fCash receivers are denominated in. Unlike `settlfCash` it is not possible for localCurrency
     * to equal collateralCurrency because liquidating local currency fCash receivers will never help recollateralize a portfolio. Local currency
     * fCash receivers only accrue value as they get closer to maturity.
     */
    function liquidatefCash(
        address payer,
        uint16 localCurrency,
        uint16 collateralCurrency
    ) external {
        // This settles out matured assets for us before we enter the rest of the function
        Common.FreeCollateralFactors memory fc = _freeCollateralFactors(payer, localCurrency, collateralCurrency);
        require(!_hasCollateral(payer), "55");
        require(fc.aggregate < 0, "12");

        Liquidation.RateParameters memory rateParam = _validateCurrencies(localCurrency, collateralCurrency);

        (int256 netCollateralCurrencyLiquidator, uint128 netLocalCurrencyPayer) = Liquidation.liquidatefCash(
            payer,
            msg.sender,
            fc.aggregate,
            fc.localNetAvailable,
            fc.collateralNetAvailable,
            rateParam,
            address(Portfolios())
        );

        int256 payerLocalBalance = cashBalances[localCurrency][payer];
        cashBalances[localCurrency][payer] = payerLocalBalance.add(netLocalCurrencyPayer);

        _finishLiquidateSettle(localCurrency, netLocalCurrencyPayer);
        _finishLiquidateSettle(collateralCurrency, netCollateralCurrencyLiquidator);

        emit Liquidate(localCurrency, collateralCurrency, payer, netLocalCurrencyPayer);
    }

    /**
     * @notice Settles current debts in an account against the reserve. Only possible if an account is truly insolvent, meaning that it only holds debts and has
     * no remaining sources of positive collateral.
     * @param account account that is undercollateralized
     * @param localCurrency currency that current debts are denominated in
     */
    function settleReserve(
        address account,
        uint16 localCurrency
    ) external {
        Portfolios().settleMaturedAssets(account);
        require(!_hasCollateral(account), "55");
        require(_hasNoAssets(account), "55");
        int256 accountLocalBalance = cashBalances[localCurrency][account];
        int256 reserveLocalBalance = cashBalances[localCurrency][G_RESERVE_ACCOUNT];

        require(accountLocalBalance < 0, "21");

        if (accountLocalBalance.neg() < reserveLocalBalance) {
            cashBalances[localCurrency][account] = 0;
            cashBalances[localCurrency][G_RESERVE_ACCOUNT] = reserveLocalBalance.subNoNeg(accountLocalBalance.neg());
        } else {
            cashBalances[localCurrency][account] = accountLocalBalance.add(reserveLocalBalance);
            cashBalances[localCurrency][G_RESERVE_ACCOUNT] = 0;
        }
    }

    /********** Settle Cash / Liquidation *************/

    /********** Internal Methods *********************/

    /** @notice Validates currencies and returns their rate parameters object */
    function _validateCurrencies(
        uint16 localCurrency,
        uint16 collateralCurrency
    ) internal view returns (Liquidation.RateParameters memory) {
        require(isValidCurrency(localCurrency), "19");
        require(isValidCurrency(collateralCurrency), "19");
        require(localCurrency != collateralCurrency, "19");

        ExchangeRate.Rate memory baseER = exchangeRateOracles[localCurrency][0];
        ExchangeRate.Rate memory quoteER;
        if (collateralCurrency != 0) {
            // If collateralCurrency == 0 it is ETH and unused in the _exchangeRate function.
            quoteER = exchangeRateOracles[collateralCurrency][0];
        }
        uint256 rate = ExchangeRate._exchangeRate(baseER, quoteER, collateralCurrency);

        return Liquidation.RateParameters(
            rate,
            localCurrency,
            collateralCurrency,
            currencyIdToDecimals[localCurrency],
            currencyIdToDecimals[collateralCurrency],
            baseER
        );
    }

    function _finishLiquidateSettle(
        uint16 currency,
        int256 netAmount
    ) internal {
        address token = currencyIdToAddress[currency];
        if (netAmount > 0) {
            TokenOptions memory options = tokenOptions[token];
            if (options.hasTransferFee) {
                // If the token has transfer fees then we cannot use _tokenDeposit to get an accurate amount of local
                // currency. The liquidator must have a sufficient balance inside the system. When transferring collateral
                // internally within the system we must always check free collateral.
                cashBalances[currency][msg.sender] = cashBalances[currency][msg.sender].subNoNeg(netAmount);
                require(_freeCollateral(msg.sender) >= 0, "37");
            } else {
                _tokenDeposit(token, msg.sender, uint128(netAmount), options);
            }
        } else if (netAmount < 0) {
            _tokenWithdraw(token, msg.sender, uint128(netAmount.neg()));
        }
    }

    /**
     * @notice Internal method for calling free collateral.
     *
     * @param account the account to check free collateral for
     * @return amount of free collateral
     */
    function _freeCollateral(address account) internal returns (int256) {
        return Portfolios().freeCollateralAggregateOnly(account);
    }

    function _freeCollateralFactors(
        address account,
        uint16 localCurrency,
        uint16 collateralCurrency
    ) internal returns (Common.FreeCollateralFactors memory) {
        return Portfolios().freeCollateralFactors(account, localCurrency, collateralCurrency);
    }


    function _hasCollateral(address account) internal view returns (bool) {
        for (uint256 i; i <= maxCurrencyId; i++) {
            if (cashBalances[uint16(i)][account] > 0) {
                return true;
            }
        }

        return false;
    }

    function _hasNoAssets(address account) internal view returns (bool) {
        Common.Asset[] memory portfolio = Portfolios().getAssets(account);
        for (uint256 i; i < portfolio.length; i++) {
            // This may be cash receiver or liquidity tokens
            if (Common.isReceiver(portfolio[i].assetType)) {
                return false;
            }
        }

        return true;
    }
}

pragma solidity ^0.6.4;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: GPL-3.0-only



import "./Common.sol";
import "./ExchangeRate.sol";

import "../lib/SafeInt256.sol";
import "../lib/SafeMath.sol";
import "../lib/SafeUInt128.sol";

import "../interface/IPortfoliosCallable.sol";
import "../storage/EscrowStorage.sol";

import "@openzeppelin/contracts/utils/SafeCast.sol";

library Liquidation {
    using SafeMath for uint256;
    using SafeInt256 for int256;
    using SafeUInt128 for uint128;

    // This buffer is used to account for the potential of decimal truncation causing accounts to be
    // permanently undercollateralized.
    int256 public constant LIQUIDATION_BUFFER = 1.01e18;

    struct TransferAmounts {
        int256 netLocalCurrencyLiquidator;
        uint128 netLocalCurrencyPayer;
        uint128 collateralTransfer;
        int256 payerCollateralBalance;
    }

    struct CollateralCurrencyParameters {
        uint128 localCurrencyRequired;
        int256 localCurrencyAvailable;
        uint16 collateralCurrency;
        int256 collateralCurrencyCashClaim;
        int256 collateralCurrencyAvailable;
        uint128 discountFactor;
        uint128 liquidityHaircut;
        IPortfoliosCallable Portfolios;
    }

    struct RateParameters {
        uint256 rate;
        uint16 localCurrency;
        uint16 collateralCurrency;
        uint256 localDecimals;
        uint256 collateralDecimals;
        ExchangeRate.Rate localToETH;
    }

    /**
     * @notice Given an account that has liquidity tokens denominated in the currency, liquidates only enough to
     * recollateralize the account.
     * @param payer account that will be liquidated
     * @param localCurrency that the tokens will be denominated in
     * @param localCurrencyRequired the amount that we need to liquidate
     * @param liquidityHaircut the haircut on liquidity tokens
     * @param localCurrencyNetAvailable the amount of local currency we can liquidate up to
     * @param Portfolios the portfolio contract to call
     * @return (
     *   netLocalCurrencyLiquidator
     *   netLocalCurrencyPayer
     *   localCurrencyNetAvailable after the action,
     *   localCurrencyRequired after action
     *  )
     */
    function _liquidateLocalLiquidityTokens(
        address payer,
        uint16 localCurrency,
        uint128 localCurrencyRequired,
        uint128 liquidityHaircut,
        int256 localCurrencyNetAvailable,
        IPortfoliosCallable Portfolios
    ) internal returns (int256, uint128, int256, uint128) {
        // Calculate amount of liquidity tokens to withdraw and do the action.
        (uint128 cashClaimWithdrawn, uint128 localCurrencyRaised) = Liquidation._localLiquidityTokenTrade(
            payer,
            localCurrency,
            localCurrencyRequired,
            liquidityHaircut,
            Portfolios
        );

        // Calculates relevant parameters post trade.
        return _calculatePostTradeFactors(
            cashClaimWithdrawn,
            localCurrencyNetAvailable,
            localCurrencyRequired,
            localCurrencyRaised,
            liquidityHaircut
        );
    }

    /** @notice Trades liquidity tokens in order to attempt to raise `localCurrencyRequired` */
    function _localLiquidityTokenTrade(
        address account,
        uint16 currency,
        uint128 localCurrencyRequired,
        uint128 liquidityHaircut,
        IPortfoliosCallable Portfolios
    ) internal returns (uint128, uint128) {
        uint128 liquidityRepoIncentive = EscrowStorageSlot._liquidityTokenRepoIncentive();

        // We can only recollateralize the local currency using the part of the liquidity token that
        // between the pre-haircut cash claim and the post-haircut cash claim.
        // cashClaim - cashClaim * haircut = required * (1 + incentive)
        // cashClaim * (1 - haircut) = required * (1 + incentive)
        // cashClaim = required * (1 + incentive) / (1 - haircut)
        uint128 cashClaimsToTrade = SafeCast.toUint128(
            uint256(localCurrencyRequired)
                .mul(liquidityRepoIncentive)
                .div(Common.DECIMALS.sub(liquidityHaircut))
        );

        uint128 remainder = Portfolios.raiseCurrentCashViaLiquidityToken(
            account,
            currency,
            cashClaimsToTrade
        );

        uint128 localCurrencyRaised;
        uint128 cashClaimWithdrawn = cashClaimsToTrade.sub(remainder);
        if (remainder > 0) {
            // cashClaim = required * (1 + incentive) / (1 - haircut)
            // (cashClaim - remainder) = (required - delta) * (1 + incentive) / (1 - haircut)
            // cashClaimWithdrawn = (required - delta) * (1 + incentive) / (1 - haircut)
            // cashClaimWithdrawn * (1 - haircut) = (required - delta) * (1 + incentive)
            // cashClaimWithdrawn * (1 - haircut) / (1 + incentive) = (required - delta) = localCurrencyRaised
            localCurrencyRaised = SafeCast.toUint128(
                uint256(cashClaimWithdrawn)
                    .mul(Common.DECIMALS.sub(liquidityHaircut))
                    .div(liquidityRepoIncentive)
            );
        } else {
            localCurrencyRaised = localCurrencyRequired;
        }

        return (cashClaimWithdrawn, localCurrencyRaised);
    }

    function _calculatePostTradeFactors(
        uint128 cashClaimWithdrawn,
        int256 netCurrencyAvailable,
        uint128 localCurrencyRequired,
        uint128 localCurrencyRaised,
        uint128 liquidityHaircut
    ) internal pure returns (int256, uint128, int256, uint128) {
        // This is the portion of the cashClaimWithdrawn that is available to recollateralize the account.
        // cashClaimWithdrawn = value * (1 + incentive) / (1 - haircut)
        // cashClaimWithdrawn * (1 - haircut) = value * (1 + incentive)
        uint128 haircutClaimAmount = SafeCast.toUint128(
            uint256(cashClaimWithdrawn)
                .mul(Common.DECIMALS.sub(liquidityHaircut))
                .div(Common.DECIMALS)
        );


        // This is the incentive paid to the liquidator for extracting liquidity tokens.
        uint128 incentive = haircutClaimAmount.sub(localCurrencyRaised);

        return (
            int256(incentive).neg(),
            // This is what will be credited back to the account
            cashClaimWithdrawn.sub(incentive),
            // The haircutClaimAmount - incentive is added to netCurrencyAvailable because it is now recollateralizing the account. This
            // is used in the next step to guard against raising too much local currency (to the point where netCurrencyAvailable is positive)
            // such that additional local currency does not actually help the account's free collateral position.
            netCurrencyAvailable.add(haircutClaimAmount).sub(incentive),
            // The new local currency required is what we required before minus the amount we added to netCurrencyAvailable to
            // recollateralize the account in the previous step.
            localCurrencyRequired.add(incentive).sub(haircutClaimAmount)
        );
    }

    /**
     * @notice Liquidates an account, first attempting to extract liquidity tokens then moving on to collateral.
     * @param payer account that is being liquidated
     * @param payerCollateralBalance payer's collateral currency account balance
     * @param fc free collateral factors object
     * @param rateParam collateral currency exchange rate parameters
     * @param Portfolios address of portfolio contract to call
     */
    function liquidate(
        address payer,
        int256 payerCollateralBalance,
        Common.FreeCollateralFactors memory fc,
        RateParameters memory rateParam,
        address Portfolios,
        uint128 maxLiquidateAmount
    ) public returns (TransferAmounts memory) {
        uint128 localCurrencyRequired = _fcAggregateToLocal(fc.aggregate, rateParam);

        TransferAmounts memory transfer = TransferAmounts(0, 0, 0, payerCollateralBalance);
        uint128 liquidityHaircut = EscrowStorageSlot._liquidityHaircut();
        if (fc.localCashClaim > 0) {
            // Account has a local currency cash claim denominated in liquidity tokens. We first extract that here.
            (
                transfer.netLocalCurrencyLiquidator,
                transfer.netLocalCurrencyPayer,
                fc.localNetAvailable,
                localCurrencyRequired
            ) = _liquidateLocalLiquidityTokens(
                payer,
                rateParam.localCurrency,
                localCurrencyRequired,
                liquidityHaircut,
                fc.localNetAvailable,
                IPortfoliosCallable(Portfolios)
            );
        }


        // If we still require more local currency and we have debts in the local currency then we will trade
        // collateral currency for local currency here.
        if (localCurrencyRequired > 0 && fc.localNetAvailable < 0) {
            _liquidateCollateralCurrency(
                payer,
                localCurrencyRequired,
                liquidityHaircut,
                transfer,
                fc,
                rateParam,
                Portfolios,
                maxLiquidateAmount
            );
        }

        return transfer;
    }


    function _fcAggregateToLocal(
        int256 fcAggregate,
        RateParameters memory rateParam
    ) internal view returns (uint128) {
        // Safety check
        require(fcAggregate < 0);

        return uint128(
            ExchangeRate._convertETHTo(
                rateParam.localToETH,
                rateParam.localDecimals,
                fcAggregate.mul(LIQUIDATION_BUFFER).div(Common.DECIMALS).neg()
            )
        );
    }

    /**
     * @notice Settles current debts using collateral currency. First attempst to raise cash in local currency liquidity tokens before moving
     * on to collateral currency.
     * @param payer account that has current debts
     * @param payerCollateralBalance payer's collateral currency account balance
     * @param fc free collateral factors object
     * @param rateParam collateral currency exchange rate parameters
     * @param Portfolios address of portfolio contract to call
     */
    function settle(
        address payer,
        int256 payerCollateralBalance,
        uint128 valueToSettle,
        Common.FreeCollateralFactors memory fc,
        RateParameters memory rateParam,
        address Portfolios
    ) public returns (TransferAmounts memory) {
        TransferAmounts memory transfer = TransferAmounts(0, 0, 0, payerCollateralBalance);
        if (fc.localCashClaim > 0) {
            uint128 remainder = IPortfoliosCallable(Portfolios).raiseCurrentCashViaLiquidityToken(
                payer,
                rateParam.localCurrency,
                valueToSettle
            );

            transfer.netLocalCurrencyPayer = valueToSettle.sub(remainder);

            if (transfer.netLocalCurrencyPayer > fc.localCashClaim) {
                // If this is the case then we've raised cash that sits inside the haircut of the liquidity token
                // and it will add collateral to the account. We calculate these factors here before moving on.
                uint128 haircutAmount = transfer.netLocalCurrencyPayer.sub(uint128(fc.localCashClaim));

                int256 netFC = ExchangeRate._convertToETH(
                    rateParam.localToETH,
                    rateParam.localDecimals,
                    haircutAmount,
                    fc.localNetAvailable < 0
                );

                // This net fc calculation is not completely accurate because the haircut amount can move the FC from
                // negative to positive but that is irrelevant here. We just want to determine that the account has positive
                // free collateral, the exact amount is not required.
                fc.aggregate = fc.aggregate.add(netFC);
            }
        }

        if (valueToSettle > transfer.netLocalCurrencyPayer && fc.aggregate >= 0) {
            uint128 liquidityHaircut = EscrowStorageSlot._liquidityHaircut();
            uint128 settlementDiscount = EscrowStorageSlot._settlementDiscount();
            uint128 localCurrencyRequired = valueToSettle.sub(transfer.netLocalCurrencyPayer);

            _tradeCollateralCurrency(
                payer,
                localCurrencyRequired,
                liquidityHaircut,
                settlementDiscount,
                transfer,
                fc,
                rateParam,
                Portfolios
            );
        }

        return transfer;
    }

    function _calculateLocalCurrencyToTrade(
        uint128 localCurrencyRequired,
        uint128 liquidationDiscount,
        uint128 localCurrencyBuffer,
        uint128 maxLocalCurrencyDebt
    ) internal pure returns (uint128) {
        // We calculate the max amount of local currency that the liquidator can trade for here. We set it to the min of the
        // netCurrencyAvailable and the localCurrencyToTrade figure calculated below. The math for this figure is as follows:

        // The benefit given to free collateral in local currency terms:
        //   localCurrencyBenefit = localCurrencyToTrade * localCurrencyBuffer
        // NOTE: this only holds true while maxLocalCurrencyDebt <= 0

        // The penalty for trading collateral currency in local currency terms:
        //   localCurrencyPenalty = collateralCurrencyPurchased * exchangeRate[collateralCurrency][localCurrency]
        //
        //  netLocalCurrencyBenefit = localCurrencyBenefit - localCurrencyPenalty
        //
        // collateralCurrencyPurchased = localCurrencyToTrade * exchangeRate[localCurrency][collateralCurrency] * liquidationDiscount
        // localCurrencyPenalty = localCurrencyToTrade * exchangeRate[localCurrency][collateralCurrency] * exchangeRate[collateralCurrency][localCurrency] * liquidationDiscount
        // localCurrencyPenalty = localCurrencyToTrade * liquidationDiscount
        // netLocalCurrencyBenefit =  localCurrencyToTrade * localCurrencyBuffer - localCurrencyToTrade * liquidationDiscount
        // netLocalCurrencyBenefit =  localCurrencyToTrade * (localCurrencyBuffer - liquidationDiscount)
        // localCurrencyToTrade =  netLocalCurrencyBenefit / (buffer - discount)
        //
        // localCurrencyRequired is netLocalCurrencyBenefit after removing liquidity tokens
        // localCurrencyToTrade =  localCurrencyRequired / (buffer - discount)

        uint128 localCurrencyToTrade = SafeCast.toUint128(
            uint256(localCurrencyRequired)
                .mul(Common.DECIMALS)
                .div(localCurrencyBuffer.sub(liquidationDiscount))
        );

        // We do not trade past the amount of local currency debt the account has or this benefit will not longer be effective.
        localCurrencyToTrade = maxLocalCurrencyDebt < localCurrencyToTrade ? maxLocalCurrencyDebt : localCurrencyToTrade;

        return localCurrencyToTrade;
    }

    function _liquidateCollateralCurrency(
        address payer,
        uint128 localCurrencyRequired,
        uint128 liquidityHaircut,
        TransferAmounts memory transfer,
        Common.FreeCollateralFactors memory fc,
        RateParameters memory rateParam,
        address Portfolios,
        uint128 maxLiquidateAmount
    ) internal {
        uint128 discountFactor = EscrowStorageSlot._liquidationDiscount();
        localCurrencyRequired = _calculateLocalCurrencyToTrade(
            localCurrencyRequired,
            discountFactor,
            rateParam.localToETH.buffer,
            uint128(fc.localNetAvailable.neg())
        );

        if (maxLiquidateAmount > 0 && localCurrencyRequired > maxLiquidateAmount) {
            localCurrencyRequired = maxLiquidateAmount;
        }

        _tradeCollateralCurrency(
            payer,
            localCurrencyRequired,
            liquidityHaircut,
            discountFactor,
            transfer,
            fc,
            rateParam,
            Portfolios
        );
    }

    function _tradeCollateralCurrency(
        address payer,
        uint128 localCurrencyRequired,
        uint128 liquidityHaircut,
        uint128 discountFactor,
        TransferAmounts memory transfer,
        Common.FreeCollateralFactors memory fc,
        RateParameters memory rateParam,
        address Portfolios
    ) internal {
        uint128 amountToRaise;
        uint128 localToPurchase;

        uint128 haircutClaim = _calculateLiquidityTokenHaircut(
            fc.collateralCashClaim,
            liquidityHaircut
        );

        int256 collateralToSell = _calculateCollateralToSell(
            discountFactor,
            localCurrencyRequired,
            rateParam
        );

        // It's possible that collateralToSell is zero even if localCurrencyRequired > 0, this can be caused
        // by very small amounts of localCurrencyRequired
        if (collateralToSell == 0) return;
        
        int256 balanceAdjustment;
        (fc.collateralNetAvailable, balanceAdjustment) = _calculatePostfCashValue(fc, transfer);
        require(fc.collateralNetAvailable > 0, "8");

        (amountToRaise, localToPurchase, transfer.collateralTransfer) = _calculatePurchaseAmounts(
            localCurrencyRequired,
            discountFactor,
            liquidityHaircut,
            haircutClaim,
            collateralToSell,
            fc,
            rateParam
        );

        // The result of this calculation is a new collateral currency balance for the payer.
        transfer.payerCollateralBalance = _calculateCollateralBalances(
            payer,
            transfer.payerCollateralBalance.add(balanceAdjustment),
            rateParam.collateralCurrency,
            transfer.collateralTransfer,
            amountToRaise,
            IPortfoliosCallable(Portfolios)
        );

        transfer.payerCollateralBalance = transfer.payerCollateralBalance.sub(balanceAdjustment);
        transfer.netLocalCurrencyPayer = transfer.netLocalCurrencyPayer.add(localToPurchase);
        transfer.netLocalCurrencyLiquidator = transfer.netLocalCurrencyLiquidator.add(localToPurchase);
    }

    /**
     * @notice Calculates collateralNetAvailable and payerCollateralBalance post fCashValue. We do not trade fCashValue
     * in this scenario so we want to only allow fCashValue to net out against negative collateral balance and no more.
     */
    function _calculatePostfCashValue(
        Common.FreeCollateralFactors memory fc,
        TransferAmounts memory transfer
    ) internal pure returns (int256, int256) {
        int256 fCashValue = fc.collateralNetAvailable
            .sub(transfer.payerCollateralBalance)
            .sub(fc.collateralCashClaim);

        if (fCashValue <= 0) {
            // If we have negative fCashValue then no adjustments are required.
            return (fc.collateralNetAvailable, 0);
        }

        if (transfer.payerCollateralBalance >= 0) {
            // If payer has a positive collateral balance then we don't need to net off against it. We remove
            // the fCashValue from net available.
            return (fc.collateralNetAvailable.sub(fCashValue), 0);
        }

        // In these scenarios the payer has a negative collateral balance and we need to partially offset the balance
        // so that the payer gets the benefit of their positive fCashValue.
        int256 netBalanceWithfCashValue = transfer.payerCollateralBalance.add(fCashValue);
        if (netBalanceWithfCashValue > 0) {
            // We have more fCashValue than required to net out the balance. We remove the excess from collateralNetAvailable
            // and adjust the netPayerBalance to zero.
            return (fc.collateralNetAvailable.sub(netBalanceWithfCashValue), transfer.payerCollateralBalance.neg());
        } else {
            // We don't have enough fCashValue to net out the balance. collateralNetAvailable is unchanged because it already takes
            // into account this netting. We adjust the balance to account for fCash only
            return (fc.collateralNetAvailable, fCashValue);
        }
    }

    function _calculateLiquidityTokenHaircut(
        int256 postHaircutCashClaim,
        uint128 liquidityHaircut
    ) internal pure returns (uint128) {
        require(postHaircutCashClaim >= 0);
        // liquidityTokenHaircut = cashClaim / haircut - cashClaim
        uint256 x = uint256(postHaircutCashClaim);

        return SafeCast.toUint128(
            uint256(x)
                .mul(Common.DECIMALS)
                .div(liquidityHaircut)
                .sub(x)
        );
    }

    function _calculatePurchaseAmounts(
        uint128 localCurrencyRequired,
        uint128 discountFactor,
        uint128 liquidityHaircut,
        uint128 haircutClaim,
        int256 collateralToSell,
        Common.FreeCollateralFactors memory fc,
        RateParameters memory rateParam
    ) internal pure returns (uint128, uint128, uint128) {
        require(fc.collateralNetAvailable > 0, "8");

        uint128 localToPurchase;
        uint128 amountToRaise;
        // This calculation is described in Appendix B of the whitepaper. It is split between this function and
        // _calculateCollateralBalances to deal with stack issues.
        if (fc.collateralNetAvailable >= collateralToSell) {
            // We have enough collateral currency available to fulfill the purchase. It is either locked up inside
            // liquidity tokens or in the account's balance. If the account's balance is negative then we will have
            // to raise additional amount to fulfill collateralToSell.
            localToPurchase = localCurrencyRequired;
        } else if (fc.collateralNetAvailable.add(haircutClaim) >= collateralToSell) {
            // We have enough collateral currency available if we account for the liquidity token haircut that
            // is not part of the collateralNetAvailable figure. Here we raise an additional amount. 

            // This has to be scaled to the preHaircutCashClaim amount:
            // haircutClaim = preHaircutCashClaim - preHaircutCashClaim * haircut
            // haircutClaim = preHaircutCashClaim * (1 - haircut)
            // liquidiytTokenHaircut / (1 - haircut) = preHaircutCashClaim
            amountToRaise = SafeCast.toUint128(
                uint256(collateralToSell.sub(fc.collateralNetAvailable))
                    .mul(Common.DECIMALS)
                    .div(Common.DECIMALS.sub(liquidityHaircut))
            );
            localToPurchase = localCurrencyRequired;
        } else if (collateralToSell > fc.collateralNetAvailable.add(haircutClaim)) {
            // There is not enough value collateral currency in the account to fulfill the purchase, we
            // specify the maximum amount that we can get from the account to partially settle.
            collateralToSell = fc.collateralNetAvailable.add(haircutClaim);

            // stack frame isn't big enough for this calculation
            // haircutClaim * 1e18 / (1e18 - liquidityHaircut), this is the maximum amountToRaise
            uint256 x = haircutClaim.mul(Common.DECIMALS);
            x = x.div(Common.DECIMALS.sub(liquidityHaircut));
            amountToRaise = SafeCast.toUint128(x);

            // In this case we partially settle the collateralToSell amount.
            require(collateralToSell > 0);
            localToPurchase = _calculateLocalCurrencyAmount(discountFactor, uint128(collateralToSell), rateParam);
        }

        require(collateralToSell > 0);

        return (amountToRaise, localToPurchase, uint128(collateralToSell));
    }

    function _calculateLocalCurrencyAmount(
        uint128 discountFactor,
        uint128 collateralToSell,
        RateParameters memory rateParam
    ) internal pure returns (uint128) {
        // collateralDecimals * rateDecimals * 1e18 * localDecimals
        //         / (rateDecimals * 1e18 * collateralDecimals) = localDecimals
        uint256 x = uint256(collateralToSell)
            .mul(rateParam.localToETH.rateDecimals)
            // Discount factor uses 1e18 as its decimal precision
            .mul(Common.DECIMALS);

        x = x
            .mul(rateParam.localDecimals)
            .div(rateParam.rate);

        return SafeCast.toUint128(x
            .div(discountFactor)
            .div(rateParam.collateralDecimals)
        );
    }

    function _calculateCollateralToSell(
        uint128 discountFactor,
        uint128 localCurrencyRequired,
        RateParameters memory rateParam
    ) internal pure returns (uint128) {
        uint256 x = rateParam.rate
            .mul(localCurrencyRequired)
            .mul(discountFactor);

        x = x
            .div(rateParam.localToETH.rateDecimals)
            .div(rateParam.localDecimals);
        
        // Splitting calculation to handle stack depth
        return SafeCast.toUint128(x
            // Multiplying to the quote decimal precision (may not be the same as the rate precision)
            .mul(rateParam.collateralDecimals)
            // discountFactor uses 1e18 as its decimal precision
            .div(Common.DECIMALS)
        );
    }

    function _calculateCollateralBalances(
        address payer,
        int256 payerBalance,
        uint16 collateralCurrency,
        uint128 collateralToSell,
        uint128 amountToRaise,
        IPortfoliosCallable Portfolios
    ) internal returns (int256) {
        // We must deterimine how to transfer collateral from the payer to liquidator. The collateral may be in cashBalances
        // or it may be locked up in liquidity tokens.
        int256 balance = payerBalance;
        bool creditBalance;

        if (balance >= collateralToSell) {
            balance = balance.sub(collateralToSell);
            creditBalance = true;
        } else {
            // If amountToRaise is greater than (collateralToSell - balance) this means that we're tapping into the
            // haircut claim amount. We need to credit back the difference to the account to ensure that the collateral
            // position does not get worse.
            int256 x = int256(collateralToSell).sub(balance);
            require(x > 0);
            uint128 tmp = uint128(x);

            if (amountToRaise > tmp) {
                balance = int256(amountToRaise).sub(tmp);
            } else {
                amountToRaise = tmp;
                balance = 0;
            }

            creditBalance = false;
        }

        if (amountToRaise > 0) {
            uint128 remainder = Portfolios.raiseCurrentCashViaLiquidityToken(
                payer,
                collateralCurrency,
                amountToRaise
            );

            if (creditBalance) {
                balance = balance.add(amountToRaise).sub(remainder);
            } else {
                // Generally we expect remainder to equal zero but this can be off by small amounts due
                // to truncation in the different calculations on the liquidity token haircuts. The upper bound on
                // amountToRaise is based on collateralCurrencyAvailable and the balance. Also note that when removing
                // liquidity tokens some amount of cash receiver is credited back to the account as well. The concern
                // here is that if this is not true then remainder could put the account into a debt that it cannot pay off.
                require(remainder <= 1, "52");
                balance = balance.sub(remainder);
            }
        }

        return balance;
    }

    /**
     * @notice Settles fCash between local and collateral currency.
     * @param payer address of account that has current cash debts
     * @param liquidator address of account liquidating
     * @param valueToSettle amount of local currency debt to settle
     * @param collateralNetAvailable net amount of collateral available to trade
     * @param rateParam exchange rate parameters
     * @param Portfolios address of the portfolios contract
     */
    function settlefCash(
        address payer,
        address liquidator,
        uint128 valueToSettle,
        int256 collateralNetAvailable,
        RateParameters memory rateParam,
        address Portfolios
    ) public returns (int256, uint128) {
        uint128 discountFactor = EscrowStorageSlot._settlementDiscount();

        return _tradefCash(
            payer,
            liquidator,
            valueToSettle,
            collateralNetAvailable,
            discountFactor,
            rateParam,
            Portfolios
        );
    }

    /**
     * @notice Liquidates fCash between local and collateral currency.
     * @param payer address of account that has current cash debts
     * @param liquidator address of account liquidating
     * @param fcAggregate free collateral shortfall denominated in ETH
     * @param localNetAvailable amount of local currency debts available to recollateralize, dictates max trading amount
     * @param collateralNetAvailable net amount of collateral available to trade
     * @param rateParam exchange rate parameters
     * @param Portfolios address of the portfolios contract
     */
    function liquidatefCash(
        address payer,
        address liquidator,
        int256 fcAggregate,
        int256 localNetAvailable,
        int256 collateralNetAvailable,
        RateParameters memory rateParam,
        address Portfolios
    ) public returns (int256, uint128) {
        uint128 localCurrencyRequired = _fcAggregateToLocal(fcAggregate, rateParam);
        uint128 discountFactor = EscrowStorageSlot._liquidationDiscount();
        require (localNetAvailable < 0, "47");

        localCurrencyRequired = _calculateLocalCurrencyToTrade(
            localCurrencyRequired,
            discountFactor,
            rateParam.localToETH.buffer,
            uint128(localNetAvailable.neg())
        );

        return _tradefCash(
            payer,
            liquidator,
            localCurrencyRequired,
            collateralNetAvailable,
            discountFactor,
            rateParam,
            Portfolios
        );
    }

    /** @notice Trades fCash denominated in collateral currency in exchange for local currency. */
    function _tradefCash(
        address payer,
        address liquidator,
        uint128 localCurrencyRequired,
        int256 collateralNetAvailable,
        uint128 discountFactor,
        RateParameters memory rateParam,
        address Portfolios
    ) internal returns (int256, uint128) {
        require(collateralNetAvailable > 0, "36");

        uint128 collateralCurrencyRequired = _calculateCollateralToSell(discountFactor, localCurrencyRequired, rateParam);
        if (collateralCurrencyRequired > collateralNetAvailable) {
            // We limit trading to the amount of collateralNetAvailable so that we don't put the account further undercollateralized
            // in the collateral currency.
            collateralCurrencyRequired = uint128(collateralNetAvailable);
            localCurrencyRequired = _calculateLocalCurrencyAmount(
                discountFactor,
                collateralCurrencyRequired,
                rateParam
            );
        }

        (uint128 shortfall, uint128 liquidatorPayment) = IPortfoliosCallable(Portfolios).raiseCurrentCashViaCashReceiver(
            payer,
            liquidator,
            rateParam.collateralCurrency,
            collateralCurrencyRequired
        );

        int256 netCollateralCurrencyLiquidator = int256(liquidatorPayment).sub(collateralCurrencyRequired.sub(shortfall));

        uint128 netLocalCurrencyPayer = localCurrencyRequired;
        if (shortfall > 0) {
            // (rate * discountFactor * (localCurrencyRequired - localShortfall)) = (collateralToSell - shortfall)
            // (rate * discountFactor * localShortfall) = shortfall
            // shortfall / (rate * discountFactor) = localCurrencyShortfall
            uint128 localCurrencyShortfall = 
                _calculateLocalCurrencyAmount(
                    discountFactor,
                    shortfall,
                    rateParam
                );

            netLocalCurrencyPayer = netLocalCurrencyPayer.sub(localCurrencyShortfall);
        }

        return (netCollateralCurrencyLiquidator, netLocalCurrencyPayer);
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: GPL-3.0-only



import "../lib/SafeInt256.sol";
import "../lib/SafeMath.sol";
import "../utils/Common.sol";
import "../interface/IAggregator.sol";

import "@openzeppelin/contracts/utils/SafeCast.sol";


library ExchangeRate {
    using SafeInt256 for int256;
    using SafeMath for uint256;

    /**
     * Exchange rates between currencies
     */
    struct Rate {
        // The address of the chainlink price oracle
        address rateOracle;
        // The decimals of precision that the rate oracle uses
        uint128 rateDecimals;
        // True of the exchange rate must be inverted
        bool mustInvert;
        // Amount of buffer to apply to the exchange rate, this defines the collateralization ratio
        // between the two currencies. This must be stored with 18 decimal precision because it is used
        // to convert to an ETH balance.
        uint128 buffer;
    }

    /**
     * @notice Converts a balance between token addresses.
     *
     * @param er exchange rate object from base to ETH
     * @param baseDecimals decimals for base currency
     * @param balance amount to convert
     * @return the converted balance denominated in ETH with 18 decimal places
     */
    function _convertToETH(
        Rate memory er,
        uint256 baseDecimals,
        int256 balance,
        bool buffer
    ) internal view returns (int256) {
        // Fetches the latest answer from the chainlink oracle and buffer it by the apporpriate amount.
        uint256 rate = _fetchExchangeRate(er, false);
        uint128 absBalance = uint128(balance.abs());

        // We are converting to ETH here so we know that it has Common.DECIMAL precision. The calculation here is:
        // baseDecimals * rateDecimals * Common.DECIMAL /  (rateDecimals * baseDecimals)
        // er.buffer is in Common.DECIMAL precision
        // We use uint256 to do the calculation and then cast back to int256 to avoid overflows.
        int256 result = int256(
            SafeCast.toUint128(rate
                .mul(absBalance)
                // Buffer has 18 decimal places of precision
                .mul(buffer ? er.buffer : Common.DECIMALS)
                .div(er.rateDecimals)
                .div(baseDecimals)
            )
        );

        return balance > 0 ? result : result.neg();
    }

    /**
     * @notice Converts the balance denominated in ETH to the equivalent value in base.
     * @param er exchange rate object from base to ETH
     * @param baseDecimals decimals for base currency
     * @param balance amount (denominated in ETH) to convert
     */
    function _convertETHTo(
        Rate memory er,
        uint256 baseDecimals,
        int256 balance
    ) internal view returns (int256) {
        uint256 rate = _fetchExchangeRate(er, true);
        uint128 absBalance = uint128(balance.abs());

        // We are converting from ETH here so we know that it has Common.DECIMAL precision. The calculation here is:
        // ethDecimals * rateDecimals * baseDecimals / (ethDecimals * rateDecimals)
        // er.buffer is in Common.DECIMAL precision
        // We use uint256 to do the calculation and then cast back to int256 to avoid overflows.
        int256 result = int256(
            SafeCast.toUint128(rate
                .mul(absBalance)
                .mul(baseDecimals)
                .div(Common.DECIMALS)
                .div(er.rateDecimals)
            )
        );

        return balance > 0 ? result : result.neg();
    }

    function _fetchExchangeRate(Rate memory er, bool invert) internal view returns (uint256) {
        int256 rate = IAggregator(er.rateOracle).latestAnswer();
        require(rate > 0, "28");

        if (invert || (er.mustInvert && !invert)) {
            // If the ER is inverted and we're NOT asking to invert then we need to invert the rate here.
            return uint256(er.rateDecimals).mul(er.rateDecimals).div(uint256(rate));
        }

        return uint256(rate);
    }

    /**
     * @notice Calculates the exchange rate between two currencies via ETH. Returns the rate.
     */
    function _exchangeRate(Rate memory baseER, Rate memory quoteER, uint16 quote) internal view returns (uint256) {
        uint256 rate = _fetchExchangeRate(baseER, false);

        if (quote != 0) {
            uint256 quoteRate = _fetchExchangeRate(quoteER, false);

            rate = rate.mul(quoteER.rateDecimals).div(quoteRate);
        }

        return rate;
    }

}

pragma solidity ^0.6.0;

// SPDX-License-Identifier: GPL-3.0-only


/** Chainlink Aggregator Price Feed Interface */
interface IAggregator {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);
  event NewRound(uint256 indexed roundId, address indexed startedBy);
}

pragma solidity ^0.6.0;

// SPDX-License-Identifier: GPL-3.0-only


import "./StorageSlot.sol";
import "../utils/ExchangeRate.sol";

library EscrowStorageSlot {
    bytes32 internal constant S_LIQUIDTION_DISCOUNT = 0xc59867f3ae9774eb97a98f3fbbe736c1ee23580155c8697cd969a2d1f3968653;
    bytes32 internal constant S_SETTLEMENT_DISCOUNT = 0xdafe5151c63bd8d33bc03c4916ccca379c56861736a985b1918a3e0c0347707b;
    bytes32 internal constant S_LIQUIDITY_TOKEN_REPO_INCENTIVE = 0x86f55df6f3f1d5533a992d6e1355f3adb2afe0c3064672910d2518432c35e770;
    bytes32 internal constant S_LIQUIDITY_HAIRCUT = 0x28971522a5177c8ac90bf7d9be4d04d6bc61da2e7623c4392f5b9494ac42e4d0;

    function _liquidationDiscount() internal view returns (uint128) {
        return uint128(StorageSlot._getStorageUint(S_LIQUIDTION_DISCOUNT));
    }

    function _settlementDiscount() internal view returns (uint128) {
        return uint128(StorageSlot._getStorageUint(S_SETTLEMENT_DISCOUNT));
    }

    function _liquidityTokenRepoIncentive() internal view returns (uint128) {
        return uint128(StorageSlot._getStorageUint(S_LIQUIDITY_TOKEN_REPO_INCENTIVE));
    }

    function _liquidityHaircut() internal view returns (uint128) {
        return uint128(StorageSlot._getStorageUint(S_LIQUIDITY_HAIRCUT));
    }

    function _setLiquidationDiscount(uint128 liquidationDiscount) internal {
        StorageSlot._setStorageUint(S_LIQUIDTION_DISCOUNT, liquidationDiscount);
    }

    function _setSettlementDiscount(uint128 settlementDiscount) internal {
        StorageSlot._setStorageUint(S_SETTLEMENT_DISCOUNT, settlementDiscount);
    }

    function _setLiquidityTokenRepoIncentive(uint128 liquidityTokenRepoIncentive) internal {
        StorageSlot._setStorageUint(S_LIQUIDITY_TOKEN_REPO_INCENTIVE, liquidityTokenRepoIncentive);
    }

    function _setLiquidityHaircut(uint128 liquidityHaircut) internal {
        StorageSlot._setStorageUint(S_LIQUIDITY_HAIRCUT, liquidityHaircut);
    }
}

contract EscrowStorage {
    // keccak256("ERC777TokensRecipient")
    bytes32 internal constant TOKENS_RECIPIENT_INTERFACE_HASH = 0xb281fc8c12954d22544db45de3159a39272895b169a852b314f9cc762e44c53b;

    // Internally we use WETH to represent ETH
    address public WETH;

    // Holds token features that can be used to check certain behaviors on deposit / withdraw.
    struct TokenOptions {
        // Whether or not the token implements the ERC777 standard.
        bool isERC777;
        // Whether or not the token charges transfer fees
        bool hasTransferFee;
    }

    uint16 public maxCurrencyId;
    mapping(uint16 => address) public currencyIdToAddress;
    mapping(uint16 => uint256) public currencyIdToDecimals;
    mapping(address => uint16) public addressToCurrencyId;
    mapping(address => TokenOptions) public tokenOptions;

    // Mapping from base currency id to quote currency id
    mapping(uint16 => mapping(uint16 => ExchangeRate.Rate)) public exchangeRateOracles;

    // Holds account cash balances that can be positive or negative.
    mapping(uint16 => mapping(address => int256)) public cashBalances;

    /********** Governance Settings ******************/
    // The address of the account that holds reserve balances in each currency. Fees are paid to this
    // account on trading and in the case of a default, this account is drained.
    address public G_RESERVE_ACCOUNT;
    /********** Governance Settings ******************/

    // The discount given to a liquidator when they purchase ETH for the local currency of an obligation.
    // This discount is taken off of the exchange rate oracle price.
    function G_LIQUIDATION_DISCOUNT() public view returns (uint128) {
        return EscrowStorageSlot._liquidationDiscount();
    }

    // The discount given to an account that settles obligations collateralized by ETH in order to settle
    // cash balances for accounts.
    function G_SETTLEMENT_DISCOUNT() public view returns (uint128) {
        return EscrowStorageSlot._settlementDiscount();
    }

    // This is the incentive given to liquidators who pull liquidity tokens out of an undercollateralized
    // account in order to bring it back into collateralization.
    function G_LIQUIDITY_TOKEN_REPO_INCENTIVE() public view returns (uint128) {
        return EscrowStorageSlot._liquidityTokenRepoIncentive();
    }

    // Cached copy of the same value on the RiskFramework contract.
    function G_LIQUIDITY_HAIRCUT() public view returns (uint128) {
        return EscrowStorageSlot._liquidityHaircut();
    }
}

pragma solidity ^0.6.0;

// SPDX-License-Identifier: GPL-3.0-only


/** @title Gets and sets parameters at a specified storage slot */
library StorageSlot {
    function _setStorageUint(bytes32 slot, uint256 data) internal {
        assembly {
            sstore(slot, data)
        }
    }

    function _getStorageUint(bytes32 slot) internal view returns (uint256) {
        uint256 result;
        assembly {
            result := sload(slot)
        }

        return result;
    }
}

pragma solidity ^0.6.0;

// SPDX-License-Identifier: MIT



import "../interface/IERC20.sol";
import "./SafeMath.sol";
import "../upgradeable/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.6.0;

// SPDX-License-Identifier: GPL-3.0-only



/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    function name() external view returns (string memory);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.6.2;

// SPDX-License-Identifier: MIT



/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

pragma solidity ^0.6.0;

// SPDX-License-Identifier: GPL-3.0-only
// SPDX-License-Identifier: MIT



/**
 * @dev Interface of the ERC777Token standard as defined in the EIP.
 *
 * This contract uses the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 registry standard] to let
 * token holders and recipients react to token movements by using setting implementers
 * for the associated interfaces in said registry. See {IERC1820Registry} and
 * {ERC1820Implementer}.
 */
interface IERC777 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the smallest part of the token that is not divisible. This
     * means all token operations (creation, movement and destruction) must have
     * amounts that are a multiple of this number.
     *
     * For most token contracts, this value will equal 1.
     */
    function granularity() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by an account (`owner`).
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * If send or receive hooks are registered for the caller and `recipient`,
     * the corresponding functions will be called with `data` and empty
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function send(address recipient, uint256 amount, bytes calldata data) external;

    /**
     * @dev Destroys `amount` tokens from the caller's account, reducing the
     * total supply.
     *
     * If a send hook is registered for the caller, the corresponding function
     * will be called with `data` and empty `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     */
    function burn(uint256 amount, bytes calldata data) external;

    /**
     * @dev Returns true if an account is an operator of `tokenHolder`.
     * Operators can send and burn tokens on behalf of their owners. All
     * accounts are their own operator.
     *
     * See {operatorSend} and {operatorBurn}.
     */
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);

    /**
     * @dev Make an account an operator of the caller.
     *
     * See {isOperatorFor}.
     *
     * Emits an {AuthorizedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function authorizeOperator(address operator) external;

    /**
     * @dev Revoke an account's operator status for the caller.
     *
     * See {isOperatorFor} and {defaultOperators}.
     *
     * Emits a {RevokedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function revokeOperator(address operator) external;

    /**
     * @dev Returns the list of default operators. These accounts are operators
     * for all token holders, even if {authorizeOperator} was never called on
     * them.
     *
     * This list is immutable, but individual holders may revoke these via
     * {revokeOperator}, in which case {isOperatorFor} will return false.
     */
    function defaultOperators() external view returns (address[] memory);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`. The caller must
     * be an operator of `sender`.
     *
     * If send or receive hooks are registered for `sender` and `recipient`,
     * the corresponding functions will be called with `data` and
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - `sender` cannot be the zero address.
     * - `sender` must have at least `amount` tokens.
     * - the caller must be an operator for `sender`.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     * The caller must be an operator of `account`.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with `data` and `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     * - the caller must be an operator for `account`.
     */
    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );

    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    event RevokedOperator(address indexed operator, address indexed tokenHolder);
}

pragma solidity ^0.6.0;

// SPDX-License-Identifier: GPL-3.0-only


/**
 * @dev Interface of the ERC777TokensRecipient standard as defined in the EIP.
 *
 * Accounts can be notified of {IERC777} tokens being sent to them by having a
 * contract implement this interface (contract holders can be their own
 * implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {ERC1820Implementer}.
 */
interface IERC777Recipient {
    /**
     * @dev Called by an {IERC777} token contract whenever tokens are being
     * moved or created into a registered account (`to`). The type of operation
     * is conveyed by `from` being the zero address or not.
     *
     * This call occurs _after_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the post-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

pragma solidity ^0.6.0;

// SPDX-License-Identifier: GPL-3.0-only


/**
 * @dev Interface of the global ERC1820 Registry, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820[EIP]. Accounts may register
 * implementers for interfaces in this registry, as well as query support.
 *
 * Implementers may be shared by multiple accounts, and can also implement more
 * than a single interface for each account. Contracts can implement interfaces
 * for themselves, but externally-owned accounts (EOA) must delegate this to a
 * contract.
 *
 * {IERC165} interfaces can also be queried via the registry.
 *
 * For an in-depth explanation and source code analysis, see the EIP text.
 */
interface IERC1820Registry {
    /**
     * @dev Sets `newManager` as the manager for `account`. A manager of an
     * account is able to set interface implementers for it.
     *
     * By default, each account is its own manager. Passing a value of `0x0` in
     * `newManager` will reset the manager to this initial state.
     *
     * Emits a {ManagerChanged} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     */
    function setManager(address account, address newManager) external;

    /**
     * @dev Returns the manager for `account`.
     *
     * See {setManager}.
     */
    function getManager(address account) external view returns (address);

    /**
     * @dev Sets the `implementer` contract as `account`'s implementer for
     * `interfaceHash`.
     *
     * `account` being the zero address is an alias for the caller's address.
     * The zero address can also be used in `implementer` to remove an old one.
     *
     * See {interfaceHash} to learn how these are created.
     *
     * Emits an {InterfaceImplementerSet} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     * - `interfaceHash` must not be an {IERC165} interface id (i.e. it must not
     * end in 28 zeroes).
     * - `implementer` must implement {IERC1820Implementer} and return true when
     * queried for support, unless `implementer` is the caller. See
     * {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function setInterfaceImplementer(address account, bytes32 interfaceHash, address implementer) external;

    /**
     * @dev Returns the implementer of `interfaceHash` for `account`. If no such
     * implementer is registered, returns the zero address.
     *
     * If `interfaceHash` is an {IERC165} interface id (i.e. it ends with 28
     * zeroes), `account` will be queried for support of it.
     *
     * `account` being the zero address is an alias for the caller's address.
     */
    function getInterfaceImplementer(address account, bytes32 interfaceHash) external view returns (address);

    /**
     * @dev Returns the interface hash for an `interfaceName`, as defined in the
     * corresponding
     * https://eips.ethereum.org/EIPS/eip-1820#interface-name[section of the EIP].
     */
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    /**
     *  @notice Updates the cache with whether the contract implements an ERC165 interface or not.
     *  @param account Address of the contract for which to update the cache.
     *  @param interfaceId ERC165 interface for which to update the cache.
     */
    function updateERC165Cache(address account, bytes4 interfaceId) external;

    /**
     *  @notice Checks whether a contract implements an ERC165 interface or not.
     *  If the result is not cached a direct lookup on the contract address is performed.
     *  If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
     *  {updateERC165Cache} with the contract address.
     *  @param account Address of the contract to check.
     *  @param interfaceId ERC165 interface to check.
     *  @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    /**
     *  @notice Checks whether a contract implements an ERC165 interface or not without using nor updating the cache.
     *  @param account Address of the contract to check.
     *  @param interfaceId ERC165 interface to check.
     *  @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);

    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);
}

pragma solidity >=0.5.0;

// SPDX-License-Identifier: GPL-3.0-only


interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;

    function approve(address guy, uint wad) external returns (bool);
}

pragma solidity ^0.6.0;

// SPDX-License-Identifier: GPL-3.0-only



/**
 * @title Notional rate oracle interface
 * @notice Contracts implementing this interface are able to provide rates to the asset
 *  risk and valuation framework.
 */
interface IRateOracle {
    /* is IERC165 */
    /**
     * Returns the currently active maturities. Note that this may read state to confirm whether or not
     * the market for a maturity has been created.
     *
     * @return an array of the active maturity ids
     */
    function getActiveMaturities() external view returns (uint32[] memory);

    /**
     * Sets governance parameters on the rate oracle.
     *
     * @param cashGroupId this cannot change once set
     * @param instrumentId cannot change once set
     * @param precision will only take effect on a new maturity
     * @param maturityLength will take effect immediately, must be careful
     * @param numMaturities will take effect immediately, makers can create new markets
     * @param maxRate will take effect immediately
     */
    function setParameters(
        uint8 cashGroupId,
        uint16 instrumentId,
        uint32 precision,
        uint32 maturityLength,
        uint32 numMaturities,
        uint32 maxRate
    ) external;
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: GPL-3.0-only



import "./utils/Common.sol";
import "./utils/Governed.sol";

import "./lib/SafeMath.sol";
import "./lib/SafeInt256.sol";
import "./lib/SafeUInt128.sol";
import "./utils/RiskFramework.sol";

import "./interface/IRateOracle.sol";
import "./interface/IPortfoliosCallable.sol";

import "./storage/PortfoliosStorage.sol";
import "./CashMarket.sol";

/**
 * @title Portfolios
 * @notice Manages account portfolios which includes all fCash positions and liquidity tokens.
 */
contract Portfolios is PortfoliosStorage, IPortfoliosCallable, Governed {
    using SafeMath for uint256;
    using SafeInt256 for int256;
    using SafeUInt128 for uint128;

    struct TradePortfolioState {
        uint128 amountRemaining;
        uint256 indexCount;
        int256 unlockedCurrentCash;
        Common.Asset[] portfolioChanges;
    }

    /**
     * @notice Emitted when an account has its portfolio settled, only emitted if the portfolio has changed
     * @param account the account that had its porfolio modified
     */
    event SettleAccount(address account);

    /**
     * @notice Emitted when an account has its portfolio settled, all accounts are emitted in the batch
     * @param accounts batch of accounts that *may* have been settled
     */
    event SettleAccountBatch(address[] accounts);

    /**
     * @notice Emitted when a new cash group is listed
     * @param cashGroupId id of the new cash group
     */
    event NewCashGroup(uint8 indexed cashGroupId);

    /**
     * @notice Emitted when a new cash group is updated
     * @param cashGroupId id of the updated cash group
     */
    event UpdateCashGroup(uint8 indexed cashGroupId);

    /**
     * @notice Emitted when max assets is set
     * @param maxAssets the max assets a portfolio can hold
     */
    event SetMaxAssets(uint256 maxAssets);

    /**
     * @notice Notice for setting haircut amount for liquidity tokens
     * @param liquidityHaircut amount of haircut applied to liquidity token claims 
     * @param fCashHaircut amount of negative haircut applied to fcash
     * @param fCashMaxHaircut max haircut amount applied to fcash
     */
    event SetHaircuts(uint128 liquidityHaircut, uint128 fCashHaircut, uint128 fCashMaxHaircut);

    /**
     * @dev skip
     * @param directory holds contract addresses for dependencies
     * @param numCurrencies initializes the number of currencies listed on the escrow contract
     * @param maxAssets max assets that a portfolio can hold
     */
    function initialize(address directory, address owner, uint16 numCurrencies, uint256 maxAssets) external initializer {
        Governed.initialize(directory, owner);

        // We must initialize this here because it cannot be a constant.
        NULL_ASSET = Common.Asset(0, 0, 0, 0, 0, 0);
        G_NUM_CURRENCIES = numCurrencies;
        G_MAX_ASSETS = maxAssets;

        emit SetMaxAssets(maxAssets);
    }

    /****** Governance Parameters ******/

    /**
     * @notice Sets the haircut amount for liquidity token claims, this is set to a percentage
     * less than 1e18, for example, a 5% haircut will be set to 0.95e18.
     * @dev governance
     * @param liquidityHaircut amount of negative haircut applied to token claims
     * @param fCashHaircut amount of negative haircut applied to fcash
     * @param fCashMaxHaircut max haircut amount applied to fcash
     */
    function setHaircuts(uint128 liquidityHaircut, uint128 fCashHaircut, uint128 fCashMaxHaircut) external onlyOwner {
        PortfoliosStorageSlot._setLiquidityHaircut(liquidityHaircut);
        PortfoliosStorageSlot._setfCashHaircut(fCashHaircut);
        PortfoliosStorageSlot._setfCashMaxHaircut(fCashMaxHaircut);
        Escrow().setLiquidityHaircut(liquidityHaircut);

        emit SetHaircuts(liquidityHaircut, fCashHaircut, fCashMaxHaircut);
    }

    /**
     * @dev skip
     * @param numCurrencies the total number of currencies set by escrow
     */
    function setNumCurrencies(uint16 numCurrencies) external override {
        require(calledByEscrow(), "20");
        G_NUM_CURRENCIES = numCurrencies;
    }

    /**
     * @notice Set the max assets that a portfolio can hold. The default will be initialized to something
     * like 10 assets, but this will be increased as new markets are created.
     * @dev governance
     * @param maxAssets new max asset number
     */
    function setMaxAssets(uint256 maxAssets) external onlyOwner {
        G_MAX_ASSETS = maxAssets;

        emit SetMaxAssets(maxAssets);
    }

    /**
     * @notice An cash group defines a collection of similar fCashs where the risk ladders can be netted
     * against each other. The identifier is only 1 byte so we can only have 255 cash groups, 0 is unused.
     * @dev governance
     * @param numMaturities the total number of maturitys
     * @param maturityLength the maturity length (in seconds)
     * @param precision the discount rate precision
     * @param currency the token address of the currenty this fCash settles in
     * @param cashMarket the rate oracle that defines the discount rate
     */
    function createCashGroup(
        uint32 numMaturities,
        uint32 maturityLength,
        uint32 precision,
        uint16 currency,
        address cashMarket
    ) external onlyOwner {
        require(currentCashGroupId <= MAX_CASH_GROUPS, "32");
        require(Escrow().isValidCurrency(currency), "19");

        currentCashGroupId++;
        cashGroups[currentCashGroupId] = Common.CashGroup(
            numMaturities,
            maturityLength,
            precision,
            cashMarket,
            currency
        );

        if (cashMarket == address(0)) {
            // If cashMarket is set to address 0, then it is an idiosyncratic cash group that does not have
            // an AMM that will trade it. It can only be traded off chain and created via mintfCashPair
            require(numMaturities == 1);
        } else if (cashMarket != address(0)) {
            // The fCash is set to 0 for discount rate oracles and there is no max rate as well.
            IRateOracle(cashMarket).setParameters(currentCashGroupId, 0, precision, maturityLength, numMaturities, 0);
        }

        emit NewCashGroup(currentCashGroupId);
    }

    /**
     * @notice Updates cash groups. Be very careful when calling this function! When changing maturities and
     * maturity sizes the markets must be updated as well.
     * @dev governance
     * @param cashGroupId the group id to update
     * @param numMaturities this is safe to update as long as the discount rate oracle is not shared
     * @param maturityLength this is only safe to update when there are no assets left
     * @param precision this is only safe to update when there are no assets left
     * @param currency this is safe to update if there are no assets or the new currency is equivalent
     * @param cashMarket this is safe to update once the oracle is established
     */
    function updateCashGroup(
        uint8 cashGroupId,
        uint32 numMaturities,
        uint32 maturityLength,
        uint32 precision,
        uint16 currency,
        address cashMarket
    ) external onlyOwner {
        require(
            cashGroupId != 0 && cashGroupId <= currentCashGroupId,
            "33"
        );
        require(Escrow().isValidCurrency(currency), "19");

        Common.CashGroup storage i = cashGroups[cashGroupId];
        if (i.numMaturities != numMaturities) i.numMaturities = numMaturities;
        if (i.maturityLength != maturityLength) i.maturityLength = maturityLength;
        if (i.precision != precision) i.precision = precision;
        if (i.currency != currency) i.currency = currency;
        if (i.cashMarket != cashMarket) i.cashMarket = cashMarket;

        // The fCash is set to 0 for discount rate oracles and there is no max rate as well.
        IRateOracle(cashMarket).setParameters(cashGroupId, 0, precision, maturityLength, numMaturities, 0);

        emit UpdateCashGroup(cashGroupId);
    }

    /****** Governance Parameters ******/

    /***** Public View Methods *****/

    /**
     * @notice Returns the assets of an account
     * @param account to retrieve
     * @return an array representing the account's portfolio
     */
    function getAssets(address account) public override view returns (Common.Asset[] memory) {
        return _accountAssets[account];
    }

    /**
     * @notice Returns a particular asset via index
     * @param account to retrieve
     * @param index of asset
     * @return a single asset by index in the portfolio
     */
    function getAsset(address account, uint256 index) public view returns (Common.Asset memory) {
        return _accountAssets[account][index];
    }

    /**
     * @notice Returns a particular cash group
     * @param cashGroupId to retrieve
     * @return the given cash group
     */
    function getCashGroup(uint8 cashGroupId) public override view returns (Common.CashGroup memory) {
        return cashGroups[cashGroupId];
    }

    /**
     * @notice Returns a batch of cash groups
     * @param groupIds array of cash group ids to retrieve
     * @return an array of cash group objects
     */
    function getCashGroups(uint8[] memory groupIds) public override view returns (Common.CashGroup[] memory) {
        Common.CashGroup[] memory results = new Common.CashGroup[](groupIds.length);

        for (uint256 i; i < groupIds.length; i++) {
            results[i] = cashGroups[groupIds[i]];
        }

        return results;
    }

    /**
     * @notice Public method for searching for a asset in an account.
     * @param account account to search
     * @param assetType the type of asset to search for
     * @param cashGroupId the cash group id
     * @param instrumentId the instrument id
     * @param maturity the maturity timestamp of the asset
     * @return (asset, index of asset)
     */
    function searchAccountAsset(
        address account,
        bytes1 assetType,
        uint8 cashGroupId,
        uint16 instrumentId,
        uint32 maturity
    ) public override view returns (Common.Asset memory, uint256) {
        Common.Asset[] storage portfolio = _accountAssets[account];
        (
            bool found, uint256 index, /* uint128 */, /* bool */ 
        ) = _searchAsset(portfolio, assetType, cashGroupId, instrumentId, maturity, false);

        if (!found) return (NULL_ASSET, index);

        return (portfolio[index], index);
    }

    /**
     * @notice Stateful version of free collateral, first settles all assets in the account before returning
     * the free collateral parameters. Generally, external developers should not need to call this function. It is used
     * internally to both check free collateral and ensure that the portfolio does not have any matured assets.
     * Call `freeCollateralView` if you require a view function.
     * @param account address of account to get free collateral for
     * @return (net free collateral position, an array of the net currency available)
     */
    function freeCollateral(address account) public override returns (int256, int256[] memory, int256[] memory) {
        // This will emit an event, which is the correct action here.
        settleMaturedAssets(account);

        return freeCollateralView(account);
    }

    function freeCollateralAggregateOnly(address account) public override returns (int256) {
        // This will emit an event, which is the correct action here.
        settleMaturedAssets(account);
        
        (int256 fc, /* int256[] memory */, /* int256[] memory */) = freeCollateralView(account);

        return fc;
    }

    function freeCollateralViewAggregateOnly(address account) public override view returns (int256) {
        (int256 fc, /* int256[] memory */, /* int256[] memory */) = freeCollateralView(account);

        return fc;
    }

    /**
     * @notice Stateful version of free collateral called during settlement and liquidation.
     * @dev skip
     * @param account address of account to get free collateral for
     * @param localCurrency local currency for the liquidation
     * @param collateralCurrency collateral currency for the liquidation
     * @return FreeCollateralFactors object
     */
    function freeCollateralFactors(
        address account,
        uint256 localCurrency,
        uint256 collateralCurrency
    ) public override returns (Common.FreeCollateralFactors memory) {
        require(calledByEscrow(), "20");
        // This will not emit an event, which is the correct action here.
        _settleMaturedAssets(account);

        (int256 fc, int256[] memory netCurrencyAvailable, int256[] memory cashClaims) = freeCollateralView(account);

        return Common.FreeCollateralFactors(
            fc,
            netCurrencyAvailable[localCurrency],
            netCurrencyAvailable[collateralCurrency],
            cashClaims[localCurrency],
            cashClaims[collateralCurrency]
        );
    }

    /**
     * @notice Returns the free collateral balance for an account as a view functon.
     * @dev - INVALID_EXCHANGE_RATE: exchange rate returned by the oracle is less than 0
     * @param account account in question
     * @return (net free collateral position, an array of the net currency available)
     */
    function freeCollateralView(address account) public view returns (int256, int256[] memory, int256[] memory) {
        int256[] memory balances = Escrow().getBalances(account);
        return _freeCollateral(account, balances);
    }

    function _freeCollateral(address account, int256[] memory balances) internal view returns (int256, int256[] memory, int256[] memory) {
        Common.Asset[] memory portfolio = _accountAssets[account];
        int256[] memory cashClaims = new int256[](balances.length);

        if (portfolio.length > 0) {
            // This returns the net requirement in each currency held by the portfolio.
            Common.Requirement[] memory requirements = RiskFramework.getRequirement(
                portfolio,
                address(this)
            );

            for (uint256 i; i < requirements.length; i++) {
                uint256 currency = uint256(requirements[i].currency);
                cashClaims[currency] = cashClaims[currency].add(requirements[i].cashClaim);
                balances[currency] = balances[currency].add(requirements[i].cashClaim).add(requirements[i].netfCashValue);
            }
        }

        // Collateral requirements are denominated in ETH and positive.
        int256[] memory ethBalances = Escrow().convertBalancesToETH(balances);

        // Sum up the required balances in ETH
        int256 fc;
        for (uint256 i; i < balances.length; i++) {
            fc = fc.add(ethBalances[i]);
        }

        return (fc, balances, cashClaims);
    }

    /***** Public Authenticated Methods *****/

    /**
     * @notice Updates the portfolio of an account with a asset, merging it into the rest of the
     * portfolio if necessary.
     * @dev skip
     * @param account to insert the asset to
     * @param asset asset to insert into the account
     * @param checkFreeCollateral allows free collateral check to be skipped (BE CAREFUL WITH THIS!)
     */
    function upsertAccountAsset(
        address account,
        Common.Asset calldata asset,
        bool checkFreeCollateral
    ) external override {
        // Only the fCash market can insert assets into a portfolio
        address cashMarket = cashGroups[asset.cashGroupId].cashMarket;
        require(msg.sender == cashMarket, "20");

        Common.Asset[] storage portfolio = _accountAssets[account];
        _upsertAsset(portfolio, asset, false);

        if (checkFreeCollateral) {
            (
                int256 fc, /* int256[] memory */, /* int256[] memory */
            ) = freeCollateral(account);
            require(fc >= 0, "5");
        }
    }

    /**
     * @notice Updates the portfolio of an account with a batch of assets, merging it into the rest of the
     * portfolio if necessary.
     * @dev skip
     * @param account to insert the assets into
     * @param assets array of assets to insert into the account
     * @param checkFreeCollateral allows free collateral check to be skipped (BE CAREFUL WITH THIS!)
     */
    function upsertAccountAssetBatch(
        address account,
        Common.Asset[] calldata assets,
        bool checkFreeCollateral
    ) external override {
        if (assets.length == 0) {
            return;
        }

        // Here we check that all the cash group ids are the same if the liquidation auction
        // is not calling this function. If this is not the case then we have an issue. Cash markets
        // should only ever call this function with the same cash group id for all the assets
        // they submit.
        uint16 id = assets[0].cashGroupId;
        for (uint256 i = 1; i < assets.length; i++) {
            require(assets[i].cashGroupId == id, "53");
        }

        address cashMarket = cashGroups[assets[0].cashGroupId].cashMarket;
        require(msg.sender == cashMarket, "20");

        Common.Asset[] storage portfolio = _accountAssets[account];
        for (uint256 i; i < assets.length; i++) {
            _upsertAsset(portfolio, assets[i], false);
        }

        if (checkFreeCollateral) {
            (
                int256 fc, /* int256[] memory */, /* int256[] memory */
            ) = freeCollateral(account);
            require(fc >= 0, "5");
        }
    }

    /**
     * @notice Transfers a asset from one account to another.
     * @dev skip
     * @param from account to transfer from
     * @param to account to transfer to
     * @param assetType the type of asset to search for
     * @param cashGroupId the cash group id
     * @param instrumentId the instrument id
     * @param maturity the maturity of the asset
     * @param value the amount of notional transfer between accounts
     */
    function transferAccountAsset(
        address from,
        address to,
        bytes1 assetType,
        uint8 cashGroupId,
        uint16 instrumentId,
        uint32 maturity,
        uint128 value
    ) external override {
        // Can only be called by ERC1155 token to transfer assets between accounts.
        require(calledByERC1155Token(), "20");

        Common.Asset[] storage fromPortfolio = _accountAssets[from];
        (
            bool found, uint256 index, /* uint128 */, /* bool */
        ) = _searchAsset(fromPortfolio, assetType, cashGroupId, instrumentId, maturity, false);
        require(found, "54");

        uint32 rate = fromPortfolio[index].rate;
        _reduceAsset(fromPortfolio, fromPortfolio[index], index, value);

        Common.Asset[] storage toPortfolio = _accountAssets[to];
        _upsertAsset(
            toPortfolio,
            Common.Asset(cashGroupId, instrumentId, maturity, assetType, rate, value),
            false
        );

        // All transfers of assets must pass a free collateral check.
        (
            int256 fc, /* int256[] memory */, /* int256[] memory */
        ) = freeCollateral(from);
        require(fc >= 0, "5");

        // Receivers of transfers do not need to pass a free collateral check because we only allow transfers
        // of positive value. Their free collateral position will always increase.
    }

    /**
     * @notice Used by ERC1155 token contract to create block trades for fCash pairs. Allows idiosyncratic
     * fCash when cashGroup is set to zero.
     * @dev skip
     */
    function mintfCashPair(
        address payer,
        address receiver,
        uint8 cashGroupId,
        uint32 maturity,
        uint128 notional
    ) external override {
        require(calledByERC1155Trade(), "20");
        require(cashGroupId != 0 && cashGroupId <= currentCashGroupId, "33");

        uint32 blockTime = uint32(block.timestamp);
        require(blockTime < maturity, "46");

        Common.CashGroup memory fcg = cashGroups[cashGroupId];

        uint32 maxMaturity;
        if (fcg.cashMarket != address(0)) {
            // This is a cash group that is traded on an AMM so we ensure that the maturity fits
            // the cadence.
            require(maturity % fcg.maturityLength == 0, "7");

            maxMaturity = blockTime - (blockTime % fcg.maturityLength) + (fcg.maturityLength * fcg.numMaturities);
        } else {
            // This is an idiosyncratic asset so its max maturity is simply relative to the current time
            maxMaturity = blockTime + fcg.maturityLength;
        }
        require(maturity <= maxMaturity, "45");


        _upsertAsset(
            _accountAssets[payer],
            Common.Asset(
                cashGroupId,
                0,
                maturity,
                Common.getCashPayer(),
                fcg.precision,
                notional
            ),
            false
        );

        _upsertAsset(
            _accountAssets[receiver],
            Common.Asset(
                cashGroupId,
                0,
                maturity,
                Common.getCashReceiver(),
                fcg.precision,
                notional
            ),
            false
        );

        (int256 fc, /* int256[] memory */, /* int256[] memory */) = freeCollateral(payer);
        require(fc >= 0, "5");

        // NOTE: we do not check that the receiver has sufficient free collateral because their collateral
        // position will always increase as a result.
    }

    /**
     * @notice Settles all matured cash assets and liquidity tokens in a user's portfolio. This method is
     * unauthenticated, anyone may settle the assets in any account. This is required for accounts that
     * have negative cash and counterparties need to settle against them. Generally, external developers
     * should not need to call this function. We ensure that accounts are settled on every free collateral
     * check, cash settlement, and liquidation.
     * @param account the account referenced
     */
    function settleMaturedAssets(address account) public override {
        bool didSettle = _settleMaturedAssets(account);

        if (didSettle) {
            emit SettleAccount(account);
        }
    }

    /**
     * @notice Settle a batch of accounts. See note for `settleMaturedAssets`, external developers should not need
     * to call this function.
     * @param accounts an array of accounts to settle
     */
    function settleMaturedAssetsBatch(address[] calldata accounts) external override {
        for (uint256 i; i < accounts.length; i++) {
            _settleMaturedAssets(accounts[i]);
        }

        // We do not want to emit when this is called by escrow during settle cash.
        if (!calledByEscrow()) {
            emit SettleAccountBatch(accounts);
        }
    }

    /**
     * @notice Settles all matured cash assets and liquidity tokens in a user's portfolio. This method is
     * unauthenticated, anyone may settle the assets in any account. This is required for accounts that
     * have negative cash and counterparties need to settle against them.
     * @param account the account referenced
     * @return true if the account had any assets that were settled, used to determine if we emit
     * an event or not
     */
    function _settleMaturedAssets(address account) internal returns (bool) {
        bool didSettle = false;
        Common.Asset[] storage portfolio = _accountAssets[account];
        uint32 blockTime = uint32(block.timestamp);

        // This is only used when merging the account's portfolio for updating cash balances in escrow. We
        // keep this here so that we can do a single function call to settle all the cash in Escrow.
        int256[] memory settledCash = new int256[](uint256(G_NUM_CURRENCIES + 1));
        uint256 length = portfolio.length;

        // Loop through the portfolio and find the assets that have matured.
        for (uint256 i; i < length; i++) {
            if (portfolio[i].maturity <= blockTime) {
                Common.Asset memory asset = portfolio[i];
                // Here we are dealing with a matured asset. We get the appropriate currency for
                // the instrument. We may want to cache this somehow, but in all likelihood there
                // will not be multiple matured assets in the same cash group.
                Common.CashGroup memory fcg = cashGroups[asset.cashGroupId];
                uint16 currency = fcg.currency;

                if (Common.isCashPayer(asset.assetType)) {
                    // If the asset is a payer, we subtract from the cash balance
                    settledCash[currency] = settledCash[currency].sub(asset.notional);
                } else if (Common.isCashReceiver(asset.assetType)) {
                    // If the asset is a receiver, we add to the cash balance
                    settledCash[currency] = settledCash[currency].add(asset.notional);
                } else if (Common.isLiquidityToken(asset.assetType)) {
                    // Settling liquidity tokens is a bit more involved since we need to remove
                    // money from the collateral pools. This function returns the amount of fCash
                    // the liquidity token has a claim to.
                    address cashMarket = fcg.cashMarket;
                    // This function call will transfer the collateral claim back to the Escrow account.
                    uint128 fCashAmount = CashMarket(cashMarket).settleLiquidityToken(
                        account,
                        asset.notional,
                        asset.maturity
                    );
                    settledCash[currency] = settledCash[currency].add(fCashAmount);
                } else {
                    revert("7");
                }

                // Remove asset from the portfolio
                _removeAsset(portfolio, i);
                // The portfolio has gotten smaller, so we need to go back to account for the removed asset.
                i--;
                length = length == 0 ? 0 : length - 1;
                didSettle = true;
            }
        }

        // We call the escrow contract to update the account's cash balances.
        if (didSettle) {
            Escrow().portfolioSettleCash(account, settledCash);
        }

        return didSettle;
    }

    /***** Public Authenticated Methods *****/

    /***** Liquidation Methods *****/

    /**
     * @notice Looks for ways to take cash from the portfolio and return it to the escrow contract during
     * cash settlement.
     * @dev skip
     * @param account the account to extract cash from
     * @param currency the currency that the token should be denominated in
     * @param amount the amount of cash to extract from the portfolio
     * @return returns the amount of remaining cash value (if any) that the function was unable
     *  to extract from the portfolio
     */
    function raiseCurrentCashViaLiquidityToken(
        address account,
        uint16 currency,
        uint128 amount
    ) external override returns (uint128) {
        // Sorting the portfolio ensures that as we iterate through it we see each cash group
        // in batches. However, this means that we won't be able to track the indexes to remove correctly.
        Common.Asset[] memory portfolio = Common._sortPortfolio(_accountAssets[account]);
        TradePortfolioState memory state = _tradePortfolio(account, currency, amount, Common.getLiquidityToken(), portfolio);

        return state.amountRemaining;
    }

    /**
     * @notice Trades cash receiver in the portfolio for cash. Only possible if there are no liquidity tokens in the portfolio
     * as required by `settlefCash` and `liquidatefCash`. If fCash assets cannot be sold in the CashMarket, sells the fCash to
     * the liquidator at a discount.
     * @dev skip
     * @param account the account to extract cash from
     * @param liquidator the account that is initiating the action
     * @param currency the currency that the token should be denominated in
     * @param amount the amount of cash to extract from the portfolio
     * @return returns the amount of remaining cash value (if any) that the function was unable
     *  to extract from the portfolio
     */
    function raiseCurrentCashViaCashReceiver(
        address account,
        address liquidator,
        uint16 currency,
        uint128 amount
    ) external override returns (uint128, uint128) {
        require(calledByEscrow(), "20");
        // Sorting the portfolio ensures that as we iterate through it we see each cash group
        // in batches. However, this means that we won't be able to track the indexes to remove correctly.
        Common.Asset[] memory portfolio = Common._sortPortfolio(_accountAssets[account]);

        // If a portfolio has liquidity tokens then it still has an asset that can be converted to cash more directly than fCash
        // receiver tokens. Will not proceed until the portfolio does not have liquidity tokens.
        uint256 fCashReceivers;
        for (uint256 i; i < portfolio.length; i++) {
            require(!Common.isLiquidityToken(portfolio[i].assetType), "56");

            // Technically we should check for the proper currency here but we do this inside
            // _tradefCashLiquidator. Not doing it here to save some SLOAD calls. This serves as
            // an upper bound for the receivers in the portfolio.
            if (Common.isCashReceiver(portfolio[i].assetType)) fCashReceivers++;
        }

        require(fCashReceivers > 0 && amount > 0, "57");

        (uint128 amountRemaining, uint128 liquidatorPayment) = _tradefCashLiquidator(
            _accountAssets[account],
            _accountAssets[liquidator],
            amount,
            currency
        );

        return (amountRemaining, liquidatorPayment);
    }

    /**
     * @notice Trades fCash receivers to the liquidator at a discount. Transfers the assets between portfolios and returns
     * the amount that the liquidator must pay in return for the assets.
     */
    function _tradefCashLiquidator(
        Common.Asset[] storage portfolio,
        Common.Asset[] storage liquidatorPortfolio,
        uint128 amountRemaining,
        uint16 currency
    ) internal returns (uint128, uint128) {
        uint128 liquidatorPayment;
        uint128 notionalToTransfer;

        uint256 length = portfolio.length;
        Common.CashGroup memory cg;
        uint128 fCashHaircut = PortfoliosStorageSlot._fCashHaircut();
        uint128 fCashMaxHaircut = PortfoliosStorageSlot._fCashMaxHaircut();

        for (uint256 i; i < length; i++) {
            Common.Asset memory asset = portfolio[i];
            if (Common.isCashReceiver(asset.assetType)) {
                cg = cashGroups[asset.cashGroupId];
                if (cg.currency != currency) continue;

                (liquidatorPayment, notionalToTransfer, amountRemaining) = _calculateNotionalToTransfer(
                    fCashHaircut,
                    fCashMaxHaircut,
                    liquidatorPayment,
                    amountRemaining,
                    asset
                );

                if (notionalToTransfer == asset.notional) {
                    // This is a full transfer and we will remove the asset, we need to update the loop
                    // variables as well.
                    _removeAsset(portfolio, i);
                    i--;
                    length = length == 0 ? 0 : length - 1;
                } else {
                    // This is a partial transfer and it means that state.amountRemaining is now
                    // equal to zero and we will exit the loop.
                    _reduceAsset(portfolio, portfolio[i], i, notionalToTransfer);
                }

                asset.notional = notionalToTransfer;
                _upsertAsset(liquidatorPortfolio, asset, false);
            }

            if (amountRemaining == 0) break;
        }

        return (amountRemaining, liquidatorPayment);
    }

    function _calculateNotionalToTransfer(
        uint128 fCashHaircut,
        uint128 fCashMaxHaircut,
        uint128 liquidatorPayment,
        uint128 amountRemaining,
        Common.Asset memory asset
    ) internal view returns (uint128, uint128, uint128) {
        // blockTime is in here because of the stack size
        uint32 blockTime = uint32(block.timestamp);
        uint128 notionalToTransfer;
        uint128 assetValue;
        int256 tmp = RiskFramework._calculateReceiverValue(
            asset.notional,
            asset.maturity,
            blockTime,
            fCashHaircut,
            fCashMaxHaircut
        );
        // Asset values will always be positive.
        require(tmp >= 0);
        assetValue = uint128(tmp);

        if (assetValue >= amountRemaining) {
            notionalToTransfer = SafeCast.toUint128(
                uint256(asset.notional)
                    .mul(amountRemaining)
                    .div(assetValue)
            );
            liquidatorPayment = liquidatorPayment.add(amountRemaining);
            amountRemaining = 0;
        } else {
            notionalToTransfer = asset.notional;
            amountRemaining = amountRemaining - assetValue;
            liquidatorPayment = liquidatorPayment.add(assetValue);
        }

        return (liquidatorPayment, notionalToTransfer, amountRemaining);
    }

    /**
     * @notice A generic, internal function that trades positions within a portfolio.
     * @param account account that holds the portfolio to trade
     * @param currency the currency that the trades should be denominated in
     * @param amount of cash available
     * @param tradeType the assetType to trade in the portfolio
     */
    function _tradePortfolio(
        address account,
        uint16 currency,
        uint128 amount,
        bytes1 tradeType,
        Common.Asset[] memory portfolio
    ) internal returns (TradePortfolioState memory) {
        // Only Escrow can execute actions to trade the portfolio
        require(calledByEscrow(), "20");

        TradePortfolioState memory state = TradePortfolioState(
            amount,
            0,
            0,
            // At most we will add twice as many assets as the portfolio (this would be for liquidity token)
            // changes where we update both liquidity tokens as well as cash obligations.
            new Common.Asset[](portfolio.length * 2)
        );

        if (portfolio.length == 0) return state;

        // We initialize these cash groups here knowing that there is at least one asset in the portfolio
        uint8 cashGroupId = portfolio[0].cashGroupId;
        Common.CashGroup memory cg = cashGroups[cashGroupId];

        // Iterate over the portfolio and trade as required.
        for (uint256 i; i < portfolio.length; i++) {
            if (cashGroupId != portfolio[i].cashGroupId) {
                // Here the cash group has changed and therefore the fCash market has also
                // changed. We need to unlock cash from the previous fCash market.
                Escrow().unlockCurrentCash(currency, cg.cashMarket, state.unlockedCurrentCash);
                // Reset this counter for the next group
                state.unlockedCurrentCash = 0;

                // Fetch the new cash group.
                cashGroupId = portfolio[i].cashGroupId;
                cg = cashGroups[cashGroupId];
            }

            // This is an idiosyncratic fCash market and we cannot trade out of it
            if (cg.cashMarket == address(0)) continue;
            if (cg.currency != currency) continue;
            if (portfolio[i].assetType != tradeType) continue;

            if (Common.isLiquidityToken(portfolio[i].assetType)) {
                _tradeLiquidityToken(portfolio[i], cg.cashMarket, state);
            } else {
                revert("7");
            }

            // No more cash left so we break out of the loop
            if (state.amountRemaining == 0) {
                break;
            }
        }

        if (state.unlockedCurrentCash != 0) {
            // Transfer cash from the last cash group in the previous loop
            Escrow().unlockCurrentCash(currency, cg.cashMarket, state.unlockedCurrentCash);
        }

        Common.Asset[] storage accountStorage = _accountAssets[account];
        for (uint256 i; i < state.indexCount; i++) {
            // This bypasses the free collateral check that we do not need to do here
            _upsertAsset(accountStorage, state.portfolioChanges[i], true);
        }

        return state;
    }

    /**
     * @notice Extracts cash from liquidity tokens.
     * @param asset the liquidity token to extract cash from
     * @param cashMarket the address of the fCash market
     * @param state state of the portfolio trade operation
     */
    function _tradeLiquidityToken(
        Common.Asset memory asset,
        address cashMarket,
        TradePortfolioState memory state
    ) internal {
        (uint128 cash, uint128 fCash, uint128 tokens) = CashMarket(cashMarket).tradeLiquidityToken(
            state.amountRemaining,
            asset.notional,
            asset.maturity
        );
        state.amountRemaining = state.amountRemaining.sub(cash);

        // This amount of cash has been removed from the market
        state.unlockedCurrentCash = state.unlockedCurrentCash.add(cash);

        // This is a CASH_RECEIVER that is credited back as a result of settling the liquidity token.
        state.portfolioChanges[state.indexCount] = Common.Asset(
            asset.cashGroupId,
            asset.instrumentId,
            asset.maturity,
            Common.getCashReceiver(),
            asset.rate,
            fCash
        );
        state.indexCount++;

        // This marks the removal of an amount of liquidity tokens
        state.portfolioChanges[state.indexCount] = Common.Asset(
            asset.cashGroupId,
            asset.instrumentId,
            asset.maturity,
            Common.makeCounterparty(Common.getLiquidityToken()),
            asset.rate,
            tokens
        );
        state.indexCount++;
    }

    /***** Liquidation Methods *****/

    /***** Internal Portfolio Methods *****/

    /**
     * @notice Returns the offset for a specific asset in an array of assets given a storage
     * pointer to a asset array. The parameters of this function define a unique id of
     * the asset.
     * @param portfolio storage pointer to the list of assets
     * @param assetType the type of asset to search for
     * @param cashGroupId the cash group id
     * @param instrumentId the instrument id
     * @param maturity maturity of the asset
     * @param findCounterparty find the counterparty of the asset
     *
     * @return (bool if found, index of asset, notional amount, is counterparty asset or not)
     */
    function _searchAsset(
        Common.Asset[] storage portfolio,
        bytes1 assetType,
        uint8 cashGroupId,
        uint16 instrumentId,
        uint32 maturity,
        bool findCounterparty
    ) internal view returns (bool, uint256, uint128, bool) {
        uint256 length = portfolio.length;
        if (length == 0) {
            return (false, length, 0, false);
        }

        for (uint256 i; i < length; i++) {
            Common.Asset storage t = portfolio[i];
            if (t.cashGroupId != cashGroupId) continue;
            if (t.instrumentId != instrumentId) continue;
            if (t.maturity != maturity) continue;

            bytes1 s = t.assetType;
            if (s == assetType) {
                return (true, i, t.notional, false);
            } else if (findCounterparty && s == Common.makeCounterparty(assetType)) {
                return (true, i, t.notional, true);
            }
        }

        return (false, length, 0, false);
    }

    /**
     * @notice Checks for the existence of a matching asset and then chooses update or append
     * as appropriate.
     * @param portfolio a list of assets
     * @param asset the new asset to add
     * @param liquidateAllowAdd allows liquidate function to continue to add assets to the portfolio
     */
    function _upsertAsset(
        Common.Asset[] storage portfolio,
        Common.Asset memory asset,
        bool liquidateAllowAdd
    ) internal {
        (bool found, uint256 index, uint128 notional, bool isCounterparty) = _searchAsset(
            portfolio,
            asset.assetType,
            asset.cashGroupId,
            asset.instrumentId,
            asset.maturity,
            true
        );

        if (!found) {
            // If not found then we append to the portfolio. We won't allow it to grow past the max assets parameter
            // except in the case of liquidating liquidity tokens. When doing so, we may need to add cash receiver tokens
            // back into the portfolio.
            require(index <= G_MAX_ASSETS || liquidateAllowAdd, "34");

            if (Common.isLiquidityToken(asset.assetType) && Common.isPayer(asset.assetType)) {
                // You cannot have a payer liquidity token without an existing liquidity token entry in
                // your portfolio since liquidity tokens must always have a positive balance.
                revert("8");
            }

            // Append the new asset
            portfolio.push(asset);
        } else if (!isCounterparty) {
            // If the asset types match, then just aggregate the notional amounts.
            portfolio[index].notional = notional.add(asset.notional);
        } else {
            if (notional >= asset.notional) {
                // We have enough notional of the asset to reduce or remove the asset.
                _reduceAsset(portfolio, portfolio[index], index, asset.notional);
            } else if (Common.isLiquidityToken(asset.assetType)) {
                // Liquidity tokens cannot go below zero.
                revert("8");
            } else if (Common.isCash(asset.assetType)) {
                // Otherwise, we need to flip the sign of the asset and set the notional amount
                // to the difference.
                portfolio[index].notional = asset.notional.sub(notional);
                portfolio[index].assetType = asset.assetType;
            }
        }
    }

    /**
     * @notice Reduces the notional of a asset by value, if value is equal to the total notional
     * then removes it from the portfolio.
     * @param portfolio a storage pointer to the account's assets
     * @param asset a storage pointer to the asset
     * @param index of the asset in the portfolio
     * @param value the amount of notional to reduce
     */
    function _reduceAsset(
        Common.Asset[] storage portfolio,
        Common.Asset storage asset,
        uint256 index,
        uint128 value
    ) internal {
        require(asset.assetType != 0x00, "7");
        require(asset.notional >= value, "8");

        if (asset.notional == value) {
            _removeAsset(portfolio, index);
        } else {
            // We did the check above that will prevent an underflow here
            asset.notional = asset.notional - value;
        }
    }

    /**
     * @notice Removes a asset from a portfolio, used when assets are transferred by _reduceAsset
     * or when they are settled.
     * @param portfolio a storage pointer to the assets
     * @param index the index of the asset to remove
     */
    function _removeAsset(Common.Asset[] storage portfolio, uint256 index) internal {
        uint256 lastIndex = portfolio.length - 1;
        if (index != lastIndex) {
            Common.Asset memory lastAsset = portfolio[lastIndex];
            portfolio[index] = lastAsset;
        }
        portfolio.pop();
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: GPL-3.0-only



import "../lib/SafeInt256.sol";
import "../lib/SafeMath.sol";

import "../utils/Governed.sol";
import "../utils/Common.sol";
import "../interface/IPortfoliosCallable.sol";
import "../storage/PortfoliosStorage.sol";

import "../CashMarket.sol";
import "@openzeppelin/contracts/utils/SafeCast.sol";

/**
 * @title Risk Framework
 * @notice Calculates the currency requirements for a portfolio.
 */
library RiskFramework {
    using SafeMath for uint256;
    using SafeInt256 for int256;

    /** The cash ladder for a single instrument or cash group */
    struct CashLadder {
        // The cash group id for this cash ladder
        uint16 id;
        // The currency group id for this cash ladder
        uint16 currency;
        // The cash ladder for the maturities of this cash group
        int256[] cashLadder;
    }

    /**
     * @notice Given a portfolio of assets, returns a set of requirements in every currency represented.
     * @param portfolio a portfolio of assets
     * @return a set of requirements in every cash group represented by the portfolio
     */
    function getRequirement(
        Common.Asset[] memory portfolio,
        address Portfolios
    ) public view returns (Common.Requirement[] memory) {
        Common._sortPortfolio(portfolio);

        // Each position in this array will hold the value of the portfolio in each maturity.
        (Common.CashGroup[] memory cashGroups, CashLadder[] memory ladders) = _fetchCashGroups(
            portfolio,
            IPortfoliosCallable(Portfolios)
        );

        uint128 fCashHaircut = PortfoliosStorageSlot._fCashHaircut();
        uint128 fCashMaxHaircut = PortfoliosStorageSlot._fCashMaxHaircut();
        uint32 blockTime = uint32(block.timestamp);

        int256[] memory cashClaims = _getCashLadders(
            portfolio,
            cashGroups,
            ladders,
            PortfoliosStorageSlot._liquidityHaircut(),
            blockTime
        );

        // We now take the per cash group cash ladder and summarize it into a single requirement. The future
        // cash group requirements will be aggregated into a single currency requirement in the free collateral function
        Common.Requirement[] memory requirements = new Common.Requirement[](ladders.length);

        for (uint256 i; i < ladders.length; i++) {
            requirements[i].currency = ladders[i].currency;
            requirements[i].cashClaim = cashClaims[i];
            uint32 initialMaturity;
            if (blockTime % cashGroups[i].maturityLength == 0) {
                // If this is true then blockTime = maturity at index 0 and we do not add an offset.
                initialMaturity = blockTime;
            } else {
                initialMaturity = blockTime - (blockTime % cashGroups[i].maturityLength) + cashGroups[i].maturityLength;
            }

            for (uint256 j; j < ladders[i].cashLadder.length; j++) {
                int256 netfCash = ladders[i].cashLadder[j];
                if (netfCash > 0) {
                    uint32 maturity = initialMaturity + cashGroups[i].maturityLength * uint32(j);
                    // If netfCash value is positive here then we have to haircut it.
                    netfCash = _calculateReceiverValue(netfCash, maturity, blockTime, fCashHaircut, fCashMaxHaircut);
                }

                requirements[i].netfCashValue = requirements[i].netfCashValue.add(netfCash);
            }
        }

        return requirements;
    }

    /**
     * @notice Calculates the cash ladders for every cash group in a portfolio.
     *
     * @param portfolio a portfolio of assets
     * @return an array of cash ladders and an npv figure for every cash group
     */
    function _getCashLadders(
        Common.Asset[] memory portfolio,
        Common.CashGroup[] memory cashGroups,
        CashLadder[] memory ladders,
        uint128 liquidityHaircut,
        uint32 blockTime
    ) internal view returns (int256[] memory) {

        // This will hold the current cash claims balance
        int256[] memory cashClaims = new int256[](ladders.length);

        // Set up the first group's cash ladder before we iterate
        uint256 groupIndex;
        // In this loop we know that the assets are sorted and none of them have matured. We always call
        // settleMaturedAssets before we enter the risk framework.
        for (uint256 i; i < portfolio.length; i++) {
            if (portfolio[i].cashGroupId != ladders[groupIndex].id) {
                // This is the start of a new group
                groupIndex++;
            }

            (int256 fCashAmount, int256 cashClaimAmount) = _calculateAssetValue(
                portfolio[i],
                cashGroups[groupIndex],
                blockTime,
                liquidityHaircut
            );

            cashClaims[groupIndex] = cashClaims[groupIndex].add(cashClaimAmount);
            if (portfolio[i].maturity <= blockTime) {
                // If asset has matured then all the fCash is considered a current cash claim. This branch will only be
                // reached when calling this function as a view. During liquidation and settlement calls we ensure that
                // all matured assets have been settled to cash first.
                cashClaims[groupIndex] = cashClaims[groupIndex].add(fCashAmount);
            } else {
                uint256 offset = (portfolio[i].maturity - blockTime) / cashGroups[groupIndex].maturityLength;

                if (cashGroups[groupIndex].cashMarket == address(0)) {
                    // We do not allow positive fCash to net out negative fCash for idiosyncratic trades
                    // so we zero out positive cash at this point.
                    fCashAmount = fCashAmount > 0 ? 0 : fCashAmount;
                }

                ladders[groupIndex].cashLadder[offset] = ladders[groupIndex].cashLadder[offset].add(fCashAmount);
            }
        }

        return cashClaims;
    }

    function _calculateAssetValue(
        Common.Asset memory asset,
        Common.CashGroup memory cg,
        uint32 blockTime,
        uint128 liquidityHaircut
    ) internal view returns (int256, int256) {
        int256 cashClaim;
        int256 fCash;

        if (Common.isLiquidityToken(asset.assetType)) {
            (cashClaim, fCash) = _calculateLiquidityTokenClaims(asset, cg.cashMarket, blockTime, liquidityHaircut);
        } else if (Common.isCashPayer(asset.assetType)) {
            fCash = int256(asset.notional).neg();
        } else if (Common.isCashReceiver(asset.assetType)) {
            fCash = int256(asset.notional);
        }

        return (fCash, cashClaim);
    }

    function _calculateReceiverValue(
        int256 fCash,
        uint32 maturity,
        uint32 blockTime,
        uint128 fCashHaircut,
        uint128 fCashMaxHaircut
    ) internal pure returns (int256) {
        require(maturity > blockTime);

        // As we roll down to maturity the haircut value will decrease until
        // we hit the maxPostHaircutValue where we cap this.
        // fCash - fCash * haircut * timeToMaturity / secondsInYear
        int256 postHaircutValue = fCash.sub(
            fCash
                .mul(fCashHaircut)
                .mul(maturity - blockTime)
                .div(Common.SECONDS_IN_YEAR)
                // fCashHaircut is in 1e18
                .div(Common.DECIMALS)
        );

        int256 maxPostHaircutValue = fCash
            // This will be set to something like 0.95e18
            .mul(fCashMaxHaircut)
            .div(Common.DECIMALS);

        if (postHaircutValue < maxPostHaircutValue) {
            return postHaircutValue;
        } else {
            return maxPostHaircutValue;
        }
    }

    function _calculateLiquidityTokenClaims(
        Common.Asset memory asset,
        address cashMarket,
        uint32 blockTime,
        uint128 liquidityHaircut
    ) internal view returns (uint128, uint128) {
        CashMarket.Market memory market = CashMarket(cashMarket).getMarket(asset.maturity);

        uint256 cashClaim;
        uint256 fCashClaim;

        if (blockTime < asset.maturity) {
            // We haircut these amounts because it is uncertain how much claim either of these will actually have
            // when it comes to reclaim the liquidity token. For example, there may be less collateral in the pool
            // relative to fCash due to trades that have happened between the initial free collateral check
            // and the liquidation.
            cashClaim = uint256(market.totalCurrentCash)
                .mul(asset.notional)
                .mul(liquidityHaircut)
                .div(Common.DECIMALS)
                .div(market.totalLiquidity);

            fCashClaim = uint256(market.totalfCash)
                .mul(asset.notional)
                .mul(liquidityHaircut)
                .div(Common.DECIMALS)
                .div(market.totalLiquidity);
        } else {
            cashClaim = uint256(market.totalCurrentCash)
                .mul(asset.notional)
                .div(market.totalLiquidity);

            fCashClaim = uint256(market.totalfCash)
                .mul(asset.notional)
                .div(market.totalLiquidity);
        }

        return (SafeCast.toUint128(cashClaim), SafeCast.toUint128(fCashClaim));
    }

    function _fetchCashGroups(
        Common.Asset[] memory portfolio,
        IPortfoliosCallable Portfolios
    ) internal view returns (Common.CashGroup[] memory, CashLadder[] memory) {
        uint8[] memory groupIds = new uint8[](portfolio.length);
        uint256 numGroups;

        groupIds[numGroups] = portfolio[0].cashGroupId;
        // Count the number of cash groups in the portfolio, we will return a cash ladder for each.
        for (uint256 i = 1; i < portfolio.length; i++) {
            if (portfolio[i].cashGroupId != groupIds[numGroups]) {
                numGroups++;
                groupIds[numGroups] = portfolio[i].cashGroupId;
            }
        }

        uint8[] memory requestGroups = new uint8[](numGroups + 1);
        for (uint256 i; i < requestGroups.length; i++) {
            requestGroups[i] = groupIds[i];
        }

        Common.CashGroup[] memory cgs = Portfolios.getCashGroups(requestGroups);

        CashLadder[] memory ladders = new CashLadder[](cgs.length);
        for (uint256 i; i < ladders.length; i++) {
            ladders[i].id = requestGroups[i];
            ladders[i].currency = cgs[i].currency;
            ladders[i].cashLadder = new int256[](cgs[i].numMaturities);
        }

        return (cgs, ladders);
    }
}

pragma solidity ^0.6.0;

// SPDX-License-Identifier: GPL-3.0-only


import "../utils/Common.sol";
import "./StorageSlot.sol";

library PortfoliosStorageSlot {
    bytes32 internal constant S_FCASH_MAX_HAIRCUT = 0xa35d3afd01f041be85725e31961e40294ad52f3b0371f222b6077b51388e2d35;
    bytes32 internal constant S_FCASH_HAIRCUT = 0x9eea34a788ac1b0fc599e6226afe7dce1337e8a7ce0bd70286c66f8d6a2fdd3c;
    bytes32 internal constant S_LIQUIDITY_HAIRCUT = 0x69aa87f611e12c87a7363d80aa4028e739f820a36283663a1ae40da7c3723fd0;

    function _fCashMaxHaircut() internal view returns (uint128) {
        return uint128(StorageSlot._getStorageUint(S_FCASH_MAX_HAIRCUT));
    }

    function _fCashHaircut() internal view returns (uint128) {
        return uint128(StorageSlot._getStorageUint(S_FCASH_HAIRCUT));
    }

    function _liquidityHaircut() internal view returns (uint128) {
        return uint128(StorageSlot._getStorageUint(S_LIQUIDITY_HAIRCUT));
    }

    function _setfCashMaxHaircut(uint128 fCashMaxHaircut) internal {
        StorageSlot._setStorageUint(S_FCASH_MAX_HAIRCUT, fCashMaxHaircut);
    }

    function _setfCashHaircut(uint128 fCashHaircut) internal {
        StorageSlot._setStorageUint(S_FCASH_HAIRCUT, fCashHaircut);
    }

    function _setLiquidityHaircut(uint128 liquidityHaircut) internal {
        StorageSlot._setStorageUint(S_LIQUIDITY_HAIRCUT, liquidityHaircut);
    }
}

contract PortfoliosStorage {
    uint8 internal constant MAX_CASH_GROUPS = 0xFE;

    // This is used when referencing a asset that does not exist.
    Common.Asset internal NULL_ASSET;

    // Mapping between accounts and their assets
    mapping(address => Common.Asset[]) internal _accountAssets;

    // Mapping between cash group ids and cash groups
    mapping(uint8 => Common.CashGroup) public cashGroups;
    // The current cash group id, 0 is unused
    uint8 public currentCashGroupId;

    /****** Governance Parameters ******/

    // Number of currency groups, set by the Escrow account.
    uint16 public G_NUM_CURRENCIES;
    // This is the max number of assets that can be in a portfolio. This is to prevent idiosyncratic assets from
    // building up in portfolios such that they can't be liquidated due to gas cost restrictions.
    uint256 public G_MAX_ASSETS;
    /****** Governance Parameters ******/

    function G_FCASH_MAX_HAIRCUT() public view returns (uint128) {
        return PortfoliosStorageSlot._fCashMaxHaircut();
    }

    function G_FCASH_HAIRCUT() public view returns (uint128) {
        return PortfoliosStorageSlot._fCashHaircut();
    }

    function G_LIQUIDITY_HAIRCUT() public view returns (uint128) {
        return PortfoliosStorageSlot._liquidityHaircut();
    }
}

pragma solidity ^0.6.0;



import './BaseAdminUpgradeabilityProxy.sol';

/**
 * @title AdminUpgradeabilityProxy
 * @dev Extends from BaseAdminUpgradeabilityProxy with a constructor for 
 * initializing the implementation, admin, and init data.
 */
contract AdminUpgradeabilityProxy is BaseAdminUpgradeabilityProxy, UpgradeabilityProxy {
  /**
   * Contract constructor.
   * @param _logic address of the initial implementation.
   * @param _admin Address of the proxy administrator.,
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  constructor(address _logic, address _admin, bytes memory _data) UpgradeabilityProxy(_logic, _data) public payable {
    assert(ADMIN_SLOT == bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1));
    _setAdmin(_admin);
  }
}

pragma solidity ^0.6.0;



import './UpgradeabilityProxy.sol';

/**
 * @title BaseAdminUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with an authorization
 * mechanism for administrative tasks.
 * All external functions in this contract must be guarded by the
 * `ifAdmin` modifier. See ethereum/solidity#3864 for a Solidity
 * feature proposal that would enable this to be done automatically.
 */
contract BaseAdminUpgradeabilityProxy is BaseUpgradeabilityProxy {
  /**
   * @dev Emitted when the administration has been transferred.
   * @param previousAdmin Address of the previous admin.
   * @param newAdmin Address of the new admin.
   */
  event AdminChanged(address previousAdmin, address newAdmin);

  /**
   * @dev Storage slot with the admin of the contract.
   * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
   * validated in the constructor.
   */

  bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

  /**
   * @dev Modifier to check whether the `msg.sender` is the admin.
   * If it is, it will run the function. Otherwise, it will delegate the call
   * to the implementation.
   */
  modifier ifAdmin() {
    if (msg.sender == _admin()) {
      _;
    } else {
      _fallback();
    }
  }

  /**
   * @return The address of the proxy admin.
   */
  function admin() external ifAdmin returns (address) {
    return _admin();
  }

  /**
   * @return The address of the implementation.
   */
  function implementation() external ifAdmin returns (address) {
    return _implementation();
  }

  /**
   * @dev Changes the admin of the proxy.
   * Only the current admin can call this function.
   * @param newAdmin Address to transfer proxy administration to.
   */
  function changeAdmin(address newAdmin) external ifAdmin {
    require(newAdmin != address(0), "Cannot change the admin of a proxy to the zero address");
    emit AdminChanged(_admin(), newAdmin);
    _setAdmin(newAdmin);
  }

  /**
   * @dev Upgrade the backing implementation of the proxy.
   * Only the admin can call this function.
   * @param newImplementation Address of the new implementation.
   */
  function upgradeTo(address newImplementation) external ifAdmin {
    _upgradeTo(newImplementation);
  }

  /**
   * @dev Upgrade the backing implementation of the proxy and call a function
   * on the new implementation.
   * This is useful to initialize the proxied contract.
   * @param newImplementation Address of the new implementation.
   * @param data Data to send as msg.data in the low level call.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   */
  function upgradeToAndCall(address newImplementation, bytes calldata data) payable external ifAdmin {
    _upgradeTo(newImplementation);
    (bool success,) = newImplementation.delegatecall(data);
    require(success);
  }

  /**
   * @return adm The admin slot.
   */
  function _admin() internal view returns (address adm) {
    bytes32 slot = ADMIN_SLOT;
    assembly {
      adm := sload(slot)
    }
  }

  /**
   * @dev Sets the address of the proxy admin.
   * @param newAdmin Address of the new proxy admin.
   */
  function _setAdmin(address newAdmin) internal {
    bytes32 slot = ADMIN_SLOT;

    assembly {
      sstore(slot, newAdmin)
    }
  }

  /**
   * @dev Only fall back when the sender is not the admin.
   */
  function _willFallback() override internal {
    require(msg.sender != _admin(), "Cannot call fallback function from the proxy admin");
  }
}

pragma solidity ^0.6.0;



import './BaseUpgradeabilityProxy.sol';

/**
 * @title UpgradeabilityProxy
 * @dev Extends BaseUpgradeabilityProxy with a constructor for initializing
 * implementation and init data.
 */
abstract contract UpgradeabilityProxy is BaseUpgradeabilityProxy {
  /**
   * @dev Contract constructor.
   * @param _logic Address of the initial implementation.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  constructor(address _logic, bytes memory _data) public payable {
    assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1));
    _setImplementation(_logic);
    if(_data.length > 0) {
      (bool success,) = _logic.delegatecall(_data);
      require(success);
    }
  }  
}

pragma solidity ^0.6.0;



import './Proxy.sol';
import './Address.sol';

/**
 * @title BaseUpgradeabilityProxy
 * @dev This contract implements a proxy that allows to change the
 * implementation address to which it will delegate.
 * Such a change is called an implementation upgrade.
 */
abstract contract BaseUpgradeabilityProxy is Proxy {
  /**
   * @dev Emitted when the implementation is upgraded.
   * @param implementation Address of the new implementation.
   */
  event Upgraded(address indexed implementation);

  /**
   * @dev Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  /**
   * @dev Returns the current implementation.
   * @return impl address of the current implementation
   */
  function _implementation() internal override view returns (address impl) {
    bytes32 slot = IMPLEMENTATION_SLOT;
    assembly {
      impl := sload(slot)
    }
  }

  /**
   * @dev Upgrades the proxy to a new implementation.
   * @param newImplementation Address of the new implementation.
   */
  function _upgradeTo(address newImplementation) internal {
    _setImplementation(newImplementation);
    emit Upgraded(newImplementation);
  }

  /**
   * @dev Sets the implementation address of the proxy.
   * @param newImplementation Address of the new implementation.
   */
  function _setImplementation(address newImplementation) internal {
    require(Address.isContract(newImplementation), "Cannot set a proxy implementation to a non-contract address");

    bytes32 slot = IMPLEMENTATION_SLOT;

    assembly {
      sstore(slot, newImplementation)
    }
  }
}

pragma solidity ^0.6.0;



/**
 * @title Proxy
 * @dev Implements delegation of calls to other contracts, with proper
 * forwarding of return values and bubbling of failures.
 * It defines a fallback function that delegates all calls to the address
 * returned by the abstract _implementation() internal function.
 */
abstract contract Proxy {
  /**
   * @dev Fallback function.
   * Implemented entirely in `_fallback`.
   */
  fallback() payable external {
    _fallback();
  }

  /**
   * @return The Address of the implementation.
   */
  function _implementation() internal virtual view returns (address);

  /**
   * @dev Delegates execution to an implementation contract.
   * This is a low level function that doesn't return to its internal call site.
   * It will return to the external caller whatever the implementation returns.
   * @param implementation Address to delegate.
   */
  function _delegate(address implementation) internal {
    assembly {
      // Copy msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0.
      calldatacopy(0, 0, calldatasize())

      // Call the implementation.
      // out and outsize are 0 because we don't know the size yet.
      let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

      // Copy the returned data.
      returndatacopy(0, 0, returndatasize())

      switch result
      // delegatecall returns 0 on error.
      case 0 { revert(0, returndatasize()) }
      default { return(0, returndatasize()) }
    }
  }

  /**
   * @dev Function that is run as the first thing in the fallback function.
   * Can be redefined in derived contracts to add functionality.
   * Redefinitions must call super._willFallback().
   */
  function _willFallback() internal virtual;

  /**
   * @dev fallback implementation.
   * Extracted to enable manual triggering.
   */
  function _fallback() internal {
    _willFallback();
    _delegate(_implementation());
  }
}

pragma solidity ^0.6.0;



import "./InitializableAdminUpgradeabilityProxy.sol";
import "./ECDSA.sol";

// Renamed from ProxyFactory because of name clash with Typechain
contract CreateProxyFactory {
  
  event ProxyCreated(address proxy);

  bytes32 private contractCodeHash;

  constructor() public {
    contractCodeHash = keccak256(
      type(InitializableAdminUpgradeabilityProxy).creationCode
    );
  }

  function deployMinimal(address _logic, bytes memory _data) public returns (address proxy) {
    // Adapted from https://github.com/optionality/clone-factory/blob/32782f82dfc5a00d103a7e61a17a5dedbd1e8e9d/contracts/CloneFactory.sol
    bytes20 targetBytes = bytes20(_logic);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      proxy := create(0, clone, 0x37)
    }
    
    emit ProxyCreated(address(proxy));

    if(_data.length > 0) {
      (bool success,) = proxy.call(_data);
      require(success);
    }    
  }

  function deploy(uint256 _salt, address _logic, address _admin, bytes memory _data) public returns (address) {
    return _deployProxy(_salt, _logic, _admin, _data, msg.sender);
  }

  function deploySigned(uint256 _salt, address _logic, address _admin, bytes memory _data, bytes memory _signature) public returns (address) {
    address signer = getSigner(_salt, _logic, _admin, _data, _signature);
    require(signer != address(0), "Invalid signature");
    return _deployProxy(_salt, _logic, _admin, _data, signer);
  }

  function getDeploymentAddress(uint256 _salt, address _sender) public view returns (address) {
    // Adapted from https://github.com/archanova/solidity/blob/08f8f6bedc6e71c24758d20219b7d0749d75919d/contracts/contractCreator/ContractCreator.sol
    bytes32 salt = _getSalt(_salt, _sender);
    bytes32 rawAddress = keccak256(
      abi.encodePacked(
        bytes1(0xff),
        address(this),
        salt,
        contractCodeHash
      )
    );

    return address(bytes20(rawAddress << 96));
  }

  function getSigner(uint256 _salt, address _logic, address _admin, bytes memory _data, bytes memory _signature) public view returns (address) {
    bytes32 msgHash = OpenZeppelinUpgradesECDSA.toEthSignedMessageHash(
      keccak256(
        abi.encodePacked(
          _salt, _logic, _admin, _data, address(this)
        )
      )
    );

    return OpenZeppelinUpgradesECDSA.recover(msgHash, _signature);
  }

  function _deployProxy(uint256 _salt, address _logic, address _admin, bytes memory _data, address _sender) internal returns (address) {
    InitializableAdminUpgradeabilityProxy proxy = _createProxy(_salt, _sender);
    emit ProxyCreated(address(proxy));
    proxy.initialize(_logic, _admin, _data);
    return address(proxy);
  }

  function _createProxy(uint256 _salt, address _sender) internal returns (InitializableAdminUpgradeabilityProxy) {
    address payable addr;
    bytes memory code = type(InitializableAdminUpgradeabilityProxy).creationCode;
    bytes32 salt = _getSalt(_salt, _sender);

    assembly {
      addr := create2(0, add(code, 0x20), mload(code), salt)
      if iszero(extcodesize(addr)) {
        revert(0, 0)
      }
    }

    return InitializableAdminUpgradeabilityProxy(addr);
  }

  function _getSalt(uint256 _salt, address _sender) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_salt, _sender)); 
  }
}

pragma solidity ^0.6.0;



import './BaseAdminUpgradeabilityProxy.sol';
import './InitializableUpgradeabilityProxy.sol';

/**
 * @title InitializableAdminUpgradeabilityProxy
 * @dev Extends from BaseAdminUpgradeabilityProxy with an initializer for 
 * initializing the implementation, admin, and init data.
 */
contract InitializableAdminUpgradeabilityProxy is BaseAdminUpgradeabilityProxy, InitializableUpgradeabilityProxy {
  /**
   * Contract initializer.
   * @param _logic address of the initial implementation.
   * @param _admin Address of the proxy administrator.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  function initialize(address _logic, address _admin, bytes memory _data) public payable {
    require(_implementation() == address(0));
    InitializableUpgradeabilityProxy.initialize(_logic, _data);
    assert(ADMIN_SLOT == bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1));
    _setAdmin(_admin);
  }
}

pragma solidity ^0.6.0;



import './BaseUpgradeabilityProxy.sol';

/**
 * @title InitializableUpgradeabilityProxy
 * @dev Extends BaseUpgradeabilityProxy with an initializer for initializing
 * implementation and init data.
 */
abstract contract InitializableUpgradeabilityProxy is BaseUpgradeabilityProxy {
  /**
   * @dev Contract initializer.
   * @param _logic Address of the initial implementation.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  function initialize(address _logic, bytes memory _data) public payable {
    require(_implementation() == address(0));
    assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1));
    _setImplementation(_logic);
    if(_data.length > 0) {
      (bool success,) = _logic.delegatecall(_data);
      require(success);
    }
  }  
}

pragma solidity ^0.6.0;



/**
 * @title Elliptic curve signature operations
 * @dev Based on https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
 * TODO Remove this library once solidity supports passing a signature to ecrecover.
 * See https://github.com/ethereum/solidity/issues/864
 *
 * Source https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-solidity/79dd498b16b957399f84b9aa7e720f98f9eb83e3/contracts/cryptography/ECDSA.sol
 * This contract is copied here and renamed from the original to avoid clashes in the compiled artifacts
 * when the user imports a zos-lib contract (that transitively causes this contract to be compiled and added to the
 * build/artifacts folder) as well as the vanilla implementation from an openzeppelin version.
 */

library OpenZeppelinUpgradesECDSA {
    /**
     * @dev Recover signer address from a message by using their signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param signature bytes signature, the signature is generated using web3.eth.sign()
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }

        if (v != 27 && v != 28) {
            return address(0);
        }

        // If the signature is valid (and not malleable), return the signer address
        return ecrecover(hash, v, r, s);
    }

    /**
     * toEthSignedMessageHash
     * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
     * and hash the result
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

pragma solidity ^0.6.0;



import "./Ownable.sol";
import "./AdminUpgradeabilityProxy.sol";

/**
 * @title ProxyAdmin
 * @dev This contract is the admin of a proxy, and is in charge
 * of upgrading it as well as transferring it to another admin.
 */
contract ProxyAdmin is OpenZeppelinUpgradesOwnable {
  
  /**
   * @dev Returns the current implementation of a proxy.
   * This is needed because only the proxy admin can query it.
   * @return The address of the current implementation of the proxy.
   */
  function getProxyImplementation(AdminUpgradeabilityProxy proxy) public view returns (address) {
    // We need to manually run the static call since the getter cannot be flagged as view
    // bytes4(keccak256("implementation()")) == 0x5c60da1b
    (bool success, bytes memory returndata) = address(proxy).staticcall(hex"5c60da1b");
    require(success);
    return abi.decode(returndata, (address));
  }

  /**
   * @dev Returns the admin of a proxy. Only the admin can query it.
   * @return The address of the current admin of the proxy.
   */
  function getProxyAdmin(AdminUpgradeabilityProxy proxy) public view returns (address) {
    // We need to manually run the static call since the getter cannot be flagged as view
    // bytes4(keccak256("admin()")) == 0xf851a440
    (bool success, bytes memory returndata) = address(proxy).staticcall(hex"f851a440");
    require(success);
    return abi.decode(returndata, (address));
  }

  /**
   * @dev Changes the admin of a proxy.
   * @param proxy Proxy to change admin.
   * @param newAdmin Address to transfer proxy administration to.
   */
  function changeProxyAdmin(AdminUpgradeabilityProxy proxy, address newAdmin) public onlyOwner {
    proxy.changeAdmin(newAdmin);
  }

  /**
   * @dev Upgrades a proxy to the newest implementation of a contract.
   * @param proxy Proxy to be upgraded.
   * @param implementation the address of the Implementation.
   */
  function upgrade(AdminUpgradeabilityProxy proxy, address implementation) public onlyOwner {
    proxy.upgradeTo(implementation);
  }

  /**
   * @dev Upgrades a proxy to the newest implementation of a contract and forwards a function call to it.
   * This is useful to initialize the proxied contract.
   * @param proxy Proxy to be upgraded.
   * @param implementation Address of the Implementation.
   * @param data Data to send as msg.data in the low level call.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   */
  function upgradeAndCall(AdminUpgradeabilityProxy proxy, address implementation, bytes memory data) payable public onlyOwner {
    proxy.upgradeToAndCall.value(msg.value)(implementation, data);
  }
}

pragma solidity ^0.6.4;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: GPL-3.0-only



import "./Common.sol";
import "../lib/SafeMath.sol";
import "../interface/IPortfoliosCallable.sol";

import "./Liquidation.sol";
import "../storage/EscrowStorage.sol";

contract MockLiquidation is EscrowStorage {

    function setParameters(
        uint128 liquidityHaircut,
        uint128 liquidationDiscount,
        uint128 settlementDiscount,
        uint128 repoIncentive
    ) external {
        EscrowStorageSlot._setLiquidityHaircut(liquidityHaircut);
        EscrowStorageSlot._setLiquidationDiscount(liquidationDiscount);
        EscrowStorageSlot._setSettlementDiscount(settlementDiscount);
        EscrowStorageSlot._setLiquidityTokenRepoIncentive(repoIncentive);
    }

    event TradeCollateralCurrency(
        uint128 netLocalCurrencyPayer,
        int256 netLocalCurrencyLiquidator,
        uint128 collateralTransfer,
        int256 payerCollateralBalance
    );

    function liquidateCollateralCurrency(
        address payer,
        uint128 localCurrencyRequired,
        uint128 liquidityHaircut,
        Liquidation.TransferAmounts memory transfer,
        Common.FreeCollateralFactors memory fc,
        Liquidation.RateParameters memory rateParam,
        address Portfolios
    ) public {
        Liquidation._liquidateCollateralCurrency(payer, localCurrencyRequired, liquidityHaircut, transfer, fc, rateParam, Portfolios, 0);

        emit TradeCollateralCurrency(
            transfer.netLocalCurrencyPayer,
            transfer.netLocalCurrencyLiquidator,
            transfer.collateralTransfer,
            transfer.payerCollateralBalance
        );
    }

    function tradeCollateralCurrency(
        address payer,
        uint128 localCurrencyRequired,
        uint128 liquidityHaircut,
        uint128 discountFactor,
        Liquidation.TransferAmounts memory transfer,
        Common.FreeCollateralFactors memory fc,
        Liquidation.RateParameters memory rateParam,
        address Portfolios
    ) public returns (uint128, uint128, int256) {
        Liquidation._tradeCollateralCurrency(payer, localCurrencyRequired, liquidityHaircut, discountFactor, transfer, fc, rateParam, Portfolios);

        emit TradeCollateralCurrency(
            transfer.netLocalCurrencyPayer,
            transfer.netLocalCurrencyLiquidator,
            transfer.collateralTransfer,
            transfer.payerCollateralBalance
        );
    }

    event LiquidityTokenTrade(uint128 cashClaimWithdrawn, uint128 localCurrencyRaised);
    function localLiquidityTokenTrade(
        address payer,
        uint16 localCurrency,
        uint128 localCurrencyRequired,
        uint128 liquidityHaircut,
        IPortfoliosCallable Portfolios
    ) public {
        (uint128 cashClaimWithdrawn, uint128 localCurrencyRaised) = 
            Liquidation._localLiquidityTokenTrade(
                payer,
                localCurrency,
                localCurrencyRequired,
                liquidityHaircut,
                IPortfoliosCallable(Portfolios)
            );

        emit LiquidityTokenTrade(cashClaimWithdrawn, localCurrencyRaised);
    }

    function calculatePostTradeFactors(
        uint128 cashClaimWithdrawn,
        int256 netCurrencyAvailable,
        uint128 localCurrencyRequired,
        uint128 localCurrencyRaised,
        uint128 liquidityHaircut
    ) public pure returns (int256, uint128, int256, uint128) {
        return Liquidation._calculatePostTradeFactors(cashClaimWithdrawn, netCurrencyAvailable, localCurrencyRequired, localCurrencyRaised, liquidityHaircut);
    }

    function calculateLocalCurrencyToTrade(
        uint128 localCurrencyRequired,
        uint128 liquidationDiscount,
        uint128 localCurrencyBuffer,
        uint128 maxLocalCurrencyDebt
    ) public pure returns (uint128) {
        return Liquidation._calculateLocalCurrencyToTrade(localCurrencyRequired, liquidationDiscount, localCurrencyBuffer, maxLocalCurrencyDebt);
    }

    function calculateLiquidityTokenHaircut(
        int256 postHaircutCashClaim,
        uint128 liquidityHaircut
    ) public pure returns (uint128)  {
        return Liquidation._calculateLiquidityTokenHaircut(postHaircutCashClaim, liquidityHaircut);
    }

    function calculateCollateralToSell(
        uint128 discountFactor,
        uint128 localCurrencyRequired,
        Liquidation.RateParameters memory rateParam
    ) public pure returns (uint128) {
        return Liquidation._calculateCollateralToSell(discountFactor, localCurrencyRequired, rateParam);
    }

    function calculateCollateralBalances(
        address payer,
        int256 payerBalance,
        uint16 collateralCurrency,
        uint128 collateralToSell,
        uint128 amountToRaise,
        address Portfolios
    ) public returns (int256) {
        return Liquidation._calculateCollateralBalances(payer, payerBalance, collateralCurrency, collateralToSell, amountToRaise, IPortfoliosCallable(Portfolios));
    }
}

contract MockPortfolios {
    using SafeMath for uint256;
    uint128 public _remainder;
    uint128 public _amount;
    uint128 public liquidityHaircut;
    uint128 public _cash;
    uint128 public _fCash;
    bool public _wasCalled;

    function setHaircut(uint128 haircut) public {
        liquidityHaircut = haircut;
    }

    function setRemainder(uint128 remainder) public {
        _remainder = remainder;
    }

    function setClaim(uint128 cash, uint128 fCash) public {
        _cash = cash;
        _fCash = fCash;
    }

    function getClaim() public view returns (uint128, uint128) {
        uint256 cashClaim = uint256(_cash)
            .mul(liquidityHaircut)
            .div(Common.DECIMALS);

        uint256 fCashClaim = uint256(_fCash)
            .mul(liquidityHaircut)
            .div(Common.DECIMALS);

        return (uint128(cashClaim), uint128(fCashClaim));
    }

    function raiseCurrentCashViaLiquidityToken(
        address /* account */,
        uint16 /* currency */,
        uint128 amount
    ) external returns (uint128) {
        _wasCalled = true;
        _amount = amount;

        // If cash is set we return the remainder here
        if (_cash != 0) {
            if (amount >= _cash) {
                return amount - _cash;
            } else {
                return 0;
            }
        }

        return _remainder;
    }
}