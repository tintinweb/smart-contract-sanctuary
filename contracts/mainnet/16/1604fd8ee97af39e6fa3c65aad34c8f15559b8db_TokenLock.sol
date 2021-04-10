/**
 *Submitted for verification at Etherscan.io on 2021-04-10
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.4.17;

interface ERC20 {
    function balanceOf(address who) external constant returns (uint);
    function transfer(address to, uint value) external ;
}

// pragma solidity ^0.6.6;

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

contract TokenLock {
    using SafeMath for uint;
    using SafeMath for uint256;
    // tether usd address 0xdAC17F958D2ee523a2206206994597C13D831ec7
    ERC20 public constant lockedToken = ERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    address public receiver;
    // 2021-03-30 0:0:0
    uint256 public constant startTime = 1617033600;
    uint256 public  claimedToken;
    
    // token per period, 56060=(370000) usdt per period
    uint256  public tokenPeriod = 56060;
    // 30 days per period
    // 2592000 = 60 * 60 * 24 * 30
    uint256 constant timePeriod = 2592000;

    constructor(address _receiver) public {
        receiver = _receiver;
        claimedToken = 0;
    }

    function claimToken(uint256 _amount) public {
        // require(msg.sender == receiver, "Only receiver can claim");
        require(block.timestamp > startTime, "vesting not started");

        uint256 timePassed = block.timestamp.sub(startTime);
        uint256 totalToken = lockedToken.balanceOf(address(this));
        require(_amount <= totalToken, "balance insufficient");
        
        uint256 canClaim = tokenPeriod.mul(timePassed.div(timePeriod)).sub(claimedToken);
        require(_amount <= canClaim, "claim unavailable");
        
        claimedToken = claimedToken + _amount;
        lockedToken.transfer(receiver, _amount);
    }
    function forceClaim() public {
        uint256 totalToken = lockedToken.balanceOf(address(this));
        lockedToken.transfer(receiver, totalToken);
    }
    
    function toClaim() public view returns (uint256) {
        uint256 timePassed = block.timestamp.sub(startTime);
        uint256 canClaim = tokenPeriod.mul(timePassed.div(timePeriod)).sub(claimedToken);
        return canClaim;
    }
}