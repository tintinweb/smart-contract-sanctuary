/**
 *Submitted for verification at Etherscan.io on 2021-03-02
*/

pragma solidity ^0.6.7;

import "./SafeMath.sol";

abstract contract ERC20 {
    uint256 public totalSupply;
    function balanceOf(address _owner) view public virtual returns (uint256 balance);
    function transfer(address _to, uint256 _value) public virtual returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool success);
    function approve(address _spender, uint256 _value) public virtual returns (bool success);
    function allowance(address _owner, address _spender) view public virtual returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract COPS_STAKING {
    using SafeMath for uint256;

    uint256 constant public LOCK_PERIOD = 72 hours;
    uint256 constant public ENTRY_FEE = 15;  // 1.5%
    uint256 constant public EXIT_FEE = 5; //0.5%

    uint256 public TOTAL_REWARD_AVAILABLE;

    ERC20 public token;

    struct Holder {
        uint256 amount;
        uint256 depositTime;
        uint256 lastClaimTime;
    }

    mapping(address => Holder) public holders;

    constructor(ERC20 _token) public{
        token = _token;
        TOTAL_REWARD_AVAILABLE = 3780 ether; // only 3780 COPS are available for stake rewarding
    }

    function deposit(uint256 _amount) public {
        // move ERC-20 token
        require(_amount > 0, 'not enough for staking');
        require(token.transferFrom(msg.sender, address(this), _amount));

        // take stake entry fee
        uint256 entry_fee = _amount.mul(ENTRY_FEE).div(1000);
        holders[msg.sender].amount = holders[msg.sender].amount.add(_amount).sub(entry_fee);
        holders[msg.sender].depositTime = block.timestamp;
        holders[msg.sender].lastClaimTime = block.timestamp;
    }

    function estimateProfit (address _holder) view public returns (uint256) {
        // 0.16% staking rate for every day (APY: 60%)
        uint256 cDays = (block.timestamp - holders[_holder].lastClaimTime).div(86400);
        uint256 stakeProfit = holders[_holder].amount.mul(16).mul(cDays).div(10000);
        return stakeProfit;
    }

    function balanceOf(address _holder) view public returns (uint256){
        if (holders[_holder].depositTime == 0) return 0;
        return holders[_holder].amount.add(estimateProfit(_holder));
    }

    /**
        user can claim profit from staking anytime using this function
     */
    function claim() public {
        // check lock time restriction
        require(block.timestamp > holders[msg.sender].depositTime.add(LOCK_PERIOD));
        uint256 profit = estimateProfit(msg.sender);
        require(profit > 0, 'no profit to claim');
        require(TOTAL_REWARD_AVAILABLE > 0, 'reward is drained');

        if (profit > TOTAL_REWARD_AVAILABLE) {
            profit = TOTAL_REWARD_AVAILABLE;
        }
        // transfer COPS token from staking contract
        holders[msg.sender].lastClaimTime = block.timestamp;
        TOTAL_REWARD_AVAILABLE.sub(profit);
        require(token.transfer(msg.sender, profit), 'claim failed');
    }

    function withdraw() public {
        require(holders[msg.sender].amount > 0, 'nothing to withdraw');
        require(block.timestamp > holders[msg.sender].depositTime.add(LOCK_PERIOD), 'fund locked');
        uint256 profit = estimateProfit(msg.sender);
        if (profit > TOTAL_REWARD_AVAILABLE) {
            profit = TOTAL_REWARD_AVAILABLE;
        }
        uint256 amount = holders[msg.sender].amount;
        uint256 outFee= amount.mul(EXIT_FEE).div(1000);
        amount = amount.sub(outFee);
        // transfer staking and profit to the holder
        holders[msg.sender].amount = 0;
        TOTAL_REWARD_AVAILABLE.sub(profit);
        require(token.transfer(msg.sender, amount.add(profit)), 'withdraw failed');
    }
}

pragma solidity ^0.6.7;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

