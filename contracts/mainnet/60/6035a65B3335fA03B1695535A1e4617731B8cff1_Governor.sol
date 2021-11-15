pragma solidity ^0.7.6;

/**
  * @title Careful Math
  * @author DeFiPie
  * @notice Derived from OpenZeppelin's SafeMath library
  *         https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol
  */
contract CarefulMath {

    /**
     * @dev Possible error codes that we can return
     */
    enum MathError {
        NO_ERROR,
        DIVISION_BY_ZERO,
        INTEGER_OVERFLOW,
        INTEGER_UNDERFLOW
    }

    /**
    * @dev Multiplies two numbers, returns an error on overflow.
    */
    function mulUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (a == 0) {
            return (MathError.NO_ERROR, 0);
        }

        uint c = a * b;

        if (c / a != b) {
            return (MathError.INTEGER_OVERFLOW, 0);
        } else {
            return (MathError.NO_ERROR, c);
        }
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function divUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (b == 0) {
            return (MathError.DIVISION_BY_ZERO, 0);
        }

        return (MathError.NO_ERROR, a / b);
    }

    /**
    * @dev Subtracts two numbers, returns an error on overflow (i.e. if subtrahend is greater than minuend).
    */
    function subUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (b <= a) {
            return (MathError.NO_ERROR, a - b);
        } else {
            return (MathError.INTEGER_UNDERFLOW, 0);
        }
    }

    /**
    * @dev Adds two numbers, returns an error on overflow.
    */
    function addUInt(uint a, uint b) internal pure returns (MathError, uint) {
        uint c = a + b;

        if (c >= a) {
            return (MathError.NO_ERROR, c);
        } else {
            return (MathError.INTEGER_OVERFLOW, 0);
        }
    }

    /**
    * @dev add a and b and then subtract c
    */
    function addThenSubUInt(uint a, uint b, uint c) internal pure returns (MathError, uint) {
        (MathError err0, uint sum) = addUInt(a, b);

        if (err0 != MathError.NO_ERROR) {
            return (err0, 0);
        }

        return subUInt(sum, c);
    }
}

pragma solidity ^0.7.6;

import "./ErrorReporter.sol";
import "./Exponential.sol";
import "./PriceOracle.sol";
import "./ControllerInterface.sol";
import "./ControllerStorage.sol";
import "./PTokenInterfaces.sol";
import "./EIP20Interface.sol";
import "./Unitroller.sol";

/**
 * @title DeFiPie's Controller Contract
 * @author DeFiPie
 */
