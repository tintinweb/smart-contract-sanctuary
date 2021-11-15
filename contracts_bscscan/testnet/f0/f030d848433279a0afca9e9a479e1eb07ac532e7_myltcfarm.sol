/**
 *Submitted for verification at BscScan.com on 2021-11-15
*/

/**

MY LTC FARM

PLANS:
  plan 1 6% 30 days 180% ROI with 25% tax = 135% ROI
  plan 2 5% 50 days 250% ROI with 25% tax = 187.5% ROI
  plan 3 4% 70 days 280% ROI with 25% tax = 210% ROI
  plan 4 32% 5 days 160% ROI with 25% tax = 120% ROI

FEES:
 10% fee for every investment which 0.5% will be directly deposited to LTC Miner contract.(deposits from miners can be adjusted base on the miners need.)
 25% fee on withdrawals and reinvestment, 20% will be kept in the contract, 5% will go to marketing wallet.

CUT OFF TIME:
 48HRS cut off time, after 48 ours of not claiming or reinvesting the earning will stop.

REFERRALS:
 5% referral bonus. 1 level.

ANTI WHALE FEATURES:
 Wallet max deposit limited to only 75 LTC($20,000.00)
 48hrs cut off time, user should re-invest or withdraw before the 48hrs timer ends.

VIP PLAN:
 Plan 4 is the VIP Plan,
 User will need to have a total amount of 1.5 LTC($400.00) in other plans to qualify.
 5 LTC minimum investment. ($2000.00)

*/


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

