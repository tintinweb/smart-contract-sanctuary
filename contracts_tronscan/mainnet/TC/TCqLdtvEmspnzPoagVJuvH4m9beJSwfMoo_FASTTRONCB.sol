//SourceUnit: fasttroncb.sol

//
//
//       *********************************************************************************************************************
//       *                                        SAFE , LEGIT , AUDITED Smart Contract                                      *
//       *********************************************************************************************************************
//       *                                          fast.troncb.com FAST-TRONCB(NEW)- Crypto Bank Team                       *
//       * Any similar smart contract is fake. The best smart contract on TRON network. The balance will not be zero at all  *
//       *                                                Audit by : Xaud.work                                               *
//       *                           WhitePaper : Http://fast.troncb.com/files/WhitePaper.pdf                                *    
//       *                             Audit Report : Http://fast.troncb.com/files/audit.pdf                                 *
//       *********************************************************************************************************************
//
//

pragma solidity 0.5.10;

contract FASTTRONCB {
    
        using SafeMath for uint256;
    	    	
    	uint256 constant public MARKETING_FEE = 6;
	    uint256 constant public PROJECT_FEE = 3;
	    uint256 constant public ADMIN_FEE = 1;
	    uint256 constant public ADMIN_FEE_PENALTY = 2;
	    
	    uint256 constant public PERCENTS_DIVIDER = 100;
	    uint256 constant public TIME_STEP = 1 days;
	    uint256 constant public PROJECT_START = 1611502200; // 24/01/2021 15:30 UTC;
	    
	    uint256[4] public DAILY_MAX=[100,100,100,100];
	    uint256[4] public DAY_LIMIT_FOR_PLANS= [100000 trx, 80000 trx, 40000 trx,20000 trx];
	    uint256[4] public DAY_STEPS=[30000 trx,24000 trx,12000 trx,6000 trx];//+30% daily
	    uint256[4] public PERCENTS_PENALTI = [80 , 70 , 60 , 50 ];

	    
	    uint256 public totalUsers;
	    uint256 public totalInvested;
	    uint256 public totalWithdrawn;
	    uint256 public totalDeposits;
	    uint256 public totalPenalty;
	  
	    uint256[4] public totalInvestedPlans;
	    uint256[4] public totalDepositsPlans;
        uint256[4] public totalWithdrawnPlans;
	  
	    address payable public marketingAddress;
	    address payable public projectAddress;
	    address public defaultReferrer;
  
  struct Plan {
        bool PlanAct;
        uint256 Plan_MinInv;
        uint256 Plan_MaxInv;
        uint256 Plan_Time;
        uint256 Plan_TotalPercent;
        uint256 Plan_referral_percentage;
        uint256 Plan_minimum_referral_percent;
   
    }
    
  struct Deposit {
	    bool DepAct;
	    uint256 plan;
    	uint256 amount;
		uint256 withdrawn;
		uint256 start;
		uint256 end_time;
	}

  struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		address referrer;
        uint256[4] referral_amount; //bonus
        uint256[4] referral_count;  //count
    }
  struct Daily_Limit {
        uint256 _currentday;
        uint256[4] _plan;
        bool[4] _flag;
    }
   
 
    Plan[] public plans;

	mapping (address => User) internal users;
    mapping (uint256 => Daily_Limit ) internal daily_limits;
    
	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount, uint256 plan);
	event Withdrawn(address indexed user, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);
    event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);


   	constructor(address payable marketingAddr, address payable projectAddr, address defaultRef) public {
		require(!isContract(marketingAddr) && !isContract(projectAddr));
		marketingAddress = marketingAddr;
		projectAddress = projectAddr;
		defaultReferrer = defaultRef;
		plans.push(Plan(true,100 trx,50000 trx , 20 * 86400 , 200 ,4,5));
        plans.push(Plan(true,80 trx,40000 trx , 20 * 86400 , 240 ,3,6));
        plans.push(Plan(true,60 trx,20000 trx , 30 * 86400 , 420 ,2,7));
        plans.push(Plan(true,50 trx,10000 trx , 30 * 86400 , 480 ,1,8));
        
  	}



