// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;


// 
/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// 
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// 
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

// 
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

// 
contract CentaurLiquidityMining is Ownable {

	using SafeMath for uint;

	// Events
	event Deposit(uint256 _timestmap, address indexed _address, uint256 indexed _pid, uint256 _amount);
	event Withdraw(uint256 _timestamp, address indexed _address, uint256 indexed _pid, uint256 _amount);
	event EmergencyWithdraw(uint256 _timestamp, address indexed _address, uint256 indexed _pid, uint256 _amount);

	// CNTR Token Contract & Funding Address
	IERC20 public constant CNTR = IERC20(0x03042482d64577A7bdb282260e2eA4c8a89C064B);
	address public fundingAddress = 0xf6B13425d1F7D920E3F6EF43F7c5DdbC2E59AbF6;

	struct LPInfo {
		// Address of LP token contract
		IERC20 lpToken;

		// LP reward per block
		uint256 rewardPerBlock;

		// Last reward block
		uint256 lastRewardBlock;

		// Accumulated reward per share (times 1e12 to minimize rounding errors)
		uint256 accRewardPerShare;
	}

	struct Staker {
		// Total Amount Staked
		uint256 amountStaked;

		// Reward Debt (pending reward = (staker.amountStaked * pool.accRewardPerShare) - staker.rewardDebt)
		uint256 rewardDebt;
	}

	// Liquidity Pools
	LPInfo[] public liquidityPools;

	// Info of each user that stakes LP tokens.
	// poolId => address => staker
    mapping (uint256 => mapping (address => Staker)) public stakers;

    // Starting block for mining
    uint256 public startBlock;

    // End block for mining (Will be ongoing if unset/0)
    uint256 public endBlock;

	/**
     * @dev Constructor
     */

	constructor(uint256 _startBlock) public {
		startBlock = _startBlock;
	}

	/**
     * @dev Contract Modifiers
     */

	function updateFundingAddress(address _address) public onlyOwner {
		fundingAddress = _address;
	}

	function updateStartBlock(uint256 _startBlock) public onlyOwner {
		require(startBlock > block.number, "Mining has started, unable to update startBlock");
		require(_startBlock > block.number, "startBlock has to be in the future");

        for (uint256 i = 0; i < liquidityPools.length; i++) {
            LPInfo storage pool = liquidityPools[i];
            pool.lastRewardBlock = _startBlock;
        }

		startBlock = _startBlock;
	}

	function updateEndBlock(uint256 _endBlock) public onlyOwner {
		require(endBlock > block.number || endBlock == 0, "Mining has ended, unable to update endBlock");
		require(_endBlock > block.number, "endBlock has to be in the future");

		endBlock = _endBlock;
	}

	/**
     * @dev Liquidity Pool functions
     */

    // Add liquidity pool
    function addLiquidityPool(IERC20 _lpToken, uint256 _rewardPerBlock) public onlyOwner {

    	uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;

    	liquidityPools.push(LPInfo({
            lpToken: _lpToken,
            rewardPerBlock: _rewardPerBlock,
            lastRewardBlock: lastRewardBlock,
            accRewardPerShare: 0
        }));
    }

    // Update LP rewardPerBlock
    function updateRewardPerBlock(uint256 _pid, uint256 _rewardPerBlock) public onlyOwner {
        updatePoolRewards(_pid);

    	liquidityPools[_pid].rewardPerBlock = _rewardPerBlock;
    }

    // Update pool rewards variables
    function updatePoolRewards(uint256 _pid) public {
    	LPInfo storage pool = liquidityPools[_pid];

    	if (block.number <= pool.lastRewardBlock) {
            return;
        }

        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 blockElapsed = 0;
        if (block.number < endBlock || endBlock == 0) {
            blockElapsed = (block.number).sub(pool.lastRewardBlock);
        } else if (endBlock >= pool.lastRewardBlock) {
            blockElapsed = endBlock.sub(pool.lastRewardBlock);
        }

        uint256 totalReward = blockElapsed.mul(pool.rewardPerBlock);
        pool.accRewardPerShare = pool.accRewardPerShare.add(totalReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

	/**
     * @dev Stake functions
     */

	// Deposit LP tokens into the liquidity pool
	function deposit(uint256 _pid, uint256 _amount) public {
        require(block.number < endBlock || endBlock == 0);

		LPInfo storage pool = liquidityPools[_pid];
        Staker storage user = stakers[_pid][msg.sender];

        updatePoolRewards(_pid);

        // Issue accrued rewards to user
        if (user.amountStaked > 0) {
            uint256 pending = user.amountStaked.mul(pool.accRewardPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
            	_issueRewards(msg.sender, pending);
            }
        }

        // Process deposit
        if(_amount > 0) {
            require(pool.lpToken.transferFrom(msg.sender, address(this), _amount));
            user.amountStaked = user.amountStaked.add(_amount);
        }

        // Update user reward debt
        user.rewardDebt = user.amountStaked.mul(pool.accRewardPerShare).div(1e12);

        emit Deposit(block.timestamp, msg.sender, _pid, _amount);
	}

	// Withdraw LP tokens from liquidity pool
	function withdraw(uint256 _pid, uint256 _amount) public {
		LPInfo storage pool = liquidityPools[_pid];
        Staker storage user = stakers[_pid][msg.sender];

        require(user.amountStaked >= _amount, "Amount to withdraw more than amount staked");

        updatePoolRewards(_pid);

        // Issue accrued rewards to user
        if (user.amountStaked > 0) {
            uint256 pending = user.amountStaked.mul(pool.accRewardPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
            	_issueRewards(msg.sender, pending);
            }
        }

        // Process withdraw
        if(_amount > 0) {
            user.amountStaked = user.amountStaked.sub(_amount);
            require(pool.lpToken.transfer(msg.sender, _amount));
        }

        // Update user reward debt
        user.rewardDebt = user.amountStaked.mul(pool.accRewardPerShare).div(1e12);

        emit Withdraw(block.timestamp, msg.sender, _pid, _amount);
	}

	// Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        LPInfo storage pool = liquidityPools[_pid];
        Staker storage user = stakers[_pid][msg.sender];

        uint256 amount = user.amountStaked;
        user.amountStaked = 0;
        user.rewardDebt = 0;

        require(pool.lpToken.transfer(msg.sender, amount));

        emit EmergencyWithdraw(block.timestamp, msg.sender, _pid, amount);
    }

    // Function to issue rewards from funding address to user
	function _issueRewards(address _to, uint256 _amount) internal {
		// For transparency, rewards are transfered from funding address to contract then to user

    	// Transfer rewards from funding address to contract
        require(CNTR.transferFrom(fundingAddress, address(this), _amount));

        // Transfer rewards from contract to user
        require(CNTR.transfer(_to, _amount));
	}

	// View function to see pending rewards on frontend.
    function pendingRewards(uint256 _pid, address _user) external view returns (uint256) {
        LPInfo storage pool = liquidityPools[_pid];
        Staker storage user = stakers[_pid][_user];

        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {

            uint256 blockElapsed = 0;
            if (block.number < endBlock || endBlock == 0) {
                blockElapsed = (block.number).sub(pool.lastRewardBlock);
            } else if (endBlock >= pool.lastRewardBlock) {
                blockElapsed = endBlock.sub(pool.lastRewardBlock);
            }

            uint256 totalReward = blockElapsed.mul(pool.rewardPerBlock);
            accRewardPerShare = accRewardPerShare.add(totalReward.mul(1e12).div(lpSupply));
        }

        return user.amountStaked.mul(accRewardPerShare).div(1e12).sub(user.rewardDebt);
    }
}