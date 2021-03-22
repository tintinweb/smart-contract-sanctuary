pragma solidity ^0.5.16;

import "./KToken.sol";
import "./KMCD.sol";
import "./ErrorReporter.sol";
import "./Exponential.sol";
import "./KineControllerInterface.sol";
import "./ControllerStorage.sol";
import "./Unitroller.sol";
import "./KineOracleInterface.sol";
import "./KineSafeMath.sol";

/**
Copyright 2020 Compound Labs, Inc.
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
* Original work from Compound: https://github.com/compound-finance/compound-protocol/blob/master/contracts/Comptroller.sol
* Modified to work in the Kine system.
* Main modifications:
*   1. removed Comp token related logics.
*   2. removed interest rate model related logics.
*   3. simplified calculations in mint, redeem, liquidity check, seize due to we don't use interest model/exchange rate.
*   4. user can only supply kTokens (see KToken) and borrow Kine MCDs (see KMCD). Kine MCD's underlying can be considered as itself.
*   5. removed error code propagation mechanism, using revert to fail fast and loudly.
*/

/**
 * @title Kine's Controller Contract
 * @author Kine
 */
contract Controller is ControllerStorage, KineControllerInterface, Exponential, ControllerErrorReporter {
    /// @notice Emitted when an admin supports a market
    event MarketListed(KToken kToken);

    /// @notice Emitted when an account enters a market
    event MarketEntered(KToken kToken, address account);

    /// @notice Emitted when an account exits a market
    event MarketExited(KToken kToken, address account);

    /// @notice Emitted when close factor is changed by admin
    event NewCloseFactor(uint oldCloseFactorMantissa, uint newCloseFactorMantissa);

    /// @notice Emitted when a collateral factor is changed by admin
    event NewCollateralFactor(KToken kToken, uint oldCollateralFactorMantissa, uint newCollateralFactorMantissa);

    /// @notice Emitted when liquidation incentive is changed by admin
    event NewLiquidationIncentive(uint oldLiquidationIncentiveMantissa, uint newLiquidationIncentiveMantissa);

    /// @notice Emitted when price oracle is changed
    event NewPriceOracle(KineOracleInterface oldPriceOracle, KineOracleInterface newPriceOracle);

    /// @notice Emitted when pause guardian is changed
    event NewPauseGuardian(address oldPauseGuardian, address newPauseGuardian);

    /// @notice Emitted when an action is paused globally
    event ActionPaused(string action, bool pauseState);

    /// @notice Emitted when an action is paused on a market
    event ActionPaused(KToken kToken, string action, bool pauseState);

    /// @notice Emitted when borrow cap for a kToken is changed
    event NewBorrowCap(KToken indexed kToken, uint newBorrowCap);

    /// @notice Emitted when supply cap for a kToken is changed
    event NewSupplyCap(KToken indexed kToken, uint newSupplyCap);

    /// @notice Emitted when borrow/supply cap guardian is changed
    event NewCapGuardian(address oldCapGuardian, address newCapGuardian);

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

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin can call this function");
        _;
    }

    /*** Assets You Are In ***/

    /**
     * @notice Returns the assets an account has entered
     * @param account The address of the account to pull assets for
     * @return A dynamic list with the assets the account has entered
     */
    function getAssetsIn(address account) external view returns (KToken[] memory) {
        KToken[] memory assetsIn = accountAssets[account];

        return assetsIn;
    }

    /**
     * @notice Returns whether the given account is entered in the given asset
     * @param account The address of the account to check
     * @param kToken The kToken to check
     * @return True if the account is in the asset, otherwise false.
     */
    function checkMembership(address account, KToken kToken) external view returns (bool) {
        return markets[address(kToken)].accountMembership[account];
    }

    /**
     * @notice Add assets to be included in account liquidity calculation
     * @param kTokens The list of addresses of the kToken markets to be enabled
     * @dev will revert if any market entering failed
     */
    function enterMarkets(address[] memory kTokens) public {
        uint len = kTokens.length;
        for (uint i = 0; i < len; i++) {
            KToken kToken = KToken(kTokens[i]);
            addToMarketInternal(kToken, msg.sender);
        }
    }

    /**
     * @notice Add the market to the borrower's "assets in" for liquidity calculations
     * @param kToken The market to enter
     * @param borrower The address of the account to modify
     */
    function addToMarketInternal(KToken kToken, address borrower) internal {
        Market storage marketToJoin = markets[address(kToken)];

        require(marketToJoin.isListed, MARKET_NOT_LISTED);

        if (marketToJoin.accountMembership[borrower] == true) {
            // already joined
            return;
        }

        // survived the gauntlet, add to list
        // NOTE: we store these somewhat redundantly as a significant optimization
        //  this avoids having to iterate through the list for the most common use cases
        //  that is, only when we need to perform liquidity checks
        //  and not whenever we want to check if an account is in a particular market
        marketToJoin.accountMembership[borrower] = true;
        accountAssets[borrower].push(kToken);

        emit MarketEntered(kToken, borrower);
    }

    /**
     * @notice Removes asset from sender's account liquidity calculation
     * @dev Sender must not have an outstanding borrow balance in the asset,
     *  or be providing necessary collateral for an outstanding borrow.
     * @param kTokenAddress The address of the asset to be removed
     */
    function exitMarket(address kTokenAddress) external {
        KToken kToken = KToken(kTokenAddress);
        /* Get sender tokensHeld and amountOwed underlying from the kToken */
        (uint tokensHeld, uint amountOwed) = kToken.getAccountSnapshot(msg.sender);

        /* Fail if the sender has a borrow balance */
        require(amountOwed == 0, EXIT_MARKET_BALANCE_OWED);

        /* Fail if the sender is not permitted to redeem all of their tokens */
        (bool allowed,) = redeemAllowedInternal(kTokenAddress, msg.sender, tokensHeld);
        require(allowed, EXIT_MARKET_REJECTION);

        Market storage marketToExit = markets[address(kToken)];

        /* Succeed true if the sender is not already ‘in’ the market */
        if (!marketToExit.accountMembership[msg.sender]) {
            return;
        }

        /* Set kToken account membership to false */
        delete marketToExit.accountMembership[msg.sender];

        /* Delete kToken from the account’s list of assets */
        // load into memory for faster iteration
        KToken[] memory userAssetList = accountAssets[msg.sender];
        uint len = userAssetList.length;
        uint assetIndex = len;
        for (uint i = 0; i < len; i++) {
            if (userAssetList[i] == kToken) {
                assetIndex = i;
                break;
            }
        }

        // We *must* have found the asset in the list or our redundant data structure is broken
        require(assetIndex < len, "accountAssets array broken");

        // copy last item in list to location of item to be removed, reduce length by 1
        KToken[] storage storedList = accountAssets[msg.sender];
        if (assetIndex != storedList.length - 1) {
            storedList[assetIndex] = storedList[storedList.length - 1];
        }
        storedList.length--;

        emit MarketExited(kToken, msg.sender);
    }

    /*** Policy Hooks ***/

    /**
     * @notice Checks if the account should be allowed to mint tokens in the given market
     * @param kToken The market to verify the mint against
     * @param minter The account which would get the minted tokens
     * @param mintAmount The amount of underlying being supplied to the market in exchange for tokens
     * @return false and reason if mint not allowed, otherwise return true and empty string
     */
    function mintAllowed(address kToken, address minter, uint mintAmount) external returns (bool allowed, string memory reason) {
        if (mintGuardianPaused[kToken]) {
            allowed = false;
            reason = MINT_PAUSED;
            return (allowed, reason);
        }

        uint supplyCap = supplyCaps[kToken];
        // Supply cap of 0 corresponds to unlimited supplying
        if (supplyCap != 0) {
            uint totalSupply = KToken(kToken).totalSupply();
            uint nextTotalSupply = totalSupply.add(mintAmount);
            if (nextTotalSupply > supplyCap) {
                allowed = false;
                reason = MARKET_SUPPLY_CAP_REACHED;
                return (allowed, reason);
            }
        }

        // Shh - currently unused
        minter;

        if (!markets[kToken].isListed) {
            allowed = false;
            reason = MARKET_NOT_LISTED;
            return (allowed, reason);
        }

        allowed = true;
        return (allowed, reason);
    }

    /**
     * @notice Validates mint and reverts on rejection. May emit logs.
     * @param kToken Asset being minted
     * @param minter The address minting the tokens
     * @param actualMintAmount The amount of the underlying asset being minted
     * @param mintTokens The number of tokens being minted
     */
    function mintVerify(address kToken, address minter, uint actualMintAmount, uint mintTokens) external {
        // Shh - currently unused
        kToken;
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
     * @param kToken The market to verify the redeem against
     * @param redeemer The account which would redeem the tokens
     * @param redeemTokens The number of kTokens to exchange for the underlying asset in the market
     * @return false and reason if redeem not allowed, otherwise return true and empty string
     */
    function redeemAllowed(address kToken, address redeemer, uint redeemTokens) external returns (bool allowed, string memory reason) {
        return redeemAllowedInternal(kToken, redeemer, redeemTokens);
    }

    /**
     * @param kToken The market to verify the redeem against
     * @param redeemer The account which would redeem the tokens
     * @param redeemTokens The number of kTokens to exchange for the underlying asset in the market
     * @return false and reason if redeem not allowed, otherwise return true and empty string
     */
    function redeemAllowedInternal(address kToken, address redeemer, uint redeemTokens) internal view returns (bool allowed, string memory reason) {
        if (!markets[kToken].isListed) {
            allowed = false;
            reason = MARKET_NOT_LISTED;
            return (allowed, reason);
        }

        /* If the redeemer is not 'in' the market, then we can bypass the liquidity check */
        if (!markets[kToken].accountMembership[redeemer]) {
            allowed = true;
            return (allowed, reason);
        }

        /* Otherwise, perform a hypothetical liquidity check to guard against shortfall */
        (, uint shortfall) = getHypotheticalAccountLiquidityInternal(redeemer, KToken(kToken), redeemTokens, 0);
        if (shortfall > 0) {
            allowed = false;
            reason = INSUFFICIENT_LIQUIDITY;
            return (allowed, reason);
        }

        allowed = true;
        return (allowed, reason);
    }

    /**
     * @notice Validates redeem and reverts on rejection. May emit logs.
     * @param kToken Asset being redeemed
     * @param redeemer The address redeeming the tokens
     * @param redeemTokens The number of tokens being redeemed
     */
    function redeemVerify(address kToken, address redeemer, uint redeemTokens) external {
        // Shh - currently unused
        kToken;
        redeemer;

        require(redeemTokens != 0, REDEEM_TOKENS_ZERO);
    }

    /**
     * @notice Checks if the account should be allowed to borrow the underlying asset of the given market
     * @param kToken The market to verify the borrow against
     * @param borrower The account which would borrow the asset
     * @param borrowAmount The amount of underlying the account would borrow
     * @return false and reason if borrow not allowed, otherwise return true and empty string
     */
    function borrowAllowed(address kToken, address borrower, uint borrowAmount) external returns (bool allowed, string memory reason) {
        if (borrowGuardianPaused[kToken]) {
            allowed = false;
            reason = BORROW_PAUSED;
            return (allowed, reason);
        }

        if (!markets[kToken].isListed) {
            allowed = false;
            reason = MARKET_NOT_LISTED;
            return (allowed, reason);
        }

        if (!markets[kToken].accountMembership[borrower]) {
            // only kTokens may call borrowAllowed if borrower not in market
            require(msg.sender == kToken, "sender must be kToken");

            // attempt to add borrower to the market
            addToMarketInternal(KToken(msg.sender), borrower);

            // it should be impossible to break the important invariant
            assert(markets[kToken].accountMembership[borrower]);
        }

        require(oracle.getUnderlyingPrice(kToken) != 0, "price error");

        uint borrowCap = borrowCaps[kToken];
        // Borrow cap of 0 corresponds to unlimited borrowing
        if (borrowCap != 0) {
            uint totalBorrows = KMCD(kToken).totalBorrows();
            uint nextTotalBorrows = totalBorrows.add(borrowAmount);
            if (nextTotalBorrows > borrowCap) {
                allowed = false;
                reason = MARKET_BORROW_CAP_REACHED;
                return (allowed, reason);
            }
        }

        (, uint shortfall) = getHypotheticalAccountLiquidityInternal(borrower, KToken(kToken), 0, borrowAmount);
        if (shortfall > 0) {
            allowed = false;
            reason = INSUFFICIENT_LIQUIDITY;
            return (allowed, reason);
        }

        allowed = true;
        return (allowed, reason);
    }

    /**
     * @notice Validates borrow and reverts on rejection. May emit logs.
     * @param kToken Asset whose underlying is being borrowed
     * @param borrower The address borrowing the underlying
     * @param borrowAmount The amount of the underlying asset requested to borrow
     */
    function borrowVerify(address kToken, address borrower, uint borrowAmount) external {
        // Shh - currently unused
        kToken;
        borrower;
        borrowAmount;

        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            maxAssets = maxAssets;
        }
    }

    /**
     * @notice Checks if the account should be allowed to repay a borrow in the given market
     * @param kToken The market to verify the repay against
     * @param payer The account which would repay the asset
     * @param borrower The account which would borrowed the asset
     * @param repayAmount The amount of the underlying asset the account would repay
     * @return false and reason if repay borrow not allowed, otherwise return true and empty string
     */
    function repayBorrowAllowed(
        address kToken,
        address payer,
        address borrower,
        uint repayAmount) external returns (bool allowed, string memory reason) {
        // Shh - currently unused
        payer;
        borrower;
        repayAmount;

        if (!markets[kToken].isListed) {
            allowed = false;
            reason = MARKET_NOT_LISTED;
        }

        allowed = true;
        return (allowed, reason);
    }

    /**
     * @notice Validates repayBorrow and reverts on rejection. May emit logs.
     * @param kToken Asset being repaid
     * @param payer The address repaying the borrow
     * @param borrower The address of the borrower
     * @param actualRepayAmount The amount of underlying being repaid
     */
    function repayBorrowVerify(
        address kToken,
        address payer,
        address borrower,
        uint actualRepayAmount) external {
        // Shh - currently unused
        kToken;
        payer;
        borrower;
        actualRepayAmount;

        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            maxAssets = maxAssets;
        }
    }

    /**
     * @notice Checks if the liquidation should be allowed to occur
     * @param kTokenBorrowed Asset which was borrowed by the borrower
     * @param kTokenCollateral Asset which was used as collateral and will be seized
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param repayAmount The amount of underlying being repaid
     * @return false and reason if liquidate borrow not allowed, otherwise return true and empty string
     */
    function liquidateBorrowAllowed(
        address kTokenBorrowed,
        address kTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) external returns (bool allowed, string memory reason) {
        // Shh - currently unused
        liquidator;

        if (!markets[kTokenBorrowed].isListed || !markets[kTokenCollateral].isListed) {
            allowed = false;
            reason = MARKET_NOT_LISTED;
            return (allowed, reason);
        }

        if (KToken(kTokenCollateral).controller() != KToken(kTokenBorrowed).controller()) {
            allowed = false;
            reason = CONTROLLER_MISMATCH;
            return (allowed, reason);
        }

        /* The borrower must have shortfall in order to be liquidatable */
        (, uint shortfall) = getAccountLiquidityInternal(borrower);
        if (shortfall == 0) {
            allowed = false;
            reason = INSUFFICIENT_SHORTFALL;
            return (allowed, reason);
        }

        /* The liquidator may not repay more than what is allowed by the closeFactor */
        /* Only KMCD has borrow related logics */
        uint borrowBalance = KMCD(kTokenBorrowed).borrowBalance(borrower);
        uint maxClose = mulScalarTruncate(Exp({mantissa : closeFactorMantissa}), borrowBalance);
        if (repayAmount > maxClose) {
            allowed = false;
            reason = TOO_MUCH_REPAY;
            return (allowed, reason);
        }

        allowed = true;
        return (allowed, reason);
    }

    /**
     * @notice Validates liquidateBorrow and reverts on rejection. May emit logs.
     * @param kTokenBorrowed Asset which was borrowed by the borrower
     * @param kTokenCollateral Asset which was used as collateral and will be seized
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param actualRepayAmount The amount of underlying being repaid
     */
    function liquidateBorrowVerify(
        address kTokenBorrowed,
        address kTokenCollateral,
        address liquidator,
        address borrower,
        uint actualRepayAmount,
        uint seizeTokens) external {
        // Shh - currently unused
        kTokenBorrowed;
        kTokenCollateral;
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
     * @param kTokenCollateral Asset which was used as collateral and will be seized
     * @param kTokenBorrowed Asset which was borrowed by the borrower
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param seizeTokens The number of collateral tokens to seize
     * @return false and reason if seize not allowed, otherwise return true and empty string
     */
    function seizeAllowed(
        address kTokenCollateral,
        address kTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external returns (bool allowed, string memory reason) {
        if (seizeGuardianPaused) {
            allowed = false;
            reason = SEIZE_PAUSED;
            return (allowed, reason);
        }

        // Shh - currently unused
        seizeTokens;
        liquidator;
        borrower;

        if (!markets[kTokenCollateral].isListed || !markets[kTokenBorrowed].isListed) {
            allowed = false;
            reason = MARKET_NOT_LISTED;
            return (allowed, reason);
        }

        if (KToken(kTokenCollateral).controller() != KToken(kTokenBorrowed).controller()) {
            allowed = false;
            reason = CONTROLLER_MISMATCH;
            return (allowed, reason);
        }

        allowed = true;
        return (allowed, reason);
    }

    /**
     * @notice Validates seize and reverts on rejection. May emit logs.
     * @param kTokenCollateral Asset which was used as collateral and will be seized
     * @param kTokenBorrowed Asset which was borrowed by the borrower
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param seizeTokens The number of collateral tokens to seize
     */
    function seizeVerify(
        address kTokenCollateral,
        address kTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external {
        // Shh - currently unused
        kTokenCollateral;
        kTokenBorrowed;
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
     * @param kToken The market to verify the transfer against
     * @param src The account which sources the tokens
     * @param dst The account which receives the tokens
     * @param transferTokens The number of kTokens to transfer
     * @return false and reason if seize not allowed, otherwise return true and empty string
     */
    function transferAllowed(address kToken, address src, address dst, uint transferTokens) external returns (bool allowed, string memory reason) {
        if (transferGuardianPaused) {
            allowed = false;
            reason = TRANSFER_PAUSED;
            return (allowed, reason);
        }

        // not used currently
        dst;

        // Currently the only consideration is whether or not
        //  the src is allowed to redeem this many tokens
        return redeemAllowedInternal(kToken, src, transferTokens);
    }

    /**
     * @notice Validates transfer and reverts on rejection. May emit logs.
     * @param kToken Asset being transferred
     * @param src The account which sources the tokens
     * @param dst The account which receives the tokens
     * @param transferTokens The number of kTokens to transfer
     */
    function transferVerify(address kToken, address src, address dst, uint transferTokens) external {
        // Shh - currently unused
        kToken;
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
     *  Note that `kTokenBalance` is the number of kTokens the account owns in the market,
     *  whereas `borrowBalance` is the amount of underlying that the account has borrowed.
     *  In Kine system, user can only borrow Kine MCD, the `borrowBalance` is the amount of Kine MCD account has borrowed.
     */
    struct AccountLiquidityLocalVars {
        uint sumCollateral;
        uint sumBorrowPlusEffects;
        uint kTokenBalance;
        uint borrowBalance;
        uint oraclePriceMantissa;
        Exp collateralFactor;
        Exp oraclePrice;
        Exp tokensToDenom;
    }

    /**
     * @notice Determine the current account liquidity wrt collateral requirements
     * @return (account liquidity in excess of collateral requirements,
     *          account shortfall below collateral requirements)
     */
    function getAccountLiquidity(address account) public view returns (uint, uint) {
        return getHypotheticalAccountLiquidityInternal(account, KToken(0), 0, 0);
    }

    /**
     * @notice Determine the current account liquidity wrt collateral requirements
     * @return (account liquidity in excess of collateral requirements,
     *          account shortfall below collateral requirements)
     */
    function getAccountLiquidityInternal(address account) internal view returns (uint, uint) {
        return getHypotheticalAccountLiquidityInternal(account, KToken(0), 0, 0);
    }

    /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @param kTokenModify The market to hypothetically redeem/borrow in
     * @param account The account to determine liquidity for
     * @param redeemTokens The number of tokens to hypothetically redeem
     * @param borrowAmount The amount of underlying to hypothetically borrow
     * @return (hypothetical account liquidity in excess of collateral requirements,
     *          hypothetical account shortfall below collateral requirements)
     */
    function getHypotheticalAccountLiquidity(
        address account,
        address kTokenModify,
        uint redeemTokens,
        uint borrowAmount) public view returns (uint, uint) {
        return getHypotheticalAccountLiquidityInternal(account, KToken(kTokenModify), redeemTokens, borrowAmount);
    }

    /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @param kTokenModify The market to hypothetically redeem/borrow in
     * @param account The account to determine liquidity for
     * @param redeemTokens The number of tokens to hypothetically redeem
     * @param borrowAmount The amount of underlying to hypothetically borrow
     * @return (hypothetical account liquidity in excess of collateral requirements,
     *          hypothetical account shortfall below collateral requirements)
     */
    function getHypotheticalAccountLiquidityInternal(
        address account,
        KToken kTokenModify,
        uint redeemTokens,
        uint borrowAmount) internal view returns (uint, uint) {

        AccountLiquidityLocalVars memory vars;

        // For each asset the account is in
        KToken[] memory assets = accountAssets[account];
        for (uint i = 0; i < assets.length; i++) {
            KToken asset = assets[i];

            // Read the balances from the kToken
            (vars.kTokenBalance, vars.borrowBalance) = asset.getAccountSnapshot(account);
            vars.collateralFactor = Exp({mantissa : markets[address(asset)].collateralFactorMantissa});

            // Get the normalized price of the asset
            vars.oraclePriceMantissa = oracle.getUnderlyingPrice(address(asset));
            require(vars.oraclePriceMantissa != 0, "price error");
            vars.oraclePrice = Exp({mantissa : vars.oraclePriceMantissa});

            // Pre-compute a conversion factor
            vars.tokensToDenom = mulExp(vars.collateralFactor, vars.oraclePrice);

            // sumCollateral += tokensToDenom * kTokenBalance
            vars.sumCollateral = mulScalarTruncateAddUInt(vars.tokensToDenom, vars.kTokenBalance, vars.sumCollateral);

            // sumBorrowPlusEffects += oraclePrice * borrowBalance
            vars.sumBorrowPlusEffects = mulScalarTruncateAddUInt(vars.oraclePrice, vars.borrowBalance, vars.sumBorrowPlusEffects);

            // Calculate effects of interacting with kTokenModify
            if (asset == kTokenModify) {
                // redeem effect
                // sumBorrowPlusEffects += tokensToDenom * redeemTokens
                vars.sumBorrowPlusEffects = mulScalarTruncateAddUInt(vars.tokensToDenom, redeemTokens, vars.sumBorrowPlusEffects);

                // borrow effect
                // sumBorrowPlusEffects += oraclePrice * borrowAmount
                vars.sumBorrowPlusEffects = mulScalarTruncateAddUInt(vars.oraclePrice, borrowAmount, vars.sumBorrowPlusEffects);
            }
        }

        // These are safe, as the underflow condition is checked first
        if (vars.sumCollateral > vars.sumBorrowPlusEffects) {
            return (vars.sumCollateral - vars.sumBorrowPlusEffects, 0);
        } else {
            return (0, vars.sumBorrowPlusEffects - vars.sumCollateral);
        }
    }

    /**
     * @notice Calculate number of tokens of collateral asset to seize given an underlying amount
     * @dev Used in liquidation (called in kMCD.liquidateBorrowFresh)
     * @param kTokenBorrowed The address of the borrowed kToken
     * @param kTokenCollateral The address of the collateral kToken
     * @param actualRepayAmount The amount of kTokenBorrowed underlying to convert into kTokenCollateral tokens
     * @return number of kTokenCollateral tokens to be seized in a liquidation
     */
    function liquidateCalculateSeizeTokens(address kTokenBorrowed, address kTokenCollateral, uint actualRepayAmount) external view returns (uint) {
        /* Read oracle prices for borrowed and collateral markets */
        uint priceBorrowedMantissa = oracle.getUnderlyingPrice(kTokenBorrowed);
        uint priceCollateralMantissa = oracle.getUnderlyingPrice(kTokenCollateral);
        require(priceBorrowedMantissa != 0 && priceCollateralMantissa != 0, "price error");

        /*
         *  calculate the number of collateral tokens to seize:
         *  seizeTokens = actualRepayAmount * liquidationIncentive * priceBorrowed / priceCollateral
        */
        Exp memory numerator = mulExp(liquidationIncentiveMantissa, priceBorrowedMantissa);
        Exp memory denominator = Exp({mantissa : priceCollateralMantissa});
        Exp memory ratio = divExp(numerator, denominator);
        uint seizeTokens = mulScalarTruncate(ratio, actualRepayAmount);

        return seizeTokens;
    }

    /*** Admin Functions ***/

    /**
      * @notice Sets a new price oracle for the controller
      * @dev Admin function to set a new price oracle
      */
    function _setPriceOracle(KineOracleInterface newOracle) external onlyAdmin() {
        KineOracleInterface oldOracle = oracle;
        oracle = newOracle;
        emit NewPriceOracle(oldOracle, newOracle);
    }

    /**
      * @notice Sets the closeFactor used when liquidating borrows
      * @dev Admin function to set closeFactor
      * @param newCloseFactorMantissa New close factor, scaled by 1e18
      */
    function _setCloseFactor(uint newCloseFactorMantissa) external onlyAdmin() {
        require(newCloseFactorMantissa <= closeFactorMaxMantissa, INVALID_CLOSE_FACTOR);
        require(newCloseFactorMantissa >= closeFactorMinMantissa, INVALID_CLOSE_FACTOR);

        uint oldCloseFactorMantissa = closeFactorMantissa;
        closeFactorMantissa = newCloseFactorMantissa;
        emit NewCloseFactor(oldCloseFactorMantissa, closeFactorMantissa);
    }

    /**
      * @notice Sets the collateralFactor for a market
      * @dev Admin function to set per-market collateralFactor
      * @param kToken The market to set the factor on
      * @param newCollateralFactorMantissa The new collateral factor, scaled by 1e18
      */
    function _setCollateralFactor(KToken kToken, uint newCollateralFactorMantissa) external onlyAdmin() {
        // Verify market is listed
        Market storage market = markets[address(kToken)];
        require(market.isListed, MARKET_NOT_LISTED);

        Exp memory newCollateralFactorExp = Exp({mantissa : newCollateralFactorMantissa});

        // Check collateral factor <= 0.9
        Exp memory highLimit = Exp({mantissa : collateralFactorMaxMantissa});
        require(!lessThanExp(highLimit, newCollateralFactorExp), INVALID_COLLATERAL_FACTOR);

        // If collateral factor != 0, fail if price == 0
        require(newCollateralFactorMantissa == 0 || oracle.getUnderlyingPrice(address(kToken)) != 0, "price error");

        // Set market's collateral factor to new collateral factor, remember old value
        uint oldCollateralFactorMantissa = market.collateralFactorMantissa;
        market.collateralFactorMantissa = newCollateralFactorMantissa;

        // Emit event with asset, old collateral factor, and new collateral factor
        emit NewCollateralFactor(kToken, oldCollateralFactorMantissa, newCollateralFactorMantissa);
    }

    /**
      * @notice Sets liquidationIncentive
      * @dev Admin function to set liquidationIncentive
      * @param newLiquidationIncentiveMantissa New liquidationIncentive scaled by 1e18
      */
    function _setLiquidationIncentive(uint newLiquidationIncentiveMantissa) external onlyAdmin() {
        require(newLiquidationIncentiveMantissa <= liquidationIncentiveMaxMantissa, INVALID_LIQUIDATION_INCENTIVE);
        require(newLiquidationIncentiveMantissa >= liquidationIncentiveMinMantissa, INVALID_LIQUIDATION_INCENTIVE);

        uint oldLiquidationIncentiveMantissa = liquidationIncentiveMantissa;
        liquidationIncentiveMantissa = newLiquidationIncentiveMantissa;
        emit NewLiquidationIncentive(oldLiquidationIncentiveMantissa, newLiquidationIncentiveMantissa);
    }

    /**
      * @notice Add the market to the markets mapping and set it as listed
      * @dev Admin function to set isListed and add support for the market
      * @param kToken The address of the market (token) to list
      */
    function _supportMarket(KToken kToken) external onlyAdmin() {
        require(!markets[address(kToken)].isListed, MARKET_ALREADY_LISTED);

        kToken.isKToken();
        // Sanity check to make sure its really a KToken

        markets[address(kToken)] = Market({isListed : true, collateralFactorMantissa : 0});

        _addMarketInternal(address(kToken));

        emit MarketListed(kToken);
    }

    function _addMarketInternal(address kToken) internal {
        for (uint i = 0; i < allMarkets.length; i ++) {
            require(allMarkets[i] != KToken(kToken), MARKET_ALREADY_ADDED);
        }
        allMarkets.push(KToken(kToken));
    }


    /**
      * @notice Set the given borrow caps for the given kToken markets. Borrowing that brings total borrows to or above borrow cap will revert.
      * @dev Admin or capGuardian can call this function to set the borrow caps. A borrow cap of 0 corresponds to unlimited borrowing.
      * @param kTokens The addresses of the markets (tokens) to change the borrow caps for
      * @param newBorrowCaps The new borrow cap values in underlying to be set. A value of 0 corresponds to unlimited borrowing.
      */
    function _setMarketBorrowCaps(KToken[] calldata kTokens, uint[] calldata newBorrowCaps) external {
        require(msg.sender == admin || msg.sender == capGuardian, "only admin or cap guardian can set borrow caps");

        uint numMarkets = kTokens.length;
        uint numBorrowCaps = newBorrowCaps.length;

        require(numMarkets != 0 && numMarkets == numBorrowCaps, "invalid input");

        for (uint i = 0; i < numMarkets; i++) {
            borrowCaps[address(kTokens[i])] = newBorrowCaps[i];
            emit NewBorrowCap(kTokens[i], newBorrowCaps[i]);
        }
    }

    /**
      * @notice Set the given supply caps for the given kToken markets. Supplying that brings total supply to or above supply cap will revert.
      * @dev Admin or capGuardian can call this function to set the supply caps. A supply cap of 0 corresponds to unlimited supplying.
      * @param kTokens The addresses of the markets (tokens) to change the supply caps for
      * @param newSupplyCaps The new supply cap values in underlying to be set. A value of 0 corresponds to unlimited supplying.
      */
    function _setMarketSupplyCaps(KToken[] calldata kTokens, uint[] calldata newSupplyCaps) external {
        require(msg.sender == admin || msg.sender == capGuardian, "only admin or cap guardian can set supply caps");

        uint numMarkets = kTokens.length;
        uint numSupplyCaps = newSupplyCaps.length;

        require(numMarkets != 0 && numMarkets == numSupplyCaps, "invalid input");

        for (uint i = 0; i < numMarkets; i++) {
            supplyCaps[address(kTokens[i])] = newSupplyCaps[i];
            emit NewSupplyCap(kTokens[i], newSupplyCaps[i]);
        }
    }

    /**
     * @notice Admin function to change the Borrow and Supply Cap Guardian
     * @param newCapGuardian The address of the new Cap Guardian
     */
    function _setCapGuardian(address newCapGuardian) external onlyAdmin() {
        address oldCapGuardian = capGuardian;
        capGuardian = newCapGuardian;
        emit NewCapGuardian(oldCapGuardian, newCapGuardian);
    }

    /**
     * @notice Admin function to change the Pause Guardian
     * @param newPauseGuardian The address of the new Pause Guardian
     */
    function _setPauseGuardian(address newPauseGuardian) external onlyAdmin() {
        address oldPauseGuardian = pauseGuardian;
        pauseGuardian = newPauseGuardian;
        emit NewPauseGuardian(oldPauseGuardian, pauseGuardian);
    }

    function _setMintPaused(KToken kToken, bool state) public returns (bool) {
        require(markets[address(kToken)].isListed, "cannot pause a market that is not listed");
        require(msg.sender == pauseGuardian || msg.sender == admin, "only pause guardian and admin can pause/unpause");

        mintGuardianPaused[address(kToken)] = state;
        emit ActionPaused(kToken, "Mint", state);
        return state;
    }

    function _setBorrowPaused(KToken kToken, bool state) public returns (bool) {
        require(markets[address(kToken)].isListed, "cannot pause a market that is not listed");
        require(msg.sender == pauseGuardian || msg.sender == admin, "only pause guardian and admin can pause/unpause");

        borrowGuardianPaused[address(kToken)] = state;
        emit ActionPaused(kToken, "Borrow", state);
        return state;
    }

    function _setTransferPaused(bool state) public returns (bool) {
        require(msg.sender == pauseGuardian || msg.sender == admin, "only pause guardian and admin can pause/unpause");

        transferGuardianPaused = state;
        emit ActionPaused("Transfer", state);
        return state;
    }

    function _setSeizePaused(bool state) public returns (bool) {
        require(msg.sender == pauseGuardian || msg.sender == admin, "only pause guardian and admin can pause/unpause");

        seizeGuardianPaused = state;
        emit ActionPaused("Seize", state);
        return state;
    }

    function _become(Unitroller unitroller) public {
        require(msg.sender == unitroller.admin(), "only unitroller admin can change brains");
        unitroller._acceptImplementation();
    }

    /**
     * @notice Return all of the markets
     * @dev The automatic getter may be used to access an individual market.
     * @return The list of market addresses
     */
    function getAllMarkets() public view returns (KToken[] memory) {
        return allMarkets;
    }

    function getBlockNumber() public view returns (uint) {
        return block.number;
    }

    function getOracle() external view returns (address) {
        return address(oracle);
    }

}

pragma solidity ^0.5.16;

import "./KToken.sol";
import "./KineOracleInterface.sol";

/**
Copyright 2020 Compound Labs, Inc.
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
* Original work from Compound: https://github.com/compound-finance/compound-protocol/blob/master/contracts/ComptrollerStorage.sol
* Modified to work in the Kine system.
* Main modifications:
*   1. removed Comp token related logics.
*   2. removed interest rate model related logics.
*   3. combined different versions storage contracts into one.
*/

contract UnitrollerAdminStorage {
    /**
    * @notice Administrator for this contract
    */
    address public admin;

    /**
    * @notice Pending administrator for this contract
    */
    address public pendingAdmin;

    /**
    * @notice Active brains of Unitroller
    */
    address public controllerImplementation;

    /**
    * @notice Pending brains of Unitroller
    */
    address public pendingControllerImplementation;
}

contract ControllerStorage is UnitrollerAdminStorage {

    struct Market {
        /// @notice Whether or not this market is listed
        bool isListed;

        /**
         * @notice Multiplier representing the most one can borrow against their collateral in this market.
         *  For instance, 0.9 to allow borrowing 90% of collateral value.
         *  Must be between 0 and 1, and stored as a mantissa.
         */
        uint collateralFactorMantissa;

        /// @notice Per-market mapping of "accounts in this asset"
        mapping(address => bool) accountMembership;
    }

    /**
     * @notice Oracle which gives the price of any given asset
     */
    KineOracleInterface public oracle;

    /**
     * @notice Multiplier used to calculate the maximum repayAmount when liquidating a borrow
     */
    uint public closeFactorMantissa;

    /**
     * @notice Multiplier representing the discount on collateral that a liquidator receives
     */
    uint public liquidationIncentiveMantissa;

    /**
     * @notice Max number of assets a single account can participate in (borrow or use as collateral)
     */
    uint public maxAssets;

    /**
     * @notice Per-account mapping of "assets you are in", capped by maxAssets
     */
    mapping(address => KToken[]) public accountAssets;

    /**
     * @notice Official mapping of kTokens -> Market metadata
     * @dev Used e.g. to determine if a market is supported
     */
    mapping(address => Market) public markets;

    /// @notice A list of all markets
    KToken[] public allMarkets;

    /**
     * @notice The Pause Guardian can pause certain actions as a safety mechanism.
     *  Actions which allow users to remove their own assets cannot be paused.
     *  Liquidation / seizing / transfer can only be paused globally, not by market.
     */
    address public pauseGuardian;
    // @notice The capGuardian can set borrowCaps/supplyCaps to any number for any market. Lowering the borrow/supply cap could disable borrowing/supplying on the given market.
    address public capGuardian;
    bool public transferGuardianPaused;
    bool public seizeGuardianPaused;
    mapping(address => bool) public mintGuardianPaused;
    mapping(address => bool) public borrowGuardianPaused;

    // @notice Borrow caps enforced by borrowAllowed for each kToken address. Defaults to zero which corresponds to unlimited borrowing.
    mapping(address => uint) public borrowCaps;
    // @notice Supply caps enforced by mintAllowed for each kToken address. Defaults to zero which corresponds to unlimited supplying.
    mapping(address => uint) public supplyCaps;

}

pragma solidity ^0.5.16;

/**
Copyright 2020 Compound Labs, Inc.
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @title ERC 20 Token Standard Interface
 *  https://eips.ethereum.org/EIPS/eip-20
 */
interface EIP20Interface {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    /**
      * @notice Get the total number of tokens in circulation
      * @return The supply of tokens
      */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return Whether or not the transfer succeeded
      */
    function transfer(address dst, uint256 amount) external returns (bool success);

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return Whether or not the transfer succeeded
      */
    function transferFrom(address src, address dst, uint256 amount) external returns (bool success);

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved (-1 means infinite)
      * @return Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return The number of tokens allowed to be spent (-1 means infinite)
      */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

pragma solidity ^0.5.16;

/**
Copyright 2020 Compound Labs, Inc.
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @title EIP20NonStandardInterface
 * @dev Version of ERC20 with no return values for `transfer` and `transferFrom`
 *  See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
interface EIP20NonStandardInterface {

    /**
     * @notice Get the total number of tokens in circulation
     * @return The supply of tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transfer` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transfer(address dst, uint256 amount) external;

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transferFrom` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transferFrom(address src, address dst, uint256 amount) external;

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved
      * @return Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return The number of tokens allowed to be spent
      */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

pragma solidity ^0.5.16;

/**
Copyright 2020 Compound Labs, Inc.
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
* Original work from Compound: https://github.com/compound-finance/compound-protocol/blob/master/contracts/ErrorReporter.sol
* Modified to work in the Kine system.
* Main modifications:
*   1. using constant string instead of enums
*/

contract ControllerErrorReporter {
    string internal constant MARKET_NOT_LISTED = "MARKET_NOT_LISTED";
    string internal constant MARKET_ALREADY_LISTED = "MARKET_ALREADY_LISTED";
    string internal constant MARKET_ALREADY_ADDED = "MARKET_ALREADY_ADDED";
    string internal constant EXIT_MARKET_BALANCE_OWED = "EXIT_MARKET_BALANCE_OWED";
    string internal constant EXIT_MARKET_REJECTION = "EXIT_MARKET_REJECTION";
    string internal constant MINT_PAUSED = "MINT_PAUSED";
    string internal constant BORROW_PAUSED = "BORROW_PAUSED";
    string internal constant SEIZE_PAUSED = "SEIZE_PAUSED";
    string internal constant TRANSFER_PAUSED = "TRANSFER_PAUSED";
    string internal constant MARKET_BORROW_CAP_REACHED = "MARKET_BORROW_CAP_REACHED";
    string internal constant MARKET_SUPPLY_CAP_REACHED = "MARKET_SUPPLY_CAP_REACHED";
    string internal constant REDEEM_TOKENS_ZERO = "REDEEM_TOKENS_ZERO";
    string internal constant INSUFFICIENT_LIQUIDITY = "INSUFFICIENT_LIQUIDITY";
    string internal constant INSUFFICIENT_SHORTFALL = "INSUFFICIENT_SHORTFALL";
    string internal constant TOO_MUCH_REPAY = "TOO_MUCH_REPAY";
    string internal constant CONTROLLER_MISMATCH = "CONTROLLER_MISMATCH";
    string internal constant INVALID_COLLATERAL_FACTOR = "INVALID_COLLATERAL_FACTOR";
    string internal constant INVALID_CLOSE_FACTOR = "INVALID_CLOSE_FACTOR";
    string internal constant INVALID_LIQUIDATION_INCENTIVE = "INVALID_LIQUIDATION_INCENTIVE";
}

contract KTokenErrorReporter {
    string internal constant BAD_INPUT = "BAD_INPUT";
    string internal constant TRANSFER_NOT_ALLOWED = "TRANSFER_NOT_ALLOWED";
    string internal constant TRANSFER_NOT_ENOUGH = "TRANSFER_NOT_ENOUGH";
    string internal constant TRANSFER_TOO_MUCH = "TRANSFER_TOO_MUCH";
    string internal constant MINT_NEW_TOTAL_SUPPLY_CALCULATION_FAILED = "MINT_NEW_TOTAL_SUPPLY_CALCULATION_FAILED";
    string internal constant MINT_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED = "MINT_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED";
    string internal constant REDEEM_NEW_TOTAL_SUPPLY_CALCULATION_FAILED = "REDEEM_NEW_TOTAL_SUPPLY_CALCULATION_FAILED";
    string internal constant REDEEM_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED = "REDEEM_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED";
    string internal constant BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED = "BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED";
    string internal constant BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED = "BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED";
    string internal constant REPAY_BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED = "REPAY_BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED";
    string internal constant REPAY_BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED = "REPAY_BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED";
    string internal constant INVALID_CLOSE_AMOUNT_REQUESTED = "INVALID_CLOSE_AMOUNT_REQUESTED";
    string internal constant LIQUIDATE_SEIZE_TOO_MUCH = "LIQUIDATE_SEIZE_TOO_MUCH";
    string internal constant TOKEN_INSUFFICIENT_CASH = "TOKEN_INSUFFICIENT_CASH";
    string internal constant INVALID_ACCOUNT_PAIR = "INVALID_ACCOUNT_PAIR";
    string internal constant LIQUIDATE_SEIZE_BALANCE_DECREMENT_FAILED = "LIQUIDATE_SEIZE_BALANCE_DECREMENT_FAILED";
    string internal constant LIQUIDATE_SEIZE_BALANCE_INCREMENT_FAILED = "LIQUIDATE_SEIZE_BALANCE_INCREMENT_FAILED";
    string internal constant TOKEN_TRANSFER_IN_FAILED = "TOKEN_TRANSFER_IN_FAILED";
    string internal constant TOKEN_TRANSFER_IN_OVERFLOW = "TOKEN_TRANSFER_IN_OVERFLOW";
    string internal constant TOKEN_TRANSFER_OUT_FAILED = "TOKEN_TRANSFER_OUT_FAILED";

}

pragma solidity ^0.5.16;

import "./KineSafeMath.sol";

/**
Copyright 2020 Compound Labs, Inc.
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
* Original work from Compound: https://github.com/compound-finance/compound-protocol/blob/master/contracts/Comptroller.sol
* Modified to work in the Kine system.
* Main modifications:
*   1. use SafeMath instead of CarefulMath to fail fast and loudly
*/

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Compound
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract Exponential {
    using KineSafeMath for uint;
    uint constant expScale = 1e18;
    uint constant doubleScale = 1e36;
    uint constant halfExpScale = expScale / 2;
    uint constant mantissaOne = expScale;

    struct Exp {
        uint mantissa;
    }

    struct Double {
        uint mantissa;
    }

    /**
     * @dev Creates an exponential from numerator and denominator values.
     */
    function getExp(uint num, uint denom) pure internal returns (Exp memory) {
        uint rational = num.mul(expScale).div(denom);
        return Exp({mantissa : rational});
    }

    /**
     * @dev Adds two exponentials, returning a new exponential.
     */
    function addExp(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        uint result = a.mantissa.add(b.mantissa);
        return Exp({mantissa : result});
    }

    /**
     * @dev Subtracts two exponentials, returning a new exponential.
     */
    function subExp(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        uint result = a.mantissa.sub(b.mantissa);
        return Exp({mantissa : result});
    }

    /**
     * @dev Multiply an Exp by a scalar, returning a new Exp.
     */
    function mulScalar(Exp memory a, uint scalar) pure internal returns (Exp memory) {
        uint scaledMantissa = a.mantissa.mul(scalar);
        return Exp({mantissa : scaledMantissa});
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mulScalarTruncate(Exp memory a, uint scalar) pure internal returns (uint) {
        Exp memory product = mulScalar(a, scalar);
        return truncate(product);
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mulScalarTruncateAddUInt(Exp memory a, uint scalar, uint addend) pure internal returns (uint) {
        Exp memory product = mulScalar(a, scalar);
        return truncate(product).add(addend);
    }

    /**
     * @dev Divide an Exp by a scalar, returning a new Exp.
     */
    function divScalar(Exp memory a, uint scalar) pure internal returns (Exp memory) {
        uint descaledMantissa = a.mantissa.div(scalar);
        return Exp({mantissa : descaledMantissa});
    }

    /**
     * @dev Divide a scalar by an Exp, returning a new Exp.
     */
    function divScalarByExp(uint scalar, Exp memory divisor) pure internal returns (Exp memory) {
        /*
          We are doing this as:
          getExp(expScale.mul(scalar), divisor.mantissa)

          How it works:
          Exp = a / b;
          Scalar = s;
          `s / (a / b)` = `b * s / a` and since for an Exp `a = mantissa, b = expScale`
        */
        uint numerator = expScale.mul(scalar);
        return getExp(numerator, divisor.mantissa);
    }

    /**
     * @dev Divide a scalar by an Exp, then truncate to return an unsigned integer.
     */
    function divScalarByExpTruncate(uint scalar, Exp memory divisor) pure internal returns (uint) {
        Exp memory fraction = divScalarByExp(scalar, divisor);
        return truncate(fraction);
    }

    /**
     * @dev Multiplies two exponentials, returning a new exponential.
     */
    function mulExp(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        uint doubleScaledProduct = a.mantissa.mul(b.mantissa);

        // We add half the scale before dividing so that we get rounding instead of truncation.
        //  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717
        // Without this change, a result like 6.6...e-19 will be truncated to 0 instead of being rounded to 1e-18.
        uint doubleScaledProductWithHalfScale = halfExpScale.add(doubleScaledProduct);
        uint product = doubleScaledProductWithHalfScale.div(expScale);
        return Exp({mantissa : product});
    }

    /**
     * @dev Multiplies two exponentials given their mantissas, returning a new exponential.
     */
    function mulExp(uint a, uint b) pure internal returns (Exp memory) {
        return mulExp(Exp({mantissa : a}), Exp({mantissa : b}));
    }

    /**
     * @dev Divides two exponentials, returning a new exponential.
     *     (a/scale) / (b/scale) = (a/scale) * (scale/b) = a/b,
     *  which we can scale as an Exp by calling getExp(a.mantissa, b.mantissa)
     */
    function divExp(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return getExp(a.mantissa, b.mantissa);
    }

    /**
     * @dev Truncates the given exp to a whole number value.
     *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
     */
    function truncate(Exp memory exp) pure internal returns (uint) {
        // Note: We are not using careful math here as we're performing a division that cannot fail
        return exp.mantissa / expScale;
    }

    /**
     * @dev Checks if first Exp is less than second Exp.
     */
    function lessThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa < right.mantissa;
    }

    /**
     * @dev Checks if left Exp <= right Exp.
     */
    function lessThanOrEqualExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa <= right.mantissa;
    }

    /**
     * @dev Checks if left Exp > right Exp.
     */
    function greaterThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa > right.mantissa;
    }

    /**
     * @dev returns true if Exp is exactly zero
     */
    function isZeroExp(Exp memory value) pure internal returns (bool) {
        return value.mantissa == 0;
    }

    function safe224(uint n, string memory errorMessage) pure internal returns (uint224) {
        require(n < 2 ** 224, errorMessage);
        return uint224(n);
    }

    function safe32(uint n, string memory errorMessage) pure internal returns (uint32) {
        require(n < 2 ** 32, errorMessage);
        return uint32(n);
    }

    function add_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa : add_(a.mantissa, b.mantissa)});
    }

    function add_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa : add_(a.mantissa, b.mantissa)});
    }

    function add_(uint a, uint b) pure internal returns (uint) {
        return add_(a, b, "addition overflow");
    }

    function add_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa : sub_(a.mantissa, b.mantissa)});
    }

    function sub_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa : sub_(a.mantissa, b.mantissa)});
    }

    function sub_(uint a, uint b) pure internal returns (uint) {
        return sub_(a, b, "subtraction underflow");
    }

    function sub_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function mul_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa : mul_(a.mantissa, b.mantissa) / expScale});
    }

    function mul_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa : mul_(a.mantissa, b)});
    }

    function mul_(uint a, Exp memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / expScale;
    }

    function mul_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa : mul_(a.mantissa, b.mantissa) / doubleScale});
    }

    function mul_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa : mul_(a.mantissa, b)});
    }

    function mul_(uint a, Double memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / doubleScale;
    }

    function mul_(uint a, uint b) pure internal returns (uint) {
        return mul_(a, b, "multiplication overflow");
    }

    function mul_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        if (a == 0 || b == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b, errorMessage);
        return c;
    }

    function div_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa : div_(mul_(a.mantissa, expScale), b.mantissa)});
    }

    function div_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa : div_(a.mantissa, b)});
    }

    function div_(uint a, Exp memory b) pure internal returns (uint) {
        return div_(mul_(a, expScale), b.mantissa);
    }

    function div_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa : div_(mul_(a.mantissa, doubleScale), b.mantissa)});
    }

    function div_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa : div_(a.mantissa, b)});
    }

    function div_(uint a, Double memory b) pure internal returns (uint) {
        return div_(mul_(a, doubleScale), b.mantissa);
    }

    function div_(uint a, uint b) pure internal returns (uint) {
        return div_(a, b, "divide by zero");
    }

    function div_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function fraction(uint a, uint b) pure internal returns (Double memory) {
        return Double({mantissa : div_(mul_(a, doubleScale), b)});
    }
}

