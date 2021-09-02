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

contract WrappedHydraStaking {
	/* Variables */
	uint256 private _lastUpdateTime;
	uint256 private _rewardRate;
	uint256 private _rewardPerTokenStored;
	uint256 private _totalSupply;
	address private _owner;
	bool    private _initialized;
	IERC20  private _wrappedHydra;
	mapping(address => uint256) private _userRewardPerTokenPaid;
	mapping(address => uint256) private _rewards;
	mapping(address => uint256) private _balances;
	
	/* Modifiers */
	modifier initialized() {
		require( _initialized, "Not initialized" );
		_;
	}

	modifier onlyOwner() {
		require( _owner == msg.sender, "Caller is not the owner" );
		_;
	}

	modifier updateReward(address account) {
		_rewardPerTokenStored = rewardPerToken();
		_lastUpdateTime = block.number;
		if ( account != address(0) ) {
			uint256 reward = (_balances[account] * (_rewardPerTokenStored - _userRewardPerTokenPaid[account])) / 1e18;
			_rewards[account] += reward;
			_userRewardPerTokenPaid[account] = _rewardPerTokenStored;
		}
		_;
	}
	
	/* Externals */
	function initialize(address owner_, address wrappedHydra_, uint256 reward_) external returns(bool) {
		require( ! _initialized, "Already initialized" );
		require( reward_ > 0, "Reward is zero" );
		_wrappedHydra     = IERC20(wrappedHydra_);
		require( _wrappedHydra.transferFrom(owner_, address(this), reward_), "Token transfer failed" );
		_initialized      = true;
		_owner            = owner_;
		_totalSupply      += 1;
		_balances[owner_] += 1;
		_lastUpdateTime   = block.number;
		_rewardRate       = 132e5; // 8 HYD / round / delegate on Hydra blockchain;
		emit Staked(msg.sender, 1);
		return true;
	}

	function stake(uint256 amount_) external initialized updateReward(msg.sender) {
		require( amount_ > 0, "Cannot stake zero liquidity" );
		require( _wrappedHydra.transferFrom(msg.sender, address(this), amount_), "Token transfer failed" );
		_totalSupply += amount_;
		_balances[msg.sender] += amount_;
		emit Staked(msg.sender, amount_);
	}

	function withdraw(uint256 amount_) public initialized updateReward(msg.sender) {
		require( amount_ <= _balances[msg.sender], "Insufficient funds" );
		require( amount_ > 0, "Invalid amount to withdraw" );
		require( _wrappedHydra.transfer(msg.sender, amount_), "Token transfer failed" );
		_totalSupply -= amount_;
		_balances[msg.sender] -= amount_;
		emit Withdrawn(msg.sender, amount_);
	}

	function getReward() public initialized updateReward(msg.sender) {
		uint256 reward = _rewards[msg.sender];
		if ( reward > 0 ) {
			_rewards[msg.sender] = 0;
			require( _wrappedHydra.transfer(msg.sender, reward), "Token transfer failed");
			emit RewardPaid(msg.sender, reward);
		}
	}

	function exit() external initialized {
		withdraw(_balances[msg.sender]);
		getReward();
	}
  
	function withdrawRewardSupply(uint256 amount_) external initialized onlyOwner {
		uint256 rewardSupply_ = _wrappedHydra.balanceOf(address(this)) - _totalSupply;
		require( rewardSupply_ >= amount_, "Insufficient amount to withdraw" );
		require( _wrappedHydra.transfer(msg.sender, amount_), "Token transfer failed");
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

	function rewardSupply() external view returns(uint256) {
		return _wrappedHydra.balanceOf(address(this)) - _totalSupply;
	}

	function balanceOf(address account_) external view returns(uint256) {
		return _balances[account_];
	}

	function rewardRate() external view returns(uint256) {
		return _rewardRate;
	}
  
	function estimateReward(address account_) external view returns (uint256) {
		return (
			_balances[account_] * (
				rewardPerToken() - _userRewardPerTokenPaid[account_]
			)
		) / 1e18 + _rewards[account_];
	}

	/* Internals */
	function rewardPerToken() internal view returns (uint256) {
		if ( _totalSupply == 0 ) {
			return _rewardPerTokenStored;
		}
		return _rewardPerTokenStored + ((block.number - _lastUpdateTime) * _rewardRate * 1e18 / _totalSupply);
	}
	
	/* Events */
	event Staked(address indexed user, uint256 indexed amount);
	event Withdrawn(address indexed user, uint256 indexed amount);
	event RewardPaid(address indexed recipient, uint256 indexed amount);
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	event Locked(uint256 indexed amount);
}