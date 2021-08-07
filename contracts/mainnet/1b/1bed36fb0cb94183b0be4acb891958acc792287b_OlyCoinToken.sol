pragma solidity ^0.5.8;

import "./Context.sol";
import "./IERC20.sol";
import "./ERC20.sol";
import "./Ownable.sol";

contract OlyCoinToken is IERC20, ERC20Detailed, Ownable {
	struct vault {
		uint256 olyAmount;
		uint256 rewardAmount;
		uint256 unlockTime;
	}

	event Stake(address indexed holder, address indexed delegate, uint256 amount, uint256 rewardAmount, uint256 time);
	event Unstake(address indexed holder, uint256 amount, uint256 rewardAmount);

	uint256 private _maxOly;
	uint256 private _stakingRate;
	uint256 private _stakingPeriod;
	uint256 private _delegateReward;
	bool private _isStakingActive = true;

	mapping(address => mapping(uint256 => vault)) public vaults;
	mapping(address => uint256) public vaultCount;
	mapping(address => uint256) public totalStake;

    constructor(uint256 maxOly, uint256 mintCount, uint256 stakingRate, uint256 stakingPeriod, uint256 delegateReward)
    public ERC20Detailed("OlyCoin", "OLY", 4) {
    	_maxOly = maxOly * 1e4;
    	_stakingRate = stakingRate;
    	_stakingPeriod = stakingPeriod;
    	_delegateReward = delegateReward;
        mintOly(owner(), mintCount * 1e4);
    }

    function maxOly() public view returns (uint256) {
    	return _maxOly;
    }

    function stakingRate() public view returns (uint256) {
    	return _stakingRate;
    }

    function stakingPeriod() public view returns (uint256) {
    	return _stakingPeriod;
    }

    function delegateReward() public view returns (uint256) {
    	return _delegateReward;
    }

    function isStakingActive() public view returns (bool) {
    	return _isStakingActive;
    }

    function toggleStaking() public onlyOwner {
    	_isStakingActive = !_isStakingActive;
    }

    function mintOly(address to, uint256 numberOfTokens) public onlyOwner {
    	require(numberOfTokens > 0, "Can only issue more than 0 tokens");
    	require(
    		totalSupply().add(numberOfTokens) <= maxOly(),
    		"The issue of coins will exceed the maximum supply of OlyCoin"
    	);

    	_mint(to, numberOfTokens);
    }

    function setStakingRate(uint256 newStakingRate) public onlyOwner {
    	require(newStakingRate >= 1, "The percentage of staking can not be lower than 1");
    	_stakingRate = newStakingRate;
    }

    function setStakingPeriod(uint256 newStakingPeriod) public onlyOwner {
    	require(newStakingPeriod >= 1, "The period of staking can not be lower than 1");
    	_stakingPeriod = newStakingPeriod;
    }

    function setDelegateReward(uint256 newDelegateReward) public onlyOwner {
    	_delegateReward = newDelegateReward;
    }

    function burn(uint256 value) public {
    	require(maxOly() >= value && value > 0, "It is impossible to burn such a number of tokens");
    	_maxOly = maxOly().sub(value);
    	_burn(msg.sender, value);
    }

    function burnFrom(address from, uint256 value) public {
    	require(maxOly() >= value && value > 0, "It is impossible to burn such a number of tokens");
    	_maxOly = maxOly().sub(value);
        _burnFrom(from, value);
    }

    function stake(address delegate, uint256 amount) public returns (uint256 rewardAmount) {
    	require(delegate != address(0), "The delegate cannot be a zero address");
    	require(delegate != msg.sender, "The delegate cannot be the sender");
    	rewardAmount = amount.mul(stakingRate()).mul(stakingPeriod().div(30 days)).div(1e2);
    	require(rewardAmount > 0, "Invalid amount");
    	vault storage newVault = vaults[msg.sender][vaultCount[msg.sender]];
    	newVault.olyAmount = amount;
    	newVault.rewardAmount = rewardAmount;
    	newVault.unlockTime = block.timestamp.add(stakingPeriod());
    	totalStake[msg.sender] = totalStake[msg.sender].add(amount);
    	vaultCount[msg.sender]++;
    	transfer(address(this), amount);

    	if (delegateReward() > 0 && totalStake[delegate] >= 1000) {
    		_mint(delegate, amount.mul(delegateReward()).div(1e2));
    	}

    	emit Stake(msg.sender, delegate, amount, rewardAmount, stakingPeriod());
    }

    function unstake(uint256 index) public returns (uint256 olyAmount, uint256 rewardAmount) {
    	vault storage stakeVault = vaults[msg.sender][index];
    	require(block.timestamp >= stakeVault.unlockTime, "This deposit is locked");
    	olyAmount = stakeVault.olyAmount.add(0);
    	rewardAmount = stakeVault.rewardAmount.add(0);
    	stakeVault.olyAmount = 0;
    	stakeVault.rewardAmount = 0;
    	totalStake[msg.sender] = totalStake[msg.sender].sub(olyAmount);

    	_transfer(address(this), msg.sender, olyAmount);
    	_mint(msg.sender, rewardAmount);

    	emit Unstake(msg.sender, olyAmount, rewardAmount);
    }
}