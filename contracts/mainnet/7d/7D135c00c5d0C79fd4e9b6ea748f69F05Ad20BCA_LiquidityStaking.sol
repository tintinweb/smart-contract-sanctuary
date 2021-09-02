/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IERC20 {
	function transfer(address recipient, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
	function balanceOf(address account) external view returns (uint256);
}

contract LiquidityStaking {
	/* Variables */
	uint256 private _lastUpdateTime;
	uint256 private _periodFinish;
	uint256 private _rewardRate;
	uint256 private _rewardPerTokenStored;
	uint256 private _totalSupply;
	uint256 private _locked;
	address private _owner;
	bool    private _initialized;
	IERC20  private _rewardsToken; //wHYD
	IERC20  private _stakingToken; //UNI WHYD-ETH
	mapping(address => uint256) private _userRewardPerTokenPaid;
	mapping(address => uint256) private _shortRewards;
	mapping(address => uint256) private _longRewards;
	mapping(address => uint256) private _balances;
	
	/* Modifiers */
	modifier onlyOwner() {
		require( _owner == msg.sender, "Caller is not the owner" );
		_;
	}

	modifier initialized() {
		require( _initialized, "Not initialized" );
		_;
	}

	modifier updateReward(address account) {
		_rewardPerTokenStored = rewardPerToken();
		_lastUpdateTime = lastTimeRewardApplicable();
		if ( account != address(0) ) {
			uint256 reward = (_balances[account] * (_rewardPerTokenStored - _userRewardPerTokenPaid[account])) / 1e18;
			uint256 shortReward = reward / 2;
			uint256 longReward = reward - shortReward;
			_shortRewards[account] += shortReward;
			_longRewards[account] += longReward;
			_userRewardPerTokenPaid[account] = _rewardPerTokenStored;
		}
		_;
	}
	
	/* Externals */
	function initialize(address owner_, address rewardsToken_, address stakingToken_, uint256 reward_, uint256 rewardsDuration_)
	external returns(bool) {
		require( ! _initialized, "Already initialized" );
		require( owner_ != address(0), "New owner has zero address" );
		require( reward_ > 0, "Reward is zero" );
		require( rewardsDuration_ > 0, "Rewards duration is zero" );
		_initialized       = true;
		_owner             = owner_;
		_rewardsToken      = IERC20(rewardsToken_);
		_stakingToken      = IERC20(stakingToken_);
		_totalSupply      += 1;
		_balances[owner_] += 1;
		_lastUpdateTime    = block.number;
		_periodFinish      = block.number + rewardsDuration_; // a year block amount in production is 2254114
		_rewardRate        = reward_ / rewardsDuration_;
		require( _rewardsToken.transferFrom(owner_, address(this), reward_), "Token transfer failed");
		require( _stakingToken.transferFrom(owner_, address(this), 1), "Token transfer failed");
		emit OwnershipTransferred(address(0), owner_);
		emit Staked(owner_, 1);
		return true;
	}

	function stake(uint256 amount_) external initialized updateReward(msg.sender) {
		require( amount_ > 0, "Cannot stake zero liquidity" );
		require( _stakingToken.transferFrom(msg.sender, address(this), amount_), "Token transfer failed" );
		_totalSupply += amount_;
		_balances[msg.sender] += amount_;
		emit Staked(msg.sender, amount_);
	}

	function withdraw(uint256 amount_) public initialized updateReward(msg.sender) {
		require( amount_ <= _balances[msg.sender], "Insufficient funds" );
		require( amount_ > 0, "Invalid amount to withdraw" );
		require( _stakingToken.transfer(msg.sender, amount_), "Token transfer failed" );
		_totalSupply -= amount_;
		_balances[msg.sender] -= amount_;
		emit Withdrawn(msg.sender, amount_);
	}

	function getReward() public initialized updateReward(msg.sender) {
		uint256 reward = _shortRewards[msg.sender];
		if ( reward > 0 ) {
			_shortRewards[msg.sender] = 0;
			require( _rewardsToken.transfer(msg.sender, reward), "Token transfer failed");
			emit RewardPaid(msg.sender, reward);
		}
		if ( _periodFinish < block.number ) {
			reward = _longRewards[msg.sender];
			if ( reward > 0 ) {
				_longRewards[msg.sender] = 0;
				require( _rewardsToken.transfer(msg.sender, reward), "Token transfer failed");
				emit RewardPaid(msg.sender, reward);
			}
		}
	}

	function exit() external initialized {
		withdraw(_balances[msg.sender]);
		getReward();
	}

	function lockToken(uint256 amount_) external onlyOwner {
		require( amount_ > 0, "Amount is zero" );
		require( _stakingToken.transferFrom(msg.sender, address(this), amount_), "Token transfer failed" );
		_locked += amount_;
		emit Locked(amount_);
	}

	function releaseToken() external onlyOwner {
		require( _locked > 0, "Amount is zero" );
		require( _periodFinish < block.number, "Period is not over" );
		uint256 amount = _locked;
		_locked = 0;
		require( _stakingToken.transfer(msg.sender, amount), "Token transfer failed" );
		emit UnLocked(amount);
	}

	function transferOwnership(address newOwner_) external onlyOwner {
		require( newOwner_ != address(0), "New owner has zero address" );
		emit OwnershipTransferred(_owner, newOwner_);
		_owner = newOwner_;
	}

	/* Constants */
	function totalSupply() external view returns(uint256) {
		return _totalSupply;
	}

	function balanceOf(address account_) external view returns(uint256) {
		return _balances[account_];
	}

	function periodFinish() external view returns(uint256) {
		return _periodFinish;
	}

	function rewardRate() external view returns(uint256) {
		return _rewardRate;
	}

	function lockedAmount() external view returns(uint256) {
		return _locked;
	}

	function estimateShortReward(address account_) external view returns (uint256) {
		return (
			_balances[account_] * (
				rewardPerToken() - _userRewardPerTokenPaid[account_]
			)
		) / 1e18 / 2 + _shortRewards[account_];
	}

	function estimateLongReward(address account_) external view returns (uint256) {
		return (
			_balances[account_] * (
				rewardPerToken() - _userRewardPerTokenPaid[account_]
			)
		) / 1e18 / 2 + _longRewards[account_];
	}

	function owner() external view returns (address) {
		return _owner;
	}

	/* Internals */
	function lastTimeRewardApplicable() internal view returns (uint256) {
		return block.number < _periodFinish ? block.number : _periodFinish;
	}
  
	function rewardPerToken() internal view returns (uint256) {
		if ( _totalSupply == 0 ) {
			return _rewardPerTokenStored;
		}
		return _rewardPerTokenStored + ((lastTimeRewardApplicable() - _lastUpdateTime) * _rewardRate * 1e18 / _totalSupply);
	}

	/* Events */
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	event Staked(address indexed user, uint256 indexed amount);
	event Withdrawn(address indexed user, uint256 indexed amount);
	event RewardPaid(address indexed recipient, uint256 indexed amount);
	event Locked(uint256 indexed amount);
	event UnLocked(uint256 indexed amount);
}