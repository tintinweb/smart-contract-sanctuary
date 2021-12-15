// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import "../BaseLogic.sol";
import "../IRiskManager.sol";
import "../PToken.sol";
import "../Interfaces.sol";
import "../Utils.sol";


/// @notice Definition of callback method that deferLiquidityCheck will invoke on your contract
interface IDeferredLiquidityCheck {
    function onDeferredLiquidityCheck(bytes memory data) external;
}


/// @notice Batch executions, liquidity check deferrals, and interfaces to fetch prices and account liquidity
contract Exec is BaseLogic {
    constructor(bytes32 moduleGitCommit_) BaseLogic(MODULEID__EXEC, moduleGitCommit_) {}

    /// @notice Single item in a batch request
    struct EulerBatchItem {
        bool allowError;
        address proxyAddr;
        bytes data;
    }

    /// @notice Single item in a batch response
    struct EulerBatchItemResponse {
        bool success;
        bytes result;
    }

    // Accessors

    // These are not view methods, since they can perform state writes in the uniswap contract while retrieving prices

    /// @notice Compute aggregate liquidity for an account
    /// @param account User address
    /// @return status Aggregate liquidity (sum of all entered assets)
    function liquidity(address account) external nonReentrant returns (IRiskManager.LiquidityStatus memory status) {
        bytes memory result = callInternalModule(MODULEID__RISK_MANAGER,
                                                 abi.encodeWithSelector(IRiskManager.computeLiquidity.selector, account));

        (status) = abi.decode(result, (IRiskManager.LiquidityStatus));
    }

    /// @notice Compute detailed liquidity for an account, broken down by asset
    /// @param account User address
    /// @return assets List of user's entered assets and each asset's corresponding liquidity
    function detailedLiquidity(address account) public nonReentrant returns (IRiskManager.AssetLiquidity[] memory assets) {
        bytes memory result = callInternalModule(MODULEID__RISK_MANAGER,
                                                 abi.encodeWithSelector(IRiskManager.computeAssetLiquidities.selector, account));

        (assets) = abi.decode(result, (IRiskManager.AssetLiquidity[]));
    }

    /// @notice Retrieve Euler's view of an asset's price
    /// @param underlying Token address
    /// @return twap Time-weighted average price
    /// @return twapPeriod TWAP duration, either the twapWindow value in AssetConfig, or less if that duration not available
    function getPrice(address underlying) external nonReentrant returns (uint twap, uint twapPeriod) {
        bytes memory result = callInternalModule(MODULEID__RISK_MANAGER,
                                                 abi.encodeWithSelector(IRiskManager.getPrice.selector, underlying));

        (twap, twapPeriod) = abi.decode(result, (uint, uint));
    }

    /// @notice Retrieve Euler's view of an asset's price, as well as the current marginal price on uniswap
    /// @param underlying Token address
    /// @return twap Time-weighted average price
    /// @return twapPeriod TWAP duration, either the twapWindow value in AssetConfig, or less if that duration not available
    /// @return currPrice The current marginal price on uniswap3 (informational: not used anywhere in the Euler protocol)
    function getPriceFull(address underlying) external nonReentrant returns (uint twap, uint twapPeriod, uint currPrice) {
        bytes memory result = callInternalModule(MODULEID__RISK_MANAGER,
                                                 abi.encodeWithSelector(IRiskManager.getPriceFull.selector, underlying));

        (twap, twapPeriod, currPrice) = abi.decode(result, (uint, uint, uint));
    }


    // Custom execution methods

    /// @notice Defer liquidity checking for an account, to perform rebalancing, flash loans, etc. msg.sender must implement IDeferredLiquidityCheck
    /// @param account The account to defer liquidity for. Usually address(this), although not always
    /// @param data Passed through to the onDeferredLiquidityCheck() callback, so contracts don't need to store transient data in storage
    function deferLiquidityCheck(address account, bytes memory data) external reentrantOK {
        address msgSender = unpackTrailingParamMsgSender();

        require(accountLookup[account].deferLiquidityStatus == DEFERLIQUIDITY__NONE, "e/defer/reentrancy");
        accountLookup[account].deferLiquidityStatus = DEFERLIQUIDITY__CLEAN;

        IDeferredLiquidityCheck(msgSender).onDeferredLiquidityCheck(data);

        uint8 status = accountLookup[account].deferLiquidityStatus;
        accountLookup[account].deferLiquidityStatus = DEFERLIQUIDITY__NONE;

        if (status == DEFERLIQUIDITY__DIRTY) checkLiquidity(account);
    }

    /// @notice Execute several operations in a single transaction
    /// @param items List of operations to execute
    /// @param deferLiquidityChecks List of user accounts to defer liquidity checks for
    /// @return List of operation results
    function batchDispatch(EulerBatchItem[] calldata items, address[] calldata deferLiquidityChecks) public reentrantOK returns (EulerBatchItemResponse[] memory) {
        address msgSender = unpackTrailingParamMsgSender();

        for (uint i = 0; i < deferLiquidityChecks.length; ++i) {
            address account = deferLiquidityChecks[i];

            require(accountLookup[account].deferLiquidityStatus == DEFERLIQUIDITY__NONE, "e/batch/reentrancy");
            accountLookup[account].deferLiquidityStatus = DEFERLIQUIDITY__CLEAN;
        }


        EulerBatchItemResponse[] memory response = new EulerBatchItemResponse[](items.length);

        for (uint i = 0; i < items.length; ++i) {
            EulerBatchItem calldata item = items[i];
            address proxyAddr = item.proxyAddr;

            uint32 moduleId = trustedSenders[proxyAddr].moduleId;
            address moduleImpl = trustedSenders[proxyAddr].moduleImpl;

            require(moduleId != 0, "e/batch/unknown-proxy-addr");
            require(moduleId <= MAX_EXTERNAL_MODULEID, "e/batch/call-to-internal-module");

            if (moduleImpl == address(0)) moduleImpl = moduleLookup[moduleId];
            require(moduleImpl != address(0), "e/batch/module-not-installed");

            bytes memory inputWrapped = abi.encodePacked(item.data, uint160(msgSender), uint160(proxyAddr));
            (bool success, bytes memory result) = moduleImpl.delegatecall(inputWrapped);

            if (success || item.allowError) {
                EulerBatchItemResponse memory r = response[i];
                r.success = success;
                r.result = result;
            } else {
                revertBytes(result);
            }
        }


        for (uint i = 0; i < deferLiquidityChecks.length; ++i) {
            address account = deferLiquidityChecks[i];

            uint8 status = accountLookup[account].deferLiquidityStatus;
            accountLookup[account].deferLiquidityStatus = DEFERLIQUIDITY__NONE;

            if (status == DEFERLIQUIDITY__DIRTY) checkLiquidity(account);
        }

        return response;
    }

    /// @notice Results of a batchDispatch, but with extra information
    struct EulerBatchExtra {
        EulerBatchItemResponse[] responses;
        uint gasUsed;
        IRiskManager.AssetLiquidity[][] liquidities;
    }

    /// @notice Call batchDispatch, but return extra information. Only intended to be used with callStatic.
    /// @param items List of operations to execute
    /// @param deferLiquidityChecks List of user accounts to defer liquidity checks for
    /// @param queryLiquidity List of user accounts to return detailed liquidity information for
    /// @return output Structure with extra information
    function batchDispatchExtra(EulerBatchItem[] calldata items, address[] calldata deferLiquidityChecks, address[] calldata queryLiquidity) external reentrantOK returns (EulerBatchExtra memory output) {
        {
            uint origGasLeft = gasleft();
            output.responses = batchDispatch(items, deferLiquidityChecks);
            output.gasUsed = origGasLeft - gasleft();
        }

        output.liquidities = new IRiskManager.AssetLiquidity[][](queryLiquidity.length);

        for (uint i = 0; i < queryLiquidity.length; ++i) {
            output.liquidities[i] = detailedLiquidity(queryLiquidity[i]);
        }
    }


    // Average liquidity tracking

    /// @notice Enable average liquidity tracking for your account. Operations will cost more gas, but you may get additional benefits when performing liquidations
    /// @param subAccountId subAccountId 0 for primary, 1-255 for a sub-account. 
    /// @param delegate An address of another account that you would allow to use the benefits of your account's average liquidity (use the null address if you don't care about this). The other address must also reciprocally delegate to your account.
    /// @param onlyDelegate Set this flag to skip tracking average liquidity and only set the delegate.
    function trackAverageLiquidity(uint subAccountId, address delegate, bool onlyDelegate) external nonReentrant {
        address msgSender = unpackTrailingParamMsgSender();
        address account = getSubAccount(msgSender, subAccountId);
        require(account != delegate, "e/track-liquidity/self-delegation");

        emit DelegateAverageLiquidity(account, delegate);
        accountLookup[account].averageLiquidityDelegate = delegate;

        if (onlyDelegate) return;

        emit TrackAverageLiquidity(account);

        accountLookup[account].lastAverageLiquidityUpdate = uint40(block.timestamp);
        accountLookup[account].averageLiquidity = 0;
    }

    /// @notice Disable average liquidity tracking for your account and remove delegate
    /// @param subAccountId subAccountId 0 for primary, 1-255 for a sub-account
    function unTrackAverageLiquidity(uint subAccountId) external nonReentrant {
        address msgSender = unpackTrailingParamMsgSender();
        address account = getSubAccount(msgSender, subAccountId);

        emit UnTrackAverageLiquidity(account);
        emit DelegateAverageLiquidity(account, address(0));

        accountLookup[account].lastAverageLiquidityUpdate = 0;
        accountLookup[account].averageLiquidity = 0;
        accountLookup[account].averageLiquidityDelegate = address(0);
    }

    /// @notice Retrieve the average liquidity for an account
    /// @param account User account (xor in subAccountId, if applicable)
    /// @return The average liquidity, in terms of the reference asset, and post risk-adjustment
    function getAverageLiquidity(address account) external nonReentrant returns (uint) {
        return getUpdatedAverageLiquidity(account);
    }

    /// @notice Retrieve the average liquidity for an account or a delegate account, if set
    /// @param account User account (xor in subAccountId, if applicable)
    /// @return The average liquidity, in terms of the reference asset, and post risk-adjustment
    function getAverageLiquidityWithDelegate(address account) external nonReentrant returns (uint) {
        return getUpdatedAverageLiquidityWithDelegate(account);
    }

    /// @notice Retrieve the account which delegates average liquidity for an account, if set
    /// @param account User account (xor in subAccountId, if applicable)
    /// @return The average liquidity delegate account
    function getAverageLiquidityDelegateAccount(address account) external view returns (address) {
        address delegate = accountLookup[account].averageLiquidityDelegate;
        return accountLookup[delegate].averageLiquidityDelegate == account ? delegate : address(0);
    }




    // PToken wrapping/unwrapping

    /// @notice Transfer underlying tokens from sender's wallet into the pToken wrapper. Allowance should be set for the euler address.
    /// @param underlying Token address
    /// @param amount The amount to wrap in underlying units
    function pTokenWrap(address underlying, uint amount) external nonReentrant {
        address msgSender = unpackTrailingParamMsgSender();

        emit PTokenWrap(underlying, msgSender, amount);

        address pTokenAddr = reversePTokenLookup[underlying];
        require(pTokenAddr != address(0), "e/exec/ptoken-not-found");

        {
            uint origBalance = IERC20(underlying).balanceOf(pTokenAddr);
            Utils.safeTransferFrom(underlying, msgSender, pTokenAddr, amount);
            uint newBalance = IERC20(underlying).balanceOf(pTokenAddr);
            require(newBalance == origBalance + amount, "e/exec/ptoken-transfer-mismatch");
        }

        PToken(pTokenAddr).claimSurplus(msgSender);
    }

    /// @notice Transfer underlying tokens from the pToken wrapper to the sender's wallet.
    /// @param underlying Token address
    /// @param amount The amount to unwrap in underlying units
    function pTokenUnWrap(address underlying, uint amount) external nonReentrant {
        address msgSender = unpackTrailingParamMsgSender();

        emit PTokenUnWrap(underlying, msgSender, amount);

        address pTokenAddr = reversePTokenLookup[underlying];
        require(pTokenAddr != address(0), "e/exec/ptoken-not-found");

        PToken(pTokenAddr).forceUnwrap(msgSender, amount);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import "./BaseModule.sol";
import "./BaseIRM.sol";
import "./Interfaces.sol";
import "./Utils.sol";
import "./vendor/RPow.sol";
import "./IRiskManager.sol";


abstract contract BaseLogic is BaseModule {
    constructor(uint moduleId_, bytes32 moduleGitCommit_) BaseModule(moduleId_, moduleGitCommit_) {}


    // Account auth

    function getSubAccount(address primary, uint subAccountId) internal pure returns (address) {
        require(subAccountId < 256, "e/sub-account-id-too-big");
        return address(uint160(primary) ^ uint160(subAccountId));
    }

    function isSubAccountOf(address primary, address subAccount) internal pure returns (bool) {
        return (uint160(primary) | 0xFF) == (uint160(subAccount) | 0xFF);
    }



    // Entered markets array

    function getEnteredMarketsArray(address account) internal view returns (address[] memory) {
        uint32 numMarketsEntered = accountLookup[account].numMarketsEntered;
        address firstMarketEntered = accountLookup[account].firstMarketEntered;

        address[] memory output = new address[](numMarketsEntered);
        if (numMarketsEntered == 0) return output;

        address[MAX_POSSIBLE_ENTERED_MARKETS] storage markets = marketsEntered[account];

        output[0] = firstMarketEntered;

        for (uint i = 1; i < numMarketsEntered; ++i) {
            output[i] = markets[i];
        }

        return output;
    }

    function isEnteredInMarket(address account, address underlying) internal view returns (bool) {
        uint32 numMarketsEntered = accountLookup[account].numMarketsEntered;
        address firstMarketEntered = accountLookup[account].firstMarketEntered;

        if (numMarketsEntered == 0) return false;
        if (firstMarketEntered == underlying) return true;

        address[MAX_POSSIBLE_ENTERED_MARKETS] storage markets = marketsEntered[account];

        for (uint i = 1; i < numMarketsEntered; ++i) {
            if (markets[i] == underlying) return true;
        }

        return false;
    }

    function doEnterMarket(address account, address underlying) internal {
        AccountStorage storage accountStorage = accountLookup[account];

        uint32 numMarketsEntered = accountStorage.numMarketsEntered;
        address[MAX_POSSIBLE_ENTERED_MARKETS] storage markets = marketsEntered[account];

        if (numMarketsEntered != 0) {
            if (accountStorage.firstMarketEntered == underlying) return; // already entered
            for (uint i = 1; i < numMarketsEntered; i++) {
                if (markets[i] == underlying) return; // already entered
            }
        }

        require(numMarketsEntered < MAX_ENTERED_MARKETS, "e/too-many-entered-markets");

        if (numMarketsEntered == 0) accountStorage.firstMarketEntered = underlying;
        else markets[numMarketsEntered] = underlying;

        accountStorage.numMarketsEntered = numMarketsEntered + 1;

        emit EnterMarket(underlying, account);
    }

    // Liquidity check must be done by caller after calling this

    function doExitMarket(address account, address underlying) internal {
        AccountStorage storage accountStorage = accountLookup[account];

        uint32 numMarketsEntered = accountStorage.numMarketsEntered;
        address[MAX_POSSIBLE_ENTERED_MARKETS] storage markets = marketsEntered[account];
        uint searchIndex = type(uint).max;

        if (numMarketsEntered == 0) return; // already exited

        if (accountStorage.firstMarketEntered == underlying) {
            searchIndex = 0;
        } else {
            for (uint i = 1; i < numMarketsEntered; i++) {
                if (markets[i] == underlying) {
                    searchIndex = i;
                    break;
                }
            }

            if (searchIndex == type(uint).max) return; // already exited
        }

        uint lastMarketIndex = numMarketsEntered - 1;

        if (searchIndex != lastMarketIndex) {
            if (searchIndex == 0) accountStorage.firstMarketEntered = markets[lastMarketIndex];
            else markets[searchIndex] = markets[lastMarketIndex];
        }

        accountStorage.numMarketsEntered = uint32(lastMarketIndex);

        if (lastMarketIndex != 0) markets[lastMarketIndex] = address(0); // zero out for storage refund

        emit ExitMarket(underlying, account);
    }



    // AssetConfig

    function resolveAssetConfig(address underlying) internal view returns (AssetConfig memory) {
        AssetConfig memory config = underlyingLookup[underlying];
        require(config.eTokenAddress != address(0), "e/market-not-activated");

        if (config.borrowFactor == type(uint32).max) config.borrowFactor = DEFAULT_BORROW_FACTOR;
        if (config.twapWindow == type(uint24).max) config.twapWindow = DEFAULT_TWAP_WINDOW_SECONDS;

        return config;
    }


    // AssetCache

    struct AssetCache {
        address underlying;

        uint112 totalBalances;
        uint144 totalBorrows;

        uint96 reserveBalance;

        uint interestAccumulator;

        uint40 lastInterestAccumulatorUpdate;
        uint8 underlyingDecimals;
        uint32 interestRateModel;
        int96 interestRate;
        uint32 reserveFee;
        uint16 pricingType;
        uint32 pricingParameters;

        uint poolSize; // result of calling balanceOf on underlying (in external units)

        uint underlyingDecimalsScaler;
        uint maxExternalAmount;
    }

    function initAssetCache(address underlying, AssetStorage storage assetStorage, AssetCache memory assetCache) internal view returns (bool dirty) {
        dirty = false;

        assetCache.underlying = underlying;

        // Storage loads

        assetCache.lastInterestAccumulatorUpdate = assetStorage.lastInterestAccumulatorUpdate;
        uint8 underlyingDecimals = assetCache.underlyingDecimals = assetStorage.underlyingDecimals;
        assetCache.interestRateModel = assetStorage.interestRateModel;
        assetCache.interestRate = assetStorage.interestRate;
        assetCache.reserveFee = assetStorage.reserveFee;
        assetCache.pricingType = assetStorage.pricingType;
        assetCache.pricingParameters = assetStorage.pricingParameters;

        assetCache.reserveBalance = assetStorage.reserveBalance;

        assetCache.totalBalances = assetStorage.totalBalances;
        assetCache.totalBorrows = assetStorage.totalBorrows;

        assetCache.interestAccumulator = assetStorage.interestAccumulator;

        // Derived state

        unchecked {
            assetCache.underlyingDecimalsScaler = 10**(18 - underlyingDecimals);
            assetCache.maxExternalAmount = MAX_SANE_AMOUNT / assetCache.underlyingDecimalsScaler;
        }

        uint poolSize = callBalanceOf(assetCache, address(this));
        if (poolSize <= assetCache.maxExternalAmount) {
            unchecked { assetCache.poolSize = poolSize * assetCache.underlyingDecimalsScaler; }
        } else {
            assetCache.poolSize = 0;
        }

        // Update interest accumulator and reserves

        if (block.timestamp != assetCache.lastInterestAccumulatorUpdate) {
            dirty = true;

            uint deltaT = block.timestamp - assetCache.lastInterestAccumulatorUpdate;

            // Compute new values

            uint newInterestAccumulator = (RPow.rpow(uint(int(assetCache.interestRate) + 1e27), deltaT, 1e27) * assetCache.interestAccumulator) / 1e27;

            uint newTotalBorrows = assetCache.totalBorrows * newInterestAccumulator / assetCache.interestAccumulator;

            uint newReserveBalance = assetCache.reserveBalance;
            uint newTotalBalances = assetCache.totalBalances;

            uint feeAmount = (newTotalBorrows - assetCache.totalBorrows)
                               * (assetCache.reserveFee == type(uint32).max ? DEFAULT_RESERVE_FEE : assetCache.reserveFee)
                               / (RESERVE_FEE_SCALE * INTERNAL_DEBT_PRECISION);

            if (feeAmount != 0) {
                uint poolAssets = assetCache.poolSize + (newTotalBorrows / INTERNAL_DEBT_PRECISION);
                newTotalBalances = poolAssets * newTotalBalances / (poolAssets - feeAmount);
                newReserveBalance += newTotalBalances - assetCache.totalBalances;
            }

            // Store new values in assetCache, only if no overflows will occur

            if (newTotalBalances <= MAX_SANE_AMOUNT && newTotalBorrows <= MAX_SANE_DEBT_AMOUNT) {
                assetCache.totalBorrows = encodeDebtAmount(newTotalBorrows);
                assetCache.interestAccumulator = newInterestAccumulator;
                assetCache.lastInterestAccumulatorUpdate = uint40(block.timestamp);

                if (newTotalBalances != assetCache.totalBalances) {
                    assetCache.reserveBalance = encodeSmallAmount(newReserveBalance);
                    assetCache.totalBalances = encodeAmount(newTotalBalances);
                }
            }
        }
    }

    function loadAssetCache(address underlying, AssetStorage storage assetStorage) internal returns (AssetCache memory assetCache) {
        if (initAssetCache(underlying, assetStorage, assetCache)) {
            assetStorage.lastInterestAccumulatorUpdate = assetCache.lastInterestAccumulatorUpdate;

            assetStorage.underlying = assetCache.underlying; // avoid an SLOAD of this slot
            assetStorage.reserveBalance = assetCache.reserveBalance;

            assetStorage.totalBalances = assetCache.totalBalances;
            assetStorage.totalBorrows = assetCache.totalBorrows;

            assetStorage.interestAccumulator = assetCache.interestAccumulator;
        }
    }

    function loadAssetCacheRO(address underlying, AssetStorage storage assetStorage) internal view returns (AssetCache memory assetCache) {
        initAssetCache(underlying, assetStorage, assetCache);
    }



    // Utils

    function decodeExternalAmount(AssetCache memory assetCache, uint externalAmount) internal pure returns (uint scaledAmount) {
        require(externalAmount <= assetCache.maxExternalAmount, "e/amount-too-large");
        unchecked { scaledAmount = externalAmount * assetCache.underlyingDecimalsScaler; }
    }

    function encodeAmount(uint amount) internal pure returns (uint112) {
        require(amount <= MAX_SANE_AMOUNT, "e/amount-too-large-to-encode");
        return uint112(amount);
    }

    function encodeSmallAmount(uint amount) internal pure returns (uint96) {
        require(amount <= MAX_SANE_SMALL_AMOUNT, "e/small-amount-too-large-to-encode");
        return uint96(amount);
    }

    function encodeDebtAmount(uint amount) internal pure returns (uint144) {
        require(amount <= MAX_SANE_DEBT_AMOUNT, "e/debt-amount-too-large-to-encode");
        return uint144(amount);
    }

    function computeExchangeRate(AssetCache memory assetCache) private pure returns (uint) {
        if (assetCache.totalBalances == 0) return 1e18;
        return (assetCache.poolSize + (assetCache.totalBorrows / INTERNAL_DEBT_PRECISION)) * 1e18 / assetCache.totalBalances;
    }

    function underlyingAmountToBalance(AssetCache memory assetCache, uint amount) internal pure returns (uint) {
        uint exchangeRate = computeExchangeRate(assetCache);
        return amount * 1e18 / exchangeRate;
    }

    function underlyingAmountToBalanceRoundUp(AssetCache memory assetCache, uint amount) internal pure returns (uint) {
        uint exchangeRate = computeExchangeRate(assetCache);
        return (amount * 1e18 + (exchangeRate - 1)) / exchangeRate;
    }

    function balanceToUnderlyingAmount(AssetCache memory assetCache, uint amount) internal pure returns (uint) {
        uint exchangeRate = computeExchangeRate(assetCache);
        return amount * exchangeRate / 1e18;
    }

    function callBalanceOf(AssetCache memory assetCache, address account) internal view FREEMEM returns (uint) {
        // We set a gas limit so that a malicious token can't eat up all gas and cause a liquidity check to fail.

        (bool success, bytes memory data) = assetCache.underlying.staticcall{gas: 20000}(abi.encodeWithSelector(IERC20.balanceOf.selector, account));

        // If token's balanceOf() call fails for any reason, return 0. This prevents malicious tokens from causing liquidity checks to fail.
        // If the contract doesn't exist (maybe because selfdestructed), then data.length will be 0 and we will return 0.
        // Data length > 32 is allowed because some legitimate tokens append extra data that can be safely ignored.

        if (!success || data.length < 32) return 0;

        return abi.decode(data, (uint256));
    }

    function updateInterestRate(AssetStorage storage assetStorage, AssetCache memory assetCache) internal {
        uint32 utilisation;

        {
            uint totalBorrows = assetCache.totalBorrows / INTERNAL_DEBT_PRECISION;
            uint poolAssets = assetCache.poolSize + totalBorrows;
            if (poolAssets == 0) utilisation = 0; // empty pool arbitrarily given utilisation of 0
            else utilisation = uint32(totalBorrows * (uint(type(uint32).max) * 1e18) / poolAssets / 1e18);
        }

        bytes memory result = callInternalModule(assetCache.interestRateModel,
                                                 abi.encodeWithSelector(BaseIRM.computeInterestRate.selector, assetCache.underlying, utilisation));

        (int96 newInterestRate) = abi.decode(result, (int96));

        assetStorage.interestRate = assetCache.interestRate = newInterestRate;
    }

    function logAssetStatus(AssetCache memory a) internal {
        emit AssetStatus(a.underlying, a.totalBalances, a.totalBorrows / INTERNAL_DEBT_PRECISION, a.reserveBalance, a.poolSize, a.interestAccumulator, a.interestRate, block.timestamp);
    }



    // Balances

    function increaseBalance(AssetStorage storage assetStorage, AssetCache memory assetCache, address eTokenAddress, address account, uint amount) internal {
        assetStorage.users[account].balance = encodeAmount(assetStorage.users[account].balance + amount);

        assetStorage.totalBalances = assetCache.totalBalances = encodeAmount(uint(assetCache.totalBalances) + amount);

        updateInterestRate(assetStorage, assetCache);

        emit Deposit(assetCache.underlying, account, amount);
        emitViaProxy_Transfer(eTokenAddress, address(0), account, amount);
    }

    function decreaseBalance(AssetStorage storage assetStorage, AssetCache memory assetCache, address eTokenAddress, address account, uint amount) internal {
        uint origBalance = assetStorage.users[account].balance;
        require(origBalance >= amount, "e/insufficient-balance");
        assetStorage.users[account].balance = encodeAmount(origBalance - amount);

        assetStorage.totalBalances = assetCache.totalBalances = encodeAmount(assetCache.totalBalances - amount);

        updateInterestRate(assetStorage, assetCache);

        emit Withdraw(assetCache.underlying, account, amount);
        emitViaProxy_Transfer(eTokenAddress, account, address(0), amount);
    }

    function transferBalance(AssetStorage storage assetStorage, AssetCache memory assetCache, address eTokenAddress, address from, address to, uint amount) internal {
        uint origFromBalance = assetStorage.users[from].balance;
        require(origFromBalance >= amount, "e/insufficient-balance");
        uint newFromBalance;
        unchecked { newFromBalance = origFromBalance - amount; }

        assetStorage.users[from].balance = encodeAmount(newFromBalance);
        assetStorage.users[to].balance = encodeAmount(assetStorage.users[to].balance + amount);

        emit Withdraw(assetCache.underlying, from, amount);
        emit Deposit(assetCache.underlying, to, amount);
        emitViaProxy_Transfer(eTokenAddress, from, to, amount);
    }

    function withdrawAmounts(AssetStorage storage assetStorage, AssetCache memory assetCache, address account, uint amount) internal view returns (uint, uint) {
        uint amountInternal;
        if (amount == type(uint).max) {
            amountInternal = assetStorage.users[account].balance;
            amount = balanceToUnderlyingAmount(assetCache, amountInternal);
        } else {
            amount = decodeExternalAmount(assetCache, amount);
            amountInternal = underlyingAmountToBalanceRoundUp(assetCache, amount);
        }

        return (amount, amountInternal);
    }

    // Borrows

    // Returns internal precision

    function getCurrentOwedExact(AssetStorage storage assetStorage, AssetCache memory assetCache, address account, uint owed) internal view returns (uint) {
        // Don't bother loading the user's accumulator
        if (owed == 0) return 0;

        // Can't divide by 0 here: If owed is non-zero, we must've initialised the user's interestAccumulator
        return owed * assetCache.interestAccumulator / assetStorage.users[account].interestAccumulator;
    }

    // When non-zero, we round *up* to the smallest external unit so that outstanding dust in a loan can be repaid.
    // unchecked is OK here since owed is always loaded from storage, so we know it fits into a uint144 (pre-interest accural)
    // Takes and returns 27 decimals precision.

    function roundUpOwed(AssetCache memory assetCache, uint owed) private pure returns (uint) {
        if (owed == 0) return 0;

        unchecked {
            uint scale = INTERNAL_DEBT_PRECISION * assetCache.underlyingDecimalsScaler;
            return (owed + scale - 1) / scale * scale;
        }
    }

    // Returns 18-decimals precision (debt amount is rounded up)

    function getCurrentOwed(AssetStorage storage assetStorage, AssetCache memory assetCache, address account) internal view returns (uint) {
        return roundUpOwed(assetCache, getCurrentOwedExact(assetStorage, assetCache, account, assetStorage.users[account].owed)) / INTERNAL_DEBT_PRECISION;
    }

    function updateUserBorrow(AssetStorage storage assetStorage, AssetCache memory assetCache, address account) private returns (uint newOwedExact, uint prevOwedExact) {
        prevOwedExact = assetStorage.users[account].owed;

        newOwedExact = getCurrentOwedExact(assetStorage, assetCache, account, prevOwedExact);

        assetStorage.users[account].owed = encodeDebtAmount(newOwedExact);
        assetStorage.users[account].interestAccumulator = assetCache.interestAccumulator;
    }

    function logBorrowChange(AssetCache memory assetCache, address dTokenAddress, address account, uint prevOwed, uint owed) private {
        prevOwed = roundUpOwed(assetCache, prevOwed) / INTERNAL_DEBT_PRECISION;
        owed = roundUpOwed(assetCache, owed) / INTERNAL_DEBT_PRECISION;

        if (owed > prevOwed) {
            uint change = owed - prevOwed;
            emit Borrow(assetCache.underlying, account, change);
            emitViaProxy_Transfer(dTokenAddress, address(0), account, change);
        } else if (prevOwed > owed) {
            uint change = prevOwed - owed;
            emit Repay(assetCache.underlying, account, change);
            emitViaProxy_Transfer(dTokenAddress, account, address(0), change);
        }
    }

    function increaseBorrow(AssetStorage storage assetStorage, AssetCache memory assetCache, address dTokenAddress, address account, uint amount) internal {
        amount *= INTERNAL_DEBT_PRECISION;

        require(assetCache.pricingType != PRICINGTYPE__FORWARDED || pTokenLookup[assetCache.underlying] == address(0), "e/borrow-not-supported");

        (uint owed, uint prevOwed) = updateUserBorrow(assetStorage, assetCache, account);

        if (owed == 0) doEnterMarket(account, assetCache.underlying);

        owed += amount;

        assetStorage.users[account].owed = encodeDebtAmount(owed);
        assetStorage.totalBorrows = assetCache.totalBorrows = encodeDebtAmount(assetCache.totalBorrows + amount);

        updateInterestRate(assetStorage, assetCache);

        logBorrowChange(assetCache, dTokenAddress, account, prevOwed, owed);
    }

    function decreaseBorrow(AssetStorage storage assetStorage, AssetCache memory assetCache, address dTokenAddress, address account, uint origAmount) internal {
        uint amount = origAmount * INTERNAL_DEBT_PRECISION;

        (uint owed, uint prevOwed) = updateUserBorrow(assetStorage, assetCache, account);
        uint owedRoundedUp = roundUpOwed(assetCache, owed);

        require(amount <= owedRoundedUp, "e/repay-too-much");
        uint owedRemaining;
        unchecked { owedRemaining = owedRoundedUp - amount; }

        if (owed > assetCache.totalBorrows) owed = assetCache.totalBorrows;

        assetStorage.users[account].owed = encodeDebtAmount(owedRemaining);
        assetStorage.totalBorrows = assetCache.totalBorrows = encodeDebtAmount(assetCache.totalBorrows - owed + owedRemaining);

        updateInterestRate(assetStorage, assetCache);

        logBorrowChange(assetCache, dTokenAddress, account, prevOwed, owedRemaining);
    }

    function transferBorrow(AssetStorage storage assetStorage, AssetCache memory assetCache, address dTokenAddress, address from, address to, uint origAmount) internal {
        uint amount = origAmount * INTERNAL_DEBT_PRECISION;

        (uint fromOwed, uint fromOwedPrev) = updateUserBorrow(assetStorage, assetCache, from);
        (uint toOwed, uint toOwedPrev) = updateUserBorrow(assetStorage, assetCache, to);

        if (toOwed == 0) doEnterMarket(to, assetCache.underlying);

        // If amount was rounded up, transfer exact amount owed
        if (amount > fromOwed && amount - fromOwed < INTERNAL_DEBT_PRECISION) amount = fromOwed;

        require(fromOwed >= amount, "e/insufficient-balance");
        unchecked { fromOwed -= amount; }

        // Transfer any residual dust
        if (fromOwed < INTERNAL_DEBT_PRECISION) {
            amount += fromOwed;
            fromOwed = 0;
        }

        toOwed += amount;

        assetStorage.users[from].owed = encodeDebtAmount(fromOwed);
        assetStorage.users[to].owed = encodeDebtAmount(toOwed);

        logBorrowChange(assetCache, dTokenAddress, from, fromOwedPrev, fromOwed);
        logBorrowChange(assetCache, dTokenAddress, to, toOwedPrev, toOwed);
    }



    // Reserves

    function increaseReserves(AssetStorage storage assetStorage, AssetCache memory assetCache, uint amount) internal {
        assetStorage.reserveBalance = assetCache.reserveBalance = encodeSmallAmount(assetCache.reserveBalance + amount);
        assetStorage.totalBalances = assetCache.totalBalances = encodeAmount(assetCache.totalBalances + amount);
    }



    // Token asset transfers

    // amounts are in underlying units

    function pullTokens(AssetCache memory assetCache, address from, uint amount) internal returns (uint amountTransferred) {
        uint poolSizeBefore = assetCache.poolSize;

        Utils.safeTransferFrom(assetCache.underlying, from, address(this), amount / assetCache.underlyingDecimalsScaler);
        uint poolSizeAfter = assetCache.poolSize = decodeExternalAmount(assetCache, callBalanceOf(assetCache, address(this)));

        require(poolSizeAfter >= poolSizeBefore, "e/negative-transfer-amount");
        unchecked { amountTransferred = poolSizeAfter - poolSizeBefore; }
    }

    function pushTokens(AssetCache memory assetCache, address to, uint amount) internal returns (uint amountTransferred) {
        uint poolSizeBefore = assetCache.poolSize;

        Utils.safeTransfer(assetCache.underlying, to, amount / assetCache.underlyingDecimalsScaler);
        uint poolSizeAfter = assetCache.poolSize = decodeExternalAmount(assetCache, callBalanceOf(assetCache, address(this)));

        require(poolSizeBefore >= poolSizeAfter, "e/negative-transfer-amount");
        unchecked { amountTransferred = poolSizeBefore - poolSizeAfter; }
    }




    // Liquidity

    function getAssetPrice(address asset) internal returns (uint) {
        bytes memory result = callInternalModule(MODULEID__RISK_MANAGER, abi.encodeWithSelector(IRiskManager.getPrice.selector, asset));
        return abi.decode(result, (uint));
    }

    function getAccountLiquidity(address account) internal returns (uint collateralValue, uint liabilityValue) {
        bytes memory result = callInternalModule(MODULEID__RISK_MANAGER, abi.encodeWithSelector(IRiskManager.computeLiquidity.selector, account));
        (IRiskManager.LiquidityStatus memory status) = abi.decode(result, (IRiskManager.LiquidityStatus));

        collateralValue = status.collateralValue;
        liabilityValue = status.liabilityValue;
    }

    function checkLiquidity(address account) internal {
        uint8 status = accountLookup[account].deferLiquidityStatus;

        if (status == DEFERLIQUIDITY__NONE) {
            callInternalModule(MODULEID__RISK_MANAGER, abi.encodeWithSelector(IRiskManager.requireLiquidity.selector, account));
        } else if (status == DEFERLIQUIDITY__CLEAN) {
            accountLookup[account].deferLiquidityStatus = DEFERLIQUIDITY__DIRTY;
        }
    }



    // Optional average liquidity tracking

    function computeNewAverageLiquidity(address account, uint deltaT) private returns (uint) {
        uint currDuration = deltaT >= AVERAGE_LIQUIDITY_PERIOD ? AVERAGE_LIQUIDITY_PERIOD : deltaT;
        uint prevDuration = AVERAGE_LIQUIDITY_PERIOD - currDuration;

        uint currAverageLiquidity;

        {
            (uint collateralValue, uint liabilityValue) = getAccountLiquidity(account);
            currAverageLiquidity = collateralValue > liabilityValue ? collateralValue - liabilityValue : 0;
        }

        return (accountLookup[account].averageLiquidity * prevDuration / AVERAGE_LIQUIDITY_PERIOD) +
               (currAverageLiquidity * currDuration / AVERAGE_LIQUIDITY_PERIOD);
    }

    function getUpdatedAverageLiquidity(address account) internal returns (uint) {
        uint lastAverageLiquidityUpdate = accountLookup[account].lastAverageLiquidityUpdate;
        if (lastAverageLiquidityUpdate == 0) return 0;

        uint deltaT = block.timestamp - lastAverageLiquidityUpdate;
        if (deltaT == 0) return accountLookup[account].averageLiquidity;

        return computeNewAverageLiquidity(account, deltaT);
    }

    function getUpdatedAverageLiquidityWithDelegate(address account) internal returns (uint) {
        address delegate = accountLookup[account].averageLiquidityDelegate;

        return delegate != address(0) && accountLookup[delegate].averageLiquidityDelegate == account
            ? getUpdatedAverageLiquidity(delegate)
            : getUpdatedAverageLiquidity(account);
    }

    function updateAverageLiquidity(address account) internal {
        uint lastAverageLiquidityUpdate = accountLookup[account].lastAverageLiquidityUpdate;
        if (lastAverageLiquidityUpdate == 0) return;

        uint deltaT = block.timestamp - lastAverageLiquidityUpdate;
        if (deltaT == 0) return;

        accountLookup[account].lastAverageLiquidityUpdate = uint40(block.timestamp);
        accountLookup[account].averageLiquidity = computeNewAverageLiquidity(account, deltaT);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import "./Storage.sol";

// This interface is used to avoid a circular dependency between BaseLogic and RiskManager

interface IRiskManager {
    struct NewMarketParameters {
        uint16 pricingType;
        uint32 pricingParameters;

        Storage.AssetConfig config;
    }

    struct LiquidityStatus {
        uint collateralValue;
        uint liabilityValue;
        uint numBorrows;
        bool borrowIsolated;
    }

    struct AssetLiquidity {
        address underlying;
        LiquidityStatus status;
    }

    function getNewMarketParameters(address underlying) external returns (NewMarketParameters memory);

    function requireLiquidity(address account) external;
    function computeLiquidity(address account) external returns (LiquidityStatus memory status);
    function computeAssetLiquidities(address account) external returns (AssetLiquidity[] memory assets);

    function getPrice(address underlying) external returns (uint twap, uint twapPeriod);
    function getPriceFull(address underlying) external returns (uint twap, uint twapPeriod, uint currPrice);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import "./Interfaces.sol";
import "./Utils.sol";

/// @notice Protected Tokens are simple wrappers for tokens, allowing you to use tokens as collateral without permitting borrowing
contract PToken {
    address immutable euler;
    address immutable underlyingToken;

    constructor(address euler_, address underlying_) {
        euler = euler_;
        underlyingToken = underlying_;
    }


    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowances;
    uint totalBalances;


    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);


    /// @notice PToken name, ie "Euler Protected DAI"
    function name() external view returns (string memory) {
        return string(abi.encodePacked("Euler Protected ", IERC20(underlyingToken).name()));
    }

    /// @notice PToken symbol, ie "pDAI"
    function symbol() external view returns (string memory) {
        return string(abi.encodePacked("p", IERC20(underlyingToken).symbol()));
    }

    /// @notice Number of decimals, which is same as the underlying's
    function decimals() external view returns (uint8) {
        return IERC20(underlyingToken).decimals();
    }

    /// @notice Address of the underlying asset
    function underlying() external view returns (address) {
        return underlyingToken;
    }


    /// @notice Balance of an account's wrapped tokens
    function balanceOf(address who) external view returns (uint) {
        return balances[who];
    }

    /// @notice Sum of all wrapped token balances
    function totalSupply() external view returns (uint) {
        return totalBalances;
    }

    /// @notice Retrieve the current allowance
    /// @param holder Address giving permission to access tokens
    /// @param spender Trusted address
    function allowance(address holder, address spender) external view returns (uint) {
        return allowances[holder][spender];
    }


    /// @notice Transfer your own pTokens to another address
    /// @param recipient Recipient address
    /// @param amount Amount of wrapped token to transfer
    function transfer(address recipient, uint amount) external returns (bool) {
        return transferFrom(msg.sender, recipient, amount);
    }

    /// @notice Transfer pTokens from one address to another. The euler address is automatically granted approval.
    /// @param from This address must've approved the to address
    /// @param recipient Recipient address
    /// @param amount Amount to transfer
    function transferFrom(address from, address recipient, uint amount) public returns (bool) {
        require(balances[from] >= amount, "insufficient balance");
        if (from != msg.sender && msg.sender != euler && allowances[from][msg.sender] != type(uint).max) {
            require(allowances[from][msg.sender] >= amount, "insufficient allowance");
            allowances[from][msg.sender] -= amount;
            emit Approval(from, msg.sender, allowances[from][msg.sender]);
        }
        balances[from] -= amount;
        balances[recipient] += amount;
        emit Transfer(from, recipient, amount);
        return true;
    }

    /// @notice Allow spender to access an amount of your pTokens. It is not necessary to approve the euler address.
    /// @param spender Trusted address
    /// @param amount Use max uint256 for "infinite" allowance
    function approve(address spender, uint amount) external returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }



    /// @notice Convert underlying tokens to pTokens
    /// @param amount In underlying units (which are equivalent to pToken units)
    function wrap(uint amount) external {
        Utils.safeTransferFrom(underlyingToken, msg.sender, address(this), amount);
        claimSurplus(msg.sender);
    }

    /// @notice Convert pTokens to underlying tokens
    /// @param amount In pToken units (which are equivalent to underlying units)
    function unwrap(uint amount) external {
        doUnwrap(msg.sender, amount);
    }

    // Only callable by the euler contract:
    function forceUnwrap(address who, uint amount) external {
        require(msg.sender == euler, "permission denied");
        doUnwrap(who, amount);
    }

    /// @notice Claim any surplus tokens held by the PToken contract. This should only be used by contracts.
    /// @param who Beneficiary to be credited for the surplus token amount
    function claimSurplus(address who) public {
        uint currBalance = IERC20(underlyingToken).balanceOf(address(this));
        require(currBalance > totalBalances, "no surplus balance to claim");

        uint amount = currBalance - totalBalances;

        totalBalances += amount;
        balances[who] += amount;
        emit Transfer(address(0), who, amount);
    }


    // Internal shared:

    function doUnwrap(address who, uint amount) private {
        require(balances[who] >= amount, "insufficient balance");

        totalBalances -= amount;
        balances[who] -= amount;

        Utils.safeTransfer(underlyingToken, who, amount);
        emit Transfer(who, address(0), amount);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;


interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IERC3156FlashBorrower {
    function onFlashLoan(address initiator, address token, uint256 amount, uint256 fee, bytes calldata data) external returns (bytes32);
}

interface IERC3156FlashLender {
    function maxFlashLoan(address token) external view returns (uint256);
    function flashFee(address token, uint256 amount) external view returns (uint256);
    function flashLoan(IERC3156FlashBorrower receiver, address token, uint256 amount, bytes calldata data) external returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import "./Interfaces.sol";

library Utils {
    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), string(data));
    }

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), string(data));
    }

    function safeApprove(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), string(data));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import "./Base.sol";


