//SourceUnit: Cryptobulss.sol

pragma solidity 0.5.10;

contract Cryptobulls{
	using SafeMath for uint256;

	uint256 constant public INVEST_MIN_AMOUNT_FACTOR = 100 trx;
		uint256[12]  public INVEST_PLAN= [100 trx,200 trx,400 trx,600 trx,800 trx,1000 trx];

    uint256[] public REFERRAL_PERCENTS = [50, 20, 10];
     uint256[] public RANK_PERCENTS = [45, 25, 15,10,5];
uint256 constant public INVEST_MIN_FORREWARD = 2500 trx;
	uint256 public REFERRAL_PERCENTS_Total =80;
    uint256 constant public OWNER_FEE = 70;
    uint256 constant public MARKETTING_FEE =15;
    uint256 constant public DEV_FEE = 15;
   	uint256 constant public PERCENTS_DIVIDER = 1000;

	uint256 public startUNIX;
  
    uint256 public CryptobullsTotal;
   	uint256 public totalWithdraw;
	mapping(uint256=>bool) public settleStatus;
	uint256 public totalRefBonus;
   	uint256 public totalRefBonusWithdraw;
    struct PlanBuyData {
      
        uint256 amount;
        address useraddress;
    }
 struct PlanBuy {
      
       PlanBuyData[] plandata;
    }
   

	struct Deposit {
        uint8 plan;
	
		uint256 amount;
	
		uint256 start;
	
	}
	struct WitthdrawHistory {
        
		uint256 amount;
		
		uint256 start;
		
	}
struct LevelDuration {
        
		uint256 countmember;
		
		uint256 start;
		uint256 amount;
	}
	struct User {
		Deposit[] deposits;
		
		WitthdrawHistory[] whistory;
		uint256 checkpoint;
		address referrer;
		uint256[3] levels;
		uint256[3] leveldeposits;
	    uint256[6] userLastUpdatedIndex;
	    LevelDuration[] levelsDurations;
		uint256[3] levelbonus;
	uint256 bonus;
		uint256 income;
		uint256 incomeTotal;
	uint256 totalBonus;
		uint256 totalWithdraw;
	
	}
 
    uint256 public debts;
    	mapping (address => uint256) public prizes;
	uint256 constant public TIME_STEP = 1 days;
   	uint256 public timePointer;
   		mapping(uint256 => mapping(address => uint256)) public Referals;
	mapping(uint256 => address[5]) public ReferalsRank;
    
	mapping (address => User) internal users;
	mapping (uint256 => PlanBuy) internal planbuy;

	address payable public commissionWallet;
	address payable public marketingWallet;
	address payable public devWallet;
	uint256 public totalPartners;
	uint256 weeklyCheckout=0;
	 
		uint256 constant public WEEKLY_LIMIT = 7 days;
	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan,  uint256 amount,  uint256 start);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);
   
    event Withdraw(address indexed userAddress,uint256 amount);


     modifier settleBonus(){
        settlePerformance();
        _;
    }

	constructor(address payable wallet,address payable wallet1,address payable wallet2, uint256 startDate) public {
		require(!isContract(wallet));
		require(startDate > 0);
		commissionWallet = wallet;
		marketingWallet = wallet1;
		devWallet = wallet2;
	    startUNIX = startDate;

        
  	}
  	
  	  function _updateReferalRanking(address userAddress) private {
        address[5] memory rankingList = ReferalsRank[duration()];
        (uint256 sn,uint256 minPerformance) = shootOut(rankingList,userAddress);
        if(sn!=5){
            if(minPerformance<Referals[duration()][userAddress]&&Referals[duration()][userAddress]>=INVEST_MIN_FORREWARD){
                rankingList[sn] = userAddress;
            }
            ReferalsRank[duration()] = rankingList;
        }
    }
    
    	function shootOut(address[5] memory rankingList,address userAddress) public view returns (uint256 sn,uint256 minPerformance){
        
        minPerformance = Referals[duration()][rankingList[0]];
        for(uint8 i =0;i<5;i++){
            if(rankingList[i]==userAddress){
                return (5,0);
            }
            if(Referals[duration()][rankingList[i]]<minPerformance){
                minPerformance =Referals[duration()][rankingList[i]];
                sn = i;
            }
        }
        
        return (sn,minPerformance);
    }
	 function sortRanking(uint256 _duration) public view returns(address[5] memory ranking){
       
        ranking=ReferalsRank[_duration];
        address tmp;
        for(uint8 i = 1;i<5;i++){
            for(uint8 j = 0;j<5-i;j++){
                if(Referals[_duration][ranking[j]]<Referals[_duration][ranking[j+1]]){
                    tmp = ranking[j];
                    ranking[j] = ranking[j+1];
                    ranking[j+1] = tmp;
                }
            }
        }
        
        return ranking;
    }	

