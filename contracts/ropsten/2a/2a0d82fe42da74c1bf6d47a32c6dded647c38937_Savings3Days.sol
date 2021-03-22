/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.1;

/**
 * Library from OpenZeppelin
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

/**
 * Library from OpenZeppelin
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

/**
 * @dev Token Wraper to use in this contract
*/
contract TokenWraper {
    
    using SafeMath for uint256;
    
    IERC20 public _token = IERC20(0x48da1aBB2ED54b8Bf63716E659aE613f6Ed50913);

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns(uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns(uint256) {
        return _balances[account];
    }

    function _save(uint256 amount) internal {
        _token.transferFrom(msg.sender, address(this), amount);
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
    }

    function _withdraw(uint256 amount) internal {
        _token.transfer(msg.sender, amount);
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
    }

    function _removeReward(address founder, uint256 amount) internal {
        _token.transfer(msg.sender, amount);
        _totalSupply = _totalSupply.sub(amount);
        _balances[founder] = _balances[founder].sub(amount);
    }
}

contract Savings3Days is TokenWraper {
    
    using SafeMath for uint256;
    
    address public founder;
    uint256 public timeLock = 3 days; // return unix epoch
    uint256 public yearly = 365 days;
    uint256 public percentRewardYearly; // % yearly
    uint256 public limitAmountSaved;
    mapping(address => uint256) private savedAmount;
    mapping(address => uint256) private savedTimestamp;
    mapping(address => uint256) public claimRewardAmount;
    mapping(address => uint256) public lockedUntil;
    
    IERC20 public token = IERC20(0x48da1aBB2ED54b8Bf63716E659aE613f6Ed50913);
    
    event Saved(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    
    modifier isFounder() {
        require(msg.sender == founder);
        _;
    }
    
    constructor(uint256 _percentRewardYearly, uint256 _limitAmountSaved) {
        percentRewardYearly = _percentRewardYearly;
        limitAmountSaved = _limitAmountSaved.mul(1000000000000000000);
        founder = msg.sender;
    }
    
    function setNewFounder(address newAddress) public isFounder {
        founder = newAddress;
    }

    function setLimitAmountSaved(uint256 _amount) public isFounder {
        limitAmountSaved = _amount;
    }
    
    function setPercentRewardYearly(uint256 _percent) public isFounder {
        percentRewardYearly = _percent;
    }

    function changeOwnership(address _account) public {
        founder = _account;
    }
    
    function rewardBalance() public view returns(uint256) {
        return balanceOf(founder);
    }
    
    function _rewardEarnedPerSecond(address account) public view returns(uint256) {
        if(account == founder) {
            return 0;
        }
        uint256 _savedAmount = savedAmount[account];
        uint256 _expectedRewardYearly = _savedAmount.mul(percentRewardYearly);
        _expectedRewardYearly = _expectedRewardYearly.div(100);
        uint256 _reward = _expectedRewardYearly.div(yearly);
        return _reward;
    }
    
    function rewardEarned(address account) public view returns(uint256) {
        uint256 _currentTime = block.timestamp;
        uint256 _rangeTime = _currentTime.sub(savedTimestamp[account]);
        uint256 _rewardEarned;
        if(_rangeTime >= timeLock) {
            _rewardEarned = _rewardEarnedPerSecond(account).mul(timeLock);
        }else {
            _rewardEarned = _rewardEarnedPerSecond(account).mul(_rangeTime);
        }
        if(claimRewardAmount[account] != 0) {
            _rewardEarned = _rewardEarned.sub(claimRewardAmount[account]);
        }
        return _rewardEarned;
    }
    
    function save(uint256 _amount) public {
        uint256 _userTotalSupply = totalSupply().sub(rewardBalance());
        require(_userTotalSupply.add(_amount) <= limitAmountSaved, "Amount saved by all users, have reach it limits");
        require(_amount > 0, "Cannot save 0");
        super._save(_amount);
        uint256 _currentTime = block.timestamp;
        savedAmount[msg.sender] = _amount;
        claimRewardAmount[msg.sender] = 0;
        savedTimestamp[msg.sender] = _currentTime;
        lockedUntil[msg.sender] = _currentTime.add(timeLock);
        emit Saved(msg.sender, _amount);
    }
    
    function withdraw(uint256 _amount) public {
        require(msg.sender != founder, "Founder not allowed to withdraw");
        require(lockedUntil[msg.sender] > 0, "No user found.");
        require(lockedUntil[msg.sender] < block.timestamp, "Not unlocked yet.");
        require(_amount > 0, "Cannot withdraw 0");
        super._withdraw(_amount);
        emit Withdrawn(msg.sender, _amount);
    }
    
    function getReward() public {
        uint256 _rewardEarned = rewardEarned(msg.sender);
        require(_rewardEarned > 0, "Doesn't have a reward.");
        require(rewardBalance() > _rewardEarned, "Reward balance not enough.");
        super._removeReward(founder, _rewardEarned);
        claimRewardAmount[msg.sender] = claimRewardAmount[msg.sender].add(_rewardEarned);
        if(lockedUntil[msg.sender] < block.timestamp) {
            savedAmount[msg.sender] = 0;
            claimRewardAmount[msg.sender] = 0;
        }
        emit RewardPaid(msg.sender, _rewardEarned);
    }
}