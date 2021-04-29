/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;



// Part: BConst

contract BConst {
  uint public constant BONE = 10**18;

  uint public constant MIN_BOUND_TOKENS = 2;
  uint public constant MAX_BOUND_TOKENS = 8;

  uint public constant MIN_FEE = BONE / 10**6;
  uint public constant MAX_FEE = BONE / 10;
  uint public constant EXIT_FEE = 0;

  uint public constant MIN_WEIGHT = BONE;
  uint public constant MAX_WEIGHT = BONE * 50;
  uint public constant MAX_TOTAL_WEIGHT = BONE * 50;
  uint public constant MIN_BALANCE = BONE / 10**12;

  uint public constant INIT_POOL_SUPPLY = BONE * 100;

  uint public constant MIN_BPOW_BASE = 1 wei;
  uint public constant MAX_BPOW_BASE = (2 * BONE) - 1 wei;
  uint public constant BPOW_PRECISION = BONE / 10**10;

  uint public constant MAX_IN_RATIO = BONE / 2;
  uint public constant MAX_OUT_RATIO = (BONE / 3) + 1 wei;
}

// Part: IBalancerPool

interface IBalancerPool {
  function getFinalTokens() external view returns (address[] memory);

  function getNormalizedWeight(address token) external view returns (uint);

  function getSwapFee() external view returns (uint);

  function getNumTokens() external view returns (uint);

  function getBalance(address token) external view returns (uint);

  function totalSupply() external view returns (uint);

  function joinPool(uint poolAmountOut, uint[] calldata maxAmountsIn) external;

  function swapExactAmountOut(
    address tokenIn,
    uint maxAmountIn,
    address tokenOut,
    uint tokenAmountOut,
    uint maxPrice
  ) external returns (uint tokenAmountIn, uint spotPriceAfter);

  function joinswapExternAmountIn(
    address tokenIn,
    uint tokenAmountIn,
    uint minPoolAmountOut
  ) external returns (uint poolAmountOut);

  function exitPool(uint poolAmoutnIn, uint[] calldata minAmountsOut) external;

  function exitswapExternAmountOut(
    address tokenOut,
    uint tokenAmountOut,
    uint maxPoolAmountIn
  ) external returns (uint poolAmountIn);
}

// Part: IBaseOracle