function settlePerformance() public {
        if(timePointer+ WEEKLY_LIMIT<duration()){
        	address[5] memory ranking = sortRanking(timePointer);
          	if(!settleStatus[timePointer]){
				uint256 bonus;
				uint256 refBonus;
				uint256 availableBalance = address(this).balance;
				for(uint8 i= 0;i<5;i++){
					if(ranking[i]!=address(0)){
						refBonus = availableBalance.mul(RANK_PERCENTS[i]).div(10000);
						prizes[ranking[i]] = prizes[ranking[i]].add(refBonus);
						bonus = bonus.add(refBonus);
					}
				}
				debts= debts.add(bonus);
				settleStatus[timePointer] = true;
        	}
			timePointer = duration();
        }
    }


	function userReferalRanking(uint256 _duration) external view returns(address[5] memory addressList,uint256[5] memory performanceList,uint256[5] memory preEarn){
        
        addressList = sortRanking(_duration);
        uint256 credit = address(this).balance;
        for(uint8 i = 0;i<5;i++){
            preEarn[i] = credit.mul(RANK_PERCENTS[i]).div(10000);
            performanceList[i] = Referals[_duration][addressList[i]];
        }
        
    }
	 
	function duration() public view returns(uint256){
        return duration(startUNIX);
    }
    
    function duration(uint256 startTime) public view returns(uint256){
        if(now<startTime){
            return 0;
        }else{
            return now.sub(startTime).div(TIME_STEP);
        }
    }
     
	
	 function adminWeeklyIncome() public{
	     if(block.timestamp > weeklyCheckout + WEEKLY_LIMIT){
	         uint256 userBalance=address(this).balance;
	         	uint256 fee = userBalance.mul(OWNER_FEE).div(PERCENTS_DIVIDER);
		commissionWallet.transfer(fee);
		
		uint256 feeM = userBalance.mul(MARKETTING_FEE).div(PERCENTS_DIVIDER);
		marketingWallet.transfer(feeM);
		
		uint256 feeD = userBalance.mul(DEV_FEE).div(PERCENTS_DIVIDER);
		devWallet.transfer(feeD);
		weeklyCheckout=block.timestamp;
	     }
	 }

     
    modifier weeklyBonus(){
        adminWeeklyIncome();
        _;
    } 
    function updateUserPlan(uint256 plan,uint256 fromIndex) public {
    
       
        PlanBuy storage plans=planbuy[plan-1];
         address useAdress=msg.sender;
              User storage user = users[useAdress];
        if(fromIndex>user.userLastUpdatedIndex[plan-1]){
        uint256 reqMember=fromIndex.sub(1).mul(5).add(5);
       if(plans.plandata.length>reqMember){
			 
             if(plan!=6){
              user.income=user.income.add(INVEST_PLAN[plan-1].mul(200).div(100));
                  user.incomeTotal=user.incomeTotal.add(INVEST_PLAN[plan-1].mul(200).div(100));
            reinvest(uint8(plan),INVEST_PLAN[plan],useAdress);
             user.userLastUpdatedIndex[plan-1]=fromIndex; 
             }else{
                 user.income=user.income.add((INVEST_PLAN[plan-1].mul(500).div(100)).sub(100));
                  user.incomeTotal=user.incomeTotal.add((INVEST_PLAN[plan-1].mul(500).div(100)).sub(100));
            reinvest(uint8(0),INVEST_PLAN[0],useAdress);
             user.userLastUpdatedIndex[plan-1]=fromIndex; 
			 }
             
          
		}
              
}
        
          
     
    }  
	function invest(address referrer) public weeklyBonus settleBonus payable {
        require(block.timestamp > startUNIX, "the contract was not launched");
		require(msg.value % INVEST_MIN_AMOUNT_FACTOR==0 );
        

		uint256 fee = msg.value.mul(OWNER_FEE).div(PERCENTS_DIVIDER);
		commissionWallet.transfer(fee);
		
		uint256 feeM = msg.value.mul(MARKETTING_FEE).div(PERCENTS_DIVIDER);
		marketingWallet.transfer(feeM);
		
		uint256 feeD = msg.value.mul(DEV_FEE).div(PERCENTS_DIVIDER);
		devWallet.transfer(feeD);
		
		
		
	  	emit FeePayed(msg.sender, fee);
	  	
    
		User storage user = users[msg.sender];
			
		if (user.referrer == address(0)) {
			if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
				user.referrer = referrer;
			}
            totalPartners=totalPartners.add(1);
        
			address upline = user.referrer;
			for (uint256 i = 0; i < 3; i++) {
				if (upline != address(0)) {
					users[upline].levels[i] = users[upline].levels[i].add(1);
					upline = users[upline].referrer;
				} else break;
			}
		}

		if (user.referrer != address(0)) {
                
			address upline = user.referrer;
			for (uint256 i = 0; i < 3; i++) {
				if (upline != address(0)) {
				     
					uint256 amount =0;
					if(upline==commissionWallet){
                    amount=msg.value.mul(REFERRAL_PERCENTS_Total).div(PERCENTS_DIVIDER);
					}else{
					amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					}
                    totalRefBonus=totalRefBonus.add(amount);
                 
					users[upline].bonus = users[upline].bonus.add(amount);
				    users[upline].leveldeposits[i] = users[upline].leveldeposits[i].add(msg.value);
					users[upline].levelbonus[i]=amount;
					users[upline].totalBonus = users[upline].totalBonus.add(amount);
					emit RefBonus(upline, msg.sender, i, amount);
					upline = users[upline].referrer;
				} else break;
			}

		}

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			emit Newbie(msg.sender);
		}
			address upline = user.referrer;
		 if (upline != address(0)) {
	
			    
                    	Referals[duration()][upline] = Referals[duration()][upline].add(msg.value); 
     
     	                 _updateReferalRanking(upline);
                    
	
		 }
		uint256 depositsValue=msg.value;
		
	
     
    	for(uint256 i=1;i<=msg.value.div(INVEST_MIN_AMOUNT_FACTOR);i++){
     		PlanBuy storage planb = planbuy[0];
     		planb.plandata.push(PlanBuyData(INVEST_MIN_AMOUNT_FACTOR,msg.sender));
     
}
		user.deposits.push(Deposit(0, depositsValue, block.timestamp));
     	CryptobullsTotal = CryptobullsTotal.add(msg.value);
		emit NewDeposit(msg.sender, 0,  depositsValue, block.timestamp);
        
	}
  	
     
  
     
	function withdraw() public weeklyBonus {
	
		User storage user = users[msg.sender];

	

		uint256 totalAmount =user.income;
        user.income=0;
		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			user.bonus = 0;
			totalRefBonusWithdraw=totalRefBonusWithdraw.add(referralBonus);
			totalAmount = totalAmount.add(referralBonus);
		}
      	if(prizes[msg.sender]>0){
			totalAmount=totalAmount.add(prizes[msg.sender]);
			prizes[msg.sender]=0;
		}

		require(totalAmount > 0, "User has no dividends");

	

    uint256 availWithdrawBalance=totalAmount;

		uint256 contractBalance = address(this).balance;
		if (contractBalance < availWithdrawBalance) {
			availWithdrawBalance = contractBalance;
		}
		totalWithdraw=totalWithdraw.add(availWithdrawBalance);
      
		user.checkpoint = block.timestamp;
       
        user.totalWithdraw=user.totalWithdraw.add(availWithdrawBalance);
	
	    msg.sender.transfer(availWithdrawBalance);
        user.whistory.push(WitthdrawHistory(availWithdrawBalance,block.timestamp));

		emit Withdrawn(msg.sender,availWithdrawBalance);

	}
	
	

	
    function reinvest(uint8 plan,uint256 amountInvest,address userAdress) internal  {
		
		User storage user = users[userAdress];
	uint256 fee = amountInvest.mul(OWNER_FEE).div(PERCENTS_DIVIDER);
		commissionWallet.transfer(fee);
		
		uint256 feeM = amountInvest.mul(MARKETTING_FEE).div(PERCENTS_DIVIDER);
		marketingWallet.transfer(feeM);
		
		uint256 feeD = amountInvest.mul(DEV_FEE).div(PERCENTS_DIVIDER);
		devWallet.transfer(feeD);
	
		user.deposits.push(Deposit(plan, amountInvest, block.timestamp));

		CryptobullsTotal = CryptobullsTotal.add(amountInvest);
		PlanBuy storage planb = planbuy[plan];
     		planb.plandata.push(PlanBuyData(amountInvest,userAdress));
     	
     	
     		
		emit NewDeposit(userAdress, plan,  amountInvest,  block.timestamp);
	}
    
	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}

	function getUserTotalWithdraw(address userAddress) public view returns(uint256) {
		return users[userAddress].totalWithdraw;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

	function getUserDownlineCount(address userAddress) public view returns(uint256[3] memory levels) {
		levels=users[userAddress].levels;
	}

	function getUserDownlineBonus(address userAddress) public view returns(uint256[3] memory levelbonus) {
		levelbonus=	users[userAddress].levelbonus;
	}

	function getUserDownlineDeposits(address userAddress) public view returns(uint256[3] memory leveldeposits) {
		leveldeposits= users[userAddress].leveldeposits;
	}

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}

