// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IBEP20.sol";

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
		IBEP20(autoAddress).transferFrom(account, address(this), amount);
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
		IBEP20(autoAddress).transfer(_msgSender(), amount);
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
		IBEP20(autoAddress).transfer(_msgSender(), amount);
	}

	function addRewards(uint256 duration, uint256 amount) public nonReentrant {
		require(duration > 0, "Duration cannot be 0.");
		require(duration < 1000, "Duration should be in days.");
		_updateDailyRates(); // also updates the rewards available vs. waiting to be claimed
		uint256 today = (block.timestamp / 86400);
		uint256 end = today + duration;
		if (end > rewardEnd)
			rewardEnd = end;
		IBEP20(autoAddress).transferFrom(_msgSender(), address(this), amount);
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