/**
 *Submitted for verification at Etherscan.io on 2021-07-31
*/

pragma solidity ^0.5.12;


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

interface IDPR {
    function transferFrom(address _spender, address _to, uint256 _amount) external returns(bool);
    function transfer(address _to, uint256 _amount) external returns(bool);
    function balanceOf(address _owner) external view returns(uint256);
}

contract Claim {
    using SafeMath for uint256;

    IDPR public dpr;
    //system info
    address public owner;
    uint256 public total_release_periods = 212;
    uint256 public start_time = 1627776000; //2021 年 05 月 10 日 08:00
    bool public pause = true;
    // uer info 
    mapping(address=>uint256) public total_lock_amount;
    mapping(address=>uint256) public release_per_period;
    mapping(address=>uint256) public user_released;

    //=====events=======
    event claim(address _addr, uint256 _amount);
    event distribute(address _addr, uint256 _amount);
    event OwnerTransfer(address _newOwner);

    //====modifiers====
    modifier onlyOwner(){
        require(owner == msg.sender, "MerkleClaim: Not Owner");
        _;
    }

    modifier whenNotPaused(){
        require(pause == false, "MerkleClaim: Pause");
        _;
    }

    constructor(address _token) public {
        dpr = IDPR(_token);
        owner = msg.sender;
    }

    function transferOwnerShip(address _newOwner) onlyOwner external {
        require(_newOwner != address(0), "MerkleClaim: Wrong owner");
        owner = _newOwner;
        emit OwnerTransfer(_newOwner);
    }

    function distributeAndLock(address _addr, uint256 _amount) external onlyOwner{
        lockTokens(_addr, _amount);
        emit distribute(_addr, _amount);
    }

    function lockTokens(address _addr, uint256 _amount) private{
        total_lock_amount[_addr] = _amount;
        release_per_period[_addr] = _amount.div(total_release_periods);
    }

    function setPuase(bool is_pause) onlyOwner external {
        pause = is_pause;
    }

    function claimTokens() whenNotPaused external {
        require(total_lock_amount[msg.sender] != 0, "User does not have lock record");
        require(total_lock_amount[msg.sender].sub(user_released[msg.sender]) > 0, "all token has been claimed");
        uint256 periods = block.timestamp.sub(start_time).div(1 days);
        uint256 total_release_amount = release_per_period[msg.sender].mul(periods);
        
        if(total_release_amount >= total_lock_amount[msg.sender]){
            total_release_amount = total_lock_amount[msg.sender];
        }

        uint256 release_amount = total_release_amount.sub(user_released[msg.sender]);
        // update user info
        user_released[msg.sender] = total_release_amount;
        require(dpr.balanceOf(address(this)) >= release_amount, "MerkleClaim: Balance not enough");
        require(dpr.transfer(msg.sender, release_amount), "MerkleClaim: Transfer Failed");    
        emit claim(msg.sender, release_amount);
    }

    function unreleased(address user) external view returns(uint256){
        return total_lock_amount[user].sub(user_released[user]);
    }

    function withdraw(address _to, uint256 _amount) external onlyOwner{
        require(dpr.transfer(_to, dpr.balanceOf(address(this))), "MerkleClaim: Transfer Failed");
    }

    function pullTokens(uint256 _amount) external onlyOwner{
        require(dpr.transferFrom(owner, address(this), _amount), "MerkleClaim: TransferFrom failed");
    }
}