contract Controller is ControllerStorage, ControllerInterface, ControllerErrorReporter, Exponential {
    /// @notice Emitted when an admin supports a market
    event MarketListed(address pToken);

    /// @notice Emitted when an account enters a market
    event MarketEntered(address pToken, address account);

    /// @notice Emitted when an account exits a market
    event MarketExited(address pToken, address account);

    /// @notice Emitted when close factor is changed by admin
    event NewCloseFactor(uint oldCloseFactorMantissa, uint newCloseFactorMantissa);

    /// @notice Emitted when a collateral factor is changed by admin
    event NewCollateralFactor(address pToken, uint oldCollateralFactorMantissa, uint newCollateralFactorMantissa);

    /// @notice Emitted when liquidation incentive is changed by admin
    event NewLiquidationIncentive(uint oldLiquidationIncentiveMantissa, uint newLiquidationIncentiveMantissa);

    /// @notice Emitted when maxAssets is changed by admin
    event NewMaxAssets(uint oldMaxAssets, uint newMaxAssets);

    /// @notice Emitted when price oracle is changed
    event NewPriceOracle(PriceOracle oldPriceOracle, PriceOracle newPriceOracle);

    /// @notice Emitted when pause guardian is changed
    event NewPauseGuardian(address oldPauseGuardian, address newPauseGuardian);

    /// @notice Emitted when an action is paused globally
    event ActionPaused(string action, bool pauseState);

    /// @notice Emitted when an action is paused on a market
    event ActionPaused(address pToken, string action, bool pauseState);

    /// @notice Emitted when a new PIE speed is calculated for a market
    event PieSpeedUpdated(address indexed pToken, uint newSpeed);

    /// @notice Emitted when PIE is distributed to a supplier
    event DistributedSupplierPie(address indexed pToken, address indexed supplier, uint pieDelta, uint pieSupplyIndex);

    /// @notice Emitted when PIE is distributed to a borrower
    event DistributedBorrowerPie(address indexed pToken, address indexed borrower, uint pieDelta, uint pieBorrowIndex);

    /// @notice The threshold above which the flywheel transfers PIE, in wei
    uint public constant pieClaimThreshold = 0.001e18;

    /// @notice The initial PIE index for a market
    uint224 public constant pieInitialIndex = 1e36;

    // closeFactorMantissa must be strictly greater than this value
    uint internal constant closeFactorMinMantissa = 0.05e18; // 0.05

    // closeFactorMantissa must not exceed this value
    uint internal constant closeFactorMaxMantissa = 0.9e18; // 0.9

    // No collateralFactorMantissa may exceed this value
    uint internal constant collateralFactorMaxMantissa = 0.9e18; // 0.9

    // liquidationIncentiveMantissa must be no less than this value
    uint internal constant liquidationIncentiveMinMantissa = 1.0e18; // 1.0

    // liquidationIncentiveMantissa must be no greater than this value
    uint internal constant liquidationIncentiveMaxMantissa = 1.5e18; // 1.5

    constructor() {
        admin = msg.sender;
    }

    /*** Assets You Are In ***/

    /**
     * @notice Returns the assets an account has entered
     * @param account The address of the account to pull assets for
     * @return A dynamic list with the assets the account has entered
     */
    function getAssetsIn(address account) external view returns (address[] memory) {
        address[] memory assetsIn = accountAssets[account];

        return assetsIn;
    }

    /**
     * @notice Returns whether the given account is entered in the given asset
     * @param account The address of the account to check
     * @param pToken The pToken to check
     * @return True if the account is in the asset, otherwise false.
     */
    function checkMembership(address account, address pToken) external view returns (bool) {
        return markets[pToken].accountMembership[account];
    }

    /**
     * @notice Add assets to be included in account liquidity calculation
     * @param pTokens The list of addresses of the pToken markets to be enabled
     * @return Success indicator for whether each corresponding market was entered
     */
    function enterMarkets(address[] memory pTokens) public override returns (uint[] memory) {
        uint len = pTokens.length;

        uint[] memory results = new uint[](len);
        for (uint i = 0; i < len; i++) {
            address pToken = pTokens[i];

            results[i] = uint(addToMarketInternal(pToken, msg.sender));
        }

        return results;
    }

    /**
     * @notice Add the market to the borrower's "assets in" for liquidity calculations
     * @param pToken The market to enter
     * @param borrower The address of the account to modify
     * @return Success indicator for whether the market was entered
     */
    function addToMarketInternal(address pToken, address borrower) internal returns (Error) {
        Market storage marketToJoin = markets[pToken];

        if (!marketToJoin.isListed) {
            // market is not listed, cannot join
            return Error.MARKET_NOT_LISTED;
        }

        if (marketToJoin.accountMembership[borrower] == true) {
            // already joined
            return Error.NO_ERROR;
        }

        if (accountAssets[borrower].length >= maxAssets)  {
            // no space, cannot join
            return Error.TOO_MANY_ASSETS;
        }

        // survived the gauntlet, add to list
        // NOTE: we store these somewhat redundantly as a significant optimization
        //  this avoids having to iterate through the list for the most common use cases
        //  that is, only when we need to perform liquidity checks
        //  and not whenever we want to check if an account is in a particular market
        marketToJoin.accountMembership[borrower] = true;
        accountAssets[borrower].push(pToken);

        emit MarketEntered(pToken, borrower);

        return Error.NO_ERROR;
    }

    /**
     * @notice Removes asset from sender's account liquidity calculation
     * @dev Sender must not have an outstanding borrow balance in the asset,
     *  or be providing neccessary collateral for an outstanding borrow.
     * @param pTokenAddress The address of the asset to be removed
     * @return Whether or not the account successfully exited the market
     */
    function exitMarket(address pTokenAddress) external override returns (uint) {
        address pToken = pTokenAddress;
        /* Get sender tokensHeld and amountOwed underlying from the pToken */
        (uint oErr, uint tokensHeld, uint amountOwed, ) = PTokenInterface(pToken).getAccountSnapshot(msg.sender);
        require(oErr == 0, "exitMarket: getAccountSnapshot failed"); // semi-opaque error code

        /* Fail if the sender has a borrow balance */
        if (amountOwed != 0) {
            return fail(Error.NONZERO_BORROW_BALANCE, FailureInfo.EXIT_MARKET_BALANCE_OWED);
        }

        /* Fail if the sender is not permitted to redeem all of their tokens */
        uint allowed = redeemAllowedInternal(pTokenAddress, msg.sender, tokensHeld);
        if (allowed != 0) {
            return failOpaque(Error.REJECTION, FailureInfo.EXIT_MARKET_REJECTION, allowed);
        }

        Market storage marketToExit = markets[pToken];

        /* Return true if the sender is not already ‘in’ the market */
        if (!marketToExit.accountMembership[msg.sender]) {
            return uint(Error.NO_ERROR);
        }

        /* Set pToken account membership to false */
        delete marketToExit.accountMembership[msg.sender];

        /* Delete pToken from the account’s list of assets */
        // load into memory for faster iteration
        address[] memory userAssetList = accountAssets[msg.sender];
        uint len = userAssetList.length;
        uint assetIndex = len;
        for (uint i = 0; i < len; i++) {
            if (userAssetList[i] == pToken) {
                assetIndex = i;
                break;
            }
        }

        // We *must* have found the asset in the list or our redundant data structure is broken
        assert(assetIndex < len);

        // copy last item in list to location of item to be removed, reduce length by 1
        address[] storage storedList = accountAssets[msg.sender];
        storedList[assetIndex] = storedList[storedList.length - 1];
        storedList.pop(); //storedList.length--;

        emit MarketExited(pToken, msg.sender);

        return uint(Error.NO_ERROR);
    }

    /*** Policy Hooks ***/

    /**
     * @notice Checks if the account should be allowed to mint tokens in the given market
     * @param pToken The market to verify the mint against
     * @param minter The account which would get the minted tokens
     * @param mintAmount The amount of underlying being supplied to the market in exchange for tokens
     * @return 0 if the mint is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function mintAllowed(address pToken, address minter, uint mintAmount) external override returns (uint) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!mintGuardianPaused[pToken], "mint is paused");

        // Shh - currently unused
        minter;
        mintAmount;

        if (!markets[pToken].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        // Keep the flywheel moving
        updatePieSupplyIndex(pToken);
        distributeSupplierPie(pToken, minter, false);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Checks if the account should be allowed to redeem tokens in the given market
     * @param pToken The market to verify the redeem against
     * @param redeemer The account which would redeem the tokens
     * @param redeemTokens The number of pTokens to exchange for the underlying asset in the market
     * @return 0 if the redeem is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function redeemAllowed(address pToken, address redeemer, uint redeemTokens) external override returns (uint) {
        uint allowed = redeemAllowedInternal(pToken, redeemer, redeemTokens);
        if (allowed != uint(Error.NO_ERROR)) {
            return allowed;
        }

        // Keep the flywheel moving
        updatePieSupplyIndex(pToken);
        distributeSupplierPie(pToken, redeemer, false);

        return uint(Error.NO_ERROR);
    }

    function redeemAllowedInternal(address pToken, address redeemer, uint redeemTokens) internal view returns (uint) {
        if (!markets[pToken].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        /* If the redeemer is not 'in' the market, then we can bypass the liquidity check */
        if (!markets[pToken].accountMembership[redeemer]) {
            return uint(Error.NO_ERROR);
        }

        /* Otherwise, perform a hypothetical liquidity check to guard against shortfall */
        (Error err, , uint shortfall) = getHypotheticalAccountLiquidityInternal(redeemer, pToken, redeemTokens, 0);
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
     * @param pToken Asset being redeemed
     * @param redeemer The address redeeming the tokens
     * @param redeemAmount The amount of the underlying asset being redeemed
     * @param redeemTokens The number of tokens being redeemed
     */
    function redeemVerify(address pToken, address redeemer, uint redeemAmount, uint redeemTokens) external override {
        // Shh - currently unused
        pToken;
        redeemer;

        // Require tokens is zero or amount is also zero
        if (redeemTokens == 0 && redeemAmount > 0) {
            revert("redeemTokens zero");
        }
    }

    /**
     * @notice Checks if the account should be allowed to borrow the underlying asset of the given market
     * @param pToken The market to verify the borrow against
     * @param borrower The account which would borrow the asset
     * @param borrowAmount The amount of underlying the account would borrow
     * @return 0 if the borrow is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function borrowAllowed(address pToken, address borrower, uint borrowAmount) external override returns (uint) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!borrowGuardianPaused[pToken], "borrow is paused");

        if (!markets[pToken].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        Error err;

        if (!markets[pToken].accountMembership[borrower]) {
            // only pTokens may call borrowAllowed if borrower not in market
            require(msg.sender == pToken, "sender must be pToken");

            // attempt to add borrower to the market
            err = addToMarketInternal(msg.sender, borrower);
            if (err != Error.NO_ERROR) {
                return uint(err);
            }

            // it should be impossible to break the important invariant
            assert(markets[pToken].accountMembership[borrower]);
        }

        if (oracle.getUnderlyingPrice(pToken) == 0) {
            return uint(Error.PRICE_ERROR);
        }

        uint shortfall;

        (err, , shortfall) = getHypotheticalAccountLiquidityInternal(borrower, pToken, 0, borrowAmount);
        if (err != Error.NO_ERROR) {
            return uint(err);
        }
        if (shortfall > 0) {
            return uint(Error.INSUFFICIENT_LIQUIDITY);
        }

        // Keep the flywheel moving
        Exp memory borrowIndex = Exp({mantissa: PTokenInterface(pToken).borrowIndex()});
        updatePieBorrowIndex(pToken, borrowIndex);
        distributeBorrowerPie(pToken, borrower, borrowIndex, false);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Checks if the account should be allowed to repay a borrow in the given market
     * @param pToken The market to verify the repay against
     * @param payer The account which would repay the asset
     * @param borrower The account which would borrowed the asset
     * @param repayAmount The amount of the underlying asset the account would repay
     * @return 0 if the repay is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function repayBorrowAllowed(
        address pToken,
        address payer,
        address borrower,
        uint repayAmount
    ) external override returns (uint) {
        // Shh - currently unused
        payer;
        borrower;
        repayAmount;

        if (!markets[pToken].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        // Keep the flywheel moving
        Exp memory borrowIndex = Exp({mantissa: PTokenInterface(pToken).borrowIndex()});
        updatePieBorrowIndex(pToken, borrowIndex);
        distributeBorrowerPie(pToken, borrower, borrowIndex, false);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Checks if the liquidation should be allowed to occur
     * @param pTokenBorrowed Asset which was borrowed by the borrower
     * @param pTokenCollateral Asset which was used as collateral and will be seized
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param repayAmount The amount of underlying being repaid
     */
    function liquidateBorrowAllowed(
        address pTokenBorrowed,
        address pTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount
    ) external override returns (uint) {
        // Shh - currently unused
        liquidator;

        if (!markets[pTokenBorrowed].isListed || !markets[pTokenCollateral].isListed) {
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
        uint borrowBalance = PTokenInterface(pTokenBorrowed).borrowBalanceStored(borrower);
        (MathError mathErr, uint maxClose) = mulScalarTruncate(Exp({mantissa: closeFactorMantissa}), borrowBalance);
        if (mathErr != MathError.NO_ERROR) {
            return uint(Error.MATH_ERROR);
        }
        if (repayAmount > maxClose) {
            return uint(Error.TOO_MUCH_REPAY);
        }

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Checks if the seizing of assets should be allowed to occur
     * @param pTokenCollateral Asset which was used as collateral and will be seized
     * @param pTokenBorrowed Asset which was borrowed by the borrower
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param seizeTokens The number of collateral tokens to seize
     */
    function seizeAllowed(
        address pTokenCollateral,
        address pTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens
    ) external override returns (uint) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!seizeGuardianPaused, "seize is paused");

        // Shh - currently unused
        seizeTokens;

        if (!markets[pTokenCollateral].isListed || !markets[pTokenBorrowed].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        if (PTokenInterface(pTokenCollateral).controller() != PTokenInterface(pTokenBorrowed).controller()) {
            return uint(Error.CONTROLLER_MISMATCH);
        }

        // Keep the flywheel moving
        updatePieSupplyIndex(pTokenCollateral);
        distributeSupplierPie(pTokenCollateral, borrower, false);
        distributeSupplierPie(pTokenCollateral, liquidator, false);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Checks if the account should be allowed to transfer tokens in the given market
     * @param pToken The market to verify the transfer against
     * @param src The account which sources the tokens
     * @param dst The account which receives the tokens
     * @param transferTokens The number of pTokens to transfer
     * @return 0 if the transfer is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function transferAllowed(
        address pToken,
        address src,
        address dst,
        uint transferTokens
    ) external override returns (uint) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!transferGuardianPaused, "transfer is paused");

        // Currently the only consideration is whether or not
        //  the src is allowed to redeem this many tokens
        uint allowed = redeemAllowedInternal(pToken, src, transferTokens);
        if (allowed != uint(Error.NO_ERROR)) {
            return allowed;
        }

        // Keep the flywheel moving
        updatePieSupplyIndex(pToken);
        distributeSupplierPie(pToken, src, false);
        distributeSupplierPie(pToken, dst, false);

        return uint(Error.NO_ERROR);
    }

    /*** Liquidity/Liquidation Calculations ***/

    /**
     * @dev Local vars for avoiding stack-depth limits in calculating account liquidity.
     *  Note that `pTokenBalance` is the number of pTokens the account owns in the market,
     *  whereas `borrowBalance` is the amount of underlying that the account has borrowed.
     */
    struct AccountLiquidityLocalVars {
        uint sumCollateral;
        uint sumBorrowPlusEffects;
        uint pTokenBalance;
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
        (Error err, uint liquidity, uint shortfall) = getHypotheticalAccountLiquidityInternal(account, address(0), 0, 0);

        return (uint(err), liquidity, shortfall);
    }

    /**
     * @notice Determine the current account liquidity wrt collateral requirements
     * @return (possible error code,
                account liquidity in excess of collateral requirements,
     *          account shortfall below collateral requirements)
     */
    function getAccountLiquidityInternal(address account) internal view returns (Error, uint, uint) {
        return getHypotheticalAccountLiquidityInternal(account, address(0), 0, 0);
    }

    /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @param pTokenModify The market to hypothetically redeem/borrow in
     * @param account The account to determine liquidity for
     * @param redeemTokens The number of tokens to hypothetically redeem
     * @param borrowAmount The amount of underlying to hypothetically borrow
     * @return (possible error code (semi-opaque),
                hypothetical account liquidity in excess of collateral requirements,
     *          hypothetical account shortfall below collateral requirements)
     */
    function getHypotheticalAccountLiquidity(
        address account,
        address pTokenModify,
        uint redeemTokens,
        uint borrowAmount
    ) public view virtual returns (uint, uint, uint) {
        (Error err, uint liquidity, uint shortfall) = getHypotheticalAccountLiquidityInternal(account, pTokenModify, redeemTokens, borrowAmount);
        return (uint(err), liquidity, shortfall);
    }

    /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @param pTokenModify The market to hypothetically redeem/borrow in
     * @param account The account to determine liquidity for
     * @param redeemTokens The number of tokens to hypothetically redeem
     * @param borrowAmount The amount of underlying to hypothetically borrow
     * @dev Note that we calculate the exchangeRateStored for each collateral pToken using stored data,
     *  without calculating accumulated interest.
     * @return (possible error code,
                hypothetical account liquidity in excess of collateral requirements,
     *          hypothetical account shortfall below collateral requirements)
     */
    function getHypotheticalAccountLiquidityInternal(
        address account,
        address pTokenModify,
        uint redeemTokens,
        uint borrowAmount
    ) internal view returns (Error, uint, uint) {

        AccountLiquidityLocalVars memory vars; // Holds all our calculation results
        uint oErr;
        MathError mErr;

        // For each asset the account is in
        address[] memory assets = accountAssets[account];
        for (uint i = 0; i < assets.length; i++) {
            address asset = assets[i];

            // Read the balances and exchange rate from the pToken
            (oErr, vars.pTokenBalance, vars.borrowBalance, vars.exchangeRateMantissa) = PTokenInterface(asset).getAccountSnapshot(account);
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
            (mErr, vars.tokensToDenom) = mulExp3(vars.collateralFactor, vars.exchangeRate, vars.oraclePrice);
            if (mErr != MathError.NO_ERROR) {
                return (Error.MATH_ERROR, 0, 0);
            }

            // sumCollateral += tokensToDenom * pTokenBalance
            (mErr, vars.sumCollateral) = mulScalarTruncateAddUInt(vars.tokensToDenom, vars.pTokenBalance, vars.sumCollateral);
            if (mErr != MathError.NO_ERROR) {
                return (Error.MATH_ERROR, 0, 0);
            }

            // sumBorrowPlusEffects += oraclePrice * borrowBalance
            (mErr, vars.sumBorrowPlusEffects) = mulScalarTruncateAddUInt(vars.oraclePrice, vars.borrowBalance, vars.sumBorrowPlusEffects);
            if (mErr != MathError.NO_ERROR) {
                return (Error.MATH_ERROR, 0, 0);
            }

            // Calculate effects of interacting with pTokenModify
            if (asset == pTokenModify) {
                // redeem effect
                // sumBorrowPlusEffects += tokensToDenom * redeemTokens
                (mErr, vars.sumBorrowPlusEffects) = mulScalarTruncateAddUInt(vars.tokensToDenom, redeemTokens, vars.sumBorrowPlusEffects);
                if (mErr != MathError.NO_ERROR) {
                    return (Error.MATH_ERROR, 0, 0);
                }

                // borrow effect
                // sumBorrowPlusEffects += oraclePrice * borrowAmount
                (mErr, vars.sumBorrowPlusEffects) = mulScalarTruncateAddUInt(vars.oraclePrice, borrowAmount, vars.sumBorrowPlusEffects);
                if (mErr != MathError.NO_ERROR) {
                    return (Error.MATH_ERROR, 0, 0);
                }
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
     * @dev Used in liquidation (called in pToken.liquidateBorrowFresh)
     * @param pTokenBorrowed The address of the borrowed pToken
     * @param pTokenCollateral The address of the collateral pToken
     * @param actualRepayAmount The amount of pTokenBorrowed underlying to convert into pTokenCollateral tokens
     * @return (errorCode, number of pTokenCollateral tokens to be seized in a liquidation)
     */
    function liquidateCalculateSeizeTokens(
        address pTokenBorrowed,
        address pTokenCollateral,
        uint actualRepayAmount
    ) external view override returns (uint, uint) {
        /* Read oracle prices for borrowed and collateral markets */
        uint priceBorrowedMantissa = oracle.getUnderlyingPrice(pTokenBorrowed);
        uint priceCollateralMantissa = oracle.getUnderlyingPrice(pTokenCollateral);
        if (priceBorrowedMantissa == 0 || priceCollateralMantissa == 0) {
            return (uint(Error.PRICE_ERROR), 0);
        }

        /*
         * Get the exchange rate and calculate the number of collateral tokens to seize:
         *  seizeAmount = actualRepayAmount * liquidationIncentive * priceBorrowed / priceCollateral
         *  seizeTokens = seizeAmount / exchangeRate
         *   = actualRepayAmount * (liquidationIncentive * priceBorrowed) / (priceCollateral * exchangeRate)
         */
        uint exchangeRateMantissa = PTokenInterface(pTokenCollateral).exchangeRateStored(); // Note: reverts on error
        uint seizeTokens;
        Exp memory numerator;
        Exp memory denominator;
        Exp memory ratio;
        MathError mathErr;

        (mathErr, numerator) = mulExp(liquidationIncentiveMantissa, priceBorrowedMantissa);
        if (mathErr != MathError.NO_ERROR) {
            return (uint(Error.MATH_ERROR), 0);
        }

        (mathErr, denominator) = mulExp(priceCollateralMantissa, exchangeRateMantissa);
        if (mathErr != MathError.NO_ERROR) {
            return (uint(Error.MATH_ERROR), 0);
        }

        (mathErr, ratio) = divExp(numerator, denominator);
        if (mathErr != MathError.NO_ERROR) {
            return (uint(Error.MATH_ERROR), 0);
        }

        (mathErr, seizeTokens) = mulScalarTruncate(ratio, actualRepayAmount);
        if (mathErr != MathError.NO_ERROR) {
            return (uint(Error.MATH_ERROR), 0);
        }

        return (uint(Error.NO_ERROR), seizeTokens);
    }

    /*** Admin Functions ***/

    /**
      * @notice Sets a new price oracle for the controller
      * @dev Admin function to set a new price oracle
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setPriceOracle(PriceOracle newOracle) public returns (uint) {
        // Check caller is admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PRICE_ORACLE_OWNER_CHECK);
        }

        // Track the old oracle for the controller
        PriceOracle oldOracle = oracle;

        // Set controller's oracle to newOracle
        oracle = newOracle;

        // Emit NewPriceOracle(oldOracle, newOracle)
        emit NewPriceOracle(oldOracle, newOracle);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Sets a PIE address for the controller
      * @return uint 0=success
      */
    function _setPieAddress(address pieAddress_) public returns (uint) {
        require(msg.sender == admin && pieAddress == address(0),"pie address may only be initialized once");

        pieAddress = pieAddress_;

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Sets the closeFactor used when liquidating borrows
      * @dev Admin function to set closeFactor
      * @param newCloseFactorMantissa New close factor, scaled by 1e18
      * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
      */
    function _setCloseFactor(uint newCloseFactorMantissa) external returns (uint) {
        // Check caller is admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_CLOSE_FACTOR_OWNER_CHECK);
        }

        Exp memory newCloseFactorExp = Exp({mantissa: newCloseFactorMantissa});
        Exp memory lowLimit = Exp({mantissa: closeFactorMinMantissa});
        if (lessThanOrEqualExp(newCloseFactorExp, lowLimit)) {
            return fail(Error.INVALID_CLOSE_FACTOR, FailureInfo.SET_CLOSE_FACTOR_VALIDATION);
        }

        Exp memory highLimit = Exp({mantissa: closeFactorMaxMantissa});
        if (lessThanExp(highLimit, newCloseFactorExp)) {
            return fail(Error.INVALID_CLOSE_FACTOR, FailureInfo.SET_CLOSE_FACTOR_VALIDATION);
        }

        uint oldCloseFactorMantissa = closeFactorMantissa;
        closeFactorMantissa = newCloseFactorMantissa;
        emit NewCloseFactor(oldCloseFactorMantissa, closeFactorMantissa);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Sets the collateralFactor for a market
      * @dev Admin function to set per-market collateralFactor
      * @param pToken The market to set the factor on
      * @param newCollateralFactorMantissa The new collateral factor, scaled by 1e18
      * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
      */
    function _setCollateralFactor(address pToken, uint newCollateralFactorMantissa) external returns (uint) {
        // Check caller is admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_COLLATERAL_FACTOR_OWNER_CHECK);
        }

        // Verify market is listed
        Market storage market = markets[pToken];
        if (!market.isListed) {
            return fail(Error.MARKET_NOT_LISTED, FailureInfo.SET_COLLATERAL_FACTOR_NO_EXISTS);
        }

        Exp memory newCollateralFactorExp = Exp({mantissa: newCollateralFactorMantissa});

        // Check collateral factor <= 0.9
        Exp memory highLimit = Exp({mantissa: collateralFactorMaxMantissa});
        if (lessThanExp(highLimit, newCollateralFactorExp)) {
            return fail(Error.INVALID_COLLATERAL_FACTOR, FailureInfo.SET_COLLATERAL_FACTOR_VALIDATION);
        }

        oracle.updateUnderlyingPrice(pToken);
        // If collateral factor != 0, fail if price == 0
        if (newCollateralFactorMantissa != 0 && oracle.getUnderlyingPrice(pToken) == 0) {
            return fail(Error.PRICE_ERROR, FailureInfo.SET_COLLATERAL_FACTOR_WITHOUT_PRICE);
        }

        // Set market's collateral factor to new collateral factor, remember old value
        uint oldCollateralFactorMantissa = market.collateralFactorMantissa;
        market.collateralFactorMantissa = newCollateralFactorMantissa;

        // Emit event with asset, old collateral factor, and new collateral factor
        emit NewCollateralFactor(pToken, oldCollateralFactorMantissa, newCollateralFactorMantissa);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Sets maxAssets which controls how many markets can be entered
      * @dev Admin function to set maxAssets
      * @param newMaxAssets New max assets
      * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
      */
    function _setMaxAssets(uint newMaxAssets) external returns (uint) {
        // Check caller is admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_MAX_ASSETS_OWNER_CHECK);
        }

        uint oldMaxAssets = maxAssets;
        maxAssets = newMaxAssets;
        emit NewMaxAssets(oldMaxAssets, newMaxAssets);

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

        // Check de-scaled min <= newLiquidationIncentive <= max
        Exp memory newLiquidationIncentive = Exp({mantissa: newLiquidationIncentiveMantissa});
        Exp memory minLiquidationIncentive = Exp({mantissa: liquidationIncentiveMinMantissa});
        if (lessThanExp(newLiquidationIncentive, minLiquidationIncentive)) {
            return fail(Error.INVALID_LIQUIDATION_INCENTIVE, FailureInfo.SET_LIQUIDATION_INCENTIVE_VALIDATION);
        }

        Exp memory maxLiquidationIncentive = Exp({mantissa: liquidationIncentiveMaxMantissa});
        if (lessThanExp(maxLiquidationIncentive, newLiquidationIncentive)) {
            return fail(Error.INVALID_LIQUIDATION_INCENTIVE, FailureInfo.SET_LIQUIDATION_INCENTIVE_VALIDATION);
        }

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
      * @param pToken The address of the market (token) to list
      * @return uint 0=success, otherwise a failure. (See enum Error for details)
      */
    function _supportMarket(address pToken) external returns (uint) {
        if (msg.sender != admin && msg.sender != factory) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SUPPORT_MARKET_OWNER_CHECK);
        }

        if (markets[pToken].isListed) {
            return fail(Error.MARKET_ALREADY_LISTED, FailureInfo.SUPPORT_MARKET_EXISTS);
        }

        PTokenInterface(pToken).isPToken(); // Sanity check to make sure its really a PToken

        _addMarketInternal(pToken);

        Market storage newMarket = markets[pToken];
        newMarket.isListed = true;

        emit MarketListed(pToken);

        return uint(Error.NO_ERROR);
    }

    function _addMarketInternal(address pToken) internal {
        require(markets[pToken].isListed == false, "market already added");
        allMarkets.push(pToken);
    }

    /**
     * @notice Admin function to change the Pause Guardian
     * @param newPauseGuardian The address of the new Pause Guardian
     * @return uint 0=success, otherwise a failure. (See enum Error for details)
     */
    function _setPauseGuardian(address newPauseGuardian) public returns (uint) {
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

    function _setMintPaused(address pToken, bool state) public returns (bool) {
        require(markets[pToken].isListed, "cannot pause a market that is not listed");
        require(msg.sender == pauseGuardian || msg.sender == admin, "only pause guardian and admin can pause");
        require(msg.sender == admin || state == true, "only admin can unpause");

        mintGuardianPaused[pToken] = state;
        emit ActionPaused(pToken, "Mint", state);
        return state;
    }

    function _setBorrowPaused(address pToken, bool state) public returns (bool) {
        require(markets[pToken].isListed, "cannot pause a market that is not listed");
        require(msg.sender == pauseGuardian || msg.sender == admin, "only pause guardian and admin can pause");
        require(msg.sender == admin || state == true, "only admin can unpause");

        borrowGuardianPaused[pToken] = state;
        emit ActionPaused(pToken, "Borrow", state);
        return state;
    }

    function _setTransferPaused(bool state) public returns (bool) {
        require(msg.sender == pauseGuardian || msg.sender == admin, "only pause guardian and admin can pause");
        require(msg.sender == admin || state == true, "only admin can unpause");

        transferGuardianPaused = state;
        emit ActionPaused("Transfer", state);
        return state;
    }

    function _setSeizePaused(bool state) public returns (bool) {
        require(msg.sender == pauseGuardian || msg.sender == admin, "only pause guardian and admin can pause");
        require(msg.sender == admin || state == true, "only admin can unpause");

        seizeGuardianPaused = state;
        emit ActionPaused("Seize", state);
        return state;
    }

    function _setFactoryContract(address _factory) external returns (uint) {
        if (msg.sender != admin) {
            return uint(Error.UNAUTHORIZED);
        }

        factory = _factory;
        return uint(Error.NO_ERROR);
    }

    function _become(address payable unitroller) public {
        require(msg.sender == Unitroller(unitroller).admin(), "only unitroller admin can change brains");
        require(Unitroller(unitroller)._acceptImplementation() == 0, "change not authorized");
    }

    /*** Pie Distribution ***/

    /**
     * @notice Set PIE speed for a single market
     * @param pToken The market whose PIE speed to update
     * @param pieSpeed New PIE speed for market
     */
    function setPieSpeedInternal(address pToken, uint pieSpeed) internal {
        uint currentPieSpeed = pieSpeeds[pToken];
        if (currentPieSpeed != 0) {
            // note that PIE speed could be set to 0 to halt liquidity rewards for a market
            Exp memory borrowIndex = Exp({mantissa: PTokenInterface(pToken).borrowIndex()});
            updatePieSupplyIndex(pToken);
            updatePieBorrowIndex(pToken, borrowIndex);
        } else if (pieSpeed != 0) {
            // Add the PIE market
            Market storage market = markets[pToken];
            require(market.isListed == true, "pie market is not listed");

            if (pieSupplyState[pToken].index == 0) {
                pieSupplyState[pToken] = PieMarketState({
                    index: pieInitialIndex,
                    block: safe32(getBlockNumber(), "block number exceeds 32 bits")
                });
            } else {
                pieSupplyState[pToken].block = safe32(getBlockNumber(), "block number exceeds 32 bits");
            }

            if (pieBorrowState[pToken].index == 0) {
                pieBorrowState[pToken] = PieMarketState({
                    index: pieInitialIndex,
                    block: safe32(getBlockNumber(), "block number exceeds 32 bits")
                });
            } else {
                pieBorrowState[pToken].block = safe32(getBlockNumber(), "block number exceeds 32 bits");
            }
        }

        if (currentPieSpeed != pieSpeed) {
            pieSpeeds[pToken] = pieSpeed;
            emit PieSpeedUpdated(pToken, pieSpeed);
        }
    }

    /**
     * @notice Accrue PIE to the market by updating the supply index
     * @param pToken The market whose supply index to update
     */
    function updatePieSupplyIndex(address pToken) internal {
        PieMarketState storage supplyState = pieSupplyState[pToken];
        uint supplySpeed = pieSpeeds[pToken];
        uint blockNumber = getBlockNumber();
        uint deltaBlocks = sub_(blockNumber, uint(supplyState.block));
        if (deltaBlocks > 0 && supplySpeed > 0) {
            uint supplyTokens = PTokenInterface(pToken).totalSupply();
            uint pieAccrued = mul_(deltaBlocks, supplySpeed);
            Double memory ratio = supplyTokens > 0 ? fraction(pieAccrued, supplyTokens) : Double({mantissa: 0});
            Double memory index = add_(Double({mantissa: supplyState.index}), ratio);
            pieSupplyState[pToken] = PieMarketState({
                index: safe224(index.mantissa, "new index exceeds 224 bits"),
                block: safe32(blockNumber, "block number exceeds 32 bits")
            });
        }
    }

    /**
     * @notice Accrue PIE to the market by updating the borrow index
     * @param pToken The market whose borrow index to update
     */
    function updatePieBorrowIndex(address pToken, Exp memory marketBorrowIndex) internal {
        PieMarketState storage borrowState = pieBorrowState[pToken];
        uint borrowSpeed = pieSpeeds[pToken];
        uint blockNumber = getBlockNumber();
        uint deltaBlocks = sub_(blockNumber, uint(borrowState.block));
        if (deltaBlocks > 0 && borrowSpeed > 0) {
            uint borrowAmount = div_(PTokenInterface(pToken).totalBorrows(), marketBorrowIndex);
            uint pieAccrued = mul_(deltaBlocks, borrowSpeed);
            Double memory ratio = borrowAmount > 0 ? fraction(pieAccrued, borrowAmount) : Double({mantissa: 0});
            Double memory index = add_(Double({mantissa: borrowState.index}), ratio);
            pieBorrowState[pToken] = PieMarketState({
                index: safe224(index.mantissa, "new index exceeds 224 bits"),
                block: safe32(blockNumber, "block number exceeds 32 bits")
            });
        }
    }

    /**
     * @notice Calculate PIE accrued by a supplier and possibly transfer it to them
     * @param pToken The market in which the supplier is interacting
     * @param supplier The address of the supplier to distribute PIE to
     */
    function distributeSupplierPie(address pToken, address supplier, bool distributeAll) internal {
        PieMarketState storage supplyState = pieSupplyState[pToken];
        Double memory supplyIndex = Double({mantissa: supplyState.index});
        Double memory supplierIndex = Double({mantissa: pieSupplierIndex[pToken][supplier]});
        pieSupplierIndex[pToken][supplier] = supplyIndex.mantissa;

        if (supplierIndex.mantissa == 0 && supplyIndex.mantissa > 0) {
            supplierIndex.mantissa = pieInitialIndex;
        }

        Double memory deltaIndex = sub_(supplyIndex, supplierIndex);
        uint supplierTokens = PTokenInterface(pToken).balanceOf(supplier);
        uint supplierDelta = mul_(supplierTokens, deltaIndex);
        uint supplierAccrued = add_(pieAccrued[supplier], supplierDelta);
        pieAccrued[supplier] = transferPie(supplier, supplierAccrued, distributeAll ? 0 : pieClaimThreshold);
        emit DistributedSupplierPie(pToken, supplier, supplierDelta, supplyIndex.mantissa);
    }

    /**
     * @notice Calculate PIE accrued by a borrower and possibly transfer it to them
     * @dev Borrowers will not begin to accrue until after the first interaction with the protocol.
     * @param pToken The market in which the borrower is interacting
     * @param borrower The address of the borrower to distribute PIE to
     */
    function distributeBorrowerPie(
        address pToken,
        address borrower,
        Exp memory marketBorrowIndex,
        bool distributeAll
    ) internal {
        PieMarketState storage borrowState = pieBorrowState[pToken];
        Double memory borrowIndex = Double({mantissa: borrowState.index});
        Double memory borrowerIndex = Double({mantissa: pieBorrowerIndex[pToken][borrower]});
        pieBorrowerIndex[pToken][borrower] = borrowIndex.mantissa;

        if (borrowerIndex.mantissa > 0) {
            Double memory deltaIndex = sub_(borrowIndex, borrowerIndex);
            uint borrowerAmount = div_(PTokenInterface(pToken).borrowBalanceStored(borrower), marketBorrowIndex);
            uint borrowerDelta = mul_(borrowerAmount, deltaIndex);
            uint borrowerAccrued = add_(pieAccrued[borrower], borrowerDelta);
            pieAccrued[borrower] = transferPie(borrower, borrowerAccrued, distributeAll ? 0 : pieClaimThreshold);
            emit DistributedBorrowerPie(pToken, borrower, borrowerDelta, borrowIndex.mantissa);
        }
    }

    /**
     * @notice Claim all the pie accrued by holder in all markets
     * @param holder The address to claim PIE for
     */
    function claimPie(address holder) public {
        claimPie(holder, allMarkets);
    }

    /**
     * @notice Claim all the pie accrued by holder in the specified markets
     * @param holder The address to claim PIE for
     * @param pTokens The list of markets to claim PIE in
     */
    function claimPie(address holder, address[] memory pTokens) public {
        address[] memory holders = new address[](1);
        holders[0] = holder;
        claimPie(holders, pTokens, true, true);
    }

    /**
     * @notice Claim all pie accrued by the holders
     * @param holders The addresses to claim PIE for
     * @param pTokens The list of markets to claim PIE in
     * @param borrowers Whether or not to claim PIE earned by borrowing
     * @param suppliers Whether or not to claim PIE earned by supplying
     */
    function claimPie(address[] memory holders, address[] memory pTokens, bool borrowers, bool suppliers) public {
        for (uint i = 0; i < pTokens.length; i++) {
            address pToken = pTokens[i];
            require(markets[pToken].isListed, "market must be listed");
            if (borrowers == true) {
                Exp memory borrowIndex = Exp({mantissa: PTokenInterface(pToken).borrowIndex()});
                updatePieBorrowIndex(pToken, borrowIndex);
                for (uint j = 0; j < holders.length; j++) {
                    distributeBorrowerPie(pToken, holders[j], borrowIndex, true);
                }
            }
            if (suppliers == true) {
                updatePieSupplyIndex(pToken);
                for (uint j = 0; j < holders.length; j++) {
                    distributeSupplierPie(pToken, holders[j], true);
                }
            }
        }
    }

    /**
     * @notice Transfer PIE to the user
     * @dev Note: If there is not enough PIE, we do not perform the transfer all.
     * @param user The address of the user to transfer PIE to
     * @param userAccrued The amount of PIE to (possibly) transfer
     * @return The userAccrued of PIE which was NOT transferred to the user
     */
    function transferPie(address user, uint userAccrued, uint threshold) internal returns (uint) {
        if (userAccrued >= threshold && userAccrued > 0) {
            address pie = getPieAddress();
            uint pieRemaining = EIP20Interface(pie).balanceOf(address(this));
            if (userAccrued <= pieRemaining) {
                EIP20Interface(pie).transfer(user, userAccrued);
                return 0;
            }
        }
        return userAccrued;
    }

    /*** Pie Distribution Admin ***/

    /**
    * @notice Set PIE speed for a single market
    * @param pToken The market whose PIE speed to update
    * @param pieSpeed New PIE speed for market
    */
    function _setPieSpeed(address pToken, uint pieSpeed) public {
        require(msg.sender == admin, "only admin can set pie speed");
        setPieSpeedInternal(pToken, pieSpeed);
    }

    /**
     * @notice Return all of the markets
     * @dev The automatic getter may be used to access an individual market.
     * @return The list of market addresses
     */
    function getAllMarkets() public view returns (address[] memory) {
        return allMarkets;
    }

    function getBlockNumber() public view virtual returns (uint) {
        return block.number;
    }

    /**
     * @notice Return the address of the PIE token
     * @return The address of PIE
     */
    function getPieAddress() public view virtual returns (address) {
        return pieAddress;
    }

    function getOracle() public view override returns (PriceOracle) {
        return oracle;
    }
}

pragma solidity ^0.7.6;

import "./PriceOracle.sol";

abstract contract ControllerInterface {
    /// @notice Indicator that this is a Controller contract (for inspection)
    bool public constant isController = true;

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata pTokens) external virtual returns (uint[] memory);
    function exitMarket(address pToken) external virtual returns (uint);

    /*** Policy Hooks ***/

    function mintAllowed(address pToken, address minter, uint mintAmount) external virtual returns (uint);
    function redeemAllowed(address pToken, address redeemer, uint redeemTokens) external virtual returns (uint);
    function redeemVerify(address pToken, address redeemer, uint redeemAmount, uint redeemTokens) external virtual;
    function borrowAllowed(address pToken, address borrower, uint borrowAmount) external virtual returns (uint);

    function repayBorrowAllowed(
        address pToken,
        address payer,
        address borrower,
        uint repayAmount) external virtual returns (uint);

    function liquidateBorrowAllowed(
        address pTokenBorrowed,
        address pTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) external virtual returns (uint);

    function seizeAllowed(
        address pTokenCollateral,
        address pTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external virtual returns (uint);

    function transferAllowed(address pToken, address src, address dst, uint transferTokens) external virtual returns (uint);

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address pTokenBorrowed,
        address pTokenCollateral,
        uint repayAmount) external view virtual returns (uint, uint);

    function getOracle() external view virtual returns (PriceOracle);
}

pragma solidity ^0.7.6;

import "./PriceOracle.sol";

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
    /**
     * @notice Oracle which gives the price of any given asset
     */
    PriceOracle public oracle;

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
    mapping(address => address[]) public accountAssets;

    /// @notice isListed Whether or not this market is listed
    /**
     * @notice collateralFactorMantissa Multiplier representing the most one can borrow against their collateral in this market.
     *  For instance, 0.9 to allow borrowing 90% of collateral value.
     *  Must be between 0 and 1, and stored as a mantissa.
     */
    /// @notice accountMembership Per-market mapping of "accounts in this asset"
    /// @notice isPied Whether or not this market receives PIE
    struct Market {
        bool isListed;
        uint collateralFactorMantissa;
        mapping(address => bool) accountMembership;
        bool isPied;
    }

    /**
     * @notice Official mapping of pTokens -> Market metadata
     * @dev Used e.g. to determine if a market is supported
     */
    mapping(address => Market) public markets;

    /**
     * @notice The Pause Guardian can pause certain actions as a safety mechanism.
     *  Actions which allow users to remove their own assets cannot be paused.
     *  Liquidation / seizing / transfer can only be paused globally, not by market.
     */
    address public pauseGuardian;
    bool public _mintGuardianPaused;
    bool public _borrowGuardianPaused;
    bool public transferGuardianPaused;
    bool public seizeGuardianPaused;
    mapping(address => bool) public mintGuardianPaused;
    mapping(address => bool) public borrowGuardianPaused;

    /// @notice index The market's last updated pieBorrowIndex or pieSupplyIndex
    /// @notice block The block number the index was last updated at
    struct PieMarketState {
        uint224 index;
        uint32 block;
    }

    /// @notice A list of all markets
    address[] public allMarkets;

    /// @notice The rate at which the flywheel distributes PIE, per block
    uint public pieRate;

    /// @notice Address of the PIE token
    address public pieAddress;

    // @notice Address of the factory
    address public factory;

    /// @notice The portion of pieRate that each market currently receives
    mapping(address => uint) public pieSpeeds;

    /// @notice The PIE market supply state for each market
    mapping(address => PieMarketState) public pieSupplyState;

    /// @notice The PIE market borrow state for each market
    mapping(address => PieMarketState) public pieBorrowState;

    /// @notice The PIE borrow index for each market for each supplier as of the last time they accrued PIE
    mapping(address => mapping(address => uint)) public pieSupplierIndex;

    /// @notice The PIE borrow index for each market for each borrower as of the last time they accrued PIE
    mapping(address => mapping(address => uint)) public pieBorrowerIndex;

    /// @notice The PIE accrued but not yet transferred to each user
    mapping(address => uint) public pieAccrued;
}

pragma solidity ^0.7.6;

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
    function balanceOf(address owner) external view returns (uint256);

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return Whether or not the transfer succeeded
      */
    function transfer(address dst, uint256 amount) external returns (bool);

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return Whether or not the transfer succeeded
      */
    function transferFrom(address src, address dst, uint256 amount) external returns (bool);

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved (-1 means infinite)
      * @return Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return The number of tokens allowed to be spent (-1 means infinite)
      */
    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

pragma solidity ^0.7.6;

contract ControllerErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED,
        CONTROLLER_MISMATCH,
        INSUFFICIENT_SHORTFALL,
        INSUFFICIENT_LIQUIDITY,
        INVALID_CLOSE_FACTOR,
        INVALID_COLLATERAL_FACTOR,
        INVALID_LIQUIDATION_INCENTIVE,
        MARKET_NOT_ENTERED, // no longer possible
        MARKET_NOT_LISTED,
        MARKET_ALREADY_LISTED,
        MATH_ERROR,
        NONZERO_BORROW_BALANCE,
        PRICE_ERROR,
        PRICE_UPDATE_ERROR,
        REJECTION,
        SNAPSHOT_ERROR,
        TOO_MANY_ASSETS,
        TOO_MUCH_REPAY
    }

    enum FailureInfo {
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK,
        EXIT_MARKET_BALANCE_OWED,
        EXIT_MARKET_REJECTION,
        SET_CLOSE_FACTOR_OWNER_CHECK,
        SET_CLOSE_FACTOR_VALIDATION,
        SET_COLLATERAL_FACTOR_OWNER_CHECK,
        SET_COLLATERAL_FACTOR_NO_EXISTS,
        SET_COLLATERAL_FACTOR_VALIDATION,
        SET_COLLATERAL_FACTOR_WITHOUT_PRICE,
        SET_IMPLEMENTATION_OWNER_CHECK,
        SET_LIQUIDATION_INCENTIVE_OWNER_CHECK,
        SET_LIQUIDATION_INCENTIVE_VALIDATION,
        SET_MAX_ASSETS_OWNER_CHECK,
        SET_PAUSE_GUARDIAN_OWNER_CHECK,
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_PENDING_IMPLEMENTATION_OWNER_CHECK,
        SET_PRICE_ORACLE_OWNER_CHECK,
        SUPPORT_MARKET_EXISTS,
        SUPPORT_MARKET_OWNER_CHECK
    }

    /**
      * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
      * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
      **/
    event Failure(uint error, uint info, uint detail);

    /**
      * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
      */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }

    /**
      * @dev use this when reporting an opaque error from an upgradeable collaborator contract
      */
    function failOpaque(Error err, FailureInfo info, uint opaqueError) internal returns (uint) {
        emit Failure(uint(err), uint(info), opaqueError);

        return uint(err);
    }
}

