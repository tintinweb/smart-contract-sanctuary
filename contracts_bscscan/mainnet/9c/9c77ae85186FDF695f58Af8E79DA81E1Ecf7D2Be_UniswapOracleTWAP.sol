// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "./UniswapConfig.sol";
import "./PosterAccessControl.sol";

import "./UniswapHelper.sol";
import "./IExternalOracle.sol";
import "./IERC20Extended.sol";
import "./IBeefyInterfaces.sol";

struct Observation {
    uint timestamp;
    uint acc;
}

contract UniswapOracleTWAP is UniswapConfig, PosterAccessControl {
    using FixedPoint for *;

    /// @notice The number of wei in 1 ETH
    uint public constant ethBaseUnit = 1e18;

    /// @notice A common scaling factor to maintain precision
    uint public constant expScale = 1e18;

    /// @notice The minimum amount of time in seconds required for the old uniswap price accumulator to be replaced
    uint public immutable anchorPeriod;

    /// @notice Official prices by symbol hash
    mapping(bytes32 => uint) public prices;

    /// @notice The old observation for each symbolHash
    mapping(bytes32 => Observation) public oldObservations;

    /// @notice The new observation for each symbolHash
    mapping(bytes32 => Observation) public newObservations;

    /// @notice Stores underlying address for different cTokens
    mapping(address => address) public underlyings;

    /// @notice The event emitted when the stored price is updated
    event PriceUpdated(string symbol, uint price);

    /// @notice The event emitted when the uniswap window changes
    event UniswapWindowUpdated(bytes32 indexed symbolHash, uint oldTimestamp, uint newTimestamp, uint oldPrice, uint newPrice);

    /// @notice The event emitted when the cToken underlying mapping is updated
    event CTokenUnderlyingUpdated(address cToken, address underlying);

    /// @notice The precision factor of base asset's (ETH) price 
    uint public basePricePrecision;

    string ETH;
    bytes32 public ethHash;

    constructor(uint anchorPeriod_, string memory baseAsset_, uint basePricePrecision_) public {
        require(basePricePrecision_ <= 1e36, "basePricePrecision_ max limit exceeded");

        anchorPeriod = anchorPeriod_;
        ETH = baseAsset_;
        ethHash = keccak256(abi.encodePacked(ETH));
        basePricePrecision = basePricePrecision_;
    }

    function _setConfig(TokenConfig memory config) public {
        // already performs some checks
        _setConfigInternal(config);

        require(config.baseUnit > 0, "baseUnit must be greater than zero");
        if (config.priceSource == PriceSource.UNISWAP) {
            address uniswapMarket = config.uniswapMarket;
            require(uniswapMarket != address(0), "must have uni market");
            if (config.isPairWithStablecoin) {
                uint8 decimals;
                // verify precision of quote currency (stablecoin)
                if (IUniswapV2Pair(uniswapMarket).token0() == config.underlying) {
                    decimals = IERC20(IUniswapV2Pair(uniswapMarket).token1()).decimals();
                } else {
                    decimals = IERC20(IUniswapV2Pair(uniswapMarket).token0()).decimals();
                }
                require(10 ** uint256(decimals) == basePricePrecision, "basePricePrecision mismatch");
            }
            bytes32 symbolHash = config.symbolHash;
            uint cumulativePrice = currentCumulativePrice(config);
            oldObservations[symbolHash].timestamp = block.timestamp;
            newObservations[symbolHash].timestamp = block.timestamp;
            oldObservations[symbolHash].acc = cumulativePrice;
            newObservations[symbolHash].acc = cumulativePrice;
            emit UniswapWindowUpdated(symbolHash, block.timestamp, block.timestamp, cumulativePrice, cumulativePrice);
        }
        if (config.priceSource == PriceSource.FIXED_USD) {
            require(config.fixedPrice != 0, "fixedPrice must be greater than zero");
        }
        if (config.priceSource == PriceSource.EXTERNAL_ORACLE) {
            require(config.externalOracle != address(0), "must have external oracle");
        }
        if (config.priceSource == PriceSource.BEEFY_VAULT) {
            // Note: These 18 decimals precision conditions may make this contract BSC specific
            require(IERC20(config.underlying).decimals() == 18, "underlying precision mismatch");
            IERC20 underlyingAsset = IBeefyVault(config.underlying).want();
            require(underlyingAsset.decimals() == 18, "want precision mismatch");
            require(
                getTokenConfigByUnderlying(address(underlyingAsset))
                    .priceSource != PriceSource.BEEFY_VAULT,
                "underlying asset priceSource can't be BEEFY_VAULT"
            );
        }
    }

    function _setConfigs(TokenConfig[] memory configs) external {
        for (uint i = 0; i < configs.length; i++) {
            _setConfig(configs[i]);
        }
    }

    function _setPrice(address underlying, string memory symbol, uint priceMantissa) public {
        require(msg.sender == poster, "Unauthorized");

        TokenConfig memory config = getTokenConfigByUnderlying(underlying);
        require(keccak256(abi.encodePacked(symbol)) == config.symbolHash, "Invalid symbol");

        if (config.priceSource == PriceSource.POSTER) {
            prices[config.symbolHash] = priceMantissa;
            emit PriceUpdated(symbol, priceMantissa);
        }
    }

    function _setUnderlyingForCToken(address cToken, address underlying) public {
        require(msg.sender == admin, "Unauthorized");
        require(underlyings[cToken] == address(0), "underlying already exists");
        require(cToken != address(0) && underlying != address(0), "invalid input");

        // token config for underlying must exist
        TokenConfig memory config = getTokenConfigByUnderlying(underlying);

        underlyings[cToken] = config.underlying;
        emit CTokenUnderlyingUpdated(cToken, config.underlying);
    }

    function _setUnderlyingForCTokens(address[] memory _cTokens, address[] memory _underlyings) public {
        require(_cTokens.length == _underlyings.length, "length mismatch");
        for (uint i = 0; i < _cTokens.length; i++) {
            _setUnderlyingForCToken(_cTokens[i], _underlyings[i]);
        }
    }

    /**
     * @notice Get the official price for a symbol
     * @param symbol The symbol to fetch the price of
     * @return Price denominated in USD
     */
    function price(string memory symbol) external view returns (uint) {
        TokenConfig memory config = getTokenConfigBySymbol(symbol);
        return priceInternal(config);
    }

    /**
     * @notice Get the official price for an underlying asset
     * @param underlying The address to fetch the price of
     * @return Price denominated in USD
     */
    function price(address underlying) public view returns (uint) {
        TokenConfig memory config = getTokenConfigByUnderlying(underlying);
        return priceInternal(config);
    }

    function priceInternal(TokenConfig memory config) internal view returns (uint) {
        if (config.priceSource == PriceSource.UNISWAP) return prices[config.symbolHash];
        if (config.priceSource == PriceSource.FIXED_USD) return config.fixedPrice;
        if (config.priceSource == PriceSource.POSTER) return prices[config.symbolHash];
        if (config.priceSource == PriceSource.EXTERNAL_ORACLE) {
            uint8 oracleDecimals = IExternalOracle(config.externalOracle).decimals();
            (, int256 answer, , , ) = IExternalOracle(config.externalOracle).latestRoundData();
            return mul(uint256(answer), basePricePrecision) / (10 ** uint256(oracleDecimals));
        }
        if (config.priceSource == PriceSource.BEEFY_VAULT) {
            uint priceInWantTokens = IBeefyVault(config.underlying).getPricePerFullShare();
            uint wantTokenUsdPrice = price(address(IBeefyVault(config.underlying).want()));
            return mul(priceInWantTokens, wantTokenUsdPrice) / expScale;
        }
    }

    /**
     * @notice Get the underlying price of a cToken
     * @dev Implements the PriceOracle interface for Compound v2.
     * @param cToken The cToken address for price retrieval
     * @return Price denominated in USD for the given cToken address
     */
    function getUnderlyingPrice(address cToken) external view returns (uint) {
        TokenConfig memory config = getTokenConfigByUnderlying(underlyings[cToken]);
        // Comptroller needs prices in the format: ${raw price} * 1e(36 - baseUnit)
        uint factor = 1e36 / basePricePrecision;
        return mul(factor, priceInternal(config)) / config.baseUnit;
    }

    /**
     * @notice Update oracle prices
     * @param cToken The cToken address
     */
    function updatePrice(address cToken) external {
        address underlying = underlyings[cToken];
        if (underlying != address(0)) {
            updateUnderlyingPrice(underlying);
        }
    }

    /**
     * @notice Update oracle prices
     * @param underlying The underlying address
     */
    function updateUnderlyingPrice(address underlying) public {
        updateEthPrice();
        TokenConfig memory config = getTokenConfigByUnderlying(underlying);

        if (config.symbolHash != ethHash) {
            uint ethPrice = prices[ethHash];
            // Try to update the storage
            updatePriceInternal(config.symbol, ethPrice);
        }
    }

    /**
     * @notice Update oracle prices
     * @param symbol The underlying symbol
     */
    function updatePrice(string memory symbol) external {
        updateEthPrice();
        if (keccak256(abi.encodePacked(symbol)) != ethHash) {
            uint ethPrice = prices[ethHash];
            // Try to update the storage
            updatePriceInternal(symbol, ethPrice);
        }
    }

    /**
     * @notice Open function to update all prices
     */
    function updateAllPrices() public {
        for (uint i = 0; i < numTokens; i++) {
            updateUnderlyingPrice(getTokenConfig(i).underlying);
        }
    }

    /**
     * @notice Update ETH price, and recalculate stored price by comparing to anchor
     */
    function updateEthPrice() public {
        uint ethPrice = fetchEthPrice();
        // Try to update the storage
        updatePriceInternal(ETH, ethPrice);
    }

    function updatePriceInternal(string memory symbol, uint ethPrice) internal {
        TokenConfig memory config = getTokenConfigBySymbol(symbol);

        if (config.priceSource == PriceSource.UNISWAP) {
            bytes32 symbolHash = keccak256(abi.encodePacked(symbol));
            uint anchorPrice;
            if (symbolHash == ethHash) {
                anchorPrice = ethPrice;
            } else if (config.isPairWithStablecoin) {
                anchorPrice = fetchAnchorPrice(config, ethBaseUnit);
            } else {
                anchorPrice = fetchAnchorPrice(config, ethPrice);
            }

            prices[symbolHash] = anchorPrice;
            emit PriceUpdated(symbol, anchorPrice);
        }
        if (config.priceSource == PriceSource.BEEFY_VAULT) {
            // update price for underlying 'want' asset
            address underlyingAsset = address(IBeefyVault(config.underlying).want());
            updateUnderlyingPrice(underlyingAsset);
        }
    }

    /**
     * @dev Fetches the current token/quoteCurrency price accumulator from uniswap.
     */
    function currentCumulativePrice(TokenConfig memory config) internal view returns (uint) {
        (uint cumulativePrice0, uint cumulativePrice1,) = UniswapV2OracleLibrary.currentCumulativePrices(config.uniswapMarket);
        if (config.isUniswapReversed) {
            return cumulativePrice1;
        } else {
            return cumulativePrice0;
        }
    }

    /**
     * @dev Fetches the current eth/usd price from uniswap, with basePricePrecision as precision.
     *  Conversion factor is 1e18 for eth/usd market, since we decode uniswap price statically with 18 decimals.
     */
    function fetchEthPrice() internal returns (uint) {
        return fetchAnchorPrice(getTokenConfigBySymbolHash(ethHash), ethBaseUnit);
    }

    /**
     * @dev Fetches the current token/usd price from uniswap, with basePricePrecision as precision.
     */
    function fetchAnchorPrice(TokenConfig memory config, uint conversionFactor) internal virtual returns (uint) {
        (uint nowCumulativePrice, uint oldCumulativePrice, uint oldTimestamp) = pokeWindowValues(config);

        // This should be impossible, but better safe than sorry
        require(block.timestamp > oldTimestamp, "now must come after before");
        uint timeElapsed = block.timestamp - oldTimestamp;

        // Calculate uniswap time-weighted average price
        // Underflow is a property of the accumulators: https://uniswap.org/audit.html#orgc9b3190
        FixedPoint.uq112x112 memory priceAverage = FixedPoint.uq112x112(uint224((nowCumulativePrice - oldCumulativePrice) / timeElapsed));
        uint rawUniswapPriceMantissa = priceAverage.decode112with18();
        uint unscaledPriceMantissa = mul(rawUniswapPriceMantissa, conversionFactor);
        uint anchorPrice;

        // Adjust rawUniswapPrice according to the units of the non-ETH asset
        // In the case of ETH, we would have to scale by 1e6 / USDC_UNITS, but since baseUnit2 is 1e6 (USDC), it cancels

        // In the case of non-ETH tokens
        // a. pokeWindowValues already handled uniswap reversed cases, so priceAverage will always be Token/ETH TWAP price.
        // b. conversionFactor = ETH price * 1e6
        // unscaledPriceMantissa = priceAverage(token/ETH TWAP price) * expScale * conversionFactor
        // so ->
        // anchorPrice = priceAverage * tokenBaseUnit / ethBaseUnit * ETH_price * 1e6
        //             = priceAverage * conversionFactor * tokenBaseUnit / ethBaseUnit
        //             = unscaledPriceMantissa / expScale * tokenBaseUnit / ethBaseUnit
        anchorPrice = mul(unscaledPriceMantissa, config.baseUnit) / ethBaseUnit / expScale;
        return anchorPrice;
    }

    /**
     * @dev Get time-weighted average prices for a token at the current timestamp.
     *  Update new and old observations of lagging window if period elapsed.
     */
    function pokeWindowValues(TokenConfig memory config) internal returns (uint, uint, uint) {
        bytes32 symbolHash = config.symbolHash;
        uint cumulativePrice = currentCumulativePrice(config);

        Observation memory newObservation = newObservations[symbolHash];

        // Update new and old observations if elapsed time is greater than or equal to anchor period
        uint timeElapsed = block.timestamp - newObservation.timestamp;
        if (timeElapsed >= anchorPeriod) {
            oldObservations[symbolHash].timestamp = newObservation.timestamp;
            oldObservations[symbolHash].acc = newObservation.acc;

            newObservations[symbolHash].timestamp = block.timestamp;
            newObservations[symbolHash].acc = cumulativePrice;
            emit UniswapWindowUpdated(config.symbolHash, newObservation.timestamp, block.timestamp, newObservation.acc, cumulativePrice);
        }
        return (cumulativePrice, oldObservations[symbolHash].acc, oldObservations[symbolHash].timestamp);
    }

    function getSymbolHash(string memory symbol) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(symbol));
    }

    /// @dev Overflow proof multiplication
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) return 0;
        uint c = a * b;
        require(c / a == b, "multiplication overflow");
        return c;
    }
}