// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./SafeMath.sol";

contract VestingVaultBatchRelease {

    using SafeMath for uint256;

    event ChangeBeneficiary(address oldBeneficiary, address newBeneficiary);

    event Withdraw(address indexed to, uint256 amount);

    string public name;

    address public vestingToken;

    uint256 public constant vestingPeriodUnit = 30 days;

    uint256 public constant vestingBatchs = 10;

    uint256 public immutable timeLockedVestedAmount;

    uint256 public vestingEndTimestamp;

    address public beneficiary;

    constructor (string memory name_, address vestingToken_, address beneficiary_, uint256 timeLockedVestedAmount_) {
        name = name_;
        vestingToken = vestingToken_;
        vestingEndTimestamp = block.timestamp + vestingPeriodUnit.mul(vestingBatchs);
        timeLockedVestedAmount = timeLockedVestedAmount_;
        beneficiary = beneficiary_;
    }

    function setBeneficiary(address newBeneficiary) public {
        require(msg.sender == beneficiary, "VestingVault.setBeneficiary: can only be called by beneficiary");
        emit ChangeBeneficiary(beneficiary, newBeneficiary);
        beneficiary = newBeneficiary;
    }

    function withdraw(address to, uint256 amount) public {
        require(msg.sender == beneficiary, "VestingVault.withdraw: can only be called by beneficiary");
        IToken(vestingToken).transfer(to, amount);

        uint256 currentTimestamp = block.timestamp;
        if (currentTimestamp < vestingEndTimestamp) {
            //release discretely on a "vestingPeriodUnit" basis (e.g. monthly basis if vestingPeriodUnit = 30 days)
            //after every vestingPeriodUnit, 1 vestingBatch (1/vestingBatchs of timeLockedVestedAmount) is released
            //ratio remaining locked = (1/vestingBatchs) * ((vestingEndTimestamp - currentTimestamp)/vestingPeriodUnit + 1)
            uint256 vested = vestingEndTimestamp.sub(currentTimestamp).div(vestingPeriodUnit).add(1).mul(timeLockedVestedAmount).div(vestingBatchs);
            uint256 balance = IToken(vestingToken).balanceOf(address(this));
            require(balance >= vested, "VestingVault.withdraw: amount exceeds allowed by schedule");
        }

        emit Withdraw(to, amount);
    }

}

interface IToken {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
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
        return add(a, b, "SafeMath: addition overflow");
    }

    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return mul(a, b, "SafeMath: multiplication overflow");
    }

    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}