contract TokenErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED,
        BAD_INPUT,
        CONTROLLER_REJECTION,
        CONTROLLER_CALCULATION_ERROR,
        INTEREST_RATE_MODEL_ERROR,
        INVALID_ACCOUNT_PAIR,
        INVALID_CLOSE_AMOUNT_REQUESTED,
        INVALID_COLLATERAL_FACTOR,
        MATH_ERROR,
        MARKET_NOT_FRESH,
        MARKET_NOT_LISTED,
        TOKEN_INSUFFICIENT_ALLOWANCE,
        TOKEN_INSUFFICIENT_BALANCE,
        TOKEN_INSUFFICIENT_CASH,
        TOKEN_TRANSFER_IN_FAILED,
        TOKEN_TRANSFER_OUT_FAILED
    }

    /*
     * Note: FailureInfo (but not Error) is kept in alphabetical order
     *       This is because FailureInfo grows significantly faster, and
     *       the order of Error has some meaning, while the order of FailureInfo
     *       is entirely arbitrary.
     */
    enum FailureInfo {
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        ACCRUE_INTEREST_ACCUMULATED_INTEREST_CALCULATION_FAILED,
        ACCRUE_INTEREST_BORROW_RATE_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_BORROW_INDEX_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_TOTAL_BORROWS_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_TOTAL_RESERVES_CALCULATION_FAILED,
        ACCRUE_INTEREST_SIMPLE_INTEREST_FACTOR_CALCULATION_FAILED,
        BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        BORROW_ACCRUE_INTEREST_FAILED,
        BORROW_CASH_NOT_AVAILABLE,
        BORROW_FRESHNESS_CHECK,
        BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
        BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED,
        BORROW_MARKET_NOT_LISTED,
        BORROW_CONTROLLER_REJECTION,
        LIQUIDATE_ACCRUE_BORROW_INTEREST_FAILED,
        LIQUIDATE_ACCRUE_COLLATERAL_INTEREST_FAILED,
        LIQUIDATE_COLLATERAL_FRESHNESS_CHECK,
        LIQUIDATE_CONTROLLER_REJECTION,
        LIQUIDATE_CONTROLLER_CALCULATE_AMOUNT_SEIZE_FAILED,
        LIQUIDATE_CLOSE_AMOUNT_IS_UINT_MAX,
        LIQUIDATE_CLOSE_AMOUNT_IS_ZERO,
        LIQUIDATE_FRESHNESS_CHECK,
        LIQUIDATE_LIQUIDATOR_IS_BORROWER,
        LIQUIDATE_REPAY_BORROW_FRESH_FAILED,
        LIQUIDATE_SEIZE_BALANCE_INCREMENT_FAILED,
        LIQUIDATE_SEIZE_BALANCE_DECREMENT_FAILED,
        LIQUIDATE_SEIZE_CONTROLLER_REJECTION,
        LIQUIDATE_SEIZE_LIQUIDATOR_IS_BORROWER,
        LIQUIDATE_SEIZE_TOO_MUCH,
        MINT_ACCRUE_INTEREST_FAILED,
        MINT_CONTROLLER_REJECTION,
        MINT_EXCHANGE_CALCULATION_FAILED,
        MINT_EXCHANGE_RATE_READ_FAILED,
        MINT_FRESHNESS_CHECK,
        MINT_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED,
        MINT_NEW_TOTAL_SUPPLY_CALCULATION_FAILED,
        MINT_TRANSFER_IN_FAILED,
        MINT_TRANSFER_IN_NOT_POSSIBLE,
        REDEEM_ACCRUE_INTEREST_FAILED,
        REDEEM_CONTROLLER_REJECTION,
        REDEEM_EXCHANGE_TOKENS_CALCULATION_FAILED,
        REDEEM_EXCHANGE_AMOUNT_CALCULATION_FAILED,
        REDEEM_EXCHANGE_RATE_READ_FAILED,
        REDEEM_FRESHNESS_CHECK,
        REDEEM_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED,
        REDEEM_NEW_TOTAL_SUPPLY_CALCULATION_FAILED,
        REDEEM_TRANSFER_OUT_NOT_POSSIBLE,
        REDUCE_RESERVES_ACCRUE_INTEREST_FAILED,
        REDUCE_RESERVES_ADMIN_CHECK,
        REDUCE_RESERVES_CASH_NOT_AVAILABLE,
        REDUCE_RESERVES_FRESH_CHECK,
        REDUCE_RESERVES_VALIDATION,
        REPAY_BEHALF_ACCRUE_INTEREST_FAILED,
        REPAY_BORROW_ACCRUE_INTEREST_FAILED,
        REPAY_BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_CONTROLLER_REJECTION,
        REPAY_BORROW_FRESHNESS_CHECK,
        REPAY_BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_TRANSFER_IN_NOT_POSSIBLE,
        SET_COLLATERAL_FACTOR_OWNER_CHECK,
        SET_COLLATERAL_FACTOR_VALIDATION,
        SET_CONTROLLER_OWNER_CHECK,
        SET_INTEREST_RATE_MODEL_ACCRUE_INTEREST_FAILED,
        SET_INTEREST_RATE_MODEL_FRESH_CHECK,
        SET_INTEREST_RATE_MODEL_OWNER_CHECK,
        SET_MAX_ASSETS_OWNER_CHECK,
        SET_ORACLE_MARKET_NOT_LISTED,
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_RESERVE_FACTOR_ACCRUE_INTEREST_FAILED,
        SET_RESERVE_FACTOR_ADMIN_CHECK,
        SET_RESERVE_FACTOR_FRESH_CHECK,
        SET_RESERVE_FACTOR_BOUNDS_CHECK,
        TRANSFER_CONTROLLER_REJECTION,
        TRANSFER_NOT_ALLOWED,
        TRANSFER_NOT_ENOUGH,
        TRANSFER_TOO_MUCH,
        ADD_RESERVES_ACCRUE_INTEREST_FAILED,
        ADD_RESERVES_FRESH_CHECK,
        ADD_RESERVES_TRANSFER_IN_NOT_POSSIBLE,
        SET_NEW_IMPLEMENTATION
    }

    /**
      * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
      * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
      **/
    event Failure(uint error, uint info, uint detail);

    /**
      * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
      */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }

    /**
      * @dev use this when reporting an opaque error from an upgradeable collaborator contract
      */
    function failOpaque(Error err, FailureInfo info, uint opaqueError) internal returns (uint) {
        emit Failure(uint(err), uint(info), opaqueError);

        return uint(err);
    }
}

