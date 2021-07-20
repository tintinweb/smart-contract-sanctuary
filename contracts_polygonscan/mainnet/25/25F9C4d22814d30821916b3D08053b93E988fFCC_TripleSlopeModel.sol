/**
 *Submitted for verification at polygonscan.com on 2021-07-20
*/

// Sources flattened with hardhat v2.4.3 https://hardhat.org

// File openzeppelin-solidity-2.3.0/contracts/math/[email protected]

pragma solidity ^0.5.0;

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


// File contracts/5/TripleSlopeModel.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;

//
//contract TripleSlopeModel {
//    using SafeMath for uint256;
//
//    function getInterestRate(uint256 debt, uint256 floating) external pure returns (uint256) {
//        uint256 total = debt.add(floating);
//        uint256 utilization = total == 0 ? 0 : debt.mul(10000).div(total);
//        if (utilization < 5000) {
//            // Less than 50% utilization - 10% APY
//            return uint256(10e16) / 365 days;
//        } else if (utilization < 9500) {
//            // Between 50% and 95% - 10%-25% APY
//            return (10e16 + utilization.sub(5000).mul(15e16).div(10000)) / 365 days;
//        } else if (utilization < 10000) {
//            // Between 95% and 100% - 25%-100% APY
//            return (25e16 + utilization.sub(7500).mul(75e16).div(10000)) / 365 days;
//        } else {
//            // Not possible, but just in case - 100% APY
//            return uint256(100e16) / 365 days;
//        }
//    }
//}
//
//pragma solidity 0.6.6;
//
//import "openzeppelin-solidity-2.3.0/contracts/math/SafeMath.sol";
//
contract TripleSlopeModel {
    using SafeMath for uint256;

    uint256 public constant CEIL_SLOPE_1 = 50e18;
    uint256 public constant CEIL_SLOPE_2 = 90e18;
    uint256 public constant CEIL_SLOPE_3 = 100e18;

    uint256 public constant MAX_INTEREST_SLOPE_1 = 20e16;
    uint256 public constant MAX_INTEREST_SLOPE_2 = 20e16;
    uint256 public constant MAX_INTEREST_SLOPE_3 = 150e16;

    /// @dev Return the interest rate per second, using 1e18 as denom.
    function getInterestRate(uint256 debt, uint256 floating) external pure returns (uint256) {
        if (debt == 0 && floating == 0) return 0;

        uint256 total = debt.add(floating);
        uint256 utilization = debt.mul(100e18).div(total);
        if (utilization < CEIL_SLOPE_1) {
            // Less than 50% utilization - 0%-20% APY
            return utilization.mul(MAX_INTEREST_SLOPE_1).div(CEIL_SLOPE_1) / 365 days;
        } else if (utilization < CEIL_SLOPE_2) {
            // Between 50% and 90% - 20% APY
            return uint256(MAX_INTEREST_SLOPE_2) / 365 days;
        } else if (utilization < CEIL_SLOPE_3) {
            // Between 90% and 100% - 20%-150% APY
            return (MAX_INTEREST_SLOPE_2 + utilization.sub(CEIL_SLOPE_2).mul(MAX_INTEREST_SLOPE_3.sub(MAX_INTEREST_SLOPE_2)).div(CEIL_SLOPE_3.sub(CEIL_SLOPE_2))) / 365 days;
        } else {
            // Not possible, but just in case - 150% APY
            return MAX_INTEREST_SLOPE_3 / 365 days;
        }
    }
}