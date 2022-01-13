// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./WTF.sol";
import "./ERC20.sol";
import "./PRBMathUD60x18.sol";

contract StakingRewards {

	using PRBMathUD60x18 for uint256;

	uint256 constant private FLOAT_SCALAR = 2**64;
	uint256 constant private PERCENT_FEE = 5; // only for WTF staking
	uint256 constant private X_TICK = 30 days;

	struct User {
		uint256 deposited;
		int256 scaledPayout;
	}

	struct Info {
		uint256 totalRewards;
		uint256 startTime;
		uint256 lastUpdated;
		uint256 pendingFee;
		uint256 scaledRewardsPerToken;
		uint256 totalDeposited;
		mapping(address => User) users;
		WTF wtf;
		ERC20 token;
	}
	Info private info;


	event Deposit(address indexed user, uint256 amount, uint256 fee);
	event Withdraw(address indexed user, uint256 amount, uint256 fee);
	event Claim(address indexed user, uint256 amount);
	event Reinvest(address indexed user, uint256 amount);
	event Reward(uint256 amount);


	constructor(uint256 _totalRewards, uint256 _stakingRewardsStart, ERC20 _token) {
		info.totalRewards = _totalRewards;
		info.startTime = block.timestamp < _stakingRewardsStart ? _stakingRewardsStart : block.timestamp;
		info.lastUpdated = startTime();
		info.wtf = WTF(msg.sender);
		info.token = _token;
	}

	function update() public {
		uint256 _now = block.timestamp;
		if (_now > info.lastUpdated && totalDeposited() > 0) {
			uint256 _reward = info.totalRewards.mul(_delta(_getX(info.lastUpdated), _getX(_now)));
			if (info.pendingFee > 0) {
				_reward += info.pendingFee;
				info.pendingFee = 0;
			}
			uint256 _balanceBefore = info.wtf.balanceOf(address(this));
			info.wtf.claimRewards();
			_reward += info.wtf.balanceOf(address(this)) - _balanceBefore;
			info.lastUpdated = _now;
			_disburse(_reward);
		}
	}

	function deposit(uint256 _amount) external {
		depositFor(msg.sender, _amount);
	}

	function depositFor(address _user, uint256 _amount) public {
		require(_amount > 0);
		update();
		uint256 _balanceBefore = info.token.balanceOf(address(this));
		info.token.transferFrom(msg.sender, address(this), _amount);
		uint256 _amountReceived = info.token.balanceOf(address(this)) - _balanceBefore;
		_deposit(_user, _amountReceived);
	}

	function tokenCallback(address _from, uint256 _tokens, bytes calldata) external returns (bool) {
		require(_isWTF() && msg.sender == tokenAddress());
		require(_tokens > 0);
		update();
		_deposit(_from, _tokens);
		return true;
	}

	function disburse(uint256 _amount) public {
		require(_amount > 0);
		update();
		uint256 _balanceBefore = info.wtf.balanceOf(address(this));
		info.wtf.transferFrom(msg.sender, address(this), _amount);
		uint256 _amountReceived = info.wtf.balanceOf(address(this)) - _balanceBefore;
		_processFee(_amountReceived);
	}

	function withdrawAll() public {
		uint256 _deposited = depositedOf(msg.sender);
		if (_deposited > 0) {
			withdraw(_deposited);
		}
	}

	function withdraw(uint256 _amount) public {
		require(_amount > 0 && _amount <= depositedOf(msg.sender));
		update();
		info.totalDeposited -= _amount;
		info.users[msg.sender].deposited -= _amount;
		info.users[msg.sender].scaledPayout -= int256(_amount * info.scaledRewardsPerToken);
		uint256 _fee = _calculateFee(_amount);
		info.token.transfer(msg.sender, _amount - _fee);
		_processFee(_fee);
		emit Withdraw(msg.sender, _amount, _fee);
	}

	function claim() public {
		update();
		uint256 _rewards = rewardsOf(msg.sender);
		if (_rewards > 0) {
			info.users[msg.sender].scaledPayout += int256(_rewards * FLOAT_SCALAR);
			info.wtf.transfer(msg.sender, _rewards);
			emit Claim(msg.sender, _rewards);
		}
	}

	function reinvest() public {
		require(_isWTF());
		update();
		uint256 _rewards = rewardsOf(msg.sender);
		if (_rewards > 0) {
			info.users[msg.sender].scaledPayout += int256(_rewards * FLOAT_SCALAR);
			_deposit(msg.sender, _rewards);
			emit Reinvest(msg.sender, _rewards);
		}
	}

	
	function wtfAddress() public view returns (address) {
		return address(info.wtf);
	}
	
	function tokenAddress() public view returns (address) {
		return address(info.token);
	}

	function startTime() public view returns (uint256) {
		return info.startTime;
	}

	function totalDeposited() public view returns (uint256) {
		return info.totalDeposited;
	}

	function depositedOf(address _user) public view returns (uint256) {
		return info.users[_user].deposited;
	}
	
	function rewardsOf(address _user) public view returns (uint256) {
		return uint256(int256(info.scaledRewardsPerToken * depositedOf(_user)) - info.users[_user].scaledPayout) / FLOAT_SCALAR;
	}
	
	function currentRatePerDay() public view returns (uint256) {
		if (block.timestamp < startTime()) {
			return info.totalRewards.mul(_delta(_getX(startTime()), _getX(startTime() + 24 hours)));
		} else {
			return info.totalRewards.mul(_delta(_getX(block.timestamp), _getX(block.timestamp + 24 hours)));
		}
	}

	function totalDistributed() public view returns (uint256) {
		return info.totalRewards.mul(_sum(_getX(block.timestamp)));
	}

	function allInfoFor(address _user) external view returns (uint256 startingTime, uint256 totalRewardsDistributed, uint256 rewardsRatePerDay, uint256 currentFeePercent, uint256 totalTokensDeposited, uint256 virtualRewards, uint256 userWTF, uint256 userBalance, uint256 userAllowance, uint256 userDeposited, uint256 userRewards) {
		startingTime = startTime();
		totalRewardsDistributed = totalDistributed();
		rewardsRatePerDay = currentRatePerDay();
		currentFeePercent = _calculateFee(1e20);
		totalTokensDeposited = totalDeposited();
		virtualRewards = block.timestamp > info.lastUpdated ? info.totalRewards.mul(_delta(_getX(info.lastUpdated), _getX(block.timestamp))) : 0;
		userWTF = info.wtf.balanceOf(_user);
		userBalance = info.token.balanceOf(_user);
		userAllowance = info.token.allowance(_user, address(this));
		userDeposited = depositedOf(_user);
		userRewards = rewardsOf(_user);
	}

	
	function _deposit(address _user, uint256 _amount) internal {
		uint256 _fee = _calculateFee(_amount);
		uint256 _deposited = _amount - _fee;
		info.totalDeposited += _deposited;
		info.users[_user].deposited += _deposited;
		info.users[_user].scaledPayout += int256(_deposited * info.scaledRewardsPerToken);
		_processFee(_fee);
		emit Deposit(_user, _amount, _fee);
	}
	
	function _processFee(uint256 _fee) internal {
		if (_fee > 0) {
			if (block.timestamp < startTime() || totalDeposited() == 0) {
				info.pendingFee += _fee;
			} else {
				_disburse(_fee);
			}
		}
	}

	function _disburse(uint256 _amount) internal {
		info.scaledRewardsPerToken += _amount * FLOAT_SCALAR / totalDeposited();
		emit Reward(_amount);
	}


	function _isWTF() internal view returns (bool) {
		return wtfAddress() == tokenAddress();
	}

	function _calculateFee(uint256 _amount) internal view returns (uint256) {
		return _isWTF() ? (_amount * PERCENT_FEE / 100).mul(1e18 - _sum(_getX(block.timestamp))) : 0;
	}
	
	function _getX(uint256 t) internal view returns (uint256) {
		uint256 _start = startTime();
		if (t < _start) {
			return 0;
		} else {
			return ((t - _start) * 1e18).div(X_TICK * 1e18);
		}
	}

	function _sum(uint256 x) internal pure returns (uint256) {
		uint256 _e2x = x.exp2();
		return (_e2x - 1e18).div(_e2x);
	}

	function _delta(uint256 x1, uint256 x2) internal pure returns (uint256) {
		require(x2 >= x1);
		return _sum(x2) - _sum(x1);
	}
}