contract OracleErrorReporter {
    enum Error {
        NO_ERROR,
        POOL_OR_COIN_EXIST,
        UNAUTHORIZED,
        UPDATE_PRICE
    }

    enum FailureInfo {
        ADD_POOL_OR_COIN,
        NO_PAIR,
        NO_RESERVES,
        PERIOD_NOT_ELAPSED,
        SET_NEW_IMPLEMENTATION,
        UPDATE_DATA
    }

    /**
      * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
      * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
      **/
    event Failure(uint error, uint info, uint detail);

    /**
      * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
      */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }
}

contract FactoryErrorReporter {
    enum Error {
        NO_ERROR,
        INVALID_POOL,
        MARKET_NOT_LISTED,
        UNAUTHORIZED
    }

    enum FailureInfo {
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        CREATE_PETH_POOL,
        CREATE_PPIE_POOL,
        DEFICIENCY_LIQUIDITY_IN_POOL_OR_PAIR_IS_NOT_EXIST,
        SET_MIN_LIQUIDITY_OWNER_CHECK,
        SET_NEW_CONTROLLER,
        SET_NEW_DECIMALS,
        SET_NEW_EXCHANGE_RATE,
        SET_NEW_IMPLEMENTATION,
        SET_NEW_INTEREST_RATE_MODEL,
        SET_NEW_ORACLE,
        SET_NEW_RESERVE_FACTOR,
        SET_PENDING_ADMIN_OWNER_CHECK,
        SUPPORT_MARKET_BAD_RESULT
    }

    /**
      * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
      * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
      **/
    event Failure(uint error, uint info, uint detail);

    /**
      * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
      */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }
}

contract RegistryErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED
    }

    enum FailureInfo {
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        SET_NEW_IMPLEMENTATION,
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_NEW_FACTORY
    }

    /**
      * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
      * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
      **/
    event Failure(uint error, uint info, uint detail);

    /**
      * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
      */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }
}

pragma solidity ^0.7.6;

import "./CarefulMath.sol";

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author DeFiPie
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract Exponential is CarefulMath {
    uint constant expScale = 1e18;
    uint constant doubleScale = 1e36;
    uint constant halfExpScale = expScale/2;
    uint constant mantissaOne = expScale;

    struct Exp {
        uint mantissa;
    }

    struct Double {
        uint mantissa;
    }

    /**
     * @dev Creates an exponential from numerator and denominator values.
     *      Note: Returns an error if (`num` * 10e18) > MAX_INT,
     *            or if `denom` is zero.
     */
    function getExp(uint num, uint denom) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint scaledNumerator) = mulUInt(num, expScale);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        (MathError err1, uint rational) = divUInt(scaledNumerator, denom);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: rational}));
    }

    /**
     * @dev Adds two exponentials, returning a new exponential.
     */
    function addExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        (MathError error, uint result) = addUInt(a.mantissa, b.mantissa);

        return (error, Exp({mantissa: result}));
    }

    /**
     * @dev Subtracts two exponentials, returning a new exponential.
     */
    function subExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        (MathError error, uint result) = subUInt(a.mantissa, b.mantissa);

        return (error, Exp({mantissa: result}));
    }

    /**
     * @dev Multiply an Exp by a scalar, returning a new Exp.
     */
    function mulScalar(Exp memory a, uint scalar) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint scaledMantissa) = mulUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: scaledMantissa}));
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mulScalarTruncate(Exp memory a, uint scalar) pure internal returns (MathError, uint) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, truncate(product));
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mulScalarTruncateAddUInt(Exp memory a, uint scalar, uint addend) pure internal returns (MathError, uint) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return addUInt(truncate(product), addend);
    }

    /**
     * @dev Divide an Exp by a scalar, returning a new Exp.
     */
    function divScalar(Exp memory a, uint scalar) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint descaledMantissa) = divUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: descaledMantissa}));
    }

    /**
     * @dev Divide a scalar by an Exp, returning a new Exp.
     */
    function divScalarByExp(uint scalar, Exp memory divisor) pure internal returns (MathError, Exp memory) {
        /*
          We are doing this as:
          getExp(mulUInt(expScale, scalar), divisor.mantissa)

          How it works:
          Exp = a / b;
          Scalar = s;
          `s / (a / b)` = `b * s / a` and since for an Exp `a = mantissa, b = expScale`
        */
        (MathError err0, uint numerator) = mulUInt(expScale, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }
        return getExp(numerator, divisor.mantissa);
    }

    /**
     * @dev Divide a scalar by an Exp, then truncate to return an unsigned integer.
     */
    function divScalarByExpTruncate(uint scalar, Exp memory divisor) pure internal returns (MathError, uint) {
        (MathError err, Exp memory fraction_) = divScalarByExp(scalar, divisor);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, truncate(fraction_));
    }

    /**
     * @dev Multiplies two exponentials, returning a new exponential.
     */
    function mulExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {

        (MathError err0, uint doubleScaledProduct) = mulUInt(a.mantissa, b.mantissa);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        // We add half the scale before dividing so that we get rounding instead of truncation.
        //  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717
        // Without this change, a result like 6.6...e-19 will be truncated to 0 instead of being rounded to 1e-18.
        (MathError err1, uint doubleScaledProductWithHalfScale) = addUInt(halfExpScale, doubleScaledProduct);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        (MathError err2, uint product) = divUInt(doubleScaledProductWithHalfScale, expScale);
        // The only error `div` can return is MathError.DIVISION_BY_ZERO but we control `expScale` and it is not zero.
        assert(err2 == MathError.NO_ERROR);

        return (MathError.NO_ERROR, Exp({mantissa: product}));
    }

    /**
     * @dev Multiplies two exponentials given their mantissas, returning a new exponential.
     */
    function mulExp(uint a, uint b) pure internal returns (MathError, Exp memory) {
        return mulExp(Exp({mantissa: a}), Exp({mantissa: b}));
    }

    /**
     * @dev Multiplies three exponentials, returning a new exponential.
     */
    function mulExp3(Exp memory a, Exp memory b, Exp memory c) pure internal returns (MathError, Exp memory) {
        (MathError err, Exp memory ab) = mulExp(a, b);
        if (err != MathError.NO_ERROR) {
            return (err, ab);
        }
        return mulExp(ab, c);
    }

    /**
     * @dev Divides two exponentials, returning a new exponential.
     *     (a/scale) / (b/scale) = (a/scale) * (scale/b) = a/b,
     *  which we can scale as an Exp by calling getExp(a.mantissa, b.mantissa)
     */
    function divExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
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
        require(n < 2**224, errorMessage);
        return uint224(n);
    }

    function safe32(uint n, string memory errorMessage) pure internal returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function add_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: add_(a.mantissa, b.mantissa)});
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
        return Exp({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(uint a, uint b) pure internal returns (uint) {
        return sub_(a, b, "subtraction underflow");
    }

    function sub_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function mul_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b.mantissa) / expScale});
    }

    function mul_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint a, Exp memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / expScale;
    }

    function mul_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b.mantissa) / doubleScale});
    }

    function mul_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b)});
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
        return Exp({mantissa: div_(mul_(a.mantissa, expScale), b.mantissa)});
    }

    function div_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint a, Exp memory b) pure internal returns (uint) {
        return div_(mul_(a, expScale), b.mantissa);
    }

    function div_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(a.mantissa, doubleScale), b.mantissa)});
    }

    function div_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: div_(a.mantissa, b)});
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
        return Double({mantissa: div_(mul_(a, doubleScale), b)});
    }
}

pragma solidity ^0.7.6;
pragma abicoder v2;

import '../Registry.sol';

