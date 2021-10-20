// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol';

import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol';
import './interfaces/IGoenDistributor.sol';

contract FarmingPool {
    using SafeMath for uint256;
    
    address public immutable owner;
    
    IBEP20 public stakingToken;
    
    IBEP20 public GOEN_TOKEN;
    
    IGoenDistributor public goenDistributor;
    
    //
    mapping(address=>uint256) public firstTimeDepositedUser;
    
    //
    mapping(address=>uint256) public lasttimeUpdateRewardUser;
    
    //
    mapping(address=>uint256) public rewards;
    
    //
    mapping(address => uint256) private balances;
    
    mapping(address => uint256) private goenBalances;

    event Deposit(address user, uint256 amount);
    event Withdraw(address user, uint256 amount);
    event RewardClaim(address user, uint256 amount);
    
    
    modifier updateReward(address user) {
        rewards[user] = earned(user);
        if (firstTimeDepositedUser[user] == 0) {
            firstTimeDepositedUser[user] = block.timestamp;
        }
        lasttimeUpdateRewardUser[user] = block.timestamp;
        _;
    }
    
    constructor() public {
        owner = msg.sender;
    }

    function setGoenToken(address goenAddress) 
    public  
    {
        require(msg.sender == owner, 'Only owner can do this');
        GOEN_TOKEN = IBEP20(goenAddress);
    }

    function setGoenDistributor(address distributorAddress) 
    public  
    {
        require(msg.sender == owner, 'Only owner can do this');
        goenDistributor = IGoenDistributor(distributorAddress);
    }

    function setStakingToken(address goenAddress) 
    public  
    {
        require(msg.sender == owner, 'Only owner can do this');
        stakingToken = IBEP20(goenAddress);
    }
    
    function deposit(uint256 _amount) 
    public 
    updateReward(msg.sender) 
    {
        require(_amount > 0, 'Invalid amount');
        balances[msg.sender] = balances[msg.sender].add(_amount);
        goenBalances[msg.sender] = goenBalanceFromBalance(balances[msg.sender]);
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        emit Deposit(msg.sender, _amount);
    }
    
    function withdrawUnderlying(uint256 _amount) 
    public 
    updateReward(msg.sender) {
        require(_amount > 0, 'Invalid amount');
        require(balances[msg.sender] >= _amount, 'Balance not enough');
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        goenBalances[msg.sender] = goenBalanceFromBalance(balances[msg.sender]);
        
        if (balances[msg.sender] == 0) {
            delete firstTimeDepositedUser[msg.sender];
            delete lasttimeUpdateRewardUser[msg.sender];
        }
        stakingToken.transfer(msg.sender, _amount);
        emit Withdraw(msg.sender, _amount);
    }
    
    function getReward() public updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        require(reward > 0, 'Empty reward');
        rewards[msg.sender] = 0;
        goenDistributor.sendTo(msg.sender, reward);
        emit RewardClaim(msg.sender, reward);
    }
    
    function principalOf(address user) 
    view 
    public 
    returns (uint256) {
        return balances[user];
    }

    function totalDeposit()
    view
    public
    returns (uint256) {
        return stakingToken.balanceOf(address(this));
    }
    
    function goenBalanceFromBalance(uint256 _amount)
    public
    view
    returns (uint256) {
        return GOEN_TOKEN.balanceOf(address(stakingToken))
                .mul(_amount)
                .div(stakingToken.totalSupply());
    }
    
    function goenBalanceOf(address user) public view returns (uint256) {
        return goenBalances[user];
    }
    
    function apr(address user) 
    public 
    view 
    returns (uint256) {
        uint256 enterPoolTimestamp = firstTimeDepositedUser[user];
        if (enterPoolTimestamp == 0) {
            return 50;
        }
        uint256 duration = block.timestamp - enterPoolTimestamp;
        if (duration < 30 days) {
            return 50;
        }
        if (duration < 60 days) {
            return 50 + (duration - (30 days))*100/(30 days);
        }
        return 100;
    }
    
    function earned(address user) 
    public 
    view 
    returns (uint256) {
        uint256 additionalEarned = calculateAdditionalReward(user);
        return rewards[user] + additionalEarned;
    }
    
    function calculateAdditionalReward(address user) public view returns (uint256) {
        uint256 userBalance = goenBalanceOf(user);
        uint256 enterPoolTimestamp = firstTimeDepositedUser[user];
        uint256 lasttimeUpdateReward = lasttimeUpdateRewardUser[user];
        if (enterPoolTimestamp == 0) {
            return 0;
        }
        uint256 duration = block.timestamp - lasttimeUpdateReward;
        uint256 totalDuration = block.timestamp - enterPoolTimestamp;
        uint256 calculatedDuration = lasttimeUpdateReward - enterPoolTimestamp;
        
        if (calculatedDuration < 30 days) {
            uint256 firstPhaseDuration = 30 days - calculatedDuration;
            if (totalDuration < 30 days) {
                return userBalance * (duration)/(2*365*86400);
            } else if (totalDuration < 60 days) {
                uint256 secondPhaseReward = ((totalDuration-30 days)**2 - (30 days)**2)*(userBalance/(30 days*4));
                return (userBalance/(2*365*86400)) * firstPhaseDuration + secondPhaseReward;
            } else {
                uint256 secondPhaseReward = ((60 days)**2 - (30 days)**2)*(userBalance/(30 days*4));
                uint256 thirdPhaseDuration = block.timestamp - (60 days + enterPoolTimestamp);
                return (userBalance/(2*365*86400)) * firstPhaseDuration + secondPhaseReward + userBalance*thirdPhaseDuration/(365*86400);
            }
        }
        
        if (calculatedDuration < 60 days) {
            if (totalDuration < 60 days) {
                return (totalDuration**2 - calculatedDuration**2)*(userBalance/(30 days*4));
            } else {
                uint256 secondPhaseReward = ((60 days)**2 - calculatedDuration**2)*(userBalance/(30 days*4));
                uint256 thirdPhaseDuration = block.timestamp - (60 days + enterPoolTimestamp);
                return secondPhaseReward + userBalance*thirdPhaseDuration/(365*86400);
            }
        }
        
        return userBalance * (block.timestamp - lasttimeUpdateReward)/(365*86400);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

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
        require(c >= a, 'SafeMath: addition overflow');

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
        return sub(a, b, 'SafeMath: subtraction overflow');
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
        return div(a, b, 'SafeMath: division by zero');
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        return mod(a, b, 'SafeMath: modulo by zero');
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

pragma solidity 0.6.12;


interface IGoenDistributor {
    function harvest(uint256 totalValue, uint256 period) external returns (uint256);
    function sendTo(address to, uint256 amount) external;
}