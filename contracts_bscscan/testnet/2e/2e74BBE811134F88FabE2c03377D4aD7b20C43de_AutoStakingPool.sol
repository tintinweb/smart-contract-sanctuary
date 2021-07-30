/**
 *Submitted for verification at BscScan.com on 2021-07-29
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;



// Part: Context

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// Part: IERC20

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

// Part: ReentrancyGuard

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// Part: Ownable

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// File: AutoStakingPool.sol

contract AutoStakingPool is Context, Ownable, ReentrancyGuard {
	// constants
	address public autoAddress;

	// current balance, and when accounts are allowed to unstake
	struct Release {
		uint256 date;
		uint256 amount;
	}
	mapping(address => uint256) private _balance;
	mapping(address => uint256) private _availableBalance;
	mapping(address => Release[]) private _releases;
	uint256 public startDate;

	// rewards for staking
	mapping(address => uint256) private _nextUnpaidDay;
	mapping(address => uint256) private _rewards;

	// day = timespan from day*86400 to (day+1)*86400
	// everything is paid out at end of day
	uint256 private _rewardSupply;
	uint256 private _rewardsYetToBeClaimed; // this variable may ultimately be unnecessary?
	uint256 public rewardEnd;
	uint256 public dailyPayout;

	mapping(uint256 => uint256) private dailyRewardRate; // values in Autowei for better precision
	uint256 private _nextDayToUpdate;
	uint256 private _totalStaked; // total staked across all users in a day

	constructor(address _autoAddress, uint256 _startDate) {
		autoAddress = _autoAddress;
		startDate = _startDate;
	}

	function stake(uint256 amount) public nonReentrant {
		_stake(_msgSender(), amount);
	}

	function stake(address account, uint256 amount) public nonReentrant {
		require(
			_msgSender() == account || _msgSender() == autoAddress,
			"Cannot stake on behalf of another account."
		);
		_stake(account, amount);
	}

	function _stake(address account, uint256 amount) public {
		_updateRewards(account); // also calls _updateDailyRates()
		IERC20(autoAddress).transferFrom(account, address(this), amount);
		_balance[account] += amount;
		_totalStaked += amount;
		uint256 date = (startDate < block.timestamp)
			? block.timestamp - startDate
			: 0;
		uint256 fifth = amount / 5;
		_releases[account].push(Release(date + 604800, fifth));
		_releases[account].push(Release(date + 1209600, fifth));
		_releases[account].push(Release(date + 1814400, fifth));
		_releases[account].push(Release(date + 2419200, fifth));
		_releases[account].push(Release(date + 3024000, amount - 4 * fifth));
	}

	function balanceOf(address account) public view returns (uint256) {
		return _balance[account];
	}

	function availableBalance(address account) public view returns (uint256) {
		uint newlyAvailable = 0;
		Release[] memory arr = _releases[account];
		for (uint i = 0; i < arr.length; i++)
			if (block.timestamp > startDate + arr[i].date)
				newlyAvailable += arr[i].amount;
		return _availableBalance[account] + newlyAvailable;
	}

	function lockedBalance(address account) public view returns (uint256) {
		return balanceOf(account) - availableBalance(account);
	}

	function withdraw(uint256 amount) public nonReentrant {
		_updateRewards(_msgSender()); // also calls _updateDailyRates()
		_processReleases(_msgSender());
		require(_availableBalance[_msgSender()] >= amount, "Not enough AUTO avaialable to withdraw.");
		IERC20(autoAddress).transfer(_msgSender(), amount);
		_availableBalance[_msgSender()] -= amount;
		_balance[_msgSender()] -= amount;
		_totalStaked -= amount;
	}

	function rewards(address account) public view returns (uint256) {
		if (_nextUnpaidDay[account] == 0) // waiting for user's first stake
			return 0;
		uint256 today = block.timestamp / 86400;
		uint256 start = _nextUnpaidDay[account];
		uint256 staked = _balance[account];
		uint256 totalRewards = _rewards[account];
		for (uint256 day = start; day < today; day++)
			totalRewards += staked * _rewardRate(day) / 1e18;
		return totalRewards;
	}

	function withdrawRewards() public nonReentrant {
		_updateRewards(_msgSender());
		uint256 amount = _rewards[_msgSender()];
		require(amount > 0, "Nothing to withdraw.");
		// This should never fail unless I've done something wrong
		require(amount <= _rewardsYetToBeClaimed, "Insufficient funds in contract.");
		_rewardsYetToBeClaimed -= amount;
		_rewards[_msgSender()] = 0;
		IERC20(autoAddress).transfer(_msgSender(), amount);
	}

	function addRewards(uint256 duration, uint256 amount) public nonReentrant {
		require(duration > 0, "Duration cannot be 0.");
		require(duration < 1000, "Duration should be in days.");
		_updateDailyRates(); // also updates the rewards available vs. waiting to be claimed
		uint256 today = (block.timestamp / 86400);
		uint256 end = today + duration;
		if (end > rewardEnd)
			rewardEnd = end;
		IERC20(autoAddress).transferFrom(_msgSender(), address(this), amount);
		_rewardSupply += amount;
		dailyPayout = _rewardSupply / (rewardEnd - today);
		if (_nextDayToUpdate == 0)
			_nextDayToUpdate = today;
	}

	function showReleases(address account) public view returns (Release[] memory) {
		return _releases[account];
	}

	function delayStartDate(uint256 newDate) public onlyOwner {
		require(startDate < block.timestamp + 604800, "Start date is too far passed to update.");
		require(newDate > startDate, "Start date must increase.");
		startDate = newDate;
	}

	// make this public to somewhat reduce user gas costs?
	function _updateDailyRates() private {
		if (rewardEnd <= _nextDayToUpdate)
			return;
		uint256 today = block.timestamp / 86400;
		// add this to somewhat reduce gas costs on already-updated withdrawls?
		// if (today < nextDayToUpdate)
		// 	return;
		uint256 day = _nextDayToUpdate;
		for (; day < today; day++)
			dailyRewardRate[day] = _rewardRate(day);
		uint256 end = day;
		if (end > rewardEnd)
			end = rewardEnd;
		uint256 totalRewarded = dailyPayout * (end - _nextDayToUpdate);
		_nextDayToUpdate = day;
		_rewardSupply -= totalRewarded;
		_rewardsYetToBeClaimed += totalRewarded;
	}

	// TODO make sure this is called before every balance change
	function _updateRewards(address account) private {
		_updateDailyRates();
		_rewards[account] = rewards(account);
		_nextUnpaidDay[account] = block.timestamp / 86400;
	}

	function _processReleases(address account) private {
		uint removed = 0;
		Release[] storage arr = _releases[account];
		for (uint i = 0; i < arr.length; i++) {
			if (removed > 0)
				arr[i - removed] = arr[i];
			if (block.timestamp > startDate + arr[i].date) {
				_availableBalance[account] += arr[i].amount;
				removed += 1;
			}
		}
		for (uint i = 0; i < removed; i++)
			arr.pop();
		_releases[account] = arr;
	}

	function _rewardRate(uint256 day) private view returns (uint256) {
		if (day < _nextDayToUpdate)
			return dailyRewardRate[day];
		if (day >= rewardEnd || _totalStaked == 0)
			return 0;
		else
			return (dailyPayout * 1e18) / _totalStaked;
	}
}