abstract contract BaseModule is Base {
    // Construction

    // public accessors common to all modules

    uint immutable public moduleId;
    bytes32 immutable public moduleGitCommit;

    constructor(uint moduleId_, bytes32 moduleGitCommit_) {
        moduleId = moduleId_;
        moduleGitCommit = moduleGitCommit_;
    }


    // Accessing parameters

    function unpackTrailingParamMsgSender() internal pure returns (address msgSender) {
        assembly {
            mstore(0, 0)

            calldatacopy(12, sub(calldatasize(), 40), 20)
            msgSender := mload(0)
        }
    }

    function unpackTrailingParams() internal pure returns (address msgSender, address proxyAddr) {
        assembly {
            mstore(0, 0)

            calldatacopy(12, sub(calldatasize(), 40), 20)
            msgSender := mload(0)

            calldatacopy(12, sub(calldatasize(), 20), 20)
            proxyAddr := mload(0)
        }
    }


    // Emit logs via proxies

    function emitViaProxy_Transfer(address proxyAddr, address from, address to, uint value) internal FREEMEM {
        (bool success,) = proxyAddr.call(abi.encodePacked(
                               uint8(3),
                               keccak256(bytes('Transfer(address,address,uint256)')),
                               bytes32(uint(uint160(from))),
                               bytes32(uint(uint160(to))),
                               value
                          ));
        require(success, "e/log-proxy-fail");
    }

    function emitViaProxy_Approval(address proxyAddr, address owner, address spender, uint value) internal FREEMEM {
        (bool success,) = proxyAddr.call(abi.encodePacked(
                               uint8(3),
                               keccak256(bytes('Approval(address,address,uint256)')),
                               bytes32(uint(uint160(owner))),
                               bytes32(uint(uint160(spender))),
                               value
                          ));
        require(success, "e/log-proxy-fail");
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import "./BaseModule.sol";

abstract contract BaseIRM is BaseModule {
    constructor(uint moduleId_, bytes32 moduleGitCommit_) BaseModule(moduleId_, moduleGitCommit_) {}

    int96 internal constant MAX_ALLOWED_INTEREST_RATE = int96(int(uint(5 * 1e27) / SECONDS_PER_YEAR)); // 500% APR
    int96 internal constant MIN_ALLOWED_INTEREST_RATE = 0;

    function computeInterestRateImpl(address, uint32) internal virtual returns (int96);

    function computeInterestRate(address underlying, uint32 utilisation) external returns (int96) {
        int96 rate = computeInterestRateImpl(underlying, utilisation);

        if (rate > MAX_ALLOWED_INTEREST_RATE) rate = MAX_ALLOWED_INTEREST_RATE;
        else if (rate < MIN_ALLOWED_INTEREST_RATE) rate = MIN_ALLOWED_INTEREST_RATE;

        return rate;
    }

    function reset(address underlying, bytes calldata resetParams) external virtual {}
}

// SPDX-License-Identifier: AGPL-3.0-or-later

// From MakerDAO DSS

// Copyright (C) 2018 Rain <[email protected]>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

library RPow {
    function rpow(uint x, uint n, uint base) internal pure returns (uint z) {
        assembly {
            switch x case 0 {switch n case 0 {z := base} default {z := 0}}
            default {
                switch mod(n, 2) case 0 { z := base } default { z := x }
                let half := div(base, 2)  // for rounding.
                for { n := div(n, 2) } n { n := div(n,2) } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) { revert(0,0) }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) { revert(0,0) }
                    x := div(xxRound, base)
                    if mod(n,2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) { revert(0,0) }
                        z := div(zxRound, base)
                    }
                }
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;
//import "hardhat/console.sol"; // DEV_MODE

import "./Storage.sol";
import "./Events.sol";
import "./Proxy.sol";

abstract contract Base is Storage, Events {
    // Modules

    function _createProxy(uint proxyModuleId) internal returns (address) {
        require(proxyModuleId != 0, "e/create-proxy/invalid-module");
        require(proxyModuleId <= MAX_EXTERNAL_MODULEID, "e/create-proxy/internal-module");

        // If we've already created a proxy for a single-proxy module, just return it:

        if (proxyLookup[proxyModuleId] != address(0)) return proxyLookup[proxyModuleId];

        // Otherwise create a proxy:

        address proxyAddr = address(new Proxy());

        if (proxyModuleId <= MAX_EXTERNAL_SINGLE_PROXY_MODULEID) proxyLookup[proxyModuleId] = proxyAddr;

        trustedSenders[proxyAddr] = TrustedSenderInfo({ moduleId: uint32(proxyModuleId), moduleImpl: address(0) });

        emit ProxyCreated(proxyAddr, proxyModuleId);

        return proxyAddr;
    }

    function callInternalModule(uint moduleId, bytes memory input) internal returns (bytes memory) {
        (bool success, bytes memory result) = moduleLookup[moduleId].delegatecall(input);
        if (!success) revertBytes(result);
        return result;
    }



    // Modifiers

    modifier nonReentrant() {
        require(reentrancyLock == REENTRANCYLOCK__UNLOCKED, "e/reentrancy");

        reentrancyLock = REENTRANCYLOCK__LOCKED;
        _;
        reentrancyLock = REENTRANCYLOCK__UNLOCKED;
    }

    modifier reentrantOK() { // documentation only
        _;
    }

    // WARNING: Must be very careful with this modifier. It resets the free memory pointer
    // to the value it was when the function started. This saves gas if more memory will
    // be allocated in the future. However, if the memory will be later referenced
    // (for example because the function has returned a pointer to it) then you cannot
    // use this modifier.

    modifier FREEMEM() {
        uint origFreeMemPtr;

        assembly {
            origFreeMemPtr := mload(0x40)
        }

        _;

        /*
        assembly { // DEV_MODE: overwrite the freed memory with garbage to detect bugs
            let garbage := 0xDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEF
            for { let i := origFreeMemPtr } lt(i, mload(0x40)) { i := add(i, 32) } { mstore(i, garbage) }
        }
        */

        assembly {
            mstore(0x40, origFreeMemPtr)
        }
    }



    // Error handling

    function revertBytes(bytes memory errMsg) internal pure {
        if (errMsg.length > 0) {
            assembly {
                revert(add(32, errMsg), mload(errMsg))
            }
        }

        revert("e/empty-error");
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import "./Constants.sol";

abstract contract Storage is Constants {
    // Dispatcher and upgrades

    uint reentrancyLock;

    address upgradeAdmin;
    address governorAdmin;

    mapping(uint => address) moduleLookup; // moduleId => module implementation
    mapping(uint => address) proxyLookup; // moduleId => proxy address (only for single-proxy modules)

    struct TrustedSenderInfo {
        uint32 moduleId; // 0 = un-trusted
        address moduleImpl; // only non-zero for external single-proxy modules
    }

    mapping(address => TrustedSenderInfo) trustedSenders; // sender address => moduleId (0 = un-trusted)



    // Account-level state
    // Sub-accounts are considered distinct accounts

    struct AccountStorage {
        // Packed slot: 1 + 5 + 4 + 20 = 30
        uint8 deferLiquidityStatus;
        uint40 lastAverageLiquidityUpdate;
        uint32 numMarketsEntered;
        address firstMarketEntered;

        uint averageLiquidity;
        address averageLiquidityDelegate;
    }

    mapping(address => AccountStorage) accountLookup;
    mapping(address => address[MAX_POSSIBLE_ENTERED_MARKETS]) marketsEntered;



    // Markets and assets

    struct AssetConfig {
        // Packed slot: 20 + 1 + 4 + 4 + 3 = 32
        address eTokenAddress;
        bool borrowIsolated;
        uint32 collateralFactor;
        uint32 borrowFactor;
        uint24 twapWindow;
    }

    struct UserAsset {
        uint112 balance;
        uint144 owed;

        uint interestAccumulator;
    }

    struct AssetStorage {
        // Packed slot: 5 + 1 + 4 + 12 + 4 + 2 + 4 = 32
        uint40 lastInterestAccumulatorUpdate;
        uint8 underlyingDecimals; // Not dynamic, but put here to live in same storage slot
        uint32 interestRateModel;
        int96 interestRate;
        uint32 reserveFee;
        uint16 pricingType;
        uint32 pricingParameters;

        address underlying;
        uint96 reserveBalance;

        address dTokenAddress;

        uint112 totalBalances;
        uint144 totalBorrows;

        uint interestAccumulator;

        mapping(address => UserAsset) users;

        mapping(address => mapping(address => uint)) eTokenAllowance;
        mapping(address => mapping(address => uint)) dTokenAllowance;
    }

    mapping(address => AssetConfig) internal underlyingLookup; // underlying => AssetConfig
    mapping(address => AssetStorage) internal eTokenLookup; // EToken => AssetStorage
    mapping(address => address) internal dTokenLookup; // DToken => EToken
    mapping(address => address) internal pTokenLookup; // PToken => underlying
    mapping(address => address) internal reversePTokenLookup; // underlying => PToken
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import "./Storage.sol";

abstract contract Events {
    event Genesis();


    event ProxyCreated(address indexed proxy, uint moduleId);
    event MarketActivated(address indexed underlying, address indexed eToken, address indexed dToken);
    event PTokenActivated(address indexed underlying, address indexed pToken);

    event EnterMarket(address indexed underlying, address indexed account);
    event ExitMarket(address indexed underlying, address indexed account);

    event Deposit(address indexed underlying, address indexed account, uint amount);
    event Withdraw(address indexed underlying, address indexed account, uint amount);
    event Borrow(address indexed underlying, address indexed account, uint amount);
    event Repay(address indexed underlying, address indexed account, uint amount);

    event Liquidation(address indexed liquidator, address indexed violator, address indexed underlying, address collateral, uint repay, uint yield, uint healthScore, uint baseDiscount, uint discount);

    event TrackAverageLiquidity(address indexed account);
    event UnTrackAverageLiquidity(address indexed account);
    event DelegateAverageLiquidity(address indexed account, address indexed delegate);

    event PTokenWrap(address indexed underlying, address indexed account, uint amount);
    event PTokenUnWrap(address indexed underlying, address indexed account, uint amount);

    event AssetStatus(address indexed underlying, uint totalBalances, uint totalBorrows, uint96 reserveBalance, uint poolSize, uint interestAccumulator, int96 interestRate, uint timestamp);


    event RequestDeposit(address indexed account, uint amount);
    event RequestWithdraw(address indexed account, uint amount);
    event RequestMint(address indexed account, uint amount);
    event RequestBurn(address indexed account, uint amount);
    event RequestTransferEToken(address indexed from, address indexed to, uint amount);

    event RequestBorrow(address indexed account, uint amount);
    event RequestRepay(address indexed account, uint amount);
    event RequestTransferDToken(address indexed from, address indexed to, uint amount);

    event RequestLiquidate(address indexed liquidator, address indexed violator, address indexed underlying, address collateral, uint repay, uint minYield);


    event InstallerSetUpgradeAdmin(address indexed newUpgradeAdmin);
    event InstallerSetGovernorAdmin(address indexed newGovernorAdmin);
    event InstallerInstallModule(uint indexed moduleId, address indexed moduleImpl, bytes32 moduleGitCommit);


    event GovSetAssetConfig(address indexed underlying, Storage.AssetConfig newConfig);
    event GovSetIRM(address indexed underlying, uint interestRateModel, bytes resetParams);
    event GovSetPricingConfig(address indexed underlying, uint16 newPricingType, uint32 newPricingParameter);
    event GovSetReserveFee(address indexed underlying, uint32 newReserveFee);
    event GovConvertReserves(address indexed underlying, address indexed recipient, uint amount);

    event RequestSwap(address indexed accountIn, address indexed accountOut, address indexed underlyingIn, address underlyingOut, uint amount, uint swapType);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

contract Proxy {
    address immutable creator;

    constructor() {
        creator = msg.sender;
    }

    // External interface

    fallback() external {
        address creator_ = creator;

        if (msg.sender == creator_) {
            assembly {
                mstore(0, 0)
                calldatacopy(31, 0, calldatasize())

                switch mload(0) // numTopics
                    case 0 { log0(32,  sub(calldatasize(), 1)) }
                    case 1 { log1(64,  sub(calldatasize(), 33),  mload(32)) }
                    case 2 { log2(96,  sub(calldatasize(), 65),  mload(32), mload(64)) }
                    case 3 { log3(128, sub(calldatasize(), 97),  mload(32), mload(64), mload(96)) }
                    case 4 { log4(160, sub(calldatasize(), 129), mload(32), mload(64), mload(96), mload(128)) }
                    default { revert(0, 0) }

                return(0, 0)
            }
        } else {
            assembly {
                mstore(0, 0xe9c4a3ac00000000000000000000000000000000000000000000000000000000) // dispatch() selector
                calldatacopy(4, 0, calldatasize())
                mstore(add(4, calldatasize()), shl(96, caller()))

                let result := call(gas(), creator_, 0, 0, add(24, calldatasize()), 0, 0)
                returndatacopy(0, 0, returndatasize())

                switch result
                    case 0 { revert(0, returndatasize()) }
                    default { return(0, returndatasize()) }
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

abstract contract Constants {
    // Universal

    uint internal constant SECONDS_PER_YEAR = 365.2425 * 86400; // Gregorian calendar


    // Protocol parameters

    uint internal constant MAX_SANE_AMOUNT = type(uint112).max;
    uint internal constant MAX_SANE_SMALL_AMOUNT = type(uint96).max;
    uint internal constant MAX_SANE_DEBT_AMOUNT = type(uint144).max;
    uint internal constant INTERNAL_DEBT_PRECISION = 1e9;
    uint internal constant MAX_ENTERED_MARKETS = 10; // per sub-account
    uint internal constant MAX_POSSIBLE_ENTERED_MARKETS = 2**32; // limited by size of AccountStorage.numMarketsEntered
    uint internal constant CONFIG_FACTOR_SCALE = 4_000_000_000; // must fit into a uint32
    uint internal constant RESERVE_FEE_SCALE = 4_000_000_000; // must fit into a uint32
    uint32 internal constant DEFAULT_RESERVE_FEE = uint32(0.23 * 4_000_000_000);
    uint internal constant INITIAL_INTEREST_ACCUMULATOR = 1e27;
    uint internal constant AVERAGE_LIQUIDITY_PERIOD = 24 * 60 * 60;
    uint16 internal constant MIN_UNISWAP3_OBSERVATION_CARDINALITY = 10;
    uint24 internal constant DEFAULT_TWAP_WINDOW_SECONDS = 30 * 60;
    uint32 internal constant DEFAULT_BORROW_FACTOR = uint32(0.28 * 4_000_000_000);


    // Implementation internals

    uint internal constant REENTRANCYLOCK__UNLOCKED = 1;
    uint internal constant REENTRANCYLOCK__LOCKED = 2;

    uint8 internal constant DEFERLIQUIDITY__NONE = 0;
    uint8 internal constant DEFERLIQUIDITY__CLEAN = 1;
    uint8 internal constant DEFERLIQUIDITY__DIRTY = 2;


    // Pricing types

    uint16 internal constant PRICINGTYPE__PEGGED = 1;
    uint16 internal constant PRICINGTYPE__UNISWAP3_TWAP = 2;
    uint16 internal constant PRICINGTYPE__FORWARDED = 3;


    // Modules

    // Public single-proxy modules
    uint internal constant MODULEID__INSTALLER = 1;
    uint internal constant MODULEID__MARKETS = 2;
    uint internal constant MODULEID__LIQUIDATION = 3;
    uint internal constant MODULEID__GOVERNANCE = 4;
    uint internal constant MODULEID__EXEC = 5;
    uint internal constant MODULEID__SWAP = 6;

    uint internal constant MAX_EXTERNAL_SINGLE_PROXY_MODULEID = 499_999;

    // Public multi-proxy modules
    uint internal constant MODULEID__ETOKEN = 500_000;
    uint internal constant MODULEID__DTOKEN = 500_001;

    uint internal constant MAX_EXTERNAL_MODULEID = 999_999;

    // Internal modules
    uint internal constant MODULEID__RISK_MANAGER = 1_000_000;

    // Interest rate models
    //   Default for new markets
    uint internal constant MODULEID__IRM_DEFAULT = 2_000_000;
    //   Testing-only
    uint internal constant MODULEID__IRM_ZERO = 2_000_001;
    uint internal constant MODULEID__IRM_FIXED = 2_000_002;
    uint internal constant MODULEID__IRM_LINEAR = 2_000_100;
    //   Classes
    uint internal constant MODULEID__IRM_CLASS__STABLE = 2_000_500;
    uint internal constant MODULEID__IRM_CLASS__MAJOR = 2_000_501;
    uint internal constant MODULEID__IRM_CLASS__MIDCAP = 2_000_502;

    // Swap types
    uint internal constant SWAP_TYPE__UNI_EXACT_INPUT_SINGLE = 1;
    uint internal constant SWAP_TYPE__UNI_EXACT_INPUT = 2;
    uint internal constant SWAP_TYPE__UNI_EXACT_OUTPUT_SINGLE = 3;
    uint internal constant SWAP_TYPE__UNI_EXACT_OUTPUT = 4;
    uint internal constant SWAP_TYPE__1INCH = 5;
}