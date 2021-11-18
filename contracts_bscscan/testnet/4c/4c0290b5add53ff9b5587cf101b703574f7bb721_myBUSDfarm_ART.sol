/**
 *Submitted for verification at BscScan.com on 2021-11-17
*/

/**

MY BUSD FARM - ART

PLANS:
  plan 1 7% 30 days 180% ROI with 25% tax = 135% ROI
  plan 2 5% 50 days 250% ROI with 25% tax = 187.5% ROI
  plan 3 23% 7 days 161% ROI with 25% tax = 120.75% ROI - VIP HUSTLER
  plan 4 32% 5 days 160% ROI with 25% tax = 120% ROI - VIP BALLLER

FEES:
 10% fee for every investment. 9% will go to the project wallet, 1% will go to the charity wallet.
 25% fee on withdrawals and reinvestment, 20% will be kept in the contract, 5% will go to marketing wallet.

CUT OFF TIME:
 48HRS cut off time, after 48 ours of not claiming or reinvesting the earning will stop.

REFERRALS:
 1 level referral bonus of 5%. 

ANTI WHALE/CUT OFF TIME FEATURES:
 48hrs cut off time, user should re-invest or withdraw within the cut off period.
 Users can only withdraw a maximum amount of $15,000.00. Excess dividends are sent back to the user's account available for the next withdrawal.

VIP PLANS:
 Plan 3 - VIP HUSTLER 
   Users are required to have a total deposit amount of $750.00 in the normal plan before they can invest into the VIP Plan. Minimum investment is $1,500.00
 Plan 4 - VIP BALLLER 
   Users are required to have a total deposit amount of $1,500.00 in the normal plan before they can invest into the VIP Plan. Minimum investment is $3,000.00
 
PROJECT FEATURES:
 Re-invest button, users can now reinvest without withdrawing their earnings, using the re-invest button resets the plan and is counted as new investments.
 Contract is compiled using the latest compiler version.
 Adjustable Plan rewards.
 First farm project to have dynamic setters. Parameters can be changed for events, promotions and to keep the project running and sustainable.
 Statistic counters:
    Total Number of investors/re-investors in the project.
    Total Amount of invesments/re-invested in the project.
    Total Number of investors/re-investors per plan.
    Total Amount of invesments/re-invested per plan.

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

contract myBUSDfarm_ART {
	using SafeMath for uint256;
	
	IERC20 public token_BUSD;
	//address erctoken = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; /** mainnet BUSD **/
	address erctoken =  0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7; /** testnet BUSD **/
	
	/** default percentages **/
	uint256 public REFERRAL_PERCENT = 50;
	uint256 public PROJECT_FEE = 90;
	uint256 public CHARITY_WALLET_PERCENTAGE = 10;
	uint256 public MARKETING_FEE = 50;
	uint256 public CONTRACT_LONGEVITY_FEE = 200;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;
	/* anti whale features. **/
	uint256 public CUTOFF_STEP = 48 hours;
	uint256 public MAX_WITHDRAW = 15000000000000000000000; /** 15,000.00 **/
	/** requirement of total investment in the normal plan. **/
	uint256 public VIP_HUSTLER_MINIMUM = 750000000000000000000; /** $750.00 **/
	uint256 public VIP_BALLER_MINIMUM = 1500000000000000000000; /** $1,500.00 **/
	
	/* adjust percentage per plan. **/
	uint256 public ADDITIONAL_PERCENT_PLAN_1 = 0;
    uint256 public ADDITIONAL_PERCENT_PLAN_2 = 0;
    uint256 public ADDITIONAL_PERCENT_PLAN_3 = 0;
    uint256 public ADDITIONAL_PERCENT_PLAN_4 = 0;
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
        /** plan statistics **/
        uint256 planTotalInvestorCount;
        uint256 planTotalInvestments;
        uint256 planTotalReInvestorCount;
        uint256 planTotalReInvestments;
        bool isVip;
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
	address payable public partnerDev;
	address payable public projectWallet;
	address payable public marketingWallet;
	address payable public charityWallet;
	address public contractOwner;
	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 amount);
	event ReinvestedDeposit(address indexed user, uint8 plan, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

	constructor(address pOwner, address payable pPartnerDev, address payable pProjectWwallet, address payable pMarketingWallet, address payable pCharityWallet) {
		require(!isContract(pOwner));
		token_BUSD = IERC20(erctoken);
		contractOwner = pOwner;
		partnerDev = pPartnerDev;
		projectWallet = pProjectWwallet;
		marketingWallet = pMarketingWallet;
		charityWallet = pCharityWallet;

        /**
         
          plan 1 7% 30 days 180% ROI with 25% tax = 135% ROI
          plan 2 5% 50 days 250% ROI with 25% tax = 187.5% ROI
          plan 3 23% 7 days 161% ROI with 25% tax = 120.75% ROI
          plan 4 32% 5 days 160% ROI with 25% tax = 120% ROI
          
          Plan 4 is the VIP Plan,
          Users are required to have a total deposit amount of $500.00 in the normal plan before they can invest into the VIP Plan.
          
        **/

        plans.push(Plan(30, 70, 10000000000000000000, 0, 0, 0, 0, false, true));   /** $10 **/                
        plans.push(Plan(50, 50, 10000000000000000000, 0, 0, 0, 0, false, true));   /** $10 **/                  
        plans.push(Plan(7, 230, 1500000000000000000000, 0, 0, 0, 0, true, true));   /** $1,500 **/                  
        plans.push(Plan(5, 320, 3000000000000000000000, 0, 0, 0, 0, true, true)); /** $3,500 **/
	}

	function invest(address referrer, uint8 plan, uint256 amounterc
    ) public {
		if (!started) {
			if (msg.sender == contractOwner || msg.sender == partnerDev) {
				started = true;
			} else revert("Contract not yet started.");
		}
		
        require(plan < plans.length, "Invalid Plan.");
        require(amounterc >= plans[plan].mininvest, "Less than minimum amount required for the selected PLAN.");
        
        /** Check if plan is activated, if not revert transaction. **/
        if(!plans[plan].planActivated){
           revert("Plan selected is disabled."); 
        }
        
        uint256 activeNonVipDeposits = getUserActiveNonVIPInvestments(msg.sender);
        
        if(plans[plan].isVip && plan == 2 && activeNonVipDeposits < VIP_HUSTLER_MINIMUM){
            revert("Not Qualified for the VIP HUSTLER POOL."); 
        }
        
        if(plans[plan].isVip && plan == 3 && activeNonVipDeposits < VIP_BALLER_MINIMUM){
            revert("Not Qualified for the VIP BALLER POOL."); 
        }
        
        /** transfer deposit to contract. **/ 
        token_BUSD.transferFrom(address(msg.sender), address(this), amounterc);
        
        /** fees **/
		uint256 fee = amounterc.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
		uint256 charity = amounterc.mul(CHARITY_WALLET_PERCENTAGE).div(PERCENTS_DIVIDER);
		
		token_BUSD.transfer(projectWallet, fee); /** 9% **/
		token_BUSD.transfer(charityWallet, charity); /** 1% **/
        
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
		require(started, "Contract not yet started.");
        require(plan < plans.length, "Invalid plan");
        
        /** Check if plan is activated, if not revert transaction. **/
        if(plans[plan].planActivated != true){
           revert("Plan selected is disabled."); 
        }

        User storage user = users[msg.sender];
        uint256 totalAmount = getUserDividendsBeforeTAX(msg.sender, int8(plan));
        
    	/** withdraw tax. 20% to keep in contract. 5% to marketing **/
	    uint256 marketing = totalAmount.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
	    uint256 contractLongevity = totalAmount.mul(CONTRACT_LONGEVITY_FEE).div(PERCENTS_DIVIDER);
	    totalAmount = totalAmount.sub(marketing).sub(contractLongevity);
	    
	    /** 5% goes to marketing wallet **/
	    token_BUSD.transfer(marketingWallet, marketing);
	    
	    /** deposit from reinvest **/
		user.deposits.push(Deposit(plan, totalAmount, block.timestamp, true)); 
        user.reinvested = user.reinvested.add(totalAmount);
        user.checkpoints[plan] = block.timestamp;
        
        /** reinvest will also reset CUTOFF **/
        user.cutoff = block.timestamp.add(CUTOFF_STEP); 
        
        /** record total amount reinvested **/
		totalReInvested = totalReInvested.add(totalAmount);
		
		/** record total reinvested amount for plan. **/
		plans[plan].planTotalReInvestments = plans[plan].planTotalReInvestments.add(totalAmount);
		
		/** record total number of reinvestors for plan. **/
		plans[plan].planTotalReInvestorCount = plans[plan].planTotalReInvestorCount.add(1);

		emit ReinvestedDeposit(msg.sender, plan, totalAmount);
	}

	function withdraw() public {
		User storage user = users[msg.sender];

		uint256 totalAmount =  getUserDividendsBeforeTAX(msg.sender);

		uint256 referralBonus = getUserReferralBonusBeforeTax(msg.sender);
		if (referralBonus > 0) {
			user.bonus = 0;
			totalAmount = totalAmount.add(referralBonus);
		}
		
		/** withdraw tax. 20% to keep in contract. 5% to marketing **/
	    uint256 marketing = totalAmount.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
	    uint256 contractLengevity = totalAmount.mul(CONTRACT_LONGEVITY_FEE).div(PERCENTS_DIVIDER);
	    totalAmount = totalAmount.sub(marketing).sub(contractLengevity);

		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = token_BUSD.balanceOf(address(this));
		
		if (contractBalance < totalAmount) {
			user.bonus = totalAmount.sub(contractBalance);
			user.totalBonus = user.totalBonus.add(user.bonus);
			totalAmount = contractBalance;
		}

        for(uint8 i = 0; i < plans.length; i++){
		    user.checkpoints[i] = block.timestamp; /** global withdraw will reset checkpoints on all plans **/
        }
        
        /** Users can claim within 48 hours with a maximum amount of $10,000.00. 
        Excess dividends are sent back to the user's account available for the next withdrawal. **/
        if(totalAmount > MAX_WITHDRAW) {
            user.bonus = totalAmount.sub(MAX_WITHDRAW);
            totalAmount = MAX_WITHDRAW;
        }
        
        user.cutoff = block.timestamp.add(CUTOFF_STEP); /** global withdraw will also reset CUTOFF **/
		user.withdrawn = user.withdrawn.add(totalAmount);
		
		 /** amount to be withdrawn less tax. **/
        token_BUSD.transfer(msg.sender, totalAmount);
        
         /** 5% goes to marketing wallet **/
        token_BUSD.transfer(marketingWallet, marketing);
        
		emit Withdrawn(msg.sender, totalAmount);
	}

	function getContractBalance() public view returns (uint256) {
		return token_BUSD.balanceOf(address(this));
	}

	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent, uint256 minimumInvestment,
	  uint256 planTotalInvestorCount, uint256 planTotalInvestments , uint256 planTotalReInvestorCount, uint256 planTotalReInvestments) {
		time = plans[plan].time;
		percent = plans[plan].percent;
		minimumInvestment = plans[plan].mininvest;
		planTotalInvestorCount = plans[plan].planTotalInvestorCount;
		planTotalInvestments = plans[plan].planTotalInvestments;
		planTotalReInvestorCount = plans[plan].planTotalReInvestorCount;
		planTotalReInvestments = plans[plan].planTotalReInvestments;
	}
	
	function getUserDividendsAfterTAX(address userAddress) public view returns (uint256) {
	    return getUserDividendsAfterTAX(userAddress, -1);
	}
	
	function getUserDividendsAfterTAX(address userAddress, int8 plan) public view returns (uint256) {
	    uint256 amount = getUserDividendsBeforeTAX(userAddress, plan);
	    
	    uint256 marketing = amount.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
	    uint256 contractLongevity = amount.mul(CONTRACT_LONGEVITY_FEE).div(PERCENTS_DIVIDER);
	    amount = amount.sub(marketing).sub(contractLongevity);
	    
	    return amount;
	}

	
	function getUserDividendsBeforeTAX(address userAddress) public view returns (uint256) {
	    return getUserDividendsBeforeTAX(userAddress, -1);
	}

	function getUserDividendsBeforeTAX(address userAddress, int8 plan) public view returns (uint256) {
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
			    if(user.deposits[i].start >= ADDITIONAL_PERCENT_STARTTIME){
                    if(user.deposits[i].plan == 0){
                        percent = percent.add(ADDITIONAL_PERCENT_PLAN_1);                
                    }else if(user.deposits[i].plan == 1){
                        percent = percent.add(ADDITIONAL_PERCENT_PLAN_2);
                    }else if(user.deposits[i].plan == 2){
                        percent = percent.add(ADDITIONAL_PERCENT_PLAN_3);
                    }else if(user.deposits[i].plan == 3){
                        percent = percent.add(ADDITIONAL_PERCENT_PLAN_4);
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
	
	function getUserActiveNonVIPInvestments(address userAddress) public view returns (uint256){
	    uint256 totalAmount;

		/** get total active investments in non-vip plans. **/
        for(uint8 i = 0; i < plans.length; i++){
            if(!plans[i].isVip){
              totalAmount = totalAmount.add(getUserActiveInvestments(userAddress, i));
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

	function getUserReferralBonusAfterTax(address userAddress) public view returns(uint256) {
		uint256 amount = users[userAddress].bonus;
		
	    uint256 marketing = amount.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
	    uint256 contractLongevity = amount.mul(CONTRACT_LONGEVITY_FEE).div(PERCENTS_DIVIDER);
	    amount = amount.sub(marketing).sub(contractLongevity);
	    
	    return amount;
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
		return getUserReferralBonusAfterTax(userAddress).add(getUserDividendsAfterTAX(userAddress));
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
    function addAdditionalPlans(uint256 time, uint256 percent, uint256 mininvest, bool isVip, bool planActivated) external {
        require(msg.sender == contractOwner || msg.sender == partnerDev);
        plans.push(Plan(time, percent, mininvest, 0, 0, 0, 0, isVip, planActivated)); 
    }
    
    function set_projectWallet(address value) external {
        require(msg.sender == contractOwner || msg.sender == partnerDev);
        projectWallet = payable(value);
    }
    
    function set_marketingWallet(address value) external {
        require(msg.sender == contractOwner || msg.sender == partnerDev);
        marketingWallet = payable(value);
    }
    
    function set_CharityWallet(address value) external {
        require(msg.sender == contractOwner || msg.sender == partnerDev);
        charityWallet = payable(value);
    }
    
    function set_CHARITY_WALLET_PERCENTAGE(uint256 value) external {
        require(msg.sender == contractOwner || msg.sender == partnerDev);
        require(value < 20); /** 2 max **/
        CHARITY_WALLET_PERCENTAGE = value;
    }
    
    function set_REFERRAL_PERCENT(uint256 value) external {
        require(msg.sender == contractOwner || msg.sender == partnerDev);
        require(value < 100); /** 10 max **/
        REFERRAL_PERCENT = value;
    }
    
    function set_PROJECT_FEE(uint256 value) external {
        require(msg.sender == contractOwner || msg.sender == partnerDev);
        require(value < 120); /** 12 max **/
        PROJECT_FEE = value;
    }
        
    function set_CONTRACT_LONGEVITY_FEE(uint256 value) external {
        require(msg.sender == contractOwner || msg.sender == partnerDev);
        require(value < 250); /** 25 max **/
        
        CONTRACT_LONGEVITY_FEE = value;
    }
    
    function set_MARKETING_FEE(uint256 value) external {
        require(msg.sender == contractOwner || msg.sender == partnerDev);
        require(value < 100); /** 10 max **/
        MARKETING_FEE = value;
    }
    
    function set_PlanPercent(uint8 plan, uint256 value) external {
        require(msg.sender == contractOwner || msg.sender == partnerDev);
        plans[plan].percent = value;
    }
    
    function set_PlanTime(uint8 plan, uint256 value) external {
        require(msg.sender == contractOwner || msg.sender == partnerDev);
        plans[plan].time = value;
    }
    
    function set_PlanMinInvest(uint8 plan, uint256 value) external {
        require(msg.sender == contractOwner || msg.sender == partnerDev);
        plans[plan].mininvest = value;
    }
    
    function set_PlanIsVIP(uint8 plan, bool value) external {
        require(msg.sender == contractOwner || msg.sender == partnerDev);
        plans[plan].isVip = value;
    }
    
    function set_PlanActivated(uint8 plan, bool value) external {
        require(msg.sender == contractOwner || msg.sender == partnerDev);
        plans[plan].planActivated = value;
    }
    
    function setADDITIONAL_PERCENT_STARTTIME(uint256 value) external {
        require(msg.sender == contractOwner || msg.sender == partnerDev);
        ADDITIONAL_PERCENT_STARTTIME = value;
    }
    
    function setAdditionalPercent_Plan1(uint256 value) external {
        require(msg.sender == contractOwner || msg.sender == partnerDev);
        require(value < 100); /** 100 = 10% **/
        ADDITIONAL_PERCENT_PLAN_1 = value;
    }
    
    function setAdditionalPercent_Plan2(uint256 value) external {
        require(msg.sender == contractOwner || msg.sender == partnerDev);
        require(value < 100); /** 100 = 10% **/
        ADDITIONAL_PERCENT_PLAN_2 = value;
    }
    
    function setAdditionalPercent_Plan3(uint256 value) external {
        require(msg.sender == contractOwner || msg.sender == partnerDev);
        require(value < 100); /** 100 = 10% **/
        ADDITIONAL_PERCENT_PLAN_3 = value;
    }
    
    function setAdditionalPercent_Plan4(uint256 value) external {
        require(msg.sender == contractOwner || msg.sender == partnerDev);
        require(value < 100); /** 100 = 10% **/
        ADDITIONAL_PERCENT_PLAN_4 = value;
    }
    
    function setCUTOFF_STEP(uint256 value) external {
        require(msg.sender == contractOwner || msg.sender == partnerDev);
        CUTOFF_STEP = value;
    }
    
    function setVIP_HUSTLER_MINIMUM(uint256 value) external {
        require(msg.sender == contractOwner || msg.sender == partnerDev);
        VIP_HUSTLER_MINIMUM = value;
    }
    
    function setVIP_BALLER_MINIMUM(uint256 value) external {
        require(msg.sender == contractOwner || msg.sender == partnerDev);
        VIP_BALLER_MINIMUM = value;
    }
    
    function setMAX_WITHDRAW(uint256 value) external {
        require(msg.sender == contractOwner || msg.sender == partnerDev);
        MAX_WITHDRAW = value;
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