contract Governor {
    /// @notice The name of this contract
    string public constant name = "DeFiPie Governor";

    uint public threshold = 15_000_000e18; // 15M pPIE or ~300K PIE
    uint public quorum = 150_000_000e18; // 150M pPIE or ~3M PIE
    uint public delay = 1; // 1 block
    uint public period = 19710; // ~3 days in blocks (assuming 15s blocks)

    /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
    function quorumVotes() public view returns (uint) { return quorum; }

    /// @notice The number of votes required in order for a voter to become a proposer
    function proposalThreshold() public view returns (uint) { return threshold; }

    /// @notice The maximum number of actions that can be included in a proposal
    function proposalMaxOperations() public pure returns (uint) { return 10; } // 10 actions

    /// @notice The delay before voting on a proposal may take place, once proposed
    function votingDelay() public view returns (uint) { return delay; }

    /// @notice The duration of voting on a proposal, in blocks
    function votingPeriod() public view virtual returns (uint) { return period; }

    /// @notice The address of the DeFiPie Protocol Timelock
    TimelockInterface public timelock;

    /// @notice The address of the Registry
    Registry public registry;

    /// @notice The address of the Governor Guardian
    address public guardian;

    /// @notice The total number of proposals
    uint public proposalCount;

    /// @notice id Unique id for looking up a proposal
    /// @notice proposer Creator of the proposal
    /// @notice eta The timestamp that the proposal will be available for execution, set once the vote succeeds
    /// @notice targets the ordered list of target addresses for calls to be made
    /// @notice values The ordered list of values (i.e. msg.value) to be passed to the calls to be made
    /// @notice signatures The ordered list of function signatures to be called
    /// @notice calldatas The ordered list of calldata to be passed to each call
    /// @notice startBlock The block at which voting begins: holders must delegate their votes prior to this block
    /// @notice endBlock The block at which voting ends: votes must be cast prior to this block
    /// @notice forVotes Current number of votes in favor of this proposal
    /// @notice againstVotes Current number of votes in opposition to this proposal
    /// @notice canceled Flag marking whether the proposal has been canceled
    /// @notice executed Flag marking whether the proposal has been executed
    /// @notice receipts Receipts of ballots for the entire set of voters

    struct Proposal {
        uint id;
        address proposer;
        uint eta;
        address[] targets;
        uint[] values;
        string[] signatures;
        bytes[] calldatas;
        uint startBlock;
        uint endBlock;
        uint forVotes;
        uint againstVotes;
        bool canceled;
        bool executed;
        mapping (address => Receipt) receipts;
    }

    /// @notice Ballot receipt record for a voter
    /// @notice hasVoted Whether or not a vote has been cast
    /// @notice support Whether or not the voter supports the proposal
    /// @notice votes The number of votes the voter had, which were cast

    struct Receipt {
        bool hasVoted;
        bool support;
        uint96 votes;
    }

    /// @notice Possible states that a proposal may be in
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    /// @notice The official record of all proposals ever proposed
    mapping (uint => Proposal) public proposals;

    /// @notice The latest proposal for each proposer
    mapping (address => uint) public latestProposalIds;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the ballot struct used by the contract
    bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,bool support)");

    /// @notice An event emitted when a new proposal is created
    event ProposalCreated(
        uint id,
        address proposer,
        address[] targets,
        uint[] values,
        string[] signatures,
        bytes[] calldatas,
        uint startBlock,
        uint endBlock,
        string description
    );

    /// @notice An event emitted when a vote has been cast on a proposal
    event VoteCast(address voter, uint proposalId, bool support, uint votes);

    /// @notice An event emitted when a proposal has been canceled
    event ProposalCanceled(uint id);

    /// @notice An event emitted when a proposal has been queued in the Timelock
    event ProposalQueued(uint id, uint eta);

    /// @notice An event emitted when a proposal has been executed in the Timelock
    event ProposalExecuted(uint id);

    event NewQuorum(uint indexed newQuorum);
    event NewThreshold(uint indexed newThreshold);
    event NewVotingDelay(uint indexed newVotingDelay);
    event NewVotingPeriod(uint indexed newVotingPeriod);

    constructor(address timelock_, address registry_, address guardian_) {
        timelock = TimelockInterface(timelock_);
        registry = Registry(registry_);
        guardian = guardian_;
    }

    function propose(
        address[] memory targets,
        uint[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) public returns (uint) {
        require(PPieInterface(registry.pPIE()).getPriorVotes(msg.sender, sub256(block.number, 1)) > proposalThreshold(), "Governor::propose: proposer votes below proposal threshold");
        require(targets.length == values.length && targets.length == signatures.length && targets.length == calldatas.length, "Governor::propose: proposal function information parity mismatch");
        require(targets.length != 0, "Governor::propose: must provide actions");
        require(targets.length <= proposalMaxOperations(), "Governor::propose: too many actions");

        uint latestProposalId = latestProposalIds[msg.sender];
        if (latestProposalId != 0) {
            ProposalState proposersLatestProposalState = state(latestProposalId);
            require(proposersLatestProposalState != ProposalState.Active, "Governor::propose: one live proposal per proposer, found an already active proposal");
            require(proposersLatestProposalState != ProposalState.Pending, "Governor::propose: one live proposal per proposer, found an already pending proposal");
        }

        uint startBlock = add256(block.number, votingDelay());
        uint endBlock = add256(startBlock, votingPeriod());

        proposalCount++;
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.proposer = msg.sender;
        newProposal.targets = targets;
        newProposal.values = values;
        newProposal.signatures = signatures;
        newProposal.calldatas = calldatas;
        newProposal.startBlock = startBlock;
        newProposal.endBlock = endBlock;

        latestProposalIds[newProposal.proposer] = newProposal.id;

        emit ProposalCreated(newProposal.id, msg.sender, targets, values, signatures, calldatas, startBlock, endBlock, description);
        return newProposal.id;
    }

    function queue(uint proposalId) public {
        require(state(proposalId) == ProposalState.Succeeded, "Governor::queue: proposal can only be queued if it is succeeded");
        Proposal storage proposal = proposals[proposalId];
        uint eta = add256(block.timestamp, timelock.delay());
        for (uint i = 0; i < proposal.targets.length; i++) {
            _queueOrRevert(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], eta);
        }
        proposal.eta = eta;
        emit ProposalQueued(proposalId, eta);
    }

    function _queueOrRevert(address target, uint value, string memory signature, bytes memory data, uint eta) internal {
        require(!timelock.queuedTransactions(keccak256(abi.encode(target, value, signature, data, eta))), "Governor::_queueOrRevert: proposal action already queued at eta");
        timelock.queueTransaction(target, value, signature, data, eta);
    }

    function execute(uint proposalId) public payable {
        require(state(proposalId) == ProposalState.Queued, "Governor::execute: proposal can only be executed if it is queued");
        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;
        for (uint i = 0; i < proposal.targets.length; i++) {
            timelock.executeTransaction{value: proposal.values[i]}(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }
        emit ProposalExecuted(proposalId);
    }

    function cancel(uint proposalId) public {
        ProposalState state_ = state(proposalId);
        require(state_ != ProposalState.Executed, "Governor::cancel: cannot cancel executed proposal");

        Proposal storage proposal = proposals[proposalId];
        require(msg.sender == guardian || PPieInterface(registry.pPIE()).getPriorVotes(proposal.proposer, sub256(block.number, 1)) < proposalThreshold(), "Governor::cancel: proposer above threshold");

        proposal.canceled = true;
        for (uint i = 0; i < proposal.targets.length; i++) {
            timelock.cancelTransaction(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }

        emit ProposalCanceled(proposalId);
    }

    function getActions(
        uint proposalId
    ) public view returns (
        address[] memory targets,
        uint[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas
    ) {
        Proposal storage p = proposals[proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

    function getReceipt(uint proposalId, address voter) public view returns (Receipt memory) {
        return proposals[proposalId].receipts[voter];
    }

    function getForVotes(uint proposalId) public view returns (uint) {
        return proposals[proposalId].forVotes;
    }

    function state(uint proposalId) public view returns (ProposalState) {
        require(proposalCount >= proposalId && proposalId > 0, "Governor::state: invalid proposal id");
        Proposal storage proposal = proposals[proposalId];
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.number <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < quorumVotes()) {
            return ProposalState.Defeated;
        } else if (proposal.eta == 0) {
            return ProposalState.Succeeded;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.timestamp >= add256(proposal.eta, timelock.GRACE_PERIOD())) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }

    function castVote(uint proposalId, bool support) public {
        _castVote(msg.sender, proposalId, support);
    }

    function castVoteBySig(uint proposalId, bool support, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "Governor::castVoteBySig: invalid signature");
        _castVote(signatory, proposalId, support);
    }

    function _castVote(address voter, uint proposalId, bool support) internal {
        require(state(proposalId) == ProposalState.Active, "Governor::_castVote: voting is closed");
        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[voter];
        require(receipt.hasVoted == false, "Governor::_castVote: voter already voted");
        uint96 votes = PPieInterface(registry.pPIE()).getPriorVotes(voter, proposal.startBlock);

        if (support) {
            proposal.forVotes = add256(proposal.forVotes, votes);
        } else {
            proposal.againstVotes = add256(proposal.againstVotes, votes);
        }

        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = votes;

        emit VoteCast(voter, proposalId, support, votes);
    }

    function setQuorum(uint newQuorum) external {
        require(msg.sender == guardian, "Governor::setQuorum: sender must be gov guardian");
        quorum = newQuorum;

        emit NewQuorum(newQuorum);
    }

    function setThreshold(uint newThreshold) external {
        require(msg.sender == guardian, "Governor::setThreshold: sender must be gov guardian");
        threshold = newThreshold;

        emit NewThreshold(newThreshold);
    }

    function setVotingDelay(uint newVotingDelay) external {
        require(msg.sender == guardian, "Governor::setVotingDelay: sender must be gov guardian");
        delay = newVotingDelay;

        emit NewVotingDelay(newVotingDelay);
    }

    function setVotingPeriod(uint newVotingPeriod) external {
        require(msg.sender == guardian, "Governor::setVotingPeriod: sender must be gov guardian");
        period = newVotingPeriod;

        emit NewVotingPeriod(newVotingPeriod);
    }

    function __acceptAdmin() public {
        require(msg.sender == guardian, "Governor::__acceptAdmin: sender must be gov guardian");
        timelock.acceptAdmin();
    }

    function __abdicate() public {
        require(msg.sender == guardian, "Governor::__abdicate: sender must be gov guardian");
        guardian = address(0);
    }

    function __queueSetTimelockPendingAdmin(address newPendingAdmin, uint eta) public {
        require(msg.sender == guardian, "Governor::__queueSetTimelockPendingAdmin: sender must be gov guardian");
        timelock.queueTransaction(address(timelock), 0, "setPendingAdmin(address)", abi.encode(newPendingAdmin), eta);
    }

    function __executeSetTimelockPendingAdmin(address newPendingAdmin, uint eta) public {
        require(msg.sender == guardian, "Governor::__executeSetTimelockPendingAdmin: sender must be gov guardian");
        timelock.executeTransaction(address(timelock), 0, "setPendingAdmin(address)", abi.encode(newPendingAdmin), eta);
    }

    function add256(uint256 a, uint256 b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "addition overflow");
        return c;
    }

    function sub256(uint256 a, uint256 b) internal pure returns (uint) {
        require(b <= a, "subtraction underflow");
        return a - b;
    }

    function getChainId() internal pure returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}

interface TimelockInterface {
    function delay() external view returns (uint);
    function GRACE_PERIOD() external view returns (uint);
    function acceptAdmin() external;
    function queuedTransactions(bytes32 hash) external view returns (bool);
    function queueTransaction(address target, uint value, string calldata signature, bytes calldata data, uint eta) external returns (bytes32);
    function cancelTransaction(address target, uint value, string calldata signature, bytes calldata data, uint eta) external;
    function executeTransaction(address target, uint value, string calldata signature, bytes calldata data, uint eta) external payable returns (bytes memory);
}

interface PPieInterface {
    function getPriorVotes(address account, uint blockNumber) external view returns (uint96);
}

pragma solidity ^0.7.6;

import "./SafeMath.sol";

interface AggregatorInterface {
    function latestAnswer() external view returns (int256);
}

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint _x;
    }

    uint8 private constant RESOLUTION = 112;

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint y) internal pure returns (uq144x112 memory) {
        uint z;
        require(y == 0 || (z = uint(self._x) * y) / y == uint(self._x), "FixedPoint: MULTIPLICATION_OVERFLOW");
        return uq144x112(z);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }
}

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

pragma solidity ^0.7.6;

/**
  * @title DeFiPie's InterestRateModel Interface
  * @author DeFiPie
  */
abstract contract InterestRateModel {
    /// @notice Indicator that this is an InterestRateModel contract (for inspection)
    bool public constant isInterestRateModel = true;

    /**
      * @notice Calculates the current borrow interest rate per block
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @return The borrow rate per block (as a percentage, and scaled by 1e18)
      */
    function getBorrowRate(uint cash, uint borrows, uint reserves) external view virtual returns (uint);

    /**
      * @notice Calculates the current supply interest rate per block
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @param reserveFactorMantissa The current reserve factor the market has
      * @return The supply rate per block (as a percentage, and scaled by 1e18)
      */
    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) external view virtual returns (uint);

}

pragma solidity ^0.7.6;

import "./ProxyWithRegistry.sol";
import "./RegistryInterface.sol";

/**
 * @title DeFiPie's PErc20Delegator Contract
 * @notice PTokens which wrap an EIP-20 underlying and delegate to an implementation
 * @author DeFiPie
 */
contract PErc20Delegator is ProxyWithRegistry {

    /**
     * @notice Construct a new money market
     * @param underlying_ The address of the underlying asset
     * @param controller_ The address of the Controller
     * @param interestRateModel_ The address of the interest rate model
     * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
     * @param initialReserveFactorMantissa_ The initial reserve factor, scaled by 1e18
     * @param name_ ERC-20 name of this token
     * @param symbol_ ERC-20 symbol of this token
     * @param decimals_ ERC-20 decimal precision of this token
     * @param registry_ The address of the registry contract
     */
    constructor(
        address underlying_,
        address controller_,
        address interestRateModel_,
        uint initialExchangeRateMantissa_,
        uint initialReserveFactorMantissa_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address registry_
    ) {
        // Set registry
        _setRegistry(registry_);

        // First delegate gets to initialize the delegator (i.e. storage contract)
        delegateTo(_pTokenImplementation(), abi.encodeWithSignature("initialize(address,address,address,address,uint256,uint256,string,string,uint8)",
                                                            underlying_,
                                                            registry_,
                                                            controller_,
                                                            interestRateModel_,
                                                            initialExchangeRateMantissa_,
                                                            initialReserveFactorMantissa_,
                                                            name_,
                                                            symbol_,
                                                            decimals_));
    }

    /**
     * @notice Internal method to delegate execution to another contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     * @param callee The contract to delegatecall
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateTo(address callee, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returnData) = callee.delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize())
            }
        }
        return returnData;
    }

    function delegateAndReturn() internal returns (bytes memory) {
        (bool success, ) = _pTokenImplementation().delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize())

            switch success
            case 0 { revert(free_mem_ptr, returndatasize()) }
            default { return(free_mem_ptr, returndatasize()) }
        }
    }

    /**
     * @notice Delegates execution to an implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     */
    fallback() external {
        // delegate all other functions to current implementation
        delegateAndReturn();
    }
}

pragma solidity ^0.7.6;

import "./ProxyWithRegistry.sol";
import "./RegistryInterface.sol";
import "./ErrorReporter.sol";

/**
 * @title DeFiPie's PETHDelegator Contract
 * @notice PETH which wrap a delegate to an implementation
 * @author DeFiPie
 */
contract PETHDelegator is ImplementationStorage, ProxyWithRegistry, TokenErrorReporter {

    /**
      * @notice Emitted when implementation is changed
      */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
     * @notice Construct a new money market
     * @param pETHImplementation_ The address of the PEthImplementation
     * @param controller_ The address of the Controller
     * @param interestRateModel_ The address of the interest rate model
     * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
     * @param initialReserveFactorMantissa_ The initial reserve factor, scaled by 1e18
     * @param name_ ERC-20 name of this token
     * @param symbol_ ERC-20 symbol of this token
     * @param decimals_ ERC-20 decimal precision of this token
     * @param registry_ The address of the registry contract
     */
    constructor(
        address pETHImplementation_,
        address controller_,
        address interestRateModel_,
        uint initialExchangeRateMantissa_,
        uint initialReserveFactorMantissa_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address registry_
    ) {
        // Set registry
        _setRegistry(registry_);
        _setImplementation(pETHImplementation_);

        // First delegate gets to initialize the delegator (i.e. storage contract)
        delegateTo(implementation, abi.encodeWithSignature("initialize(address,address,address,uint256,uint256,string,string,uint8)",
                                                            registry_,
                                                            controller_,
                                                            interestRateModel_,
                                                            initialExchangeRateMantissa_,
                                                            initialReserveFactorMantissa_,
                                                            name_,
                                                            symbol_,
                                                            decimals_));
    }

    /**
     * @notice Internal method to delegate execution to another contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     * @param callee The contract to delegatecall
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateTo(address callee, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returnData) = callee.delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize())
            }
        }
        return returnData;
    }

    function delegateAndReturn() private returns (bytes memory) {
        (bool success, ) = implementation.delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize())

            switch success
            case 0 { revert(free_mem_ptr, returndatasize()) }
            default { return(free_mem_ptr, returndatasize()) }
        }
    }

    /**
     * @notice Delegates execution to an implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     */
    fallback() external payable {
        // delegate all other functions to current implementation
        delegateAndReturn();
    }

    receive() external payable {
        // delegate all other functions to current implementation
        delegateAndReturn();
    }

    function setImplementation(address newImplementation) external returns(uint) {
        if (msg.sender != RegistryInterface(registry).admin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_NEW_IMPLEMENTATION);
        }

        address oldImplementation = implementation;
        _setImplementation(newImplementation);

        emit NewImplementation(oldImplementation, implementation);

        return(uint(Error.NO_ERROR));
    }
}

pragma solidity ^0.7.6;

import "./ProxyWithRegistry.sol";
import "./RegistryInterface.sol";
import "./ErrorReporter.sol";

/**
 * @title DeFiPie's PPIEDelegator Contract
 * @notice PPIE which wrap an EIP-20 underlying and delegate to an implementation
 * @author DeFiPie
 */
contract PPIEDelegator is ImplementationStorage, ProxyWithRegistry, TokenErrorReporter {

    /**
      * @notice Emitted when implementation is changed
      */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
     * @notice Construct a new money market
     * @param underlying_ The address of the underlying asset
     * @param pPIEImplementation_ The address of the PPIEImplementation
     * @param controller_ The address of the Controller
     * @param interestRateModel_ The address of the interest rate model
     * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
     * @param initialReserveFactorMantissa_ The initial reserve factor, scaled by 1e18
     * @param name_ ERC-20 name of this token
     * @param symbol_ ERC-20 symbol of this token
     * @param decimals_ ERC-20 decimal precision of this token
     * @param registry_ The address of the registry contract
     */
    constructor(
        address underlying_,
        address pPIEImplementation_,
        address controller_,
        address interestRateModel_,
        uint initialExchangeRateMantissa_,
        uint initialReserveFactorMantissa_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address registry_
    ) {
        // Set registry
        _setRegistry(registry_);
        _setImplementation(pPIEImplementation_);

        // First delegate gets to initialize the delegator (i.e. storage contract)
        delegateTo(implementation, abi.encodeWithSignature("initialize(address,address,address,address,uint256,uint256,string,string,uint8)",
                                                        underlying_,
                                                        registry_,
                                                        controller_,
                                                        interestRateModel_,
                                                        initialExchangeRateMantissa_,
                                                        initialReserveFactorMantissa_,
                                                        name_,
                                                        symbol_,
                                                        decimals_));
    }

    /**
     * @notice Internal method to delegate execution to another contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     * @param callee The contract to delegatecall
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateTo(address callee, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returnData) = callee.delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize())
            }
        }
        return returnData;
    }

    function delegateAndReturn() internal returns (bytes memory) {
        (bool success, ) = implementation.delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize())

            switch success
            case 0 { revert(free_mem_ptr, returndatasize()) }
            default { return(free_mem_ptr, returndatasize()) }
        }
    }

    /**
     * @notice Delegates execution to an implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     */
    fallback() external {
        // delegate all other functions to current implementation
        delegateAndReturn();
    }

    function setImplementation(address newImplementation) external returns(uint) {
        if (msg.sender != RegistryInterface(registry).admin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_NEW_IMPLEMENTATION);
        }

        address oldImplementation = implementation;
        _setImplementation(newImplementation);

        emit NewImplementation(oldImplementation, implementation);

        return(uint(Error.NO_ERROR));
    }
}

pragma solidity ^0.7.6;

import './PErc20Delegator.sol';
import './RegistryInterface.sol';
import './EIP20Interface.sol';
import './Strings.sol';
import "./IPriceFeeds.sol";
import "./ErrorReporter.sol";
import "./SafeMath.sol";
import "./PEtherDelegator.sol";
import "./PPIEDelegator.sol";
import "./Controller.sol";
import "./UniswapPriceOracle.sol";

