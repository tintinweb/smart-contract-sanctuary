pragma solidity ^0.7.4;

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

pragma solidity ^0.7.4;

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

    /// @notice Emitted when market pieed status is changed
    event MarketPied(address pToken, bool isPied);

    /// @notice Emitted when PIE rate is changed
    event NewPieRate(uint oldPieRate, uint newPieRate);

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
        // pToken;
        // redeemer;

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
        // payer;
        // borrower;
        // repayAmount;

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
        // seizeTokens;

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

    function refreshPieSpeeds() public {
        require(msg.sender == tx.origin, "only externally owned accounts may refresh speeds");
        refreshPieSpeedsInternal();
    }

    /**
     * @notice Recalculate and update PIE speeds for all PIE markets
     */
    function refreshPieSpeedsInternal() internal {
        address[] memory allMarkets_ = allMarkets;

        for (uint i = 0; i < allMarkets_.length; i++) {
            address pToken = allMarkets_[i];
            Exp memory borrowIndex = Exp({mantissa: PTokenInterface(pToken).borrowIndex()});
            updatePieSupplyIndex(pToken);
            updatePieBorrowIndex(pToken, borrowIndex);
        }

        Exp memory totalUtility = Exp({mantissa: 0});
        Exp[] memory utilities = new Exp[](allMarkets_.length);
        for (uint i = 0; i < allMarkets_.length; i++) {
            address pToken = allMarkets_[i];
            if (markets[pToken].isPied) {
                oracle.updateUnderlyingPrice(pToken);
                Exp memory assetPrice = Exp({mantissa: oracle.getUnderlyingPrice(pToken)});
                Exp memory interestPerBlock = mul_(Exp({mantissa: PTokenInterface(pToken).borrowRatePerBlock()}), PTokenInterface(pToken).totalBorrows());
                Exp memory utility = mul_(interestPerBlock, assetPrice);
                utilities[i] = utility;
                totalUtility = add_(totalUtility, utility);
            }
        }

        for (uint i = 0; i < allMarkets_.length; i++) {
            address pToken = allMarkets[i];
            uint newSpeed = totalUtility.mantissa > 0 ? mul_(pieRate, div_(utilities[i], totalUtility)) : 0;
            pieSpeeds[pToken] = newSpeed;
            emit PieSpeedUpdated(pToken, newSpeed);
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
     * @notice Transfer PIE to the user, if they are above the threshold
     * @dev Note: If there is not enough PIE, we do not perform the transfer all.
     * @param user The address of the user to transfer PIE to
     * @param userAccrued The amount of PIE to (possibly) transfer
     * @return The amount of PIE which was NOT transferred to the user
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

    /*** Pie Distribution Admin ***/

    /**
     * @notice Set the amount of PIE distributed per block
     * @param pieRate_ The amount of PIE wei per block to distribute
     */
    function _setPieRate(uint pieRate_) public {
        require(msg.sender == admin, "only admin can change pie rate");

        uint oldRate = pieRate;
        pieRate = pieRate_;
        emit NewPieRate(oldRate, pieRate_);

        refreshPieSpeedsInternal();
    }

    function _addPieMarkets(address[] memory pTokens) public {
        require(msg.sender == admin, "only admin can add pie market");

        for (uint i = 0; i < pTokens.length; i++) {
            _addPieMarketInternal(pTokens[i]);
        }

        refreshPieSpeedsInternal();
    }

    function _addPieMarketInternal(address pToken) internal {
        Market storage market = markets[pToken];
        require(market.isListed == true, "pie market is not listed");
        require(market.isPied == false, "pie market already added");

        market.isPied = true;
        emit MarketPied(pToken, true);

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

    /**
     * @notice Remove a market from pieMarkets, preventing it from earning PIE in the flywheel
     * @param pToken The address of the market to drop
     */
    function _dropPieMarket(address pToken) public {
        require(msg.sender == admin, "only admin can drop pie market");

        Market storage market = markets[pToken];
        require(market.isPied == true, "market is not a pie market");

        market.isPied = false;
        emit MarketPied(pToken, false);

        refreshPieSpeedsInternal();
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

pragma solidity ^0.7.4;

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

pragma solidity ^0.7.4;

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

pragma solidity ^0.7.4;

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

pragma solidity ^0.7.4;

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
        UNAUTHORIZED,
        UPDATE_PRICE
    }

    enum FailureInfo {
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        NO_RESERVES,
        PERIOD_NOT_ELAPSED,
        SET_NEW_ADDRESSES,
        SET_NEW_IMPLEMENTATION,
        SET_PENDING_ADMIN_OWNER_CHECK
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
        DEFICIENCY_ETH_LIQUIDITY_IN_POOL,
        PAIR_IS_NOT_EXIST,
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

pragma solidity ^0.7.4;

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

pragma solidity ^0.7.4;

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

pragma solidity ^0.7.4;

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

pragma solidity ^0.7.4;

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

pragma solidity ^0.7.4;

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

pragma solidity ^0.7.4;

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

pragma solidity ^0.7.4;

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