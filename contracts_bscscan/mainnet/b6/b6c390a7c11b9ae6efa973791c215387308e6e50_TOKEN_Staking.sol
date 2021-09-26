/**
 *Submitted for verification at BscScan.com on 2021-09-26
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.7.5;

//MATH OPERATIONS -- designed to avoid possibility of errors with built-in math functions
library SafeMath {
    //@dev Multiplies two numbers, throws on overflow.
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    //@dev Integer division of two numbers, truncating the quotient (i.e. rounds down).
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        return c;
    }
    //@dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        uint256 c = a - b;
        return c;
    }
    //@dev Adds two numbers, throws on overflow.
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
//end library
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

abstract contract Ownable {
    address internal _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
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

contract TOKEN_Staking is Ownable {
	using SafeMath for uint256;

	address public constant TOKEN = 0xb48f795a9AdA9Cfd023bD32D32A9974fBd4e951c ; //token to stake

	//STAKING PARAMETERS
	uint256 public constant stakingPeriod = 30 days; //period over which tokens are locked after staking
	uint256 public stakingEnd; //point after which staking rewards cease to accumulate
	uint256 public rewardRate = 14; //14% linear return per staking period
	uint256 public totalStaked; //sum of all user stakes
	uint256 public maxTotalStaked = 58000e23; //5.8 million tokens
	uint256 public minStaked = 1e8; //1000 tokens. min staked per user

	//STAKING MAPPINGS
	mapping (address => uint256) public stakedTokens; //amount of tokens that address has staked
	mapping (address => uint256) public lastStaked; //last time at which address staked, deposited, or "rolled over" their position by calling updateStake directly
	mapping (address => uint256) public totalEarnedTokens; //total tokens earned through staking by each user
	
	constructor(){
		stakingEnd = (block.timestamp + 180 days);
	}

	//STAKING FUNCTIONS
	function deposit(uint256 amountTokens) external {
		require( (stakedTokens[msg.sender] >= minStaked || amountTokens >= minStaked), "deposit: must exceed minimum stake" );
		require(totalStaked + amountTokens <= maxTotalStaked, "deposit: amount would exceed max stake. call updateStake to claim dividends");
		updateStake();
		IERC20(TOKEN).transferFrom(msg.sender, address(this), amountTokens);
		stakedTokens[msg.sender] += amountTokens;
		totalStaked += amountTokens;
	}

	function updateStake() public {
		uint256 stakedUntil = min(block.timestamp, stakingEnd);
		uint256 periodStaked = stakedUntil.sub(lastStaked[msg.sender]);
		uint256 dividends;
		//linear rewards up to stakingPeriod
		if(periodStaked < stakingPeriod) {
			dividends = periodStaked.mul(stakedTokens[msg.sender]).mul(rewardRate).div(stakingPeriod).div(100);
		} else {
			dividends = stakedTokens[msg.sender].mul(rewardRate).div(100);
		}
		//update lastStaked time for msg.sender -- user cannot unstake until end of another stakingPeriod
		lastStaked[msg.sender] = stakedUntil;
		//withdraw dividends for user if rolling over dividends would exceed staking cap, else stake the dividends automatically
		if(totalStaked + dividends > maxTotalStaked) {
			IERC20(TOKEN).transfer(msg.sender, dividends);
			totalEarnedTokens[msg.sender] += dividends;
		} else {
			stakedTokens[msg.sender] += dividends;
			totalStaked += dividends;
			totalEarnedTokens[msg.sender] += dividends;
		}
	}

	function withdrawDividends() external {
		uint256 stakedUntil = min(block.timestamp, stakingEnd);
		uint256 periodStaked = stakedUntil.sub(lastStaked[msg.sender]);
		uint256 dividends;
		//linear rewards up to stakingPeriod
		if(periodStaked < stakingPeriod) {
			dividends = periodStaked.mul(stakedTokens[msg.sender]).mul(rewardRate).div(stakingPeriod).div(100);
		} else {
			dividends = stakedTokens[msg.sender].mul(rewardRate).div(100);
		}
		//update lastStaked time for msg.sender -- user cannot unstake until end of another stakingPeriod
		lastStaked[msg.sender] = stakedUntil;
		//withdraw dividends for user
		IERC20(TOKEN).transfer(msg.sender, dividends);
		totalEarnedTokens[msg.sender] += dividends;
	}

    function min(uint256 a, uint256 b) internal pure returns(uint256) {
        return a < b ? a : b;
    }

	function unstake() external {
		uint256 timeSinceStake = (block.timestamp).sub(lastStaked[msg.sender]);
		require(timeSinceStake >= stakingPeriod || block.timestamp > stakingEnd, "unstake: staking period for user still ongoing");
		updateStake();
		uint256 toTransfer = stakedTokens[msg.sender];
		stakedTokens[msg.sender] = 0;
		IERC20(TOKEN).transfer(msg.sender, toTransfer);
		totalStaked = totalStaked.sub(toTransfer);
	}

	function getPendingDivs(address user) external view returns(uint256) {
		uint256 stakedUntil = min(block.timestamp, stakingEnd);
		uint256 periodStaked = stakedUntil.sub(lastStaked[user]);
		uint256 dividends;
		//linear rewards up to stakingPeriod
		if(periodStaked < stakingPeriod) {
			dividends = periodStaked.mul(stakedTokens[user]).mul(rewardRate).div(stakingPeriod).div(100);
		} else {
			dividends = stakedTokens[user].mul(rewardRate).div(100);
		}
		return(dividends);
	}

	//OWNER ONLY FUNCTIONS
	function updateMinStake(uint256 newMinStake) external onlyOwner() {
		minStaked = newMinStake;
	}

	function updateStakingEnd(uint256 newStakingEnd) external onlyOwner() {
		require(newStakingEnd >= block.timestamp, "updateStakingEnd: newStakingEnd must be in future");
		stakingEnd = newStakingEnd;
	}

	function updateRewardRate(uint256 newRewardRate) external onlyOwner() {
		require(newRewardRate <= 100, "what are you, crazy?");
		rewardRate = newRewardRate;
	}

	function updateMaxTotalStaked(uint256 newMaxTotalStaked) external onlyOwner() {
		maxTotalStaked = newMaxTotalStaked;
	}

	//allows owner to recover ERC20 tokens for users when they are mistakenly sent to contract
	function recoverTokens(address tokenAddress, address dest, uint256 amountTokens) external onlyOwner() {
		require(tokenAddress != TOKEN, "recoverTokens: cannot move staked token");
		IERC20(tokenAddress).transfer(dest, amountTokens);
	}

	//allows owner to reclaim any tokens not distributed during staking
	function recoverTOKEN() external onlyOwner() {
		require(block.timestamp >= (stakingEnd + 30 days), "recoverTOKEN: too early");
		uint256 amountToSend = IERC20(TOKEN).balanceOf(address(this));
		IERC20(TOKEN).transfer(msg.sender, amountToSend);
	}
}