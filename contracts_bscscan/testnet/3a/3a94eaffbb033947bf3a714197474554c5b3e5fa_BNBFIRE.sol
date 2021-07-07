/**
 *Submitted for verification at BscScan.com on 2021-07-07
*/

// SPDX-License-Identifier: MIT 
 
 /*  BNB FIRE - Investment platform based on Binance Smart Chain blockchain smart-contract technology. Stake BNB and earn daily 17-20% ROI. Safe and legit!
 *   The only official platform of original BNB FIRE team! All other platforms with the same contract code are FAKE!
 *		
 * 	 	 ____  _   _ ____    ______ _____ _____  ______ 
 *		|  _ \| \ | |  _ \  |  ____|_   _|  __ \|  ____|
 *		| |_) |  \| | |_) | | |__    | | | |__) | |__   		BNB FIRE 
 *		|  _ <| . ` |  _ <  |  __|   | | |  _  /|  __|  		© All rights reserved.
 *		| |_) | |\  | |_) | | |     _| |_| | \ \| |____ 
 *		|____/|_| \_|____/  |_|    |_____|_|  \_\______|
 *   ┌───────────────────────────────────────────────────────────────────────┐
 *   │   Website: https://bnbfire.app                                        │
 *   │                                                                       │
 *   │   Telegram Live Support: @bnbfire_support                             |
 *   │   Telegram Public Group: https://t.me/bnbfire                         |
 *   └───────────────────────────────────────────────────────────────────────┘
 *
 *   [USAGE INSTRUCTION]
 *
 *   1) Connect browser extension Metamask (see help: https://academy.binance.com/en/articles/connecting-metamask-to-binance-smart-chain ).
 *   2) Choose one of the tariff plans, enter the BNB amount (0.05 BNB minimum) using our website "Stake BNB" button.
 *   3) Withdraw and compound your earnings every 24 hours using our website "Withdraw" button.
 *
 *   [INVESTMENT CONDITIONS]
 *
 *   - Basic interest rate: +1% every 24 hours (~0.04% hourly) - only for new deposits.
 *   - Minimal deposit: 0.05 BNB, no maximal limit.
 *   - Total income: based on your tariff plan (from 17% to 20% daily!!!) + Basic interest rate !!!
 *   - Earnings every moment, withdraw any time 24 hours after deposit.
 *
 *   [AFFILIATE PROGRAM]
 *
 *   - 10-level referral commission: 8% - 5% - 0.1% - 0.1% - 0.1% - 0.1% - 0.1% - 0.1% - 0.1% - 0.1%.
 *
 *   [FUNDS DISTRIBUTION]
 *
 *   - 70.2% Platform main balance, participants payouts.
 *   - 6%    Advertising and promotion expenses.
 *   - 13.8% Affiliate program bonuses.
 *   - 10%   Support work, technical functioning, administration fee.
 */

pragma solidity 0.5.8;

