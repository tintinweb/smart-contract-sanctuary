//SourceUnit: TronCentury.sol

 /*   TronCapital - investment platform based on TRX blockchain smart-contract technology. Safe and legit!
 *
 *   ┌───────────────────────────────────────────────────────────────────────┐
 *   │   Website: https://troncentury.finance                                │
 *   │                                                                       │
 *   │   Telegram Official Group: @troncentury                               |
 *   └───────────────────────────────────────────────────────────────────────┘
 *
 *   [USAGE INSTRUCTION]
 *
 *   1) Connect TRON browser extension TronLink, or mobile wallet apps like Klever
 *   2) Choose one of the tariff plans, enter the TRX amount (50 TRX minimum) using our website "Deposit Now" button
 *   3) Wait for your earnings
 *   4) Withdraw earnings any time using our website "Withdraw" button
 *
 *   [INVESTMENT CONDITIONS]
 *
 *   - Basic interest rate: +25% every 24 hours (~1.04% hourly) - only for new deposits
 *   - Minimal deposit: 50 TRX
 *   - Maximum deposit: 500,000 TRX
 *   - Bonus 0.1% Interest everday, Bonus 0.1% Interest on every 1M Contract Balance
 *
 *   - Total income: based on your tarrif plan (from 5% to 8% daily) 
 *   - Earnings every moment, withdraw any time (if you use capitalization of interest you can withdraw only after end of your deposit) 
 *
 *   [AFFILIATE PROGRAM]
 *
 *   - 5-level referral commission: 7% - 3% - 1% - 0.5% - 0.5% 
 *
 *   [FUNDS DISTRIBUTION]
 *
 *   - 90% Platform main balance, participants payouts
 *   - 5% Advertising and promotion expenses
 *   - 5% Support work, technical functioning, administration fee
 */


 pragma solidity 0.5.10;

