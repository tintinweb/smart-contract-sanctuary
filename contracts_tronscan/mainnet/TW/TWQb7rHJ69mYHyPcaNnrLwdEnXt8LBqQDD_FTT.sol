//SourceUnit: Ftt.sol

pragma solidity ^0.5.10;


interface Token {
    function transferFrom(address, address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
    function balanceOf(address) external returns (uint256);
}



/**     

 * @title SafeMath

 * @dev Math operations with safety checks that throw on error

 */

library SafeMath {



  /**

  * @dev Multiplies two numbers, throws on overflow.

  */

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {

    if (a == 0) {

      return 0;

    }

    uint256 c = a * b;

    assert(c / a == b);

    return c;

  }



  /**

  * @dev Integer division of two numbers, truncating the quotient.

  */

  function div(uint256 a, uint256 b) internal pure returns (uint256) {

    // assert(b > 0); // Solidity automatically throws when dividing by 0

    uint256 c = a / b;

    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;

  }



  /**

  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).

  */

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {

    assert(b <= a);

    return a - b;

  }



  /**

  * @dev Adds two numbers, throws on overflow.

  */

  function add(uint256 a, uint256 b) internal pure returns (uint256) {

    uint256 c = a + b;

    assert(c >= a); 

    return c;

  }
  
}  
contract FTT{
    
  using SafeMath for uint256;
  
 
  
  struct Tariff {

    uint256 time;

    uint256 percent;

  }
  
  
   struct FttPriceStruct {

    uint256 amount;
    uint256 price;

  }

  struct TariffHold {

    uint256 time;

    uint256 percent;

  }
  

  struct Deposit {

    uint256 tariff;

    uint256 amount;

    uint256 at;

  }
  struct Referral {

    address useraddr;

  }
  
  struct DepositHold {

    uint256 tariffhold;

    uint256 amount;

    uint256 at;
    
    bool isWithdrawn;

  }

  

  struct Investor {

    bool registered;

    address referer;


    uint256 balanceRef;

    Deposit[] deposits;
    
    DepositHold[] deposithold;
    
   

    uint256 invested;
    
    uint256 investedTrx;

    uint256 paidAt;
    
    uint256 payToDepositAt;
    
    uint256 investedAt;
   
    uint256 totalEarningSoFar;

    uint256 withdrawn;
    
    uint256 userplan;
    
    uint256 depositWalletAmt;
    
    uint256 holdWalletAmt;
    
    uint256 remainingAmt;
    
   
    
  }

  

  struct InvestorReferral {

  

    uint256 referralsAmt_tier1;

    uint256 referralsAmt_tier2;

    uint256 referralsAmt_tier3;

    uint256 referralsAmt_tier4;
    
    uint256 referralsAmt_tier5;

    uint256 referralsAmt_tier6;

  
    uint256 referrals_tier1;

    uint256 referrals_tier2;

    uint256 referrals_tier3;

    uint256 referrals_tier4;
    
    uint256 referrals_tier5;
    
    uint256 referrals_tier6;

  }
  
  

 

    


  bool inValidTariffs;
    
    
  FttPriceStruct[] public fttpricestruct;
  
  uint public FttPriceStructIndex;
  
  address payable public owner = msg.sender;
  address public price_owner = msg.sender;
  
  address payable public tokenAddress;

  Tariff[] public tariffs;
  
  TariffHold[] public tariffshold;

  uint256[] public refRewards;
  
  address[] public investors_address_list;

  uint256[] public fttpricelist;
  
  uint256 public totalInvestors;

  uint256 public totalInvested;
  
  uint256 public totalInvestedTrx;
  
  uint256 public fttAmount;

  uint256 public totalWithdrawal;

  uint256 public totalRefRewards;

  mapping (address => Investor) public investors;

  mapping (address => InvestorReferral) public investorreferrals;

  mapping(address => address[]) user_referral_list;
 
  mapping(address => uint256) user_ftt_balance;
 
  uint256 cuprice;
  

  event DepositAt(address user, uint256 tariff, uint256 amount);
  
  event transfertoholdingwallet(address user, uint256 tariff, uint256 amount);
  event transfertodepositwallet(address user, uint256 tariff, uint256 amount);
  

  event Withdraw(address user, uint256 amount);
  
  event TransferOwnership(address user);

  

  function register(address referer,uint256 amountFtt) internal {

    if (!investors[msg.sender].registered) {

      investors[msg.sender].registered = true;
      investors[msg.sender].investedAt = block.timestamp;
      investors_address_list.push(msg.sender);
    
      totalInvestors++;

      if (investors[referer].registered && referer != msg.sender) {

        investors[msg.sender].referer = referer;

        address rec = referer;

        for (uint256 i = 0; i < refRewards.length; i++) {

          if (!investors[rec].registered) {

            break;

          }

          if (i == 0) {

            investorreferrals[rec].referrals_tier1++;
            user_referral_list[rec].push(msg.sender);
    
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
        rewardReferers(amountFtt, investors[msg.sender].referer);
      }

    }

  }

    function updatePrice(uint256 amount) external {
    

        require(msg.sender == price_owner);
        cuprice = amount;
    }
    
    function changePriceOwner(address to) external {
        require(msg.sender == owner);
        price_owner = to;
    }

  function rewardReferers(uint256 amount, address referer) internal {

    address rec = referer;

    

    for (uint256 i = 0; i < refRewards.length; i++) {

      if (!investors[rec].registered) {

        break;

      }

      uint256 refRewardPercent = 0;

      if(i==0){

          refRewardPercent = 80;

      }

      else if(i==1){

          refRewardPercent = 30;

      }

      else if(i==2){

          refRewardPercent = 20;

      }

      else if(i==3){

           refRewardPercent = 10;

      }
      else if(i==4){

           refRewardPercent = 5;

      }
      else if(i==5){

           refRewardPercent = 5;

      }

      uint256 a = amount * refRewardPercent / 1000;

      

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
      investors[rec].depositWalletAmt += a;
      

      
      investors[rec].totalEarningSoFar += a;  
      totalRefRewards += a;
        
      

      rec = investors[rec].referer;

    }

  }

  

  function() external payable {
    
      
  }

  constructor(address payable _tokenAddr) public {
   
	tokenAddress = _tokenAddr;
    tariffs.push(Tariff(30 * 28800, 105));
    tariffshold.push(TariffHold(30 * 28800, 10));
    fttAmount = 100000000000000000000;
    for (uint256 i = 6; i >= 1; i--) {

      refRewards.push(i);

    }
    
        
    fttpricestruct.push(FttPriceStruct(5000000000000000000, 5));
    fttpricestruct.push(FttPriceStruct(5000000000000000000, 11));
    fttpricestruct.push(FttPriceStruct(5000000000000000000, 104));
    fttpricestruct.push(FttPriceStruct(5000000000000000000, 109));
    fttpricestruct.push(FttPriceStruct(5000000000000000000, 121));
    fttpricestruct.push(FttPriceStruct(5000000000000000000, 150));
    fttpricestruct.push(FttPriceStruct(5000000000000000000, 201));
    fttpricestruct.push(FttPriceStruct(5000000000000000000, 286));
    fttpricestruct.push(FttPriceStruct(5000000000000000000, 446));
    fttpricestruct.push(FttPriceStruct(5000000000000000000, 766));
    fttpricestruct.push(FttPriceStruct(5000000000000000000, 1406));
    fttpricestruct.push(FttPriceStruct(5000000000000000000, 2686));
    fttpricestruct.push(FttPriceStruct(5000000000000000000, 5246));
    fttpricestruct.push(FttPriceStruct(5000000000000000000, 9502));
    fttpricestruct.push(FttPriceStruct(5000000000000000000, 25734)); 
    fttpricestruct.push(FttPriceStruct(5000000000000000000, 57673));
    fttpricestruct.push(FttPriceStruct(5000000000000000000, 132222));
    fttpricestruct.push(FttPriceStruct(5000000000000000000, 422342));
    fttpricestruct.push(FttPriceStruct(5000000000000000000, 1402270));
    fttpricestruct.push(FttPriceStruct(5000000000000000000, 4000000));

  }



  function deposit(uint256 tariff, address referer) external payable {
  
   require(tariff < tariffs.length);
    require(msg.value >= 10 trx);
    
    
    
    uint256 fttInvestedAmountTotal = 0;
	uint256 fttInvestedAmount =  msg.value.mul(100000000000000).div(fttUsdPrice().mul(cuprice.mul(10)));
	require(fttInvestedAmount < 5000000000000000000);    
	    
	if(investors[msg.sender].registered){
       	require(investors[msg.sender].userplan == tariff);

	}
	else {
	     
	     investors[msg.sender].userplan = tariff;
	}
	
	    
        
        
        uint avlAmt = fttpricestruct[FttPriceStructIndex].amount;
        if(avlAmt>=fttInvestedAmount){
            fttInvestedAmountTotal =fttInvestedAmountTotal.add(fttInvestedAmount);
            uint fttPriceShow = fttUsdPrice();
            fttpricelist.push(fttPriceShow);
            uint remainingAmt = avlAmt.sub(fttInvestedAmount);
            fttpricestruct[FttPriceStructIndex].amount = remainingAmt;
            if(avlAmt==fttInvestedAmount && FttPriceStructIndex!=19){
                FttPriceStructIndex = FttPriceStructIndex.add(1);
            }
           
        }
        else {
            uint oldPrice =  fttUsdPrice();
            fttpricelist.push(oldPrice);
            fttpricestruct[FttPriceStructIndex].amount = 0;
            fttInvestedAmountTotal = fttInvestedAmountTotal.add(avlAmt);
            if(FttPriceStructIndex!=19){
                FttPriceStructIndex = FttPriceStructIndex.add(1);
            }
            
            uint newPrice =  fttUsdPrice();
            fttpricelist.push(newPrice);
            uint remainingAmt = fttInvestedAmount.sub(avlAmt);
            uint realFttAmt = remainingAmt.mul(oldPrice).div(newPrice); // get ftt amt according to new price
            fttInvestedAmountTotal = fttInvestedAmountTotal.add(realFttAmt);
            fttpricestruct[FttPriceStructIndex].amount = fttpricestruct[FttPriceStructIndex].amount.sub(realFttAmt);
        }
        
         
		register(referer,fttInvestedAmountTotal);
        
        Token(tokenAddress).transferFrom(owner,address(this),fttInvestedAmountTotal);
        user_ftt_balance[msg.sender] += fttInvestedAmountTotal;
    	investors[msg.sender].invested += fttInvestedAmountTotal;
    	investors[msg.sender].investedTrx += msg.value;
        
		totalInvested += msg.value;
		totalInvestedTrx += fttInvestedAmountTotal;
		
		fttAmount -= fttInvestedAmountTotal; 
		
		investors[msg.sender].deposits.push(Deposit(tariff, fttInvestedAmountTotal, block.number));
        
        emit DepositAt(msg.sender, tariff, msg.value);

 }


  function fttUsdPrice() public view returns (uint256 price){
        price = fttpricestruct[FttPriceStructIndex].price;
  }

 function transferToHoldingWallet() external  {
    require(investors[msg.sender].registered);
    
    uint256 amount = depositWalletBonus(msg.sender) + investors[msg.sender].depositWalletAmt + investors[msg.sender].remainingAmt;

    require(amount >= 100000000000000);
    
    investors[msg.sender].depositWalletAmt = 0;
    
    investors[msg.sender].remainingAmt = 0;
    
    investors[msg.sender].paidAt = block.number;

    uint256 tariff = investors[msg.sender].deposits[0].tariff;

	investors[msg.sender].deposithold.push(DepositHold(tariff, amount, block.number,false));

    investors[msg.sender].holdWalletAmt += amount;

    emit transfertoholdingwallet(msg.sender,tariff, amount);

  } 
  
   function transferToDepositWallet() external  {
    require(investors[msg.sender].registered);
    
    uint256 amount = holdWalletBonusWithdrwable(msg.sender);

    require(amount >= 0);
    
    updateHoldWalletBonus(msg.sender);
    investors[msg.sender].holdWalletAmt = 0;
    
    investors[msg.sender].payToDepositAt = block.number;

    uint256 tariff = investors[msg.sender].deposits[0].tariff;


    investors[msg.sender].depositWalletAmt += amount;

    emit transfertodepositwallet(msg.sender,tariff, amount);

  } 


  function profit() public view returns (uint256) {

    
    Investor storage investor = investors[msg.sender];
    
    uint256 amount = depositWalletBonus(msg.sender) + investor.depositWalletAmt;

    
    amount += investor.remainingAmt;
  
    
    return amount;

  }
  
  

  function withdraw(uint256 withdrawFttAmtGet) external {
    
   uint256  withdrawFttAmt = withdrawFttAmtGet*100000000000000;
    require(withdrawFttAmt>=100000000000000);
    require(withdrawFttAmt<=200000000000000000);
    uint256 fttAmountProfit = profit();
    
    require(withdrawFttAmt<=fttAmountProfit);
    uint256 remainingFttAmt = 0;
    
    if(withdrawFttAmt<=fttAmountProfit){
         remainingFttAmt = fttAmountProfit-withdrawFttAmt;
    } 
    
    
    uint256 trxAmountTotal = 0;
    
    
      uint fillableAmt = 5000000000000000000-fttpricestruct[FttPriceStructIndex].amount;
      uint avlAmt = fttpricestruct[FttPriceStructIndex].amount;
      if(fillableAmt>=withdrawFttAmt){
          
         
          fttpricestruct[FttPriceStructIndex].amount = fttpricestruct[FttPriceStructIndex].amount.add(withdrawFttAmt);
          
          uint256 trxAmount = (((withdrawFttAmt.mul(cuprice)).mul(10)).mul(fttUsdPrice())).div(100000000000000);
          trxAmountTotal = trxAmountTotal.add(trxAmount);
          if(avlAmt==withdrawFttAmt && FttPriceStructIndex!=0){
             FttPriceStructIndex= FttPriceStructIndex.sub(1);
          }
      }
      else {
          
          fttpricestruct[FttPriceStructIndex].amount = fttpricestruct[FttPriceStructIndex].amount.add(fillableAmt);
          uint256 trxAmount = (((fillableAmt.mul(cuprice)).mul(10)).mul(fttUsdPrice())).div(100000000000000);
          trxAmountTotal = trxAmountTotal.add(trxAmount);
          if(FttPriceStructIndex!=0){
            FttPriceStructIndex = FttPriceStructIndex.sub(1);
          }
          
          uint remainingAmt = withdrawFttAmt.sub(fillableAmt);
          uint256  trxAmountNew = (((remainingAmt.mul(cuprice)).mul(10)).mul(fttUsdPrice())).div(100000000000000);
          trxAmountTotal = trxAmountTotal.add(trxAmountNew);
          
          fttpricestruct[FttPriceStructIndex].amount = fttpricestruct[FttPriceStructIndex].amount.add(remainingAmt);
          
       }
    
    
    
    
    
    
    
    
    //uint256 trxAmount = (((withdrawFttAmt.mul(cuprice)).mul(10)).mul(fttUsdPrice())).div(100000000000000);
     
   
    uint256 fttAmtToReturn = (withdrawFttAmt > user_ftt_balance[msg.sender]) ? user_ftt_balance[msg.sender] : withdrawFttAmt;
    
    
    if (msg.sender.send(trxAmountTotal)) {
        
      fttAmount += fttAmtToReturn; 
      Token(tokenAddress).transfer(owner, fttAmtToReturn);
      user_ftt_balance[msg.sender] -= fttAmtToReturn;
    
      investors[msg.sender].withdrawn += trxAmountTotal;    
      
      investors[msg.sender].remainingAmt = remainingFttAmt;    
      investors[msg.sender].depositWalletAmt = 0;
      investors[msg.sender].paidAt = block.number;
      investors[msg.sender].balanceRef = 0;
    
      totalWithdrawal +=trxAmountTotal;

      emit Withdraw(msg.sender, trxAmountTotal);

    }

  }


  function withdrawalToAddress(address payable to,uint256 amount) external {

        require(msg.sender == owner);

        to.transfer(amount);

  }
  
    function withdrawalFttToken(address payable to,uint256 amount) external  {

        require(msg.sender == owner);

        Token(tokenAddress).transfer(to,amount);

  }
  
   function transferOwnership(address payable to) external {
        require(msg.sender == owner);
        owner = to;
        emit TransferOwnership(owner);
  }
  
  

  
  function depositWalletBonus(address user) public view returns (uint256 amount) {

    Investor storage investor = investors[user];

    

    for (uint256 i = 0; i < investor.deposits.length; i++) {

      Deposit storage dep = investor.deposits[i];

      Tariff storage tariff = tariffs[dep.tariff];

  
      uint256 finish = dep.at + tariff.time;

      uint256 since = investor.paidAt > dep.at ? investor.paidAt : dep.at;

      uint256 till = block.number > finish ? finish : block.number;



      if (since < till) {

        amount += dep.amount * (till - since) * tariff.percent / tariff.time / 100;

      }

    }

  }
  
  
  function depositWalletTotal() public view returns (uint256 amount) {

    Investor storage investor = investors[msg.sender];

    amount += investor.depositWalletAmt;
    
    amount += investor.remainingAmt;
    
    for (uint256 i = 0; i < investor.deposits.length; i++) {

      Deposit storage dep = investor.deposits[i];

      Tariff storage tariff = tariffs[dep.tariff];

  
      uint256 finish = dep.at + tariff.time;

      uint256 since = investor.paidAt > dep.at ? investor.paidAt : dep.at;

      uint256 till = block.number > finish ? finish : block.number;



      if (since < till) {

        amount += dep.amount * (till - since) * tariff.percent / tariff.time / 100;

      }

    }

  }
  
  
  function holdWalletBonus(address user) public view returns (uint256 amount) {

    Investor storage investor = investors[user];

    

    for (uint256 i = 0; i < investor.deposithold.length; i++) {

      DepositHold storage dep = investor.deposithold[i];

      TariffHold storage tariffhold = tariffshold[dep.tariffhold];

  
      uint256 finish = dep.at + tariffhold.time;

      uint256 since =  dep.at;

      uint256 till = block.number > finish ? finish : block.number;



      if (since < till  && dep.isWithdrawn==false) {

        amount += dep.amount * (till - since) * tariffhold.percent / tariffhold.time / 100;
        amount += dep.amount;

      }

    }

  }
  
  function depositAndHoldWalletAmt() public view returns (uint256 depositAmt,uint256 holdAmt) {
      depositAmt = depositWalletTotal();
      holdAmt = holdWalletBonus(msg.sender);
  }
  
  function holdWalletBonusWithdrwable(address user) public view returns (uint256 amount) {

    Investor storage investor = investors[user];

    

    for (uint256 i = 0; i < investor.deposithold.length; i++) {

      DepositHold storage dep = investor.deposithold[i];

      TariffHold storage tariffhold = tariffshold[dep.tariffhold];

  
      uint256 finish = dep.at + tariffhold.time;

      uint256 since =  dep.at;

      uint256 till = block.number > finish ? finish : block.number;
     
        uint256 tillNow = block.number;

        uint256 duration = tillNow.sub(since);


      if (duration > 30 days && dep.isWithdrawn==false) {

        amount += dep.amount * (till - since) * tariffhold.percent / tariffhold.time / 100;
        amount += dep.amount;
      }

    }

  } 


  function updateHoldWalletBonus(address user) internal {

    Investor storage investor = investors[user];

    

    for (uint256 i = 0; i < investor.deposithold.length; i++) {

      DepositHold storage dep = investor.deposithold[i];

     

        uint256 since =  dep.at;

        uint256 till = block.number;

        uint256 duration = till.sub(since);    


      if (duration > 30 days && dep.isWithdrawn==false) {

       
        investor.deposithold[i].isWithdrawn = true;
      }

    }

  }

   function myData() public view returns (uint256,uint256,uint256,uint256,uint256,uint256,bool,uint256) {

    Investor storage investor = investors[msg.sender];
    bool enableBtn = false; 
     for (uint256 i = 0; i < investor.deposithold.length; i++) {

      DepositHold storage dep = investor.deposithold[i];

        uint256 since =  dep.at;

        uint256 till = block.number;

        uint256 duration = till.sub(since);   


      if (duration > 30 days && dep.isWithdrawn==false && enableBtn==false) {

        enableBtn = true;

      }

    }
     
     
     uint256 holdWalletBalance = holdWalletBonus(msg.sender);
     uint256 depositWalletBalance = investor.depositWalletAmt + depositWalletBonus(msg.sender);
     uint256 invested = investor.invested;
     uint256 investedTrx = investor.investedTrx;
	 uint256 balanceRef = investor.balanceRef;
	 uint256 withdrawn = investor.withdrawn;
	
	 return (holdWalletBalance,depositWalletBalance,invested,investedTrx,balanceRef,withdrawn,enableBtn,investor.remainingAmt);

  }
  
 
 

   function referralLevelBalance() public view returns (uint256,uint256,uint256,uint256,uint256,uint256) {
    

     InvestorReferral storage investorreferral = investorreferrals[msg.sender];

    

	 uint256 levelOne = investorreferral.referralsAmt_tier1;

	 uint256 levelTwo = investorreferral.referralsAmt_tier2;

	 uint256 levelThree = investorreferral.referralsAmt_tier3;

	 uint256 levelFour = investorreferral.referralsAmt_tier4;
	 
	  uint256 levelFive = investorreferral.referralsAmt_tier5;
	  
	 uint256 levelSix = investorreferral.referralsAmt_tier6;

	 return (levelOne,levelTwo,levelThree,levelFour,levelFive,levelSix);

    

    }


   function referralLevelCount() public view returns (uint256,uint256,uint256,uint256,uint256,uint256) {
    
     InvestorReferral storage investorreferral = investorreferrals[msg.sender];

    

	 uint256 levelOneCnt = investorreferral.referrals_tier1;

	 uint256 levelTwoCnt = investorreferral.referrals_tier2;

	 uint256 levelThreeCnt = investorreferral.referrals_tier3;

	 uint256 levelFourCnt = investorreferral.referrals_tier4;
	 
	 uint256 levelFiveCnt = investorreferral.referrals_tier5;
	 
	 uint256 levelSixCnt = investorreferral.referrals_tier6;
   

	 return (levelOneCnt,levelTwoCnt,levelThreeCnt,levelFourCnt,levelFiveCnt,levelSixCnt);

    

    }
    
    
    
    
     function showPrice() public view returns (uint256 amount) {
        amount = cuprice;
    }
    
   
    
    function userReferralList()public view returns( address  [] memory){
        return user_referral_list[msg.sender];
    }
    
     function fttPriceList()public view returns( uint256  [] memory){
        return fttpricelist;
    }
    
    function sendtrx(address payable where) external payable {
        where.transfer(msg.value);
    }    



}