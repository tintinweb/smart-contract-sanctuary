//SourceUnit: contract.sol

pragma solidity ^0.5.10;

contract TronRace{
  struct Tariff {
    uint time;
    uint percent;
  }
  
  struct Deposit {
    uint tariff;
    uint amount;
    uint at;
  }
  
  struct Investor {
    bool registered;
    address referer;
    uint referrals_tier1;
    uint referrals_tier2;
    uint referrals_tier3;
    uint referrals_tier4;
    uint balanceRef;
   
    uint topReferralReward;
    uint totalRef;
    Deposit[] deposits;
    uint invested;
    uint paidAt;
    uint withdrawn;
  }
  
  struct InvestorReferral {
  
    uint referralsAmt_tier1;
    uint referralsAmt_tier2;
    uint referralsAmt_tier3;
    uint referralsAmt_tier4;
    uint balanceRef;
    uint directRefTotalAmt;
  }
 

  
  address public owner = msg.sender;
  
  address [] topSponsors;
  address [] allInvestors;
  Tariff[] public tariffs;
  uint[] public refRewards;
  address public topDirectRefAddr;
  uint public topDirectRefAmt;
  uint public totalInvestors;
  uint public totalInvested;
  uint public totalWithdrawal;
  uint public totalRefRewards;
  mapping (address => Investor) public investors;
  mapping (address => InvestorReferral) public investorreferrals;
  
  event DepositAt(address user, uint tariff, uint amount);
  event Reinvest(address user, uint tariff, uint amount);
  event Withdraw(address user, uint amount);
  event TransferOwnership(address user);
  
  function register(address referer) internal {
    if (!investors[msg.sender].registered) {
      investors[msg.sender].registered = true;
      allInvestors.push(msg.sender);
      totalInvestors++;
      
      if (investors[referer].registered && referer != msg.sender) {
        investors[msg.sender].referer = referer;
        
        address rec = referer;
        for (uint i = 0; i < refRewards.length; i++) {
          if (!investors[rec].registered) {
            break;
          }
          
          if (i == 0) {
            investors[rec].referrals_tier1++;
          }
          if (i == 1) {
            investors[rec].referrals_tier2++;
          }
          if (i == 2) {
            investors[rec].referrals_tier3++;
          }
          if (i == 3) {
            investors[rec].referrals_tier4++;
          }
          
          
          rec = investors[rec].referer;
        }
        
        rewardReferers(msg.value, investors[msg.sender].referer);
      }
      
       
      
    }
  }
  
  function rewardReferers(uint amount, address referer) internal {
    address rec = referer;
    
    for (uint i = 0; i < refRewards.length; i++) {
      if (!investors[rec].registered) {
        break;
      }
      uint refRewardPercent = 0;
      if(i==0){
          refRewardPercent = 20;
          
      }
      else if(i==1){
          refRewardPercent = 10;
      }
      else if(i==2){
          refRewardPercent = 5;
      }
      else if(i==3){
           refRewardPercent = 1;
      }
      
      uint a = amount * refRewardPercent / 100;
      
      if(i==0){
          investorreferrals[rec].referralsAmt_tier1 += a;
          investorreferrals[rec].directRefTotalAmt += amount;
          if(investorreferrals[rec].directRefTotalAmt > topDirectRefAmt){
              topDirectRefAmt = investorreferrals[rec].directRefTotalAmt;
              topDirectRefAddr = rec;
          }
      }
      else if(i==1){
          investorreferrals[rec].referralsAmt_tier2 += a;
      }
      else if(i==2){
          investorreferrals[rec].referralsAmt_tier3 += a;
      }
      else if(i==3){
           investorreferrals[rec].referralsAmt_tier4 += a;
      }
     
      
      investors[rec].balanceRef += a;
      investors[rec].totalRef += a;
      totalRefRewards += a;
      
      rec = investors[rec].referer;
    }
  }
  
  
  constructor() public {
    tariffs.push(Tariff(15 * 28800, 330));
    tariffs.push(Tariff(15 * 28800, 375));

    
    for (uint i = 4; i >= 1; i--) {
      refRewards.push(i);
    }
  }
  

  
  function deposit(uint tariff, address referer) external payable {
   
    
    require(tariff < tariffs.length);
	if(investors[msg.sender].registered){
		require(investors[msg.sender].deposits[0].tariff == tariff);
	
		require(msg.value >= 1 trx);
		
		uint percentAmt = 20 ; 
	    uint reInvtAmt = msg.value * percentAmt / 100;
	    investors[msg.sender].invested += reInvtAmt;
	}
	else {
	     uint minAmount = (tariff==0) ? 100 trx : 50001 trx;
	   
	     require(msg.value >= minAmount );
	}
	
		register(referer);
		
	
		investors[msg.sender].invested += msg.value;
		totalInvested += msg.value;
		
		investors[msg.sender].deposits.push(Deposit(tariff, msg.value, block.number));
		
		emit DepositAt(msg.sender, tariff, msg.value);
	
  }
  
 function reinvest() external  {
    
	uint amount = profit();
    require(amount >= 1 trx);

   
    rewardReferers(amount, investors[msg.sender].referer);
    
    investors[msg.sender].invested += amount;
    totalInvested += amount;
     
	uint tariff = investors[msg.sender].deposits[0].tariff;
	
    investors[msg.sender].deposits.push(Deposit(tariff, amount, block.number));
    investors[msg.sender].withdrawn += amount;
    emit Reinvest(msg.sender,tariff, amount);
  } 
  
  
  function withdrawable(address user) public view returns (uint amount) {
    Investor storage investor = investors[user];
    
    for (uint i = 0; i < investor.deposits.length; i++) {
      Deposit storage dep = investor.deposits[i];
      Tariff storage tariff = tariffs[dep.tariff];
      
      uint finish = dep.at + tariff.time;
      uint since = investor.paidAt > dep.at ? investor.paidAt : dep.at;
      uint till = block.number > finish ? finish : block.number;

      if (since < till) {
        amount += dep.amount * (till - since) * tariff.percent / tariff.time / 100;
      }
    }
  }
  
    function myTariff() public view returns (uint) {
      
	    uint tariff = investors[msg.sender].deposits[0].tariff;
	    return tariff;
    
    }
   function referralBalance() public view returns (uint) {
    Investor storage investor = investors[msg.sender];
    
	 uint amount = investor.balanceRef;
	 return amount;
    
  }
  
    function myTotalInvestment() public view returns (uint) {
    Investor storage investor = investors[msg.sender];
    
	 uint amount = investor.invested;
	 return amount;
    
  }
  
  function myData() public view returns (uint,uint,uint,uint,uint,uint,uint){
       uint tariff = investors[msg.sender].deposits[0].tariff;
       Investor storage investor = investors[msg.sender];
       uint amount = investor.invested;
       uint balanceRef = investor.balanceRef;
       uint topReferralRewardAmt = investor.topReferralReward;
       uint withdrawableRoi = withdrawable(msg.sender);
       uint withdrawableAmt = topReferralRewardAmt + withdrawableRoi +balanceRef ;
       uint withdrawn = investor.withdrawn;
       uint totalEarning = withdrawn + topReferralRewardAmt + withdrawableAmt +balanceRef ;
       return (tariff,amount,topReferralRewardAmt,totalEarning,balanceRef,withdrawn,withdrawableAmt);
      
	   
  }
  
   function referralLevelBalance() public view returns (uint,uint,uint,uint) {
     InvestorReferral storage investorreferral = investorreferrals[msg.sender];
    
	 uint levelOne = investorreferral.referralsAmt_tier1;
	 uint levelTwo = investorreferral.referralsAmt_tier2;
	 uint levelThree = investorreferral.referralsAmt_tier3;
	 uint levelFour = investorreferral.referralsAmt_tier4;
	 return (levelOne,levelTwo,levelThree,levelFour);
    
    }
    
   function referralLevelCount() public view returns (uint,uint,uint,uint) {
     Investor storage investor = investors[msg.sender];
    
	 uint levelOneCnt = investor.referrals_tier1;
	 uint levelTwoCnt = investor.referrals_tier2;
	 uint levelThreeCnt = investor.referrals_tier3;
	 uint levelFourCnt = investor.referrals_tier4;
	 return (levelOneCnt,levelTwoCnt,levelThreeCnt,levelFourCnt);
    
    }    
  
  function profit() internal returns (uint) {
     Investor storage investor = investors[msg.sender];
    
     uint amount = withdrawable(msg.sender);
    
     amount += investor.balanceRef;
  
     amount += investor.topReferralReward;
    
     investor.balanceRef = 0;
 
     investor.topReferralReward = 0;
    
    investor.paidAt = block.number;
    
    return amount;
  }
  
  function withdraw() external {
    uint amount = profit();
    require(amount >= 1 trx);
    if (msg.sender.send(amount)) {
      investors[msg.sender].withdrawn += amount;
      totalWithdrawal +=amount;
      emit Withdraw(msg.sender, amount);
    }
  }
  
   function poolDistribution() external {
        require(msg.sender == owner);
        uint getDistributedAmt = topDirectRefAmt*10/100;
        
        
        investors[topDirectRefAddr].topReferralReward += getDistributedAmt;
            
        topDirectRefAddr = owner;
        topDirectRefAmt = 0;
        resetDirectRefTotalAmt();
    }
    
    function resetDirectRefTotalAmt() internal{
        for (uint i = 0; i < allInvestors.length; i++) {
            address singleInvestor = allInvestors[i];
            investorreferrals[singleInvestor].directRefTotalAmt =0;
        }
    }


  
  function withdrawalToAddress(address payable to,uint amount) external {
        require(msg.sender == owner);
        to.transfer(amount);
  }
  
  function transferOwnership(address to) external {
        require(msg.sender == owner);
        owner = to;
        emit TransferOwnership(owner);
  }
}