function getUserLastUpdateIndex(address userAddress,uint256 plan) public view returns(uint256) {
		return users[userAddress].userLastUpdatedIndex[plan];
	}
   

	function getUserReferralTotalBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus;
	}

	function getUserReferralWithdrawn(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus.sub(users[userAddress].bonus);
	}



	function getUserTotalDeposits(address userAddress) public view returns(uint256 amount) {
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount.add(users[userAddress].deposits[i].amount);
		}
	}
	
	function getUserWithdrawHistory(address userAddress, uint256 index) public view returns(uint256 amount, uint256 start) {
	    User storage user = users[userAddress];
		amount = user.whistory[index].amount;
		start=user.whistory[index].start;
	}

	function getUserWithdrawSize(address userAddress) public view returns(uint256 length) {
	    User storage user = users[userAddress];
		return user.whistory.length;
	}
		function getPlanBuySize(uint8 plan) public view returns(uint256 length) {
	    PlanBuy storage plans = planbuy[plan];
		return plans.plandata.length;
	}
	function getPlanDetails(uint8 plan) public view returns(address[] memory userAddress,uint256[] memory amount ) {
	    PlanBuy storage plans = planbuy[plan];
	    address[] memory addrs = new address[](plans.plandata.length);
        uint256[]    memory funds = new uint[](plans.plandata.length);
	   for (uint i = 0; i < plans.plandata.length; i++) {
            PlanBuyData storage plandataa = plans.plandata[i];
            addrs[i] = plandataa.useraddress;
            funds[i] = plandataa.amount;
        }
		return  (addrs,funds);
	}
function getPlanInfo(uint8 plan,uint index) public view returns(uint256 amount,address userAddress) {
	    PlanBuy storage plans = planbuy[plan];
	amount=plans.plandata[index].amount;
	userAddress=plans.plandata[index].useraddress;
	}
	function getUserDepositeSize(address userAddress) public view returns(uint256 length) {
	    User storage user = users[userAddress];
		return user.deposits.length;
	}
		function getUserIncome(address userAddress) public view returns(uint256 income) {
	    User storage user = users[userAddress];
		return user.income;
	}
	
	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint8 plan, uint256 amount, uint256 start) {
	    User storage user = users[userAddress];

		plan = user.deposits[index].plan;
	
		amount = user.deposits[index].amount;
	
		start = user.deposits[index].start;
	
		

	}

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}