function invest(uint plan , address referrer) public payable  {
    
        require(block.timestamp>=PROJECT_START, "Wait For countdown");
	    require(!isContract(msg.sender));  
	    require(!isContract(referrer));  
	
	    require(plan < plans.length, "No Plan" );
	
		require(msg.value >= plans[plan].Plan_MinInv, "Minimum deposit error");
        require(msg.value <= plans[plan].Plan_MaxInv, "Maximum deposit error");
    
        require(isRegPlan(plan,msg.sender)==false, "Plan Not Registered");
       	
       	uint256 availableLimit = getCurrentDayLimit(plan);
        require(availableLimit > 0, "Deposit limit exceed");
    
        User storage user = users[msg.sender];
        uint256 msgValue = msg.value;

        if (msgValue > availableLimit) {
    
            msg.sender.transfer(msgValue.sub(availableLimit));
            msgValue = availableLimit;
    
        }

        getCurrentDayLimitChange(plan,msgValue);
        
		marketingAddress.transfer(msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
		projectAddress.transfer(msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));

		emit FeePayed(msg.sender, msg.value.mul(MARKETING_FEE.add(PROJECT_FEE)).div(PERCENTS_DIVIDER));

    	if (user.referrer == address(0)) {
	
			if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
				user.referrer = referrer;
			} else if (msg.sender != defaultReferrer) {
				user.referrer = defaultReferrer;
			}

			address upline = user.referrer;
    
             if (upline != address(0)) {
              users[upline].referral_count[plan]=users[upline].referral_count[plan].add(1);
		    }
		}

		if (user.referrer != address(0)) {
	
			address upline = user.referrer;
				if (upline != address(0)) {
	
					uint256 amount = msg.value.mul(plans[plan].Plan_referral_percentage).div(PERCENTS_DIVIDER);
					users[upline].referral_amount[plan]= users[upline].referral_amount[plan].add(amount);
					emit RefBonus(upline, msg.sender, plan, amount);
					upline = users[upline].referrer;
	
				} 
			

		}	    
	    if (user.deposits.length == 0) {
	
			user.checkpoint = block.timestamp;
			totalUsers = totalUsers.add(1);
			emit Newbie(msg.sender);
	
		}
	
		user.deposits.push(Deposit(true,plan,msgValue, 0, block.timestamp , (block.timestamp + plans[plan].Plan_Time )));
	
		totalInvested = totalInvested.add(msgValue);
		totalInvestedPlans[plan] = totalInvestedPlans[plan].add(msgValue);
		totalDeposits = totalDeposits.add(1);
		totalDepositsPlans[plan] = totalDepositsPlans[plan].add(1);
	
		emit NewDeposit(msg.sender, msgValue,plan);
	}
	
function withdraw(uint plan) public{
    
       User storage user = users[msg.sender];
       uint256 _withdrawn;
       uint256 _bonus;
       require(isRegPlan(plan,msg.sender)==true);
    
       for (uint256 i = 0; i < user.deposits.length; i++){
    
          uint256 _refmin=user.deposits[i].amount.mul((plans[plan].Plan_minimum_referral_percent).div(PERCENTS_DIVIDER));
            if (user.deposits[i].DepAct==true && user.deposits[i].end_time<=block.timestamp && user.deposits[i].plan==plan && user.referral_amount[plan]>=_refmin){
              
              _withdrawn=user.deposits[i].amount.mul(plans[plan].Plan_TotalPercent).div(PERCENTS_DIVIDER);
              _bonus=user.referral_amount[plan];
              
              user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(_withdrawn);
              user.deposits[i].DepAct = false;
              user.referral_amount[plan] = 0;
              msg.sender.transfer(_withdrawn.add(_bonus));
        	  
        	  projectAddress.transfer(user.deposits[i].amount.mul(ADMIN_FEE).div(PERCENTS_DIVIDER));
              
              user.deposits[i].amount = 0;
      	      totalWithdrawn = totalWithdrawn.add(_withdrawn);
              emit Withdrawn(msg.sender,_withdrawn);
            }
           if(user.deposits[i].DepAct==true && user.deposits[i].end_time>block.timestamp && user.deposits[i].plan==plan ){
              
              _withdrawn=user.deposits[i].amount.mul(PERCENTS_PENALTI[plan]).div(PERCENTS_DIVIDER);
        
        	  user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(_withdrawn);
              user.deposits[i].DepAct = false;
        
              msg.sender.transfer(_withdrawn);
              projectAddress.transfer(user.deposits[i].amount.mul(ADMIN_FEE_PENALTY).div(PERCENTS_DIVIDER));
              user.deposits[i].amount = 0;
              totalPenalty = totalPenalty.add(_withdrawn);
              totalWithdrawn = totalWithdrawn.add(_withdrawn);
              totalWithdrawnPlans[plan] = totalWithdrawnPlans[plan].add(_withdrawn);
        
              emit Withdrawn(msg.sender,_withdrawn);
            }
        }
}

function deposit_dividends(uint plan) public view returns (uint256) {
    
    User storage user = users[msg.sender];
    uint256 dividends;
	 require(isRegPlan(plan,msg.sender)==true);
    	for (uint256 i = 0; i < user.deposits.length; i++){
        	 if(user.deposits[i].DepAct==true && user.deposits[i].start<=block.timestamp && user.deposits[i].plan==plan 
	           && user.deposits[i].withdrawn <= user.deposits[i].amount.mul(plans[plan].Plan_TotalPercent).div(PERCENTS_DIVIDER)) {
                    if(user.deposits[i].end_time>=block.timestamp ){
	                     dividends = ((user.deposits[i].amount.mul(plans[plan].Plan_TotalPercent).div(PERCENTS_DIVIDER))
	                     .div(plans[plan].Plan_Time)).mul((block.timestamp).sub(user.deposits[i].start));
                     }else{
                          dividends=user.deposits[i].amount.mul(plans[plan].Plan_TotalPercent).div(PERCENTS_DIVIDER);
                    }
	        }  
	    }
	return dividends;
}