contract myltcfarm {
	using SafeMath for uint256;
	
	IERC20 public token_LTC;
	address erctoken = 0xEC5dCb5Dbf4B114C9d0F65BcCAb49EC54F6A0867; //testnet DAI
	//0x4338665CBB7B2485A8855A139b75D5e34AB0DB94 mainnet litecoin
	uint256 public INVEST_MIN_AMOUNT = 0.005 ether; // 0.005 ltc
	uint256 public REFERRAL_PERCENT = 50; //5% referral bonus
	uint256 public PROJECT_FEE = 95; // 9.5% tax on deposit
	uint256 public LTC_CONTRACT_DEPOSIT = 5; // 0.5% tax on deposit will be directly deposited to LTC MINER
	uint256 public MARKETING_FEE = 40; // tax on withdraw: 4% to marketing
	uint256 public CONTRACT_LONGEVITY_FEE = 200; // tax on withdraw: keep 20% in contract
	
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;
	
	uint256 public CUTOFF_STEP = 48 hours;
	uint256 public MAX_WALLET_DEPOSIT = 75 ether;
	uint256 public VIP_MINIMUM = 1.5 ether;
	
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
	address payable public ltcMinerContract;
	address public contractOwner;
	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 amount);
	event ReinvestedDeposit(address indexed user, uint8 plan, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

	constructor(address pOwner, address payable pProjectWwallet, address payable pMarketingWallet, address payable pltcMinerContract) {
		require(!isContract(pOwner));
		token_LTC = IERC20(erctoken);
		contractOwner = pOwner;
		projectWallet = pProjectWwallet;
		marketingWallet = pMarketingWallet;
		ltcMinerContract = pltcMinerContract;

        /**
          plan 1 6% 30 days 180% ROI with 25% tax = 135% ROI
          plan 2 5% 50 days 250% ROI with 25% tax = 187.5% ROI
          plan 3 4% 70 days 280% ROI with 25% tax = 210% ROI
          plan 4 32% 5 days 160% ROI with 25% tax = 120% ROI
          
          Plan 4 is the VIP Plan,
          User should have a total deposit of 1.5 LTC to qualify for the VIP PLan.
          5 LTC minimum investment. ($2000.00)
        **/

        plans.push(Plan(30, 60, 0));                 
        plans.push(Plan(50, 50, 0));                   
        plans.push(Plan(70, 40, 0));                   
        plans.push(Plan(5, 320, 5000000000000000000)); // 5LTC
	}

	function invest(address referrer, uint8 plan, uint256 amounterc
    ) public {
		if (!started) {
			if (msg.sender == contractOwner) {
				started = true;
			} else revert("Not started yet");
		}
		
        require(plan < plans.length, "Invalid plan");
        require(amounterc >= INVEST_MIN_AMOUNT, "Less than minimum amount");
        require(amounterc >= plans[plan].mininvest);
        uint256 totalDeposits = getUserTotalDeposits(msg.sender);
        require(totalDeposits < MAX_WALLET_DEPOSIT, "Wallet deposit limit reached 75 LTC");
           
        /**If user wants to invest to plan 3, but did not meet the requirement of 1.5LTC total deposit, revert and throw message. **/
        if(plan == 3 && totalDeposits < VIP_MINIMUM){
            revert("To be able to invest to VIP Plan. User must have a total deposit of 1.5 LTC or higher.");
        }
        
        token_LTC.transferFrom(address(msg.sender), address(this), amounterc); //transfer deposit to contract.
        
        //fees
		uint256 fee = amounterc.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
		uint256 ltc = amounterc.mul(LTC_CONTRACT_DEPOSIT).div(PERCENTS_DIVIDER);
		
		token_LTC.transfer(projectWallet, fee); //9.5% project fee.
		token_LTC.transfer(ltcMinerContract, ltc); //0.5% direct deposit to ltc miner every investment.
        
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
                emit RefBonus(upline, msg.sender, amount);
            }
        }

		if (user.deposits.length == 0) {
			user.checkpoints[plan] = block.timestamp;
			user.cutoff = block.timestamp.add(CUTOFF_STEP); // new user gets current time + CUTOFF_STEP for initial time window
			emit Newbie(msg.sender);
		}

		user.deposits.push(Deposit(plan, amounterc, block.timestamp, false)); // deposit from new invest

		totalInvested = totalInvested.add(amounterc);
        
		emit NewDeposit(msg.sender, plan, amounterc);
        emit FeePayed(msg.sender, SafeMath.add(fee,ltc));
	}
	
	function reinvest(uint8 plan) public {
		if (!started) {
			revert("Not started yet");
		}

        require(plan < plans.length, "Invalid plan");

        User storage user = users[msg.sender];
        uint256 totalAmount = getUserDividendsBeforeTAX(msg.sender, int8(plan));
        
    	// withdraw tax. 20% to keep in contract. 5% to marketing
	    uint256 marketing = totalAmount.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
	    uint256 contractLongevity = totalAmount.mul(CONTRACT_LONGEVITY_FEE).div(PERCENTS_DIVIDER);
	    totalAmount = totalAmount.sub(marketing).sub(contractLongevity);
	    
	    token_LTC.transfer(marketingWallet, marketing); //5% goes to marketing wallet
	    
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
		
		// withdraw tax. 20% to keep in contract. 5% to marketing
	    uint256 marketing = totalAmount.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
	    uint256 contractLengevity = totalAmount.mul(CONTRACT_LONGEVITY_FEE).div(PERCENTS_DIVIDER);
	    totalAmount = totalAmount.sub(marketing).sub(contractLengevity);

		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = token_LTC.balanceOf(address(this));
		
		if (contractBalance < totalAmount) {
			user.bonus = totalAmount.sub(contractBalance);
			user.totalBonus = user.totalBonus.add(user.bonus);
			totalAmount = contractBalance;
		}

        for(uint8 i = 0; i < plans.length; i++){
		    user.checkpoints[i] = block.timestamp; // global withdraw will reset checkpoints on all plans
        }
        
        user.cutoff = block.timestamp.add(CUTOFF_STEP); // global withdraw will also reset CUTOFF
		user.withdrawn = user.withdrawn.add(totalAmount);
		
        token_LTC.transfer(msg.sender, totalAmount); // amount to be withdrawn less tax.
        token_LTC.transfer(marketingWallet, marketing); //5% goes to marketing wallet
        
		emit Withdrawn(msg.sender, totalAmount);
	}

	function getContractBalance() public view returns (uint256) {
		return token_LTC.balanceOf(address(this));
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
    
    function set_ltcMinerContract(address value) external {
        require(msg.sender == contractOwner);
        marketingWallet = payable(value);
    }
    
    function set_LTC_MINER_PERCENT(uint256 value) external {
        require(msg.sender == contractOwner);
        require(value < 20); // 2 max
        LTC_CONTRACT_DEPOSIT = value;
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
    
    function setVIP_MINIMUM(uint256 value) external {
        require(msg.sender == contractOwner);
        VIP_MINIMUM = value;
    }
    
    function setMAX_WALLET_DEPOSIT(uint256 value) external {
        require(msg.sender == contractOwner);
        MAX_WALLET_DEPOSIT = value;
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