contract TronCentury {
	using SafeMath for uint256;
	uint256 constant public INVEST_MIN_AMOUNT = 50E6;
	uint256 constant public INVEST_MAX_AMOUNT = 500000E6;
	uint256[] public REFERRAL_PERCENTS = [70, 30, 10,5,5];
	uint256 public REFERRAL_PERCENTS_Total = 120;
	uint256 constant public PROJECT_FEE = 100;
	uint256 constant public INSURANCE_PERCENT = 200;
	uint256 constant public CONTRACT_DONATION = 200;
	uint256 constant public WITHDRAW_PERCENT = 600;
	uint256 constant public PERCENT_STEP = 1;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;

	uint256 public TOTAL_DEPOSITED_GLOBAL;
	uint256 public TOTAL_TRX_INSURED;
	uint256 public TOTAL_WITHDREW_GLOBAL;
	uint256 public TOTAL_UNIQUE_USERS;
	uint256 public TOTAL_INSURANCE_CLAIMED;

    struct Plan {
        uint256 time;
        uint256 percent;
    }

    Plan[] internal plans;

	struct Deposit {
        uint8 plan;
		uint256 percent;
		uint256 amount;
		uint256 profit;
		uint256 start;
		uint256 finish;
	}
	struct WithdrawHistory {
		uint256 amount;
		uint256 start;
	}
	struct User {
		Deposit[] deposits;
		WithdrawHistory[] whistory;
		uint256 checkpoint;
		address referrer;
		uint256[5] levels;
		uint256 bonus;
		uint256 totalBonus;
		uint256 UserTotalDeposit;
		uint256 UserTotalWithdraw;
		uint256 deleted;
	}

	mapping (address => User) internal users;

	uint256 public startUNIX;
	address payable public commissionWallet;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish);
	event Insured(address indexed user, uint256 amount);
	event Claimed(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

	constructor(address payable feesWallet, uint256 startDate) public {
		require(startDate > 0);
		commissionWallet = feesWallet;
		startUNIX = startDate;
        plans.push(Plan(8, 250));
        plans.push(Plan(15, 200));
        plans.push(Plan(30, 150));
        plans.push(Plan(60, 100));
	}

    function IS_INSURANCE_ENABLED() public view returns (uint256) {
        uint256 _contractBalance = (address(this).balance).sub(TOTAL_TRX_INSURED);
        if (_contractBalance <= 50000E6) {
            return 1;
        }
        return 0;
    }
    function getUserInsuranceInfo(address userAdress) public view returns (uint256 claimAmount, uint256 eligible, uint256 userTotalDeposit, uint256 userTotalWithdraw) {
        User storage user = users[userAdress];
        if (user.UserTotalDeposit > user.UserTotalWithdraw && user.deleted == 0){
            claimAmount = user.UserTotalDeposit.sub(user.UserTotalWithdraw);
            eligible = 1;
        }
        return(claimAmount, eligible, user.UserTotalDeposit, user.UserTotalWithdraw);
    }
    function claimInsurance() public  {
        require(users[msg.sender].deleted == 0, "Error: Insurance Already Claimed");
        require(IS_INSURANCE_ENABLED() == 1, "Error : Insurance will automatically enable when TRX balance reached 50K or Below");
        require(TOTAL_TRX_INSURED > 1E6, "Error: Insurance Balance is Empty");
        
        User storage user = users[msg.sender];
        
        (uint256 claimAmount, uint256 eligible, ,) = getUserInsuranceInfo(msg.sender);
        
        require(eligible==1, "Not eligible for insurance");
        
        if (claimAmount > 0){
            uint256 _contractBalance = (address(this).balance);
            if (_contractBalance < claimAmount){
                claimAmount = _contractBalance;
            }
            if (TOTAL_TRX_INSURED < claimAmount) {
                claimAmount = TOTAL_TRX_INSURED;
            }
			TOTAL_INSURANCE_CLAIMED = TOTAL_INSURANCE_CLAIMED.add(claimAmount);
			TOTAL_TRX_INSURED = TOTAL_TRX_INSURED.sub(claimAmount);
			user.UserTotalWithdraw = user.UserTotalWithdraw.add(claimAmount);
			users[msg.sender].deleted = 1;
            msg.sender.transfer(claimAmount);
            emit Claimed(msg.sender, claimAmount);
        }
    }
	function insured(uint256 amountInsured,address userAdress) internal {
		TOTAL_TRX_INSURED = TOTAL_TRX_INSURED.add(amountInsured);
		emit Insured(userAdress, amountInsured);
	}
	function invest(address referrer, uint8 plan) public payable {
		require(msg.value >= INVEST_MIN_AMOUNT, "Error : Minimum 50 TRX");
		require(msg.value <= INVEST_MAX_AMOUNT, "Error : Maximum 500000 TRX");
        require(plan < 4, "Invalid plan");

		User storage user = users[msg.sender];
        require(user.deleted == 0, "No Investment accepted after claiming Insurance.");
        
		uint256 fee = msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
		commissionWallet.transfer(fee);
		emit FeePayed(msg.sender, fee);

		if (user.referrer == address(0)) {
			if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
				user.referrer = referrer;
			}            
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
					uint256 amount = 0;
					amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].bonus = users[upline].bonus.add(amount);
					users[upline].totalBonus = users[upline].totalBonus.add(amount);
					emit RefBonus(upline, msg.sender, i, amount);
					upline = users[upline].referrer;
				} else break;
			}

		}

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			TOTAL_UNIQUE_USERS=TOTAL_UNIQUE_USERS.add(1);
			emit Newbie(msg.sender);
		}

		(uint256 percent, uint256 profit, uint256 finish) = getResult(plan, msg.value);
		user.deposits.push(Deposit(plan, percent, msg.value, profit, block.timestamp, finish));
        user.UserTotalDeposit = user.UserTotalDeposit.add(msg.value);
		TOTAL_DEPOSITED_GLOBAL = TOTAL_DEPOSITED_GLOBAL.add(msg.value);
		emit NewDeposit(msg.sender, plan, percent, msg.value, profit, block.timestamp, finish);
	}
	
	function withdraw() public {
	    require(users[msg.sender].deleted == 0, "Error: Deleted Account not eligible for Withdrawal");
	    
		User storage user = users[msg.sender];
        
		uint256 totalAmount = getUserDividends(msg.sender);
		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			user.bonus = 0;
			totalAmount = totalAmount.add(referralBonus);
		}
		require(totalAmount > 0, "Error: 0 Dividends");
        
		uint256 contractBalance = (address(this).balance).sub(TOTAL_TRX_INSURED);
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}
		
        TOTAL_WITHDREW_GLOBAL = TOTAL_WITHDREW_GLOBAL.add(totalAmount);
		user.checkpoint = block.timestamp;
        uint256 withdrawAmount=totalAmount.mul(WITHDRAW_PERCENT).div(PERCENTS_DIVIDER);
		uint256 InsuranceAmount=totalAmount.mul(INSURANCE_PERCENT).div(PERCENTS_DIVIDER);
        user.whistory.push(WithdrawHistory(totalAmount,block.timestamp));
		insured(InsuranceAmount,msg.sender);
		user.UserTotalWithdraw = user.UserTotalWithdraw.add(withdrawAmount);
		msg.sender.transfer(withdrawAmount);
		emit Withdrawn(msg.sender, totalAmount);
	}
    
    //unused
	function getBasePlanInfo(uint8 plan) public view returns (uint256 time, uint256 percent) {
		time = plans[plan].time;
		percent = plans[plan].percent;
	}
	function getDailyRoiIncrement() public view returns (uint256){
        uint256 percent = PERCENT_STEP.mul(block.timestamp.sub(startUNIX)).div(TIME_STEP);
        if(percent>50){
            percent=50;
        }
        return percent;
    }
    function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}
	//used
	function getInsuredBalance() public view returns (uint256) {
	    return TOTAL_TRX_INSURED;
	}
    function contractBalanceBonus() public view returns (uint256){
		uint256 contractBalance = address(this).balance;
		uint256 contractBalancePercent = contractBalance.div(1000000E6); 
		if (contractBalancePercent >=50){
		    contractBalancePercent = 50;
		}
		return contractBalancePercent;
    }
	function getPercent(uint8 plan) public view returns (uint256) {
		if (block.timestamp > startUNIX) {
			uint256 percent=PERCENT_STEP.mul(block.timestamp.sub(startUNIX)).div(TIME_STEP);
			if(percent>50){
			    percent=50;
    			if(block.timestamp.sub(startUNIX) > 50 days) {
    			    percent = percent.add(contractBalanceBonus());
    			}
			}
			return plans[plan].percent.add(percent);
		} else {
			return plans[plan].percent;
		}
    }
	function getResult(uint8 plan, uint256 deposit) public view returns (uint256 percent, uint256 profit, uint256 finish) {
		percent = getPercent(plan);	
		profit = (deposit.mul(percent).div(PERCENTS_DIVIDER.div(10)).mul(plans[plan].time)).div(10);
		finish = block.timestamp.add(plans[plan].time.mul(TIME_STEP));
	}
	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];
		
		uint256 totalAmount;
		for (uint256 i = 0; i < user.deposits.length; i++) {
			if (user.checkpoint < user.deposits[i].finish) {
				if (user.deposits[i].plan < 4) {
					uint256 share = user.deposits[i].amount.mul(user.deposits[i].percent).div(PERCENTS_DIVIDER);
					uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
					uint256 to = user.deposits[i].finish < block.timestamp ? user.deposits[i].finish : block.timestamp;
					if (from < to) {
						totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
					}
				} else if (block.timestamp > user.deposits[i].finish) {
					totalAmount = totalAmount.add(user.deposits[i].profit);
				}
			}
		}
        if (user.deleted == 1) {
            return 0;
        }
		return totalAmount;
	}
	function getUserDownlineCount(address userAddress) public view returns(uint256, uint256, uint256, uint256, uint256) {
		return (users[userAddress].levels[0], users[userAddress].levels[1], users[userAddress].levels[2], users[userAddress].levels[3], users[userAddress].levels[4]);
	}
	function getUserReferralBonus(address userAddress) public view returns(uint256) {
	    if (users[userAddress].deleted == 1) {
	        return 0;
	    }
		return users[userAddress].bonus;
	}
	function getUserWithdrawCount(address userAddress) public view returns(uint256 length) {
	    User storage user = users[userAddress];
		return user.whistory.length;
	}
	function getUserWithdrawHistory(address userAddress, uint256 index) public view returns(uint256 amount, uint256 start) {
	    User storage user = users[userAddress];
		amount = user.whistory[index].amount;
		start=user.whistory[index].start;
	}
	function getUserDepositCount(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}
	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish) {
	    User storage user = users[userAddress];

		plan = user.deposits[index].plan;
		percent = user.deposits[index].percent;
		amount = user.deposits[index].amount;
		profit = user.deposits[index].profit;
		start = user.deposits[index].start;
		finish = user.deposits[index].finish;
	}
	function getUserReferralTotalBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus;
	}
	function getUserReferralWithdrawn(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus.sub(users[userAddress].bonus);
	}
	function getUserAccountDeleted(address userAddress) public view returns(uint256) {
		return users[userAddress].deleted;
	}
	function getUserAvailable(address userAddress) public view returns(uint256) {
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
	}
	
	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}
	function getContractBalance() public view returns (uint256) {
		return (address(this).balance).sub(TOTAL_TRX_INSURED);
	}
    //----//
	function getUserTotalTRXDeposits(address userAddress) public view returns(uint256 amount) {
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount.add(users[userAddress].deposits[i].amount);
		}
	}
	//deposit insurance
	function depositinsurance() public payable {
        uint256 InsuranceAmount = msg.value;
        require(msg.value > 1E6, "Minimum 1 TRX");
        insured(InsuranceAmount,msg.sender);
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