contract PTokenFactory is FactoryErrorReporter {
    using strings for *;
    using SafeMath for uint;

    UniswapPriceOracle public oracle;
    uint public minUniswapLiquidity;

    // decimals for pToken
    uint8 public decimals = 8;

    // default parameters for pToken
    address public controller;
    address public interestRateModel;
    uint256 public initialExchangeRateMantissa;
    uint256 public initialReserveFactorMantissa;

    /**
     * Fired on creation new pToken proxy
     * @param newPToken Address of new PToken proxy contract
     */
    event PTokenCreated(address newPToken);

    RegistryInterface public registry;

    constructor(
        RegistryInterface registry_,
        uint minUniswapLiquidity_,
        address oracle_,
        address _controller,
        address _interestRateModel,
        uint256 _initialExchangeRateMantissa,
        uint256 _initialReserveFactorMantissa
    ) {
        registry = registry_;
        minUniswapLiquidity = minUniswapLiquidity_;
        oracle = UniswapPriceOracle(oracle_);
        controller = _controller;
        interestRateModel = _interestRateModel;
        initialExchangeRateMantissa = _initialExchangeRateMantissa;
        initialReserveFactorMantissa = _initialReserveFactorMantissa;
    }

    /**
     * Creates new pToken proxy contract and adds pToken to the controller
     * @param underlying_ The address of the underlying asset
     */
    function createPToken(address underlying_) external returns (uint) {
        if (!checkPair(underlying_)) {
            return fail(Error.INVALID_POOL, FailureInfo.DEFICIENCY_LIQUIDITY_IN_POOL_OR_PAIR_IS_NOT_EXIST);
        }

        (string memory name, string memory symbol) = _createPTokenNameAndSymbol(underlying_);

        uint power = EIP20Interface(underlying_).decimals();
        uint exchangeRateMantissa = calcExchangeRate(power);

        PErc20Delegator newPToken = new PErc20Delegator(underlying_, controller, interestRateModel, exchangeRateMantissa, initialReserveFactorMantissa, name, symbol, decimals, address(registry));

        uint256 result = Controller(controller)._supportMarket(address(newPToken));
        if (result != 0) {
            return fail(Error.MARKET_NOT_LISTED, FailureInfo.SUPPORT_MARKET_BAD_RESULT);
        }

        registry.addPToken(underlying_, address(newPToken));

        emit PTokenCreated(address(newPToken));

        oracle.update(underlying_);

        return uint(Error.NO_ERROR);
    }

    function createPETH(address pETHImplementation_) external virtual returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.CREATE_PETH_POOL);
        }

        string memory name = "DeFiPie ETH";
        string memory symbol = "pETH";

        uint power = 18;
        uint exchangeRateMantissa = calcExchangeRate(power);

        PETHDelegator newPETH = new PETHDelegator(pETHImplementation_, controller, interestRateModel, exchangeRateMantissa, initialReserveFactorMantissa, name, symbol, decimals, address(registry));

        uint256 result = Controller(controller)._supportMarket(address(newPETH));
        if (result != 0) {
            return fail(Error.MARKET_NOT_LISTED, FailureInfo.SUPPORT_MARKET_BAD_RESULT);
        }

        registry.addPETH(address(newPETH));

        emit PTokenCreated(address(newPETH));

        return uint(Error.NO_ERROR);
    }

    function createPPIE(address underlying_, address pPIEImplementation_) external virtual returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.CREATE_PPIE_POOL);
        }

        string memory name = "DeFiPie PIE";
        string memory symbol = "pPIE";

        uint power = EIP20Interface(underlying_).decimals();
        uint exchangeRateMantissa = calcExchangeRate(power);

        PPIEDelegator newPPIE = new PPIEDelegator(underlying_, pPIEImplementation_, controller, interestRateModel, exchangeRateMantissa, initialReserveFactorMantissa, name, symbol, decimals, address(registry));

        uint256 result = Controller(controller)._supportMarket(address(newPPIE));
        if (result != 0) {
            return fail(Error.MARKET_NOT_LISTED, FailureInfo.SUPPORT_MARKET_BAD_RESULT);
        }

        registry.addPPIE(address(newPPIE));

        emit PTokenCreated(address(newPPIE));

        oracle.update(underlying_);

        return uint(Error.NO_ERROR);
    }

    function checkPair(address asset) public view returns (bool) {
        (address pair, uint112 ethEquivalentReserves) = oracle.searchPair(asset);

        return bool(pair != address(0) && ethEquivalentReserves >= minUniswapLiquidity);
    }

    function setMinUniswapLiquidity(uint minUniswapLiquidity_) public returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_MIN_LIQUIDITY_OWNER_CHECK);
        }

        minUniswapLiquidity = minUniswapLiquidity_;

        return uint(Error.NO_ERROR);
    }

    function setOracle(address oracle_) public returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_NEW_ORACLE);
        }

        oracle = UniswapPriceOracle(oracle_);

        return uint(Error.NO_ERROR);
    }

    /**
     *  Sets address of actual controller contract
     *  @return uint 0 = success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function setController(address newController) external returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_NEW_CONTROLLER);
        }
        controller = newController;

        return(uint(Error.NO_ERROR));
    }

    /**
     *  Sets address of actual interestRateModel contract
     *  @return uint 0 = success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function setInterestRateModel(address newInterestRateModel) external returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_NEW_INTEREST_RATE_MODEL);
        }

        interestRateModel = newInterestRateModel;

        return(uint(Error.NO_ERROR));
    }

    /**
     *  Sets initial exchange rate
     *  @return uint 0 = success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function setInitialExchangeRateMantissa(uint _initialExchangeRateMantissa) external returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_NEW_EXCHANGE_RATE);
        }

        initialExchangeRateMantissa = _initialExchangeRateMantissa;

        return(uint(Error.NO_ERROR));
    }

    function setInitialReserveFactorMantissa(uint _initialReserveFactorMantissa) external returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_NEW_RESERVE_FACTOR);
        }

        initialReserveFactorMantissa = _initialReserveFactorMantissa;

        return(uint(Error.NO_ERROR));
    }

    function setPTokenDecimals(uint _decimals) external returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_NEW_DECIMALS);
        }

        decimals = uint8(_decimals);

        return(uint(Error.NO_ERROR));
    }

    function getAdmin() public view returns(address payable) {
        return registry.admin();
    }

    function _createPTokenNameAndSymbol(address underlying) internal view returns (string memory, string memory) {
        string memory name = ("DeFiPie ".toSlice().concat(EIP20Interface(underlying).name().toSlice()));
        string memory symbol = ("p".toSlice().concat(EIP20Interface(underlying).symbol().toSlice()));
        return (name, symbol);
    }

    function calcExchangeRate(uint power) internal view returns (uint) {
        uint factor;

        if (decimals >= power) {
            factor = 10**(decimals - power);
            return initialExchangeRateMantissa.div(factor);
        } else {
            factor = 10**(power - decimals);
            return initialExchangeRateMantissa.mul(factor);
        }
    }
}

pragma solidity ^0.7.6;

import "./ControllerInterface.sol";
import "./InterestRateModel.sol";
import "./ProxyWithRegistry.sol";

contract PTokenStorage is ProxyWithRegistryStorage {
    /**
     * @dev Guard variable for re-entrancy checks
     */
    bool internal _notEntered;

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
     * @dev Maximum borrow rate that can ever be applied (.0005% / block)
     */

    uint internal constant borrowRateMaxMantissa = 0.0005e16;

    /**
     * @dev Maximum fraction of interest that can be set aside for reserves
     */
    uint internal constant reserveFactorMaxMantissa = 1e18;

    /**
     * @notice Contract which oversees inter-pToken operations
     */
    ControllerInterface public controller;

    /**
     * @notice Model which tells what the current interest rate should be
     */
    InterestRateModel public interestRateModel;

    /**
     * @dev Initial exchange rate used when minting the first PTokens (used when totalSupply = 0)
     */
    uint internal initialExchangeRateMantissa;

    /**
     * @notice Fraction of interest currently set aside for reserves
     */
    uint public reserveFactorMantissa;

    /**
     * @notice Block number that interest was last accrued at
     */
    uint public accrualBlockNumber;

    /**
     * @notice Accumulator of the total earned interest rate since the opening of the market
     */
    uint public borrowIndex;

    /**
     * @notice Total amount of outstanding borrows of the underlying in this market
     */
    uint public totalBorrows;

    /**
     * @notice Total amount of reserves of the underlying held in this market
     */
    uint public totalReserves;

    /**
     * @notice Total number of tokens in circulation
     */
    uint public totalSupply;

    /**
     * @dev Official record of token balances for each account
     */
    mapping (address => uint) internal accountTokens;

    /**
     * @dev Approved token transfer amounts on behalf of others
     */
    mapping (address => mapping (address => uint)) internal transferAllowances;

    /**
     * @notice Container for borrow balance information
     * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
     * @member interestIndex Global borrowIndex as of the most recent balance-changing action
     */
    struct BorrowSnapshot {
        uint principal;
        uint interestIndex;
    }

    /**
     * @dev Mapping of account addresses to outstanding borrow balances
     */
    mapping(address => BorrowSnapshot) internal accountBorrows;
}

abstract contract PTokenInterface is PTokenStorage {
    /**
     * @notice Indicator that this is a PToken contract (for inspection)
     */
    bool public constant isPToken = true;


    /*** Market Events ***/

    /**
     * @notice Event emitted when interest is accrued
     */
    event AccrueInterest(uint cashPrior, uint interestAccumulated, uint borrowIndex, uint totalBorrows, uint totalReserves);

    /**
     * @notice Event emitted when tokens are minted
     */
    event Mint(address minter, uint mintAmount, uint mintTokens);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint redeemAmount, uint redeemTokens);

    /**
     * @notice Event emitted when underlying is borrowed
     */
    event Borrow(address borrower, uint borrowAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(address payer, address borrower, uint repayAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is liquidated
     */
    event LiquidateBorrow(address liquidator, address borrower, uint repayAmount, address pTokenCollateral, uint seizeTokens);


    /*** Admin Events ***/

    /**
     * @notice Event emitted when controller is changed
     */
    event NewController(ControllerInterface oldController, ControllerInterface newController);

    /**
     * @notice Event emitted when interestRateModel is changed
     */
    event NewMarketInterestRateModel(InterestRateModel oldInterestRateModel, InterestRateModel newInterestRateModel);

    /**
     * @notice Event emitted when the reserve factor is changed
     */
    event NewReserveFactor(uint oldReserveFactorMantissa, uint newReserveFactorMantissa);

    /**
     * @notice Event emitted when the reserves are added
     */
    event ReservesAdded(address benefactor, uint addAmount, uint newTotalReserves);

    /**
     * @notice Event emitted when the reserves are reduced
     */
    event ReservesReduced(address admin, uint reduceAmount, uint newTotalReserves);

    /**
     * @notice EIP20 Transfer event
     */
    event Transfer(address indexed from, address indexed to, uint amount);

    /**
     * @notice EIP20 Approval event
     */
    event Approval(address indexed owner, address indexed spender, uint amount);

    /*** User Interface ***/

    function transfer(address dst, uint amount) external virtual returns (bool);
    function transferFrom(address src, address dst, uint amount) external virtual returns (bool);
    function approve(address spender, uint amount) external virtual returns (bool);
    function allowance(address owner, address spender) external view virtual returns (uint);
    function balanceOf(address owner) external view virtual returns (uint);
    function balanceOfUnderlying(address owner) external virtual returns (uint);
    function getAccountSnapshot(address account) external view virtual returns (uint, uint, uint, uint);
    function borrowRatePerBlock() external view virtual returns (uint);
    function supplyRatePerBlock() external view virtual returns (uint);
    function totalBorrowsCurrent() external virtual returns (uint);
    function borrowBalanceCurrent(address account) external virtual returns (uint);
    function borrowBalanceStored(address account) public view virtual returns (uint);
    function exchangeRateCurrent() public virtual returns (uint);
    function exchangeRateStored() public view virtual returns (uint);
    function getCash() external view virtual returns (uint);
    function accrueInterest() public virtual returns (uint);
    function seize(address liquidator, address borrower, uint seizeTokens) external virtual returns (uint);

    /*** Admin Functions ***/

    function _setController(ControllerInterface newController) public virtual returns (uint);
    function _setReserveFactor(uint newReserveFactorMantissa) external virtual returns (uint);
    function _reduceReserves(uint reduceAmount) external virtual returns (uint);
    function _setInterestRateModel(InterestRateModel newInterestRateModel) public virtual returns (uint);
}

contract PErc20Storage {
    /**
     * @notice Underlying asset for this PToken
     */
    address public underlying;
}

abstract contract PErc20Interface is PErc20Storage {

    /*** User Interface ***/

    function mint(uint mintAmount) external virtual returns (uint);
    function redeem(uint redeemTokens) external virtual returns (uint);
    function redeemUnderlying(uint redeemAmount) external virtual returns (uint);
    function borrow(uint borrowAmount) external virtual returns (uint);
    function repayBorrow(uint repayAmount) external virtual returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) external virtual returns (uint);
    function liquidateBorrow(address borrower, uint repayAmount, PTokenInterface pTokenCollateral) external virtual returns (uint);

    /*** Admin Functions ***/

    function _addReserves(uint addAmount) external virtual returns (uint);
}

contract PPIEStorage {
    /// @notice A record of each accounts delegate
    mapping (address => address) public delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;
}

abstract contract PPIEInterface is PPIEStorage {
    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    function delegate(address delegatee) external virtual;
    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) external virtual;
    function getCurrentVotes(address account) external view virtual returns (uint96);
    function getPriorVotes(address account, uint blockNumber) external view virtual returns (uint96);
}

pragma solidity ^0.7.6;

abstract contract PriceOracle {
    /// @notice Indicator that this is a PriceOracle contract (for inspection)
    bool public constant isPriceOracle = true;

    event PriceUpdated(address asset, uint price);

    /**
      * @notice Get the underlying price of a pToken asset
      * @param pToken The pToken to get the underlying price of
      * @return The underlying asset price mantissa (scaled by 1e18).
      *  Zero means the price is unavailable.
      */
    function getUnderlyingPrice(address pToken) external view virtual returns (uint);

    function updateUnderlyingPrice(address pToken) external virtual returns (uint);
}

pragma solidity ^0.7.6;

import "./RegistryInterface.sol";

contract ProxyWithRegistryStorage {

    /**
     * @notice Address of the registry contract
     */
    address public registry;
}

abstract contract ProxyWithRegistryInterface is ProxyWithRegistryStorage {
    function _setRegistry(address _registry) internal virtual;
    function _pTokenImplementation() internal view virtual returns (address);
}

contract ProxyWithRegistry is ProxyWithRegistryInterface {
    /**
     *  Returns actual address of the implementation contract from current registry
     *  @return registry Address of the registry
     */
    function _pTokenImplementation() internal view override returns (address) {
        return RegistryInterface(registry).pTokenImplementation();
    }

    function _setRegistry(address _registry) internal override {
        registry = _registry;
    }
}

contract ImplementationStorage {

    address public implementation;

    function _setImplementation(address implementation_) internal {
        implementation = implementation_;
    }
}

pragma solidity ^0.7.6;

import "./PTokenInterfaces.sol";
import './RegistryStorage.sol';
import "./ErrorReporter.sol";
import "./Controller.sol";
import "./PTokenFactory.sol";

