//SourceUnit: TronCenturyReloaded.sol

 /*   TronCentury Reloaded - investment platform based on TRX blockchain smart-contract technology. Safe and legit!
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
 *   2) Choose one of the deposit plans, enter the TRX amount (50 TRX minimum) using our website "Deposit Now" button
 *   3) Wait for your earnings
 *	 4) Boost your earning by referring new users
 *   5) Withdraw earnings any time using our website "Withdraw" button
 *
 *   𝗪𝗵𝘆 𝘁𝗼 𝗝𝗼𝗶𝗻 𝗧𝗿𝗼𝗻𝗖𝗲𝗻𝘁𝘂𝗿𝘆?
 * 
 *	 👉 𝗔𝗳𝗳𝗼𝗿𝗱𝗮𝗯𝗹𝗲 𝗝𝗼𝗶𝗻𝗶𝗻𝗴: Anyone can join us with minimum amount as 50 Tron. 
 * 
 *	 👉 𝗠𝘂𝗹𝘁𝗶𝗽𝗹𝗲 𝗣𝗹𝗮𝗻𝘀: There are  4 Unique Crafted Plans to suit Everyone's need
 * 
 *	 👉 𝗟𝘂𝗰𝗿𝗮𝘁𝗶𝘃𝗲 𝗥𝗲𝘁𝘂𝗿𝗻: You get daily return upto 35% 
 * 
 *	 👉 𝗔𝗱𝗱𝗶𝘁𝗶𝗼𝗻𝗮𝗹 𝗜𝗻𝘁𝗲𝗿𝗲𝘀𝘁 𝗕𝗼𝗻𝘂𝘀𝗲𝘀: Get upto 10% as Additional daily Interest
 * 
 *	 👉 𝗦𝗺𝗼𝗼𝘁𝗵 𝗪𝗶𝘁𝗵𝗱𝗿𝗮𝘄𝗮𝗹: You can withdraw your profit any point of time
 * 
 *	 👉 𝗥𝗲𝗳𝗲𝗿𝗮𝗹 𝗕𝗼𝗻𝘂𝘀: We have lucrative referral program with 15% Referral Rewards upto 5 Level deep
 * 
 *	 👉 𝗟𝗲𝗮𝗱𝗲𝗿𝘀𝗵𝗶𝗽 𝗕𝗼𝗻𝘂𝘀: We have created pool to share extra bonus to extra-ordinary leaders, 1% of daily deposit will be shared among top 5 leaders
 * 
 *	 👉 𝗕𝘂𝗶𝗹𝘁-𝗶𝗻 𝗜𝗻𝘀𝘂𝗿𝗮𝗻𝗰𝗲: Your initial deposit is secured with our inbuilt insurance, so anyone can claim it in case of not profit
 *
 *   [AFFILIATE PROGRAM]
 *
 *   - 5-level referral commission: 5% - 4% - 3% - 2% - 1% 
 *
 */

pragma solidity 0.5.10;

