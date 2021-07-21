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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
pragma solidity 0.8.4;

interface IIBToken {
    function underlying() external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

contract TokenConfigWrapper {
    enum PriceSource {
        chainlink,
        pairOracle
    }

    struct TokenConfig {
        address ibToken;
        address underlying;
        bytes32 symbolHash;
        uint256 baseUnit;
        PriceSource priceSource;
    }

    mapping(address => TokenConfig) public getTokenConfigByIBToken;
    mapping(bytes32 => address) public getIBTokenBySymbolHash;
    mapping(address => address) public getIBTokenByUnderlying;

    function setTokenConfigInternal(
        address _ibToken,
        address _underlying,
        string memory _symbol,
        uint256 _decimals,
        PriceSource _priceSource
    ) internal {
        require(getIBTokenByUnderlying[_underlying] == address(0), "IBToken & underlying existed");

        bytes32 symbolHash = keccak256(abi.encodePacked(_symbol));
        TokenConfig storage _newToken = getTokenConfigByIBToken[_ibToken];
        _newToken.ibToken = _ibToken;
        _newToken.underlying = _underlying;
        _newToken.baseUnit = 10**_decimals;
        _newToken.symbolHash = symbolHash;
        _newToken.priceSource = _priceSource;

        getIBTokenByUnderlying[_newToken.underlying] = _ibToken;
        getIBTokenBySymbolHash[_newToken.symbolHash] = _ibToken;
    }

    function getTokenConfigBySymbolHash(bytes32 _symbolHash) internal view returns (TokenConfig memory) {
        address ibToken = getIBTokenBySymbolHash[_symbolHash];
        require(ibToken != address(0), "token config not found");
        return getTokenConfigByIBToken[ibToken];
    }

    function getTokenConfigBySymbol(string memory symbol) external view returns (TokenConfig memory) {
        bytes32 symbolHash = keccak256(abi.encodePacked(symbol));
        return getTokenConfigBySymbolHash(symbolHash);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./TokenConfigWrapper.sol";
import "./IIBToken.sol";
import "./ChainlinkLib.sol";
import "./UniswapOracle.sol";

contract UniPriceFeed is Ownable, TokenConfigWrapper, UniswapOracle {
    address public uniswapOracle;
    mapping (address => address) public getChainlinkFeedByUnderlying;

    function getUnderlyingPrice(IIBToken _ibToken) external view returns (uint256) {
        TokenConfig storage config = getTokenConfigByIBToken[address(_ibToken)];
         // Comptroller needs prices in the format: ${raw price} * 1e(36 - baseUnit)
         // Since the prices in this view have 6 decimals, we must scale them by 1e(36 - 6 - baseUnit)
        return 1e18 * getPrice(config) / config.baseUnit;
    }

    function getPrice(TokenConfig memory config) internal view returns(uint256) {
        if (config.priceSource == PriceSource.chainlink) {
            return ChainlinkLib.consult(getChainlinkFeedByUnderlying[config.underlying], PRECISION);
        }

        if (config.priceSource == PriceSource.pairOracle) {
            return getTwapPrice(config.underlying, PRECISION);
        }

        return 0; // price is not available
    }

    // Operating function
    function setTokenConfig(
        address _ibToken,
        address _underlying,
        string memory _symbol,
        uint256 _decimals,
        PriceSource _priceSource,
        address _chainlinkFeed,
        BaseToken[] calldata _baseTokens,
        address[] calldata _lpPairs
    ) external onlyOwner {
        setTokenConfigInternal(_ibToken, _underlying, _symbol, _decimals, _priceSource);

        if (_priceSource == PriceSource.chainlink) {
            require(_chainlinkFeed != address(0), "!chainlink");
            getChainlinkFeedByUnderlying[_underlying] = _chainlinkFeed;
        }

        if (_priceSource == PriceSource.pairOracle) {
            addTokenLPPairInternal(_underlying, _baseTokens, _lpPairs);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../libs/UniswapLib.sol";
import "./ChainlinkLib.sol";

contract UniswapOracle {
    using FixedPoint for FixedPoint.uq144x112;
    using FixedPoint for FixedPoint.uq112x112;

    enum BaseToken {MATIC, ETH, USDC}

    struct PriceRoute {
        bytes32 id;
        BaseToken base;
        address uniswapPair;
    }

    uint256 public constant PRECISION = 1e18;
    uint256 public PERIOD = 600; // 10 minutes
    uint256 public blockTimestampLast;

    address[] public whitelistedTokens;

    /// @dev official TWAP usd per token price
    mapping(address => uint256) public prices;

    /// @dev price of token used as base. Get from chainlink. MUST be update before all update to price
    mapping(BaseToken => uint256) public basePrice;

    mapping(BaseToken => address) public getBaseTokenChainlinkFeed;

    /// @dev array of available route
    mapping(address => PriceRoute[]) public getPriceRoute;

    /// @dev last cumulative price for a route
    mapping(bytes32 => uint256) public lastCumulativePrice;

    constructor() {
        getBaseTokenChainlinkFeed[BaseToken.ETH] = 0xF9680D99D6C9589e2a93a78A04A279e509205945;
        getBaseTokenChainlinkFeed[BaseToken.MATIC] = 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0;
        getBaseTokenChainlinkFeed[BaseToken.USDC] = 0xfE4A8cc5b5B2366C1B58Bea3858e81843581b2F7;
    }

    function getTwapPrice(address _token, uint256 _amountIn) internal view returns (uint256) {
        return (_amountIn * prices[_token]) / PRECISION;
    }

    function update() external {
        uint256 timeElapsed = block.timestamp - blockTimestampLast;
        require(timeElapsed >= PERIOD, "!period");
        fetchBasePrice();
        for (uint256 i = 0; i < whitelistedTokens.length; i++) {
            updateOne(whitelistedTokens[i], timeElapsed);
        }

        blockTimestampLast = block.timestamp;
    }

    function fetchBasePrice() internal {
        basePrice[BaseToken.ETH] = ChainlinkLib.consult(getBaseTokenChainlinkFeed[BaseToken.ETH], PRECISION);
        basePrice[BaseToken.MATIC] = ChainlinkLib.consult(getBaseTokenChainlinkFeed[BaseToken.MATIC], PRECISION);
        basePrice[BaseToken.USDC] = ChainlinkLib.consult(getBaseTokenChainlinkFeed[BaseToken.USDC], PRECISION);
    }

    function updateOne(address _token, uint256 timeElapsed) internal {
        uint256 sum = 0;
        for (uint256 i = 0; i < getPriceRoute[_token].length; i++) {
            PriceRoute memory route = getPriceRoute[_token][i];
            sum += getTwapPriceInternal(_token, route, timeElapsed);
        }

        prices[_token] = sum / getPriceRoute[_token].length;
    }

    function getTwapPriceInternal(
        address _token,
        PriceRoute memory _route,
        uint256 _timeElapsed
    ) internal returns (uint256) {
        uint256 currentPrice = currentCumulativePrice(_token, _route.uniswapPair);
        uint256 basePrice_ = basePrice[_route.base];
        uint256 twap =
            FixedPoint
                .uq112x112(uint224((currentPrice - lastCumulativePrice[_route.id]) / _timeElapsed))
                .mul(basePrice_)
                .decode144();
        lastCumulativePrice[_route.id] = currentPrice;
        return twap;
    }

    function currentCumulativePrice(address _token, address _pair) internal view returns (uint256) {
        (uint256 cumulativePrice0, uint256 cumulativePrice1, ) = UniswapV2OracleLibrary.currentCumulativePrices(_pair);
        if (_token == IUniswapV2Pair(_pair).token0()) {
            return cumulativePrice0;
        }

        return cumulativePrice1;
    }

    function addTokenLPPairInternal(
        address _token,
        BaseToken[] calldata _bases,
        address[] calldata _pairs
    ) internal {
        require(getPriceRoute[_token].length == 0, "token already added");
        require(_bases.length == _pairs.length && _bases.length > 0, "invalid config");
        for (uint256 i = 0; i < _bases.length; i++) {
            PriceRoute memory route = PriceRoute (
                keccak256(abi.encodePacked(_bases[i], _pairs[i])),
                _bases[i],
                _pairs[i]
            );

            getPriceRoute[_token].push(route);
        }

        whitelistedTokens.push(_token);
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
    function token0() external view returns (address);
    function token1() external view returns (address);
}