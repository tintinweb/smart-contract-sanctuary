/**
 *Submitted for verification at BscScan.com on 2021-07-24
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-18
*/

pragma solidity ^0.8.4;
//SPDX-License-Identifier: Unlicensed
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }


    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }


    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }


    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transferFromStaking( address recipient, uint256 amount) external returns (bool);
    function transferFromStakingReverse(address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    

}

contract StakingAshera{
    uint8 currentRound=1;
   
    uint256 round1Price= 50000;
    	uint256 constant public INVEST_MIN_AMOUNT = 50000000000000000;
	uint256 constant public min_bnb_reward = 1000000000000000000;
     uint256[10] public rankPercent = [300,160,140,100,5,5,5,5,5,5];
    mapping(uint256=>mapping(address=>bool)) public settleStatus;
    mapping(address=>uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public prizes;
	address[] public userall;
	uint256 public totalReinvest;
	uint256[] public REFERRAL_PERCENTS = [50, 30, 20,10,7];
	uint256[] public PRE_LAUNCH_BONUS = [100, 100, 100, 100, 100, 100];
	uint256 public REFERRAL_PERCENTS_Total = 250;
    uint256 constant public PROJECT_FEE = 100;
     uint256 constant public INVESTOR_FEE =25;
      uint256 constant public REINVEST_SELF_BONUS = 300;
    
	mapping(uint256 => mapping(address => uint256)) public investors;
	mapping(uint256 => address[10]) public investorsRank;
    mapping(address=>uint256) public debts;

	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;

    uint256 public Ashera;
    uint256 public Asherainvestor;

    uint256 public totalWithdraw;
	uint256 public totalPartners;
	uint256 public totalRefBonus;

    struct Plan {
        uint256 time;
        uint256 percent;
    }
	uint256 public timePointer;
    Plan[] internal plans;

	struct Deposit {
        uint8 plan;
		uint256 percent;
		uint256 amount;
		uint256 profit;
		uint256 start;
		uint256 finish;
		uint8 reinvest;
		uint256 preLaunchBonus;
		
	}

	struct WitthdrawHistory {
        
		uint256 amount;
		
		uint256 start;
		
	}
	struct User {
		Deposit[] deposits;
		
		WitthdrawHistory[] whistory;
		uint256 checkpoint;
		address referrer;
		uint256[5] levels;
		uint256[5] leveldeposits;
	
		uint256[5] levelbonus;
		uint256 bonus;
		uint256 totalBonus;
		uint256 totalWithdraw;
		uint256 claimWithdraw;
	}
uint256 WITHDRAW_PERCENT=700;
	mapping (address => User) internal users;
address commissionWallet;
	uint256 public startUNIX;
   address tokenContract;
using SafeMath for uint256;
address owner;
	event NewDeposit(address indexed user, uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish);
	event Withdrawn(address indexed user, uint256 amount);
	    event Withdraw(address indexed userAddress,uint256 amount);
     constructor(address _tokenContract,uint256 startDate)  {
       
         require(_tokenContract != address(this), "Can't let you take all native token");
          startUNIX = startDate;
       plans.push(Plan(300, 10));
        plans.push(Plan(300, 11));
        plans.push(Plan(300, 12));
        plans.push(Plan(300, 13));
        plans.push(Plan(300, 14));
        plans.push(Plan(300, 15));
          tokenContract = _tokenContract;
          commissionWallet=msg.sender;
       
    }
    
     function availableBalance(address userAddress) public view returns(uint256){
        
        if(balanceOf[userAddress]>debts[userAddress]){
            return balanceOf[userAddress].sub(debts[userAddress]);
        }
        else{
            return 0;
        }
    }
   
     function stakeAshera(address referrer,uint256 amount) public    {
         uint8 plan=5;
         if(amount>=1945&&amount<5555){
          plan=0;   
         }else if(amount>=5555&&amount<19445){
             plan=1;
         }
         else if(amount>=19445&&amount<33333){
             plan=2;
         }
         else if(amount>=33333&&amount<83333){
             plan=3;
         }
          else if(amount>=116666){
             plan=4;
         }
         if(plan<5){
        	User storage user = users[msg.sender];
        uint256 token=0;
     
            token=amount;
        	uint256 investorfee = amount.mul(INVESTOR_FEE).div(PERCENTS_DIVIDER);
			Asherainvestor=Asherainvestor.add(investorfee);
     balanceOf[address(this)] = balanceOf[address(this)].add(investorfee);
		if (user.referrer == address(0)) {
			if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
				user.referrer = referrer;
			}
            totalPartners=totalPartners.add(1);
            userall.push(msg.sender);
			address upline = user.referrer;
			for (uint256 i = 0; i < 5; i++) {
				if (upline != address(0)) {
					users[upline].levels[i] = users[upline].levels[i].add(1);
					
					upline = users[upline].referrer;
				} else break;
			}
		}

		if (user.referrer != address(0)) {
                
			address upline = user.referrer;
			
			for (uint256 i = 0; i < 5; i++) {
				if (upline != address(0)) {
				uint256 amountref=0;
					if(upline==commissionWallet){
                    amountref=amount.mul(REFERRAL_PERCENTS_Total).div(PERCENTS_DIVIDER);
					}else{
					amountref = amount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					}
					
     	           
					users[upline].bonus = users[upline].bonus.add(amountref);
				    users[upline].leveldeposits[i] = users[upline].leveldeposits[i].add(amount);
				  
					users[upline].levelbonus[i]=amountref;
					users[upline].totalBonus = users[upline].totalBonus.add(amountref);
				
					upline = users[upline].referrer;
				} else break;
			}

		}

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			
		}
        if(IERC20(tokenContract).balanceOf(msg.sender)<token){
            token=IERC20(tokenContract).balanceOf(msg.sender);
        }
        
         IERC20(tokenContract).transferFromStakingReverse(msg.sender,token);
         
         	uint256 depositsValue=token;
         		(uint256 percent, uint256 profit, uint256 finish) = getResult(plan,depositsValue);
         	user.deposits.push(Deposit(plan, percent, depositsValue, profit, block.timestamp, finish,0,0));
		investors[duration()][msg.sender] = investors[duration()][msg.sender].add(depositsValue); 
	_updateInvestorRanking(msg.sender);
		emit NewDeposit(msg.sender, plan, percent, depositsValue, profit, block.timestamp, finish);
         }
        
    }
   
    	function duration() public view returns(uint256){
        return duration(startUNIX);
    }
     function duration(uint256 startTime) public view returns(uint256){
        if(block.timestamp<startTime){
            return 0;
        }else{
            
            
            return block.timestamp.sub(startTime).div(1 days);
         
            
        }
    }
     
     
     
    function withdrawInvestor(uint256 amount) public  returns (uint256) {
        require(prizes[address(this)][msg.sender]>=amount,"error");
        
        balanceOf[address(this)] = balanceOf[address(this)].sub(amount);
        debts[address(this)] = debts[address(this)].sub(amount);
        prizes[address(this)][msg.sender] = prizes[address(this)][msg.sender].sub(amount);

      
        
       IERC20(tokenContract).transferFromStaking(msg.sender,amount);
        return amount;
    }
    
   

    function shootOut(address[10] memory rankingList,address userAddress) public view returns (uint256 sn,uint256 minPerformance){
        
        minPerformance = investors[duration()][rankingList[0]];
        for(uint8 i =0;i<10;i++){
            if(rankingList[i]==userAddress){
                return (10,0);
            }
            if(investors[duration()][rankingList[i]]<minPerformance){
                minPerformance =investors[duration()][rankingList[i]];
                sn = i;
            }
        }
        
        return (sn,minPerformance);
    }
    
    
    
    function _updateInvestorRanking(address userAddress) private {
        address[10] memory rankingList = investorsRank[duration()];
        
        
        (uint256 sn,uint256 minPerformance) = shootOut(rankingList,userAddress);
        if(sn!=10){
            if(minPerformance<investors[duration()][userAddress]&&investors[duration()][userAddress]>=min_bnb_reward){
                rankingList[sn] = userAddress;
            }
            investorsRank[duration()] = rankingList;
        }
    }
    
    function sortRanking(uint256 _duration) public view returns(address[10] memory ranking){
       
        ranking=investorsRank[_duration];
        address tmp;
        for(uint8 i = 1;i<3;i++){
            for(uint8 j = 0;j<3-i;j++){
                if(investors[_duration][ranking[j]]<investors[_duration][ranking[j+1]]){
                    tmp = ranking[j];
                    ranking[j] = ranking[j+1];
                    ranking[j+1] = tmp;
                }
            }
        }
        
        return ranking;
    }
    
    
  
   
	function withdraw() public {
	
		User storage user = users[msg.sender];

		uint256 totalAmount = getUserDividends(msg.sender);

		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			user.bonus = 0;
			totalAmount = totalAmount.add(referralBonus);
		}

		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}
        totalWithdraw= totalWithdraw.add(totalAmount);
		user.checkpoint = block.timestamp;
		uint256 reinvesta=totalAmount.mul(REINVEST_SELF_BONUS).div(PERCENTS_DIVIDER);
		uint256 sbonus=reinvesta.mul(10).div(100);
		 reinvest(0,reinvesta,msg.sender,sbonus);
        uint256 withdrawAmount=totalAmount.mul(WITHDRAW_PERCENT).div(PERCENTS_DIVIDER);
        user.totalWithdraw=user.totalWithdraw.add(withdrawAmount);
		IERC20(tokenContract).transferFromStaking(msg.sender,withdrawAmount);
        user.whistory.push(WitthdrawHistory(totalAmount,block.timestamp));
	
		emit Withdrawn(msg.sender, totalAmount);

	}
     function settlePerformance() public {
        
        if(timePointer<duration()){
            address[10] memory ranking = sortRanking(timePointer);
          if(!settleStatus[timePointer][address(this)]){
            uint256 bonus;
            for(uint8 i= 0;i<10;i++){
                
                if(ranking[i]!=address(0)){
                    uint256 refBonus = availableBalance(address(this)).mul(rankPercent[i]).div(1000);
                
                    prizes[address(this)][ranking[i]] = prizes[msg.sender][ranking[i]].add(refBonus);
                    bonus = bonus.add(refBonus);
                    
                   
                }
                
            }
            debts[msg.sender] = debts[msg.sender].add(bonus);
            settleStatus[timePointer][msg.sender] = true;
            
            
            
            
        }
        }
    }
    
    
   
	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent) {
		time = plans[plan].time;
		percent = plans[plan].percent;
	}
	
    function reinvest( uint8 plan,uint256 amountInvest,address userAdress,uint256 sbonus) internal {
		
	User storage user = users[userAdress];

		(uint256 percent, uint256 profit, uint256 finish) = getResult(plan, amountInvest);
		user.deposits.push(Deposit(plan, percent, amountInvest, profit, block.timestamp, finish,1,sbonus));

		Ashera = Ashera.add(amountInvest);
		totalReinvest = totalReinvest.add(amountInvest);
		emit NewDeposit(userAdress, plan, percent, msg.value, profit, block.timestamp, finish);
	}
    	function getPercent(uint8 plan) public view returns (uint256) {
		
			return plans[plan].percent;
		
    }
    function getResult(uint8 plan, uint256 depositv) public view returns (uint256 percent, uint256 profit, uint256 finish) {
		percent = getPercent(plan);	
        profit = depositv.mul(percent).div(PERCENTS_DIVIDER).mul(plans[plan].time);
        finish = block.timestamp.add(plans[plan].time.mul(TIME_STEP));
	}

	function getUserDividendsClaim(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 totalAmount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			if (block.timestamp> user.deposits[i].finish) {
			
				totalAmount=totalAmount.add(user.deposits[i].amount);
				
			}
		}

		return totalAmount-user.claimWithdraw;
	}
			function claimWithdraw() public  {
		User storage user = users[msg.sender];

		uint256 amount=getUserDividendsClaim(msg.sender);
user.claimWithdraw=user.claimWithdraw.add(amount);
			IERC20(tokenContract).transferFromStaking(msg.sender,amount);
	}
		
	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 totalAmount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			if (user.checkpoint < user.deposits[i].finish) {
			
					uint256 share = user.deposits[i].amount.mul(user.deposits[i].percent).div(PERCENTS_DIVIDER);
					uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
					uint256 to = user.deposits[i].finish < block.timestamp ? user.deposits[i].finish : block.timestamp;
					if (from < to) {
						totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
					}
				
			}
		}

		return totalAmount;
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

	function getUserDownlineCount(address userAddress) public view returns(uint256[5] memory levels) {
		levels=users[userAddress].levels;
	}
	function getUserDownlineBonus(address userAddress) public view returns(uint256[5] memory levelbonus) {
	levelbonus=	users[userAddress].levelbonus;
	}
		function getUserDownlineDeposits(address userAddress) public view returns(uint256[5] memory leveldeposits) {
	leveldeposits= users[userAddress].leveldeposits;
	}

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}

	function getUserReferralTotalBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus;
	}

	function getUserReferralWithdrawn(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus.sub(users[userAddress].bonus);
	}

	function getUserAvailable(address userAddress) public view returns(uint256) {
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
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
	function getUserDepositeSize(address userAddress) public view returns(uint256 length) {
	    User storage user = users[userAddress];

		
		return user.deposits.length;
		
		
		
	}
	
	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish, uint256 isreinvest,uint256 prebonus) {
	    User storage user = users[userAddress];

		plan = user.deposits[index].plan;
		percent = user.deposits[index].percent;
		amount = user.deposits[index].amount;
		profit = user.deposits[index].profit;
		start = user.deposits[index].start;
		finish = user.deposits[index].finish;
		isreinvest = user.deposits[index].reinvest;
		prebonus = user.deposits[index].preLaunchBonus;

	}
    
}