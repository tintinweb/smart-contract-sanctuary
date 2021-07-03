// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./UniswapConfig.sol";
import "./UniswapLib.sol";
import "../Ownable.sol";
import "../Chainlink/AggregatorValidatorInterface.sol";

struct Observation {
    uint timestamp;
    uint acc;
}

struct PriceData {
    uint248 price;
    bool failoverActive;
}

contract UniswapAnchoredView is AggregatorValidatorInterface, UniswapConfig, Ownable {
    using FixedPoint for *;

    /// @notice The number of wei in 1 ETH
    uint public constant ethBaseUnit = 1e18;

    /// @notice A common scaling factor to maintain precision
    uint public constant expScale = 1e18;

    /// @notice The highest ratio of the new price to the anchor price that will still trigger the price to be updated
    uint public immutable upperBoundAnchorRatio;

    /// @notice The lowest ratio of the new price to the anchor price that will still trigger the price to be updated
    uint public immutable lowerBoundAnchorRatio;

    /// @notice The minimum amount of time in seconds required for the old uniswap price accumulator to be replaced
    uint public immutable anchorPeriod;

    /// @notice Official prices by symbol hash
    mapping(bytes32 => PriceData) public prices;

    /// @notice The old observation for each symbolHash
    mapping(bytes32 => Observation) public oldObservations;

    /// @notice The new observation for each symbolHash
    mapping(bytes32 => Observation) public newObservations;

    /// @notice The event emitted when new prices are posted but the stored price is not updated due to the anchor
    event PriceGuarded(bytes32 indexed symbolHash, uint reporter, uint anchor);

    /// @notice The event emitted when the stored price is updated
    event PriceUpdated(bytes32 indexed symbolHash, uint price);

    /// @notice The event emitted when anchor price is updated
    event AnchorPriceUpdated(bytes32 indexed symbolHash, uint anchorPrice, uint oldTimestamp, uint newTimestamp);

    /// @notice The event emitted when the uniswap window changes
    event UniswapWindowUpdated(bytes32 indexed symbolHash, uint oldTimestamp, uint newTimestamp, uint oldPrice, uint newPrice);

    /// @notice The event emitted when failover is activated
    event FailoverActivated(bytes32 indexed symbolHash);

    /// @notice The event emitted when failover is deactivated
    event FailoverDeactivated(bytes32 indexed symbolHash);

    bytes32 constant ethHash = keccak256(abi.encodePacked("ETH"));

    /**
     * @notice Construct a uniswap anchored view for a set of token configurations
     * @dev Note that to avoid immature TWAPs, the system must run for at least a single anchorPeriod before using.
     *      NOTE: Reported prices are set to 1 during construction. We assume that this contract will not be voted in by
     *      governance until prices have been updated through `validate` for each TokenConfig.
     * @param anchorToleranceMantissa_ The percentage tolerance that the reporter may deviate from the uniswap anchor
     * @param anchorPeriod_ The minimum amount of time required for the old uniswap price accumulator to be replaced
     * @param configs The static token configurations which define what prices are supported and how
     */
    constructor(uint anchorToleranceMantissa_,
                uint anchorPeriod_,
                TokenConfig[] memory configs) UniswapConfig(configs) public {

        anchorPeriod = anchorPeriod_;

        // Allow the tolerance to be whatever the deployer chooses, but prevent under/overflow (and prices from being 0)
        upperBoundAnchorRatio = anchorToleranceMantissa_ > uint(-1) - 100e16 ? uint(-1) : 100e16 + anchorToleranceMantissa_;
        lowerBoundAnchorRatio = anchorToleranceMantissa_ < 100e16 ? 100e16 - anchorToleranceMantissa_ : 1;

        for (uint i = 0; i < configs.length; i++) {
            TokenConfig memory config = configs[i];
            require(config.baseUnit > 0, "baseUnit must be greater than zero");
            address uniswapMarket = config.uniswapMarket;
            if (config.priceSource == PriceSource.REPORTER) {
                require(uniswapMarket != address(0), "reported prices must have an anchor");
                require(config.reporter != address(0), "reported price must have a reporter");
                bytes32 symbolHash = config.symbolHash;
                prices[symbolHash].price = 1;
                uint cumulativePrice = currentCumulativePrice(config);
                oldObservations[symbolHash].timestamp = block.timestamp;
                newObservations[symbolHash].timestamp = block.timestamp;
                oldObservations[symbolHash].acc = cumulativePrice;
                newObservations[symbolHash].acc = cumulativePrice;
                emit UniswapWindowUpdated(symbolHash, block.timestamp, block.timestamp, cumulativePrice, cumulativePrice);
            } else {
                require(uniswapMarket == address(0), "only reported prices utilize an anchor");
            }
        }
    }

    /**
     * @notice Get the official price for a symbol
     * @param symbol The symbol to fetch the price of
     * @return Price denominated in USD, with 6 decimals
     */
    function price(string memory symbol) external view returns (uint) {
        TokenConfig memory config = getTokenConfigBySymbol(symbol);
        return priceInternal(config);
    }

    function priceInternal(TokenConfig memory config) internal view returns (uint) {
        if (config.priceSource == PriceSource.REPORTER) return prices[config.symbolHash].price;
        // config.fixedPrice holds a fixed-point number with scaling factor 10**6 for FIXED_USD
        if (config.priceSource == PriceSource.FIXED_USD) return config.fixedPrice;
        if (config.priceSource == PriceSource.FIXED_ETH) {
            uint usdPerEth = prices[ethHash].price;
            require(usdPerEth > 0, "ETH price not set, cannot convert to dollars");
            // config.fixedPrice holds a fixed-point number with scaling factor 10**18 for FIXED_ETH
            return mul(usdPerEth, config.fixedPrice) / ethBaseUnit;
        }
    }

    /**
     * @notice Get the underlying price of a cToken
     * @dev Implements the PriceOracle interface for Compound v2.
     * @param cToken The cToken address for price retrieval
     * @return Price denominated in USD, with 18 decimals, for the given cToken address
     */
    function getUnderlyingPrice(address cToken) external view returns (uint) {
        TokenConfig memory config = getTokenConfigByCToken(cToken);
         // Comptroller needs prices in the format: ${raw price} * 1e36 / baseUnit
         // The baseUnit of an asset is the amount of the smallest denomination of that asset per whole.
         // For example, the baseUnit of ETH is 1e18.
         // Since the prices in this view have 6 decimals, we must scale them by 1e(36 - 6)/baseUnit
        return mul(1e30, priceInternal(config)) / config.baseUnit;
    }

    /**
     * @notice This is called by the reporter whenever a new price is posted on-chain
     * @dev called by AccessControlledOffchainAggregator
     * @param currentAnswer the price
     * @return valid bool
     */
    function validate(uint256/* previousRoundId */,
            int256 /* previousAnswer */,
            uint256 /* currentRoundId */,
            int256 currentAnswer) external override returns (bool valid) {

        // NOTE: We don't do any access control on msg.sender here. The access control is done in getTokenConfigByReporter,
        // which will REVERT if an unauthorized address is passed.
        TokenConfig memory config = getTokenConfigByReporter(msg.sender);
        uint256 reportedPrice = convertReportedPrice(config, currentAnswer);
        uint256 anchorPrice = calculateAnchorPriceFromEthPrice(config);

        PriceData memory priceData = prices[config.symbolHash];
        if (priceData.failoverActive) {
            require(anchorPrice < 2**248, "Anchor price too large");
            prices[config.symbolHash].price = uint248(anchorPrice);
            emit PriceUpdated(config.symbolHash, anchorPrice);
        } else if (isWithinAnchor(reportedPrice, anchorPrice)) {
            require(reportedPrice < 2**248, "Reported price too large");
            prices[config.symbolHash].price = uint248(reportedPrice);
            emit PriceUpdated(config.symbolHash, reportedPrice);
            valid = true;
        } else {
            emit PriceGuarded(config.symbolHash, reportedPrice, anchorPrice);
        }
    }

    /**
     * @notice In the event that a feed is failed over to Uniswap TWAP, this function can be called
     * by anyone to update the TWAP price.
     * @dev This only works if the feed represented by the symbolHash is failed over, and will revert otherwise
     * @param symbolHash bytes32
     */
    function pokeFailedOverPrice(bytes32 symbolHash) public {
        PriceData memory priceData = prices[symbolHash];
        require(priceData.failoverActive, "Failover must be active");
        TokenConfig memory config = getTokenConfigBySymbolHash(symbolHash);
        uint anchorPrice = calculateAnchorPriceFromEthPrice(config);
        require(anchorPrice < 2**248, "Anchor price too large");
        prices[config.symbolHash].price = uint248(anchorPrice);
        emit PriceUpdated(config.symbolHash, anchorPrice);
    }

    /**
     * @notice Calculate the anchor price by fetching price data from the TWAP
     * @param config TokenConfig
     * @return anchorPrice uint
     */
    function calculateAnchorPriceFromEthPrice(TokenConfig memory config) internal returns (uint anchorPrice) {
        uint ethPrice = fetchEthAnchorPrice();
        require(config.priceSource == PriceSource.REPORTER, "only reporter prices get posted");
        if (config.symbolHash == ethHash) {
            anchorPrice = ethPrice;
        } else {
            anchorPrice = fetchAnchorPrice(config.symbolHash, config, ethPrice);
        }
    }

    /**
     * @notice Convert the reported price to the 6 decimal format that this view requires
     * @param config TokenConfig
     * @param reportedPrice from the reporter
     * @return convertedPrice uint256
     */
    function convertReportedPrice(TokenConfig memory config, int256 reportedPrice) internal pure returns (uint256) {
        require(reportedPrice >= 0, "Reported price cannot be negative");
        uint256 unsignedPrice = uint256(reportedPrice);
        uint256 convertedPrice = mul(unsignedPrice, config.reporterMultiplier) / config.baseUnit;
        return convertedPrice;
    }


    function isWithinAnchor(uint reporterPrice, uint anchorPrice) internal view returns (bool) {
        if (reporterPrice > 0) {
            uint anchorRatio = mul(anchorPrice, 100e16) / reporterPrice;
            return anchorRatio <= upperBoundAnchorRatio && anchorRatio >= lowerBoundAnchorRatio;
        }
        return false;
    }

    /**
     * @dev Fetches the current token/eth price accumulator from uniswap.
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
     * @dev Fetches the current eth/usd price from uniswap, with 6 decimals of precision.
     *  Conversion factor is 1e18 for eth/usdc market, since we decode uniswap price statically with 18 decimals.
     */
    function fetchEthAnchorPrice() internal returns (uint) {
        return fetchAnchorPrice(ethHash, getTokenConfigBySymbolHash(ethHash), ethBaseUnit);
    }

    /**
     * @dev Fetches the current token/usd price from uniswap, with 6 decimals of precision.
     * @param conversionFactor 1e18 if seeking the ETH price, and a 6 decimal ETH-USDC price in the case of other assets
     */
    function fetchAnchorPrice(bytes32 symbolHash, TokenConfig memory config, uint conversionFactor) internal virtual returns (uint) {
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

        emit AnchorPriceUpdated(symbolHash, anchorPrice, oldTimestamp, block.timestamp);

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

    /**
     * @notice Activate failover, and fall back to using failover directly.
     * @dev Only the owner can call this function
     */
    function activateFailover(bytes32 symbolHash) external onlyOwner() {
        require(!prices[symbolHash].failoverActive, "Already activated");
        prices[symbolHash].failoverActive = true;
        emit FailoverActivated(symbolHash);
        pokeFailedOverPrice(symbolHash);
    }

    /**
     * @notice Deactivate a previously activated failover
     * @dev Only the owner can call this function
     */
    function deactivateFailover(bytes32 symbolHash) external onlyOwner() {
        require(prices[symbolHash].failoverActive, "Already deactivated");
        prices[symbolHash].failoverActive = false;
        emit FailoverDeactivated(symbolHash);
    }

    /// @dev Overflow proof multiplication
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) return 0;
        uint c = a * b;
        require(c / a == b, "multiplication overflow");
        return c;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface CErc20 {
    function underlying() external view returns (address);
}

contract UniswapConfig {
    /// @dev Describe how to interpret the fixedPrice in the TokenConfig.
    enum PriceSource {
        FIXED_ETH, /// implies the fixedPrice is a constant multiple of the ETH price (which varies)
        FIXED_USD, /// implies the fixedPrice is a constant multiple of the USD price (which is 1)
        REPORTER   /// implies the price is set by the reporter
    }

    /// @dev Describe how the USD price should be determined for an asset.
    ///  There should be 1 TokenConfig object for each supported asset, passed in the constructor.
    struct TokenConfig {
        address cToken;
        address underlying;
        bytes32 symbolHash;
        uint256 baseUnit;
        PriceSource priceSource;
        uint256 fixedPrice;
        address uniswapMarket;
        address reporter;
        uint256 reporterMultiplier;
        bool isUniswapReversed;
    }

    /// @notice The max number of tokens this contract is hardcoded to support
    /// @dev Do not change this variable without updating all the fields throughout the contract.
    uint public constant maxTokens = 25;

    /// @notice The number of tokens this contract actually supports
    uint public immutable numTokens;

    address internal immutable cToken00;
    address internal immutable cToken01;
    address internal immutable cToken02;
    address internal immutable cToken03;
    address internal immutable cToken04;
    address internal immutable cToken05;
    address internal immutable cToken06;
    address internal immutable cToken07;
    address internal immutable cToken08;
    address internal immutable cToken09;
    address internal immutable cToken10;
    address internal immutable cToken11;
    address internal immutable cToken12;
    address internal immutable cToken13;
    address internal immutable cToken14;
    address internal immutable cToken15;
    address internal immutable cToken16;
    address internal immutable cToken17;
    address internal immutable cToken18;
    address internal immutable cToken19;
    address internal immutable cToken20;
    address internal immutable cToken21;
    address internal immutable cToken22;
    address internal immutable cToken23;
    address internal immutable cToken24;

    address internal immutable underlying00;
    address internal immutable underlying01;
    address internal immutable underlying02;
    address internal immutable underlying03;
    address internal immutable underlying04;
    address internal immutable underlying05;
    address internal immutable underlying06;
    address internal immutable underlying07;
    address internal immutable underlying08;
    address internal immutable underlying09;
    address internal immutable underlying10;
    address internal immutable underlying11;
    address internal immutable underlying12;
    address internal immutable underlying13;
    address internal immutable underlying14;
    address internal immutable underlying15;
    address internal immutable underlying16;
    address internal immutable underlying17;
    address internal immutable underlying18;
    address internal immutable underlying19;
    address internal immutable underlying20;
    address internal immutable underlying21;
    address internal immutable underlying22;
    address internal immutable underlying23;
    address internal immutable underlying24;

    bytes32 internal immutable symbolHash00;
    bytes32 internal immutable symbolHash01;
    bytes32 internal immutable symbolHash02;
    bytes32 internal immutable symbolHash03;
    bytes32 internal immutable symbolHash04;
    bytes32 internal immutable symbolHash05;
    bytes32 internal immutable symbolHash06;
    bytes32 internal immutable symbolHash07;
    bytes32 internal immutable symbolHash08;
    bytes32 internal immutable symbolHash09;
    bytes32 internal immutable symbolHash10;
    bytes32 internal immutable symbolHash11;
    bytes32 internal immutable symbolHash12;
    bytes32 internal immutable symbolHash13;
    bytes32 internal immutable symbolHash14;
    bytes32 internal immutable symbolHash15;
    bytes32 internal immutable symbolHash16;
    bytes32 internal immutable symbolHash17;
    bytes32 internal immutable symbolHash18;
    bytes32 internal immutable symbolHash19;
    bytes32 internal immutable symbolHash20;
    bytes32 internal immutable symbolHash21;
    bytes32 internal immutable symbolHash22;
    bytes32 internal immutable symbolHash23;
    bytes32 internal immutable symbolHash24;

    uint256 internal immutable baseUnit00;
    uint256 internal immutable baseUnit01;
    uint256 internal immutable baseUnit02;
    uint256 internal immutable baseUnit03;
    uint256 internal immutable baseUnit04;
    uint256 internal immutable baseUnit05;
    uint256 internal immutable baseUnit06;
    uint256 internal immutable baseUnit07;
    uint256 internal immutable baseUnit08;
    uint256 internal immutable baseUnit09;
    uint256 internal immutable baseUnit10;
    uint256 internal immutable baseUnit11;
    uint256 internal immutable baseUnit12;
    uint256 internal immutable baseUnit13;
    uint256 internal immutable baseUnit14;
    uint256 internal immutable baseUnit15;
    uint256 internal immutable baseUnit16;
    uint256 internal immutable baseUnit17;
    uint256 internal immutable baseUnit18;
    uint256 internal immutable baseUnit19;
    uint256 internal immutable baseUnit20;
    uint256 internal immutable baseUnit21;
    uint256 internal immutable baseUnit22;
    uint256 internal immutable baseUnit23;
    uint256 internal immutable baseUnit24;

    PriceSource internal immutable priceSource00;
    PriceSource internal immutable priceSource01;
    PriceSource internal immutable priceSource02;
    PriceSource internal immutable priceSource03;
    PriceSource internal immutable priceSource04;
    PriceSource internal immutable priceSource05;
    PriceSource internal immutable priceSource06;
    PriceSource internal immutable priceSource07;
    PriceSource internal immutable priceSource08;
    PriceSource internal immutable priceSource09;
    PriceSource internal immutable priceSource10;
    PriceSource internal immutable priceSource11;
    PriceSource internal immutable priceSource12;
    PriceSource internal immutable priceSource13;
    PriceSource internal immutable priceSource14;
    PriceSource internal immutable priceSource15;
    PriceSource internal immutable priceSource16;
    PriceSource internal immutable priceSource17;
    PriceSource internal immutable priceSource18;
    PriceSource internal immutable priceSource19;
    PriceSource internal immutable priceSource20;
    PriceSource internal immutable priceSource21;
    PriceSource internal immutable priceSource22;
    PriceSource internal immutable priceSource23;
    PriceSource internal immutable priceSource24;

    uint256 internal immutable fixedPrice00;
    uint256 internal immutable fixedPrice01;
    uint256 internal immutable fixedPrice02;
    uint256 internal immutable fixedPrice03;
    uint256 internal immutable fixedPrice04;
    uint256 internal immutable fixedPrice05;
    uint256 internal immutable fixedPrice06;
    uint256 internal immutable fixedPrice07;
    uint256 internal immutable fixedPrice08;
    uint256 internal immutable fixedPrice09;
    uint256 internal immutable fixedPrice10;
    uint256 internal immutable fixedPrice11;
    uint256 internal immutable fixedPrice12;
    uint256 internal immutable fixedPrice13;
    uint256 internal immutable fixedPrice14;
    uint256 internal immutable fixedPrice15;
    uint256 internal immutable fixedPrice16;
    uint256 internal immutable fixedPrice17;
    uint256 internal immutable fixedPrice18;
    uint256 internal immutable fixedPrice19;
    uint256 internal immutable fixedPrice20;
    uint256 internal immutable fixedPrice21;
    uint256 internal immutable fixedPrice22;
    uint256 internal immutable fixedPrice23;
    uint256 internal immutable fixedPrice24;

    address internal immutable uniswapMarket00;
    address internal immutable uniswapMarket01;
    address internal immutable uniswapMarket02;
    address internal immutable uniswapMarket03;
    address internal immutable uniswapMarket04;
    address internal immutable uniswapMarket05;
    address internal immutable uniswapMarket06;
    address internal immutable uniswapMarket07;
    address internal immutable uniswapMarket08;
    address internal immutable uniswapMarket09;
    address internal immutable uniswapMarket10;
    address internal immutable uniswapMarket11;
    address internal immutable uniswapMarket12;
    address internal immutable uniswapMarket13;
    address internal immutable uniswapMarket14;
    address internal immutable uniswapMarket15;
    address internal immutable uniswapMarket16;
    address internal immutable uniswapMarket17;
    address internal immutable uniswapMarket18;
    address internal immutable uniswapMarket19;
    address internal immutable uniswapMarket20;
    address internal immutable uniswapMarket21;
    address internal immutable uniswapMarket22;
    address internal immutable uniswapMarket23;
    address internal immutable uniswapMarket24;

    address internal immutable reporter00;
    address internal immutable reporter01;
    address internal immutable reporter02;
    address internal immutable reporter03;
    address internal immutable reporter04;
    address internal immutable reporter05;
    address internal immutable reporter06;
    address internal immutable reporter07;
    address internal immutable reporter08;
    address internal immutable reporter09;
    address internal immutable reporter10;
    address internal immutable reporter11;
    address internal immutable reporter12;
    address internal immutable reporter13;
    address internal immutable reporter14;
    address internal immutable reporter15;
    address internal immutable reporter16;
    address internal immutable reporter17;
    address internal immutable reporter18;
    address internal immutable reporter19;
    address internal immutable reporter20;
    address internal immutable reporter21;
    address internal immutable reporter22;
    address internal immutable reporter23;
    address internal immutable reporter24;

    uint256 internal immutable reporterMultiplier00;
    uint256 internal immutable reporterMultiplier01;
    uint256 internal immutable reporterMultiplier02;
    uint256 internal immutable reporterMultiplier03;
    uint256 internal immutable reporterMultiplier04;
    uint256 internal immutable reporterMultiplier05;
    uint256 internal immutable reporterMultiplier06;
    uint256 internal immutable reporterMultiplier07;
    uint256 internal immutable reporterMultiplier08;
    uint256 internal immutable reporterMultiplier09;
    uint256 internal immutable reporterMultiplier10;
    uint256 internal immutable reporterMultiplier11;
    uint256 internal immutable reporterMultiplier12;
    uint256 internal immutable reporterMultiplier13;
    uint256 internal immutable reporterMultiplier14;
    uint256 internal immutable reporterMultiplier15;
    uint256 internal immutable reporterMultiplier16;
    uint256 internal immutable reporterMultiplier17;
    uint256 internal immutable reporterMultiplier18;
    uint256 internal immutable reporterMultiplier19;
    uint256 internal immutable reporterMultiplier20;
    uint256 internal immutable reporterMultiplier21;
    uint256 internal immutable reporterMultiplier22;
    uint256 internal immutable reporterMultiplier23;
    uint256 internal immutable reporterMultiplier24;

    bool internal immutable isUniswapReversed00;
    bool internal immutable isUniswapReversed01;
    bool internal immutable isUniswapReversed02;
    bool internal immutable isUniswapReversed03;
    bool internal immutable isUniswapReversed04;
    bool internal immutable isUniswapReversed05;
    bool internal immutable isUniswapReversed06;
    bool internal immutable isUniswapReversed07;
    bool internal immutable isUniswapReversed08;
    bool internal immutable isUniswapReversed09;
    bool internal immutable isUniswapReversed10;
    bool internal immutable isUniswapReversed11;
    bool internal immutable isUniswapReversed12;
    bool internal immutable isUniswapReversed13;
    bool internal immutable isUniswapReversed14;
    bool internal immutable isUniswapReversed15;
    bool internal immutable isUniswapReversed16;
    bool internal immutable isUniswapReversed17;
    bool internal immutable isUniswapReversed18;
    bool internal immutable isUniswapReversed19;
    bool internal immutable isUniswapReversed20;
    bool internal immutable isUniswapReversed21;
    bool internal immutable isUniswapReversed22;
    bool internal immutable isUniswapReversed23;
    bool internal immutable isUniswapReversed24;

    /**
     * @notice Construct an immutable store of configs into the contract data
     * @param configs The configs for the supported assets
     */
    constructor(TokenConfig[] memory configs) public {
        require(configs.length <= maxTokens, "too many configs");
        numTokens = configs.length;

        cToken00 = get(configs, 0).cToken;
        cToken01 = get(configs, 1).cToken;
        cToken02 = get(configs, 2).cToken;
        cToken03 = get(configs, 3).cToken;
        cToken04 = get(configs, 4).cToken;
        cToken05 = get(configs, 5).cToken;
        cToken06 = get(configs, 6).cToken;
        cToken07 = get(configs, 7).cToken;
        cToken08 = get(configs, 8).cToken;
        cToken09 = get(configs, 9).cToken;
        cToken10 = get(configs, 10).cToken;
        cToken11 = get(configs, 11).cToken;
        cToken12 = get(configs, 12).cToken;
        cToken13 = get(configs, 13).cToken;
        cToken14 = get(configs, 14).cToken;
        cToken15 = get(configs, 15).cToken;
        cToken16 = get(configs, 16).cToken;
        cToken17 = get(configs, 17).cToken;
        cToken18 = get(configs, 18).cToken;
        cToken19 = get(configs, 19).cToken;
        cToken20 = get(configs, 20).cToken;
        cToken21 = get(configs, 21).cToken;
        cToken22 = get(configs, 22).cToken;
        cToken23 = get(configs, 23).cToken;
        cToken24 = get(configs, 24).cToken;

        underlying00 = get(configs, 0).underlying;
        underlying01 = get(configs, 1).underlying;
        underlying02 = get(configs, 2).underlying;
        underlying03 = get(configs, 3).underlying;
        underlying04 = get(configs, 4).underlying;
        underlying05 = get(configs, 5).underlying;
        underlying06 = get(configs, 6).underlying;
        underlying07 = get(configs, 7).underlying;
        underlying08 = get(configs, 8).underlying;
        underlying09 = get(configs, 9).underlying;
        underlying10 = get(configs, 10).underlying;
        underlying11 = get(configs, 11).underlying;
        underlying12 = get(configs, 12).underlying;
        underlying13 = get(configs, 13).underlying;
        underlying14 = get(configs, 14).underlying;
        underlying15 = get(configs, 15).underlying;
        underlying16 = get(configs, 16).underlying;
        underlying17 = get(configs, 17).underlying;
        underlying18 = get(configs, 18).underlying;
        underlying19 = get(configs, 19).underlying;
        underlying20 = get(configs, 20).underlying;
        underlying21 = get(configs, 21).underlying;
        underlying22 = get(configs, 22).underlying;
        underlying23 = get(configs, 23).underlying;
        underlying24 = get(configs, 24).underlying;

        symbolHash00 = get(configs, 0).symbolHash;
        symbolHash01 = get(configs, 1).symbolHash;
        symbolHash02 = get(configs, 2).symbolHash;
        symbolHash03 = get(configs, 3).symbolHash;
        symbolHash04 = get(configs, 4).symbolHash;
        symbolHash05 = get(configs, 5).symbolHash;
        symbolHash06 = get(configs, 6).symbolHash;
        symbolHash07 = get(configs, 7).symbolHash;
        symbolHash08 = get(configs, 8).symbolHash;
        symbolHash09 = get(configs, 9).symbolHash;
        symbolHash10 = get(configs, 10).symbolHash;
        symbolHash11 = get(configs, 11).symbolHash;
        symbolHash12 = get(configs, 12).symbolHash;
        symbolHash13 = get(configs, 13).symbolHash;
        symbolHash14 = get(configs, 14).symbolHash;
        symbolHash15 = get(configs, 15).symbolHash;
        symbolHash16 = get(configs, 16).symbolHash;
        symbolHash17 = get(configs, 17).symbolHash;
        symbolHash18 = get(configs, 18).symbolHash;
        symbolHash19 = get(configs, 19).symbolHash;
        symbolHash20 = get(configs, 20).symbolHash;
        symbolHash21 = get(configs, 21).symbolHash;
        symbolHash22 = get(configs, 22).symbolHash;
        symbolHash23 = get(configs, 23).symbolHash;
        symbolHash24 = get(configs, 24).symbolHash;

        baseUnit00 = get(configs, 0).baseUnit;
        baseUnit01 = get(configs, 1).baseUnit;
        baseUnit02 = get(configs, 2).baseUnit;
        baseUnit03 = get(configs, 3).baseUnit;
        baseUnit04 = get(configs, 4).baseUnit;
        baseUnit05 = get(configs, 5).baseUnit;
        baseUnit06 = get(configs, 6).baseUnit;
        baseUnit07 = get(configs, 7).baseUnit;
        baseUnit08 = get(configs, 8).baseUnit;
        baseUnit09 = get(configs, 9).baseUnit;
        baseUnit10 = get(configs, 10).baseUnit;
        baseUnit11 = get(configs, 11).baseUnit;
        baseUnit12 = get(configs, 12).baseUnit;
        baseUnit13 = get(configs, 13).baseUnit;
        baseUnit14 = get(configs, 14).baseUnit;
        baseUnit15 = get(configs, 15).baseUnit;
        baseUnit16 = get(configs, 16).baseUnit;
        baseUnit17 = get(configs, 17).baseUnit;
        baseUnit18 = get(configs, 18).baseUnit;
        baseUnit19 = get(configs, 19).baseUnit;
        baseUnit20 = get(configs, 20).baseUnit;
        baseUnit21 = get(configs, 21).baseUnit;
        baseUnit22 = get(configs, 22).baseUnit;
        baseUnit23 = get(configs, 23).baseUnit;
        baseUnit24 = get(configs, 24).baseUnit;

        priceSource00 = get(configs, 0).priceSource;
        priceSource01 = get(configs, 1).priceSource;
        priceSource02 = get(configs, 2).priceSource;
        priceSource03 = get(configs, 3).priceSource;
        priceSource04 = get(configs, 4).priceSource;
        priceSource05 = get(configs, 5).priceSource;
        priceSource06 = get(configs, 6).priceSource;
        priceSource07 = get(configs, 7).priceSource;
        priceSource08 = get(configs, 8).priceSource;
        priceSource09 = get(configs, 9).priceSource;
        priceSource10 = get(configs, 10).priceSource;
        priceSource11 = get(configs, 11).priceSource;
        priceSource12 = get(configs, 12).priceSource;
        priceSource13 = get(configs, 13).priceSource;
        priceSource14 = get(configs, 14).priceSource;
        priceSource15 = get(configs, 15).priceSource;
        priceSource16 = get(configs, 16).priceSource;
        priceSource17 = get(configs, 17).priceSource;
        priceSource18 = get(configs, 18).priceSource;
        priceSource19 = get(configs, 19).priceSource;
        priceSource20 = get(configs, 20).priceSource;
        priceSource21 = get(configs, 21).priceSource;
        priceSource22 = get(configs, 22).priceSource;
        priceSource23 = get(configs, 23).priceSource;
        priceSource24 = get(configs, 24).priceSource;

        fixedPrice00 = get(configs, 0).fixedPrice;
        fixedPrice01 = get(configs, 1).fixedPrice;
        fixedPrice02 = get(configs, 2).fixedPrice;
        fixedPrice03 = get(configs, 3).fixedPrice;
        fixedPrice04 = get(configs, 4).fixedPrice;
        fixedPrice05 = get(configs, 5).fixedPrice;
        fixedPrice06 = get(configs, 6).fixedPrice;
        fixedPrice07 = get(configs, 7).fixedPrice;
        fixedPrice08 = get(configs, 8).fixedPrice;
        fixedPrice09 = get(configs, 9).fixedPrice;
        fixedPrice10 = get(configs, 10).fixedPrice;
        fixedPrice11 = get(configs, 11).fixedPrice;
        fixedPrice12 = get(configs, 12).fixedPrice;
        fixedPrice13 = get(configs, 13).fixedPrice;
        fixedPrice14 = get(configs, 14).fixedPrice;
        fixedPrice15 = get(configs, 15).fixedPrice;
        fixedPrice16 = get(configs, 16).fixedPrice;
        fixedPrice17 = get(configs, 17).fixedPrice;
        fixedPrice18 = get(configs, 18).fixedPrice;
        fixedPrice19 = get(configs, 19).fixedPrice;
        fixedPrice20 = get(configs, 20).fixedPrice;
        fixedPrice21 = get(configs, 21).fixedPrice;
        fixedPrice22 = get(configs, 22).fixedPrice;
        fixedPrice23 = get(configs, 23).fixedPrice;
        fixedPrice24 = get(configs, 24).fixedPrice;

        uniswapMarket00 = get(configs, 0).uniswapMarket;
        uniswapMarket01 = get(configs, 1).uniswapMarket;
        uniswapMarket02 = get(configs, 2).uniswapMarket;
        uniswapMarket03 = get(configs, 3).uniswapMarket;
        uniswapMarket04 = get(configs, 4).uniswapMarket;
        uniswapMarket05 = get(configs, 5).uniswapMarket;
        uniswapMarket06 = get(configs, 6).uniswapMarket;
        uniswapMarket07 = get(configs, 7).uniswapMarket;
        uniswapMarket08 = get(configs, 8).uniswapMarket;
        uniswapMarket09 = get(configs, 9).uniswapMarket;
        uniswapMarket10 = get(configs, 10).uniswapMarket;
        uniswapMarket11 = get(configs, 11).uniswapMarket;
        uniswapMarket12 = get(configs, 12).uniswapMarket;
        uniswapMarket13 = get(configs, 13).uniswapMarket;
        uniswapMarket14 = get(configs, 14).uniswapMarket;
        uniswapMarket15 = get(configs, 15).uniswapMarket;
        uniswapMarket16 = get(configs, 16).uniswapMarket;
        uniswapMarket17 = get(configs, 17).uniswapMarket;
        uniswapMarket18 = get(configs, 18).uniswapMarket;
        uniswapMarket19 = get(configs, 19).uniswapMarket;
        uniswapMarket20 = get(configs, 20).uniswapMarket;
        uniswapMarket21 = get(configs, 21).uniswapMarket;
        uniswapMarket22 = get(configs, 22).uniswapMarket;
        uniswapMarket23 = get(configs, 23).uniswapMarket;
        uniswapMarket24 = get(configs, 24).uniswapMarket;

        reporter00 = get(configs, 0).reporter;
        reporter01 = get(configs, 1).reporter;
        reporter02 = get(configs, 2).reporter;
        reporter03 = get(configs, 3).reporter;
        reporter04 = get(configs, 4).reporter;
        reporter05 = get(configs, 5).reporter;
        reporter06 = get(configs, 6).reporter;
        reporter07 = get(configs, 7).reporter;
        reporter08 = get(configs, 8).reporter;
        reporter09 = get(configs, 9).reporter;
        reporter10 = get(configs, 10).reporter;
        reporter11 = get(configs, 11).reporter;
        reporter12 = get(configs, 12).reporter;
        reporter13 = get(configs, 13).reporter;
        reporter14 = get(configs, 14).reporter;
        reporter15 = get(configs, 15).reporter;
        reporter16 = get(configs, 16).reporter;
        reporter17 = get(configs, 17).reporter;
        reporter18 = get(configs, 18).reporter;
        reporter19 = get(configs, 19).reporter;
        reporter20 = get(configs, 20).reporter;
        reporter21 = get(configs, 21).reporter;
        reporter22 = get(configs, 22).reporter;
        reporter23 = get(configs, 23).reporter;
        reporter24 = get(configs, 24).reporter;

        reporterMultiplier00 = get(configs, 0).reporterMultiplier;
        reporterMultiplier01 = get(configs, 1).reporterMultiplier;
        reporterMultiplier02 = get(configs, 2).reporterMultiplier;
        reporterMultiplier03 = get(configs, 3).reporterMultiplier;
        reporterMultiplier04 = get(configs, 4).reporterMultiplier;
        reporterMultiplier05 = get(configs, 5).reporterMultiplier;
        reporterMultiplier06 = get(configs, 6).reporterMultiplier;
        reporterMultiplier07 = get(configs, 7).reporterMultiplier;
        reporterMultiplier08 = get(configs, 8).reporterMultiplier;
        reporterMultiplier09 = get(configs, 9).reporterMultiplier;
        reporterMultiplier10 = get(configs, 10).reporterMultiplier;
        reporterMultiplier11 = get(configs, 11).reporterMultiplier;
        reporterMultiplier12 = get(configs, 12).reporterMultiplier;
        reporterMultiplier13 = get(configs, 13).reporterMultiplier;
        reporterMultiplier14 = get(configs, 14).reporterMultiplier;
        reporterMultiplier15 = get(configs, 15).reporterMultiplier;
        reporterMultiplier16 = get(configs, 16).reporterMultiplier;
        reporterMultiplier17 = get(configs, 17).reporterMultiplier;
        reporterMultiplier18 = get(configs, 18).reporterMultiplier;
        reporterMultiplier19 = get(configs, 19).reporterMultiplier;
        reporterMultiplier20 = get(configs, 20).reporterMultiplier;
        reporterMultiplier21 = get(configs, 21).reporterMultiplier;
        reporterMultiplier22 = get(configs, 22).reporterMultiplier;
        reporterMultiplier23 = get(configs, 23).reporterMultiplier;
        reporterMultiplier24 = get(configs, 24).reporterMultiplier;

        isUniswapReversed00 = get(configs, 0).isUniswapReversed;
        isUniswapReversed01 = get(configs, 1).isUniswapReversed;
        isUniswapReversed02 = get(configs, 2).isUniswapReversed;
        isUniswapReversed03 = get(configs, 3).isUniswapReversed;
        isUniswapReversed04 = get(configs, 4).isUniswapReversed;
        isUniswapReversed05 = get(configs, 5).isUniswapReversed;
        isUniswapReversed06 = get(configs, 6).isUniswapReversed;
        isUniswapReversed07 = get(configs, 7).isUniswapReversed;
        isUniswapReversed08 = get(configs, 8).isUniswapReversed;
        isUniswapReversed09 = get(configs, 9).isUniswapReversed;
        isUniswapReversed10 = get(configs, 10).isUniswapReversed;
        isUniswapReversed11 = get(configs, 11).isUniswapReversed;
        isUniswapReversed12 = get(configs, 12).isUniswapReversed;
        isUniswapReversed13 = get(configs, 13).isUniswapReversed;
        isUniswapReversed14 = get(configs, 14).isUniswapReversed;
        isUniswapReversed15 = get(configs, 15).isUniswapReversed;
        isUniswapReversed16 = get(configs, 16).isUniswapReversed;
        isUniswapReversed17 = get(configs, 17).isUniswapReversed;
        isUniswapReversed18 = get(configs, 18).isUniswapReversed;
        isUniswapReversed19 = get(configs, 19).isUniswapReversed;
        isUniswapReversed20 = get(configs, 20).isUniswapReversed;
        isUniswapReversed21 = get(configs, 21).isUniswapReversed;
        isUniswapReversed22 = get(configs, 22).isUniswapReversed;
        isUniswapReversed23 = get(configs, 23).isUniswapReversed;
        isUniswapReversed24 = get(configs, 24).isUniswapReversed;
    }

    function get(TokenConfig[] memory configs, uint i) internal pure returns (TokenConfig memory) {
        if (i < configs.length)
            return configs[i];
        return TokenConfig({
            cToken: address(0),
            underlying: address(0),
            symbolHash: bytes32(0),
            baseUnit: uint256(0),
            priceSource: PriceSource(0),
            fixedPrice: uint256(0),
            uniswapMarket: address(0),
            reporter: address(0),
            reporterMultiplier: uint256(0),
            isUniswapReversed: false
        });
    }

    function getReporterIndex(address reporter) internal view returns(uint) {
        if (reporter == reporter00) return 0;
        if (reporter == reporter01) return 1;
        if (reporter == reporter02) return 2;
        if (reporter == reporter03) return 3;
        if (reporter == reporter04) return 4;
        if (reporter == reporter05) return 5;
        if (reporter == reporter06) return 6;
        if (reporter == reporter07) return 7;
        if (reporter == reporter08) return 8;
        if (reporter == reporter09) return 9;
        if (reporter == reporter10) return 10;
        if (reporter == reporter11) return 11;
        if (reporter == reporter12) return 12;
        if (reporter == reporter13) return 13;
        if (reporter == reporter14) return 14;
        if (reporter == reporter15) return 15;
        if (reporter == reporter16) return 16;
        if (reporter == reporter17) return 17;
        if (reporter == reporter18) return 18;
        if (reporter == reporter19) return 19;
        if (reporter == reporter20) return 20;
        if (reporter == reporter21) return 21;
        if (reporter == reporter22) return 22;
        if (reporter == reporter23) return 23;
        if (reporter == reporter24) return 24;

        return type(uint).max;
    }

    function getCTokenIndex(address cToken) internal view returns (uint) {
        if (cToken == cToken00) return 0;
        if (cToken == cToken01) return 1;
        if (cToken == cToken02) return 2;
        if (cToken == cToken03) return 3;
        if (cToken == cToken04) return 4;
        if (cToken == cToken05) return 5;
        if (cToken == cToken06) return 6;
        if (cToken == cToken07) return 7;
        if (cToken == cToken08) return 8;
        if (cToken == cToken09) return 9;
        if (cToken == cToken10) return 10;
        if (cToken == cToken11) return 11;
        if (cToken == cToken12) return 12;
        if (cToken == cToken13) return 13;
        if (cToken == cToken14) return 14;
        if (cToken == cToken15) return 15;
        if (cToken == cToken16) return 16;
        if (cToken == cToken17) return 17;
        if (cToken == cToken18) return 18;
        if (cToken == cToken19) return 19;
        if (cToken == cToken20) return 20;
        if (cToken == cToken21) return 21;
        if (cToken == cToken22) return 22;
        if (cToken == cToken23) return 23;
        if (cToken == cToken24) return 24;

        return uint(-1);
    }

    function getUnderlyingIndex(address underlying) internal view returns (uint) {
        if (underlying == underlying00) return 0;
        if (underlying == underlying01) return 1;
        if (underlying == underlying02) return 2;
        if (underlying == underlying03) return 3;
        if (underlying == underlying04) return 4;
        if (underlying == underlying05) return 5;
        if (underlying == underlying06) return 6;
        if (underlying == underlying07) return 7;
        if (underlying == underlying08) return 8;
        if (underlying == underlying09) return 9;
        if (underlying == underlying10) return 10;
        if (underlying == underlying11) return 11;
        if (underlying == underlying12) return 12;
        if (underlying == underlying13) return 13;
        if (underlying == underlying14) return 14;
        if (underlying == underlying15) return 15;
        if (underlying == underlying16) return 16;
        if (underlying == underlying17) return 17;
        if (underlying == underlying18) return 18;
        if (underlying == underlying19) return 19;
        if (underlying == underlying20) return 20;
        if (underlying == underlying21) return 21;
        if (underlying == underlying22) return 22;
        if (underlying == underlying23) return 23;
        if (underlying == underlying24) return 24;

        return uint(-1);
    }

    function getSymbolHashIndex(bytes32 symbolHash) internal view returns (uint) {
        if (symbolHash == symbolHash00) return 0;
        if (symbolHash == symbolHash01) return 1;
        if (symbolHash == symbolHash02) return 2;
        if (symbolHash == symbolHash03) return 3;
        if (symbolHash == symbolHash04) return 4;
        if (symbolHash == symbolHash05) return 5;
        if (symbolHash == symbolHash06) return 6;
        if (symbolHash == symbolHash07) return 7;
        if (symbolHash == symbolHash08) return 8;
        if (symbolHash == symbolHash09) return 9;
        if (symbolHash == symbolHash10) return 10;
        if (symbolHash == symbolHash11) return 11;
        if (symbolHash == symbolHash12) return 12;
        if (symbolHash == symbolHash13) return 13;
        if (symbolHash == symbolHash14) return 14;
        if (symbolHash == symbolHash15) return 15;
        if (symbolHash == symbolHash16) return 16;
        if (symbolHash == symbolHash17) return 17;
        if (symbolHash == symbolHash18) return 18;
        if (symbolHash == symbolHash19) return 19;
        if (symbolHash == symbolHash20) return 20;
        if (symbolHash == symbolHash21) return 21;
        if (symbolHash == symbolHash22) return 22;
        if (symbolHash == symbolHash23) return 23;
        if (symbolHash == symbolHash24) return 24;

        return uint(-1);
    }

    /**
     * @notice Get the i-th config, according to the order they were passed in originally
     * @param i The index of the config to get
     * @return The config object
     */
    function getTokenConfig(uint i) public view returns (TokenConfig memory) {
        require(i < numTokens, "token config not found");

        if (i == 0) return TokenConfig({cToken: cToken00, underlying: underlying00, symbolHash: symbolHash00, baseUnit: baseUnit00, priceSource: priceSource00, fixedPrice: fixedPrice00, uniswapMarket: uniswapMarket00, reporter: reporter00, reporterMultiplier: reporterMultiplier00, isUniswapReversed: isUniswapReversed00});
        if (i == 1) return TokenConfig({cToken: cToken01, underlying: underlying01, symbolHash: symbolHash01, baseUnit: baseUnit01, priceSource: priceSource01, fixedPrice: fixedPrice01, uniswapMarket: uniswapMarket01, reporter: reporter01, reporterMultiplier: reporterMultiplier01, isUniswapReversed: isUniswapReversed01});
        if (i == 2) return TokenConfig({cToken: cToken02, underlying: underlying02, symbolHash: symbolHash02, baseUnit: baseUnit02, priceSource: priceSource02, fixedPrice: fixedPrice02, uniswapMarket: uniswapMarket02, reporter: reporter02, reporterMultiplier: reporterMultiplier02, isUniswapReversed: isUniswapReversed02});
        if (i == 3) return TokenConfig({cToken: cToken03, underlying: underlying03, symbolHash: symbolHash03, baseUnit: baseUnit03, priceSource: priceSource03, fixedPrice: fixedPrice03, uniswapMarket: uniswapMarket03, reporter: reporter03, reporterMultiplier: reporterMultiplier03, isUniswapReversed: isUniswapReversed03});
        if (i == 4) return TokenConfig({cToken: cToken04, underlying: underlying04, symbolHash: symbolHash04, baseUnit: baseUnit04, priceSource: priceSource04, fixedPrice: fixedPrice04, uniswapMarket: uniswapMarket04, reporter: reporter04, reporterMultiplier: reporterMultiplier04, isUniswapReversed: isUniswapReversed04});
        if (i == 5) return TokenConfig({cToken: cToken05, underlying: underlying05, symbolHash: symbolHash05, baseUnit: baseUnit05, priceSource: priceSource05, fixedPrice: fixedPrice05, uniswapMarket: uniswapMarket05, reporter: reporter05, reporterMultiplier: reporterMultiplier05, isUniswapReversed: isUniswapReversed05});
        if (i == 6) return TokenConfig({cToken: cToken06, underlying: underlying06, symbolHash: symbolHash06, baseUnit: baseUnit06, priceSource: priceSource06, fixedPrice: fixedPrice06, uniswapMarket: uniswapMarket06, reporter: reporter06, reporterMultiplier: reporterMultiplier06, isUniswapReversed: isUniswapReversed06});
        if (i == 7) return TokenConfig({cToken: cToken07, underlying: underlying07, symbolHash: symbolHash07, baseUnit: baseUnit07, priceSource: priceSource07, fixedPrice: fixedPrice07, uniswapMarket: uniswapMarket07, reporter: reporter07, reporterMultiplier: reporterMultiplier07, isUniswapReversed: isUniswapReversed07});
        if (i == 8) return TokenConfig({cToken: cToken08, underlying: underlying08, symbolHash: symbolHash08, baseUnit: baseUnit08, priceSource: priceSource08, fixedPrice: fixedPrice08, uniswapMarket: uniswapMarket08, reporter: reporter08, reporterMultiplier: reporterMultiplier08, isUniswapReversed: isUniswapReversed08});
        if (i == 9) return TokenConfig({cToken: cToken09, underlying: underlying09, symbolHash: symbolHash09, baseUnit: baseUnit09, priceSource: priceSource09, fixedPrice: fixedPrice09, uniswapMarket: uniswapMarket09, reporter: reporter09, reporterMultiplier: reporterMultiplier09, isUniswapReversed: isUniswapReversed09});

        if (i == 10) return TokenConfig({cToken: cToken10, underlying: underlying10, symbolHash: symbolHash10, baseUnit: baseUnit10, priceSource: priceSource10, fixedPrice: fixedPrice10, uniswapMarket: uniswapMarket10, reporter: reporter10, reporterMultiplier: reporterMultiplier10, isUniswapReversed: isUniswapReversed10});
        if (i == 11) return TokenConfig({cToken: cToken11, underlying: underlying11, symbolHash: symbolHash11, baseUnit: baseUnit11, priceSource: priceSource11, fixedPrice: fixedPrice11, uniswapMarket: uniswapMarket11, reporter: reporter11, reporterMultiplier: reporterMultiplier11, isUniswapReversed: isUniswapReversed11});
        if (i == 12) return TokenConfig({cToken: cToken12, underlying: underlying12, symbolHash: symbolHash12, baseUnit: baseUnit12, priceSource: priceSource12, fixedPrice: fixedPrice12, uniswapMarket: uniswapMarket12, reporter: reporter12, reporterMultiplier: reporterMultiplier12, isUniswapReversed: isUniswapReversed12});
        if (i == 13) return TokenConfig({cToken: cToken13, underlying: underlying13, symbolHash: symbolHash13, baseUnit: baseUnit13, priceSource: priceSource13, fixedPrice: fixedPrice13, uniswapMarket: uniswapMarket13, reporter: reporter13, reporterMultiplier: reporterMultiplier13, isUniswapReversed: isUniswapReversed13});
        if (i == 14) return TokenConfig({cToken: cToken14, underlying: underlying14, symbolHash: symbolHash14, baseUnit: baseUnit14, priceSource: priceSource14, fixedPrice: fixedPrice14, uniswapMarket: uniswapMarket14, reporter: reporter14, reporterMultiplier: reporterMultiplier14, isUniswapReversed: isUniswapReversed14});
        if (i == 15) return TokenConfig({cToken: cToken15, underlying: underlying15, symbolHash: symbolHash15, baseUnit: baseUnit15, priceSource: priceSource15, fixedPrice: fixedPrice15, uniswapMarket: uniswapMarket15, reporter: reporter15, reporterMultiplier: reporterMultiplier15, isUniswapReversed: isUniswapReversed15});
        if (i == 16) return TokenConfig({cToken: cToken16, underlying: underlying16, symbolHash: symbolHash16, baseUnit: baseUnit16, priceSource: priceSource16, fixedPrice: fixedPrice16, uniswapMarket: uniswapMarket16, reporter: reporter16, reporterMultiplier: reporterMultiplier16, isUniswapReversed: isUniswapReversed16});
        if (i == 17) return TokenConfig({cToken: cToken17, underlying: underlying17, symbolHash: symbolHash17, baseUnit: baseUnit17, priceSource: priceSource17, fixedPrice: fixedPrice17, uniswapMarket: uniswapMarket17, reporter: reporter17, reporterMultiplier: reporterMultiplier17, isUniswapReversed: isUniswapReversed17});
        if (i == 18) return TokenConfig({cToken: cToken18, underlying: underlying18, symbolHash: symbolHash18, baseUnit: baseUnit18, priceSource: priceSource18, fixedPrice: fixedPrice18, uniswapMarket: uniswapMarket18, reporter: reporter18, reporterMultiplier: reporterMultiplier18, isUniswapReversed: isUniswapReversed18});
        if (i == 19) return TokenConfig({cToken: cToken19, underlying: underlying19, symbolHash: symbolHash19, baseUnit: baseUnit19, priceSource: priceSource19, fixedPrice: fixedPrice19, uniswapMarket: uniswapMarket19, reporter: reporter19, reporterMultiplier: reporterMultiplier19, isUniswapReversed: isUniswapReversed19});

        if (i == 20) return TokenConfig({cToken: cToken20, underlying: underlying20, symbolHash: symbolHash20, baseUnit: baseUnit20, priceSource: priceSource20, fixedPrice: fixedPrice20, uniswapMarket: uniswapMarket20, reporter: reporter20, reporterMultiplier: reporterMultiplier20, isUniswapReversed: isUniswapReversed20});
        if (i == 21) return TokenConfig({cToken: cToken21, underlying: underlying21, symbolHash: symbolHash21, baseUnit: baseUnit21, priceSource: priceSource21, fixedPrice: fixedPrice21, uniswapMarket: uniswapMarket21, reporter: reporter21, reporterMultiplier: reporterMultiplier21, isUniswapReversed: isUniswapReversed21});
        if (i == 22) return TokenConfig({cToken: cToken22, underlying: underlying22, symbolHash: symbolHash22, baseUnit: baseUnit22, priceSource: priceSource22, fixedPrice: fixedPrice22, uniswapMarket: uniswapMarket22, reporter: reporter22, reporterMultiplier: reporterMultiplier22, isUniswapReversed: isUniswapReversed22});
        if (i == 23) return TokenConfig({cToken: cToken23, underlying: underlying23, symbolHash: symbolHash23, baseUnit: baseUnit23, priceSource: priceSource23, fixedPrice: fixedPrice23, uniswapMarket: uniswapMarket23, reporter: reporter23, reporterMultiplier: reporterMultiplier23, isUniswapReversed: isUniswapReversed23});
        if (i == 24) return TokenConfig({cToken: cToken24, underlying: underlying24, symbolHash: symbolHash24, baseUnit: baseUnit24, priceSource: priceSource24, fixedPrice: fixedPrice24, uniswapMarket: uniswapMarket24, reporter: reporter24, reporterMultiplier: reporterMultiplier24, isUniswapReversed: isUniswapReversed24});
    }

    /**
     * @notice Get the config for symbol
     * @param symbol The symbol of the config to get
     * @return The config object
     */
    function getTokenConfigBySymbol(string memory symbol) public view returns (TokenConfig memory) {
        return getTokenConfigBySymbolHash(keccak256(abi.encodePacked(symbol)));
    }

    /**
     * @notice Get the config for the reporter
     * @param reporter The address of the reporter of the config to get
     * @return The config object
     */
    function getTokenConfigByReporter(address reporter) public view returns (TokenConfig memory) {
        uint index = getReporterIndex(reporter);
        if (index != uint(-1)) {
            return getTokenConfig(index);
        }

        revert("token config not found");
    }

    /**
     * @notice Get the config for the symbolHash
     * @param symbolHash The keccack256 of the symbol of the config to get
     * @return The config object
     */
    function getTokenConfigBySymbolHash(bytes32 symbolHash) public view returns (TokenConfig memory) {
        uint index = getSymbolHashIndex(symbolHash);
        if (index != uint(-1)) {
            return getTokenConfig(index);
        }

        revert("token config not found");
    }

    /**
     * @notice Get the config for the cToken
     * @dev If a config for the cToken is not found, falls back to searching for the underlying.
     * @param cToken The address of the cToken of the config to get
     * @return The config object
     */
    function getTokenConfigByCToken(address cToken) public view returns (TokenConfig memory) {
        uint index = getCTokenIndex(cToken);
        if (index != uint(-1)) {
            return getTokenConfig(index);
        }

        return getTokenConfigByUnderlying(CErc20(cToken).underlying());
    }

    /**
     * @notice Get the config for an underlying asset
     * @param underlying The address of the underlying asset of the config to get
     * @return The config object
     */
    function getTokenConfigByUnderlying(address underlying) public view returns (TokenConfig memory) {
        uint index = getUnderlyingIndex(underlying);
        if (index != uint(-1)) {
            return getTokenConfig(index);
        }

        revert("token config not found");
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.12;

// Based on code from https://github.com/Uniswap/uniswap-v2-periphery

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // returns a uq112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << 112) / denominator);
    }

    // decode a uq112x112 into a uint with 18 decimals of precision
    function decode112with18(uq112x112 memory self) internal pure returns (uint) {
        // we only have 256 - 224 = 32 bits to spare, so scaling up by ~60 bits is dangerous
        // instead, get close to:
        //  (x * 1e18) >> 112
        // without risk of overflowing, e.g.:
        //  (x) / 2 ** (112 - lg(1e18))
        return uint(self._x) / 5192296858534827;
    }
}

// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(
        address pair
    ) internal view returns (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            // counterfactual
            price1Cumulative += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
    }
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;

