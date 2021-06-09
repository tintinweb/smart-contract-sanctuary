// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./SafeMath.sol";


contract KtlyoStaking {

    address public token1;
	address public token2;
	uint256 public apy;
	uint256 public duration;
	uint256 public maxStakeAmt1;
	uint256 public maxStakeAmt2;
    uint256 private interestRate;
	uint256 private tokenRatio;
	uint256 public rewardAmt1;
	uint256 public rewardAmt2;
	uint256 private amtRewardRemainingBalance1;
	uint256 private amtRewardRemainingBalance2;
	uint256 private totalStaked1;
	uint256 private totalStaked2;
	uint256 private totalRedeemed1;
	uint256 private totalRedeemed2;
	uint256 private openRewards1;
	uint256 private openRewards2;
	address public owner;
    uint256 public createdAt;
	uint256 private daysInYear;
	uint256 private secondsInYear;
	uint256 private precision = 1000000000000000000;
	bool private stakingStarted;
	struct Transaction { 
		address wallet;
		address token;
		uint256 amount;
		uint256 createdAt;
		bool redeemed;
		uint256 rewardAmt1;
		uint256 rewardAmt2;
		uint256 redeemedAt;
		uint256 stakeEnd;
	}
	mapping(address => Transaction[]) transactions;
	
	struct MaxLimit { 
		uint256 limit1;
		uint256 limit2;
	}
	
	mapping(address => bool) blackListed;
	mapping(address => MaxLimit) limits;
	
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor(
        address _token1,
		address _token2,
		uint256 _apy,
		uint256 _duration,
		uint256 _tokenRatio,
		uint256 _maxStakeAmt1,
		uint256 _rewardAmt1,
        address _owner
		
    ) {
        token1 = _token1;
		token2 = _token2;
		apy = _apy;
		duration = _duration;
		tokenRatio = _tokenRatio;
		maxStakeAmt1 = _maxStakeAmt1;
		maxStakeAmt2 = SafeMath.div(SafeMath.mul(maxStakeAmt1,tokenRatio),precision);
		rewardAmt1 = _rewardAmt1;
		rewardAmt2 = SafeMath.div(SafeMath.mul(rewardAmt1,tokenRatio),precision);
        owner = _owner;
        createdAt = block.timestamp;
		stakingStarted = false;
		daysInYear = uint256(365);
		secondsInYear = daysInYear*24*60*60;
		interestRate = SafeMath.div(SafeMath.div(SafeMath.mul(apy,duration),secondsInYear),100);
		emit CreatedContract(token1,token2,apy,duration,maxStakeAmt1,maxStakeAmt2, rewardAmt1,rewardAmt2,msg.sender,block.timestamp,interestRate,tokenRatio);
		
		
    }
	
	// return ETH
    receive() external payable {
		
        emit Reverted(msg.sender, msg.value);
		revert("ETH is not accepted");
    }
	
    // return ETH
    fallback() external payable { 
      
	   emit Reverted(msg.sender, msg.value);
	   revert("ETH is not accepted");
    }
	
	// callable by owner only
    function activate() onlyOwner public {
      
		//check for rewards
		ERC20 tokenOne = ERC20(token1);
		ERC20 tokenTwo = ERC20(token2);
		uint256 tenPerc=10;
		uint256 balanceForToken1= tokenOne.balanceOf(address(this));
		uint256 balanceForToken2= tokenTwo.balanceOf(address(this));
		uint256 token1CheckAmount;
		uint256 token2CheckAmount;
		uint256 rewardBalance1;
		uint256 rewardBalance2;
		
		token1CheckAmount = SafeMath.sub(balanceForToken1,totalStaked1);
		token2CheckAmount = SafeMath.sub(balanceForToken2,totalStaked2);
		
		rewardBalance1 = SafeMath.sub(SafeMath.sub(rewardAmt1,totalRedeemed1),openRewards1);
		rewardBalance2 = SafeMath.sub(SafeMath.sub(rewardAmt2,totalRedeemed2),openRewards2);
		
		require (token1CheckAmount>=SafeMath.div(rewardBalance1,tenPerc),"Activation error. Insufficient balance of rewards for token1");
		require (token2CheckAmount>=SafeMath.div(rewardBalance2,tenPerc),"Activation error. Insufficient balance of rewards for token2");
		//activate staking
		stakingStarted = true;
		emit StartStaking(msg.sender,block.timestamp);
    }
	
	// callable by owner only
    function deActivate() onlyOwner public {
      
		
		//de-activate staking
		stakingStarted = false;
		emit StopStaking(msg.sender,block.timestamp);
    }
	
	// callable by owner only
    function blackList(address[] memory addressList,bool blStatus) onlyOwner public {
		
		uint256 i;
		
		for (i=0;i<addressList.length;i++)
		{
			blackListed[addressList[i]]=blStatus;
		}
		if (blStatus) emit AddedToBlackList(msg.sender,block.timestamp);
		else emit RemovedFromBlackList(msg.sender,block.timestamp);
    }
	
	
	// function to stake
    function stake(address tokenContract, uint256 amt) public {
       
	   uint256 amount_reward1;
	   uint256 amount_reward2;
	   uint256 limit1;
	   uint256 limit2;
	   
	   require(stakingStarted,"Staking not active");
	   require(rewardAmt1>SafeMath.add(totalRedeemed1,openRewards1) && rewardAmt2>SafeMath.add(totalRedeemed2,openRewards2),"Rewards are spent. Staking contract is closed.");
	   require(amtRewardRemainingBalance1 > 0 && amtRewardRemainingBalance2 > 0,"Staking rewards are 0");
	   require(tokenContract==token1 || tokenContract==token2,"Invalid token contract");
	   
	   limit1 = limits[msg.sender].limit1;
	   limit2 = limits[msg.sender].limit2;
	   
	   if (token1==tokenContract) 
	   {
	    
		if (SafeMath.add(amt,limit1)>maxStakeAmt1) amt = SafeMath.sub(maxStakeAmt1,limit1);
		limits[msg.sender].limit1 = SafeMath.add(limits[msg.sender].limit1,amt);
		amount_reward1 = SafeMath.div(SafeMath.mul(amt,interestRate),precision);
		if (amtRewardRemainingBalance1<amount_reward1)
	    {
			amount_reward1 = amtRewardRemainingBalance1;
			amt = SafeMath.div(SafeMath.mul(amount_reward1,precision),interestRate);
	    }
		
		amount_reward2 = SafeMath.div(SafeMath.mul(amount_reward1,tokenRatio),precision);
		totalStaked1+=amt;
	   }
	   
	   if (token2==tokenContract) 
	   {
		if (amt+limit2>maxStakeAmt2) amt = SafeMath.sub(maxStakeAmt2,limit2);
		
		limits[msg.sender].limit2 = SafeMath.add(limits[msg.sender].limit2, amt);
		
		amount_reward2 = SafeMath.div(SafeMath.mul(amt,interestRate),precision);
		
		if (amtRewardRemainingBalance2<amount_reward2)
	    {
			amount_reward2 = amtRewardRemainingBalance2;
			amt = SafeMath.div(SafeMath.mul(amount_reward2,precision),interestRate);
	    }
		amount_reward1 = SafeMath.div(SafeMath.mul(amount_reward2,precision),tokenRatio);
		totalStaked2+=amt;
	   }
	   
	   require(amt>0,"Amount is equal to 0");
	   
	   
	   amtRewardRemainingBalance1 = SafeMath.sub(amtRewardRemainingBalance1, amount_reward1,"Insufficient rewards balance for token 1");
	   amtRewardRemainingBalance2 = SafeMath.sub(amtRewardRemainingBalance2, amount_reward2,"Insufficient rewards balance for token 2");
	   
	   ERC20 tokenERC20 = ERC20(tokenContract);
	   //transfer token
	   require(tokenERC20.transferFrom(msg.sender, address(this), amt),"Token transfer for staking not approved!");
	   
	   //create transaction
	   Transaction memory trx = Transaction(
	   {
		   wallet : msg.sender,
		   token : tokenContract,
		   amount : amt,
		   createdAt:block.timestamp,
		   redeemed : false,
		   rewardAmt1 : amount_reward1,
		   rewardAmt2 : amount_reward2,
		   stakeEnd: SafeMath.add(block.timestamp,duration),
		   redeemedAt : 0
	   });
	   openRewards1+=amount_reward1;
	   openRewards2+=amount_reward2;
	   transactions[msg.sender].push(trx);
	   
	   emit Staked(msg.sender,tokenContract, amt);
    }
	function redeemTrx(address requestor, uint256 indexId) 
	internal 
	returns (uint256 returnAmount, uint256 returnAmount2) 
	{
	   
	    
		
		if (transactions[requestor][indexId].token==token1)
		{
			returnAmount = transactions[requestor][indexId].amount;
			if (transactions[requestor][indexId].stakeEnd < block.timestamp && blackListed[requestor]!=true)
			{
				returnAmount = SafeMath.add(returnAmount,transactions[requestor][indexId].rewardAmt1);
				returnAmount2 = transactions[requestor][indexId].rewardAmt2;
			}
			limits[requestor].limit1-=transactions[requestor][indexId].amount;
		}else
		{
			
			returnAmount2 = transactions[requestor][indexId].amount;
			if (transactions[requestor][indexId].stakeEnd < block.timestamp && blackListed[requestor]!=true)
			{
				returnAmount2 = SafeMath.add(returnAmount2,transactions[requestor][indexId].rewardAmt2);
				returnAmount = transactions[requestor][indexId].rewardAmt1;
			}
			limits[requestor].limit2-=transactions[requestor][indexId].amount;
			
		}
		
		transactions[requestor][indexId].redeemed = true;
		transactions[requestor][indexId].redeemedAt = block.timestamp;
		openRewards1-=transactions[requestor][indexId].rewardAmt1;
		openRewards2-=transactions[requestor][indexId].rewardAmt2;
		return (returnAmount,returnAmount2);
	  
	   
    }
	function redeem(uint256 indexId) public {
	   uint256 returnAmount;
	   uint256 returnAmount2;
	   require(transactions[msg.sender][indexId].redeemed==false && transactions[msg.sender][indexId].stakeEnd<block.timestamp ,"Stake is already redeemed or end_date not reached");
	   
	   (returnAmount,returnAmount2) = redeemTrx(msg.sender,indexId);
	   ERC20 tokenERC20 = ERC20(token1);
	   ERC20 tokenERC20t2 = ERC20(token2);
	   if (returnAmount>0) tokenERC20.transfer(msg.sender, returnAmount);
	   if (returnAmount2>0) tokenERC20t2.transfer(msg.sender, returnAmount2);
	   if (transactions[msg.sender][indexId].token==token1) totalStaked1-=transactions[msg.sender][indexId].amount;
	   else totalStaked2-=transactions[msg.sender][indexId].amount;
	   totalRedeemed1+=transactions[msg.sender][indexId].rewardAmt1;
       totalRedeemed2+=transactions[msg.sender][indexId].rewardAmt2;
	   emit Redeemed(msg.sender,block.timestamp, returnAmount,returnAmount2);
    }
	
	function redeemAll() public {
		//check if available to redeem and transfer if available
		uint256 returnAmount;
		uint256 returnAmount2;
		uint256 returnAmountTotal;
		uint256 returnAmountTotal2;
		uint256 i;
		ERC20 tokenERC20t2;
		ERC20 tokenERC20;
		returnAmountTotal = 0;
		returnAmountTotal2 = 0;
	   
		for (i=0;i<transactions[msg.sender].length;i++)
		{
			if (transactions[msg.sender][i].redeemed==false && transactions[msg.sender][i].stakeEnd<block.timestamp)
			{
				(returnAmount,returnAmount2) = redeemTrx(msg.sender,i);
				
				returnAmountTotal = returnAmountTotal + returnAmount;
				returnAmountTotal2 = returnAmountTotal2 + returnAmount2;
				if (transactions[msg.sender][i].token==token1) 
			    {
				 totalStaked1-=transactions[msg.sender][i].amount;
				 totalRedeemed1+=transactions[msg.sender][i].rewardAmt1; 
			    }
			    else
			    {
				 totalStaked2-=transactions[msg.sender][i].amount;
				 totalRedeemed2+=transactions[msg.sender][i].rewardAmt2;
				}
			}
		}
		
		tokenERC20 = ERC20(token1);
		if (returnAmountTotal>0) tokenERC20.transfer(msg.sender, returnAmountTotal);
		tokenERC20t2 = ERC20(token2);
		if (returnAmountTotal2>0) tokenERC20t2.transfer(msg.sender, returnAmountTotal2);
		emit RedeemedAll(msg.sender,block.timestamp, returnAmountTotal,returnAmountTotal2);
	   
    }
	
	function redeemEarly(uint256 indexId) public {
	
       uint256 returnAmount;
	   uint256 returnAmount2;
	   
	   require(transactions[msg.sender][indexId].redeemed==false,"Stake is already redeemed");
	   
	   (returnAmount,returnAmount2) = redeemTrx(msg.sender,indexId);
	   
	   if (transactions[msg.sender][indexId].stakeEnd>block.timestamp)
	   {
		   amtRewardRemainingBalance1 = SafeMath.add(amtRewardRemainingBalance1, transactions[msg.sender][indexId].rewardAmt1);
		   amtRewardRemainingBalance2 = SafeMath.add(amtRewardRemainingBalance2, transactions[msg.sender][indexId].rewardAmt2);
		   
		   if (transactions[msg.sender][indexId].token==token1) totalStaked1-=transactions[msg.sender][indexId].amount;
		   else 
		   {
			totalStaked2-=transactions[msg.sender][indexId].amount;
			returnAmount = returnAmount2;
		   }
		   
		   ERC20 tokenERC20 = ERC20(transactions[msg.sender][indexId].token);
		   if (returnAmount>0) tokenERC20.transfer(msg.sender, returnAmount);
		   emit EarlyRedeemed(msg.sender,block.timestamp, returnAmount);
	   }else{
		
			ERC20 tokenERC20 = ERC20(token1);
			ERC20 tokenERC20t2 = ERC20(token2);
			if (returnAmount>0) tokenERC20.transfer(msg.sender, returnAmount);
			if (returnAmount2>0) tokenERC20t2.transfer(msg.sender, returnAmount2);
			if (transactions[msg.sender][indexId].token==token1) totalStaked1-=transactions[msg.sender][indexId].amount;
			else totalStaked2-=transactions[msg.sender][indexId].amount;
			totalRedeemed1+=transactions[msg.sender][indexId].rewardAmt1;
			totalRedeemed2+=transactions[msg.sender][indexId].rewardAmt2;
			emit Redeemed(msg.sender,block.timestamp, returnAmount,returnAmount2);
	   }
    }
	
	function redeemEarlyAll() public {
	   //check if available to redeem and transfer if available
       uint256 returnAmount;
	   uint256 returnAmount2;
	   uint256 returnAmountTotal;
	   uint256 returnAmountTotal2;
	   uint i;
	   ERC20 tokenERC20t2;
	   ERC20 tokenERC20;
	  
	   for (i=0;i<transactions[msg.sender].length;i++)
	   {
			if (transactions[msg.sender][i].redeemed==false)
			{
				(returnAmount,returnAmount2) = redeemTrx(msg.sender,i);
				
				returnAmountTotal+= returnAmount;
				returnAmountTotal2+= returnAmount2;
				
				if (transactions[msg.sender][i].stakeEnd>block.timestamp)
				{
					if (transactions[msg.sender][i].token==token1) totalStaked1-=transactions[msg.sender][i].amount;
					else totalStaked2-=transactions[msg.sender][i].amount;
				
				}else{
					
					if (transactions[msg.sender][i].token==token1) 
					{
					 totalStaked1-=transactions[msg.sender][i].amount;
					 totalRedeemed1+=transactions[msg.sender][i].rewardAmt1; 
					}
					else
					{
					 totalStaked2-=transactions[msg.sender][i].amount;
					 totalRedeemed2+=transactions[msg.sender][i].rewardAmt2;
					}
					
				}
				
				
			}
	   }
	   
	    tokenERC20 = ERC20(token1);
		if (returnAmountTotal>0) tokenERC20.transfer(msg.sender, returnAmountTotal);
		tokenERC20t2 = ERC20(token2);
		if (returnAmountTotal2>0) tokenERC20t2.transfer(msg.sender, returnAmountTotal2);
	   
	   emit EarlyRedeemedAll(msg.sender,block.timestamp, returnAmountTotal,returnAmountTotal2);
		
    }
	
	function transferReward(address token, uint256 reward_amount) public {
	
	   require(reward_amount>0,"Reward amount is 0");
	   
	   ERC20 tokenERC20 = ERC20(token);
	   //uint256 allowance = tokenERC20.allowance(msg.sender,address(this));
	   //require(allowance>=reward_amount,"Transfer not approved!");
	   tokenERC20.transferFrom(msg.sender,address(this), reward_amount);
	   if (token==token1) amtRewardRemainingBalance1 = SafeMath.add(amtRewardRemainingBalance1, reward_amount);
	   if (token==token2) amtRewardRemainingBalance2 = SafeMath.add(amtRewardRemainingBalance2, reward_amount);
	  
	   emit TransferReward(msg.sender,block.timestamp, reward_amount);
    }
	
	function transferBackReward(address token, uint256 reward_amount) onlyOwner public {
	
	   require(reward_amount>0 && stakingStarted==false,"Reward amount is 0 or staking is activated");
	   require(openRewards1==0 && openRewards2==0,"There are open rewards");
	   
	   ERC20 tokenERC20 = ERC20(token);
	  
	   if (token==token1) 
	   {
		if (reward_amount>SafeMath.sub(amtRewardRemainingBalance1, openRewards1)) reward_amount = SafeMath.sub(amtRewardRemainingBalance1, openRewards1);
		amtRewardRemainingBalance1 = SafeMath.sub(amtRewardRemainingBalance1, reward_amount);
		
	   }
	   if (token==token2) 
	   {
		if (reward_amount>SafeMath.sub(amtRewardRemainingBalance2, openRewards2)) reward_amount = SafeMath.sub(amtRewardRemainingBalance2, openRewards2);
	    amtRewardRemainingBalance2 = SafeMath.sub(amtRewardRemainingBalance2, reward_amount);
	   }
	   tokenERC20.transfer(msg.sender, reward_amount);
	   
	   emit TransferBackReward(msg.sender,block.timestamp, reward_amount);
    }
	
    
    function info() public view returns(address,uint256,uint256,uint256,uint256,uint256,uint256){
        return (owner,createdAt,apy,duration,rewardAmt1,interestRate,tokenRatio);
    }
	function getRewardsInfo() public view returns(address,address,uint256,uint256,uint256,uint256){ 
        return (token1,token2,rewardAmt1,rewardAmt2,amtRewardRemainingBalance1,amtRewardRemainingBalance2);
    }
	function getStakeRewardAmounts() public view returns(uint256,uint256,uint256,uint256,uint256,uint256){ 
        return (totalStaked1,totalStaked2,openRewards1,openRewards2,maxStakeAmt1,maxStakeAmt2);
    }
	function getMyInfo() public view returns(Transaction [] memory,MaxLimit memory){ 
        return (transactions[msg.sender],limits[msg.sender]);
    }
	function getMyStakings() public view returns(Transaction [] memory){ 
        return (transactions[msg.sender]);
    }
	function getStakings(address wallet) public view onlyOwner returns(Transaction [] memory){ 
        return (transactions[wallet]);
    }
	function getMyLimits() public view returns(MaxLimit memory){ 
        return (limits[msg.sender]);
    }
	function getBlackListedStatus(address wallet) public view returns(bool){ 
        
		return (blackListed[wallet]);
    }
	
	event CreatedContract(address token1,address token2,uint256 apy,uint256 duration,uint256 maxStakeAmt1, uint256 maxStakeAmt2, uint256 rewardAmt1,uint256 rewardAmt2,address owner,uint256 createdAt,uint256 interestRate,uint256 tokenRatio);
    event Received(address from, uint256 amount);
	event Reverted(address from, uint256 amount);
	event StartStaking(address from,uint256 startDate);
	event StopStaking(address from,uint256 stopDate);
	event Staked(address from,address tokenCtr,uint256 amount);
	event EarlyRedeemed(address to,uint256 redeemedDate,uint256 amount);
	event EarlyRedeemedAll(address to,uint256 redeemedDate,uint256 amount1,uint256 amount2);
	event Redeemed(address to,uint256 redeemedDate,uint256 amount1,uint256 amount2);
	event RedeemedAll(address to,uint256 redeemedDate,uint256 amount1,uint256 amount2);
	event TransferReward(address from,uint256 sentDate,uint256 amount);
	event TransferBackReward(address to,uint256 sentDate,uint256 amount);
	event AddedToBlackList(address from, uint256 sentDate);
	event RemovedFromBlackList(address from, uint256 sentDate);
}