pragma solidity ^0.5.16;

import "./KineControllerInterface.sol";
import "./KMCDInterfaces.sol";
import "./ErrorReporter.sol";
import "./Exponential.sol";
import "./KTokenInterfaces.sol";

/**
Copyright 2020 Compound Labs, Inc.
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
* Original work from Compound: https://github.com/compound-finance/compound-protocol/blob/master/contracts/CToken.sol
* Modified to work in the Kine system.
* Main modifications:
*   1. removed Comp token related logics.
*   2. removed interest rate model related logics.
*   3. removed mint, redeem logics. users can only supply kTokens (see KToken) and borrow Kine MCD.
*   4. removed transfer logics. MCD can't be transferred.
*   5. removed error code propagation mechanism, using revert to fail fast and loudly.
*/

/**
 * @title Kine's KMCD Contract
 * @notice Kine Market Connected Debt (MCD) contract. Users are allowed to call KUSDMinter to borrow Kine MCD and mint KUSD
 * after they supply collaterals in KTokens. One should notice that Kine MCD is not ERC20 token since it can't be transferred by user.
 * @author Kine
 */
contract KMCD is KMCDInterface, Exponential, KTokenErrorReporter {
    modifier onlyAdmin(){
        require(msg.sender == admin, "only admin can call this function");
        _;
    }

    /// @notice Prevent anyone other than minter from borrow/repay Kine MCD
    modifier onlyMinter {
        require(
            msg.sender == minter,
            "Only minter can call this function."
        );
        _;
    }

    /**
     * @notice Initialize the money market
     * @param controller_ The address of the Controller
     * @param name_ Name of this MCD token
     * @param symbol_ Symbol of this MCD token
     * @param decimals_ Decimal precision of this token
     */
    function initialize(KineControllerInterface controller_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address minter_) public {
        require(msg.sender == admin, "only admin may initialize the market");
        require(initialized == false, "market may only be initialized once");

        // Set the controller
        _setController(controller_);

        minter = minter_;
        name = name_;
        symbol = symbol_;
        decimals = decimals_;

        // The counter starts true to prevent changing it from zero to non-zero (i.e. smaller cost/refund)
        _notEntered = true;
        initialized = true;
    }

    /*** User Interface ***/

    /**
      * @notice Only minter can borrow Kine MCD on behalf of user from the protocol
      * @param borrowAmount Amount of Kine MCD to borrow on behalf of user
      */
    function borrowBehalf(address payable borrower, uint borrowAmount) onlyMinter external {
        borrowInternal(borrower, borrowAmount);
    }

    /**
     * @notice Only minter can repay Kine MCD on behalf of borrower to the protocol
     * @param borrower Account with the MCD being payed off
     * @param repayAmount The amount to repay
     */
    function repayBorrowBehalf(address borrower, uint repayAmount) onlyMinter external {
        repayBorrowBehalfInternal(borrower, repayAmount);
    }

    /**
     * @notice Only minter can liquidates the borrowers collateral on behalf of user
     *  The collateral seized is transferred to the liquidator
     * @param borrower The borrower of MCD to be liquidated
     * @param repayAmount The amount of the MCD to repay
     * @param kTokenCollateral The market in which to seize collateral from the borrower
     */
    function liquidateBorrowBehalf(address liquidator, address borrower, uint repayAmount, KTokenInterface kTokenCollateral) onlyMinter external {
        liquidateBorrowInternal(liquidator, borrower, repayAmount, kTokenCollateral);
    }

    /**
     * @notice Get a snapshot of the account's balances
     * @dev This is used by controller to more efficiently perform liquidity checks.
     * @param account Address of the account to snapshot
     * @return (token balance, borrow balance)
     */
    function getAccountSnapshot(address account) external view returns (uint, uint) {
        return (0, accountBorrows[account]);
    }

    /**
     * @dev Function to simply retrieve block number
     *  This exists mainly for inheriting test contracts to stub this result.
     */
    function getBlockNumber() internal view returns (uint) {
        return block.number;
    }

    /**
     * @notice get account's borrow balance
     * @param account The address whose balance should be get
     * @return The balance
     */
    function borrowBalance(address account) public view returns (uint) {
        return accountBorrows[account];
    }

    /**
      * @notice Sender borrows MCD from the protocol to their own address
      * @param borrowAmount The amount of MCD to borrow
      */
    function borrowInternal(address payable borrower, uint borrowAmount) internal nonReentrant {
        borrowFresh(borrower, borrowAmount);
    }

    struct BorrowLocalVars {
        uint accountBorrows;
        uint accountBorrowsNew;
        uint totalBorrowsNew;
    }

    /**
      * @notice Sender borrow MCD from the protocol to their own address
      * @param borrowAmount The amount of the MCD to borrow
      */
    function borrowFresh(address payable borrower, uint borrowAmount) internal {
        /* Fail if borrow not allowed */
        (bool allowed, string memory reason) = controller.borrowAllowed(address(this), borrower, borrowAmount);
        require(allowed, reason);

        BorrowLocalVars memory vars;

        /*
         * We calculate the new borrower and total borrow balances, failing on overflow:
         *  accountBorrowsNew = accountBorrows + borrowAmount
         *  totalBorrowsNew = totalBorrows + borrowAmount
         */
        vars.accountBorrows = accountBorrows[borrower];

        vars.accountBorrowsNew = vars.accountBorrows.add(borrowAmount, BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED);
        vars.totalBorrowsNew = totalBorrows.add(borrowAmount, BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED);

        /* We write the previously calculated values into storage */
        accountBorrows[borrower] = vars.accountBorrowsNew;
        totalBorrows = vars.totalBorrowsNew;

        /* We emit a Borrow event */
        emit Borrow(borrower, borrowAmount, vars.accountBorrowsNew, vars.totalBorrowsNew);

        /* We call the defense hook */
        controller.borrowVerify(address(this), borrower, borrowAmount);
    }

    /**
     * @notice Sender repays MCD belonging to borrower
     * @param borrower the account with the MCD being payed off
     * @param repayAmount The amount to repay
     * @return the actual repayment amount.
     */
    function repayBorrowBehalfInternal(address borrower, uint repayAmount) internal nonReentrant returns (uint) {
        return repayBorrowFresh(msg.sender, borrower, repayAmount);
    }

    struct RepayBorrowLocalVars {
        uint accountBorrows;
        uint accountBorrowsNew;
        uint totalBorrowsNew;
    }

    /**
     * @notice Borrows are repaid by another user, should be the minter.
     * @param payer the account paying off the MCD
     * @param borrower the account with the MCD being payed off
     * @param repayAmount the amount of MCD being returned
     * @return the actual repayment amount.
     */
    function repayBorrowFresh(address payer, address borrower, uint repayAmount) internal returns (uint) {
        /* Fail if repayBorrow not allowed */
        (bool allowed, string memory reason) = controller.repayBorrowAllowed(address(this), payer, borrower, repayAmount);
        require(allowed, reason);

        RepayBorrowLocalVars memory vars;

        /* We fetch the amount the borrower owes */
        vars.accountBorrows = accountBorrows[borrower];

        /*
         * We calculate the new borrower and total borrow balances, failing on underflow:
         *  accountBorrowsNew = accountBorrows - actualRepayAmount
         *  totalBorrowsNew = totalBorrows - actualRepayAmount
         */
        vars.accountBorrowsNew = vars.accountBorrows.sub(repayAmount, REPAY_BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED);
        vars.totalBorrowsNew = totalBorrows.sub(repayAmount, REPAY_BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED);

        /* We write the previously calculated values into storage */
        accountBorrows[borrower] = vars.accountBorrowsNew;
        totalBorrows = vars.totalBorrowsNew;

        /* We emit a RepayBorrow event */
        emit RepayBorrow(payer, borrower, repayAmount, vars.accountBorrowsNew, vars.totalBorrowsNew);

        /* We call the defense hook */
        controller.repayBorrowVerify(address(this), payer, borrower, repayAmount);

        return repayAmount;
    }

    /**
     * @notice The sender liquidates the borrowers collateral.
     *  The collateral seized is transferred to the liquidator.
     * @param borrower The borrower of this MCD to be liquidated
     * @param kTokenCollateral The market in which to seize collateral from the borrower
     * @param repayAmount The amount of the MCD asset to repay
     * @return the actual repayment amount.
     */
    function liquidateBorrowInternal(address liquidator, address borrower, uint repayAmount, KTokenInterface kTokenCollateral) internal nonReentrant returns (uint) {
        return liquidateBorrowFresh(liquidator, borrower, repayAmount, kTokenCollateral);
    }

    /**
     * @notice The liquidator liquidates the borrowers collateral.
     *  The collateral seized is transferred to the liquidator.
     * @param borrower The borrower of this MCD to be liquidated
     * @param liquidator The address repaying the MCD and seizing collateral
     * @param kTokenCollateral The market in which to seize collateral from the borrower
     * @param repayAmount The amount of the borrowed MCD to repay
     * @return the actual repayment amount.
     */
    function liquidateBorrowFresh(address liquidator, address borrower, uint repayAmount, KTokenInterface kTokenCollateral) internal returns (uint) {
        /* Revert if trying to seize MCD */
        require(address(kTokenCollateral) != address(this), "Kine MCD can't be seized");

        /* Fail if liquidate not allowed */
        (bool allowed, string memory reason) = controller.liquidateBorrowAllowed(address(this), address(kTokenCollateral), liquidator, borrower, repayAmount);
        require(allowed, reason);

        /* Fail if borrower = liquidator */
        require(borrower != liquidator, INVALID_ACCOUNT_PAIR);

        /* Fail if repayAmount = 0 */
        require(repayAmount != 0, INVALID_CLOSE_AMOUNT_REQUESTED);

        /* Fail if repayAmount = -1 */
        require(repayAmount != uint(- 1), INVALID_CLOSE_AMOUNT_REQUESTED);

        /* Fail if repayBorrow fails */
        uint actualRepayAmount = repayBorrowFresh(liquidator, borrower, repayAmount);

        /////////////////////////
        // EFFECTS & INTERACTIONS

        /* We calculate the number of collateral tokens that will be seized */
        uint seizeTokens = controller.liquidateCalculateSeizeTokens(address(this), address(kTokenCollateral), actualRepayAmount);

        /* Revert if borrower collateral token balance < seizeTokens */
        require(kTokenCollateral.balanceOf(borrower) >= seizeTokens, LIQUIDATE_SEIZE_TOO_MUCH);

        /* Seize borrower tokens to liquidator */
        kTokenCollateral.seize(liquidator, borrower, seizeTokens);

        /* We emit a LiquidateBorrow event */
        emit LiquidateBorrow(liquidator, borrower, actualRepayAmount, address(kTokenCollateral), seizeTokens);

        /* We call the defense hook */
        controller.liquidateBorrowVerify(address(this), address(kTokenCollateral), liquidator, borrower, actualRepayAmount, seizeTokens);

        return actualRepayAmount;
    }

    /*** Admin Functions ***/

    /**
      * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @param newPendingAdmin New pending admin.
      */
    function _setPendingAdmin(address payable newPendingAdmin) external onlyAdmin() {
        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    /**
      * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
      * @dev Admin function for pending admin to accept role and update admin
      */
    function _acceptAdmin() external {
        // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
        require(msg.sender == pendingAdmin && msg.sender != address(0), "unauthorized");

        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }

    /**
      * @notice Sets a new controller for the market
      * @dev Admin function to set a new controller
      */
    function _setController(KineControllerInterface newController) public onlyAdmin() {
        KineControllerInterface oldController = controller;
        // Ensure invoke controller.isController() returns true
        require(newController.isController(), "marker method returned false");

        // Set market's controller to newController
        controller = newController;

        // Emit NewController(oldController, newController)
        emit NewController(oldController, newController);
    }

    function _setMinter(address newMinter) public onlyAdmin() {
        address oldMinter = minter;
        minter = newMinter;

        emit NewMinter(oldMinter, newMinter);
    }

    /*** Reentrancy Guard ***/

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     */
    modifier nonReentrant() {
        require(_notEntered, "re-entered");
        _notEntered = false;
        _;
        _notEntered = true;
        // get a gas-refund post-Istanbul
    }
}

pragma solidity ^0.5.16;

import "./KineControllerInterface.sol";

contract KMCDStorage {
    /**
     * @dev Guard variable for re-entrancy checks
     */
    bool internal _notEntered;

    /**
    * @notice flag that Kine MCD has been initialized;
    */
    bool public initialized;

    /**
    * @notice Only KUSDMinter can borrow/repay Kine MCD on behalf of users;
    */
    address public minter;

    /**
     * @notice Name for this MCD
     */
    string public name;

    /**
     * @notice Symbol for this MCD
     */
    string public symbol;

    /**
     * @notice Decimals for this MCD
     */
    uint8 public decimals;

    /**
     * @notice Administrator for this contract
     */
    address payable public admin;

    /**
     * @notice Pending administrator for this contract
     */
    address payable public pendingAdmin;

    /**
     * @notice Contract which oversees inter-kToken operations
     */
    KineControllerInterface public controller;

    /**
     * @notice Approved token transfer amounts on behalf of others
     */
    mapping(address => mapping(address => uint)) internal transferAllowances;

    /**
     * @notice Total amount of outstanding borrows of the MCD
     */
    uint public totalBorrows;

    /**
     * @notice Mapping of account addresses to outstanding borrow balances
     */
    mapping(address => uint) internal accountBorrows;
}

contract KMCDInterface is KMCDStorage {
    /**
     * @notice Indicator that this is a KToken contract (for inspection)
     */
    bool public constant isKToken = true;


    /*** Market Events ***/

    /**
     * @notice Event emitted when MCD is borrowed
     */
    event Borrow(address borrower, uint borrowAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(address payer, address borrower, uint repayAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is liquidated
     */
    event LiquidateBorrow(address liquidator, address borrower, uint repayAmount, address kTokenCollateral, uint seizeTokens);


    /*** Admin Events ***/

    /**
     * @notice Event emitted when pendingAdmin is changed
     */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     * @notice Event emitted when pendingAdmin is accepted, which means admin is updated
     */
    event NewAdmin(address oldAdmin, address newAdmin);

    /**
     * @notice Event emitted when controller is changed
     */
    event NewController(KineControllerInterface oldController, KineControllerInterface newController);

    /**
     * @notice Event emitted when minter is changed
     */
    event NewMinter(address oldMinter, address newMinter);


    /*** User Interface ***/

    function getAccountSnapshot(address account) external view returns (uint, uint);

    function borrowBalance(address account) public view returns (uint);

    /*** Admin Functions ***/

    function _setPendingAdmin(address payable newPendingAdmin) external;

    function _acceptAdmin() external;

    function _setController(KineControllerInterface newController) public;
}

pragma solidity ^0.5.16;

import "./KineControllerInterface.sol";
import "./KTokenInterfaces.sol";
import "./ErrorReporter.sol";
import "./Exponential.sol";
import "./EIP20Interface.sol";
import "./EIP20NonStandardInterface.sol";

/**
Copyright 2020 Compound Labs, Inc.
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
* Original work from Compound: https://github.com/compound-finance/compound-protocol/blob/master/contracts/CToken.sol
* Modified to work in the Kine system.
* Main modifications:
*   1. removed Comp token related logics.
*   2. removed interest rate model related logics.
*   3. removed borrow/repay logics. users can only mint/redeem kTokens and borrow Kine MCD (see KMCD).
*   4. removed error code propagation mechanism, using revert to fail fast and loudly.
*/

/**
 * @title Kine's KToken Contract
 * @notice Abstract base for KTokens
 * @author Kine
 */
contract KToken is KTokenInterface, Exponential, KTokenErrorReporter {
    modifier onlyAdmin(){
        require(msg.sender == admin, "only admin can call this function");
        _;
    }

    /**
     * @notice Initialize the money market
     * @param controller_ The address of the Controller
     * @param name_ EIP-20 name of this token
     * @param symbol_ EIP-20 symbol of this token
     * @param decimals_ EIP-20 decimal precision of this token
     */
    function initialize(KineControllerInterface controller_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_) public {
        require(msg.sender == admin, "only admin may initialize the market");
        require(initialized == false, "market may only be initialized once");

        // Set the controller
        _setController(controller_);

        name = name_;
        symbol = symbol_;
        decimals = decimals_;

        // The counter starts true to prevent changing it from zero to non-zero (i.e. smaller cost/refund)
        _notEntered = true;
        initialized = true;
    }

    /**
     * @notice Transfer `tokens` tokens from `src` to `dst` by `spender`
     * @dev Called by both `transfer` and `transferFrom` internally
     * @param spender The address of the account performing the transfer
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param tokens The number of tokens to transfer
     */
    function transferTokens(address spender, address src, address dst, uint tokens) internal {
        /* Fail if transfer not allowed */
        (bool allowed, string memory reason) = controller.transferAllowed(address(this), src, dst, tokens);
        require(allowed, reason);

        /* Do not allow self-transfers */
        require(src != dst, BAD_INPUT);

        /* Get the allowance, infinite for the account owner */
        uint startingAllowance = 0;
        if (spender == src) {
            startingAllowance = uint(- 1);
        } else {
            startingAllowance = transferAllowances[src][spender];
        }

        /* Do the calculations, checking for {under,over}flow */
        uint allowanceNew = startingAllowance.sub(tokens, TRANSFER_NOT_ALLOWED);
        uint srcTokensNew = accountTokens[src].sub(tokens, TRANSFER_NOT_ENOUGH);
        uint dstTokensNew = accountTokens[dst].add(tokens, TRANSFER_TOO_MUCH);

        /////////////////////////
        // EFFECTS & INTERACTIONS
        accountTokens[src] = srcTokensNew;
        accountTokens[dst] = dstTokensNew;

        /* Eat some of the allowance (if necessary) */
        if (startingAllowance != uint(- 1)) {
            transferAllowances[src][spender] = allowanceNew;
        }

        /* We emit a Transfer event */
        emit Transfer(src, dst, tokens);

        controller.transferVerify(address(this), src, dst, tokens);
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 amount) external nonReentrant returns (bool) {
        transferTokens(msg.sender, msg.sender, dst, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(address src, address dst, uint256 amount) external nonReentrant returns (bool) {
        transferTokens(msg.sender, src, dst, amount);
        return true;
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (uint256(-1) means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        address src = msg.sender;
        transferAllowances[src][spender] = amount;
        emit Approval(src, spender, amount);
        return true;
    }

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return The number of tokens allowed to be spent (-1 means infinite)
     */
    function allowance(address owner, address spender) external view returns (uint256) {
        return transferAllowances[owner][spender];
    }

    /**
     * @notice Get the token balance of the `owner`
     * @param owner The address of the account to query
     * @return The number of tokens owned by `owner`
     */
    function balanceOf(address owner) external view returns (uint256) {
        return accountTokens[owner];
    }


    /**
     * @notice Get a snapshot of the account's balances
     * @dev This is used by controller to more efficiently perform liquidity checks.
     * and for kTokens, there is only token balance, for kMCD, there is only borrow balance
     * @param account Address of the account to snapshot
     * @return (token balance, borrow balance)
     */
    function getAccountSnapshot(address account) external view returns (uint, uint) {
        return (accountTokens[account], 0);
    }

    /**
     * @dev Function to simply retrieve block number
     *  This exists mainly for inheriting test contracts to stub this result.
     */
    function getBlockNumber() internal view returns (uint) {
        return block.number;
    }

    /**
     * @notice Get cash balance of this kToken in the underlying asset
     * @return The quantity of underlying asset owned by this contract
     */
    function getCash() external view returns (uint) {
        return getCashPrior();
    }

    /**
     * @notice Sender supplies assets into the market and receives kTokens in exchange
     * @param mintAmount The amount of the underlying asset to supply
     * @return the actual mint amount.
     */
    function mintInternal(uint mintAmount) internal nonReentrant returns (uint) {
        return mintFresh(msg.sender, mintAmount);
    }

    struct MintLocalVars {
        uint mintTokens;
        uint totalSupplyNew;
        uint accountTokensNew;
        uint actualMintAmount;
    }

    /**
     * @notice User supplies assets into the market and receives kTokens in exchange
     * @param minter The address of the account which is supplying the assets
     * @param mintAmount The amount of the underlying asset to supply
     * @return the actual mint amount.
     */
    function mintFresh(address minter, uint mintAmount) internal returns (uint) {
        /* Fail if mint not allowed */
        (bool allowed, string memory reason) = controller.mintAllowed(address(this), minter, mintAmount);
        require(allowed, reason);

        MintLocalVars memory vars;

        /////////////////////////
        // EFFECTS & INTERACTIONS

        /*
         *  We call `doTransferIn` for the minter and the mintAmount.
         *  Note: The kToken must handle variations between ERC-20 and ETH underlying.
         *  `doTransferIn` reverts if anything goes wrong, since we can't be sure if
         *  side-effects occurred. The function returns the amount actually transferred,
         *  in case of a fee. On success, the kToken holds an additional `actualMintAmount`
         *  of cash.
         */
        vars.actualMintAmount = doTransferIn(minter, mintAmount);

        /*
         *  mintTokens = actualMintAmount
         */
        vars.mintTokens = vars.actualMintAmount;

        /*
         * We calculate the new total supply of kTokens and minter token balance, checking for overflow:
         *  totalSupplyNew = totalSupply + mintTokens
         *  accountTokensNew = accountTokens[minter] + mintTokens
         */
        vars.totalSupplyNew = totalSupply.add(vars.mintTokens, MINT_NEW_TOTAL_SUPPLY_CALCULATION_FAILED);
        vars.accountTokensNew = accountTokens[minter].add(vars.mintTokens, MINT_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED);

        /* We write previously calculated values into storage */
        totalSupply = vars.totalSupplyNew;
        accountTokens[minter] = vars.accountTokensNew;

        /* We emit a Mint event, and a Transfer event */
        emit Mint(minter, vars.actualMintAmount, vars.mintTokens);
        emit Transfer(address(this), minter, vars.mintTokens);

        /* We call the defense hook */
        controller.mintVerify(address(this), minter, vars.actualMintAmount, vars.mintTokens);

        return vars.actualMintAmount;
    }

    /**
     * @notice Sender redeems kTokens in exchange for the underlying asset
     * @param redeemTokens The number of kTokens to redeem into underlying
     */
    function redeemInternal(uint redeemTokens) internal nonReentrant {
        redeemFresh(msg.sender, redeemTokens);
    }

    struct RedeemLocalVars {
        uint totalSupplyNew;
        uint accountTokensNew;
    }

    /**
     * @notice User redeems kTokens in exchange for the underlying asset
     * @param redeemer The address of the account which is redeeming the tokens
     * @param redeemTokensIn The number of kTokens to redeem into underlying (only one of redeemTokensIn or redeemAmountIn may be non-zero)
     */
    function redeemFresh(address payable redeemer, uint redeemTokensIn) internal {
        require(redeemTokensIn != 0, "redeemTokensIn must not be zero");

        RedeemLocalVars memory vars;

        /* Fail if redeem not allowed */
        (bool allowed, string memory reason) = controller.redeemAllowed(address(this), redeemer, redeemTokensIn);
        require(allowed, reason);

        /*
         * We calculate the new total supply and redeemer balance, checking for underflow:
         *  totalSupplyNew = totalSupply - redeemTokens
         *  accountTokensNew = accountTokens[redeemer] - redeemTokens
         */
        vars.totalSupplyNew = totalSupply.sub(redeemTokensIn, REDEEM_NEW_TOTAL_SUPPLY_CALCULATION_FAILED);

        vars.accountTokensNew = accountTokens[redeemer].sub(redeemTokensIn, REDEEM_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED);

        /* Fail gracefully if protocol has insufficient cash */
        require(getCashPrior() >= redeemTokensIn, TOKEN_INSUFFICIENT_CASH);

        /////////////////////////
        // EFFECTS & INTERACTIONS

        /* We write previously calculated values into storage */
        totalSupply = vars.totalSupplyNew;
        accountTokens[redeemer] = vars.accountTokensNew;
        /*
         * We invoke doTransferOut for the redeemer and the redeemAmount.
         *  Note: The kToken must handle variations between ERC-20 and ETH underlying.
         *  On success, the kToken has redeemAmount less of cash.
         *  doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
         */
        doTransferOut(redeemer, redeemTokensIn);

        /* We emit a Transfer event, and a Redeem event */
        emit Transfer(redeemer, address(this), redeemTokensIn);
        emit Redeem(redeemer, redeemTokensIn);

        /* We call the defense hook */
        controller.redeemVerify(address(this), redeemer, redeemTokensIn);
    }

    /**
     * @notice Transfers collateral tokens (this market) to the liquidator.
     * @dev Will fail unless called by another kToken during the process of liquidation.
     *  Its absolutely critical to use msg.sender as the borrowed kToken and not a parameter.
     * @param liquidator The account receiving seized collateral
     * @param borrower The account having collateral seized
     * @param seizeTokens The number of kTokens to seize
     */
    function seize(address liquidator, address borrower, uint seizeTokens) external nonReentrant {
        seizeInternal(msg.sender, liquidator, borrower, seizeTokens);
    }

    /**
     * @notice Transfers collateral tokens (this market) to the liquidator.
     * @dev Called only during an in-kind liquidation, or by liquidateBorrow during the liquidation of another KToken.
     *  Its absolutely critical to use msg.sender as the seizer kToken and not a parameter.
     * @param seizerToken The contract seizing the collateral (i.e. borrowed kToken)
     * @param liquidator The account receiving seized collateral
     * @param borrower The account having collateral seized
     * @param seizeTokens The number of kTokens to seize
     */
    function seizeInternal(address seizerToken, address liquidator, address borrower, uint seizeTokens) internal {
        /* Fail if seize not allowed */
        (bool allowed, string memory reason) = controller.seizeAllowed(address(this), seizerToken, liquidator, borrower, seizeTokens);
        require(allowed, reason);

        /* Fail if borrower = liquidator */
        require(borrower != liquidator, INVALID_ACCOUNT_PAIR);

        /*
         * We calculate the new borrower and liquidator token balances, failing on underflow/overflow:
         *  borrowerTokensNew = accountTokens[borrower] - seizeTokens
         *  liquidatorTokensNew = accountTokens[liquidator] + seizeTokens
         */
        uint borrowerTokensNew = accountTokens[borrower].sub(seizeTokens, LIQUIDATE_SEIZE_BALANCE_DECREMENT_FAILED);

        uint liquidatorTokensNew = accountTokens[liquidator].add(seizeTokens, LIQUIDATE_SEIZE_BALANCE_INCREMENT_FAILED);

        /////////////////////////
        // EFFECTS & INTERACTIONS

        /* We write the previously calculated values into storage */
        accountTokens[borrower] = borrowerTokensNew;
        accountTokens[liquidator] = liquidatorTokensNew;

        /* Emit a Transfer event */
        emit Transfer(borrower, liquidator, seizeTokens);

        /* We call the defense hook */
        controller.seizeVerify(address(this), seizerToken, liquidator, borrower, seizeTokens);
    }


    /*** Admin Functions ***/

    /**
      * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @param newPendingAdmin New pending admin.
      */
    function _setPendingAdmin(address payable newPendingAdmin) external onlyAdmin() {
        address oldPendingAdmin = pendingAdmin;
        pendingAdmin = newPendingAdmin;
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    /**
      * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
      * @dev Admin function for pending admin to accept role and update admin
      */
    function _acceptAdmin() external {
        // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
        require(msg.sender == pendingAdmin && msg.sender != address(0), "unauthorized");

        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }

    /**
      * @notice Sets a new controller for the market
      * @dev Admin function to set a new controller
      */
    function _setController(KineControllerInterface newController) public onlyAdmin() {
        KineControllerInterface oldController = controller;
        // Ensure invoke controller.isController() returns true
        require(newController.isController(), "marker method returned false");

        // Set market's controller to newController
        controller = newController;

        // Emit NewController(oldController, newController)
        emit NewController(oldController, newController);
    }

    /**
     * @notice Gets balance of this contract in terms of the underlying
     * @dev This excludes the value of the current message, if any
     * @return The quantity of underlying owned by this contract
     */
    function getCashPrior() internal view returns (uint);

    /**
     * @dev Performs a transfer in, reverting upon failure. Returns the amount actually transferred to the protocol, in case of a fee.
     *  This may revert due to insufficient balance or insufficient allowance.
     */
    function doTransferIn(address from, uint amount) internal returns (uint);

    /**
     * @dev Performs a transfer out, ideally returning an explanatory error code upon failure tather than reverting.
     *  If caller has not called checked protocol's balance, may revert due to insufficient cash held in the contract.
     *  If caller has checked protocol's balance, and verified it is >= amount, this should not revert in normal conditions.
     */
    function doTransferOut(address payable to, uint amount) internal;


    /*** Reentrancy Guard ***/

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     */
    modifier nonReentrant() {
        require(_notEntered, "re-entered");
        _notEntered = false;
        _;
        _notEntered = true;
        // get a gas-refund post-Istanbul
    }
}

pragma solidity ^0.5.16;

import "./KineControllerInterface.sol";

contract KTokenStorage {
    /**
     * @dev Guard variable for re-entrancy checks
     */
    bool internal _notEntered;

    /**
    * @notice flag that kToken has been initialized;
    */
    bool public initialized;

    /**
     * @notice EIP-20 token name for this token
     */
    string public name;

    /**
     * @notice EIP-20 token symbol for this token
     */
    string public symbol;

    /**
     * @notice EIP-20 token decimals for this token
     */
    uint8 public decimals;

    /**
     * @notice Administrator for this contract
     */
    address payable public admin;

    /**
     * @notice Pending administrator for this contract
     */
    address payable public pendingAdmin;

    /**
     * @notice Contract which oversees inter-kToken operations
     */
    KineControllerInterface public controller;

    /**
     * @notice Total number of tokens in circulation
     */
    uint public totalSupply;

    /**
     * @notice Official record of token balances for each account
     */
    mapping (address => uint) internal accountTokens;

    /**
     * @notice Approved token transfer amounts on behalf of others
     */
    mapping (address => mapping (address => uint)) internal transferAllowances;

}

contract KTokenInterface is KTokenStorage {
    /**
     * @notice Indicator that this is a KToken contract (for inspection)
     */
    bool public constant isKToken = true;


    /*** Market Events ***/

    /**
     * @notice Event emitted when tokens are minted
     */
    event Mint(address minter, uint mintAmount, uint mintTokens);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint redeemTokens);


    /*** Admin Events ***/

    /**
     * @notice Event emitted when pendingAdmin is changed
     */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     * @notice Event emitted when pendingAdmin is accepted, which means admin is updated
     */
    event NewAdmin(address oldAdmin, address newAdmin);

    /**
     * @notice Event emitted when controller is changed
     */
    event NewController(KineControllerInterface oldController, KineControllerInterface newController);

    /**
     * @notice EIP20 Transfer event
     */
    event Transfer(address indexed from, address indexed to, uint amount);

    /**
     * @notice EIP20 Approval event
     */
    event Approval(address indexed owner, address indexed spender, uint amount);


    /*** User Interface ***/

    function transfer(address dst, uint amount) external returns (bool);
    function transferFrom(address src, address dst, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function getAccountSnapshot(address account) external view returns (uint, uint);
    function getCash() external view returns (uint);
    function seize(address liquidator, address borrower, uint seizeTokens) external;


    /*** Admin Functions ***/

    function _setPendingAdmin(address payable newPendingAdmin) external;
    function _acceptAdmin() external;
    function _setController(KineControllerInterface newController) public;
}

contract KErc20Storage {
    /**
     * @notice Underlying asset for this KToken
     */
    address public underlying;
}

contract KErc20Interface is KErc20Storage {

    /*** User Interface ***/

    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external;

}

contract KDelegationStorage {
    /**
     * @notice Implementation address for this contract
     */
    address public implementation;
}

contract KDelegatorInterface is KDelegationStorage {
    /**
     * @notice Emitted when implementation is changed
     */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
     * @notice Called by the admin to update the implementation of the delegator
     * @param implementation_ The address of the new implementation for delegation
     * @param allowResign Flag to indicate whether to call _resignImplementation on the old implementation
     * @param becomeImplementationData The encoded bytes data to be passed to _becomeImplementation
     */
    function _setImplementation(address implementation_, bool allowResign, bytes memory becomeImplementationData) public;
}

contract KDelegateInterface is KDelegationStorage {
    /**
     * @notice Called by the delegator on a delegate to initialize it for duty
     * @dev Should revert if any issues arise which make it unfit for delegation
     * @param data The encoded bytes data for any initialization
     */
    function _becomeImplementation(bytes memory data) public;

    /**
     * @notice Called by the delegator on a delegate to forfeit its responsibility
     */
    function _resignImplementation() public;
}

pragma solidity ^0.5.16;

/**
Copyright 2020 Compound Labs, Inc.
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
* Original work from Compound: https://github.com/compound-finance/compound-protocol/blob/master/contracts/ComptrollerInterface.sol
* Modified to work in the Kine system.
* Main modifications:
*   1. removed Comp token related logics.
*   2. removed interest rate model related logics.
*   3. removed error code propagation mechanism to fail fast and loudly
*/

contract KineControllerInterface {
    /// @notice Indicator that this is a Controller contract (for inspection)
    bool public constant isController = true;

    /// @notice oracle getter function
    function getOracle() external view returns (address);

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata kTokens) external;

    function exitMarket(address kToken) external;

    /*** Policy Hooks ***/

    function mintAllowed(address kToken, address minter, uint mintAmount) external returns (bool, string memory);

    function mintVerify(address kToken, address minter, uint mintAmount, uint mintTokens) external;

    function redeemAllowed(address kToken, address redeemer, uint redeemTokens) external returns (bool, string memory);

    function redeemVerify(address kToken, address redeemer, uint redeemTokens) external;

    function borrowAllowed(address kToken, address borrower, uint borrowAmount) external returns (bool, string memory);

    function borrowVerify(address kToken, address borrower, uint borrowAmount) external;

    function repayBorrowAllowed(
        address kToken,
        address payer,
        address borrower,
        uint repayAmount) external returns (bool, string memory);

    function repayBorrowVerify(
        address kToken,
        address payer,
        address borrower,
        uint repayAmount) external;

    function liquidateBorrowAllowed(
        address kTokenBorrowed,
        address kTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) external returns (bool, string memory);

    function liquidateBorrowVerify(
        address kTokenBorrowed,
        address kTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount,
        uint seizeTokens) external;

    function seizeAllowed(
        address kTokenCollateral,
        address kTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external returns (bool, string memory);

    function seizeVerify(
        address kTokenCollateral,
        address kTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external;

    function transferAllowed(address kToken, address src, address dst, uint transferTokens) external returns (bool, string memory);

    function transferVerify(address kToken, address src, address dst, uint transferTokens) external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address kTokenBorrowed,
        address kTokenCollateral,
        uint repayAmount) external view returns (uint);
}

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

/**
 * @title KineOracleInterface brief abstraction of Price Oracle
 */
interface KineOracleInterface {

    /**
     * @notice Get the underlying collateral price of given kToken.
     * @dev Returned kToken underlying price is scaled by 1e(36 - underlying token decimals)
     */
    function getUnderlyingPrice(address kToken) external view returns (uint);

    /**
     * @notice Post prices of tokens owned by Kine.
     * @param messages Signed price data of tokens
     * @param signatures Signatures used to recover reporter public key
     * @param symbols Token symbols
     */
    function postPrices(bytes[] calldata messages, bytes[] calldata signatures, string[] calldata symbols) external;

    /**
     * @notice Post Kine MCD price.
     */
    function postMcdPrice(uint mcdPrice) external;

    /**
     * @notice Get the reporter address.
     */
    function reporter() external returns (address);
}

pragma solidity ^0.5.0;

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

/**
 * Original work from OpenZeppelin: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/math/SafeMath.sol
 * changes we made:
 * 1. add two methods that take errorMessage as input parameter
 */

library KineSafeMath {
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
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     * added by Kine
     */
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

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
        return sub(a, b, "SafeMath: subtraction overflow");
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
        require(c / a == b, "SafeMath: multiplication overflow");

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
     * added by Kine
     */
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

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
        return div(a, b, "SafeMath: division by zero");
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
        return mod(a, b, "SafeMath: modulo by zero");
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

pragma solidity ^0.5.16;

import "./ErrorReporter.sol";
import "./ControllerStorage.sol";

/**
Copyright 2020 Compound Labs, Inc.
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @title ControllerCore
 * @dev Storage for the controller is at this address, while execution is delegated to the `controllerImplementation`.
 * KTokens should reference this contract as their controller.
 */
contract Unitroller is UnitrollerAdminStorage {

    /**
      * @notice Emitted when pendingControllerImplementation is changed
      */
    event NewPendingImplementation(address oldPendingImplementation, address newPendingImplementation);

    /**
      * @notice Emitted when pendingControllerImplementation is accepted, which means controller implementation is updated
      */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
      * @notice Emitted when pendingAdmin is changed
      */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
      * @notice Emitted when pendingAdmin is accepted, which means admin is updated
      */
    event NewAdmin(address oldAdmin, address newAdmin);

    constructor() public {
        // Set admin to caller
        admin = msg.sender;
    }

    /*** Admin Functions ***/
    function _setPendingImplementation(address newPendingImplementation) public {
        require(msg.sender == admin, "unauthorized");

        address oldPendingImplementation = pendingControllerImplementation;

        pendingControllerImplementation = newPendingImplementation;

        emit NewPendingImplementation(oldPendingImplementation, pendingControllerImplementation);
    }

    /**
    * @notice Accepts new implementation of controller. msg.sender must be pendingImplementation
    * @dev Admin function for new implementation to accept it's role as implementation
    */
    function _acceptImplementation() public {
        // Check caller is pendingImplementation and pendingImplementation ≠ address(0)
        require(pendingControllerImplementation != address(0) && msg.sender == pendingControllerImplementation, "unauthorized");

        // Save current values for inclusion in log
        address oldImplementation = controllerImplementation;
        address oldPendingImplementation = pendingControllerImplementation;

        controllerImplementation = pendingControllerImplementation;

        pendingControllerImplementation = address(0);

        emit NewImplementation(oldImplementation, controllerImplementation);
        emit NewPendingImplementation(oldPendingImplementation, pendingControllerImplementation);
    }


    /**
      * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @param newPendingAdmin New pending admin.
      */
    function _setPendingAdmin(address newPendingAdmin) public {
        require(msg.sender == admin, "unauthorized");

        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    /**
      * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
      * @dev Admin function for pending admin to accept role and update admin
      */
    function _acceptAdmin() public {
        require(msg.sender == pendingAdmin && msg.sender != address(0), "unauthorized");

        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }

    /**
     * @dev Delegates execution to an implementation contract.
     * It returns to the external caller whatever the implementation returns
     * or forwards reverts.
     */
    function () payable external {
        // delegate all other functions to current implementation
        (bool success, ) = controllerImplementation.delegatecall(msg.data);

        assembly {
              let free_mem_ptr := mload(0x40)
              returndatacopy(free_mem_ptr, 0, returndatasize)

              switch success
              case 0 { revert(free_mem_ptr, returndatasize) }
              default { return(free_mem_ptr, returndatasize) }
        }
    }
}