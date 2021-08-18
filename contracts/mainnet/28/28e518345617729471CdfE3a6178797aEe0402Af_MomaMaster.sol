pragma solidity 0.5.17;

import "./MToken.sol";
import "./ErrorReporter.sol";
import "./PriceOracle.sol";
import "./MomaMasterInterface.sol";
import "./MomaMasterStorage.sol";
import "./MomaPool.sol";

/**
 * @title Moma's MomaMaster Contract
 * @author Moma
 */
contract MomaMaster is MomaMasterInterface, MomaMasterV1Storage, MomaMasterErrorReporter, ExponentialNoError {
    /// @notice Emitted when an admin supports a market
    event MarketListed(MToken mToken);

    /// @notice Emitted when an account enters a market
    event MarketEntered(MToken mToken, address account);

    /// @notice Emitted when an account exits a market
    event MarketExited(MToken mToken, address account);

    /// @notice Emitted when close factor is changed by admin
    event NewCloseFactor(uint oldCloseFactorMantissa, uint newCloseFactorMantissa);

    /// @notice Emitted when a collateral factor is changed by admin
    event NewCollateralFactor(MToken mToken, uint oldCollateralFactorMantissa, uint newCollateralFactorMantissa);

    /// @notice Emitted when liquidation incentive is changed by admin
    event NewLiquidationIncentive(uint oldLiquidationIncentiveMantissa, uint newLiquidationIncentiveMantissa);

    /// @notice Emitted when price oracle is changed
    event NewPriceOracle(PriceOracle oldPriceOracle, PriceOracle newPriceOracle);

    /// @notice Emitted when pause guardian is changed
    event NewPauseGuardian(address oldPauseGuardian, address newPauseGuardian);

    /// @notice Emitted when an action is paused globally
    event ActionPaused(string action, bool pauseState);

    /// @notice Emitted when an action is paused on a market
    event ActionPaused(MToken mToken, string action, bool pauseState);

    /// @notice Emitted when borrow cap for a mToken is changed
    event NewBorrowCap(MToken indexed mToken, uint newBorrowCap);

    /// @notice Emitted when a new token speed is updated for a market
    event TokenSpeedUpdated(address indexed token, MToken indexed mToken, uint oldSpeed, uint newSpeed);

    /// @notice Emitted when token is distributed to a supplier
    event DistributedSupplierToken(address indexed token, MToken indexed mToken, address indexed supplier, uint tokenDelta, uint tokenSupplyIndex);

    /// @notice Emitted when token is distributed to a borrower
    event DistributedBorrowerToken(address indexed token, MToken indexed mToken, address indexed borrower, uint tokenDelta, uint tokenBorrowIndex);

    /// @notice Emitted when token is claimed by user
    event TokenClaimed(address indexed token, address indexed user, uint accrued, uint claimed, uint notClaimed);

    /// @notice Emitted when token farm is updated by admin
     event TokenFarmUpdated(EIP20Interface token, uint oldStart, uint oldEnd, uint newStart, uint newEnd);

    /// @notice Emitted when a new token market is added to momaMarkets
    event NewTokenMarket(address indexed token, MToken indexed mToken);

    /// @notice Emitted when token is granted by admin
    event TokenGranted(address token, address recipient, uint amount);

    /// @notice Indicator that this is a MomaMaster contract (for inspection)
    bool public constant isMomaMaster = true;

    /// @notice The initial moma index for a market
    uint224 public constant momaInitialIndex = 1e36;

    // closeFactorMantissa must be strictly greater than this value
    uint internal constant closeFactorMinMantissa = 0.05e18; // 0.05

    // closeFactorMantissa must not exceed this value
    uint internal constant closeFactorMaxMantissa = 0.9e18; // 0.9

    // liquidationIncentiveMantissa must be no less than this value
    uint internal constant liquidationIncentiveMinMantissa = 1.0e18; // 1.0

    // liquidationIncentiveMantissa must be no greater than this value
    uint internal constant liquidationIncentiveMaxMantissa = 1.5e18; // 1.5

    // No collateralFactorMantissa may exceed this value
    uint internal constant collateralFactorMaxMantissa = 0.9e18; // 0.9

    constructor() public {
        admin = msg.sender;
    }

    /*** Assets You Are In ***/

    /**
     * @notice Returns the assets an account has entered
     * @param account The address of the account to pull assets for
     * @return A dynamic list with the assets the account has entered
     */
    function getAssetsIn(address account) external view returns (MToken[] memory) {
        MToken[] memory assetsIn = accountAssets[account];

        return assetsIn;
    }

    /**
     * @notice Returns whether the given account is entered in the given asset
     * @param account The address of the account to check
     * @param mToken The mToken to check
     * @return True if the account is in the asset, otherwise false.
     */
    function checkMembership(address account, MToken mToken) external view returns (bool) {
        return markets[address(mToken)].accountMembership[account];
    }

    /**
     * @notice Add assets to be included in account liquidity calculation
     * @param mTokens The list of addresses of the mToken markets to be enabled
     * @return Success indicator for whether each corresponding market was entered
     */
    function enterMarkets(address[] memory mTokens) public returns (uint[] memory) {
        uint len = mTokens.length;

        uint[] memory results = new uint[](len);
        for (uint i = 0; i < len; i++) {
            MToken mToken = MToken(mTokens[i]);

            results[i] = uint(addToMarketInternal(mToken, msg.sender));
        }

        return results;
    }

    /**
     * @notice Add the market to the borrower's "assets in" for liquidity calculations
     * @param mToken The market to enter
     * @param borrower The address of the account to modify
     * @return Success indicator for whether the market was entered
     */
    function addToMarketInternal(MToken mToken, address borrower) internal returns (Error) {
        Market storage marketToJoin = markets[address(mToken)];

        if (!marketToJoin.isListed) {
            // market is not listed, cannot join
            return Error.MARKET_NOT_LISTED;
        }

        if (oracle.getUnderlyingPrice(mToken) == 0) {
            // not have price
            return Error.PRICE_ERROR;
        }

        if (marketToJoin.accountMembership[borrower]) {
            // already joined
            return Error.NO_ERROR;
        }

        // survived the gauntlet, add to list
        // NOTE: we store these somewhat redundantly as a significant optimization
        //  this avoids having to iterate through the list for the most common use cases
        //  that is, only when we need to perform liquidity checks
        //  and not whenever we want to check if an account is in a particular market
        marketToJoin.accountMembership[borrower] = true;
        accountAssets[borrower].push(mToken);

        emit MarketEntered(mToken, borrower);

        return Error.NO_ERROR;
    }

    /**
     * @notice Removes asset from sender's account liquidity calculation
     * @dev Sender must not have an outstanding borrow balance in the asset,
     *  or be providing necessary collateral for an outstanding borrow.
     * @param mTokenAddress The address of the asset to be removed
     * @return Whether or not the account successfully exited the market
     */
    function exitMarket(address mTokenAddress) external returns (uint) {
        MToken mToken = MToken(mTokenAddress);
        /* Get sender tokensHeld and amountOwed underlying from the mToken */
        (uint oErr, uint tokensHeld, uint amountOwed, ) = mToken.getAccountSnapshot(msg.sender);
        require(oErr == 0, "exitMarket: getAccountSnapshot failed"); // semi-opaque error code

        /* Fail if the sender has a borrow balance */
        if (amountOwed != 0) {
            return fail(Error.NONZERO_BORROW_BALANCE, FailureInfo.EXIT_MARKET_BALANCE_OWED);
        }

        /* Fail if the sender is not permitted to redeem all of their tokens */
        uint allowed = redeemAllowedInternal(mTokenAddress, msg.sender, tokensHeld);
        if (allowed != 0) {
            return failOpaque(Error.REJECTION, FailureInfo.EXIT_MARKET_REJECTION, allowed);
        }

        Market storage marketToExit = markets[address(mToken)];

        /* Return true if the sender is not already ‘in’ the market */
        if (!marketToExit.accountMembership[msg.sender]) {
            return uint(Error.NO_ERROR);
        }

        /* Set mToken account membership to false */
        delete marketToExit.accountMembership[msg.sender];

        /* Delete mToken from the account’s list of assets */
        // load into memory for faster iteration
        MToken[] memory userAssetList = accountAssets[msg.sender];
        uint len = userAssetList.length;
        uint assetIndex = len;
        for (uint i = 0; i < len; i++) {
            if (userAssetList[i] == mToken) {
                assetIndex = i;
                break;
            }
        }

        // We *must* have found the asset in the list or our redundant data structure is broken
        assert(assetIndex < len);

        // copy last item in list to location of item to be removed, reduce length by 1
        MToken[] storage storedList = accountAssets[msg.sender];
        storedList[assetIndex] = storedList[storedList.length - 1];
        storedList.length--;

        emit MarketExited(mToken, msg.sender);

        return uint(Error.NO_ERROR);
    }

    /*** Policy Hooks ***/

    /**
     * @notice Checks if the account should be allowed to mint tokens in the given market
     * @param mToken The market to verify the mint against
     * @param minter The account which would get the minted tokens
     * @param mintAmount The amount of underlying being supplied to the market in exchange for tokens
     * @return 0 if the mint is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function mintAllowed(address mToken, address minter, uint mintAmount) external returns (uint) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!mintGuardianPaused[mToken], "mint is paused");

        // Shh - currently unused
        minter;
        mintAmount;

        if (!markets[mToken].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        // Keep the flywheel moving
        updateFarmSupplyIndex(mToken);
        distributeSupplierFarm(mToken, minter);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Validates mint and reverts on rejection. May emit logs.
     * @param mToken Asset being minted
     * @param minter The address minting the tokens
     * @param actualMintAmount The amount of the underlying asset being minted
     * @param mintTokens The number of tokens being minted
     */
    function mintVerify(address mToken, address minter, uint actualMintAmount, uint mintTokens) external {
        // Shh - currently unused
        mToken;
        minter;
        actualMintAmount;
        mintTokens;

        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            maxAssets = maxAssets;
        }
    }

    /**
     * @notice Checks if the account should be allowed to redeem tokens in the given market
     * @param mToken The market to verify the redeem against
     * @param redeemer The account which would redeem the tokens
     * @param redeemTokens The number of mTokens to exchange for the underlying asset in the market
     * @return 0 if the redeem is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function redeemAllowed(address mToken, address redeemer, uint redeemTokens) external returns (uint) {
        uint allowed = redeemAllowedInternal(mToken, redeemer, redeemTokens);
        if (allowed != uint(Error.NO_ERROR)) {
            return allowed;
        }

        // Keep the flywheel moving
        updateFarmSupplyIndex(mToken);
        distributeSupplierFarm(mToken, redeemer);

        return uint(Error.NO_ERROR);
    }

    function redeemAllowedInternal(address mToken, address redeemer, uint redeemTokens) internal view returns (uint) {
        if (!markets[mToken].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        /* If the redeemer is not 'in' the market, then we can bypass the liquidity check */
        if (!markets[mToken].accountMembership[redeemer]) {
            return uint(Error.NO_ERROR);
        }

        /* Otherwise, perform a hypothetical liquidity check to guard against shortfall */
        (Error err, , uint shortfall) = getHypotheticalAccountLiquidityInternal(redeemer, MToken(mToken), redeemTokens, 0);
        if (err != Error.NO_ERROR) {
            return uint(err);
        }
        if (shortfall > 0) {
            return uint(Error.INSUFFICIENT_LIQUIDITY);
        }

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Validates redeem and reverts on rejection. May emit logs.
     * @param mToken Asset being redeemed
     * @param redeemer The address redeeming the tokens
     * @param redeemAmount The amount of the underlying asset being redeemed
     * @param redeemTokens The number of tokens being redeemed
     */
    function redeemVerify(address mToken, address redeemer, uint redeemAmount, uint redeemTokens) external {
        // Shh - currently unused
        mToken;
        redeemer;

        // Require tokens is zero or amount is also zero
        if (redeemTokens == 0 && redeemAmount > 0) {
            revert("redeemTokens zero");
        }
    }

    /**
     * @notice Checks if the account should be allowed to borrow the underlying asset of the given market
     * @param mToken The market to verify the borrow against
     * @param borrower The account which would borrow the asset
     * @param borrowAmount The amount of underlying the account would borrow
     * @return 0 if the borrow is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function borrowAllowed(address mToken, address borrower, uint borrowAmount) external returns (uint) {
        require(isLendingPool, "this is not lending pool");
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!borrowGuardianPaused[mToken], "borrow is paused");

        if (!markets[mToken].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        if (!markets[mToken].accountMembership[borrower]) {
            // only mTokens may call borrowAllowed if borrower not in market
            require(msg.sender == mToken, "sender must be mToken");

            // attempt to add borrower to the market
            Error err = addToMarketInternal(MToken(msg.sender), borrower);
            if (err != Error.NO_ERROR) {
                return uint(err);
            }

            // it should be impossible to break the important invariant
            assert(markets[mToken].accountMembership[borrower]);
        }

        if (oracle.getUnderlyingPrice(MToken(mToken)) == 0) {
            return uint(Error.PRICE_ERROR);
        }


        uint borrowCap = borrowCaps[mToken];
        // Borrow cap of 0 corresponds to unlimited borrowing
        if (borrowCap != 0) {
            uint totalBorrows = MToken(mToken).totalBorrows();
            uint nextTotalBorrows = add_(totalBorrows, borrowAmount);
            require(nextTotalBorrows < borrowCap, "market borrow cap reached");
        }

        (Error err, , uint shortfall) = getHypotheticalAccountLiquidityInternal(borrower, MToken(mToken), 0, borrowAmount);
        if (err != Error.NO_ERROR) {
            return uint(err);
        }
        if (shortfall > 0) {
            return uint(Error.INSUFFICIENT_LIQUIDITY);
        }

        // Keep the flywheel moving
        uint borrowIndex = MToken(mToken).borrowIndex();
        updateFarmBorrowIndex(mToken, borrowIndex);
        distributeBorrowerFarm(mToken, borrower, borrowIndex);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Validates borrow and reverts on rejection. May emit logs.
     * @param mToken Asset whose underlying is being borrowed
     * @param borrower The address borrowing the underlying
     * @param borrowAmount The amount of the underlying asset requested to borrow
     */
    function borrowVerify(address mToken, address borrower, uint borrowAmount) external {
        // Shh - currently unused
        mToken;
        borrower;
        borrowAmount;

        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            maxAssets = maxAssets;
        }
    }

    /**
     * @notice Checks if the account should be allowed to repay a borrow in the given market
     * @param mToken The market to verify the repay against
     * @param payer The account which would repay the asset
     * @param borrower The account which would borrowed the asset
     * @param repayAmount The amount of the underlying asset the account would repay
     * @return 0 if the repay is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function repayBorrowAllowed(
        address mToken,
        address payer,
        address borrower,
        uint repayAmount) external returns (uint) {
        // Shh - currently unused
        payer;
        borrower;
        repayAmount;
        require(isLendingPool, "this is not lending pool");

        if (!markets[mToken].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        // Keep the flywheel moving
        uint borrowIndex = MToken(mToken).borrowIndex();
        updateFarmBorrowIndex(mToken, borrowIndex);
        distributeBorrowerFarm(mToken, borrower, borrowIndex);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Validates repayBorrow and reverts on rejection. May emit logs.
     * @param mToken Asset being repaid
     * @param payer The address repaying the borrow
     * @param borrower The address of the borrower
     * @param actualRepayAmount The amount of underlying being repaid
     */
    function repayBorrowVerify(
        address mToken,
        address payer,
        address borrower,
        uint actualRepayAmount,
        uint borrowerIndex) external {
        // Shh - currently unused
        mToken;
        payer;
        borrower;
        actualRepayAmount;
        borrowerIndex;

        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            maxAssets = maxAssets;
        }
    }

    /**
     * @notice Checks if the liquidation should be allowed to occur
     * @param mTokenBorrowed Asset which was borrowed by the borrower
     * @param mTokenCollateral Asset which was used as collateral and will be seized
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param repayAmount The amount of underlying being repaid
     */
    function liquidateBorrowAllowed(
        address mTokenBorrowed,
        address mTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) external returns (uint) {
        // Shh - currently unused
        liquidator;
        require(isLendingPool, "this is not lending pool");

        if (!markets[mTokenBorrowed].isListed || !markets[mTokenCollateral].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        /* The borrower must have shortfall in order to be liquidatable */
        (Error err, , uint shortfall) = getAccountLiquidityInternal(borrower);
        if (err != Error.NO_ERROR) {
            return uint(err);
        }
        if (shortfall == 0) {
            return uint(Error.INSUFFICIENT_SHORTFALL);
        }

        /* The liquidator may not repay more than what is allowed by the closeFactor */
        uint borrowBalance = MToken(mTokenBorrowed).borrowBalanceStored(borrower);
        uint maxClose = mul_ScalarTruncate(Exp({mantissa: closeFactorMantissa}), borrowBalance);
        if (repayAmount > maxClose) {
            return uint(Error.TOO_MUCH_REPAY);
        }

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Validates liquidateBorrow and reverts on rejection. May emit logs.
     * @param mTokenBorrowed Asset which was borrowed by the borrower
     * @param mTokenCollateral Asset which was used as collateral and will be seized
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param actualRepayAmount The amount of underlying being repaid
     */
    function liquidateBorrowVerify(
        address mTokenBorrowed,
        address mTokenCollateral,
        address liquidator,
        address borrower,
        uint actualRepayAmount,
        uint seizeTokens) external {
        // Shh - currently unused
        mTokenBorrowed;
        mTokenCollateral;
        liquidator;
        borrower;
        actualRepayAmount;
        seizeTokens;

        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            maxAssets = maxAssets;
        }
    }

    /**
     * @notice Checks if the seizing of assets should be allowed to occur
     * @param mTokenCollateral Asset which was used as collateral and will be seized
     * @param mTokenBorrowed Asset which was borrowed by the borrower
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param seizeTokens The number of collateral tokens to seize
     */
    function seizeAllowed(
        address mTokenCollateral,
        address mTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external returns (uint) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!seizeGuardianPaused, "seize is paused");
        require(isLendingPool, "this is not lending pool");

        // Shh - currently unused
        seizeTokens;

        if (!markets[mTokenCollateral].isListed || !markets[mTokenBorrowed].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        if (MToken(mTokenCollateral).momaMaster() != MToken(mTokenBorrowed).momaMaster()) {
            return uint(Error.MOMAMASTER_MISMATCH);
        }

        // Keep the flywheel moving
        updateFarmSupplyIndex(mTokenCollateral);
        distributeSupplierFarm(mTokenCollateral, borrower);
        distributeSupplierFarm(mTokenCollateral, liquidator);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Validates seize and reverts on rejection. May emit logs.
     * @param mTokenCollateral Asset which was used as collateral and will be seized
     * @param mTokenBorrowed Asset which was borrowed by the borrower
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param seizeTokens The number of collateral tokens to seize
     */
    function seizeVerify(
        address mTokenCollateral,
        address mTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external {
        // Shh - currently unused
        mTokenCollateral;
        mTokenBorrowed;
        liquidator;
        borrower;
        seizeTokens;

        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            maxAssets = maxAssets;
        }
    }

    /**
     * @notice Checks if the account should be allowed to transfer tokens in the given market
     * @param mToken The market to verify the transfer against
     * @param src The account which sources the tokens
     * @param dst The account which receives the tokens
     * @param transferTokens The number of mTokens to transfer
     * @return 0 if the transfer is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function transferAllowed(address mToken, address src, address dst, uint transferTokens) external returns (uint) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!transferGuardianPaused, "transfer is paused");

        // Currently the only consideration is whether or not
        //  the src is allowed to redeem this many tokens
        uint allowed = redeemAllowedInternal(mToken, src, transferTokens);
        if (allowed != uint(Error.NO_ERROR)) {
            return allowed;
        }

        // Keep the flywheel moving
        updateFarmSupplyIndex(mToken);
        distributeSupplierFarm(mToken, src);
        distributeSupplierFarm(mToken, dst);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Validates transfer and reverts on rejection. May emit logs.
     * @param mToken Asset being transferred
     * @param src The account which sources the tokens
     * @param dst The account which receives the tokens
     * @param transferTokens The number of mTokens to transfer
     */
    function transferVerify(address mToken, address src, address dst, uint transferTokens) external {
        // Shh - currently unused
        mToken;
        src;
        dst;
        transferTokens;

        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            maxAssets = maxAssets;
        }
    }

    /*** Liquidity/Liquidation Calculations ***/

    /**
     * @dev Local vars for avoiding stack-depth limits in calculating account liquidity.
     *  Note that `mTokenBalance` is the number of mTokens the account owns in the market,
     *  whereas `borrowBalance` is the amount of underlying that the account has borrowed.
     */
    struct AccountLiquidityLocalVars {
        uint sumCollateral;
        uint sumBorrowPlusEffects;
        uint mTokenBalance;
        uint borrowBalance;
        uint exchangeRateMantissa;
        uint oraclePriceMantissa;
        Exp collateralFactor;
        Exp exchangeRate;
        Exp oraclePrice;
        Exp tokensToDenom;
    }

    /**
     * @notice Determine the current account liquidity wrt collateral requirements
     * @return (possible error code (semi-opaque),
                account liquidity in excess of collateral requirements,
     *          account shortfall below collateral requirements)
     */
    function getAccountLiquidity(address account) public view returns (uint, uint, uint) {
        (Error err, uint liquidity, uint shortfall) = getHypotheticalAccountLiquidityInternal(account, MToken(0), 0, 0);

        return (uint(err), liquidity, shortfall);
    }

    /**
     * @notice Determine the current account liquidity wrt collateral requirements
     * @return (possible error code,
                account liquidity in excess of collateral requirements,
     *          account shortfall below collateral requirements)
     */
    function getAccountLiquidityInternal(address account) internal view returns (Error, uint, uint) {
        return getHypotheticalAccountLiquidityInternal(account, MToken(0), 0, 0);
    }

    /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @param mTokenModify The market to hypothetically redeem/borrow in
     * @param account The account to determine liquidity for
     * @param redeemTokens The number of tokens to hypothetically redeem
     * @param borrowAmount The amount of underlying to hypothetically borrow
     * @return (possible error code (semi-opaque),
                hypothetical account liquidity in excess of collateral requirements,
     *          hypothetical account shortfall below collateral requirements)
     */
    function getHypotheticalAccountLiquidity(
        address account,
        address mTokenModify,
        uint redeemTokens,
        uint borrowAmount) public view returns (uint, uint, uint) {
        (Error err, uint liquidity, uint shortfall) = getHypotheticalAccountLiquidityInternal(account, MToken(mTokenModify), redeemTokens, borrowAmount);
        return (uint(err), liquidity, shortfall);
    }

    /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @param mTokenModify The market to hypothetically redeem/borrow in
     * @param account The account to determine liquidity for
     * @param redeemTokens The number of tokens to hypothetically redeem
     * @param borrowAmount The amount of underlying to hypothetically borrow
     * @dev Note that we calculate the exchangeRateStored for each collateral mToken using stored data,
     *  without calculating accumulated interest.
     * @return (possible error code,
                hypothetical account liquidity in excess of collateral requirements,
     *          hypothetical account shortfall below collateral requirements)
     */
    function getHypotheticalAccountLiquidityInternal(
        address account,
        MToken mTokenModify,
        uint redeemTokens,
        uint borrowAmount) internal view returns (Error, uint, uint) {

        AccountLiquidityLocalVars memory vars; // Holds all our calculation results
        uint oErr;

        // For each asset the account is in
        MToken[] memory assets = accountAssets[account];
        for (uint i = 0; i < assets.length; i++) {
            MToken asset = assets[i];

            // Read the balances and exchange rate from the mToken
            (oErr, vars.mTokenBalance, vars.borrowBalance, vars.exchangeRateMantissa) = asset.getAccountSnapshot(account);
            if (oErr != 0) { // semi-opaque error code, we assume NO_ERROR == 0 is invariant between upgrades
                return (Error.SNAPSHOT_ERROR, 0, 0);
            }
            vars.collateralFactor = Exp({mantissa: markets[address(asset)].collateralFactorMantissa});
            vars.exchangeRate = Exp({mantissa: vars.exchangeRateMantissa});

            // Get the normalized price of the asset
            vars.oraclePriceMantissa = oracle.getUnderlyingPrice(asset);
            if (vars.oraclePriceMantissa == 0) {
                return (Error.PRICE_ERROR, 0, 0);
            }
            vars.oraclePrice = Exp({mantissa: vars.oraclePriceMantissa});

            // Pre-compute a conversion factor from tokens -> ether (normalized price value)
            vars.tokensToDenom = mul_(mul_(vars.collateralFactor, vars.exchangeRate), vars.oraclePrice);

            // sumCollateral += tokensToDenom * mTokenBalance
            vars.sumCollateral = mul_ScalarTruncateAddUInt(vars.tokensToDenom, vars.mTokenBalance, vars.sumCollateral);

            // sumBorrowPlusEffects += oraclePrice * borrowBalance
            vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(vars.oraclePrice, vars.borrowBalance, vars.sumBorrowPlusEffects);

            // Calculate effects of interacting with mTokenModify
            if (asset == mTokenModify) {
                // redeem effect
                // sumBorrowPlusEffects += tokensToDenom * redeemTokens
                vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(vars.tokensToDenom, redeemTokens, vars.sumBorrowPlusEffects);

                // borrow effect
                // sumBorrowPlusEffects += oraclePrice * borrowAmount
                vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(vars.oraclePrice, borrowAmount, vars.sumBorrowPlusEffects);
            }
        }

        // These are safe, as the underflow condition is checked first
        if (vars.sumCollateral > vars.sumBorrowPlusEffects) {
            return (Error.NO_ERROR, vars.sumCollateral - vars.sumBorrowPlusEffects, 0);
        } else {
            return (Error.NO_ERROR, 0, vars.sumBorrowPlusEffects - vars.sumCollateral);
        }
    }

    /**
     * @notice Calculate number of tokens of collateral asset to seize given an underlying amount
     * @dev Used in liquidation (called in mToken.liquidateBorrowFresh)
     * @param mTokenBorrowed The address of the borrowed mToken
     * @param mTokenCollateral The address of the collateral mToken
     * @param actualRepayAmount The amount of mTokenBorrowed underlying to convert into mTokenCollateral tokens
     * @return (errorCode, number of mTokenCollateral tokens to be seized in a liquidation)
     */
    function liquidateCalculateSeizeTokens(address mTokenBorrowed, address mTokenCollateral, uint actualRepayAmount) external view returns (uint, uint) {
        /* Read oracle prices for borrowed and collateral markets */
        uint priceBorrowedMantissa = oracle.getUnderlyingPrice(MToken(mTokenBorrowed));
        uint priceCollateralMantissa = oracle.getUnderlyingPrice(MToken(mTokenCollateral));
        if (priceBorrowedMantissa == 0 || priceCollateralMantissa == 0) {
            return (uint(Error.PRICE_ERROR), 0);
        }

        /*
         * Get the exchange rate and calculate the number of collateral tokens to seize:
         *  seizeAmount = actualRepayAmount * liquidationIncentive * priceBorrowed / priceCollateral
         *  seizeTokens = seizeAmount / exchangeRate
         *   = actualRepayAmount * (liquidationIncentive * priceBorrowed) / (priceCollateral * exchangeRate)
         */
        uint exchangeRateMantissa = MToken(mTokenCollateral).exchangeRateStored(); // Note: reverts on error
        uint seizeTokens;
        Exp memory numerator;
        Exp memory denominator;
        Exp memory ratio;

        numerator = mul_(Exp({mantissa: liquidationIncentiveMantissa}), Exp({mantissa: priceBorrowedMantissa}));
        denominator = mul_(Exp({mantissa: priceCollateralMantissa}), Exp({mantissa: exchangeRateMantissa}));
        ratio = div_(numerator, denominator);

        seizeTokens = mul_ScalarTruncate(ratio, actualRepayAmount);

        return (uint(Error.NO_ERROR), seizeTokens);
    }

    /*** Admin Functions ***/

    /**
      * @notice Sets a new price oracle for the MomaMaster
      * @dev Admin function to set a new price oracle
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _updatePriceOracle() public returns (uint) {
        // Check caller is admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PRICE_ORACLE_OWNER_CHECK);
        }

        // Read the new oracle from factory
        address newOracle = MomaFactoryInterface(factory).oracle();

        // Check newOracle
        require(newOracle != address(0), "factory not set oracle");

        // Track the old oracle for the MomaMaster
        PriceOracle oldOracle = oracle;

        // Set MomaMaster's oracle to newOracle
        oracle = PriceOracle(newOracle);

        // Emit NewPriceOracle(oldOracle, newOracle)
        emit NewPriceOracle(oldOracle, PriceOracle(newOracle));

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Sets the closeFactor used when liquidating borrows
      * @dev Admin function to set closeFactor
      * @param newCloseFactorMantissa New close factor, scaled by 1e18
      * @return uint 0=success, otherwise a failure
      */
    function _setCloseFactor(uint newCloseFactorMantissa) external returns (uint) {
        // Check caller is admin
    	require(msg.sender == admin, "only admin can set close factor");
        require(newCloseFactorMantissa >= closeFactorMinMantissa, "close factor too small");
        require(newCloseFactorMantissa <= closeFactorMaxMantissa, "close factor too large");

        uint oldCloseFactorMantissa = closeFactorMantissa;
        closeFactorMantissa = newCloseFactorMantissa;
        emit NewCloseFactor(oldCloseFactorMantissa, closeFactorMantissa);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Sets the collateralFactor for a market
      * @dev Admin function to set per-market collateralFactor
      * @param mToken The market to set the factor on
      * @param newCollateralFactorMantissa The new collateral factor, scaled by 1e18
      * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
      */
    function _setCollateralFactor(MToken mToken, uint newCollateralFactorMantissa) external returns (uint) {
        // Check caller is admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_COLLATERAL_FACTOR_OWNER_CHECK);
        }

        // Verify market is listed
        Market storage market = markets[address(mToken)];
        if (!market.isListed) {
            return fail(Error.MARKET_NOT_LISTED, FailureInfo.SET_COLLATERAL_FACTOR_NO_EXISTS);
        }

        Exp memory newCollateralFactorExp = Exp({mantissa: newCollateralFactorMantissa});

        // Check collateral factor <= 0.9
        Exp memory highLimit = Exp({mantissa: collateralFactorMaxMantissa});
        if (lessThanExp(highLimit, newCollateralFactorExp)) {
            return fail(Error.INVALID_COLLATERAL_FACTOR, FailureInfo.SET_COLLATERAL_FACTOR_VALIDATION);
        }

        // If collateral factor != 0, fail if price == 0
        if (newCollateralFactorMantissa != 0 && oracle.getUnderlyingPrice(mToken) == 0) {
            return fail(Error.PRICE_ERROR, FailureInfo.SET_COLLATERAL_FACTOR_WITHOUT_PRICE);
        }

        // Set market's collateral factor to new collateral factor, remember old value
        uint oldCollateralFactorMantissa = market.collateralFactorMantissa;
        market.collateralFactorMantissa = newCollateralFactorMantissa;

        // Emit event with asset, old collateral factor, and new collateral factor
        emit NewCollateralFactor(mToken, oldCollateralFactorMantissa, newCollateralFactorMantissa);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Sets liquidationIncentive
      * @dev Admin function to set liquidationIncentive
      * @param newLiquidationIncentiveMantissa New liquidationIncentive scaled by 1e18
      * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
      */
    function _setLiquidationIncentive(uint newLiquidationIncentiveMantissa) external returns (uint) {
        // Check caller is admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_LIQUIDATION_INCENTIVE_OWNER_CHECK);
        }

        require(newLiquidationIncentiveMantissa >= liquidationIncentiveMinMantissa, "liquidation incentive too small");
        require(newLiquidationIncentiveMantissa <= liquidationIncentiveMaxMantissa, "liquidation incentive too large");

        // Save current value for use in log
        uint oldLiquidationIncentiveMantissa = liquidationIncentiveMantissa;

        // Set liquidation incentive to new incentive
        liquidationIncentiveMantissa = newLiquidationIncentiveMantissa;

        // Emit event with old incentive, new incentive
        emit NewLiquidationIncentive(oldLiquidationIncentiveMantissa, newLiquidationIncentiveMantissa);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Add the market to the markets mapping and set it as listed
      * @dev Admin function to set isListed and add support for the market
      * @param mToken The address of the market (token) to list
      * @return uint 0=success, otherwise a failure. (See enum Error for details)
      */
    function _supportMarket(MToken mToken) external returns (uint) {
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SUPPORT_MARKET_OWNER_CHECK);
        }

        if (isLendingPool) {
            require(address(mToken.interestRateModel()) != address(0), "mToken not set interestRateModel");
        }

        // Check is mToken
        require(MomaFactoryInterface(factory).isMToken(address(mToken)), 'not mToken');

        if (markets[address(mToken)].isListed) {
            return fail(Error.MARKET_ALREADY_LISTED, FailureInfo.SUPPORT_MARKET_EXISTS);
        }

        require(mToken.isMToken(), 'not mToken contract'); // Sanity check to make sure its really a MToken

        // Note that isMomaed is not in active use anymore
        // markets[address(mToken)] = Market({isListed: true, isMomaed: false, collateralFactorMantissa: 0});
        markets[address(mToken)] = Market({isListed: true, collateralFactorMantissa: 0});

        _addMarketInternal(address(mToken));

        emit MarketListed(mToken);

        return uint(Error.NO_ERROR);
    }

    function _addMarketInternal(address mToken) internal {
        for (uint i = 0; i < allMarkets.length; i ++) {
            require(allMarkets[i] != MToken(mToken), "market already added");
        }
        allMarkets.push(MToken(mToken));
    }


    /**
      * @notice Set the given borrow caps for the given mToken markets. Borrowing that brings total borrows to or above borrow cap will revert.
      * @dev Admin or pauseGuardian function to set the borrow caps. A borrow cap of 0 corresponds to unlimited borrowing.
      * @param mTokens The addresses of the markets (tokens) to change the borrow caps for
      * @param newBorrowCaps The new borrow cap values in underlying to be set. A value of 0 corresponds to unlimited borrowing.
      */
    function _setMarketBorrowCaps(MToken[] calldata mTokens, uint[] calldata newBorrowCaps) external {
    	require(msg.sender == admin || msg.sender == pauseGuardian, "only admin or pauseGuardian can set borrow caps"); 

        uint numMarkets = mTokens.length;
        uint numBorrowCaps = newBorrowCaps.length;

        require(numMarkets != 0 && numMarkets == numBorrowCaps, "invalid input");

        for(uint i = 0; i < numMarkets; i++) {
            borrowCaps[address(mTokens[i])] = newBorrowCaps[i];
            emit NewBorrowCap(mTokens[i], newBorrowCaps[i]);
        }
    }

    /**
     * @notice Admin function to change the Pause Guardian
     * @param newPauseGuardian The address of the new Pause Guardian
     * @return uint 0=success, otherwise a failure. (See enum Error for details)
     */
    function _setPauseGuardian(address newPauseGuardian) external returns (uint) {
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PAUSE_GUARDIAN_OWNER_CHECK);
        }

        // Save current value for inclusion in log
        address oldPauseGuardian = pauseGuardian;

        // Store pauseGuardian with value newPauseGuardian
        pauseGuardian = newPauseGuardian;

        // Emit NewPauseGuardian(OldPauseGuardian, NewPauseGuardian)
        emit NewPauseGuardian(oldPauseGuardian, pauseGuardian);

        return uint(Error.NO_ERROR);
    }

    function _upgradeLendingPool() external returns (bool) {
        require(msg.sender == admin, "only admin can upgrade");

        // must update oracle first, it succuss or revert, so no need to check again
        _updatePriceOracle();

        // all markets must set interestRateModel
        for (uint i = 0; i < allMarkets.length; i++) {
            MToken mToken = allMarkets[i];
            require(address(mToken.interestRateModel()) != address(0), "support market not set interestRateModel");
            // require(oracle.getUnderlyingPrice(mToken) != 0, "support market not set price"); // let functions check
        }

        bool state = MomaFactoryInterface(factory).upgradeLendingPool();
        if (state) {
            require(updateBorrowBlock() == 0, "update borrow block error");
            isLendingPool = true;
        }
        return state;
    }

    function _setMintPaused(MToken mToken, bool state) external returns (bool) {
        require(markets[address(mToken)].isListed, "cannot pause a market that is not listed");
        require(msg.sender == pauseGuardian || msg.sender == admin, "only pause guardian and admin can pause");
        require(msg.sender == admin || state, "only admin can unpause");

        mintGuardianPaused[address(mToken)] = state;
        emit ActionPaused(mToken, "Mint", state);
        return state;
    }

    function _setBorrowPaused(MToken mToken, bool state) external returns (bool) {
        require(markets[address(mToken)].isListed, "cannot pause a market that is not listed");
        require(msg.sender == pauseGuardian || msg.sender == admin, "only pause guardian and admin can pause");
        require(msg.sender == admin || state, "only admin can unpause");

        borrowGuardianPaused[address(mToken)] = state;
        emit ActionPaused(mToken, "Borrow", state);
        return state;
    }

    function _setTransferPaused(bool state) external returns (bool) {
        require(msg.sender == pauseGuardian || msg.sender == admin, "only pause guardian and admin can pause");
        require(msg.sender == admin || state, "only admin can unpause");

        transferGuardianPaused = state;
        emit ActionPaused("Transfer", state);
        return state;
    }

    function _setSeizePaused(bool state) external returns (bool) {
        require(msg.sender == pauseGuardian || msg.sender == admin, "only pause guardian and admin can pause");
        require(msg.sender == admin || state, "only admin can unpause");

        seizeGuardianPaused = state;
        emit ActionPaused("Seize", state);
        return state;
    }

    function _become(MomaPool momaPool) external {
        require(msg.sender == momaPool.admin(), "only momaPool admin can change brains");
        require(momaPool._acceptImplementation() == 0, "change not authorized");
    }

    /**
     * @notice Checks caller is admin, or this contract is becoming the new implementation
     */
    function adminOrInitializing() internal view returns (bool) {
        return msg.sender == admin || msg.sender == momaMasterImplementation;
    }


    /*** Farming ***/

    /**
      * @notice Update all markets' borrow block for all tokens when pool upgrade to lending pool
      * @return uint 0=success, otherwise a failure
      */
    function updateBorrowBlock() internal returns (uint) {
        uint32 blockNumber = safe32(getBlockNumber(), "block number exceeds 32 bits");
        for (uint i = 0; i < allTokens.length; i++) {
            address token = allTokens[i];
            uint32 nextBlock = blockNumber;
            TokenFarmState storage state = farmStates[token];
            if (state.startBlock > blockNumber) nextBlock = state.startBlock;
            // if (state.endBlock < blockNumber) blockNumber = state.endBlock;

            MToken[] memory mTokens = state.tokenMarkets;
            for (uint j = 0; j < mTokens.length; j++) {
                MToken mToken = mTokens[j];
                state.borrowState[address(mToken)].block = nextBlock;  // if state.speeds[address(mToken)] > 0 ?
            }
        }
        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Accrue tokens and MOMA to the market by updating the supply index
     * @param mToken The market whose supply index to update
     */
    function updateFarmSupplyIndex(address mToken) internal {
        updateMomaSupplyIndex(mToken);
        for (uint i = 0; i < allTokens.length; i++) {
            address token = allTokens[i];
            updateTokenSupplyIndex(token, mToken);
        }
    }

    /**
     * @notice Accrue tokens and MOMA to the market by updating the supply index
     * @param mToken The market whose supply index to update
     * @param marketBorrowIndex The market borrow index
     */
    function updateFarmBorrowIndex(address mToken, uint marketBorrowIndex) internal {
        updateMomaBorrowIndex(mToken, marketBorrowIndex);
        for (uint i = 0; i < allTokens.length; i++) {
            address token = allTokens[i];
            updateTokenBorrowIndex(token, mToken, marketBorrowIndex);
        }
    }

    /**
     * @notice Calculate tokens and MOMA accrued by a supplier
     * @param mToken The market in which the supplier is interacting
     * @param supplier The address of the supplier to distribute tokens and MOMA to
     */
    function distributeSupplierFarm(address mToken, address supplier) internal {
        distributeSupplierMoma(mToken, supplier);
        for (uint i = 0; i < allTokens.length; i++) {
            address token = allTokens[i];
            distributeSupplierToken(token, mToken, supplier);
        }
    }

    /**
     * @notice Calculate tokens and MOMA accrued by a borrower
     * @dev Borrowers will not begin to accrue until after the first interaction with the protocol.
     * @param mToken The market in which the borrower is interacting
     * @param borrower The address of the borrower to distribute tokens and MOMA to
     * @param marketBorrowIndex The market borrow index
     */
    function distributeBorrowerFarm(address mToken, address borrower, uint marketBorrowIndex) internal {
        distributeBorrowerMoma(mToken, borrower, marketBorrowIndex);
        for (uint i = 0; i < allTokens.length; i++) {
            address token = allTokens[i];
            distributeBorrowerToken(token, mToken, borrower, marketBorrowIndex);
        }
    }


    /*** Tokens Farming ***/

    /**
     * @notice Accrue token to the market by updating the supply index
     * @param token The token whose supply index to update
     * @param mToken The market whose supply index to update
     */
    function updateTokenSupplyIndex(address token, address mToken) internal {
        delegateToFarming(abi.encodeWithSignature("updateTokenSupplyIndex(address,address)", token, mToken));
    }

    /**
     * @notice Accrue token to the market by updating the borrow index
     * @param token The token whose borrow index to update
     * @param mToken The market whose borrow index to update
     * @param marketBorrowIndex The market borrow index
     */
    function updateTokenBorrowIndex(address token, address mToken, uint marketBorrowIndex) internal {
        delegateToFarming(abi.encodeWithSignature("updateTokenBorrowIndex(address,address,uint256)", token, mToken, marketBorrowIndex));
    }

    /**
     * @notice Calculate token accrued by a supplier
     * @param token The token in which the supplier is interacting
     * @param mToken The market in which the supplier is interacting
     * @param supplier The address of the supplier to distribute token to
     */
    function distributeSupplierToken(address token, address mToken, address supplier) internal {
        delegateToFarming(abi.encodeWithSignature("distributeSupplierToken(address,address,address)", token, mToken, supplier));
    }

    /**
     * @notice Calculate token accrued by a borrower
     * @dev Borrowers will not begin to accrue until after the first interaction with the protocol.
     * @param mToken The market in which the borrower is interacting
     * @param borrower The address of the borrower to distribute token to
     * @param marketBorrowIndex The market borrow index
     */
    function distributeBorrowerToken(address token, address mToken, address borrower, uint marketBorrowIndex) internal {
        delegateToFarming(abi.encodeWithSignature("distributeBorrowerToken(address,address,address,uint256)", token, mToken, borrower, marketBorrowIndex));
    }


    /*** Reward Public Functions ***/

    /**
     * @notice Distribute all the token accrued to user in specified markets of specified token and claim
     * @param token The token to distribute
     * @param mTokens The list of markets to distribute token in
     * @param suppliers Whether or not to distribute token earned by supplying
     * @param borrowers Whether or not to distribute token earned by borrowing
     */
    function dclaim(address token, MToken[] memory mTokens, bool suppliers, bool borrowers) public {
        delegateToFarming(abi.encodeWithSignature("dclaim(address,address[],bool,bool)", token, mTokens, suppliers, borrowers));
    }

    /**
     * @notice Distribute all the token accrued to user in all markets of specified token and claim
     * @param token The token to distribute
     * @param suppliers Whether or not to distribute token earned by supplying
     * @param borrowers Whether or not to distribute token earned by borrowing
     */
    function dclaim(address token, bool suppliers, bool borrowers) external {
        delegateToFarming(abi.encodeWithSignature("dclaim(address,bool,bool)", token, suppliers, borrowers));
    }

    /**
     * @notice Distribute all the token accrued to user in all markets of specified tokens and claim
     * @param tokens The list of tokens to distribute and claim
     * @param suppliers Whether or not to distribute token earned by supplying
     * @param borrowers Whether or not to distribute token earned by borrowing
     */
    function dclaim(address[] memory tokens, bool suppliers, bool borrowers) public {
        delegateToFarming(abi.encodeWithSignature("dclaim(address[],bool,bool)", tokens, suppliers, borrowers));
    }

    /**
     * @notice Distribute all the token accrued to user in all markets of all tokens and claim
     * @param suppliers Whether or not to distribute token earned by supplying
     * @param borrowers Whether or not to distribute token earned by borrowing
     */
    function dclaim(bool suppliers, bool borrowers) external {
        delegateToFarming(abi.encodeWithSignature("dclaim(bool,bool)", suppliers, borrowers));
    }

    /**
     * @notice Claim all the token have been distributed to user of specified token
     * @param token The token to claim
     */
    function claim(address token) external {
        delegateToFarming(abi.encodeWithSignature("claim(address)", token));
    }

    /**
     * @notice Claim all the token have been distributed to user of all tokens
     */
    function claim() external {
        delegateToFarming(abi.encodeWithSignature("claim()"));
    }


    /**
     * @notice Calculate undistributed token accrued by the user in specified market of specified token
     * @param user The address to calculate token for
     * @param token The token to calculate
     * @param mToken The market to calculate token
     * @param suppliers Whether or not to calculate token earned by supplying
     * @param borrowers Whether or not to calculate token earned by borrowing
     * @return The amount of undistributed token of this user
     */
    function undistributed(address user, address token, address mToken, bool suppliers, bool borrowers) public view returns (uint) {
        bytes memory data = delegateToFarmingView(abi.encodeWithSignature("undistributed(address,address,address,bool,bool)", user, token, mToken, suppliers, borrowers));
        return abi.decode(data, (uint));
    }

    /**
     * @notice Calculate undistributed tokens accrued by the user in all markets of specified token
     * @param user The address to calculate token for
     * @param token The token to calculate
     * @param suppliers Whether or not to calculate token earned by supplying
     * @param borrowers Whether or not to calculate token earned by borrowing
     * @return The amount of undistributed token of this user in each market
     */
    function undistributed(address user, address token, bool suppliers, bool borrowers) public view returns (uint[] memory) {
        bytes memory data = delegateToFarmingView(abi.encodeWithSignature("undistributed(address,address,bool,bool)", user, token, suppliers, borrowers));
        return abi.decode(data, (uint[]));
    }


    /*** Token Distribution Admin ***/

    /**
     * @notice Transfer token to the recipient
     * @dev Note: If there is not enough token, we do not perform the transfer all.
     * @param token The token to transfer
     * @param recipient The address of the recipient to transfer token to
     * @param amount The amount of token to (possibly) transfer
     */
    function _grantToken(address token, address recipient, uint amount) external {
        delegateToFarming(abi.encodeWithSignature("_grantToken(address,address,uint256)", token, recipient, amount));
    }

    /**
      * @notice Admin function to add/update erc20 token farming
      * @dev Can only add token or restart this token farm again after endBlock
      * @param token Token to add/update for farming
      * @param start Block heiht to start to farm this token
      * @param end Block heiht to stop farming
      * @return uint 0=success, otherwise a failure
      */
    function _setTokenFarm(EIP20Interface token, uint start, uint end) external returns (uint) {
        bytes memory data = delegateToFarming(abi.encodeWithSignature("_setTokenFarm(address,uint256,uint256)", token, start, end));
        return abi.decode(data, (uint));
    }

    /**
     * @notice Set token speed for multi markets
     * @dev Note that token speed could be set to 0 to halt liquidity rewards for a market
     * @param token The token to update speed
     * @param mTokens The markets whose token speed to update
     * @param newSpeeds New token speeds for markets
     */
    function _setTokensSpeed(address token, MToken[] memory mTokens, uint[] memory newSpeeds) public {
        delegateToFarming(abi.encodeWithSignature("_setTokensSpeed(address,address[],uint256[])", token, mTokens, newSpeeds));
    }


    /*** MOMA Farming ***/

    /**
     * @notice Accrue MOMA to the market by updating the supply index
     * @param mToken The market whose supply index to update
     */
    function updateMomaSupplyIndex(address mToken) internal {
        IMomaFarming(currentMomaFarming()).updateMarketSupplyState(mToken);
    }

    /**
     * @notice Accrue MOMA to the market by updating the borrow index
     * @param mToken The market whose borrow index to update
     * @param marketBorrowIndex The market borrow index
     */
    function updateMomaBorrowIndex(address mToken, uint marketBorrowIndex) internal {
        IMomaFarming(currentMomaFarming()).updateMarketBorrowState(mToken, marketBorrowIndex);
    }

    /**
     * @notice Calculate MOMA accrued by a supplier
     * @param mToken The market in which the supplier is interacting
     * @param supplier The address of the supplier to distribute MOMA to
     */
    function distributeSupplierMoma(address mToken, address supplier) internal {
        IMomaFarming(currentMomaFarming()).distributeSupplierMoma(mToken, supplier);
    }

    /**
     * @notice Calculate MOMA accrued by a borrower
     * @dev Borrowers will not begin to accrue until after the first interaction with the protocol.
     * @param mToken The market in which the borrower is interacting
     * @param borrower The address of the borrower to distribute MOMA to
     * @param marketBorrowIndex The market borrow index
     */
    function distributeBorrowerMoma(address mToken, address borrower, uint marketBorrowIndex) internal {
        IMomaFarming(currentMomaFarming()).distributeBorrowerMoma(mToken, borrower, marketBorrowIndex);
    }


    /*** View functions ***/

    /**
     * @notice Return all of the support tokens
     * @dev The automatic getter may be used to access an individual token.
     * @return The list of market addresses
     */
    function getAllTokens() external view returns (address[] memory) {
        return allTokens;
    }

    /**
     * @notice Weather a token is farming
     * @param token The token address to ask for
     * @param market Which market
     * @return Wether this market farm the token currently
     */
    function isFarming(address token, address market) external view returns (bool) {
        uint blockNumber = getBlockNumber();
        TokenFarmState storage state = farmStates[token];
        return state.speeds[market] > 0 && blockNumber > uint(state.startBlock) && blockNumber <= uint(state.endBlock);
    }

    /**
     * @notice Get the market speed for a token
     * @param token The token address to ask for
     * @param market Which market
     * @return The market farm speed of this token currently
     */
    function getTokenMarketSpeed(address token, address market) external view returns (uint) {
        return farmStates[token].speeds[market];
    }

    /**
     * @notice Get the accrued amount of this token farming for a user
     * @param token The token address to ask for
     * @param user The user address to ask for
     * @return The accrued amount of this token farming for a user
     */
    function getTokenUserAccrued(address token, address user) external view returns (uint) {
        return farmStates[token].accrued[user];
    }

    /**
     * @notice Weather a market is this token market
     * @param token The token address to ask for
     * @param market The market address to ask for
     * @return true of false
     */
    function isTokenMarket(address token, address market) external view returns (bool) {
        return farmStates[token].isTokenMarket[market];
    }

    /**
     * @notice Return all the farming support markets of a token
     * @param token The token address to ask for
     * @return The list of market addresses
     */
    function getTokenMarkets(address token) external view returns (MToken[] memory) {
        return farmStates[token].tokenMarkets;
    }

    /**
     * @notice Return all of the markets
     * @dev The automatic getter may be used to access an individual market.
     * @return The list of market addresses
     */
    function getAllMarkets() external view returns (MToken[] memory) {
        return allMarkets;
    }

    function getBlockNumber() public view returns (uint) {
        return block.number;
    }


    /*** Delegate ***/

    /**
     * @notice Get current moma farming contract
     * @return The contract address
     */
    function currentMomaFarming() public view returns (address) {
        return MomaFactoryInterface(factory).momaFarming();
    }

    /**
     * @notice Get current farming contract
     * @return The contract address
     */
    function currentFarmingDelegate() public view returns (address) {
        return MomaFactoryInterface(factory).farmingDelegate();
    }

    /**
     * @notice Internal method to delegate execution to farming contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateToFarming(bytes memory data) internal returns (bytes memory) {
        address callee = currentFarmingDelegate();
        (bool success, bytes memory returnData) = callee.delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize)
            }
        }
        return returnData;
    }

    /**
     * @notice Public method to delegate view execution to farming contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateToFarmingSelf(bytes memory data) public returns (bytes memory) {
        require(msg.sender == address(this), "can only called by self");

        return delegateToFarming(data);
    }

    /**
     * @notice Internal method to delegate view execution to farming contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     *  There are an additional 2 prefix uints from the wrapper returndata, which we ignore since we make an extra hop.
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateToFarmingView(bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returnData) = address(this).staticcall(abi.encodeWithSignature("delegateToFarmingSelf(bytes)", data));
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize)
            }
        }
        return abi.decode(returnData, (bytes));
    }
}


interface IMomaFarming {
    function updateMarketSupplyState(address mToken) external;
    function updateMarketBorrowState(address mToken, uint marketBorrowIndex) external;
    function distributeSupplierMoma(address mToken, address supplier) external;
    function distributeBorrowerMoma(address mToken, address borrower, uint marketBorrowIndex) external;
    function upgradeLendingPool(address pool) external;
    function isMomaFarming() external view returns (bool);
}