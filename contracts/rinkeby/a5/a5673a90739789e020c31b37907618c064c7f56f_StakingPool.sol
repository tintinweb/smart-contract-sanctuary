// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./STRToken.sol";

contract StakingPool is Ownable{
	using SafeMath for uint256;

	STRToken public strToken;
	uint256 public totalTokenStaked;    

    address[] public stakingAccounts;
	mapping(address => StakerInfo) public stakers;
	mapping(address => bool) public isStaking;

	struct StakerInfo{
		uint tokenBalance;
		uint pool;
		uint stakingStartDate;
		uint stakingEndDate;
		uint releaseDate;
		uint releaseAmount;
	}

	uint public giga;
	uint public mega;
	uint public micro;
	uint public nano;
	uint public apy;

	constructor(STRToken _strToken, uint _giga, uint _mega, uint _micro, uint _nano, uint _apy){
		strToken = _strToken;
		apy = _apy;
		giga = _giga;
		mega = _mega;
		micro = _micro;
		nano = _nano;
	}

	function stakeTokens(uint tokenAmount) public{
		require(tokenAmount > 0, "amount cannot be zero");
		StakerInfo memory staker;		
		uint pool;

		//Transfer STR tokens to this contract for staking
		strToken.transferFrom(msg.sender, address(this), tokenAmount);

		//Update total staking balance 
		totalTokenStaked = totalTokenStaked.add(tokenAmount);

		//add user to stakers array only if he has not staked before
		if(!isStaking[msg.sender]){
			//determine user pool
			pool = this.updateStakerPool(tokenAmount);
			staker = StakerInfo({
				tokenBalance: tokenAmount,
				pool: pool,
				stakingStartDate: block.timestamp,
				stakingEndDate: 0,
				releaseDate: 0,
				releaseAmount: 0
				});						
			stakers[msg.sender] = staker;
		}else{
			//update staker pool & balance
			staker = stakers[msg.sender];
			
			//provide rewards till date & restake all tokens
			uint256 daysPassed = block.timestamp.sub(staker.stakingStartDate).div(365 days);
			uint256 rewards = calculateRewards(daysPassed);

			staker.tokenBalance = staker.tokenBalance.add(tokenAmount).add(rewards);
			staker.pool = this.updateStakerPool(staker.tokenBalance);
			staker.stakingStartDate = block.timestamp;
		}		

		//update staking status
		isStaking[msg.sender] = true;		
	}

	function unstakeTokens(uint tokenAmount) public{
		StakerInfo memory staker = stakers[msg.sender];
		require(tokenAmount > 0, "amount cannot be zero");
		require(staker.tokenBalance >= tokenAmount, "amount cannot be greater than staked tokens");

		//calculate rewards
		uint256 daysPassed = block.timestamp.sub(staker.stakingStartDate).div(365 days);
		uint256 rewards = calculateRewards(daysPassed);
		
		staker.releaseAmount = tokenAmount.add(rewards);

		//Update total staking balance 
		totalTokenStaked = totalTokenStaked.sub(tokenAmount);		

		//Update staking & pool balance 		
		staker.tokenBalance = staker.tokenBalance.sub(tokenAmount);
		staker.pool = this.updateStakerPool(staker.tokenBalance);
		staker.stakingEndDate = block.timestamp;
		staker.releaseDate = block.timestamp.add(7 days);

		if(staker.tokenBalance == tokenAmount){
			//update staking status
			isStaking[msg.sender] = false;	
			//remove from staking Pool
			removeStakeholder(msg.sender);	
		}	
	}

	function calculateRewards(uint256 daysPassed) public view returns(uint256){
		return daysPassed.mul(apy).mul(25).div(100).div(100);
	}
	function withdraw() public{		
		StakerInfo memory staker = stakers[msg.sender];
		require(staker.releaseDate <= block.timestamp, "Locking period is of 7 days");
		//Transfer STR tokens from this contract for unstaking
		strToken.transfer(msg.sender, staker.releaseAmount);		
	}	

    function removeStakeholder(address _address) public{
    	for (uint256 s = 0; s < stakingAccounts.length; s += 1){
    		if (_address == stakingAccounts[s]){
       			stakingAccounts[s] = stakingAccounts[stakingAccounts.length - 1];
       			stakingAccounts.pop();
       			return;
       		}
    	}       	
   }  

	function updateStakerPool(uint256 _tokenAmount) external view returns (uint) {
		uint pool;
		if(_tokenAmount >= giga){
			pool = 4;			
		}else if(_tokenAmount > mega){
			pool = 3;
		}else if(_tokenAmount > micro){
			pool = 2;
		}else if(_tokenAmount > nano){
			pool = 1;
		}else{
			pool = 0;
		}	
		return pool;	
	}

	function isStakeholder(address _address) public view returns(bool){       
       if(isStaking[_address]){
			return true;
       }
       return false;
    }  

	function getStakers() external view returns (address[] memory){
		return stakingAccounts;
	}

	function getStaker(address _address) external view returns(uint){
		return stakers[_address].pool;
	}	

	function countStakers() public view returns (uint){
		return stakingAccounts.length;
	}

}