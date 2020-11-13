// LTSSC
// iCORE liquidity token staking smart contract (farming)

pragma solidity ^0.7.0;

library Math {
    
	function max(uint256 a, uint256 b) internal pure returns (uint256) {
		return a >= b ? a : b;
	}
	function min(uint256 a, uint256 b) internal pure returns (uint256) {
		return a < b ? a : b;
	}
	function average(uint256 a, uint256 b) internal pure returns (uint256) {
		return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
	}
}
library SafeMath {
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a, "SafeMath: addition overflow");

		return c;
	}
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		return sub(a, b, "SafeMath: subtraction overflow");
	}
	function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b <= a, errorMessage);
		uint256 c = a - b;

		return c;
	}
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}

		uint256 c = a * b;
		require(c / a == b, "SafeMath: multiplication overflow");

		return c;
	}
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		return div(a, b, "SafeMath: division by zero");
	}
	function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b > 0, errorMessage);
		uint256 c = a / b;

		return c;
	}
	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		return mod(a, b, "SafeMath: modulo by zero");
	}
	function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b != 0, errorMessage);
		return a % b;
	}
}
interface IERC20 {
	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IStakedRewardsPool {
	function balanceOf(address account) external view returns (uint256);

	function earned(address account) external view returns (uint256);

	function rewardsToken() external view returns (IERC20);

	function stakingToken() external view returns (IERC20);

	function stakingTokenDecimals() external view returns (uint8);

	function totalSupply() external view returns (uint256);
	function exit() external;

	function getReward() external;

	function getRewardExact(uint256 amount) external;

	function pause() external;

	function recoverUnsupportedERC20(
		IERC20 token,
		address to,
		uint256 amount
	) external;

	function stake(uint256 amount) external;

	function unpause() external;

	function updateReward() external;

	function updateRewardFor(address account) external;

	function withdraw(uint256 amount) external;
	event RewardPaid(address indexed account, uint256 amount);
	event Staked(address indexed account, uint256 amount);
	event Withdrawn(address indexed account, uint256 amount);
	event Recovered(IERC20 token, address indexed to, uint256 amount);
}

interface IStakedRewardsPoolTimedRate is IStakedRewardsPool {
	function accruedRewardPerToken() external view returns (uint256);

	function hasEnded() external view returns (bool);

	function hasStarted() external view returns (bool);

	function lastTimeRewardApplicable() external view returns (uint256);

	function periodDuration() external view returns (uint256);

	function periodEndTime() external view returns (uint256);

	function periodStartTime() external view returns (uint256);

	function rewardRate() external view returns (uint256);

	function timeRemainingInPeriod() external view returns (uint256);
	function addToRewardsAllocation(uint256 amount) external;

