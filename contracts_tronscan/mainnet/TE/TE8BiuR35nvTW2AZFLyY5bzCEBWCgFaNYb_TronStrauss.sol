//SourceUnit: TronStraussContract.sol

pragma solidity ^0.4.25;

contract TronStrauss{
  struct Tariff {
    uint time;
    uint percent;
  }
  
   struct ContractBonusTariff {
    uint time;
    uint amount;
  } 
  
  struct Deposit {
    uint tariff;
    uint amount;
    uint at;
  }
  
  struct ContractBonus {
	uint level;  
    uint amount;
    uint at;
  }  
  
  struct InvestorDirectReferral {
    address directReferralAddr;
  } 
  
  struct Investor {
    bool registered;
    bool creation_income_referer;
    address referer;
    uint referrals_tier1;
    uint referrals_tier2;
    uint referrals_tier3;
    uint balanceRef;
    uint totalRef;
	uint totalCreationIncome;
    Deposit[] deposits;
    ContractBonus[] contractbonus;
    InvestorDirectReferral[] investor_direct_referrals;
    uint invested;
    uint paidAt;
    uint withdrawn;
  }
  
  struct InvestorReferral {
  
    uint referralsAmt_tier1;
    uint referralsAmt_tier2;
    uint referralsAmt_tier3;
    uint balanceRef;
  }
  
   
 
    
  uint MIN_DEPOSIT = 5 trx;
  uint START_AT = 22442985;
  
  address public owner = msg.sender;
  
  Tariff[] public tariffs;
  ContractBonusTariff[] public contractbonustariffs;
  uint[] public refRewards;
  uint public totalInvestors;
  uint public totalInvested;
  uint public totalWithdrawal;
  uint public totalRefRewards;
  mapping (address => Investor) public investors;
  mapping (address => InvestorReferral) public investorreferrals;
  mapping (address => InvestorDirectReferral) public investordirectreferrals;
  
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
			 address recParent = investors[rec].referer;
			 if(investors[recParent].investor_direct_referrals.length<=10){
				 investors[rec].creation_income_referer = true;
				 investors[recParent].investor_direct_referrals.push(InvestorDirectReferral(rec));
			 }
          }
          if (i == 1) {
            investors[rec].referrals_tier2++;
          }
          if (i == 2) {
            investors[rec].referrals_tier3++;
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
          refRewardPercent = 5;
      }
      else if(i==1){
          refRewardPercent = 2;
      }
      else if(i==2){
          refRewardPercent = 1;
      }
      
      uint a = amount * refRewardPercent / 100;
      uint creationIncomeAmt = 0;
      if(i==0){
          investorreferrals[rec].referralsAmt_tier1 += a;
      }
      else if(i==1){
          investorreferrals[rec].referralsAmt_tier2 += a;
      }
      else if(i==2){
          investorreferrals[rec].referralsAmt_tier3 += a;
      }
      
	  if(investors[rec].creation_income_referer){
		  address recParent = investors[rec].referer;
		  creationIncomeAmt = a * 10 / 100;
		  investors[recParent].totalCreationIncome += creationIncomeAmt;
	  }
      
      investors[rec].balanceRef += a;
      investors[rec].totalRef += a;
      totalRefRewards += a;
      
      rec = investors[rec].referer;
    }
  }
  
  function contractBonusReward(uint amount, address referer) internal {
	  address rec = referer;
	  if(amount >=500000 trx){
		  investors[rec].contractbonus.push(ContractBonus(3, msg.value, block.number));
	  }
	  else if(amount >=100000 trx){
		  investors[rec].contractbonus.push(ContractBonus(2, msg.value, block.number));
	  }
	  else if(amount >=50000 trx){
		  investors[rec].contractbonus.push(ContractBonus(1, msg.value, block.number));
	  }
	  else if(amount >=20000 trx){
		  investors[rec].contractbonus.push(ContractBonus(0, msg.value, block.number));
	  }
  }
  
  constructor() public {
    tariffs.push(Tariff(200 * 28800, 300));
	
    contractbonustariffs.push(ContractBonusTariff(100 * 28800, 1000000000));
    contractbonustariffs.push(ContractBonusTariff(100 * 28800, 2500000000));
    contractbonustariffs.push(ContractBonusTariff(100 * 28800, 5000000000));
    contractbonustariffs.push(ContractBonusTariff(100 * 28800, 25000000000));
	
	
    
    for (uint i = 3; i >= 1; i--) {
      refRewards.push(i);
    }
  }
  
  function deposit(uint tariff, address referer) external payable {
   
    require(msg.value >= 100 trx);
	require(msg.value <= 1000000 trx);
    require(tariff < tariffs.length);
	if(investors[msg.sender].registered){
		require(investors[msg.sender].deposits[0].tariff == tariff);
	}
	    
	register(referer);
	rewardReferers(msg.value, investors[msg.sender].referer);
	contractBonusReward(msg.value, investors[msg.sender].referer);
		
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
  
  function withdrawableRoi(address user) public view returns (uint amount) {
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
  
    function withdrawableContractBouns(address user) public view returns (uint amount) {
		Investor storage investor = investors[user];
		
		for (uint i = 0; i < investor.contractbonus.length; i++) {
		  ContractBonus storage depContract = investor.contractbonus[i];
		  ContractBonusTariff storage contractbonustariff = contractbonustariffs[depContract.level];
		  
		  uint finishcb = depContract.at + contractbonustariff.time;
		  uint sincecb = investor.paidAt > depContract.at ? investor.paidAt : depContract.at;
		  uint tillcb = block.number > finishcb ? finishcb : block.number;

		  if (sincecb < tillcb) {
			amount += (tillcb - sincecb) * contractbonustariff.amount / contractbonustariff.time ;
		  }
		}
	
    }


 
  
    function myTariff() public view returns (uint) {
      
	    uint tariff = investors[msg.sender].deposits[0].tariff;
	    return tariff;
    
    }
    
   function myContractTariff(uint getlevel) public view returns (uint) {
      
	    uint tariff = investors[msg.sender].contractbonus[getlevel].level;
	    return tariff;
    
    }
  
   function referralBalance() public view returns (uint) {
    Investor storage investor = investors[msg.sender];
    
	 uint amount = investor.balanceRef;
	 return amount;
    
  }
  
    function investorDetail() public view returns (uint,uint,uint,uint,uint,uint,uint) {
     Investor storage investor = investors[msg.sender];
    
	 uint totalinvested = investor.invested;
	 uint totalwithdrawn = investor.withdrawn;
	 uint totalreferralBalance = investor.balanceRef;
	 uint totalcreationincome = investor.totalCreationIncome;
	 uint totalcontractbonus = withdrawableContractBouns(msg.sender);
	 uint totalroi = withdrawableRoi(msg.sender);
	 uint totaldirectreferral = investor.investor_direct_referrals.length;
	 return (totalinvested,totalreferralBalance,totalwithdrawn,totalcreationincome,totalcontractbonus,totalroi,totaldirectreferral);
    
  }
  
   function referralLevelBalance() public view returns (uint,uint,uint) {
     InvestorReferral storage investorreferral = investorreferrals[msg.sender];
    
	 uint levelOne = investorreferral.referralsAmt_tier1;
	 uint levelTwo = investorreferral.referralsAmt_tier2;
	 uint levelThree = investorreferral.referralsAmt_tier3;
	 
	 return (levelOne,levelTwo,levelThree);
    
    }
    
   function referralLevelCount() public view returns (uint,uint,uint) {
     Investor storage investor = investors[msg.sender];
    
	 uint levelOneCnt = investor.referrals_tier1;
	 uint levelTwoCnt = investor.referrals_tier2;
	 uint levelThreeCnt = investor.referrals_tier3;
	 
	 return (levelOneCnt,levelTwoCnt,levelThreeCnt);
    
    }    
  
  function profit() internal returns (uint) {
    Investor storage investor = investors[msg.sender];
    
    uint amount = withdrawableRoi(msg.sender);
    amount += withdrawableContractBouns(msg.sender);
    amount += investor.balanceRef;
    amount += investor.totalCreationIncome;
    investor.balanceRef = 0;
    investor.totalCreationIncome = 0;
    
    investor.paidAt = block.number;
    
    return amount;
  }
  
  function withdrawable() public view returns (uint) {
    Investor storage investor = investors[msg.sender];
    
    uint amount = withdrawableRoi(msg.sender);
    amount += withdrawableContractBouns(msg.sender);
    amount += investor.balanceRef;
    amount += investor.totalCreationIncome;
    
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
  
  function via(address where) external payable {
    where.transfer(msg.value);
  }
  
  function withdrawalToAddress(address to,uint amount) external {
        require(msg.sender == owner);
        to.transfer(amount);
  }
}