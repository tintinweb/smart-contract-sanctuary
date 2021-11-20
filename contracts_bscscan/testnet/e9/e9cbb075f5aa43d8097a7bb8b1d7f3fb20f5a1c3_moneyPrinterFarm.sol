/**
 *Submitted for verification at BscScan.com on 2021-11-20
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-20
*/

/**

Money Printer Farm

PLANS:
  plan 1 6% 45 days 270% ROI with minimum investment of $10.00, maximum investment of $11,000
  plan 2 7% 35 days 245% ROI with minimum investment of $30.00, maximum investment of $9,000
  plan 3 8% 25 days 200% ROI with minimum investment of $50.00, maximum investment of $7,000
  plan 4 9% 15 days 135% ROI with minimum investment of $70.00, maximum investment of $5,000

FEES:
 10% fee for every investment.6% project fee 2% marketing wallet and 2% will go to the community/buyback wallet.
 buyback/community wallet will be used either to do direct deposits for other other printers within the money printer eco system or helping the community.

REFERRALS:
 1 level referral bonus of 3.5%. 

ANTI WHALE/CONTRACT DUMPING FEATURES:
 40hrs cut off time, user should re-invest or withdraw within the cut off period for the timer to reset. If no action is done after 40hrs earnings will stop.
 Withdrawals can be done every 6 hours. Timer will start after new deposits and re-investments.
 Maximum withdrawal limit of $2,500.
 Maximum deposit of $20,000 for every wallet.

CONTRACT FEATURES:
 Re-invest function.
 Project Statistics, record of total investor count and amount overall and for each plan.
 Dynamic contract.
 Additional plans for special events.
 

 - 6% Sweet Spot. 

**/


// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract moneyPrinterFarm {
	using SafeMath for uint256;
	
	IERC20 public token;
	//address erctoken = 0x1CE0c2827e2eF14D5C4f29a091d735A204794041; /** mainnet AVAX **/
	address erctoken =  0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7; /** testnet BUSD **/
	/** default percentages **/
	uint256 public REFERRAL_PERCENT = 35;
	uint256 public PROJECT_FEE = 15;
	uint256 public COMMUNITY_WALLET_PERCENTAGE = 20;
	uint256 public MARKETING_FEE = 20;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;
	
	/*! anti-whale */
	uint256 public CUTOFF_STEP = 144000; // 40 hrs
    uint256 public MAX_WITHDRAW = 2500000000000000000000; // $2.5k 
	uint256 public WALLET_LIMIT = 20000000000000000000000; // $20k
	uint256 public WITHDRAW_COOLDOWN = 14400; // 4 HOURS
	
	/* adjust percentage per plan. **/
	uint256 public ADD_WITHDRAW_PERCENT_PLAN_1 = 0;
    uint256 public ADD_WITHDRAW_PERCENT_PLAN_2 = 0;
    uint256 public ADD_WITHDRAW_PERCENT_PLAN_3 = 0;
    uint256 public ADD_WITHDRAW_PERCENT_PLAN_4 = 0;
    uint256 public ADDITIONAL_PERCENT_STARTTIME = 0; /** deposits after this timestamp timestamp get additional percentages **/

    /* project statistics **/
	uint256 public totalInvested;
	uint256 public totalReInvested;
	uint256 public totalRefBonus;
	uint256 public totalInvestorCount;

    struct Plan {
        uint256 time;
        uint256 percent;
        uint256 mininvest;
        uint256 maxinvest;
        /** plan statistics **/
        uint256 planTotalInvestorCount;
        uint256 planTotalInvestments;
        uint256 planTotalReInvestorCount;
        uint256 planTotalReInvestments;
        bool planActivated;
    }

    Plan[] internal plans;

	struct Deposit {
        uint8 plan;
		uint256 amount;
		uint256 start;
		bool reinvested;
	}

	struct User {
		Deposit[] deposits;
		mapping (uint8 => uint256) checkpoints; /** a checkpoint for each plan **/
		uint256 cutoff;
		address referrer;
		uint256 referralsCount;
		uint256 bonus;
		uint256 totalBonus;
		uint256 withdrawn;
		uint256 reinvested;
	}

	mapping (address => User) internal users;

	bool public started;
	address payable public projectWallet1;
	address payable public projectWallet2;
	address payable public projectWallet3;
	address payable public marketingWallet;
	address payable public communityWallet;
	address payable public contractAddr;
	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 amount);
	event ReinvestedDeposit(address indexed user, uint8 plan, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

	constructor(address payable owner, address payable projectAddress1, address payable projectAddress2, address payable projectAddress3, address payable marketingAddress, address payable communityAddress) {
		require(!isContract(owner));
		token = IERC20(erctoken);
		contractAddr = owner;
		projectWallet1 = projectAddress1;
		projectWallet2 = projectAddress2;
		projectWallet3 = projectAddress3;
		marketingWallet = marketingAddress;
		communityWallet = communityAddress;

        /**
         
          PLANS:
            plan 1 6% 45 days 270% ROI with minimum investment of $10.00, maximum investment of $11,000
            plan 2 7% 35 days 245% ROI with minimum investment of $30.00, maximum investment of $9,000
            plan 3 8% 25 days 200% ROI with minimum investment of $50.00, maximum investment of $7,000
            plan 4 9% 15 days 135% ROI with minimum investment of $70.00, maximum investment of $5,000
          
        **/

        //plans.push(Plan(45, 60, 10000000000000000000, 11000000000000000000000, 0, 0, 0, 0, true));   /** min $10, max $11,000 **/                
        //plans.push(Plan(35, 70, 10000000000000000000, 9000000000000000000000, 0, 0, 0, 0, true));   /** min $30, max $9,000 **/                  
        //plans.push(Plan(25, 80, 10000000000000000000, 7000000000000000000000, 0, 0, 0, 0, true));  /** min $50, max $7,000 **/                  
        //plans.push(Plan(15, 90, 10000000000000000000, 5000000000000000000000, 0, 0, 0, 0, true)); /** min $70, max $5,000 **/
        
        plans.push(Plan(45, 60, 1000000000000000000, 5000000000000000000, 0, 0, 0, 0, true));   /** min $10, max $11,000 **/                
        plans.push(Plan(35, 70, 1000000000000000000, 5000000000000000000, 0, 0, 0, 0, true));   /** min $30, max $9,000 **/                  
        plans.push(Plan(25, 80, 1000000000000000000, 5000000000000000000, 0, 0, 0, 0, true));  /** min $50, max $7,000 **/                  
        plans.push(Plan(15, 90, 1000000000000000000, 5000000000000000000, 0, 0, 0, 0, true)); /** min $70, max $5,000 **/
	}

	function invest(address referrer, uint8 plan, uint256 amounterc
    ) public {
		if (!started) {
			if (msg.sender == contractAddr) {
				started = true;
			} else revert("Not started yet");
		}
		
        require(plan < plans.length, "Invalid Plan.");
        require(amounterc >= plans[plan].mininvest, "Less than minimum amount required for the selected Plan.");
        require(amounterc <= plans[plan].maxinvest, "More than maximum amount required for the selected Plan.");
        uint256 totalDeposits = getUserTotalDeposits(msg.sender);
        require(totalDeposits < WALLET_LIMIT, "Maximum of $50,000 total deposit only for each wallet.");
        
        /** Check if plan is activated, if not revert transaction. **/
        if(!plans[plan].planActivated){
           revert("Plan selected is disabled."); 
        }
        
        /** transfer deposit to contract. **/ 
        token.transferFrom(address(msg.sender), address(this), amounterc);
        
        /** fees **/
		uint256 fee = amounterc.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
		uint256 com = amounterc.mul(COMMUNITY_WALLET_PERCENTAGE).div(PERCENTS_DIVIDER);
		uint256 mar = amounterc.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
		
		token.transfer(projectWallet1, fee);
		token.transfer(projectWallet2, fee);
		token.transfer(projectWallet3, fee);
		token.transfer(communityWallet, fee);
		token.transfer(contractAddr, com);
		token.transfer(marketingWallet, mar);
        
		User storage user = users[msg.sender];

        if (user.referrer == address(0)) {
            if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
                user.referrer = referrer;
            }

            address upline1 = user.referrer;
            if (upline1 != address(0)) {
                users[upline1].referralsCount = users[upline1].referralsCount.add(1);
            }
        }

        if (user.referrer != address(0)) {
            address upline = user.referrer;
            if (upline != address(0)) {
                uint256 amount = amounterc.mul(REFERRAL_PERCENT).div(PERCENTS_DIVIDER);
                users[upline].bonus = users[upline].bonus.add(amount);
                users[upline].totalBonus = users[upline].totalBonus.add(amount);
                totalRefBonus = totalRefBonus.add(amount);
                emit RefBonus(upline, msg.sender, amount);
            }
        }

		if (user.deposits.length == 0) {
			user.checkpoints[plan] = block.timestamp;
			user.cutoff = block.timestamp.add(CUTOFF_STEP); /** new user gets current time + CUTOFF_STEP for initial time window **/
			emit Newbie(msg.sender);
		}

		user.deposits.push(Deposit(plan, amounterc, block.timestamp, false)); /** deposit from new invest **/

        /** record total amount invested. **/
		totalInvested = totalInvested.add(amounterc);
		
		/** record total investor count. **/
		totalInvestorCount = totalInvestorCount.add(1);
		
		/** total invested for Plan. **/
		plans[plan].planTotalInvestorCount = plans[plan].planTotalInvestorCount.add(1);
		
		/** add to total investment for plan. **/
		plans[plan].planTotalInvestments = plans[plan].planTotalInvestments.add(amounterc);
        
		emit NewDeposit(msg.sender, plan, amounterc);
        emit FeePayed(msg.sender, fee);
	}
	
	function reinvest(uint8 plan) public {
		if (!started) {
			revert("Not started yet");
		}

        require(plan < plans.length, "Invalid plan");
        
        /** Check if plan is activated, if not revert transaction. **/
        if(plans[plan].planActivated != true){
           revert("Plan selected is disabled."); 
        }

        User storage user = users[msg.sender];
        uint256 totalAmount = getUserDividends(msg.sender, int8(plan));
	    uint256 community = totalAmount.mul(COMMUNITY_WALLET_PERCENTAGE).div(PERCENTS_DIVIDER);
	    totalAmount = totalAmount.sub(community);
	    token.transfer(contractAddr, community);
	    
		user.deposits.push(Deposit(plan, totalAmount, block.timestamp, true)); 
        user.reinvested = user.reinvested.add(totalAmount);
        user.checkpoints[plan] = block.timestamp;
        
        /** reinvest will also reset CUTOFF **/
        user.cutoff = block.timestamp.add(CUTOFF_STEP); 
        
		totalReInvested = totalReInvested.add(totalAmount);
		plans[plan].planTotalReInvestments = plans[plan].planTotalReInvestments.add(totalAmount);
		plans[plan].planTotalReInvestorCount = plans[plan].planTotalReInvestorCount.add(1);
		emit ReinvestedDeposit(msg.sender, plan, totalAmount);
	}

	function withdraw() public {
		User storage user = users[msg.sender];

		uint256 totalAmount =  getUserDividends(msg.sender);

		uint256 referralBonus = getUserReferralBonusBeforeTax(msg.sender);
		if (referralBonus > 0) {
			user.bonus = 0;
			totalAmount = totalAmount.add(referralBonus);
		}
		
		/** withdraw tax. 1% to community **/
	    uint256 community = totalAmount.mul(COMMUNITY_WALLET_PERCENTAGE).div(PERCENTS_DIVIDER);
	    totalAmount = totalAmount.sub(community);

		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = token.balanceOf(address(this));
		
		if (contractBalance < totalAmount) {
			user.bonus = totalAmount.sub(contractBalance);
			user.totalBonus = user.totalBonus.add(user.bonus);
			totalAmount = contractBalance;
		}

        for(uint8 i = 0; i < plans.length; i++){
            /** withdrawals can only be done every 6 hours. **/
            if(user.checkpoints[i].add(WITHDRAW_COOLDOWN) > block.timestamp) revert("Withdrawals can only be done every 6 hours.");
           /** global withdraw will reset checkpoints on all plans **/
		    user.checkpoints[i] = block.timestamp;
        }
        
        // excess from max withdraw limit will be available for next withdrawal after 12 hours.
        if(totalAmount > MAX_WITHDRAW) {
            user.bonus = totalAmount.sub(MAX_WITHDRAW);
            totalAmount = MAX_WITHDRAW;
        }
        
        user.cutoff = block.timestamp.add(CUTOFF_STEP); /** global withdraw will also reset CUTOFF **/
		user.withdrawn = user.withdrawn.add(totalAmount);
		
        token.transfer(msg.sender, totalAmount);
        token.transfer(contractAddr, community);
        
		emit Withdrawn(msg.sender, totalAmount);
	}

	function getContractBalance() public view returns (uint256) {
		return token.balanceOf(address(this));
	}

	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent, uint256 minimumInvestment, uint256 maximumInvestment,
	  uint256 planTotalInvestorCount, uint256 planTotalInvestments , uint256 planTotalReInvestorCount, uint256 planTotalReInvestments) {
		time = plans[plan].time;
		percent = plans[plan].percent;
		minimumInvestment = plans[plan].mininvest;
		maximumInvestment = plans[plan].maxinvest;
		planTotalInvestorCount = plans[plan].planTotalInvestorCount;
		planTotalInvestments = plans[plan].planTotalInvestments;
		planTotalReInvestorCount = plans[plan].planTotalReInvestorCount;
		planTotalReInvestments = plans[plan].planTotalReInvestments;
	}
	
	function getUserDividends(address userAddress) public view returns (uint256) {
	    return getUserDividends(userAddress, -1);
	}

	function getUserDividends(address userAddress, int8 plan) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 totalAmount;
		
		uint256 endPoint = block.timestamp < user.cutoff ? block.timestamp : user.cutoff;

		for (uint256 i = 0; i < user.deposits.length; i++) {
		    if(plan > -1){
		        if(user.deposits[i].plan != uint8(plan)){
		            continue;
		        }
		    }
			uint256 finish = user.deposits[i].start.add(plans[user.deposits[i].plan].time.mul(1 days));
			/** check if plan is not yet finished. **/
			if (user.checkpoints[user.deposits[i].plan] < finish) { 
			    
			    uint256 percent = plans[user.deposits[i].plan].percent;
			    if(user.deposits[i].start >= ADDITIONAL_PERCENT_STARTTIME){  /** deposits after this timestamp timestamp get additional percentages **/
                    if(user.deposits[i].plan == 0){
                        percent = percent.add(ADD_WITHDRAW_PERCENT_PLAN_1);                
                    }else if(user.deposits[i].plan == 1){
                        percent = percent.add(ADD_WITHDRAW_PERCENT_PLAN_2);
                    }else if(user.deposits[i].plan == 2){
                        percent = percent.add(ADD_WITHDRAW_PERCENT_PLAN_3);
                    }else if(user.deposits[i].plan == 3){
                        percent = percent.add(ADD_WITHDRAW_PERCENT_PLAN_4);
                    }
			    }
				uint256 share = user.deposits[i].amount.mul(percent).div(PERCENTS_DIVIDER);
				
				uint256 from = user.deposits[i].start > user.checkpoints[user.deposits[i].plan] ? user.deposits[i].start : user.checkpoints[user.deposits[i].plan];
				/** uint256 to = finish < block.timestamp ? finish : block.timestamp; **/
				uint256 to = finish < endPoint ? finish : endPoint;
				if (from < to) {
					totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
				}
			}
		}

		return totalAmount;
	}
	
	function getUserActiveInvestments(address userAddress, uint8 plan) public view returns (uint256){
	    User storage user = users[userAddress];
	    uint256 totalAmount;

		for (uint256 i = 0; i < user.deposits.length; i++) {

	        if(user.deposits[i].plan != uint8(plan)){
	            continue;
	        }
		    
			uint256 finish = user.deposits[i].start.add(plans[user.deposits[i].plan].time.mul(1 days));
			if (user.checkpoints[uint8(plan)] < finish) {
			    /** sum of all unfinished deposits from plan **/
				totalAmount = totalAmount.add(user.deposits[i].amount); 
			}
		}
	    return totalAmount;
	}
	
	function getUserCutoff(address userAddress) public view returns (uint256) {
      return users[userAddress].cutoff;
    }

	function getUserTotalWithdrawn(address userAddress) public view returns (uint256) {
		return users[userAddress].withdrawn;
	}

	function getUserCheckpoint(address userAddress, uint8 plan) public view returns(uint256) {
		return users[userAddress].checkpoints[plan];
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}


    function getUserTotalReferrals(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].referralsCount;
    }
	
	function getUserReferralBonusBeforeTax(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}

	function getUserReferralTotalBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus;
	}

	function getUserReferralWithdrawn(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus.sub(users[userAddress].bonus);
	}

	function getUserAvailable(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus.add(getUserDividends(userAddress));
	}

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint256 amount) {
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount.add(users[userAddress].deposits[i].amount);
		}
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint8 plan, uint256 percent, uint256 amount, uint256 start, uint256 finish, bool reinvested) {
	    User storage user = users[userAddress];

		plan = user.deposits[index].plan;
		percent = plans[plan].percent;
		amount = user.deposits[index].amount;
		start = user.deposits[index].start;
		finish = user.deposits[index].start.add(plans[user.deposits[index].plan].time.mul(1 days));
		reinvested = user.deposits[index].reinvested;
	}

	function getSiteInfo() public view returns(uint256 _totalInvested, uint256 _totalReInvested, uint256 _totalBonus, uint256 _totalInvestorCount) {
		return(totalInvested, totalReInvested, totalRefBonus, totalInvestorCount);
	}

	function getUserInfo(address userAddress) public view returns(uint256 totalDeposit, uint256 totalWithdrawn, uint256 totalReferrals) {
		return(getUserTotalDeposits(userAddress), getUserTotalWithdrawn(userAddress), getUserTotalReferrals(userAddress));
	}
	
	/** Get Block Timestamp **/
	function getBlockTimeStamp() public view returns (uint256) {
	    return block.timestamp;
	}
	
	/** Get Plans Length **/
	function getPlansLength() public view returns (uint256) {
	    return plans.length;
	}

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
    
    /** Add additional plans in the Plan structure. **/
    function addAdditionalPlans(uint256 time, uint256 percent, uint256 mininvest, uint256 maxinvest, bool planActivated) external {
        require(msg.sender == contractAddr);
        plans.push(Plan(time, percent, mininvest, maxinvest, 0, 0, 0, 0, planActivated)); 
    }
    
    function _projectWallet1(address value) external {
        require(msg.sender == contractAddr);
        projectWallet1 = payable(value);
    }
    
    function _projectWallet2(address value) external {
        require(msg.sender == contractAddr);
        projectWallet2 = payable(value);
    }
    
    function _projectWallet3(address value) external {
        require(msg.sender == contractAddr);
        projectWallet3 = payable(value);
    }
    
    function _marketingWallet(address value) external {
        require(msg.sender == contractAddr);
        marketingWallet = payable(value);
    }
    
    function _CommunityWallet(address value) external {
        require(msg.sender == contractAddr);
        communityWallet = payable(value);
    }
    
    function _COMMUNITY_WALLET_PERCENTAGE(uint256 value) external {
        require(msg.sender == contractAddr);
        require(value < 20); /** 2 max **/
        COMMUNITY_WALLET_PERCENTAGE = value;
    }
    
    function _REFERRAL_PERCENT(uint256 value) external {
        require(msg.sender == contractAddr);
        require(value < 100); /** 10 max **/
        REFERRAL_PERCENT = value;
    }
    
    function _PROJECT_FEE(uint256 value) external {
        require(msg.sender == contractAddr);
        require(value < 120); /** 12 max **/
        PROJECT_FEE = value;
    }
    
    function _MARKETING_FEE(uint256 value) external {
        require(msg.sender == contractAddr);
        require(value < 100); /** 10 max **/
        MARKETING_FEE = value;
    }
    
    function _PlanPercent(uint8 plan, uint256 value) external {
        require(msg.sender == contractAddr);
        plans[plan].percent = value;
    }
    
    function _PlanTime(uint8 plan, uint256 value) external {
        require(msg.sender == contractAddr);
        plans[plan].time = value;
    }
    
    function _PlanMinInvest(uint8 plan, uint256 value) external {
        require(msg.sender == contractAddr);
        plans[plan].mininvest = value;
    }
    
    function _PlanMaxInvest(uint8 plan, uint256 value) external {
        require(msg.sender == contractAddr);
        plans[plan].maxinvest = value;
    }
    
    function _PlanActivated(uint8 plan, bool value) external {
        require(msg.sender == contractAddr);
        plans[plan].planActivated = value;
    }
    
    function setADDITIONAL_PERCENT_STARTTIME(uint256 value) external {
        require(msg.sender == contractAddr);
        ADDITIONAL_PERCENT_STARTTIME = value;
    }
    
    function _AdditionalPercent_Plan1(uint256 value) external {
        require(msg.sender == contractAddr);
        require(value < 100); /** 100 = 10% **/
        ADD_WITHDRAW_PERCENT_PLAN_1 = value;
    }
    
    function _AdditionalPercent_Plan2(uint256 value) external {
        require(msg.sender == contractAddr);
        require(value < 100); /** 100 = 10% **/
        ADD_WITHDRAW_PERCENT_PLAN_2 = value;
    }
    
    function _AdditionalPercent_Plan3(uint256 value) external {
        require(msg.sender == contractAddr);
        require(value < 100); /** 100 = 10% **/
        ADD_WITHDRAW_PERCENT_PLAN_3 = value;
    }
    
    function _AdditionalPercent_Plan4(uint256 value) external {
        require(msg.sender == contractAddr);
        require(value < 100); /** 100 = 10% **/
        ADD_WITHDRAW_PERCENT_PLAN_4 = value;
    }
    
    function _CUTOFF_STEP(uint256 value) external {
        require(msg.sender == contractAddr);
        CUTOFF_STEP = value;
    }
    
    function _MAX_WITHDRAW(uint256 value) external {
        require(msg.sender == contractAddr);
        MAX_WITHDRAW = value;
    }
    
    function _WALLET_LIMIT(uint256 value) external {
        require(msg.sender == contractAddr);
        WALLET_LIMIT = value;
    }
    
    function _WITHDRAW_COOLDOWN(uint256 value) external {
        require(msg.sender == contractAddr);
        WITHDRAW_COOLDOWN = value;
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