contract BNBFIRE {
	using SafeMath for uint256;

	uint256 constant public INVEST_MIN_AMOUNT = 0.05 ether;
	uint256[] public REFERRAL_PERCENTS = [80, 50, 1, 1, 1, 1, 1, 1, 1, 1];
	uint256 constant public PROJECT_FEE = 50;
	uint256 constant public DEVELOPER_FEE = 50;
	uint256 constant public WINNER_FEE_1 = 30;
	uint256 constant public WINNER_FEE_2 = 20;
	uint256 constant public WINNER_FEE_3 = 10;
	uint256 constant public PERCENT_STEP = 10;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;

	uint256 public totalStaked;
	uint256 public totalRefBonus;

    struct Plan {
        uint256 time;
        uint256 percent;
        uint256 reinvest;
    }

    Plan[] internal plans;

	struct Deposit {
        uint8 plan;
		uint256 percent;
		uint256 amount;
		uint256 profit;
		uint256 start;
		uint256 finish;
		uint256 reinvest;
	}

	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		address referrer;
		uint256 referrals;
		uint256 bonus;
		uint256 totalBonus;
		uint256 totalReinvested;
	}

	mapping (address => User) internal users;

	uint256 public startUNIX;
	address payable private commissionWallet;
	address payable private developerWallet;
	address payable private winner1Wallet;
	address payable private winner2Wallet;
	address payable private winner3Wallet;
    

	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);

	constructor(address payable wallet, address payable _developer, address payable winner1, address payable winner2, address payable winner3) public {
		require(!isContract(wallet));
		commissionWallet = wallet;
		developerWallet = _developer;
		winner1Wallet = winner1;
		winner2Wallet = winner2;
		winner3Wallet = winner3;
		startUNIX = block.timestamp;

        plans.push(Plan(10, 200, 500)); // 20% per day for 10 days, 50% reinvest
        plans.push(Plan(15, 180, 300)); // 18% per day for 15 days, 30% reinvest
        plans.push(Plan(20, 170, 200)); // 17% per day for 20 days, 20% reinvest
	}

	function invest(address referrer, uint8 plan) public payable {
		require(msg.value >= INVEST_MIN_AMOUNT);
        require(plan < 3, "Invalid plan");

		uint256 fee = msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
		commissionWallet.transfer(fee);
		uint256 developerFee = msg.value.mul(DEVELOPER_FEE).div(PERCENTS_DIVIDER);
		developerWallet.transfer(developerFee);
		uint256 winner1Fee = msg.value.mul(WINNER_FEE_1).div(PERCENTS_DIVIDER);
		winner1Wallet.transfer(winner1Fee);
		uint256 winner2Fee = msg.value.mul(WINNER_FEE_2).div(PERCENTS_DIVIDER);
		winner2Wallet.transfer(winner2Fee);
		uint256 winner3Fee = msg.value.mul(WINNER_FEE_3).div(PERCENTS_DIVIDER);
		winner3Wallet.transfer(winner3Fee);
		
		
		User storage user = users[msg.sender];

		if (user.referrer == address(0)) {
			if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
				user.referrer = referrer;
			}

			address upline = user.referrer;
			for (uint256 i = 0; i < 10; i++) {
				if (upline != address(0)) {
					users[upline].referrals = users[upline].referrals.add(1);
					upline = users[upline].referrer;
				} else break;
			}
		}

		if (user.referrer != address(0)) {

			address upline = user.referrer;
			for (uint256 i = 0; i < 10; i++) {
				if (upline != address(0)) {
					uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].bonus = users[upline].bonus.add(amount);
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

		(uint256 percent, uint256 profit, uint256 finish,uint256 reinvest) = getResult(plan, msg.value);
		user.deposits.push(Deposit(plan, percent, msg.value, profit, block.timestamp, finish,reinvest));

		totalStaked = totalStaked.add(msg.value);
		emit NewDeposit(msg.sender, plan, percent, msg.value, profit, block.timestamp, finish);
	}

	function withdraw() public {
		User storage user = users[msg.sender];
		
		require(getTimer(msg.sender) < block.timestamp, "withdrawals available once a day");

		uint256 totalAmount;
		uint256 totalReinvestAmount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			if (user.checkpoint < user.deposits[i].finish) {
			    
					uint256 share = user.deposits[i].amount.mul(user.deposits[i].percent).div(PERCENTS_DIVIDER);
					uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
					uint256 to = user.deposits[i].finish < block.timestamp ? user.deposits[i].finish : block.timestamp;
					if (from < to) {
					    uint256 payout = share.mul(to.sub(from)).div(TIME_STEP);
					    uint256 reinvest = payout.mul(user.deposits[i].reinvest).div(PERCENTS_DIVIDER);
					    user.deposits[i].amount = user.deposits[i].amount.add(reinvest);
					    payout = payout.sub(reinvest);
						totalAmount = totalAmount.add(payout);
						totalReinvestAmount = totalReinvestAmount.add(reinvest);
					}
				
			}
		}

		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			user.bonus = 0;
			totalAmount = totalAmount.add(referralBonus);
		}
		
	    user.totalReinvested = user.totalReinvested.add(totalReinvestAmount);

		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}

		user.checkpoint = block.timestamp;
		
	    uint256 fee = totalReinvestAmount.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
		commissionWallet.transfer(fee);
		uint256 developerFee = totalReinvestAmount.mul(DEVELOPER_FEE).div(PERCENTS_DIVIDER);
		developerWallet.transfer(developerFee);
		uint256 winner1Fee = totalReinvestAmount.mul(WINNER_FEE_1).div(PERCENTS_DIVIDER);
		winner1Wallet.transfer(winner1Fee);
		uint256 winner2Fee = totalReinvestAmount.mul(WINNER_FEE_2).div(PERCENTS_DIVIDER);
		winner2Wallet.transfer(winner2Fee);
		uint256 winner3Fee = totalReinvestAmount.mul(WINNER_FEE_3).div(PERCENTS_DIVIDER);
		winner3Wallet.transfer(winner3Fee);
		

		msg.sender.transfer(totalAmount);

		emit Withdrawn(msg.sender, totalAmount);

	}

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent,uint256 reinvest) {
		time = plans[plan].time;
		percent = plans[plan].percent;
		reinvest = plans[plan].reinvest;
	}

	function getPercent(uint8 plan) public view returns (uint256) {
		if (block.timestamp > startUNIX) {
			return plans[plan].percent.add(PERCENT_STEP.mul(block.timestamp.sub(startUNIX)).div(TIME_STEP));
		} else {
			return plans[plan].percent;
		}
    }
    
    function getReinvest(uint8 plan) public view returns (uint256){
        
        uint256 time = block.timestamp.sub(startUNIX).div(TIME_STEP);
        
        if(plan == 0){
            return plans[plan].reinvest.sub(time.mul(20)); //reinvest decreases every day by 2%
        }
        
        if(plan == 1){
            return plans[plan].reinvest.sub(time.mul(10)); // reinvest decreases every day by 1%
        }
        
        if(plan == 2){
            return plans[plan].reinvest.sub(time.mul(5)); // reinvest decreases every day by 0.5%
        }
    }
    
    function getTimer(address userAddress) public view returns(uint256){
        return getUserCheckpoint(userAddress).add(24 hours);
    }
    

	function getResult(uint8 plan, uint256 deposit) public view returns (uint256 percent, uint256 profit, uint256 finish, uint256 reinvest) {
		percent = getPercent(plan);
		reinvest = getReinvest(plan);

		
		profit = deposit.mul(percent).div(PERCENTS_DIVIDER).mul(plans[plan].time);
		
		
	

		finish = block.timestamp.add(plans[plan].time.mul(TIME_STEP));
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
	
	function getUserReinvestedAmount(address userAddress) public view returns(uint256){
	    return users[userAddress].totalReinvested;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

	function getUserDownlineCount(address userAddress) public view returns(uint256) {
		return users[userAddress].referrals;
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

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint256 amount) {
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount.add(users[userAddress].deposits[i].amount);
		}
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish, uint256 reinvest) {
	    User storage user = users[userAddress];

		plan = user.deposits[index].plan;
		percent = user.deposits[index].percent;
		amount = user.deposits[index].amount;
		profit = user.deposits[index].profit;
		start = user.deposits[index].start;
		finish = user.deposits[index].finish;
		reinvest = user.deposits[index].reinvest;
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