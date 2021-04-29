/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;



// Part: IBaseOracle

interface IBaseOracle {
  /// @dev Return the value of the given input as ETH per unit, multiplied by 2**112.
  /// @param token The ERC-20 token to check the value.
  function getETHPx(address token) external view returns (uint);
}

// Part: ICurvePool

interface ICurvePool {
  function add_liquidity(uint[2] calldata, uint) external;

  function add_liquidity(uint[3] calldata, uint) external;

  function add_liquidity(uint[4] calldata, uint) external;

  function remove_liquidity(uint, uint[2] calldata) external;

  function remove_liquidity(uint, uint[3] calldata) external;

  function remove_liquidity(uint, uint[4] calldata) external;

  function remove_liquidity_imbalance(uint[2] calldata, uint) external;

  function remove_liquidity_imbalance(uint[3] calldata, uint) external;

  function remove_liquidity_imbalance(uint[4] calldata, uint) external;

  function remove_liquidity_one_coin(
    uint,
    int128,
    uint
  ) external;

  function get_virtual_price() external view returns (uint);
}

// Part: ICurveRegistry

interface ICurveRegistry {
  function get_n_coins(address lp) external view returns (uint, uint);

  function pool_list(uint id) external view returns (address);

  function get_coins(address pool) external view returns (address[8] memory);

  function get_gauges(address pool) external view returns (address[10] memory, uint128[10] memory);

  function get_lp_token(address pool) external view returns (address);

  function get_pool_from_lp_token(address lp) external view returns (address);
}

// Part: IERC20Decimal

interface IERC20Decimal {
  function decimals() external view returns (uint8);
}

// Part: OpenZeppelin/[email protected]/SafeMath

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

// Part: UsingBaseOracle

contract UsingBaseOracle {
  IBaseOracle public immutable base; // Base oracle source

  constructor(IBaseOracle _base) public {
    base = _base;
  }
}

// File: CurveOracle.sol

contract CurveOracle is UsingBaseOracle, IBaseOracle {
  using SafeMath for uint;

  ICurveRegistry public immutable registry; // Curve registry

  struct UnderlyingToken {
    uint8 decimals; // token decimals
    address token; // token address
  }

  mapping(address => UnderlyingToken[]) public ulTokens; // Mapping from LP token to underlying tokens
  mapping(address => address) public poolOf; // Mapping from LP token to pool

  constructor(IBaseOracle _base, ICurveRegistry _registry) public UsingBaseOracle(_base) {
    registry = _registry;
  }

  /// @dev Register the pool given LP token address and set the pool info.
  /// @param lp LP token to find the corresponding pool.
  function registerPool(address lp) external {
    address pool = poolOf[lp];
    require(pool == address(0), 'lp is already registered');
    pool = registry.get_pool_from_lp_token(lp);
    require(pool != address(0), 'no corresponding pool for lp token');
    poolOf[lp] = pool;
    (uint n, ) = registry.get_n_coins(pool);
    address[8] memory tokens = registry.get_coins(pool);
    for (uint i = 0; i < n; i++) {
      ulTokens[lp].push(
        UnderlyingToken({token: tokens[i], decimals: IERC20Decimal(tokens[i]).decimals()})
      );
    }
  }

  /// @dev Return the value of the given input as ETH per unit, multiplied by 2**112.
  /// @param lp The ERC-20 LP token to check the value.
  function getETHPx(address lp) external view override returns (uint) {
    address pool = poolOf[lp];
    require(pool != address(0), 'lp is not registered');
    UnderlyingToken[] memory tokens = ulTokens[lp];
    uint minPx = uint(-1);
    uint n = tokens.length;
    for (uint idx = 0; idx < n; idx++) {
      UnderlyingToken memory ulToken = tokens[idx];
      uint tokenPx = base.getETHPx(ulToken.token);
      if (ulToken.decimals < 18) tokenPx = tokenPx.div(10**(18 - uint(ulToken.decimals)));
      if (ulToken.decimals > 18) tokenPx = tokenPx.mul(10**(uint(ulToken.decimals) - 18));
      if (tokenPx < minPx) minPx = tokenPx;
    }
    require(minPx != uint(-1), 'no min px');
    // use min underlying token prices
    return minPx.mul(ICurvePool(pool).get_virtual_price()).div(1e18);
  }
}