	function setNewPeriod(uint256 startTime, uint256 endTime) external;
	event RewardAdded(uint256 amount);
	event NewPeriodSet(uint256 startTIme, uint256 endTime);
}
abstract contract Context {
	function _msgSender() internal view virtual returns (address payable) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns (bytes memory) {
		this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
		return msg.data;
	}
}
contract Ownable is Context {
	address private _owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	constructor () {
		address msgSender = _msgSender();
		_owner = msgSender;
		emit OwnershipTransferred(address(0), msgSender);
	}
	function owner() public view returns (address) {
		return _owner;
	}
	modifier onlyOwner() {
		require(_owner == _msgSender(), "Ownable: caller is not the owner");
		_;
	}
	function renounceOwnership() public virtual onlyOwner {
		emit OwnershipTransferred(_owner, address(0));
		_owner = address(0);
	}
	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}
}
contract Pausable is Context {
	event Paused(address account);
	event Unpaused(address account);

	bool private _paused;
	constructor () {
		_paused = false;
	}
	function paused() public view returns (bool) {
		return _paused;
	}
	modifier whenNotPaused() {
		require(!_paused, "Pausable: paused");
		_;
	}
	modifier whenPaused() {
		require(_paused, "Pausable: not paused");
		_;
	}
	function _pause() internal virtual whenNotPaused {
		_paused = true;
		emit Paused(_msgSender());
	}
	function _unpause() internal virtual whenPaused {
		_paused = false;
		emit Unpaused(_msgSender());
	}
}
contract ReentrancyGuard {
	// transaction's gas, it is best to keep them low in cases like this one, to
	uint256 private constant _NOT_ENTERED = 1;
	uint256 private constant _ENTERED = 2;

	uint256 private _status;

	constructor () {
		_status = _NOT_ENTERED;
	}
	modifier nonReentrant() {
		require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
		_status = _ENTERED;

		_;
		_status = _NOT_ENTERED;
	}
}
library Address {
	function isContract(address account) internal view returns (bool) {
		bytes32 codehash;
		bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
		assembly { codehash := extcodehash(account) }
		return (codehash != accountHash && codehash != 0x0);
	}
	function sendValue(address payable recipient, uint256 amount) internal {
		require(address(this).balance >= amount, "Address: insufficient balance");
		(bool success, ) = recipient.call{ value: amount }("");
		require(success, "Address: unable to send value, recipient may have reverted");
	}
	function functionCall(address target, bytes memory data) internal returns (bytes memory) {
	  return functionCall(target, data, "Address: low-level call failed");
	}
	function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
		return _functionCallWithValue(target, data, 0, errorMessage);
	}
	function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
		return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
	}
	function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
		require(address(this).balance >= value, "Address: insufficient balance for call");
		return _functionCallWithValue(target, data, value, errorMessage);
	}

	function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
		require(isContract(target), "Address: call to non-contract");
		(bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
		if (success) {
			return returndata;
		} else {
			if (returndata.length > 0) {

				assembly {
					let returndata_size := mload(returndata)
					revert(add(32, returndata), returndata_size)
				}
			} else {
				revert(errorMessage);
			}
		}
	}
}
library SafeERC20 {
	using SafeMath for uint256;
	using Address for address;

	function safeTransfer(IERC20 token, address to, uint256 value) internal {
		_callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
	}

	function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
		_callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
	}
	function safeApprove(IERC20 token, address spender, uint256 value) internal {
		require((value == 0) || (token.allowance(address(this), spender) == 0),
			"SafeERC20: approve from non-zero to non-zero allowance"
		);
		_callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
	}

	function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
		uint256 newAllowance = token.allowance(address(this), spender).add(value);
		_callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
	}

	function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
		uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
		_callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
	}
	function _callOptionalReturn(IERC20 token, bytes memory data) private {

		bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
		if (returndata.length > 0) { // Return data is optional
			require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
		}
	}
}