/**
 * @notice A contract with helpers for safe contract ownership.
 */
contract Ownable {

    address private ownerAddr;
    address private pendingOwnerAddr;

    event OwnershipTransferRequested(address indexed from, address indexed to);
    event OwnershipTransferred(address indexed from, address indexed to);

    constructor() public {
        ownerAddr = msg.sender;
    }

    /**
    * @notice Allows an owner to begin transferring ownership to a new address,
    * pending.
    */
    function transferOwnership(address to) external onlyOwner() {
        require(to != msg.sender, "Cannot transfer to self");

        pendingOwnerAddr = to;

        emit OwnershipTransferRequested(ownerAddr, to);
    }

    /**
    * @notice Allows an ownership transfer to be completed by the recipient.
    */
    function acceptOwnership() external {
        require(msg.sender == pendingOwnerAddr, "Must be proposed owner");

        address oldOwner = ownerAddr;
        ownerAddr = msg.sender;
        pendingOwnerAddr = address(0);

        emit OwnershipTransferred(oldOwner, msg.sender);
    }

    /**
    * @notice Get the current owner
    */
    function owner() public view returns (address) {
        return ownerAddr;
    }

    /**
    * @notice Reverts if called by anyone other than the contract owner.
    */
    modifier onlyOwner() {
        require(msg.sender == ownerAddr, "Only callable by owner");
        _;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface AggregatorValidatorInterface {
	function validate(uint256 previousRoundId,
			int256 previousAnswer,
			uint256 currentRoundId,
			int256 currentAnswer) external returns (bool);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}