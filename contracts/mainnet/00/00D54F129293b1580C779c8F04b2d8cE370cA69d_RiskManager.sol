// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../BaseLogic.sol";
import "../IRiskManager.sol";
import "../vendor/TickMath.sol";
import "../vendor/FullMath.sol";



interface IUniswapV3Factory {
    function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address pool);
}

interface IUniswapV3Pool {
    function slot0() external view returns (uint160 sqrtPriceX96, int24 tick, uint16 observationIndex, uint16 observationCardinality, uint16 observationCardinalityNext, uint8 feeProtocol, bool unlocked);
    function observe(uint32[] calldata secondsAgos) external view returns (int56[] memory tickCumulatives, uint160[] memory liquidityCumulatives);
    function observations(uint256 index) external view returns (uint32 blockTimestamp, int56 tickCumulative, uint160 liquidityCumulative, bool initialized);
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}


contract RiskManager is IRiskManager, BaseLogic {
    // Construction

    address immutable referenceAsset; // Token must have 18 decimals
    address immutable uniswapFactory;
    bytes32 immutable uniswapPoolInitCodeHash;

    struct RiskManagerSettings {
        address referenceAsset;
        address uniswapFactory;
        bytes32 uniswapPoolInitCodeHash;
    }

    constructor(bytes32 moduleGitCommit_, RiskManagerSettings memory settings) BaseLogic(MODULEID__RISK_MANAGER, moduleGitCommit_) {
        referenceAsset = settings.referenceAsset;
        uniswapFactory = settings.uniswapFactory;
        uniswapPoolInitCodeHash = settings.uniswapPoolInitCodeHash;
    }


    // Default market parameters

    function getNewMarketParameters(address underlying) external override returns (NewMarketParameters memory p) {
        p.config.borrowIsolated = true;
        p.config.collateralFactor = uint32(0);
        p.config.borrowFactor = type(uint32).max;
        p.config.twapWindow = type(uint24).max;

        if (underlying == referenceAsset) {
            // 1:1 peg

            p.pricingType = PRICINGTYPE__PEGGED;
            p.pricingParameters = uint32(0);
        } else if (pTokenLookup[underlying] != address(0)) {
            p.pricingType = PRICINGTYPE__FORWARDED;
            p.pricingParameters = uint32(0);

            p.config.collateralFactor = underlyingLookup[pTokenLookup[underlying]].collateralFactor;
        } else {
            // Uniswap3 TWAP

            // The selected fee level is the first existing pool found in the following order.
            // This may need to be corrected by a governance action if there is insufficient liquidity in the pool.

            uint24 fee;
            if (IUniswapV3Factory(uniswapFactory).getPool(underlying, referenceAsset, 3000) != address(0)) fee = 3000;
            else if (IUniswapV3Factory(uniswapFactory).getPool(underlying, referenceAsset, 500) != address(0)) fee = 500;
            else if (IUniswapV3Factory(uniswapFactory).getPool(underlying, referenceAsset, 10000) != address(0)) fee = 10000;
            else revert("e/no-uniswap-pool-avail");

            p.pricingType = PRICINGTYPE__UNISWAP3_TWAP;
            p.pricingParameters = uint32(fee);

            address pool = computeUniswapPoolAddress(underlying, fee);
            require(IUniswapV3Factory(uniswapFactory).getPool(underlying, referenceAsset, fee) == pool, "e/bad-uniswap-pool-addr");

            try IUniswapV3Pool(pool).increaseObservationCardinalityNext(MIN_UNISWAP3_OBSERVATION_CARDINALITY) {
                // Success
            } catch Error(string memory err) {
                if (keccak256(bytes(err)) == keccak256("LOK")) revert("e/risk/uniswap-pool-not-inited");
                revert(string(abi.encodePacked("e/risk/uniswap/", err)));
            } catch (bytes memory returnData) {
                revertBytes(returnData);
            }
        }
    }



    // Pricing

    function computeUniswapPoolAddress(address underlying, uint24 fee) private view returns (address) {
        address tokenA = underlying;
        address tokenB = referenceAsset;
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);

        return address(uint160(uint256(keccak256(abi.encodePacked(
                   hex'ff',
                   uniswapFactory,
                   keccak256(abi.encode(tokenA, tokenB, fee)),
                   uniswapPoolInitCodeHash
               )))));
    }


    function decodeSqrtPriceX96(AssetCache memory assetCache, uint sqrtPriceX96) private view returns (uint price) {
        if (uint160(assetCache.underlying) < uint160(referenceAsset)) {
            price = FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, uint(2**(96*2)) / 1e18) / assetCache.underlyingDecimalsScaler;
        } else {
            price = FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, uint(2**(96*2)) / (1e18 * assetCache.underlyingDecimalsScaler));
            if (price == 0) return 1e36;
            price = 1e36 / price;
        }

        if (price > 1e36) price = 1e36;
        else if (price == 0) price = 1;
    }

    function callUniswapObserve(AssetCache memory assetCache, address pool, uint ago) private returns (uint, uint) {
        uint32[] memory secondsAgos = new uint32[](2);

        secondsAgos[0] = uint32(ago);
        secondsAgos[1] = 0;

        (bool success, bytes memory data) = pool.staticcall(abi.encodeWithSelector(IUniswapV3Pool.observe.selector, secondsAgos));

        if (!success) {
            if (keccak256(data) != keccak256(abi.encodeWithSignature("Error(string)", "OLD"))) revertBytes(data);

            // The oldest available observation in the ring buffer is the index following the current (accounting for wrapping),
            // since this is the one that will be overwritten next.

            (,, uint16 index, uint16 cardinality, uint16 cardinalityNext,,) = IUniswapV3Pool(pool).slot0();

            (uint32 oldestAvailableAge,,,bool initialized) = IUniswapV3Pool(pool).observations((index + 1) % cardinality);

            // If the following observation in a ring buffer of our current cardinality is uninitialized, then all the
            // observations at higher indices are also uninitialized, so we wrap back to index 0, which we now know
            // to be the oldest available observation.

            if (!initialized) (oldestAvailableAge,,,) = IUniswapV3Pool(pool).observations(0);

            if (cardinality == cardinalityNext && cardinality < 65535) {
                // Apply negative feedback: If we don't have an observation old enough to satisfy the desired TWAP,
                // then increase the size of the ring buffer so that in the future hopefully we will.

                IUniswapV3Pool(pool).increaseObservationCardinalityNext(cardinality + 1);
            }

            // Call observe() again to get the oldest available

            ago = block.timestamp - oldestAvailableAge;
            secondsAgos[0] = uint32(ago);

            (success, data) = pool.staticcall(abi.encodeWithSelector(IUniswapV3Pool.observe.selector, secondsAgos));
            if (!success) revertBytes(data);
        }

        // If uniswap pool doesn't exist, then data will be empty and this decode will throw:

        int56[] memory tickCumulatives = abi.decode(data, (int56[])); // don't bother decoding the liquidityCumulatives array

        int24 tick = int24((tickCumulatives[1] - tickCumulatives[0]) / int56(int(ago)));

        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(tick);

        return (decodeSqrtPriceX96(assetCache, sqrtPriceX96), ago);
    }

    function resolvePricingConfig(AssetCache memory assetCache, AssetConfig memory config) private view returns (address underlying, uint16 pricingType, uint32 pricingParameters, uint24 twapWindow) {
        if (assetCache.pricingType == PRICINGTYPE__FORWARDED) {
            underlying = pTokenLookup[assetCache.underlying];

            AssetConfig memory newConfig = resolveAssetConfig(underlying);
            twapWindow = newConfig.twapWindow;

            AssetStorage storage newAssetStorage = eTokenLookup[newConfig.eTokenAddress];
            pricingType = newAssetStorage.pricingType;
            pricingParameters = newAssetStorage.pricingParameters;

            require(pricingType != PRICINGTYPE__FORWARDED, "e/nested-price-forwarding");
        } else {
            underlying = assetCache.underlying;
            pricingType = assetCache.pricingType;
            pricingParameters = assetCache.pricingParameters;
            twapWindow = config.twapWindow;
        }
    }

    function getPriceInternal(AssetCache memory assetCache, AssetConfig memory config) public FREEMEM returns (uint twap, uint twapPeriod) {
        (address underlying, uint16 pricingType, uint32 pricingParameters, uint24 twapWindow) = resolvePricingConfig(assetCache, config);

        if (pricingType == PRICINGTYPE__PEGGED) {
            twap = 1e18;
            twapPeriod = twapWindow;
        } else if (pricingType == PRICINGTYPE__UNISWAP3_TWAP) {
            address pool = computeUniswapPoolAddress(underlying, uint24(pricingParameters));
            (twap, twapPeriod) = callUniswapObserve(assetCache, pool, twapWindow);
        } else {
            revert("e/unknown-pricing-type");
        }
    }

    function getPrice(address underlying) external override returns (uint twap, uint twapPeriod) {
        AssetConfig memory config = resolveAssetConfig(underlying);
        AssetStorage storage assetStorage = eTokenLookup[config.eTokenAddress];
        AssetCache memory assetCache = loadAssetCache(underlying, assetStorage);

        (twap, twapPeriod) = getPriceInternal(assetCache, config);
    }

    // This function is only meant to be called from a view so it doesn't need to be optimised.
    // The Euler protocol itself doesn't ever use currPrice as returned by this function.

    function getPriceFull(address underlying) external override returns (uint twap, uint twapPeriod, uint currPrice) {
        AssetConfig memory config = resolveAssetConfig(underlying);
        AssetStorage storage assetStorage = eTokenLookup[config.eTokenAddress];
        AssetCache memory assetCache = loadAssetCache(underlying, assetStorage);

        (twap, twapPeriod) = getPriceInternal(assetCache, config);

        (address newUnderlying, uint16 pricingType, uint32 pricingParameters,) = resolvePricingConfig(assetCache, config);

        if (pricingType == PRICINGTYPE__PEGGED) {
            currPrice = 1e18;
        } else if (pricingType == PRICINGTYPE__UNISWAP3_TWAP || pricingType == PRICINGTYPE__FORWARDED) {
            AssetCache memory newAssetCache = loadAssetCache(newUnderlying, assetStorage);
            address pool = computeUniswapPoolAddress(newUnderlying, uint24(pricingParameters));
            (uint160 sqrtPriceX96,,,,,,) = IUniswapV3Pool(pool).slot0();
            currPrice = decodeSqrtPriceX96(newAssetCache, sqrtPriceX96);
        } else {
            revert("e/unknown-pricing-type");
        }
    }


    // Liquidity

    function computeLiquidityRaw(address account, address[] memory underlyings) private returns (LiquidityStatus memory status) {
        status.collateralValue = 0;
        status.liabilityValue = 0;
        status.numBorrows = 0;
        status.borrowIsolated = false;

        AssetConfig memory config;
        AssetStorage storage assetStorage;
        AssetCache memory assetCache;

        for (uint i = 0; i < underlyings.length; ++i) {
            address underlying = underlyings[i];
            bool assetCacheAndPriceInited = false;
            uint price;

            config = resolveAssetConfig(underlying);
            assetStorage = eTokenLookup[config.eTokenAddress];

            uint balance = assetStorage.users[account].balance;
            uint owed = assetStorage.users[account].owed;

            if (balance != 0 && config.collateralFactor != 0) {
                initAssetCache(underlying, assetStorage, assetCache);
                (price,) = getPriceInternal(assetCache, config);
                assetCacheAndPriceInited = true;

                uint assetCollateral = balanceToUnderlyingAmount(assetCache, balance);
                assetCollateral = assetCollateral * price / 1e18;
                assetCollateral = assetCollateral * config.collateralFactor / CONFIG_FACTOR_SCALE;
                status.collateralValue += assetCollateral;
            }

            if (owed != 0) {
                if (!assetCacheAndPriceInited) {
                    initAssetCache(underlying, assetStorage, assetCache);
                    (price,) = getPriceInternal(assetCache, config);
                    assetCacheAndPriceInited = true;
                }

                status.numBorrows++;
                if (config.borrowIsolated) status.borrowIsolated = true;

                uint assetLiability = getCurrentOwed(assetStorage, assetCache, account);
                assetLiability = assetLiability * price / 1e18;
                assetLiability = assetLiability * CONFIG_FACTOR_SCALE / config.borrowFactor;
                status.liabilityValue += assetLiability;
            }
        }
    }

    function computeLiquidity(address account) public override returns (LiquidityStatus memory) {
        return computeLiquidityRaw(account, getEnteredMarketsArray(account));
    }

    function computeAssetLiquidities(address account) external override returns (AssetLiquidity[] memory) {
        address[] memory underlyings = getEnteredMarketsArray(account);

        AssetLiquidity[] memory output = new AssetLiquidity[](underlyings.length);

        address[] memory singleUnderlying = new address[](1);

        for (uint i = 0; i < underlyings.length; ++i) {
            output[i].underlying = singleUnderlying[0] = underlyings[i];
            output[i].status = computeLiquidityRaw(account, singleUnderlying);
        }

        return output;
    }

    function requireLiquidity(address account) external override {
        LiquidityStatus memory status = computeLiquidity(account);

        require(!status.borrowIsolated || status.numBorrows == 1, "e/borrow-isolation-violation");
        require(status.collateralValue >= status.liabilityValue, "e/collateral-violation");
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

// From Uniswap3 Core

// Updated to Solidity 0.8 by Euler:
//   * Cast MAX_TICK to int256 before casting to uint
//   * Wrapped function bodies with "unchecked {}" so as to not add any extra gas costs

pragma solidity ^0.8.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
      unchecked {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(int(MAX_TICK)), 'T');

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
      }
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
      unchecked {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, 'R');
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
      }
    }
}

// SPDX-License-Identifier: MIT

// From Uniswap3 Core

// Updated to Solidity 0.8 by Euler:
//   * Rewrite unary negation of denominator, which is a uint
//   * Wrapped function bodies with "unchecked {}" so as to not add any extra gas costs

pragma solidity ^0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
      unchecked {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = denominator & (~denominator + 1);

        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
      }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
      unchecked {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
      }
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