/**
 *Submitted for verification at BscScan.com on 2021-11-13
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;


contract BUSDMoonFarmtest {
	using SafeMath for uint256;

	uint256 public INVEST_MIN_AMOUNT = 968; // 0.005 bnb
	uint256 public REFERRAL_PERCENT = 50;
	uint256 public PROJECT_FEE = 100; // tax on deposit
	uint256 public MARKETING_FEE = 50; // tax on withdraw: 5% to marketing
	uint256 public CONTRACT_LONGEVITY_FEE = 100; // tax on withdraw: keep 10% in contract
	
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;
	uint256 public CUTOFF_STEP = 72 hours;
	
	uint256 public ADDITIONAL_PERCENT_PLAN_1 = 0;
    uint256 public ADDITIONAL_PERCENT_PLAN_2 = 0;
    uint256 public ADDITIONAL_PERCENT_PLAN_3 = 0;
    uint256 public ADDITIONAL_PERCENT_PLAN_4 = 0;
    uint256 public ADDITIONAL_PERCENT_STARTTIME = 0; // deposits after this timestamp timestamp get additional percentages

	uint256 public totalInvested;
	uint256 public totalReInvested;
	uint256 public totalRefBonus;

    struct Plan {
        uint256 time;
        uint256 percent;
        uint256 mininvest;
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
		mapping (uint8 => uint256) checkpoints; // a checkpoint for each plan
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
	address payable public projectWallet;
	address payable public marketingWallet;
	address public contractOwner;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 amount);
	event ReinvestedDeposit(address indexed user, uint8 plan, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

	constructor(address pOwner, address payable pProjectWwallet, address payable pMarkeetingWallet) {
		require(!isContract(pOwner));
		contractOwner = pOwner;
		projectWallet = pProjectWwallet;
		marketingWallet = pMarkeetingWallet;

        plans.push(Plan(7, 230, 0));                      // Plan 1 = 23% for 7 Days    = ROI 120.75% (after Tax)
        plans.push(Plan(30, 70, 0));                      // Plan 2 = 7% for 30 Days    = ROI 157.5% (after Tax)
        plans.push(Plan(50, 50, 0));                      // Plan 3 = 5% for 50 Days    = ROI 187,5% (after Tax)
        plans.push(Plan(5, 320, 1000000000000000000));    // Plan 4 = 32% for 5 Days    = ROI 120% (after Tax) VIP-Plan with 2 BNB Minimum deposit
	}

	function invest(address referrer, uint8 plan) public payable {
		if (!started) {
			if (msg.sender == contractOwner) {
				started = true;
			} else revert("Not started yet");
		}
		
        require(plan < plans.length, "Invalid plan");
        require(msg.value >= INVEST_MIN_AMOUNT);
        require(msg.value >= plans[plan].mininvest);

		uint256 fee = msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
		projectWallet.transfer(fee);
		emit FeePayed(msg.sender, fee);

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
                uint256 amount = msg.value.mul(REFERRAL_PERCENT).div(PERCENTS_DIVIDER);
                users[upline].bonus = users[upline].bonus.add(amount);
                users[upline].totalBonus = users[upline].totalBonus.add(amount);
                emit RefBonus(upline, msg.sender, amount);
            }
        }

		if (user.deposits.length == 0) {
			user.checkpoints[plan] = block.timestamp;
			user.cutoff = block.timestamp.add(CUTOFF_STEP); // new user gets current time + CUTOFF_STEP for initial time window
			emit Newbie(msg.sender);
		}

		user.deposits.push(Deposit(plan, msg.value, block.timestamp, false)); // deposit from new invest

		totalInvested = totalInvested.add(msg.value);

		emit NewDeposit(msg.sender, plan, msg.value);
	}
	
	function reinvest(uint8 plan) public {
		if (!started) {
			revert("Not started yet");
		}

        require(plan < plans.length, "Invalid plan");

        User storage user = users[msg.sender];
        uint256 totalAmount = getUserDividendsBeforeTAX(msg.sender, int8(plan));
        
    	// withdraw tax. 10% to keep in contract. 5% to marketing
	    uint256 marketing = totalAmount.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
	    uint256 contractLengevity = totalAmount.mul(CONTRACT_LONGEVITY_FEE).div(PERCENTS_DIVIDER);
	    totalAmount = totalAmount.sub(marketing).sub(contractLengevity);
	    
	    marketingWallet.transfer(marketing);

		user.deposits.push(Deposit(plan, totalAmount, block.timestamp, true)); //deposit from reinvest
        user.reinvested = user.reinvested.add(totalAmount);
        user.checkpoints[plan] = block.timestamp;
        user.cutoff = block.timestamp.add(CUTOFF_STEP); // reinvest will also reset CUTOFF
        
		totalReInvested = totalReInvested.add(totalAmount);

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
		
	    uint256 marketing = totalAmount.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
	    uint256 contractLengevity = totalAmount.mul(CONTRACT_LONGEVITY_FEE).div(PERCENTS_DIVIDER);
	    totalAmount = totalAmount.sub(marketing).sub(contractLengevity);

		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			user.bonus = totalAmount.sub(contractBalance);
			user.totalBonus = user.totalBonus.add(user.bonus);
			totalAmount = contractBalance;
		}

        for( uint8 i = 0; i < plans.length; i++){
		    user.checkpoints[i] = block.timestamp; // global withdraw will reset checkpoints on all plans
        }
        user.cutoff = block.timestamp.add(CUTOFF_STEP); // global withdraw will also reset CUTOFF
		user.withdrawn = user.withdrawn.add(totalAmount);

		payable(address(msg.sender)).transfer(totalAmount);
		marketingWallet.transfer(marketing);

		emit Withdrawn(msg.sender, totalAmount);
	}

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent) {
		time = plans[plan].time;
		percent = plans[plan].percent;
	}
	
	function getUserDividendsAfterTAX(address userAddress) public view returns (uint256) {
	    return getUserDividendsAfterTAX(userAddress, -1);
	}
	
	function getUserDividendsAfterTAX(address userAddress, int8 plan) public view returns (uint256) {
	    uint256 amount = getUserDividendsBeforeTAX(userAddress, plan);
	    
	    uint256 marketing = amount.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
	    uint256 contractLengevity = amount.mul(CONTRACT_LONGEVITY_FEE).div(PERCENTS_DIVIDER);
	    amount = amount.sub(marketing).sub(contractLengevity);
	    
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
				//uint256 to = finish < block.timestamp ? finish : block.timestamp;
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
				totalAmount = totalAmount.add(user.deposits[i].amount); // sum of all unfinished deposits from plan
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
	    uint256 contractLengevity = amount.mul(CONTRACT_LONGEVITY_FEE).div(PERCENTS_DIVIDER);
	    amount = amount.sub(marketing).sub(contractLengevity);
	    
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

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint8 plan, uint256 percent, uint256 amount, uint256 start, uint256 finish) {
	    User storage user = users[userAddress];

		plan = user.deposits[index].plan;
		percent = plans[plan].percent;
		amount = user.deposits[index].amount;
		start = user.deposits[index].start;
		finish = user.deposits[index].start.add(plans[user.deposits[index].plan].time.mul(1 days));
	}

	function getSiteInfo() public view returns(uint256 _totalInvested, uint256 _totalBonus) {
		return(totalInvested, totalRefBonus);
	}

	function getUserInfo(address userAddress) public view returns(uint256 totalDeposit, uint256 totalWithdrawn, uint256 totalReferrals) {
		return(getUserTotalDeposits(userAddress), getUserTotalWithdrawn(userAddress), getUserTotalReferrals(userAddress));
	}

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
    
    
    function set_projectWallet(address value) external {
        require(msg.sender == contractOwner);
        projectWallet = payable(value);
    }
    
    function set_marketingWallet(address value) external {
        require(msg.sender == contractOwner);
        marketingWallet = payable(value);
    }
    
    function set_INVEST_MIN_AMOUNT(uint256 value) external {
        require(msg.sender == contractOwner);
        INVEST_MIN_AMOUNT = value;
    }
    
    function set_REFERRAL_PERCENT(uint256 value) external {
        require(msg.sender == contractOwner);
        require(value < 100); // 10 max
        REFERRAL_PERCENT = value;
    }
    
    function set_PROJECT_FEE(uint256 value) external {
        require(msg.sender == contractOwner);
        require(value < 120); // 12 max
        PROJECT_FEE = value;
    }
        
    function set_CONTRACT_LONGEVITY_FEE(uint256 value) external {
        require(msg.sender == contractOwner);
        require(value < 250); // 25 max
        
        CONTRACT_LONGEVITY_FEE = value;
    }
    
    function set_MARKETING_FEE(uint256 value) external {
        require(msg.sender == contractOwner);
        require(value < 100); // 10 max
        MARKETING_FEE = value;
    }
    
    function set_PlanPercent(uint8 plan, uint256 value) external {
        require(msg.sender == contractOwner);
        plans[plan].percent = value;
    }
    
    function set_PlanTime(uint8 plan, uint256 value) external {
        require(msg.sender == contractOwner);
        plans[plan].time = value;
    }
    
    function set_PlanMinInvest(uint8 plan, uint256 value) external {
        require(msg.sender == contractOwner);
        plans[plan].mininvest = value;
    }
    
    function setAdditionalPercent_Plan1(uint256 value) external {
        require(msg.sender == contractOwner);
        require(value < 100); // 100 = 10%
        ADDITIONAL_PERCENT_PLAN_1 = value;
    }
    
    function setAdditionalPercent_Plan2(uint256 value) external {
        require(msg.sender == contractOwner);
        require(value < 100); // 100 = 10%
        ADDITIONAL_PERCENT_PLAN_2 = value;
    }
    
    function setAdditionalPercent_Plan3(uint256 value) external {
        require(msg.sender == contractOwner);
        require(value < 100); // 100 = 10%
        ADDITIONAL_PERCENT_PLAN_3 = value;
    }
    
    function setAdditionalPercent_Plan4(uint256 value) external {
        require(msg.sender == contractOwner);
        require(value < 100); // 100 = 10%
        ADDITIONAL_PERCENT_PLAN_4 = value;
    }
    
    function setCUTOFF_STEP(uint256 value) external {
        require(msg.sender == contractOwner);
        CUTOFF_STEP = value;
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