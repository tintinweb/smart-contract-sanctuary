/**
 *Submitted for verification at BscScan.com on 2022-01-18
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;


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
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract stakingContract {

    using SafeMath for uint256;

    event OwnershipTransferred(address indexed owner, address indexed newOwner);
    event StakeLimitUpdated(uint256 stakeLimit);

    address public owner;
    IERC20 public token;
    uint256 minTxAmount = 100000 * 10 ** 8;

    struct userDetails {
        uint256 level;
        uint256 amount;
        uint256 initialTime;
        uint256 endTime;
        uint256 rewardAmount;
        uint256 withdrawAmount;
        bool isActive;
    }

    mapping(address =>mapping(uint256 => userDetails)) private user;
    mapping(uint256 => uint256) private levelPercentage;

    modifier onlyOwner() {
        require(owner == msg.sender,"Ownable: Caller is not owner");
        _;
    }

    constructor (IERC20 _token) {
        token = _token;
        levelPercentage[1] = 127;
        levelPercentage[2] = 223;
        levelPercentage[3] = 305; 
        owner = msg.sender;  
    }

    function transferOwnership(address newOwner) public onlyOwner returns(bool){
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        return true;
    }

    function staking(uint256 amount, uint256 level) public returns(bool) {
        require(amount >= minTxAmount, "amount is less than minTxAmount");
        require(!(user[msg.sender][level].isActive),"user already exist");
        user[msg.sender][level].amount = amount;
        user[msg.sender][level].level = level;
        setlevel(level);
        user[msg.sender][level].initialTime = block.timestamp;
        user[msg.sender][level].isActive = true;
        token.transferFrom(msg.sender, address(this), amount);
        return true;
    }

    function setlevel(uint256 level) internal {
        if(level == 1) {
            user[msg.sender][level].endTime = 0;
        }
        else if(level == 2) {
            user[msg.sender][level].endTime = block.timestamp + 60 days;
        }
        else if(level == 3) {
            user[msg.sender][level].endTime = block.timestamp + 90 days;
        }
    }

    function getRewards(address account, uint256 level) public view returns(uint256) {
        if(user[account][level].isActive) {
            uint256 stakeAmount = user[account][level].amount;
            uint256 timeDiff;
            require(block.timestamp >= user[account][level].initialTime, "Time exceeds");
            unchecked {
                timeDiff = block.timestamp - user[account][level].initialTime;
            }
            uint256 rewardRate = levelPercentage[user[account][level].level];
            uint256 rewardAmount = (stakeAmount*(rewardRate)/100)*timeDiff/365 days;
            return rewardAmount;
        }
        else return 0;
    }

    function withdraw(uint256 level) public returns(bool) {
        require(user[msg.sender][level].isActive, "user not exist");
        require(user[msg.sender][level].endTime <= block.timestamp, "staking end time is not reached ");
        uint256 rewardAmount = getRewards(msg.sender, level);
        uint256 amount = rewardAmount + user[msg.sender][level].amount;
        token.transfer(msg.sender, amount);
        user[msg.sender][level].amount = 0;
        user[msg.sender][level].rewardAmount += rewardAmount; 
        user[msg.sender][level].withdrawAmount += amount; 
        user[msg.sender][level].isActive = false; 
        return true;
    }

    function emergencyWithdraw(uint256 level) public returns(uint256) {
        require(user[msg.sender][level].isActive, "user not exist");
        uint256 stakedAmount = user[msg.sender][level].amount.sub(user[msg.sender][level].amount.mul(3).div(100)); 
        token.transfer(msg.sender, stakedAmount);
        user[msg.sender][level].amount = 0;
        user[msg.sender][level].isActive = false;
        return stakedAmount;
    }

    function getUserDetails(address account, uint256 level) public view returns(userDetails memory, uint256) {
        uint256 reward = getRewards(account, level);
        return (userDetails(user[account][level].level, user[account][level].amount, user[account][level].initialTime, user[account][level].endTime, user[account][level].rewardAmount, user[account][level].withdrawAmount, user[account][level].isActive), reward);
    }

    function setStakeLimit(uint256 stakeLimit) public onlyOwner returns(bool) {
        minTxAmount = stakeLimit;
        emit StakeLimitUpdated(minTxAmount);
        return true;
    }


}