abstract contract StakedRewardsPool is
	Context,
	ReentrancyGuard,
	Ownable,
	Pausable,
	IStakedRewardsPool
{
	using SafeERC20 for IERC20;
	using SafeMath for uint256;
	mapping(address => uint256) internal _rewards;
	uint8 private _stakingTokenDecimals;
	IERC20 private _rewardsToken;
	IERC20 private _stakingToken;
	uint256 private _stakingTokenBase;
	mapping(address => uint256) private _balances;
	uint256 private _totalSupply;
	constructor(
		IERC20 rewardsToken,
		IERC20 stakingToken,
		uint8 stakingTokenDecimals
	) Ownable() {
		require(
			stakingTokenDecimals < 77,
			"StakedRewardsPool: staking token has far too many decimals"
		);

		_rewardsToken = rewardsToken;

		_stakingToken = stakingToken;
		_stakingTokenDecimals = stakingTokenDecimals;
		_stakingTokenBase = 10**stakingTokenDecimals;
	}
	function balanceOf(address account) public view override returns (uint256) {
		return _balances[account];
	}

	function earned(address account)
		public
		view
		virtual
		override
		returns (uint256);

	function rewardsToken() public view override returns (IERC20) {
		return _rewardsToken;
	}

	function stakingToken() public view override returns (IERC20) {
		return _stakingToken;
	}

	function stakingTokenDecimals() public view override returns (uint8) {
		return _stakingTokenDecimals;
	}

	function totalSupply() public view override returns (uint256) {
		return _totalSupply;
	}
	function exit() public override nonReentrant {
		_exit();
	}

	function getReward() public override nonReentrant {
		_getReward();
	}

	function getRewardExact(uint256 amount) public override nonReentrant {
		_getRewardExact(amount);
	}

	function pause() public override onlyOwner {
		_pause();
	}
	function recoverUnsupportedERC20(
		IERC20 token,
		address to,
		uint256 amount
	) public override onlyOwner {
		_recoverUnsupportedERC20(token, to, amount);
	}

	function stake(uint256 amount) public override nonReentrant whenNotPaused {
		_stakeFrom(_msgSender(), amount);
	}

	function unpause() public override onlyOwner {
		_unpause();
	}

	function updateReward() public override nonReentrant {
		_updateRewardFor(_msgSender());
	}

	function updateRewardFor(address account) public override nonReentrant {
		_updateRewardFor(account);
	}

	function withdraw(uint256 amount) public override nonReentrant {
		_withdraw(amount);
	}
	function _getStakingTokenBase() internal view returns (uint256) {
		return _stakingTokenBase;
	}
	function _exit() internal virtual {
		_withdraw(_balances[_msgSender()]);
		_getReward();
	}

	function _getReward() internal virtual {
		_updateRewardFor(_msgSender());
		uint256 reward = _rewards[_msgSender()];
		if (reward > 0) {
			_rewards[_msgSender()] = 0;
			_rewardsToken.safeTransfer(_msgSender(), reward);
			emit RewardPaid(_msgSender(), reward);
		}
	}

	function _getRewardExact(uint256 amount) internal virtual {
		_updateRewardFor(_msgSender());
		uint256 reward = _rewards[_msgSender()];
		require(
			amount <= reward,
			"StakedRewardsPool: can not redeem more rewards than you have earned"
		);
		_rewards[_msgSender()] = reward.sub(amount);
		_rewardsToken.safeTransfer(_msgSender(), amount);
		emit RewardPaid(_msgSender(), amount);
	}

	function _recoverUnsupportedERC20(
		IERC20 token,
		address to,
		uint256 amount
	) internal virtual {
		require(
			token != _stakingToken,
			"StakedRewardsPool: cannot withdraw the staking token"
		);
		require(
			token != _rewardsToken,
			"StakedRewardsPool: cannot withdraw the rewards token"
		);
		token.safeTransfer(to, amount);
		emit Recovered(token, to, amount);
	}

	function _stakeFrom(address account, uint256 amount) internal virtual {
		require(
			account != address(0),
			"StakedRewardsPool: cannot stake from the zero address"
		);
		require(amount > 0, "StakedRewardsPool: cannot stake zero");
		_updateRewardFor(account);
		_totalSupply = _totalSupply.add(amount);
		_balances[account] = _balances[account].add(amount);
		_stakingToken.safeTransferFrom(account, address(this), amount);
		emit Staked(account, amount);
	}

	function _updateRewardFor(address account) internal virtual;

	function _withdraw(uint256 amount) internal virtual {
		require(amount > 0, "StakedRewardsPool: cannot withdraw zero");
		_updateRewardFor(_msgSender());
		_totalSupply = _totalSupply.sub(amount);
		_balances[_msgSender()] = _balances[_msgSender()].sub(amount);
		_stakingToken.safeTransfer(_msgSender(), amount);
		emit Withdrawn(_msgSender(), amount);
	}
}
contract StakedRewardsPoolTimedRate is
	StakedRewardsPool,
	IStakedRewardsPoolTimedRate
{
	using SafeMath for uint256;
	uint256 private _accruedRewardPerToken;
	mapping(address => uint256) private _accruedRewardPerTokenPaid;
	uint256 private _lastUpdateTime;
	uint256 private _periodEndTime;
	uint256 private _periodStartTime;
	uint256 private _rewardRate;
	modifier whenStarted {
		require(
			hasStarted(),
			"StakedRewardsPoolTimedRate: current rewards distribution period has not yet begun"
		);
		_;
	}
	constructor(
		IERC20 rewardsToken,
		IERC20 stakingToken,
		uint8 stakingTokenDecimals,
		uint256 periodStartTime,
		uint256 periodEndTime
	) StakedRewardsPool(rewardsToken, stakingToken, stakingTokenDecimals) {
		_periodStartTime = periodStartTime;
		_periodEndTime = periodEndTime;
	}
	function accruedRewardPerToken() public view override returns (uint256) {
		uint256 totalSupply = totalSupply();
		if (totalSupply == 0) {
			return _accruedRewardPerToken;
		}

		uint256 lastUpdateTime = _lastUpdateTime;
		uint256 lastTimeApplicable = lastTimeRewardApplicable();
		if (_periodStartTime > lastUpdateTime) {
			if (_periodStartTime > lastTimeApplicable) {
				return _accruedRewardPerToken;
			}
			lastUpdateTime = _periodStartTime;
		}

		uint256 dt = lastTimeApplicable.sub(lastUpdateTime);
		if (dt == 0) {
			return _accruedRewardPerToken;
		}

		uint256 accruedReward = _rewardRate.mul(dt);

		return
			_accruedRewardPerToken.add(
				accruedReward.mul(_getStakingTokenBase()).div(totalSupply)
			);
	}

	function earned(address account)
		public
		view
		override(IStakedRewardsPool, StakedRewardsPool)
		returns (uint256)
	{
		return
			balanceOf(account)
				.mul(accruedRewardPerToken().sub(_accruedRewardPerTokenPaid[account]))
				.div(_getStakingTokenBase())
				.add(_rewards[account]);
	}

	function hasStarted() public view override returns (bool) {
		return block.timestamp >= _periodStartTime;
	}

	function hasEnded() public view override returns (bool) {
		return block.timestamp >= _periodEndTime;
	}

	function lastTimeRewardApplicable() public view override returns (uint256) {
		if (!hasStarted()) {
			return _lastUpdateTime;
		}
		return Math.min(block.timestamp, _periodEndTime);
	}

	function periodDuration() public view override returns (uint256) {
		return _periodEndTime.sub(_periodStartTime);
	}

	function periodEndTime() public view override returns (uint256) {
		return _periodEndTime;
	}

	function periodStartTime() public view override returns (uint256) {
		return _periodStartTime;
	}

	function rewardRate() public view override returns (uint256) {
		return _rewardRate;
	}

	function timeRemainingInPeriod()
		public
		view
		override
		whenStarted
		returns (uint256)
	{
		if (hasEnded()) {
			return 0;
		}
		return _periodEndTime.sub(block.timestamp);
	}
	function addToRewardsAllocation(uint256 amount)
		public
		override
		nonReentrant
		onlyOwner
	{
		_addToRewardsAllocation(amount);
	}

	function setNewPeriod(uint256 startTime, uint256 endTime)
		public
		override
		onlyOwner
	{
		require(
			!hasStarted() || hasEnded(),
			"StakedRewardsPoolTimedRate: cannot change an ongoing staking period"
		);
		require(
			endTime > startTime,
			"StakedRewardsPoolTimedRate: endTime must be greater than startTime"
		);
		require(
			startTime > block.timestamp,
			"StakedRewardsPoolTimedRate: startTime must be greater than the current block time"
		);
		_updateAccrual();

		if (hasEnded()) {
			_rewardRate = 0;
		} else {
			uint256 totalReward = _rewardRate.mul(periodDuration());
			_rewardRate = totalReward.div(endTime.sub(startTime));
		}

		_periodStartTime = startTime;
		_periodEndTime = endTime;

		emit NewPeriodSet(startTime, endTime);
	}
	function _addToRewardsAllocation(uint256 amount) internal {
		_updateAccrual();
		uint256 remainingTime;
		if (!hasStarted() || hasEnded()) {
			remainingTime = periodDuration();
		} else {
			remainingTime = timeRemainingInPeriod();
		}

		_rewardRate = _rewardRate.add(amount.div(remainingTime));

		emit RewardAdded(amount);
	}

	function _updateAccrual() internal {
		_accruedRewardPerToken = accruedRewardPerToken();
		_lastUpdateTime = lastTimeRewardApplicable();
	}
	function _updateRewardFor(address account) internal override {
		_updateAccrual();
		_rewards[account] = earned(account);
		_accruedRewardPerTokenPaid[account] = _accruedRewardPerToken;
	}
}