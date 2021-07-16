//SourceUnit: contract.sol

pragma solidity ^0.5.10;



contract TronAvenger{

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


    uint balanceRef;

    Deposit[] deposits;

    uint invested;

    uint paidAt;
    
    uint investedAt;
    
    uint boosterInvestment;
    
    uint totalEarningSoFar;

    uint withdrawn;
    
    uint userplan;
    
    bool firstWithdrawal;
    
    bool compoundBonus;
    
    uint contractBonus;
    
    uint compoundingBonus;
    
  }

  

  struct InvestorReferral {

  

    uint referralsAmt_tier1;

    uint referralsAmt_tier2;

    uint referralsAmt_tier3;

    uint referralsAmt_tier4;
    
    uint referralsAmt_tier5;

    uint referralsAmt_tier6;

  
    uint referrals_tier1;

    uint referrals_tier2;

    uint referrals_tier3;

    uint referrals_tier4;
    
    uint referrals_tier5;
    
    uint referrals_tier6;

  }
  
  

 

    


  bool inValidTariffs;

  address public owner = msg.sender;

  

  Tariff[] public tariffs;

  uint[] public refRewards;
  
  address[] public investors_address_list;

  uint public totalInvestors;
  
  uint public contractAmtForBonus;

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
      investors[msg.sender].investedAt = block.timestamp;
      investors_address_list.push(msg.sender);
      
      

      totalInvestors++;

      

      if (investors[referer].registered && referer != msg.sender) {

        investors[msg.sender].referer = referer;

        

        address rec = referer;

        for (uint i = 0; i < refRewards.length; i++) {

          if (!investors[rec].registered) {

            break;

          }

          

          if (i == 0) {

            investorreferrals[rec].referrals_tier1++;
            investors[rec].boosterInvestment += msg.value;
          
            

          }

          if (i == 1) {

            investorreferrals[rec].referrals_tier2++;

          }

          if (i == 2) {

            investorreferrals[rec].referrals_tier3++;

          }

          if (i == 3) {

            investorreferrals[rec].referrals_tier4++;

          }
          if (i == 4) {

            investorreferrals[rec].referrals_tier5++;

          }
          if (i == 5) {

            investorreferrals[rec].referrals_tier6++;

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

          refRewardPercent = 10;

      }

      else if(i==1){

          refRewardPercent = 5;

      }

      else if(i==2){

          refRewardPercent = 2;

      }

      else if(i==3){

           refRewardPercent = 1;

      }
      else if(i==4){

           refRewardPercent = 1;

      }
      else if(i==5){

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

           investorreferrals[rec].referralsAmt_tier4 += a;

      }
      else if(i==4){

           investorreferrals[rec].referralsAmt_tier5 += a;

      }
      else if(i==5){

           investorreferrals[rec].referralsAmt_tier6 += a;

      }
      

      investors[rec].balanceRef += a;

      
      investors[rec].totalEarningSoFar += a;  
      totalRefRewards += a;
        
      

      rec = investors[rec].referer;

    }

  }

  

  

  constructor() public {

    tariffs.push(Tariff(30 * 28800, 255));
    tariffs.push(Tariff(25 * 28800, 237));

    tariffs.push(Tariff(16 * 28800, 200));
    tariffs.push(Tariff(12 * 28800, 162));


    

    for (uint i = 6; i >= 1; i--) {

      refRewards.push(i);

    }

  }

  

  function deposit(uint tariff, address referer) external payable {

   require(tariff < tariffs.length);
    

	if(investors[msg.sender].registered){
        require(msg.value >= 1);
		require(investors[msg.sender].userplan == tariff);

	}
	else {
	     require(msg.value >= 10);
	     investors[msg.sender].userplan = tariff;
	}

		register(referer);

    	investors[msg.sender].invested += msg.value;
       
		totalInvested += msg.value;
		
		contractAmtForBonus += msg.value;

		investors[msg.sender].deposits.push(Deposit(tariff, msg.value, block.number));
        
        contractBonusDistribution();
        
		emit DepositAt(msg.sender, tariff, msg.value);

 }

  

 function reinvest() external  {
    require(investors[msg.sender].registered);
    
    uint amount = profit();

    require(amount >= 1 trx);
    
    if(investors[msg.sender].compoundBonus == true){
        uint compoundingBonus = amount*10/100;
        investors[msg.sender].compoundingBonus += compoundingBonus;
        amount +=compoundingBonus;
    }
    investors[msg.sender].invested += amount;

    totalInvested += amount;

    uint tariff = investors[msg.sender].deposits[0].tariff;

	investors[msg.sender].deposits.push(Deposit(tariff, amount, block.number));

    investors[msg.sender].withdrawn += amount;

    emit Reinvest(msg.sender,tariff, amount);

  } 


  function profit() internal returns (uint) {

    Investor storage investor = investors[msg.sender];

    

    uint amount = withdrawable(msg.sender);

    
    investor.totalEarningSoFar += amount;
    amount += investor.balanceRef;
    amount += investor.contractBonus;
    investor.balanceRef = 0;
    investor.contractBonus = 0;
    

    investor.paidAt = block.number;

    

    return amount;

  }

  

  function withdraw() external {
    
    uint amount = profit();
    require(amount >= 10 trx);
 

    if (msg.sender.send(amount)) {
    
        bool userFirstWithdrawal = investors[msg.sender].firstWithdrawal;
        uint getTime = block.timestamp - investors[msg.sender].investedAt;
        if(userFirstWithdrawal == false && getTime > 24 hours){
            investors[msg.sender].compoundBonus = true;
        }
        investors[msg.sender].firstWithdrawal = true;
    
      investors[msg.sender].withdrawn += amount;

      totalWithdrawal +=amount;

      emit Withdraw(msg.sender, amount);

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
  
  
   function contractBonusDistribution() internal {
        if(contractAmtForBonus >= 1000000 trx) {
            uint distributeAmt = contractAmtForBonus/1000;
            uint eachUserBonus = distributeAmt/totalInvestors;
            for(uint i = 0; i < investors_address_list.length; i++) {
                
                address userAddr = investors_address_list[i];
                investors[userAddr].contractBonus += eachUserBonus;
                
            }
            contractAmtForBonus = 0;
            
        }
       
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

   function myData() public view returns (uint,uint,uint,uint,uint,uint,uint) {

    Investor storage investor = investors[msg.sender];
     
     uint profitAmount = withdrawable(msg.sender);
     uint myplan = investors[msg.sender].userplan;
     uint invested = investor.invested;
	 uint balanceRef = investor.balanceRef;
	 uint contractBonus = investor.contractBonus;
	 uint compoundingBonus = investor.compoundingBonus;
     uint totalIncome = balanceRef + profitAmount +contractBonus;
     
     uint withdrawn = investor.withdrawn;
	 return (myplan,invested,balanceRef,totalIncome,withdrawn,contractBonus,compoundingBonus);

    

  }



  

   function referralLevelBalanceAndCount() public view returns (uint,uint,uint,uint,uint,uint) {
    

     InvestorReferral storage investorreferral = investorreferrals[msg.sender];

    

	 uint levelOne = investorreferral.referralsAmt_tier1;

	 uint levelTwo = investorreferral.referralsAmt_tier2;

	 uint levelThree = investorreferral.referralsAmt_tier3;

	 uint levelFour = investorreferral.referralsAmt_tier4;
	 
	  uint levelFive = investorreferral.referralsAmt_tier5;
	  
	 uint levelSix = investorreferral.referralsAmt_tier6;

	 return (levelOne,levelTwo,levelThree,levelFour,levelFive,levelSix);

    

    }


   function referralLevelCount() public view returns (uint,uint,uint,uint,uint,uint) {
    
     InvestorReferral storage investorreferral = investorreferrals[msg.sender];

    

	 uint levelOneCnt = investorreferral.referrals_tier1;

	 uint levelTwoCnt = investorreferral.referrals_tier2;

	 uint levelThreeCnt = investorreferral.referrals_tier3;

	 uint levelFourCnt = investorreferral.referrals_tier4;
	 
	 uint levelFiveCnt = investorreferral.referrals_tier5;
	 
	 uint levelSixCnt = investorreferral.referrals_tier6;
   

	 return (levelOneCnt,levelTwoCnt,levelThreeCnt,levelFourCnt,levelFiveCnt,levelSixCnt);

    

    }
    

    


}