interface IBaseOracle {
  /// @dev Return the value of the given input as ETH per unit, multiplied by 2**112.
  /// @param token The ERC-20 token to check the value.
  function getETHPx(address token) external view returns (uint);
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

// Part: BNum

contract BNum is BConst {
  function btoi(uint a) internal pure returns (uint) {
    return a / BONE;
  }

  function bfloor(uint a) internal pure returns (uint) {
    return btoi(a) * BONE;
  }

  function badd(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    require(c >= a, 'ERR_ADD_OVERFLOW');
    return c;
  }

  function bsub(uint a, uint b) internal pure returns (uint) {
    (uint c, bool flag) = bsubSign(a, b);
    require(!flag, 'ERR_SUB_UNDERFLOW');
    return c;
  }

  function bsubSign(uint a, uint b) internal pure returns (uint, bool) {
    if (a >= b) {
      return (a - b, false);
    } else {
      return (b - a, true);
    }
  }

  function bmul(uint a, uint b) internal pure returns (uint) {
    uint c0 = a * b;
    require(a == 0 || c0 / a == b, 'ERR_MUL_OVERFLOW');
    uint c1 = c0 + (BONE / 2);
    require(c1 >= c0, 'ERR_MUL_OVERFLOW');
    uint c2 = c1 / BONE;
    return c2;
  }

  function bdiv(uint a, uint b) internal pure returns (uint) {
    require(b != 0, 'ERR_DIV_ZERO');
    uint c0 = a * BONE;
    require(a == 0 || c0 / a == BONE, 'ERR_DIV_INTERNAL'); // bmul overflow
    uint c1 = c0 + (b / 2);
    require(c1 >= c0, 'ERR_DIV_INTERNAL'); //  badd require
    uint c2 = c1 / b;
    return c2;
  }

  // DSMath.wpow
  function bpowi(uint a, uint n) internal pure returns (uint) {
    uint z = n % 2 != 0 ? a : BONE;

    for (n /= 2; n != 0; n /= 2) {
      a = bmul(a, a);

      if (n % 2 != 0) {
        z = bmul(z, a);
      }
    }
    return z;
  }

  // Compute b^(e.w) by splitting it into (b^e)*(b^0.w).
  // Use `bpowi` for `b^e` and `bpowK` for k iterations
  // of approximation of b^0.w
  function bpow(uint base, uint exp) internal pure returns (uint) {
    require(base >= MIN_BPOW_BASE, 'ERR_BPOW_BASE_TOO_LOW');
    require(base <= MAX_BPOW_BASE, 'ERR_BPOW_BASE_TOO_HIGH');

    uint whole = bfloor(exp);
    uint remain = bsub(exp, whole);

    uint wholePow = bpowi(base, btoi(whole));

    if (remain == 0) {
      return wholePow;
    }

    uint partialResult = bpowApprox(base, remain, BPOW_PRECISION);
    return bmul(wholePow, partialResult);
  }

  function bpowApprox(
    uint base,
    uint exp,
    uint precision
  ) internal pure returns (uint) {
    // term 0:
    uint a = exp;
    (uint x, bool xneg) = bsubSign(base, BONE);
    uint term = BONE;
    uint sum = term;
    bool negative = false;

    // term(k) = numer / denom
    //         = (product(a - i - 1, i=1-->k) * x^k) / (k!)
    // each iteration, multiply previous term by (a-(k-1)) * x / k
    // continue until term is less than precision
    for (uint i = 1; term >= precision; i++) {
      uint bigK = i * BONE;
      (uint c, bool cneg) = bsubSign(a, bsub(bigK, BONE));
      term = bmul(term, bmul(c, x));
      term = bdiv(term, bigK);
      if (term == 0) break;

      if (xneg) negative = !negative;
      if (cneg) negative = !negative;
      if (negative) {
        sum = bsub(sum, term);
      } else {
        sum = badd(sum, term);
      }
    }

    return sum;
  }
}

// Part: UsingBaseOracle

contract UsingBaseOracle {
  IBaseOracle public immutable base; // Base oracle source

  constructor(IBaseOracle _base) public {
    base = _base;
  }
}

// File: BalancerPairOracle.sol

contract BalancerPairOracle is UsingBaseOracle, IBaseOracle, BNum {
  using SafeMath for uint;

  constructor(IBaseOracle _base) public UsingBaseOracle(_base) {}

  /// @dev Return fair reserve amounts given spot reserves, weights, and fair prices.
  /// @param resA Reserve of the first asset
  /// @param resB Reserve of the second asset
  /// @param wA Weight of the first asset
  /// @param wB Weight of the second asset
  /// @param pxA Fair price of the first asset
  /// @param pxB Fair price of the second asset
  function computeFairReserves(
    uint resA,
    uint resB,
    uint wA,
    uint wB,
    uint pxA,
    uint pxB
  ) internal pure returns (uint fairResA, uint fairResB) {
    // NOTE: wA + wB = 1 (normalize weights)
    // constant product = resA^wA * resB^wB
    // constraints:
    // - fairResA^wA * fairResB^wB = constant product
    // - fairResA * pxA / wA = fairResB * pxB / wB
    // Solving equations:
    // --> fairResA^wA * (fairResA * (pxA * wB) / (wA * pxB))^wB = constant product
    // --> fairResA / r1^wB = constant product
    // --> fairResA = resA^wA * resB^wB * r1^wB
    // --> fairResA = resA * (resB/resA)^wB * r1^wB = resA * (r1/r0)^wB
    uint r0 = bdiv(resA, resB);
    uint r1 = bdiv(bmul(wA, pxB), bmul(wB, pxA));
    // fairResA = resA * (r1 / r0) ^ wB
    // fairResB = resB * (r0 / r1) ^ wA
    if (r0 > r1) {
      uint ratio = bdiv(r1, r0);
      fairResA = bmul(resA, bpow(ratio, wB));
      fairResB = bdiv(resB, bpow(ratio, wA));
    } else {
      uint ratio = bdiv(r0, r1);
      fairResA = bdiv(resA, bpow(ratio, wB));
      fairResB = bmul(resB, bpow(ratio, wA));
    }
  }

  /// @dev Return the value of the given input as ETH per unit, multiplied by 2**112.
  /// @param token The ERC-20 token to check the value.
  function getETHPx(address token) external view override returns (uint) {
    IBalancerPool pool = IBalancerPool(token);
    require(pool.getNumTokens() == 2, 'num tokens must be 2');
    address[] memory tokens = pool.getFinalTokens();
    address tokenA = tokens[0];
    address tokenB = tokens[1];
    uint pxA = base.getETHPx(tokenA);
    uint pxB = base.getETHPx(tokenB);
    (uint fairResA, uint fairResB) =
      computeFairReserves(
        pool.getBalance(tokenA),
        pool.getBalance(tokenB),
        pool.getNormalizedWeight(tokenA),
        pool.getNormalizedWeight(tokenB),
        pxA,
        pxB
      );
    // use fairReserveA and fairReserveB to compute LP token price
    // LP price = (fairResA * pxA + fairResB * pxB) / totalLPSupply
    return fairResA.mul(pxA).add(fairResB.mul(pxB)).div(pool.totalSupply());
  }
}