function UserDeposits(uint plan) public view returns (bool,uint256,uint256,uint256,uint256,uint256){
	
	    User storage user = users[msg.sender];
	   
	    for (uint256 i = 0; i < user.deposits.length; i++) {
	        if(user.deposits[i].plan==plan && user.deposits[i].DepAct==true){
	            return(user.deposits[i].DepAct,user.deposits[i].plan,user.deposits[i].amount,user.deposits[i].withdrawn,user.deposits[i].start,user.deposits[i].end_time);
	        }
       }
	    
}

function getTotalpenalty() public view returns(uint256){
    return totalPenalty;
}

function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

function getUserTotalDeposits(address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];

		uint256 amount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			amount = amount.add(user.deposits[i].amount);
		}

		return amount;
	}

function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];

		uint256 amount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			amount = amount.add(user.deposits[i].withdrawn);
		}

		return amount;
	}

function getCurrentDayLimit(uint plan) internal returns (uint256) {
	    require(plan < plans.length, "No Plan" );
        uint256 limit=0;
        uint256 currentDay = (block.timestamp.sub(PROJECT_START)).div(TIME_STEP);

             if (daily_limits[currentDay]._plan[plan]==0 && daily_limits[currentDay]._flag[plan]==false ){
                limit = (currentDay.mul(DAY_STEPS[plan])).add(DAY_LIMIT_FOR_PLANS[plan]);
                if (limit> 1000000000000) limit=1000000000000;
                 daily_limits[currentDay]._plan[plan]= limit;
                 DAILY_MAX[plan]=limit;
             }else if(daily_limits[currentDay]._plan[plan]>0 && daily_limits[currentDay]._flag[plan]==false){ 
                limit = daily_limits[currentDay]._plan[plan];
            }
        return limit;
       
}

function getCurrentDayLimitViewPercentage(uint plan) public view returns (uint256) {

     return DAILY_MAX[plan];

}

function getCurrentDayLimitView(uint plan) public view returns (uint256) {
	    require(plan < plans.length, "No Plan" );
        uint256 limit=0;
        uint256 currentDay = (block.timestamp.sub(PROJECT_START)).div(TIME_STEP);

             if (daily_limits[currentDay]._plan[plan]==0 && daily_limits[currentDay]._flag[plan]==false ){
                limit = (currentDay.mul(DAY_STEPS[plan])).add(DAY_LIMIT_FOR_PLANS[plan]);
                if (limit> 1000000000000) limit=1000000000000;
             }else if(daily_limits[currentDay]._plan[plan]>0 && daily_limits[currentDay]._flag[plan]==false){ 
                limit = daily_limits[currentDay]._plan[plan];
            }
        return limit;

}

function getCurrentDayLimitChange(uint plan , uint256 amount) internal {
    uint256 daily = daily_limits[getCurrentDay()]._plan[plan];
    daily=daily.sub(amount);
    if (daily==0){
        daily_limits[getCurrentDay()]._flag[plan]==true;
    } else{
        daily_limits[getCurrentDay()]._flag[plan]==false;
    }
    daily_limits[getCurrentDay()]._plan[plan]=daily;
    
}

function isRegPlan(uint plan, address investor) internal view returns(bool) {
       	User storage user = users[investor];
       	bool _PlanReg=false;
       if( user.deposits.length!=0){
         	for (uint256 i = 0; i < user.deposits.length;) {
              if(user.deposits[i].plan==plan && user.deposits[i].DepAct==true) {
                _PlanReg=true;
                 break;
        }else{
               _PlanReg=false;
                i++;
        }
     }
        }
           return _PlanReg;

}

function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

function getCurrentDay() public view returns (uint) {
        return (block.timestamp.sub(PROJECT_START)).div(TIME_STEP);
    }

function getUserBonus(uint plan) public view returns (uint256){
    return users[msg.sender].referral_amount[plan];
}

function getUserReferralCount(uint plan) public view returns (uint256){
    return users[msg.sender].referral_count[plan];
}

function getPlanTotalDeposit(uint plan) public view returns(uint256){
    return totalDepositsPlans[plan];
}

function getPlanTotalInvested(uint plan) public view returns(uint256){
    return totalInvestedPlans[plan];
}

function getPlanTotalWithdrawn(uint plan) public view returns(uint256){
    return totalWithdrawnPlans[plan];
}

function getTotalUsers() public view returns(uint256){
    return totalUsers;
}

function getTotalWithdrawn() public view returns(uint256){
    return totalWithdrawn;
}

function getTotalInvested() public view returns(uint256){
    return totalInvested;
}

function getTotalDeposits() public view returns(uint256){
    return totalDeposits;
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