contract TronCenturyReloaded {
	using SafeMath for uint256;
	uint256 constant public INVEST_MIN_AMOUNT = 50E6;
	uint256 constant public INVEST_MAX_AMOUNT = 500000E6;
	uint256[] public REFERRAL_PERCENTS = [50, 40, 30, 20, 10];
	uint256 public REFERRAL_PERCENTS_Total = 150;
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
		uint256 paid;
		uint256 total;
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
		uint256 pool_Bonus;
	}

	mapping (address => User) internal users;

	uint256 public startUNIX;
	address payable public commissionWallet;
 	address public botOwner;

 	mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
	uint256 public pool_balance;
	uint8[] public pool_bonuses;
	mapping(uint8 => address) public pool_top;
	uint256 public pool_cycle;
	uint256 public pool_last_draw;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish);
	event Insured(address indexed user, uint256 amount);
	event Claimed(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);
	event PoolPayout(address indexed addr, uint256 amount);

	constructor(address payable feesWallet, uint256 startDate,address  _botOwner) public {
		require(startDate > 0);
		commissionWallet = feesWallet;
		startUNIX = startDate;
		botOwner=_botOwner;
	    plans.push(Plan(8, 250));
	    plans.push(Plan(15, 200));
	    plans.push(Plan(30, 150));
	    plans.push(Plan(60, 100));
	    pool_bonuses.push(30);
	    pool_bonuses.push(25);
	    pool_bonuses.push(20);
	    pool_bonuses.push(15);
	    pool_bonuses.push(10);
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
        require(IS_INSURANCE_ENABLED() == 1, "Error : Insurance will automatically enable when TRX balance reaches 50K or Below");
        require(TOTAL_TRX_INSURED > 1E6, "Error: Insufficient Insurance Balance");

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
    	require(block.timestamp > startUNIX, "Error: Not Started Yet");
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

		_pollDeposits(msg.sender, msg.value);
		emit NewDeposit(msg.sender, plan, percent, msg.value, profit, block.timestamp, finish);
	}
	//new withdraw
	function withdraw() public {
	  require(users[msg.sender].deleted == 0, "Error: Deleted Account not eligible for Withdrawal");
		User storage user = users[msg.sender];
		uint256 totalAmount = getUserDividends(msg.sender);
		uint256 withdrawAmount = totalAmount.mul(WITHDRAW_PERCENT).div(PERCENTS_DIVIDER);
		uint256 InsuranceAmount = totalAmount.mul(INSURANCE_PERCENT).div(PERCENTS_DIVIDER);
		insured(InsuranceAmount,msg.sender);
		uint256 referralBonus = getUserReferralBonus(msg.sender);
		uint256 poolBonus = getUserPoolBonus(msg.sender);
		if (referralBonus > 0) {
			user.bonus = 0;
			withdrawAmount = withdrawAmount.add(referralBonus);
		}
		if (poolBonus > 0) {
			user.pool_Bonus = 0;
			withdrawAmount = withdrawAmount.add(poolBonus);
		}
		require(withdrawAmount > 0, "Error: 0 Dividends");
		uint256 contractBalance = (address(this).balance).sub(TOTAL_TRX_INSURED);
		if (contractBalance < withdrawAmount) {
			withdrawAmount = contractBalance;
		}
  		TOTAL_WITHDREW_GLOBAL = TOTAL_WITHDREW_GLOBAL.add(withdrawAmount);
		user.checkpoint = block.timestamp;
    	user.whistory.push(WithdrawHistory(withdrawAmount,totalAmount,block.timestamp));
		user.UserTotalWithdraw = user.UserTotalWithdraw.add(withdrawAmount);
		msg.sender.transfer(withdrawAmount);
		emit Withdrawn(msg.sender, withdrawAmount);
	}

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
	function getUserPoolBonus(address userAddress) public view returns(uint256) {
	    if (users[userAddress].deleted == 1) {
	        return 0;
	    }
		return users[userAddress].pool_Bonus;
	}
	function getUserWithdrawCount(address userAddress) public view returns(uint256 length) {
	    User storage user = users[userAddress];
		return user.whistory.length;
	}
	function getUserWithdrawHistory(address userAddress, uint256 index) public view returns(uint256 paid, uint256 total, uint256 start) {
	  User storage user = users[userAddress];
		paid = user.whistory[index].paid;
		total = user.whistory[index].total;
		start = user.whistory[index].start;
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
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress)).add(getUserPoolBonus(userAddress));
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}
	function getContractBalance() public view returns (uint256) {
		return (address(this).balance).sub(TOTAL_TRX_INSURED);
	}
	//deposit insurance
	function depositinsurance() public payable {
        uint256 InsuranceAmount = msg.value;
        require(msg.value > 1E6, "Minimum 1 TRX");
        insured(InsuranceAmount,msg.sender);
    }


    //New
    function _drawPool() public {
        require(msg.sender==botOwner,"Only botowner can call");
        require(pool_last_draw.add(86400) <= block.timestamp,"Once in every 24 Hours");
        pool_last_draw = uint40(block.timestamp);

        pool_cycle++;

        uint256 draw_amount = pool_balance;

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            uint256 win = draw_amount.mul(pool_bonuses[i]).div(100);

            users[pool_top[i]].pool_Bonus=users[pool_top[i]].pool_Bonus.add(win);

            pool_balance=pool_balance.sub(win);

            emit PoolPayout(pool_top[i], win);
        }
        pool_balance=0;
        for(uint8 j = 0; j < pool_bonuses.length; j++) {
            pool_top[j] = address(0);
        }
    }

    function _pollDeposits(address _addr, uint256 _amount) private {

        pool_balance =  pool_balance.add((_amount).div(100));

        address upline = users[_addr].referrer;

        if(upline == address(0)) return;

        pool_users_refs_deposits_sum[pool_cycle][upline] = pool_users_refs_deposits_sum[pool_cycle][upline].add(_amount);

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == upline) break;

            if(pool_top[i] == address(0)) {
                pool_top[i] = upline;
                break;
            }

            if(pool_users_refs_deposits_sum[pool_cycle][upline] > pool_users_refs_deposits_sum[pool_cycle][pool_top[i]]) {
                for(uint8 j = i + 1; j < pool_bonuses.length; j++) {
                    if(pool_top[j] == upline) {
                        for(uint8 k = j; k <= pool_bonuses.length; k++) {
                            pool_top[k] = pool_top[k + 1];
                        }
                        break;
                    }
                }

                for(uint8 m = uint8(pool_bonuses.length - 1); m > i; m--) {
                    pool_top[m] = pool_top[m - 1];
                }

                pool_top[i] = upline;

                break;
            }
        }
    }

    function top5Leaderboard() view external returns(uint256[5] memory _rewards) {
          for(uint8 k = 0; k < pool_bonuses.length; k++) {
            _rewards[k] = pool_balance.mul(pool_bonuses[k]).div(100);
        }
        return (_rewards);
    }

}



//Remove Balance from CB when paid to top 5 sponsors, to maintain CB and Insurance

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