contract Registry is RegistryStorage, RegistryErrorReporter {

    address public factory;
    address public pTokenImplementation;

    mapping (address => address) public pTokens;
    address public pETH;
    address public pPIE;

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
      * @notice Emitted when PTokenImplementation is changed
      */
    event NewPTokenImplementation(address oldImplementation, address newImplementation);

    /**
      * @notice Emitted when Factory address is changed
      */
    event NewFactory(address oldFactory, address newFactory);

    /**
      * @notice Emitted when admin remove pToken
      */
    event RemovePToken(address pToken);

    constructor() {}

    function initialize(address _pTokenImplementation) public {
        require(pTokenImplementation == address(0), "Registry may only be initialized once");

        pTokenImplementation = _pTokenImplementation;
    }

    /**
     *  Sets address of actual pToken implementation contract
     *  @return uint 0 = success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function setPTokenImplementation(address newImplementation) external returns (uint) {
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_NEW_IMPLEMENTATION);
        }

        address oldImplementation = pTokenImplementation;
        pTokenImplementation = newImplementation;

        emit NewPTokenImplementation(oldImplementation, pTokenImplementation);

        return(uint(Error.NO_ERROR));
    }

    function _setFactoryContract(address _factory) external returns (uint) {
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_NEW_FACTORY);
        }

        address oldFactory = factory;
        factory = _factory;

        emit NewFactory(oldFactory, factory);

        return uint(Error.NO_ERROR);
    }

    function addPToken(address underlying, address pToken) public returns (uint) {
        require(msg.sender == admin || msg.sender == factory, "Only admin or factory can add PTokens");

        PTokenInterface(pToken).isPToken(); // Sanity check to make sure its really a PToken

        require(pTokens[underlying] == address(0), "Token already added");
        pTokens[underlying] = pToken;

        return uint(Error.NO_ERROR);
    }

    function addPETH(address pETH_) public returns (uint) {
        require(msg.sender == admin || msg.sender == factory, "Only admin or factory can add PETH");

        PTokenInterface(pETH_).isPToken(); // Sanity check to make sure its really a PToken

        require(pETH == address(0), "ETH already added");
        pETH = pETH_;

        return uint(Error.NO_ERROR);
    }

    function addPPIE(address pPIE_) public returns (uint) {
        require(msg.sender == admin || msg.sender == factory, "Only admin or factory can add PPIE");

        PTokenInterface(pPIE_).isPToken(); // Sanity check to make sure its really a PToken

        require(pPIE == address(0), "PIE already added");
        pPIE = pPIE_;

        address underlying = PErc20Storage(pPIE).underlying();
        pTokens[underlying] = pPIE;

        return uint(Error.NO_ERROR);
    }

    function removePToken(address pToken) public returns (uint) {
        require(msg.sender == admin, "Only admin can remove PTokens");

        PTokenInterface(pToken).isPToken(); // Sanity check to make sure its really a PToken

        address underlying = PErc20Storage(pToken).underlying();
        require(pTokens[underlying] != address(0), "Token not added");
        delete pTokens[underlying];

        emit RemovePToken(pToken);

        return uint(Error.NO_ERROR);
    }
}

pragma solidity ^0.7.6;

interface RegistryInterface {

    /**
     *  Returns admin address for cToken contracts
     *  @return admin address
     */
    function admin() external view returns (address payable);

    /**
     *  Returns address of actual PToken implementation contract
     *  @return Address of contract
     */
    function pTokenImplementation() external view returns (address);

    function addPToken(address underlying, address pToken) external returns(uint);
    function addPETH(address pETH_) external returns(uint);
    function addPPIE(address pPIE_) external returns(uint);
}

pragma solidity ^0.7.6;

contract RegistryStorage {
    address public implementation;
    address public admin;
    address public pendingAdmin;
}

pragma solidity ^0.7.6;

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/Math.sol
// Subject to the MIT license.

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
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
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
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
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
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
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
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
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
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
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
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <[email protected]>
 *
 * @dev Functionality in this library is largely implemented using an
 *      abstraction called a 'slice'. A slice represents a part of a string -
 *      anything from the entire string to a single character, or even no
 *      characters at all (a 0-length slice). Since a slice only has to specify
 *      an offset and a length, copying and manipulating slices is a lot less
 *      expensive than copying and manipulating the strings they reference.
 *
 *      To further reduce gas costs, most functions on slice that need to return
 *      a slice modify the original one instead of allocating a new one; for
 *      instance, `s.split(".")` will return the text up to the first '.',
 *      modifying s to only contain the remainder of the string after the '.'.
 *      In situations where you do not want to modify the original slice, you
 *      can make a copy first with `.copy()`, for example:
 *      `s.copy().split(".")`. Try and avoid using this idiom in loops; since
 *      Solidity has no memory management, it will result in allocating many
 *      short-lived slices that are later discarded.
 *
 *      Functions that return two slices come in two versions: a non-allocating
 *      version that takes the second slice as an argument, modifying it in
 *      place, and an allocating version that allocates and returns the second
 *      slice; see `nextRune` for example.
 *
 *      Functions that have to copy string data will return strings rather than
 *      slices; these can be cast back to slices for further processing if
 *      required.
 *
 *      For convenience, some functions are provided with non-modifying
 *      variants that create a new slice and return both; for instance,
 *      `s.splitNew('.')` leaves s unmodified, and returns two values
 *      corresponding to the left and right parts of the string.
 */

pragma solidity ^0.7.6;

