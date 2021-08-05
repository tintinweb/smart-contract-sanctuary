/**
 *Submitted for verification at Etherscan.io on 2020-11-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity ^0.6.0;

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


pragma solidity ^0.6.0;

contract Farm {
    using SafeMath for uint256;

    struct User {
        uint256 lastBlockChecked;
        uint256 rewards;
        uint256 pooledBalance3;
        uint256 pooledBalance6;
        uint256 pooledBalance12;
        uint256 lastStake3;
        uint256 lastStake6;
        uint256 lastStake12;
    }


    uint256 public difficulty3;
    uint256 public difficulty6;
    uint256 public difficulty12;

    uint256 public totalPooledBPT3;
    uint256 public totalPooledBPT6;
    uint256 public totalPooledBPT12;
    
    uint256 private month = 2629743;
    
    address private owner;

    IERC20 public ao;
    IERC20 public bpt;


    mapping(address => User) public pooled;
    mapping(address => uint256) public totalClaimed;

    
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount, uint256 fee);
    event Rewarded(address indexed user, uint256 amountClaimed);


    constructor (address _ao, address _bpt) public {
        owner = msg.sender;
        ao = IERC20(_ao);
        bpt = IERC20(_bpt);
    }

    modifier _onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    


    function update(address account) internal virtual {
        pooled[account].rewards = pendingReward(msg.sender);
        pooled[account].lastBlockChecked = block.number;        
    }
    
    function getPooledBalance3(address _account) public view returns (uint256) {
        return pooled[_account].pooledBalance3;
    }

    function getPooledBalance6(address _account) public view returns (uint256) {
        return pooled[_account].pooledBalance6;
    }

    function getPooledBalance12(address _account) public view returns (uint256) {
        return pooled[_account].pooledBalance12;
    }
    
    function getLast3(address _account) public view returns (uint256) {
        return pooled[_account].lastStake3;
    }

    function getLast6(address _account) public view returns (uint256) {
        return pooled[_account].lastStake6;
    }

    function getLast12(address _account) public view returns (uint256) {
        return pooled[_account].lastStake12;
    }
    
    function setDifficulty(uint256 amount3, uint256 amount6, uint256 amount12) public _onlyOwner {
        difficulty3 = amount3;
        difficulty6 = amount6;
        difficulty12 = amount12;

    }

    function pooledBalance() public view returns (uint256) {
        return bpt.balanceOf(address(this));
    }

    function aoRemaining() public view returns (uint256) {
        return ao.balanceOf(address(this));
    }




    function pendingReward(address account) public view returns (uint256) {
        if (block.number > pooled[account].lastBlockChecked) {
            uint256 rewardBlocks = block.number
                                        .sub(pooled[account].lastBlockChecked);
                                        
                                        
             

                uint256 reward3 = pooled[account].pooledBalance3.mul(rewardBlocks) / difficulty3;
                uint256 reward6 = pooled[account].pooledBalance6.mul(rewardBlocks) / difficulty6;
                uint256 reward12 = pooled[account].pooledBalance12.mul(rewardBlocks) / difficulty12;


                return pooled[account].rewards.add(reward3).add(reward6).add(reward12);
        }
    }

    function stakePool3(uint256 amount) public {
        update(msg.sender);
        require(bpt.transferFrom(msg.sender, address(this), amount));
        pooled[msg.sender].pooledBalance3 = pooled[msg.sender].pooledBalance3.add(amount);
        pooled[msg.sender].lastStake3 = now;
        totalPooledBPT3 = totalPooledBPT3.add(amount);
        emit Staked(msg.sender, amount);
    }

    function stakePool6(uint256 amount) public {
        update(msg.sender);
        require(bpt.transferFrom(msg.sender, address(this), amount));
        pooled[msg.sender].pooledBalance6 = pooled[msg.sender].pooledBalance6.add(amount);
        pooled[msg.sender].lastStake6 = now;
        totalPooledBPT6 = totalPooledBPT6.add(amount);
        emit Staked(msg.sender, amount);
    }

    function stakePool12(uint256 amount) public {
        update(msg.sender);
        require(bpt.transferFrom(msg.sender, address(this), amount));
        pooled[msg.sender].pooledBalance12 = pooled[msg.sender].pooledBalance12.add(amount);
        pooled[msg.sender].lastStake12 = now;
        totalPooledBPT12 = totalPooledBPT12.add(amount);
        emit Staked(msg.sender, amount);
    }

    function totalPoolSum() public view returns (uint256) {
        return totalPooledBPT3.add(totalPooledBPT6).add(totalPooledBPT12);
    }
   
   function withdrawPool3(uint256 amount) public {

       uint256 timeSinceLastStake = now.sub(pooled[msg.sender].lastStake3);
       require(timeSinceLastStake >= month, "Unlock time has not elapsed");
       require(pooled[msg.sender].pooledBalance3 >= amount);

       uint256 baseAmount = amount.mul(pooledBalance()).div(totalPoolSum());
       uint256 withdrawBPT;
       uint256 fee;

       if (timeSinceLastStake < month.mul(2)) {
           withdrawBPT = baseAmount.mul(85).div(100);
           fee = 15;
           } else if (timeSinceLastStake >= month.mul(2) && timeSinceLastStake < month.mul(3)) {
            withdrawBPT = baseAmount.mul(90).div(100);
           fee = 10;
           } else if (timeSinceLastStake >= month.mul(3)) {
           withdrawBPT = baseAmount;
           fee = 0;
           }

        getReward();
        pooled[msg.sender].pooledBalance3 = pooled[msg.sender].pooledBalance3.sub(amount);
        totalPooledBPT3 = totalPooledBPT3.sub(amount);
        
        bpt.transfer(msg.sender, withdrawBPT);
        emit Withdrawn(msg.sender, amount, fee);
    }

    function withdrawPool6(uint256 amount) public {

       uint256 timeSinceLastStake = now.sub(pooled[msg.sender].lastStake6);
       require(timeSinceLastStake >= month.mul(2), "Unlock time has not elapsed");
       require(pooled[msg.sender].pooledBalance6 >= amount);

       uint256 baseAmount = amount.mul(pooledBalance()).div(totalPoolSum());
       uint256 withdrawBPT;
       uint256 fee;

       if (timeSinceLastStake < month.mul(4)) {
           withdrawBPT = baseAmount.mul(85).div(100);
           fee = 15;
           } else if (timeSinceLastStake >= month.mul(4) && timeSinceLastStake < month.mul(6)) {
            withdrawBPT = baseAmount.mul(90).div(100);
           fee = 10;
           } else if (timeSinceLastStake >= month.mul(6)) {
           withdrawBPT = baseAmount;
           fee = 0;
           }

        getReward();
        pooled[msg.sender].pooledBalance6 = pooled[msg.sender].pooledBalance6.sub(amount);
        totalPooledBPT6 = totalPooledBPT6.sub(amount);

        bpt.transfer(msg.sender, withdrawBPT);
        emit Withdrawn(msg.sender, amount, fee);
    }

    function withdrawPool12(uint256 amount) public {

       uint256 timeSinceLastStake = now.sub(pooled[msg.sender].lastStake12);
       require(timeSinceLastStake >= month.mul(4), "Unlock time has not elapsed");
       require(pooled[msg.sender].pooledBalance12 >= amount);

       uint256 baseAmount = amount.mul(pooledBalance()).div(totalPoolSum());
       uint256 withdrawBPT;
       uint256 fee;

       if (timeSinceLastStake < month.mul(8)) {
           withdrawBPT = baseAmount.mul(85).div(100);
           fee = 15;
           } else if (timeSinceLastStake >= month.mul(8) && timeSinceLastStake < month.mul(12)) {
            withdrawBPT = baseAmount.mul(90).div(100);
           fee = 10;
           } else if (timeSinceLastStake >= month.mul(12)) {
           withdrawBPT = baseAmount;
           fee = 0;
           }

        getReward();
        pooled[msg.sender].pooledBalance12 = pooled[msg.sender].pooledBalance12.sub(amount);
        totalPooledBPT12 = totalPooledBPT12.sub(amount);

        bpt.transfer(msg.sender, withdrawBPT);
        emit Withdrawn(msg.sender, amount, fee);
    }

    

   function getReward() public {
       update(msg.sender);
       uint256 reward = pooled[msg.sender].rewards;
       if (reward <= aoRemaining()) {
       pooled[msg.sender].rewards = 0;
       ao.transfer(msg.sender, reward);
       totalClaimed[msg.sender] = totalClaimed[msg.sender].add(reward);
       emit Rewarded(msg.sender, reward);
       }
   }

    
}