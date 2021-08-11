// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IGuardedPriceOracle {
    /// @notice The event emitted when new prices are posted but the stored price is not updated due to the anchor
    event PriceGuarded(string symbol, uint256 reporter, uint256 anchor);

    /// @notice The event emitted when the stored price is updated
    event PriceUpdated(string symbol, uint256 price);

    /// @notice The event emitted when anchor price is updated
    event AnchorPriceUpdated(
        string symbol,
        address uniswapMarket,
        uint256 anchorPrice,
        uint256 oldTimestamp,
        uint256 newTimestamp
    );

    /// @notice The event emitted when the uniswap window changes
    event UniswapWindowUpdated(
        bytes32 indexed symbolHash,
        uint256 oldTimestamp,
        uint256 newTimestamp,
        uint256 oldPrice,
        uint256 newPrice
    );

    /// @notice The event emitted when reporter invalidates itself
    event ReporterInvalidated(address reporter);

    /**
     * @notice Post open oracle reporter prices, and recalculate stored price by comparing to anchor
     * @dev only prices from configured reporter will be stored in the view.
     * @param messages The messages to post to the oracle
     * @param symbols The symbols to compare to anchor for authoritative reading
     */
    function postPrices(
        bytes[] calldata messages,
        string[] calldata symbols
    ) external;


    /**
      * @notice Get the underlying price of a rToken asset
      * @param rToken The rToken to get the underlying price of
      * @return The underlying asset price mantissa (scaled by 36 - underlying decimals).
      *  Zero means the price is unavailable.
      */
    function getUnderlyingPrice(address rToken) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IRToken {
    function underlying() external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./libs/ChainlinkLib.sol";
import "./libs/FixedPoint.sol";
import "./libs/UniswapV2Library.sol";
import "./TokenConfigWrapper.sol";
import "./ReporterData.sol";
import "./IGuardedPriceOracle.sol";
import "./IRToken.sol";


/**
 * Price feed with anchor based in uniswap pair TWAP
 * Inspired by Compound Open Price Feed
 */
contract IronPriceOracle is Ownable, TokenConfigWrapper, ReporterData, IGuardedPriceOracle {
    using FixedPoint for *;

    struct Observation {
        uint256 timestamp;
        uint256 acc;
    }

    /// @notice Indicator that this is a PriceOracle contract (for inspection)
    bool public constant isPriceOracle = true;

    /// @notice The Open Oracle Reporter
    mapping(address => bool) public reporters;

    /// @notice Official prices by symbol hash
    mapping(bytes32 => uint256) public prices;

    uint256 public constant PRECISION = 1e18;

    /// @notice base token price in 18 decimals scale
    mapping(BaseToken => uint256) baseTokenPrice;

    /// @notice base token scale = 10 ^ decimals
    mapping(BaseToken => uint256) baseTokenBaseUnit;

    /// @notice base token price in 18 decimals scale
    mapping(BaseToken => address) baseTokenChainlinkFeed;

    /// @notice The old observation for each routeHash
    mapping(bytes32 => Observation) public oldObservations;

    /// @notice The new observation for each routeHash
    mapping(bytes32 => Observation) public newObservations;

    /// @notice The highest ratio of the new price to the anchor price that will still trigger the price to be updated
    uint256 public immutable upperBoundAnchorRatio;

    /// @notice The lowest ratio of the new price to the anchor price that will still trigger the price to be updated
    uint256 public immutable lowerBoundAnchorRatio;

    /// @notice The minimum amount of time in seconds required for the old uniswap price accumulator to be replaced
    uint256 public immutable anchorPeriod;

    // ============== MODIFIER ==============
    modifier onlyReporter() {
        require(reporters[msg.sender], "!reporter");
        _;
    }

    constructor(
        address reporter_,
        uint256 anchorToleranceMantissa_,
        uint256 anchorPeriod_
    ) {
        anchorPeriod = anchorPeriod_;

        upperBoundAnchorRatio = anchorToleranceMantissa_ > type(uint256).max - 100e16
            ? type(uint256).max
            : 100e16 + anchorToleranceMantissa_;
        lowerBoundAnchorRatio = anchorToleranceMantissa_ < 100e16 ? 100e16 - anchorToleranceMantissa_ : 1;

        baseTokenChainlinkFeed[BaseToken.ETH] = 0xF9680D99D6C9589e2a93a78A04A279e509205945;
        baseTokenChainlinkFeed[BaseToken.USDC] = 0xfE4A8cc5b5B2366C1B58Bea3858e81843581b2F7;
        baseTokenChainlinkFeed[BaseToken.MATIC] = 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0;
        baseTokenBaseUnit[BaseToken.ETH] = 1e18;
        baseTokenBaseUnit[BaseToken.USDC] = 1e6;
        baseTokenBaseUnit[BaseToken.MATIC] = 1e18;
        reporters[reporter_] = true;
    }

    function postPrices(bytes[] calldata messages, string[] calldata symbols) external override onlyReporter {
        require(messages.length != 0, "emptyMessages");

        // Save the prices
        for (uint256 i = 0; i < messages.length; i++) {
            putPriceData(msg.sender, messages[i]);
        }

        fetchBasePrice();

        // Try to update the view storage
        for (uint256 i = 0; i < symbols.length; i++) {
            postPriceInternal(symbols[i]);
        }
    }

    function postPriceInternal(string memory symbol) internal {
        bytes32 symbolHash = keccak256(abi.encodePacked(symbol));
        TokenConfig memory config = getTokenConfigBySymbolHash[symbolHash];
        require(config.priceSource == PriceSource.REPORTER, "only reporter prices get posted");

        uint256 reporterPrice = getPriceData(msg.sender, symbol);
        uint256 anchorPrice = fetchAnchorPrice(symbol, config);

        if (isWithinAnchor(reporterPrice, anchorPrice)) {
            prices[symbolHash] = reporterPrice;
            emit PriceUpdated(symbol, reporterPrice);
        } else {
            emit PriceGuarded(symbol, reporterPrice, anchorPrice);
        }
    }

    // ================= VIEW FUNCTIONS ==================

    function getUnderlyingPrice(address rToken) external view override returns (uint256) {
        TokenConfig memory config = getTokenConfigByRToken[rToken];
        return (1e18 * price(config)) / config.baseUnit;
    }

    function price(string memory symbol) external view returns (uint256) {
        TokenConfig memory config = getTokenConfigBySymbol(symbol);
        return price(config);
    }

    // ===================== INTERNAL FUNCTIONS =====================

    function price(TokenConfig memory config) internal view returns (uint256) {
        if (config.priceSource == PriceSource.FIXED_CHAINLINK) {
            return ChainlinkLib.consult(getChainlinkFeedBySymbolHash[config.symbolHash], PRECISION);
        }
        return prices[config.symbolHash];
    }

    function isWithinAnchor(uint256 reporterPrice, uint256 anchorPrice) internal view returns (bool) {
        if (reporterPrice > 0) {
            uint256 anchorRatio = (anchorPrice * PRECISION) / reporterPrice;
            return anchorRatio <= upperBoundAnchorRatio && anchorRatio >= lowerBoundAnchorRatio;
        }
        return false;
    }

    function fetchBasePrice() internal {
        fetchBasePrice(BaseToken.ETH);
        fetchBasePrice(BaseToken.USDC);
    }

    function fetchBasePrice(BaseToken baseToken) internal {
        baseTokenPrice[baseToken] = ChainlinkLib.consult(baseTokenChainlinkFeed[baseToken], PRECISION);
    }

    function fetchAnchorPrice(string memory symbol, TokenConfig memory config) internal returns (uint256 anchorPrice) {
        PriceRoute[] memory routes = getPriceRouteBySymbolHash[config.symbolHash];
        uint256 nRoute = routes.length;

        require(nRoute != 0, "invalidRouteConfig");

        if (nRoute == 1) {
            anchorPrice = fetchTWAPPrice(symbol, config.baseUnit, routes[0]);
        } else {
            uint256 sum = 0;

            for (uint256 i = 0; i < nRoute; i++) {
                sum += fetchTWAPPrice(symbol, config.baseUnit, routes[i]);
            }

            anchorPrice = sum / nRoute;
        }
    }

    function fetchTWAPPrice(
        string memory symbol,
        uint256 baseUnit,
        PriceRoute memory route
    ) internal virtual returns (uint256) {
        (uint256 nowCumulativePrice, uint256 oldCumulativePrice, uint256 oldTimestamp) = pokeWindowValues(route);

        // This should be impossible, but better safe than sorry
        require(block.timestamp > oldTimestamp, "now must come after before");
        uint256 timeElapsed = block.timestamp - oldTimestamp;

        FixedPoint.uq112x112 memory priceAverage = FixedPoint.uq112x112(
            uint224((nowCumulativePrice - oldCumulativePrice) / timeElapsed)
        );
        uint256 rawUniswapPriceMantissa = priceAverage.decode112with18();
        uint256 unscaledPriceMantissa = rawUniswapPriceMantissa * baseTokenPrice[route.baseToken];
        uint256 twapPrice = (unscaledPriceMantissa * baseUnit) / baseTokenBaseUnit[route.baseToken] / PRECISION;
        emit AnchorPriceUpdated(symbol, route.uniswapPair, twapPrice, oldTimestamp, block.timestamp);
        return twapPrice;
    }

    /**
     * @dev Get time-weighted average prices for a token at the current timestamp.
     *  Update new and old observations of lagging window if period elapsed.
     */
    function pokeWindowValues(PriceRoute memory route)
        internal
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        bytes32 routeHash = route.routeHash;
        uint256 cumulativePrice = currentCumulativePrice(route.uniswapPair, route.isUniswapReversed);
        Observation memory newObservation = newObservations[routeHash];

        // Update new and old observations if elapsed time is greater than or equal to anchor period
        uint256 timeElapsed = block.timestamp - newObservation.timestamp;
        if (timeElapsed >= anchorPeriod) {
            oldObservations[routeHash].timestamp = newObservation.timestamp;
            oldObservations[routeHash].acc = newObservation.acc;

            newObservations[routeHash].timestamp = block.timestamp;
            newObservations[routeHash].acc = cumulativePrice;
            emit UniswapWindowUpdated(
                routeHash,
                newObservation.timestamp,
                block.timestamp,
                newObservation.acc,
                cumulativePrice
            );
        }
        return (cumulativePrice, oldObservations[routeHash].acc, oldObservations[routeHash].timestamp);
    }

    function currentCumulativePrice(address uniswapMarket, bool isUniswapReversed) internal view returns (uint256) {
        (uint256 cumulativePrice0, uint256 cumulativePrice1, ) = UniswapV2Library.currentCumulativePrices(
            uniswapMarket
        );
        if (isUniswapReversed) {
            return cumulativePrice1;
        } else {
            return cumulativePrice0;
        }
    }

    // ============= OPERATING FUNCTION =================
    function _setTokenConfig(
        address rToken,
        string memory symbol,
        uint256 decimal,
        PriceSource priceSource,
        address chainlinkFeed,
        BaseToken[] calldata baseToken,
        address[] calldata uniswapPair,
        bool[] calldata isUniswapReversed
    ) public onlyOwner {
        require(decimal > 0, "zeroDecimal");
        require(baseToken.length == uniswapPair.length, "uniswapPairMissMatch");
        require(baseToken.length == isUniswapReversed.length, "isPairReversedMissMatch");

        bytes32 symbolHash = keccak256(abi.encodePacked(symbol));
        TokenConfigWrapper._setTokenConfig(rToken, symbolHash, decimal, priceSource);

        if (priceSource == PriceSource.FIXED_CHAINLINK) {
            require(chainlinkFeed != address(0), "missingChainlinkAddress");
            require(baseToken.length == 0, "priceRouteNotNeccessary");
            getChainlinkFeedBySymbolHash[symbolHash] = chainlinkFeed;
            return;
        }

        require(baseToken.length > 0, "emptyPriceRoute");

        for (uint256 i = 0; i < baseToken.length; i++) {
            bytes32 routeHash = keccak256(abi.encodePacked(symbol, uniswapPair[i]));
            _setAnchorPriceRoute(symbolHash, routeHash, baseToken[i], uniswapPair[i], isUniswapReversed[i]);

            uint256 cumulativePrice = currentCumulativePrice(uniswapPair[i], isUniswapReversed[i]);
            oldObservations[routeHash].timestamp = block.timestamp;
            newObservations[routeHash].timestamp = block.timestamp;
            oldObservations[routeHash].acc = cumulativePrice;
            newObservations[routeHash].acc = cumulativePrice;
        }
    }

    function _addReporter(address reporter) external onlyOwner {
        require(reporter != address(0), "zeroAddress");
        require(!reporters[reporter], "alreadyAdded");
        reporters[reporter] = true;
    }

    function _removeReporter(address reporter) external onlyOwner {
        require(reporter != address(0), "zeroAddress");
        require(reporters[reporter], "notWhitelisted");
        reporters[reporter] = false;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

contract ReporterData {
    struct Datum {
        uint64 timestamp;
        uint224 value;
    }

    ///@notice The event emitted when a source writes to its storage
    event Write(address indexed source, string key, uint64 timestamp, uint224 value);

    ///@notice The event emitted when the timestamp on a price is invalid and it is not written to storage
    event NotWritten(uint64 priorTimestamp, uint256 messageTimestamp, uint256 blockTimestamp);

    mapping(address => mapping(string => Datum)) private data;

    function putPriceData(address source_, bytes calldata message) internal returns (string memory) {
        (uint64 timestamp, string memory key, uint224 value) = abi.decode(message, (uint64, string, uint224));
        Datum storage prior = data[source_][key];
        if (timestamp > prior.timestamp && timestamp < block.timestamp + 60 minutes && source_ != address(0)) {
            data[source_][key] = Datum(timestamp, value);
            emit Write(source_, key, timestamp, value);
        } else {
            emit NotWritten(prior.timestamp, timestamp, block.timestamp);
        }
        return key;
    }

    function getPriceData(address source_, string memory key) internal view returns (uint256) {
        return data[source_][key].value;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

contract TokenConfigWrapper {
    enum BaseToken {
        ETH,
        USDC,
        MATIC
    }

    enum PriceSource {
        FIXED_CHAINLINK,
        REPORTER
    }

    struct PriceRoute {
        bytes32 routeHash;
        address uniswapPair;
        BaseToken baseToken;
        bool isUniswapReversed;
    }

    struct TokenConfig {
        address rToken;
        bytes32 symbolHash;
        PriceSource priceSource;
        uint256 baseUnit; // unit scale by token decimals
    }

    mapping(bytes32 => TokenConfig) getTokenConfigBySymbolHash;

    mapping(address => TokenConfig) getTokenConfigByRToken;

    /// @dev route to fetch anchor price
    mapping(bytes32 => PriceRoute[]) getPriceRouteBySymbolHash;

    mapping(bytes32 => address) getChainlinkFeedBySymbolHash;

    function _setTokenConfig(
        address rToken,
        bytes32 symbolHash,
        uint256 decimal,
        PriceSource priceSource
    ) internal {
        require(decimal > 0, "zeroDecimal");

        TokenConfig memory config = TokenConfig({
            symbolHash: symbolHash,
            rToken: rToken,
            priceSource: priceSource,
            baseUnit: 10**decimal
        });

        getTokenConfigBySymbolHash[symbolHash] = config;
        getTokenConfigByRToken[rToken] = config;
    }

    function _setAnchorPriceRoute(
        bytes32 symbolHash,
        bytes32 routeHash,
        BaseToken baseToken,
        address uniswapPair,
        bool isUniswapReversed
    ) internal {
        require(uniswapPair != address(0), "zeroUniswapPair");

        getPriceRouteBySymbolHash[symbolHash].push(
            PriceRoute({
                routeHash: routeHash,
                uniswapPair: uniswapPair,
                baseToken: baseToken,
                isUniswapReversed: isUniswapReversed
            })
        );
    }

    function getTokenConfigBySymbol(string memory symbol) public view returns (TokenConfig memory) {
        return getTokenConfigBySymbolHash[keccak256(abi.encodePacked(symbol))];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library ChainlinkLib {

    function consult(address _priceFeedAddress, uint _amountIn) internal view returns (uint256) {
        assert(_priceFeedAddress != address(0));
        AggregatorV3Interface _priceFeed = AggregatorV3Interface(_priceFeedAddress);
        (, int256 _price, , , ) = _priceFeed.latestRoundData();
        uint8 _decimals = _priceFeed.decimals();
        return (uint256(_price) * _amountIn) / (10**_decimals);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

import "./Babylonian.sol";

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint256 _x;
    }

    uint8 private constant RESOLUTION = 112;
    uint256 private constant Q112 = uint256(1) << RESOLUTION;
    uint256 private constant Q224 = Q112 << RESOLUTION;

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function div(uq112x112 memory self, uint112 x) internal pure returns (uq112x112 memory) {
        require(x != 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112(self._x / uint224(x));
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint256 y) internal pure returns (uq144x112 memory) {
        uint256 z;
        require(y == 0 || (z = uint256(self._x) * y) / y == uint256(self._x), "FixedPoint: MULTIPLICATION_OVERFLOW");
        return uq144x112(z);
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }

    // take the reciprocal of a UQ112x112
    function reciprocal(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        require(self._x != 0, "FixedPoint: ZERO_RECIPROCAL");
        return uq112x112(uint224(Q224 / self._x));
    }

    // square root of a UQ112x112
    function sqrt(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(Babylonian.sqrt(uint256(self._x)) << 56));
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "./FixedPoint.sol";

// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2Library {
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
    function token0() external view returns (address);
    function token1() external view returns (address);
}