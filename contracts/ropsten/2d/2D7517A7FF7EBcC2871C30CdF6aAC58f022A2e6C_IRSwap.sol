// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/compound-protocol/CTokenInterface.sol";

contract IRSwap {

  using SafeMath for uint256;
  
  address public cTokenAddress;
  uint8 public initLeverage; //leverage here is the reciprocal of initial margin ratio
  uint8 public maintLeverage; //leverage here is the reciprocal of maintenance margin ratio
  
  IRSwapSpec[] swaps;
  
  struct IRSwapSpec {
    uint256 startBlock;
    uint256 endBlock;
    uint256 notional;
    uint256 initCTokenRate;
    uint256 fixedRatePerBlock;
    address addressPayer;
    uint256 fundingPayer;
    uint256 accruedInterestPayer;
    address addressReceiver;
    uint256 fundingReceiver;
    uint256 accruedInterestReceiver;
  }
  
  constructor(address _cTokenAddress, uint8 _initLeverage, uint8 _maintLeverage) public {
    cTokenAddress = _cTokenAddress;
    initLeverage = _initLeverage;
    maintLeverage = _maintLeverage;
  }

  function getCTokenRate() public view returns(uint256, uint256) {
    return (CTokenInterface(cTokenAddress).exchangeRateStored(), block.number);
  }

  function pingCompound() public {
    CTokenInterface(cTokenAddress).accrueInterest();
  }

  function createSwap(
                      uint256 notional,
                      uint256 endBlock,
                      uint256 fixedRatePerBlock,
                      address addressPayer,
                      uint256 fundingPayer,
                      address addressReceiver,
                      uint256 fundingReceiver
                      ) public {
    require(notional > 0, "notional too small");
    require(endBlock > block.number, "endBlock must be in future");
    require(fundingPayer >= notional.div(initLeverage), "funding below initMargin");
    require(fundingReceiver >= notional.div(initLeverage), "funding below initMargin");

    (uint256 initCTokenRate, ) = getCTokenRate();
    IRSwapSpec memory swap = IRSwapSpec(block.number,
                                 endBlock,
                                 notional,
                                 initCTokenRate,
                                 fixedRatePerBlock,
                                 addressPayer,
                                 fundingPayer,
                                 0,
                                 addressReceiver,
                                 fundingReceiver,
                                 0
                                 );
    swaps.push(swap);
  }

  function accrueInterest(uint256 i) public {
    require(i < swaps.length, "index out of bounds");
    IRSwapSpec storage swap = swaps[i];
    (uint256 currentCTokenRate, uint256 currentBlock) = getCTokenRate();
    swap.accruedInterestPayer = swap.notional.mul(currentCTokenRate).div(swap.initCTokenRate).sub(swap.notional);
    uint256 accruedInterestReceiver = swap.notional;
    uint256 periods = currentBlock.sub(swap.startBlock);
    uint256 mantissa = 1e18;  //fixedRatePerBlock by convention is eighteen decimals
    for(uint j=0; j < periods; j++) {
      accruedInterestReceiver = accruedInterestReceiver.mul(mantissa + swap.fixedRatePerBlock).div(mantissa);
    }
    accruedInterestReceiver = accruedInterestReceiver - swap.notional;
    swap.accruedInterestReceiver = accruedInterestReceiver;
  }

  //READ FUNCTIONS
  function getSwapSpec(uint256 i) public view returns(
                                                      uint256,
                                                      uint256,
                                                      uint256,
                                                      uint256,
                                                      uint256,
                                                      address,
                                                      uint256,
                                                      uint256,
                                                      address,
                                                      uint256,
                                                      uint256
                                                      ) {
    require(i < swaps.length, "index out of bounds");
    IRSwapSpec memory swap = swaps[i];
    return (swap.startBlock,
            swap.endBlock,
            swap.notional,
            swap.initCTokenRate,
            swap.fixedRatePerBlock,
            swap.addressPayer,
            swap.fundingPayer,
            swap.accruedInterestPayer,
            swap.addressReceiver,
            swap.fundingReceiver,
            swap.accruedInterestReceiver
            );
  }
}

pragma solidity ^0.8.9;

interface CTokenInterface {
  function transfer(address dst, uint amount) external returns (bool);
  function transferFrom(address src, address dst, uint amount) external returns (bool);
  function approve(address spender, uint amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint);
  function balanceOf(address owner) external view returns (uint);
  function balanceOfUnderlying(address owner) external returns (uint);
  function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
  function borrowRatePerBlock() external view returns (uint);
  function supplyRatePerBlock() external view returns (uint);
  function totalBorrowsCurrent() external returns (uint);
  function borrowBalanceCurrent(address account) external returns (uint);
  function borrowBalanceStored(address account) external view returns (uint);
  function exchangeRateCurrent() external returns (uint);
  function exchangeRateStored() external view returns (uint);
  function getCash() external view returns (uint);
  function accrueInterest() external returns (uint);
  function seize(address liquidator, address borrower, uint seizeTokens) external returns (uint); 
}