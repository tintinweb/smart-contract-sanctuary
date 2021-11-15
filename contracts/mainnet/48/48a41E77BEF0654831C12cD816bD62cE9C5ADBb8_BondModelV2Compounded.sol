// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../lib/math/MathUtils.sol";

import "./ABondModelV2.sol";

contract BondModelV2Compounded is ABondModelV2
{
    using SafeMath for uint256;

    function gain(
        uint256 total_,
        uint256 loanable_,
        uint256 dailyRate_,
        uint256 principal_,
        uint16 forDays_
    )
      public view override
    returns (uint256)
    {
        if (0 == total_.add(principal_)) {
          return 0;
        }

        uint256 dailyRateAprox = slippedDailyRate(dailyRate_, total_, loanable_, principal_, 0);

        uint256 aproxGain = MathUtils.compound2(
          principal_,
          dailyRateAprox,
          forDays_
        ).sub(principal_);

        uint256 rate = slippedDailyRate(dailyRate_, total_, loanable_, principal_, aproxGain);

        return MathUtils.compound2(principal_, rate, forDays_).sub(principal_);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";

library MathUtils {

    using SafeMath for uint256;

    uint256 public constant EXP_SCALE = 1e18;

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x > y ? x : y;
    }

    function compound(
        // in wei
        uint256 principal,
        // rate is * EXP_SCALE
        uint256 ratePerPeriod,
        uint16 periods
    ) internal pure returns (uint256) {
      if (0 == ratePerPeriod) {
        return principal;
      }

      while (periods > 0) {
          // principal += principal * ratePerPeriod / EXP_SCALE;
          principal = principal.add(principal.mul(ratePerPeriod).div(EXP_SCALE));
          periods -= 1;
      }

      return principal;
    }

    function compound2(
      uint256 principal,
      uint256 ratePerPeriod,
      uint16 periods
    ) internal pure returns (uint256) {
      if (0 == ratePerPeriod) {
        return principal;
      }

      while (periods > 0) {
        if (periods % 2 == 1) {
          //principal += principal * ratePerPeriod / EXP_SCALE;
          principal = principal.add(principal.mul(ratePerPeriod).div(EXP_SCALE));
          periods -= 1;
        } else {
          //ratePerPeriod = ((2 * ratePerPeriod * EXP_SCALE) + (ratePerPeriod * ratePerPeriod)) / EXP_SCALE;
          ratePerPeriod = ((uint256(2).mul(ratePerPeriod).mul(EXP_SCALE)).add(ratePerPeriod.mul(ratePerPeriod))).div(EXP_SCALE);
          periods /= 2;
        }
      }

      return principal;
    }

    function linearGain(
      uint256 principal,
      uint256 ratePerPeriod,
      uint16 periods
    ) internal pure returns (uint256) {
      return principal.add(
        fractionOf(principal, ratePerPeriod.mul(periods))
      );
    }

    // computes a * f / EXP_SCALE
    function fractionOf(uint256 a, uint256 f) internal pure returns (uint256) {
      return a.mul(f).div(EXP_SCALE);
    }

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../lib/math/MathUtils.sol";

import "../Governed.sol";

abstract contract ABondModelV2 is Governed
{
    using SafeMath for uint256;

    uint256 public constant EXP_SCALE = 1e18;

    uint256 public MAX_POOL_RATIO = 650 * 1e15; // 65%

    function gain(uint256 total_, uint256 loanable_, uint256 dailyRate_, uint256 principal_, uint16 forDays_) external view virtual returns (uint256);

    function setMaxPoolRatio(uint256 newMaxPoolRatio_)
      public
      onlyDao
    {
      MAX_POOL_RATIO = newMaxPoolRatio_;
    }

    function maxDailyRate(
      uint256 total_,
      uint256 loanable_,
      uint256 dailyRate_
    )
      public view
    returns (uint256)
    {
      if (0 == total_) {
        return 0;
      }

      return slippedDailyRate(dailyRate_, total_, loanable_, 0, 0);
    }

    function slippedDailyRate(
        uint256 dailyRate_,
        uint256 total_,
        uint256 loanable_,
        uint256 principal_,
        uint256 aproxGain_
    )
      public view
    returns (uint256)
    {
      if (0 == total_.add(principal_)) {
        return 0;
      }

      // ((loanable - aproxGain) / (total + principal)),
      uint256 ratio = (loanable_.sub(aproxGain_, "BondModelV2: liquidity")).mul(EXP_SCALE).div(total_.add(principal_));

      return MathUtils.fractionOf(
        dailyRate_,
        MathUtils.min(ratio, MAX_POOL_RATIO)
      );
    }

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;
pragma abicoder v2;

abstract contract Governed {

  address public dao;
  address public guardian;

  modifier onlyDao {
    require(
        dao == msg.sender,
        "GOV: not dao"
      );
    _;
  }

  modifier onlyDaoOrGuardian {
    require(
      msg.sender == dao || msg.sender == guardian,
      "GOV: not dao/guardian"
    );
    _;
  }

  constructor()
  {
    dao = msg.sender;
    guardian = msg.sender;
  }

  function setDao(address dao_)
    external
    onlyDao
  {
    dao = dao_;
  }

  function setGuardian(address guardian_)
    external
    onlyDao
  {
    guardian = guardian_;
  }

}