library strings {
    struct slice {
        uint _len;
        uint _ptr;
    }

    function memcpy(uint dest, uint src, uint leng) private pure {
        // Copy word-length chunks while possible
        for(; leng >= 32; leng -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - leng) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    /*
     * @dev Returns the length of a null-terminated bytes32 string.
     * @param self The value to find the length of.
     * @return The length of the string, from 0 to 32.
     */
    function len(bytes32 self) internal pure returns (uint) {
        uint ret;
        if (self == 0)
            return 0;
        if (uint(self) & 0xffffffffffffffffffffffffffffffff == 0) {
            ret += 16;
            self = bytes32(uint(self) / 0x100000000000000000000000000000000);
        }
        if (uint(self) & 0xffffffffffffffff == 0) {
            ret += 8;
            self = bytes32(uint(self) / 0x10000000000000000);
        }
        if (uint(self) & 0xffffffff == 0) {
            ret += 4;
            self = bytes32(uint(self) / 0x100000000);
        }
        if (uint(self) & 0xffff == 0) {
            ret += 2;
            self = bytes32(uint(self) / 0x10000);
        }
        if (uint(self) & 0xff == 0) {
            ret += 1;
        }
        return 32 - ret;
    }

    /*
     * @dev Returns a slice containing the entire bytes32, interpreted as a
     *      null-terminated utf-8 string.
     * @param self The bytes32 value to convert to a slice.
     * @return A new slice containing the value of the input argument up to the
     *         first null.
     */
    function toSliceB32(bytes32 self) internal pure returns (slice memory ret) {
        // Allocate space for `self` in memory, copy it there, and point ret at it
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            mstore(ptr, self)
            mstore(add(ret, 0x20), ptr)
        }
        ret._len = len(self);
    }

    /*
     * @dev Returns a new slice containing the same data as the current slice.
     * @param self The slice to copy.
     * @return A new slice containing the same data as `self`.
     */
    function copy(slice memory self) internal pure returns (slice memory) {
        return slice(self._len, self._ptr);
    }

    /*
     * @dev Copies a slice to a new string.
     * @param self The slice to copy.
     * @return A newly allocated string containing the slice's text.
     */
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

    /*
     * @dev Returns the length in runes of the slice. Note that this operation
     *      takes time proportional to the length of the slice; avoid using it
     *      in loops, and call `slice.empty()` if you only need to know whether
     *      the slice is empty or not.
     * @param self The slice to operate on.
     * @return The length of the slice in runes.
     */
    function len(slice memory self) internal pure returns (uint l) {
        // Starting at ptr-31 means the LSB will be the byte we care about
        uint ptr = self._ptr - 31;
        uint end = ptr + self._len;
        for (l = 0; ptr < end; l++) {
            uint8 b;
            assembly { b := and(mload(ptr), 0xFF) }
            if (b < 0x80) {
                ptr += 1;
            } else if(b < 0xE0) {
                ptr += 2;
            } else if(b < 0xF0) {
                ptr += 3;
            } else if(b < 0xF8) {
                ptr += 4;
            } else if(b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }

    /*
     * @dev Returns true if the slice is empty (has a length of 0).
     * @param self The slice to operate on.
     * @return True if the slice is empty, False otherwise.
     */
    function empty(slice memory self) internal pure returns (bool) {
        return self._len == 0;
    }

    /*
     * @dev Returns a negative number if `other` comes lexicographically after
     *      `self`, a positive number if it comes before, or zero if the
     *      contents of the two slices are equal. Comparison is done per-rune,
     *      on unicode codepoints.
     * @param self The first slice to compare.
     * @param other The second slice to compare.
     * @return The result of the comparison.
     */
    function compare(slice memory self, slice memory other) internal pure returns (int) {
        uint shortest = self._len;
        if (other._len < self._len)
            shortest = other._len;

        uint selfptr = self._ptr;
        uint otherptr = other._ptr;
        for (uint idx = 0; idx < shortest; idx += 32) {
            uint a;
            uint b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                // Mask out irrelevant bytes and check again
                uint256 mask = uint256(-1); // 0xffff...
                if(shortest < 32) {
                    mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                }
                uint256 diff = (a & mask) - (b & mask);
                if (diff != 0)
                    return int(diff);
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int(self._len) - int(other._len);
    }

    /*
     * @dev Returns true if the two slices contain the same text.
     * @param self The first slice to compare.
     * @param self The second slice to compare.
     * @return True if the slices are equal, false otherwise.
     */
    function equals(slice memory self, slice memory other) internal pure returns (bool) {
        return compare(self, other) == 0;
    }

    /*
     * @dev Extracts the first rune in the slice into `rune`, advancing the
     *      slice to point to the next rune and returning `self`.
     * @param self The slice to operate on.
     * @param rune The slice that will contain the first rune.
     * @return `rune`.
     */
    function nextRune(slice memory self, slice memory rune) internal pure returns (slice memory) {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint l;
        uint b;
        // Load the first byte of the rune into the LSBs of b
        assembly { b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF) }
        if (b < 0x80) {
            l = 1;
        } else if(b < 0xE0) {
            l = 2;
        } else if(b < 0xF0) {
            l = 3;
        } else {
            l = 4;
        }

        // Check for truncated codepoints
        if (l > self._len) {
            rune._len = self._len;
            self._ptr += self._len;
            self._len = 0;
            return rune;
        }

        self._ptr += l;
        self._len -= l;
        rune._len = l;
        return rune;
    }

    /*
     * @dev Returns the first rune in the slice, advancing the slice to point
     *      to the next rune.
     * @param self The slice to operate on.
     * @return A slice containing only the first rune from `self`.
     */
    function nextRune(slice memory self) internal pure returns (slice memory ret) {
        nextRune(self, ret);
    }

    /*
     * @dev Returns the number of the first codepoint in the slice.
     * @param self The slice to operate on.
     * @return The number of the first codepoint in the slice.
     */
    function ord(slice memory self) internal pure returns (uint ret) {
        if (self._len == 0) {
            return 0;
        }

        uint word;
        uint length;
        uint divisor = 2 ** 248;

        // Load the rune into the MSBs of b
        assembly { word:= mload(mload(add(self, 32))) }
        uint b = word / divisor;
        if (b < 0x80) {
            ret = b;
            length = 1;
        } else if(b < 0xE0) {
            ret = b & 0x1F;
            length = 2;
        } else if(b < 0xF0) {
            ret = b & 0x0F;
            length = 3;
        } else {
            ret = b & 0x07;
            length = 4;
        }

        // Check for truncated codepoints
        if (length > self._len) {
            return 0;
        }

        for (uint i = 1; i < length; i++) {
            divisor = divisor / 256;
            b = (word / divisor) & 0xFF;
            if (b & 0xC0 != 0x80) {
                // Invalid UTF-8 sequence
                return 0;
            }
            ret = (ret * 64) | (b & 0x3F);
        }

        return ret;
    }

    /*
     * @dev Returns the keccak-256 hash of the slice.
     * @param self The slice to hash.
     * @return The hash of the slice.
     */
    function keccak(slice memory self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

    /*
     * @dev Returns true if `self` starts with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function startsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        if (self._ptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let selfptr := mload(add(self, 0x20))
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }
        return equal;
    }

    /*
     * @dev If `self` starts with `needle`, `needle` is removed from the
     *      beginning of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function beyond(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
            self._ptr += needle._len;
        }

        return self;
    }

    /*
     * @dev Returns true if the slice ends with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function endsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        uint selfptr = self._ptr + self._len - needle._len;

        if (selfptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }

        return equal;
    }

    /*
     * @dev If `self` ends with `needle`, `needle` is removed from the
     *      end of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function until(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        uint selfptr = self._ptr + self._len - needle._len;
        bool equal = true;
        if (selfptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
        }

        return self;
    }

    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr = selfptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                uint end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr >= end)
                        return selfptr + selflen;
                    ptr++;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    // Returns the memory address of the first byte after the last occurrence of
    // `needle` in `self`, or the address of `self` if not found.
    function rfindPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                ptr = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr <= selfptr)
                        return selfptr;
                    ptr--;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr + needlelen;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr + needlelen;
                    ptr -= 1;
                }
            }
        }
        return selfptr;
    }

    /*
     * @dev Modifies `self` to contain everything from the first occurrence of
     *      `needle` to the end of the slice. `self` is set to the empty slice
     *      if `needle` is not found.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function find(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len -= ptr - self._ptr;
        self._ptr = ptr;
        return self;
    }

    /*
     * @dev Modifies `self` to contain the part of the string from the start of
     *      `self` to the end of the first occurrence of `needle`. If `needle`
     *      is not found, `self` is set to the empty slice.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function rfind(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len = ptr - self._ptr;
        return self;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and `token` to everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function split(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and returning everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` up to the first occurrence of `delim`.
     */
    function split(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        split(self, needle, token);
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and `token` to everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function rsplit(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = ptr;
        token._len = self._len - (ptr - self._ptr);
        if (ptr == self._ptr) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and returning everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` after the last occurrence of `delim`.
     */
    function rsplit(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        rsplit(self, needle, token);
    }

    /*
     * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return The number of occurrences of `needle` found in `self`.
     */
    function count(slice memory self, slice memory needle) internal pure returns (uint cnt) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
    }

    /*
     * @dev Returns True if `self` contains `needle`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return True if `needle` is found in `self`, false otherwise.
     */
    function contains(slice memory self, slice memory needle) internal pure returns (bool) {
        return rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
    }

    /*
     * @dev Returns a newly allocated string containing the concatenation of
     *      `self` and `other`.
     * @param self The first slice to concatenate.
     * @param other The second slice to concatenate.
     * @return The concatenation of the two strings.
     */
    function concat(slice memory self, slice memory other) internal pure returns (string memory) {
        string memory ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

    /*
     * @dev Joins an array of slices, using `self` as a delimiter, returning a
     *      newly allocated string.
     * @param self The delimiter to use.
     * @param parts A list of slices to join.
     * @return A newly allocated string containing all the slices in `parts`,
     *         joined with `self`.
     */
    function join(slice memory self, slice[] memory parts) internal pure returns (string memory) {
        if (parts.length == 0)
            return "";

        uint length = self._len * (parts.length - 1);
        for(uint i = 0; i < parts.length; i++)
            length += parts[i]._len;

        string memory ret = new string(length);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        for(uint i = 0; i < parts.length; i++) {
            memcpy(retptr, parts[i]._ptr, parts[i]._len);
            retptr += parts[i]._len;
            if (i < parts.length - 1) {
                memcpy(retptr, self._ptr, self._len);
                retptr += self._len;
            }
        }

        return ret;
    }
}

pragma solidity ^0.7.6;
pragma abicoder v2;

import "./PriceOracle.sol";
import "./ErrorReporter.sol";
import "./PTokenInterfaces.sol";
import "./SafeMath.sol";
import "./UniswapPriceOracleStorage.sol";
import "./EIP20Interface.sol";
import "./Controller.sol";
import "./PTokenFactory.sol";

contract UniswapPriceOracle is UniswapPriceOracleStorageV1, PriceOracle, OracleErrorReporter {
    using FixedPoint for *;
    using SafeMath for uint;

    event PoolAdded(uint id, address poolFactory);
    event PoolRemoved(uint id, address poolFactory);
    event PoolUpdated(uint id, address poolFactory);

    event StableCoinAdded(uint id, address coin);
    event StableCoinRemoved(uint id, address coin);
    event StableCoinUpdated(uint id, address coin);

    event AssetPairUpdated(address asset, address pair);

    constructor() {}

    function initialize(
        address poolFactory_,
        address WETHToken_,
        address ETHUSDPriceFeed_
    )
        public
    {
        require(
            WETHToken == address(0) &&
            ETHUSDPriceFeed == address(0)
            , "Oracle: may only be initialized once"
        );

        WETHToken = WETHToken_;
        ETHUSDPriceFeed = ETHUSDPriceFeed_;

        require(
            poolFactory_ != address(0)
            , 'Oracle: invalid address for factory'
        );

        poolFactories.push(poolFactory_);

        emit PoolAdded(0, poolFactory_);
    }

    function updateUnderlyingPrice(address pToken) public override returns (uint) {
        if (pToken == Registry(registry).pETH()) {
            return uint(Error.NO_ERROR);
        }

        address asset = PErc20Interface(pToken).underlying();

        return update(asset);
    }

    // Get the most recent price for a asset in USD with 18 decimals of precision.
    function getPriceInUSD(address asset) public view virtual returns (uint) {
        uint ETHUSDPrice = uint(AggregatorInterface(ETHUSDPriceFeed).latestAnswer());
        uint AssetETHCourse = getCourseInETH(asset);

        // div 1e8 is chainlink precision for ETH
        return ETHUSDPrice.mul(AssetETHCourse).div(1e8);
    }

    function getCourseInETH(address asset) public view returns (uint) {
        if (asset == Registry(registry).pETH()) {
            // ether always worth 1
            return 1e18;
        }

        return averagePrices[asset];
    }

    function update(address asset) public returns (uint) {
        uint112 reserve0;
        uint112 reserve1;
        uint32 blockTimeStamp;
        address pair;

        if (isNewAsset(asset)) {
            if (assetPair[asset] == address(0)) {
                // first update from factory or other users
                (pair, ) = searchPair(asset);
            } else {
                // after updatePair function
                pair = assetPair[asset];
            }

            if (pair != address(0)) {
                assetPair[asset] = pair;

                (reserve0, reserve1, blockTimeStamp) = getReservesFromPair(asset);

                if (reserve1 < minReserveLiquidity) {
                    return fail(Error.UPDATE_PRICE, FailureInfo.NO_RESERVES);
                }

                cumulativePrices[pair][asset].priceAverage = FixedPoint.uq112x112(uqdiv(encode(reserve1), reserve0));
            } else {
                return fail(Error.UPDATE_PRICE, FailureInfo.NO_PAIR);
            }
        } else {
            // second and next updates
            (, , blockTimeStamp) = getReservesFromPair(asset);

            if (reserve1 < minReserveLiquidity) {
                cumulativePrices[assetPair[asset]][asset].priceAverage._x = 0;
                cumulativePrices[assetPair[asset]][asset].priceCumulativePrevious = 0;
                cumulativePrices[assetPair[asset]][asset].blockTimeStampPrevious = 0;

                return fail(Error.UPDATE_PRICE, FailureInfo.NO_RESERVES);
            }

            if (!isPeriodElapsed(asset)) {
                return fail(Error.UPDATE_PRICE, FailureInfo.PERIOD_NOT_ELAPSED);
            }

            pair = assetPair[asset];

            uint32 timeElapsed = blockTimeStamp - cumulativePrices[pair][asset].blockTimeStampPrevious;

            // overflow is desired, casting never truncates
            // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
            if (asset == IUniswapV2Pair(pair).token0()) {
                cumulativePrices[pair][asset].priceAverage = FixedPoint.uq112x112(uint224((IUniswapV2Pair(pair).price0CumulativeLast() - cumulativePrices[pair][asset].priceCumulativePrevious) / timeElapsed));
            } else {
                cumulativePrices[pair][asset].priceAverage = FixedPoint.uq112x112(uint224((IUniswapV2Pair(pair).price1CumulativeLast() - cumulativePrices[pair][asset].priceCumulativePrevious) / timeElapsed));
            }
        }

        cumulativePrices[pair][asset].blockTimeStampPrevious = blockTimeStamp;

        // update data
        if (asset == IUniswapV2Pair(pair).token0()) {
            cumulativePrices[pair][asset].priceCumulativePrevious = IUniswapV2Pair(pair).price0CumulativeLast();
        } else {
            cumulativePrices[pair][asset].priceCumulativePrevious = IUniswapV2Pair(pair).price1CumulativeLast();
        }

        averagePrices[asset] = calcCourseInETH(asset);

        emit PriceUpdated(asset, getCourseInETH(asset));

        return uint(Error.NO_ERROR);
    }

    function checkAndUpdateAllNewAssets() public {
        PTokenFactory factory = PTokenFactory(Registry(registry).factory());
        Controller controller = Controller(factory.controller());

        address[] memory allMarkets = Controller(controller).getAllMarkets();

        updateNewAssets(allMarkets);
    }

    function updateNewAssets(address[] memory pTokens) public {
        address asset;

        for(uint i = 0; i < pTokens.length; i++) {
            if (pTokens[i] == Registry(registry).pETH()) {
                continue;
            }

            asset = PErc20Interface(pTokens[i]).underlying();

            if (isNewAsset(asset)) {
                update(asset);
            }
        }
    }

    function getUnderlyingPrice(address pToken) public view override virtual returns (uint) {
        if (pToken == Registry(registry).pETH()) {
            return getPriceInUSD(Registry(registry).pETH());
        }

        address asset = PErc20Interface(pToken).underlying();
        uint price = getPriceInUSD(asset);
        uint decimals = EIP20Interface(asset).decimals();

        return price.mul(10 ** (36 - decimals)).div(1e18);
    }

    function isNewAsset(address asset) public view returns (bool) {
        return bool(cumulativePrices[assetPair[asset]][asset].blockTimeStampPrevious == 0);
    }

    function getPoolPair(address asset, uint poolId) public view returns (address) {
        IUniswapV2Factory factory = IUniswapV2Factory(poolFactories[poolId]);

        return factory.getPair(WETHToken, asset);
    }

    function getPoolPairWithStableCoin(address asset, uint poolId, uint stableCoinId) public view returns (address) {
        IUniswapV2Factory factory = IUniswapV2Factory(poolFactories[poolId]);

        return factory.getPair(stableCoins[stableCoinId], asset);
    }

    function getReservesFromPair(address asset) public view returns (uint112, uint112, uint32) {
        uint112 assetReserve;
        uint112 ethOrCoinReserves;
        uint32 blockTimeStamp;

        IUniswapV2Pair pair = IUniswapV2Pair(assetPair[asset]);

        address token0 = pair.token0();

        if (token0 == asset) {
            (assetReserve, ethOrCoinReserves, blockTimeStamp) = pair.getReserves();
        } else {
            (ethOrCoinReserves, assetReserve, blockTimeStamp) = pair.getReserves();
        }

        return (assetReserve, ethOrCoinReserves, blockTimeStamp);
    }

    function isPeriodElapsed(address asset) public view returns (bool) {
        IUniswapV2Pair pair = IUniswapV2Pair(assetPair[asset]);

        ( , , uint32 blockTimeStamp) = pair.getReserves();

        uint timeElapsed = uint(blockTimeStamp).sub(uint(cumulativePrices[assetPair[asset]][asset].blockTimeStampPrevious));

        return bool(timeElapsed > period);
    }

    function calcCourseInETH(address asset) public view returns (uint) {
        if (asset == Registry(registry).pETH()) {
            // ether always worth 1
            return 1e18;
        }

        uint power = EIP20Interface(asset).decimals();
        uint amountIn = 10**power;

        return getETHAmount(asset, amountIn);
    }

    function getETHAmount(address asset, uint amountIn) public view returns (uint) {
        address pair = assetPair[asset];

        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();

        uint power;
        uint result = cumulativePrices[pair][asset].priceAverage.mul(amountIn).decode144();

        if (token0 == WETHToken || token1 == WETHToken) {
            // asset and weth pool
            return result;
        } else {
            // asset and stable coin pool
            if (token0 == asset) {
                power = EIP20Interface(token1).decimals();
                return result.mul(getCourseInETH(token1)).div(10**power);
            } else {
                power = EIP20Interface(token0).decimals();
                return result.mul(getCourseInETH(token0)).div(10**power);
            }
        }
    }

    function searchPair(address asset) public view returns (address, uint112) {
        address pair;
        uint112 maxReserves;

        IUniswapV2Pair tempPair;
        uint112 ETHReserves;

        for (uint i = 0; i < poolFactories.length; i++) {
            tempPair = IUniswapV2Pair(getPoolPair(asset, i));

            if (address(tempPair) != address(0)) {
                if (tempPair.token0() == asset) {
                    (, ETHReserves, ) = tempPair.getReserves();
                } else {
                    (ETHReserves, , ) = tempPair.getReserves();
                }

                if (ETHReserves > maxReserves) {
                    maxReserves = ETHReserves;
                    pair = address(tempPair);
                }
            }

            for (uint j = 0; j < stableCoins.length; j++) {
                tempPair = IUniswapV2Pair(getPoolPairWithStableCoin(asset, i, j));

                if (address(tempPair) != address(0)) {
                    uint112 stableCoinReserve;
                    uint power;

                    address token0 = tempPair.token0();
                    address token1 = tempPair.token1();

                    if (token0 == asset) {
                        (, stableCoinReserve,) = tempPair.getReserves();
                        power = EIP20Interface(token1).decimals();
                        ETHReserves = uint112(getCourseInETH(token1) * stableCoinReserve / (10**power));
                    } else {
                        (stableCoinReserve, , ) = tempPair.getReserves();
                        power = EIP20Interface(token0).decimals();
                        ETHReserves = uint112(getCourseInETH(token0) * stableCoinReserve / (10**power));
                    }

                    if (ETHReserves > maxReserves) {
                        maxReserves = ETHReserves;
                        pair = address(tempPair);
                    }
                }
            }
        }

        return (pair, maxReserves);
    }

    function _setNewAddresses(address WETHToken_, address ETHUSDPriceFeed_) external returns (uint) {
        // Check caller = admin
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.UPDATE_DATA);
        }

        WETHToken = WETHToken_;
        ETHUSDPriceFeed = ETHUSDPriceFeed_;

        return uint(Error.NO_ERROR);
    }

    function _setMinReserveLiquidity(uint minReserveLiquidity_) public returns (uint) {
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.UPDATE_DATA);
        }

        minReserveLiquidity = minReserveLiquidity_;

        return uint(Error.NO_ERROR);
    }

    function _setPeriod(uint period_) public returns (uint) {
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.UPDATE_DATA);
        }

        period = period_;

        return uint(Error.NO_ERROR);
    }

    function _addPool(address poolFactory_) public returns (uint) {
        // Check caller = admin
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ADD_POOL_OR_COIN);
        }

        require(
            poolFactory_ != address(0)
            , 'Oracle: invalid address for factory'
        );

        for (uint i = 0; i < poolFactories.length; i++) {
            if (poolFactories[i] == poolFactory_) {
                return fail(Error.POOL_OR_COIN_EXIST, FailureInfo.ADD_POOL_OR_COIN);
            }
        }

        poolFactories.push(poolFactory_);
        uint poolId = poolFactories.length - 1;

        emit PoolAdded(poolId, poolFactory_);

        return uint(Error.NO_ERROR);
    }

    function _removePool(uint poolId) public returns (uint) {
        // Check caller = admin
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.UPDATE_DATA);
        }

        require(
            poolFactories.length > 1
            , 'Oracle: must have one pool'
        );

        uint lastId = poolFactories.length - 1;

        address factory = poolFactories[lastId];
        poolFactories.pop();
        emit PoolRemoved(lastId, factory);

        if (lastId != poolId) {
            poolFactories[poolId] = factory;
            emit PoolUpdated(poolId, factory);
        }

        return uint(Error.NO_ERROR);
    }

    function _updatePool(uint poolId, address poolFactory_) public returns (uint) {
        // Check caller = admin
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.UPDATE_DATA);
        }

        require(
            poolFactory_ != address(0)
            , 'Oracle: invalid address for factory'
        );

        for (uint i = 0; i < poolFactories.length; i++) {
            if (poolFactories[i] == poolFactory_) {
                return fail(Error.POOL_OR_COIN_EXIST, FailureInfo.UPDATE_DATA);
            }
        }

        poolFactories[poolId] = poolFactory_;

        emit PoolUpdated(poolId, poolFactory_);

        return uint(Error.NO_ERROR);
    }

    function _addStableCoin(address stableCoin_) public returns (uint) {
        // Check caller = admin
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ADD_POOL_OR_COIN);
        }

        require(
            stableCoin_ != address(0)
            , 'Oracle: invalid address for stable coin'
        );

        for (uint i = 0; i < stableCoins.length; i++) {
            if (stableCoins[i] == stableCoin_) {
                return fail(Error.POOL_OR_COIN_EXIST, FailureInfo.ADD_POOL_OR_COIN);
            }
        }

        stableCoins.push(stableCoin_);

        emit StableCoinAdded(stableCoins.length - 1, stableCoin_);

        return uint(Error.NO_ERROR);
    }

    function _removeStableCoin(uint coinId) public returns (uint) {
        // Check caller = admin
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.UPDATE_DATA);
        }

        require(
            stableCoins.length > 0
            , 'Oracle: stable coins are empty'
        );


        uint lastId = stableCoins.length - 1;

        address stableCoin = stableCoins[lastId];
        stableCoins.pop();
        emit StableCoinRemoved(lastId, stableCoin);

        if (lastId != coinId) {
            stableCoins[coinId] = stableCoin;
            emit StableCoinUpdated(coinId, stableCoin);
        }

        return uint(Error.NO_ERROR);
    }

    function _updateStableCoin(uint coinId, address stableCoin_) public returns (uint) {
        // Check caller = admin
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.UPDATE_DATA);
        }

        require(
            stableCoin_ != address(0)
            , 'Oracle: invalid address for stable coin'
        );

        for (uint i = 0; i < stableCoins.length; i++) {
            if (stableCoins[i] == stableCoin_) {
                return fail(Error.POOL_OR_COIN_EXIST, FailureInfo.UPDATE_DATA);
            }
        }

        stableCoins[coinId] = stableCoin_;

        emit StableCoinUpdated(coinId, stableCoin_);

        return uint(Error.NO_ERROR);
    }

    function _updateAssetPair(address asset, address pair) public returns (uint) {
        // Check caller = admin
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.UPDATE_DATA);
        }

        require(
            pair != address(0)
            , 'Oracle: invalid address for pair'
        );

        cumulativePrices[assetPair[asset]][asset].priceAverage._x = 0;
        cumulativePrices[assetPair[asset]][asset].priceCumulativePrevious = 0;
        cumulativePrices[assetPair[asset]][asset].blockTimeStampPrevious = 0;

        assetPair[asset] = pair;

        emit AssetPairUpdated(asset, pair);

        return update(asset);
    }

    function getAllPoolFactories() public view returns (address[] memory) {
        return poolFactories;
    }

    function getAllStableCoins() public view returns (address[] memory) {
        return stableCoins;
    }

    function getMyAdmin() public view returns (address) {
        return Registry(registry).admin();
    }

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal view returns (uint224 z) {
        z = uint224(y) * uint224(Q112); // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }

}

pragma solidity ^0.7.6;
pragma abicoder v2;

import './Registry.sol';
import "./IPriceFeeds.sol";

contract UniswapPriceOracleProxyStorage {
    address public implementation;
    address public registry;
    uint public Q112 = 2**112;
    uint public period = 10 minutes;
}

contract UniswapPriceOracleStorageV1 is UniswapPriceOracleProxyStorage {
    uint public minReserveLiquidity;

    address public WETHToken;
    address public ETHUSDPriceFeed;

    struct PoolCumulativePrice {
        FixedPoint.uq112x112 priceAverage;
        uint priceCumulativePrevious;
        uint32 blockTimeStampPrevious;
    }

    // asset => assetPair => data from pool
    mapping(address => mapping (address => PoolCumulativePrice)) public cumulativePrices;
    mapping(address => uint) public averagePrices;

    // asset => pair with reserves
    mapping(address => address) public assetPair;

    address[] public poolFactories;
    address[] public stableCoins;
}

pragma solidity ^0.7.6;

import "./ErrorReporter.sol";
import "./ControllerStorage.sol";
/**
 * @title ControllerCore
 * @dev Storage for the controller is at this address, while execution is delegated to the `controllerImplementation`.
 * PTokens should reference this contract as their controller.
 */
contract Unitroller is UnitrollerAdminStorage, ControllerErrorReporter {

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

    constructor() {
        // Set admin to caller
        admin = msg.sender;
    }

    /*** Admin Functions ***/
    function _setPendingImplementation(address newPendingImplementation) public returns (uint) {

        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PENDING_IMPLEMENTATION_OWNER_CHECK);
        }

        address oldPendingImplementation = pendingControllerImplementation;

        pendingControllerImplementation = newPendingImplementation;

        emit NewPendingImplementation(oldPendingImplementation, pendingControllerImplementation);

        return uint(Error.NO_ERROR);
    }

    /**
    * @notice Accepts new implementation of controller. msg.sender must be pendingImplementation
    * @dev Admin function for new implementation to accept it's role as implementation
    * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
    */
    function _acceptImplementation() public returns (uint) {
        // Check caller is pendingImplementation and pendingImplementation ≠ address(0)
        if (msg.sender != pendingControllerImplementation || pendingControllerImplementation == address(0)) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK);
        }

        // Save current values for inclusion in log
        address oldImplementation = controllerImplementation;
        address oldPendingImplementation = pendingControllerImplementation;

        controllerImplementation = pendingControllerImplementation;

        pendingControllerImplementation = address(0);

        emit NewImplementation(oldImplementation, controllerImplementation);
        emit NewPendingImplementation(oldPendingImplementation, pendingControllerImplementation);

        return uint(Error.NO_ERROR);
    }


    /**
      * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @param newPendingAdmin New pending admin.
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setPendingAdmin(address newPendingAdmin) public returns (uint) {
        // Check caller = admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PENDING_ADMIN_OWNER_CHECK);
        }

        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
      * @dev Admin function for pending admin to accept role and update admin
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _acceptAdmin() public returns (uint) {
        // Check caller is pendingAdmin
        if (msg.sender != pendingAdmin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ACCEPT_ADMIN_PENDING_ADMIN_CHECK);
        }

        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);

        return uint(Error.NO_ERROR);
    }

    /**
     * @dev Delegates execution to an implementation contract.
     * It returns to the external caller whatever the implementation returns
     * or forwards reverts.
     */
    fallback() payable external {
        // delegate all other functions to current implementation
        (bool success, ) = controllerImplementation.delegatecall(msg.data);

        assembly {
        let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize())

            switch success
            case 0 { revert(free_mem_ptr, returndatasize()) }
            default { return(free_mem_ptr, returndatasize()) }
        }
    }
}

