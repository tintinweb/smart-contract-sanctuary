// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;


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
// The MIT License (MIT)
// Copyright (c) 2016-2020 zOS Global Limited
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
contract CentaurStakingV1 is Ownable {

	using SafeMath for uint;

	// Events
	event Deposit(uint256 _timestmap, address indexed _address, uint256 _amount);
	event Withdraw(uint256 _timestamp, address indexed _address, uint256 _amount);

	// CNTR Token Contract & Funding Address
	IERC20 public tokenContract = IERC20(0x03042482d64577A7bdb282260e2eA4c8a89C064B);
	address public fundingAddress = 0x6359EAdBB84C8f7683E26F392A1573Ab6a37B4b4;

	// Current rewardPercentage
	uint256 public currentRewardPercentage;
	
	// Initial & Final Reward Constants (100% => 10000)
	uint256 constant initialRewardPercentage = 1000; // 10%
	uint256 constant finalRewardPercetage = 500; // 5%

	// Rewards % decrement when TVL hits certain volume (100% => 10000)
	uint256 constant rewardDecrementCycle = 10000000 * 1 ether; // Decrement when TVL hits certain volume
	uint256 constant percentageDecrementPerCycle = 50; // 0.5%

	// Stake Lock Constants
	uint256 public constant stakeLockDuration = 30 days;

	// Stake tracking
	uint256 public stakeStartTimestamp;
	uint256 public stakeEndTimestamp;

	mapping(address => StakeInfo[]) stakeHolders;

	struct StakeInfo {
		uint256 startTimestamp;
		uint256 amountStaked;
		uint256 rewardPercentage;
		bool withdrawn;
	}

	// Total Value Locked (TVL) Tracking
	uint256 public totalValueLocked;

	/**
     * @dev Constructor
     */

	constructor() public {
		currentRewardPercentage = initialRewardPercentage;
		stakeStartTimestamp = block.timestamp + 7 days; // Stake event will start 7 days from deployment
		stakeEndTimestamp = stakeStartTimestamp + 30 days; // Stake event is going to run for 30 days
	}

	/**
     * @dev Contract Modifiers
     */

	function updateFundingAddress(address _address) public onlyOwner {
		require(block.timestamp < stakeStartTimestamp);

		fundingAddress = _address;
	}

	function changeStartTimestamp(uint256 _timestamp) public onlyOwner {
		require(block.timestamp < stakeStartTimestamp);

		stakeStartTimestamp = _timestamp;
	}

	function changeEndTimestamp(uint256 _timestamp) public onlyOwner {
		require(block.timestamp < stakeEndTimestamp);
		require(_timestamp > stakeStartTimestamp);

		stakeEndTimestamp = _timestamp;
	}

	/**
     * @dev Stake functions
     */

    function deposit(uint256 _amount) public {
    	require(block.timestamp > stakeStartTimestamp && block.timestamp < stakeEndTimestamp, "Contract is not accepting deposits at the moment");
    	require(_amount > 0, "Amount has to be more than 0");
    	require(stakeHolders[msg.sender].length < 1000, "Prevent Denial of Service");

    	// Transfers amount to contract
    	require(tokenContract.transferFrom(msg.sender, address(this), _amount));
		emit Deposit(block.timestamp, msg.sender, _amount);

    	uint256 stakeAmount = _amount;
		uint256 stakeRewards = 0;

    	// Check if deposit exceeds rewardDecrementCycle
		while(stakeAmount >= amountToNextDecrement()) {

			// Variable cache
			uint256 amountToNextDecrement = amountToNextDecrement();

			// Add new stake
	    	StakeInfo memory newStake;
	    	newStake.startTimestamp = block.timestamp;
	    	newStake.amountStaked = amountToNextDecrement;
	    	newStake.rewardPercentage = currentRewardPercentage;

	    	stakeHolders[msg.sender].push(newStake);

	    	stakeAmount = stakeAmount.sub(amountToNextDecrement);
	    	stakeRewards = stakeRewards.add(amountToNextDecrement.mul(currentRewardPercentage).div(10000));

			totalValueLocked = totalValueLocked.add(amountToNextDecrement);

	    	// Reduce reward percentage if not at final
    		if (currentRewardPercentage > finalRewardPercetage) {
    			currentRewardPercentage = currentRewardPercentage.sub(percentageDecrementPerCycle);
    		}
		}

		// Deposit leftover stake
		if (stakeAmount > 0) {
			// Add new stake
	    	StakeInfo memory newStake;
	    	newStake.startTimestamp = block.timestamp;
	    	newStake.amountStaked = stakeAmount;
	    	newStake.rewardPercentage = currentRewardPercentage;

	    	stakeHolders[msg.sender].push(newStake);

	    	stakeRewards = stakeRewards.add(stakeAmount.mul(currentRewardPercentage).div(10000));

	    	totalValueLocked = totalValueLocked.add(stakeAmount);
		}

		// Transfer stake rewards from funding address to contract
    	require(tokenContract.transferFrom(fundingAddress, address(this), stakeRewards));

    	// Transfer total from contract to msg.sender
    	require(tokenContract.transfer(msg.sender, stakeRewards));

    }

    function withdraw() public {
    	_withdraw(msg.sender);
    }

    function withdrawAddress(address _address) public onlyOwner {
    	_withdraw(_address);
    }

    function _withdraw(address _address) internal {
    	uint256 withdrawAmount = 0;

    	for(uint256 i = 0; i < stakeHolders[_address].length; i++) {
    		StakeInfo storage stake = stakeHolders[_address][i];
    		if (!stake.withdrawn && block.timestamp >= stake.startTimestamp + stakeLockDuration) {
	    		withdrawAmount = withdrawAmount.add(stake.amountStaked);
	    		stake.withdrawn = true;
    		}
    	}

    	require(withdrawAmount > 0, "No funds available for withdrawal");

    	totalValueLocked = totalValueLocked.sub(withdrawAmount);

    	require(tokenContract.transfer(_address, withdrawAmount));
    	emit Withdraw(block.timestamp, _address, withdrawAmount);
    }

    function amountToNextDecrement() public view returns (uint256) {
    	return rewardDecrementCycle.sub(totalValueLocked.mod(rewardDecrementCycle));
    }

    function amountAvailableForWithdrawal(address _address) public view returns (uint256) {
    	uint256 withdrawAmount = 0;

    	for(uint256 i = 0; i < stakeHolders[_address].length; i++) {
    		StakeInfo storage stake = stakeHolders[_address][i];
    		if (!stake.withdrawn && block.timestamp >= stake.startTimestamp + stakeLockDuration) {
	    		withdrawAmount = withdrawAmount.add(stake.amountStaked);
    		}
    	}

    	return withdrawAmount;
    }

    function getStakes(address _address) public view returns(StakeInfo[] memory) {
    	StakeInfo[] memory stakes = new StakeInfo[](stakeHolders[_address].length);

    	for (uint256 i = 0; i < stakeHolders[_address].length; i++) {
    		StakeInfo storage stake = stakeHolders[_address][i];
    		stakes[i] = stake;
    	}

    	return stakes;
    }
}