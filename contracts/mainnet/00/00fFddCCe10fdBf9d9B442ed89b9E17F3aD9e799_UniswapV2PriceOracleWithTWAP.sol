// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/IPriceOracle.sol";
import "../interfaces/IERC20Metadata.sol";
import "../interfaces/IUniswapV2Pair.sol";

interface IUniswapTWAPOracle {
  function pair() external view returns (address);

  function quote(
    address tokenIn,
    uint256 amountIn,
    address tokenOut,
    uint256 points
  ) external view returns (uint256 amountOut, uint256 lastUpdatedAgo);
}

contract UniswapV2PriceOracleWithTWAP is Ownable, IPriceOracle {
  using SafeMath for uint256;

  event UpdatePair(address indexed asset, address pair);
  event UpdateTWAP(address indexed asset, address pair);
  event UpdateMaxPriceDiff(address indexed asset, uint256 maxPriceDiff);
  event UpdateMaxTimestampDelta(uint256 maxTimestampDelta);

  // The address of Chainlink Oracle
  address public immutable chainlink;

  // The address base token.
  address public immutable base;

  // Mapping from asset address to uniswap v2 like pair.
  mapping(address => address) public pairs;

  // Mapping from pair address to twap address.
  mapping(address => address) public twaps;

  // The max price diff between spot price and twap price.
  mapping(address => uint256) public maxPriceDiff;

  // The max timestamp delta between current block and twap last updated timestamp.
  uint256 public maxTimestampDelta = 24 * 60 * 60;

  /// @param _chainlink The address of chainlink oracle.
  /// @param _base The address of base token.
  constructor(address _chainlink, address _base) {
    require(_chainlink != address(0), "UniswapV2PriceOracleWithTWAP: zero address");
    require(_base != address(0), "UniswapV2PriceOracleWithTWAP: zero address");

    chainlink = _chainlink;
    base = _base;
  }

  /// @dev Return the usd price of asset. mutilpled by 1e18
  /// @param _asset The address of asset
  function price(address _asset) public view override returns (uint256) {
    address _pair = pairs[_asset];
    require(_pair != address(0), "UniswapV2PriceOracleWithTWAP: not supported");

    address _base = base;
    uint256 _basePrice = IPriceOracle(chainlink).price(_base);
    (uint256 _reserve0, uint256 _reserve1, ) = IUniswapV2Pair(_pair).getReserves();
    address _token0 = IUniswapV2Pair(_pair).token0();
    address _token1 = IUniswapV2Pair(_pair).token1();

    // validate price
    if (_asset == _token0) {
      _validate(_pair, _base, _asset, _reserve1, _reserve0);
    } else {
      _validate(_pair, _base, _asset, _reserve0, _reserve1);
    }

    // make reserve with scale 1e18
    if (IERC20Metadata(_token0).decimals() < 18) {
      _reserve0 = _reserve0.mul(10**(18 - IERC20Metadata(_token0).decimals()));
    }
    if (IERC20Metadata(_token1).decimals() < 18) {
      _reserve1 = _reserve1.mul(10**(18 - IERC20Metadata(_token1).decimals()));
    }

    if (_asset == _token0) {
      return _basePrice.mul(_reserve1).div(_reserve0);
    } else {
      return _basePrice.mul(_reserve0).div(_reserve1);
    }
  }

  /// @dev Return the usd value of asset. mutilpled by 1e18
  /// @param _asset The address of asset
  /// @param _amount The amount of asset
  function value(address _asset, uint256 _amount) external view override returns (uint256) {
    uint256 _price = price(_asset);
    return _price.mul(_amount).div(10**IERC20Metadata(_asset).decimals());
  }

  /// @dev Update the UniswapV2 pair for asset
  /// @param _asset The address of asset
  /// @param _pair The address of UniswapV2 pair
  function updatePair(address _asset, address _pair) external onlyOwner {
    require(_pair != address(0), "UniswapV2PriceOracleWithTWAP: invalid pair");

    address _base = base;
    require(_base != _asset, "UniswapV2PriceOracleWithTWAP: invalid asset");

    address _token0 = IUniswapV2Pair(_pair).token0();
    address _token1 = IUniswapV2Pair(_pair).token1();
    require(_token0 == _asset || _token1 == _asset, "UniswapV2PriceOracleWithTWAP: invalid pair");
    require(_token0 == _base || _token1 == _base, "UniswapV2PriceOracleWithTWAP: invalid pair");

    pairs[_asset] = _pair;

    emit UpdatePair(_asset, _pair);
  }

  /// @dev Update the TWAP Oracle address for UniswapV2 pair
  /// @param _pair The address of UniswapV2 pair
  /// @param _twap The address of twap oracle.
  function updateTWAP(address _pair, address _twap) external onlyOwner {
    require(IUniswapTWAPOracle(_twap).pair() == _pair, "UniswapV2PriceOracleWithTWAP: invalid twap");

    twaps[_pair] = _twap;

    emit UpdateTWAP(_pair, _twap);
  }

  /// @dev Update the max price diff between spot price and twap price.
  /// @param _asset The address of asset.
  /// @param _maxPriceDiff The max price diff.
  function updatePriceDiff(address _asset, uint256 _maxPriceDiff) external onlyOwner {
    require(_maxPriceDiff <= 2e17, "UniswapV2PriceOracleWithTWAP: should <= 20%");

    maxPriceDiff[_asset] = _maxPriceDiff;

    emit UpdateMaxPriceDiff(_asset, _maxPriceDiff);
  }

  /// @dev Update max timestamp delta between current block and twap last updated timestamp.
  /// @param _maxTimestampDelta The value of max timestamp delta, in seconds.
  function updateMaxTimestampDelta(uint256 _maxTimestampDelta) external onlyOwner {
    maxTimestampDelta = _maxTimestampDelta;

    emit UpdateMaxTimestampDelta(_maxTimestampDelta);
  }

  function _validate(
    address _pair,
    address _base,
    address _asset,
    uint256 _reserveBase,
    uint256 _reserveAsset
  ) internal view {
    address _twap = twaps[_pair];
    // skip check if twap not available, usually will be used in test.
    if (_twap == address(0)) return;
    uint256 _priceDiff = maxPriceDiff[_asset];
    uint256 _unitAmount = 10**IERC20Metadata(_asset).decimals();

    // number of base token that 1 asset can swap right now.
    uint256 _amount = _reserveBase.mul(_unitAmount).div(_reserveAsset);
    // number of base token that 1 asset can swap in twap.
    (uint256 _twapAmount, uint256 _lastUpdatedAgo) = IUniswapTWAPOracle(_twap).quote(_asset, _unitAmount, _base, 2);

    require(_lastUpdatedAgo <= maxTimestampDelta, "UniswapV2PriceOracleWithTWAP: twap price too old");
    require(_amount >= _twapAmount.mul(1e18 - _priceDiff).div(1e18), "UniswapV2PriceOracleWithTWAP: price too small");
    require(_amount <= _twapAmount.mul(1e18 + _priceDiff).div(1e18), "UniswapV2PriceOracleWithTWAP: price too large");
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IPriceOracle {
  /// @dev Return the usd price of asset. mutilpled by 1e18
  /// @param _asset The address of asset
  function price(address _asset) external view returns (uint256);

  /// @dev Return the usd value of asset. mutilpled by 1e18
  /// @param _asset The address of asset
  /// @param _amount The amount of asset
  function value(address _asset, uint256 _amount) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IERC20Metadata {
  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IUniswapV2Pair {
  function totalSupply() external view returns (uint256);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function price0CumulativeLast() external view returns (uint256);

  function price1CumulativeLast() external view returns (uint256);
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