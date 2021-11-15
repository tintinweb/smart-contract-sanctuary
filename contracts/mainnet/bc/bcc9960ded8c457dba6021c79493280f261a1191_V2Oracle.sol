// SPDX-License-Identifier: MIT
pragma solidity >=0.7.5;
pragma abicoder v2;

import "./interfaces/IOracle.sol";
import "./libraries/SafeMath.sol";
import "./libraries/LibraryV2Oracle.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20 {
  function decimals() external view returns (uint8);
}

contract V2Oracle is IOracle, Ownable {
  using FixedPoint for *;
  using SafeMath for uint256;

  address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address public constant AQUA = 0xD34a24006b862f4E9936c506691539D6433aD297;
  address public constant UNISWAP_V2_FACTORY =
    0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

  uint256 public WINDOW;

  mapping(address => uint256) public cummulativeAveragePrice;
  mapping(address => uint256) public cummulativeEthPrice;
  mapping(address => uint32) public tokenToTimestampLast;
  mapping(address => uint256) public cummulativeAveragePriceReserve;
  mapping(address => uint256) public cummulativeEthPriceReserve;
  mapping(address => uint32) public lastTokenTimestamp;

  event AssetValue(uint256, uint256);

  constructor(uint256 window) {
    WINDOW = window;
  }

  function setWindow(uint256 newWindow) external onlyOwner {
    WINDOW = newWindow;
  }

  function setValues(address token) internal {
    address pool = IUniswapV2Factory(UNISWAP_V2_FACTORY).getPair(WETH, token);
    if (pool != address(0)) {
      if (WETH < token) {
        (
          cummulativeEthPrice[token],
          cummulativeAveragePrice[token],
          tokenToTimestampLast[token]
        ) = UniswapV2OracleLibrary.currentCumulativePrices(address(pool));
        cummulativeAveragePriceReserve[token] = IUniswapV2Pair(pool)
          .price0CumulativeLast();
        cummulativeEthPriceReserve[token] = IUniswapV2Pair(pool)
          .price1CumulativeLast();
      } else {
        (
          cummulativeAveragePrice[token],
          cummulativeEthPrice[token],
          tokenToTimestampLast[token]
        ) = UniswapV2OracleLibrary.currentCumulativePrices(address(pool));
        cummulativeAveragePriceReserve[token] = IUniswapV2Pair(pool)
          .price1CumulativeLast();
        cummulativeEthPriceReserve[token] = IUniswapV2Pair(pool)
          .price0CumulativeLast();
      }
      lastTokenTimestamp[token] = uint32(block.timestamp);
    }
  }

  function fetch(address token, bytes calldata)
    external
    override
    returns (uint256 price)
  {
    uint256 ethPerAqua = _getAmounts(AQUA);
    emit AssetValue(ethPerAqua, block.timestamp);
    uint256 ethPerToken = _getAmounts(token);
    emit AssetValue(ethPerToken, block.timestamp);
    if (ethPerToken == 0 || ethPerAqua == 0) return 0;
    price = (ethPerToken.mul(1e18)).div(ethPerAqua);
    emit AssetValue(price, block.timestamp);
  }

  function fetchAquaPrice() external override returns (uint256 price) {
    // to get aqua per eth
    if (
      cummulativeAveragePrice[AQUA] == 0 ||
      (uint32(block.timestamp) - lastTokenTimestamp[AQUA]) >= WINDOW
    ) {
      setValues(AQUA);
    }
    uint32 timeElapsed = lastTokenTimestamp[AQUA] - tokenToTimestampLast[AQUA];
    price = _calculate(
      cummulativeEthPrice[AQUA],
      cummulativeAveragePriceReserve[AQUA],
      timeElapsed,
      AQUA
    );
    emit AssetValue(price, block.timestamp);
  }

  function _getAmounts(address token) internal returns (uint256 ethPerToken) {
    if (
      cummulativeAveragePrice[token] == 0 ||
      (uint32(block.timestamp) - lastTokenTimestamp[token]) >= WINDOW
    ) {
      setValues(token);
    }
    address poolAddress = IUniswapV2Factory(UNISWAP_V2_FACTORY).getPair(
      WETH,
      token
    );
    if (poolAddress == address(0)) return 0;
    uint32 timeElapsed = lastTokenTimestamp[token] -
      tokenToTimestampLast[token];
    ethPerToken = _calculate(
      cummulativeAveragePrice[token],
      cummulativeEthPriceReserve[token],
      timeElapsed,
      token
    );
  }

  function _calculate(
    uint256 latestCommulative,
    uint256 oldCommulative,
    uint32 timeElapsed,
    address token
  ) public view returns (uint256 assetValue) {
    FixedPoint.uq112x112 memory priceTemp = FixedPoint.uq112x112(
      uint224((latestCommulative.sub(oldCommulative)).div(timeElapsed))
    );
    uint8 decimals = IERC20(token).decimals();
    assetValue = priceTemp.mul(10**decimals).decode144();
  }
}

// SPDX-License-Identifier: <SPDX-License>
pragma solidity 0.7.5;

interface IOracle {
    function fetch(address token, bytes calldata data)
        external
        returns (uint256 price);

    function fetchAquaPrice() external returns (uint256 price);
}

pragma solidity >=0.7.5;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

pragma solidity >=0.7.5;

import "./FixedPoint.sol";
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

library UniswapV2OracleLibrary {
    using FixedPoint for *;
    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2**32);
    }
    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(address pair)
        internal
        view
        returns (
            uint256 ,
            uint256 ,
            uint32 
        )
    {
        uint32 blockTimestamp = currentBlockTimestamp();
        uint256 price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        uint256 price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();
        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += uint256(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            // counterfactual
            price1Cumulative += uint256(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
        return (price0Cumulative, price1Cumulative, blockTimestampLast);
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

pragma solidity >=0.7.5;

import "./FullMath.sol";

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
    uint8 public constant RESOLUTION = 112;
    uint256 public constant Q112 = 0x10000000000000000000000000000; // 2**112
    uint256 private constant Q224 = 0x100000000000000000000000000000000000000000000000000000000; // 2**224
    uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)
    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }
    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint256 y) internal pure returns (uq144x112 memory) {
        uint256 z = 0;
        require(y == 0 || (z = self._x * y) / y == self._x, 'FixedPoint::mul: overflow');
        return uq144x112(z);
    }
    function fraction(uint256 numerator, uint256 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, 'FixedPoint::fraction: division by zero');
        if (numerator == 0) return FixedPoint.uq112x112(0);
        if (numerator <= uint144(-1)) {
            uint256 result = (numerator << RESOLUTION) / denominator;
            require(result <= uint224(-1), 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        } else {
            uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
            require(result <= uint224(-1), 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        }
    }
}

pragma solidity >=0.7.5;

library FullMath {
    function fullMul(uint256 x, uint256 y) internal pure returns (uint256 l, uint256 h) {
        uint256 mm = mulmod(x, y, uint256(-1));
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }
    function fullDiv(
        uint256 l,
        uint256 h,
        uint256 d
    ) private pure returns (uint256) {
        uint256 pow2 = d & -d;
        d /= pow2;
        l /= pow2;
        l += h * ((-pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        return l * r;
    }
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 d
    ) internal pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);
        uint256 mm = mulmod(x, y, d);
        if (mm > l) h -= 1;
        l -= mm;
        if (h == 0) return l / d;
        require(h < d, 'FullMath: FULLDIV_OVERFLOW');
        return fullDiv(l, h, d);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

