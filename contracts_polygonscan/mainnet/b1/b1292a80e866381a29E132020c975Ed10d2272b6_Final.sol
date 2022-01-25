/**
 *Submitted for verification at polygonscan.com on 2022-01-25
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/math/SafeMath.sol


pragma solidity ^0.8.0;

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

// File: final.sol


pragma solidity ^0.8.2;

interface IERC20Token {
    
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function decimals() external returns (uint256);  
}

contract Final {
    using SafeMath for uint256;

     struct User {
        address inviter;
        address self;
        uint256 limit;
        uint256 amountLocked;
        uint256 numReff;
        uint256 joinTimes;
    }

    mapping(address => User) public tree;
    address payable owner;
    IERC20Token public tokenContract;
    uint256 daystounlock = 300 days;
    uint256 reftounlock = 2;
    uint256 price = 6;
    uint256 levels = 15;
    constructor(IERC20Token _tokenContract) public {
        owner = (payable(msg.sender));
        tokenContract = _tokenContract;
        tree[msg.sender] = User(msg.sender, msg.sender, 0, 0, 0, 0);
    }

    function enter(address inviter) external payable {
        require(msg.value >= price , "Must be at least 1 ether"); 
        require(tree[msg.sender].inviter == address(0), "Sender can't already exist in tree");
        require(tree[inviter].self == inviter, "Inviter must exist");
        owner.transfer(msg.value);
        tree[msg.sender] = User(inviter, msg.sender, msg.value.mul(20000).div(price), msg.value.mul(100000).div(price), 0, block.timestamp);
        tree[inviter].numReff += 1;

        address  current = inviter;
        uint256 rewardlimit = tree[current].limit;
        uint level = 0;
        uint amount = msg.value.mul(20000).div(price);
       while(current != owner) {
            amount = amount.div(2);
            level += 1;
            rewardlimit = rewardlimit.div(2**level); 
            if (level <= levels)    {      
            if (rewardlimit >= amount){
            require(tokenContract.transferFrom(owner, current, amount));}
            else{
            require(tokenContract.transferFrom(owner, current, rewardlimit));}
            current = tree[current].inviter;
            rewardlimit = tree[current].limit;
        }
       }

    }
    function buy() external payable {
        require(tree[msg.sender].self != address(0), "You are not a member yet");
        owner.transfer(msg.value);
        tree[msg.sender].limit +=  msg.value.mul(20000).div(price);
        

        tree[msg.sender].amountLocked += msg.value.mul(100000).div(price);

        address  current = tree[msg.sender].inviter;
        uint256 rewardlimit = tree[current].limit;
        uint level = 0;
        uint amount = msg.value.mul(20000).div(price);
       while(current != owner) {
            amount = amount.div(2);
            level += 1;
            rewardlimit = rewardlimit.div(2**level);   
            if (level <= levels)    {        
            if (rewardlimit >= amount){
            require(tokenContract.transferFrom(owner, current, amount));}
            else{
            require(tokenContract.transferFrom(owner, current, rewardlimit));}
            current = tree[current].inviter;
            rewardlimit = tree[current].limit;
            }
        }
    }
    function withdraw(uint256 _amount) public {
        require(tree[msg.sender].numReff >= reftounlock, "Your minimum refferal limit is not reached" );
        require(tree[msg.sender].joinTimes.add(daystounlock) <= block.timestamp, "lock time is not over" );        
        require(tree[msg.sender].amountLocked >= _amount, "Amount exceeds balance");
        require(tokenContract.transferFrom(owner, msg.sender, _amount));
        tree[msg.sender].amountLocked -= _amount;
           
    }
    function change(uint256 _days) public {
        require(msg.sender == owner);
        daystounlock = _days;
    }
    function changeref(uint256 _reffs) public {
        require(msg.sender == owner);
        reftounlock = _reffs;
    }
    function setprice(uint256 _price) public {
        require(msg.sender == owner);
        price = _price;
    }
    function setlevel(uint256 _level) public {
        require(msg.sender == owner);
        levels = _level;
    }
}