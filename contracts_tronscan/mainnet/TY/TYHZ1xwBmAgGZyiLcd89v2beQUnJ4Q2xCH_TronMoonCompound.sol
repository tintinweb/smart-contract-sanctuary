//SourceUnit: TronMoonCompound.sol

 /*  Tron Moon Compound Addon - Community Contribution pool with daily automatically compounded ROC based on TRX blockchain smart-contract technology. 
 *   Safe and decentralized. The Smart Contract source is verified and available to everyone. The community decides the future of the project!
 *
 *   ┌───────────────────────────────────────────────────────────────────────┐
 *   │   Website: https://tronmoon.space                                     │
 *   │                                                                       │
 *   │   Telegram Public Group and Support: @tronmoonofficial                |
 *   |                                                                       |        
 *   |   E-mail: admin@tronmoon.space                                        |
 *   └───────────────────────────────────────────────────────────────────────┘
 *
 *   [USAGE INSTRUCTION]
 *
 *   1) Connect TRON browser extension TronLink, or mobile wallet apps like TronLink Pro / Klever
 *   2) Open at least one deposit into TronMoon to unlock the compound feature
 *   3) Deposit at least 200 TRX (max 50K TRX per deposit) in the compounding plan (50 days, funds withdraw after expiration)
 *   4) Wait for your earnings. You can withdraw only after the plan expiration. Max withdraw 10K TRX every 24h
 *   5) 5% of the deposited amount and 5% of the withdrawn amount go to the TronMoon contract balance automatically
 *   6) Keep inviting people using your TronMoon Ref Link and suggest them to open a compounding plan to sustain the Compound Community Pool
 *   7) You will receive 3% (Lv1) and 2% (Lv2) referral commissions. Remind your downline to open the website with your TronMoon ref link BEFORE investing in the plan if they already joined TronMoon
 *   8) Deposit more when you want! Everything is in the hands of the community. Deposit only what you can afford to lose.
 *   9) If you want to close the plan before the expiration you can Cut&Run but you will be able to withdraw only the 60% of your initial deposits (TronMoon 5% fee excluded)
 *
 *   [SMART CONTRACT DETAILS]
 *
 *   - ROC (return of contribution): 2.5% every 24h with automatic compounding (for every deposit)
 *   - Percent increase of 0.1% every 10M TRX of total contracts balance, considering the sum of TronMoon Balance and the compound plan contract balance (percentage is applied only to new deposits, after the percentage change)
 *   - Plan duration: 50 days (from the deposit timestamp)
 *   - Minimal deposit: 200 TRX, max single deposit 50K TRX, Max total deposit 1M TRX (per wallet)
 *   - Withdraw only after plan expiration. You can then withdraw a maximum of 10K TRX per day
 *   - Cut&Run feature to close the plan also before expiration, withdrawing the 60% of your deposited amount (excluded the 5% Tron moon deposit fee). Only one cut&run allowed, cut&run disables further deposits with the account.
 *   - Affiliate program with 2 levels (directs, and second line)
 *
 *   [AFFILIATE PROGRAM]
 *
 *   - 2 Levels referral commissions: 3% and 2% (total 5%) using the same ref link used for TronMoon. 
 *   - If you don't have a sponsor, you can still join: the admin (adminAddress) will be your sponsor
 *   - Your sponsor must be a TronMoon registered user (another participant who deposited into the main contract), otherwise the admin will be your sponsor
 *   - Once joined you cannot change your sponsor
 *   - Referral system is different from the one used by TronMoon main contract, your upline could differ from the one you have in TronMoon
 *   - If you want to maintain the same upline ask your downline to use the same referral link used for the TronMoon sponsorship
 *   - To receive commissions bonus from the second line you must deposit at least one time. Otherwise you will receive only the commission bonus from the first line.
 *   - Not paid referral commissions (eg. missing second line) will remain into the smart contract as balance
 *   - Make sure to always log into TronMoon with your ref link if you want to invest for the first time, otherwise the Admin will be your sponsor!
 *
 *   [FUNDS DISTRIBUTION OF THE DEPOSITS]
 *
 *   - 80% Platform main balance, participants payouts (and TronMoon 5% redirect applied on withdraw amount)
 *   - 5% Referral Program
 *   - 5% TronMoon deposit 
 *   - 5% Developer fee
 *   - 5% Advertising and promotion expenses, Support work, technical functioning, administration fee
 *
 */


pragma solidity 0.5.9;


// TronMoon abstract contract to read if user joined TronMoon
contract TronMoon {
	address payable public adminAddress; 
	address payable public devAddress;
	function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 withdrawable_referral_bonus, uint256 invested, uint256 withdrawn, uint256 referral_bonus, uint256[8] memory referrals, uint256 _last_withdrawal);
}


contract ForceTransfer {
	// Destruct with forced transfer, to bypass the absence of the fallback function in TronMoon
	constructor(address payable toAddress) public payable{
        selfdestruct(toAddress);
    }
}


contract TronMoonCompound {

	// Limits (values expressed in SUN - 1e6)
	uint256 constant public TOTAL_INVEST_MAX = 1000000e6;		// Maximum total TRX per user
	uint256 constant public INVEST_MAX_AMOUNT = 50000e6;		// Max Invest amount per transaction
	uint256 constant public INVEST_MIN_AMOUNT = 200e6;			// Min invest amount per transaction
	uint256 constant public MAX_DAILY_WITHDRAW = 10000e6;		// Max daily withdraw amount
	// Plan definition
	uint16 constant public PLAN_DAYS = 50;						// Plan duration in days
	uint16 constant public PLAN_DAILY_PERCENT_BASE = 25;		// Daily per-thousand (base)
	// Referrals: only 2 level 
	uint16 constant public FIRST_REF_PERCENT = 30;				// Perthousand of the first line (affiliation plan)
	uint16 constant public SECOND_REF_PERCENT = 20;				// Perthousand of the second line (affiliation plan)
	// Per-thousand increase every X contract balance (the SUM of TronMoon and this contract balance will be used!)
	uint256 constant public BALANCE_STEP = 10000000e6;			// Balance Step associated to PERCENT_INCR (in SUN)
	uint16 constant public PERCENT_INCR = 1;					// Per-thousand value added to base deposit percentage every BALANCE_STEP
	// Cut and run feature
	uint16 constant public CUT_RUN_PERCENTAGE = 600;			// 60% of total deposits (TronMoon forced redeposit calculated on this amount)
	// Fees and TronMoon deposit	
	uint16 constant public TRON_MOON_FEE = 50;					// Automatic deposit to TronMoon contract when investing and when withdrawing
	uint16 constant public ADMIN_FEE = 50;						// Admin fee (only on deposit)
	uint16 constant public DEV_FEE = 50;						// Dev fee (only on deposit)
	// Units
	uint16 constant public PERCENTS_DIVIDER = 1000;				// To use perthousand
	uint256 constant public TIME_STEP = 1 days;					// 1 day constant

	// Data structures

    struct Plan {
        uint256 time;			// number of days of the plan
        uint16 percent;			// base percent of the plan (before increments)
    }

	struct Deposit {
		uint16 percent;			// Deposit percent (daily with daily compounding)
		uint256 amount;			// Initial deposit (principal)
		uint256 profit;			// Dividends at expiration
		uint256 start;			// deposit submission timestamp
		uint256 finish;			// deposit expiration timestamp
	}

	struct User {
		Deposit[] deposits;			// All deposits
		address payable referral;	// The parent
		uint32[2] n_ref;			// Number of refs
		uint256 ref_bonus;			// Referral bonus
		uint256 checkpoint;			// Checkpoint (last withdraw or when creating the player)
		uint256 totStaked;			// Total invested
		uint256 pendingWithdraw;	// Pending withdraw
		uint256 totWithdrawn;		// Total withdrawn (including the tronmoon fees)
		bool cut_runned;			// True when user did cut&run, prevents further deposits
	}

	// Global variables
	address payable public adminAddress;        		// Project manager 
	address payable public devAddress;          		// Developer
	address payable public TronMoonContractAddress;		// TronMoon Contract address for deposits
	Plan internal plan;									// The compounding plan
	mapping (address => User) internal users;			// Players
	uint256 public totalStaked;							// Total staked (invested) into the contract (persistent)
	uint256 public totalWithdrawn;						// Total withdrawn (including the tronmoon fees)
	uint256 public n_users;								// Number of users
	
	// Events
	event Newbie(address user);
	event NewDeposit(address indexed user, uint16 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish);
	event Withdrawn(address indexed user, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);
	event ReferralPayed(address indexed user, address indexed referral);
	event TronMoonDeposit(address indexed user, uint256 totalAmount);


	// Constructor
	constructor(address payable TronMoonContractAddr) public {
		require(isContract(TronMoonContractAddr));
		// Initialize the contract
		TronMoonContractAddress = TronMoonContractAddr;
		adminAddress = TronMoon(TronMoonContractAddress).adminAddress();
		devAddress = TronMoon(TronMoonContractAddress).devAddress();
		plan = Plan(PLAN_DAYS, PLAN_DAILY_PERCENT_BASE);
	}


	// Create a deposit
	function invest(address payable referral) public payable {
		uint256 tronmoon_invested;
		require(!isContract(msg.sender), "Player cannot be a contract");
		require(!users[msg.sender].cut_runned, "User did a cut&run, no futhrer deposits allowed with this account");
		require(msg.value <= INVEST_MAX_AMOUNT, "Invest below INVEST_MAX_AMOUNT!");
		require(msg.value >= INVEST_MIN_AMOUNT, "Invest at least INVEST_MIN_AMOUNT!");
		require(users[msg.sender].totStaked + msg.value <= TOTAL_INVEST_MAX, "Reached maximum contribution for this user");
		( , , tronmoon_invested, , , , ) = TronMoon(TronMoonContractAddress).userInfo(msg.sender);
		require(tronmoon_invested > 0, "You must do at least one deposit into TronMoon to unlock this feature");
		User storage user = users[msg.sender];
		// This is a new user
		if (user.deposits.length == 0) {
			// Set referral
			uint256 referral_tronmoon_invested;
			( , , referral_tronmoon_invested, , , , ) = TronMoon(TronMoonContractAddress).userInfo(referral);
			if (referral_tronmoon_invested > 0 && referral != msg.sender) {
				user.referral = referral;
			} else {
				user.referral = adminAddress;
			}
			users[user.referral].n_ref[0]++;		// Update statistics
			if (user.referral != adminAddress) {
				User storage parent = users[user.referral];
				users[parent.referral].n_ref[1]++;		// Update statistics
			}
			// Set initial checkpoint
			user.checkpoint = block.timestamp;
			// Increment the number of users
			n_users++;
			emit Newbie(msg.sender);
		}
		// Pay the referral commissions with instant pay (direct transfer)
		uint256 first_ref_amount = msg.value * FIRST_REF_PERCENT / PERCENTS_DIVIDER;
		user.referral.transfer(first_ref_amount);		// Pay the parent
		emit ReferralPayed(msg.sender, user.referral);
		users[user.referral].ref_bonus += first_ref_amount;
		if (user.referral != adminAddress) {
			// Pay the second level, if the first level wasn't the admin
			uint256 second_ref_amount = msg.value * SECOND_REF_PERCENT / PERCENTS_DIVIDER;
			User storage parent_user = users[user.referral];
			if (parent_user.referral != address(0)) {
				parent_user.referral.transfer(second_ref_amount);		// Pay the grandparent
				emit ReferralPayed(msg.sender, parent_user.referral);
				users[parent_user.referral].ref_bonus += second_ref_amount;
			}
		}
		// Pay the Fees
		uint256 dev_fee = msg.value * DEV_FEE / PERCENTS_DIVIDER;
		uint256 admin_fee = msg.value * ADMIN_FEE / PERCENTS_DIVIDER;
		devAddress.transfer(dev_fee);
		adminAddress.transfer(admin_fee);
		emit FeePayed(msg.sender, dev_fee+admin_fee);
		// Transfer to TronMoon on deposit
		uint256 tron_moon_deposit_amount = msg.value * TRON_MOON_FEE / PERCENTS_DIVIDER;
		// Force transfer procedure
		(new ForceTransfer).value(tron_moon_deposit_amount)(TronMoonContractAddress);
		emit TronMoonDeposit(msg.sender, tron_moon_deposit_amount);
		// Calculate a new deposit with compounding and add the deposit. 
		// In case of base percentage depending on contract balance, this will affect only new deposits
		(uint16 percent, uint256 profit, uint256 finish) = getResult(msg.value);
		user.deposits.push(Deposit(percent, msg.value, profit, block.timestamp, finish));
		// Update statistics
		user.totStaked += msg.value;
		totalStaked += msg.value;
		emit NewDeposit(msg.sender, percent, msg.value, profit, block.timestamp, finish);
	}
	

	
	// Withdraw 
	function withdraw() public {
		User storage user = users[msg.sender];
		require(user.deposits.length > 0 && block.timestamp > user.deposits[0].finish, "There must be at least one finished deposit to withdraw");
		require(block.timestamp > user.checkpoint + TIME_STEP, "Can withdraw only once per day (if there are dividends)");
		require(address(this).balance > 0, "Cannot withdraw, contract balance is 0");
		// Calculate new dividends
		uint256 totalAmount = getUserDividends(msg.sender);
		// Add to pending withdraw
		user.pendingWithdraw += totalAmount;
		require(user.pendingWithdraw > 0, "User has no dividends to withdraw");
		uint256 current_withdrawing = user.pendingWithdraw > MAX_DAILY_WITHDRAW ? MAX_DAILY_WITHDRAW : user.pendingWithdraw;
		// Manage condition if balance is not enough
		uint256 contractBalance = address(this).balance;
		if (contractBalance < current_withdrawing) {
			current_withdrawing = contractBalance;
		}
		// Update checkpoint
		user.checkpoint = block.timestamp;
		// Update withdrawn and remaining
		user.pendingWithdraw -= current_withdrawing;
		user.totWithdrawn += current_withdrawing;	// Update statistics 
		totalWithdrawn += current_withdrawing; 		// Update global statistics
		// Send the fee to tronmoon smart contract
		uint256 tron_moon_deposit_amount = current_withdrawing * TRON_MOON_FEE / PERCENTS_DIVIDER;
		// Force transfer procedure
		(new ForceTransfer).value(tron_moon_deposit_amount)(TronMoonContractAddress);
		emit TronMoonDeposit(msg.sender, tron_moon_deposit_amount);
		// Do the withdraw
		uint256 toWithdraw = current_withdrawing - tron_moon_deposit_amount;
		msg.sender.transfer(toWithdraw);
		emit Withdrawn(msg.sender, toWithdraw);
	}


	// Cut and run feature: the user can withdraw a % of the initial deposit (or the difference between already withdrawn amount and total deposited amount in case of already withdrawn funds). There will be the TronMoon fee also in this case. The user can Cut and Run at any time, also before the plan expiration
	function cutAndRun() public {
		require(!users[msg.sender].cut_runned, "User already did the cut&run");
	    User storage user = users[msg.sender];
		uint256 cutAndRunAmount = user.totStaked * CUT_RUN_PERCENTAGE / PERCENTS_DIVIDER;
		uint256 cutAndRunAvailable = cutAndRunAmount > user.totWithdrawn ? cutAndRunAmount - user.totWithdrawn : 0;
		// Coerce to contract balance
		cutAndRunAvailable = address(this).balance > cutAndRunAvailable ? cutAndRunAvailable : address(this).balance;
		// If > 0 run and delete all user deposits and update statistics
		if (cutAndRunAvailable > 0) {
			user.totWithdrawn += cutAndRunAvailable;
			totalWithdrawn += cutAndRunAvailable;
			// Send the fee to tronmoon smart contract
			uint256 tron_moon_deposit_amount = cutAndRunAvailable * TRON_MOON_FEE / PERCENTS_DIVIDER;
			// Force transfer procedure
			(new ForceTransfer).value(tron_moon_deposit_amount)(TronMoonContractAddress);
			emit TronMoonDeposit(msg.sender, tron_moon_deposit_amount);
			// Do the withdraw
			uint256 toWithdraw = cutAndRunAvailable - tron_moon_deposit_amount;
			msg.sender.transfer(toWithdraw);
			emit Withdrawn(msg.sender, toWithdraw);
			delete user.deposits;
			user.totStaked = 0;
			user.pendingWithdraw = 0;
			user.checkpoint = block.timestamp;
			users[msg.sender].cut_runned = true;
		} else {
			revert("Nothing to withdraw with Cut&Run");
		}
	}



	// Return current plan percent
	function getPercent() public view returns (uint16) {
		// Using TronMoon + Compound plan balance for the percentage boost
		uint256 total_balance = address(this).balance + address(TronMoonContractAddress).balance;
		uint256 multip = total_balance >= BALANCE_STEP ? total_balance / BALANCE_STEP : 0;
		return plan.percent + PERCENT_INCR*uint16(multip);
    }


	// Returns the percent, the total profit and the finish timestamp for a new deposit amount
	function getResult(uint256 deposit) public view returns (uint16 percent, uint256 profit, uint256 finish) {
		// Get percent
		percent = getPercent();
		// Calculate compounding
		for (uint256 i = 0; i < plan.time; i++) {
			profit += ((deposit + profit) * percent) / PERCENTS_DIVIDER;
		}
		// Plan expiration timestamp
		finish = block.timestamp + plan.time * TIME_STEP;
	}


	// Returns the dividends for the withdraw function (only claimable dividends, so considered only expired deposits)
	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];
		uint256 totalAmount;
		for (uint256 i = 0; i < user.deposits.length; i++) {
			if (user.checkpoint < user.deposits[i].finish) {
				if (block.timestamp > user.deposits[i].finish) {
					totalAmount += user.deposits[i].profit;
				}
			}
		}
		return totalAmount;
	}


	// Return current cumulated dividends (day per day). But these are not withdrawable until the plan expiration
	function getUserCumulatedDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];
		uint256 totalAmount;
		for (uint256 i = 0; i < user.deposits.length; i++) {
			if (user.checkpoint < user.deposits[i].finish) {
				uint256 deposit_profit;
				// elapsed seconds coerced to deposit duration
				uint256 elapsed_seconds = block.timestamp < user.deposits[i].finish ? block.timestamp - user.deposits[i].start : user.deposits[i].finish - user.deposits[i].start;
				uint256 elapsed_days = elapsed_seconds / TIME_STEP;
				for (uint256 j = 0; j < elapsed_days; j++) {
					deposit_profit += ((user.deposits[i].amount + deposit_profit) * user.deposits[i].percent) / PERCENTS_DIVIDER;
				}
				// Add estimation of intradays profits (decimal part) to have the number updated every second (block.timestamp)
				uint256 remaining_elapsed_seconds = elapsed_seconds - elapsed_days * TIME_STEP;
				uint256 next_interests = ((user.deposits[i].amount + deposit_profit) * user.deposits[i].percent) / PERCENTS_DIVIDER;
				uint256 intraday_profits = (next_interests - deposit_profit) * remaining_elapsed_seconds / TIME_STEP;	// proportion (linear)
				deposit_profit += intraday_profits;
				// Add to the total (all deposits)
				totalAmount += deposit_profit;
			}
		}
		return totalAmount;
	}


	// Get all user information
	function getUserInfo(address userAddress) public view returns (address referral, uint32[2] memory ref_count, uint256 ref_bonus, uint256 checkpoint, uint256 deposit_length, uint256 totStaked, uint256 pendingWithdraw, uint256 totWithdrawn) {
		User storage user = users[userAddress];
		referral = user.referral;
		ref_count = user.n_ref;
		ref_bonus = user.ref_bonus;
		deposit_length = users[userAddress].deposits.length;
		checkpoint = user.checkpoint;
		totStaked = user.totStaked;
		pendingWithdraw = user.pendingWithdraw;
		totWithdrawn = user.totWithdrawn;
	}


	// Get all user information + extra enabled information
	function getUserInfoExt(address userAddress) public view returns (address referral, uint32[2] memory ref_count, uint256 ref_bonus, uint256 checkpoint, uint256 totStaked, uint256 cumulated_dividends, uint256 pendingWithdraw_updated, uint256 totWithdrawn, bool invest_enabled, bool withdraw_enabled, uint256 countdown_sec, uint256 end_timestamp) {
		referral = users[userAddress].referral;
		ref_count = users[userAddress].n_ref;
		ref_bonus = users[userAddress].ref_bonus;
		checkpoint = users[userAddress].checkpoint;
		totStaked = users[userAddress].totStaked;
		cumulated_dividends = getUserCumulatedDividends(userAddress);
		pendingWithdraw_updated = users[userAddress].pendingWithdraw + getUserDividends(userAddress);
		totWithdrawn = users[userAddress].totWithdrawn;
		invest_enabled = getInvestEnabled(userAddress);
		(withdraw_enabled, countdown_sec, end_timestamp) = getWithdrawEnabledAndCountdown(userAddress);

	}


	// Get all contract global information
	function getContractInfo() public view returns(uint256 glob_invested, uint256 glob_withdrawn, uint256 glob_users, uint16 current_percentage) {
		glob_invested = totalStaked;
		glob_withdrawn =  totalWithdrawn;
		glob_users = n_users;
		current_percentage = getPercent();
	}


	// Returns true if we must enable the invest button and amount field in the frontend. Basically the info is read from TronMoon smart contract
	function getInvestEnabled(address player) public view returns(bool) {
		uint256 tronmoon_invested;
		( , , tronmoon_invested, , , , ) = TronMoon(TronMoonContractAddress).userInfo(player);
		return tronmoon_invested > 0;
	}


	// Returns the enabled status for the withdraw button and the countdown in seconds
	function getWithdrawEnabledAndCountdown(address player) public view returns(bool enabled, uint256 countdown_sec, uint256 end_timestamp) {
		User storage user = users[player];
		bool at_least_one_deposit_expired = user.deposits.length > 0 && block.timestamp > user.deposits[0].finish;
		bool deadtime_expired = block.timestamp > user.checkpoint + TIME_STEP;
		bool something_to_withdraw = user.pendingWithdraw > 0 || getUserDividends(player) > 0;
		// Determine if withdraw button in the frontend is clickable or not
		enabled = at_least_one_deposit_expired && deadtime_expired && something_to_withdraw;
		// Determine the countdown in seconds (to show only if not enabled)
		if (at_least_one_deposit_expired) {
			if (something_to_withdraw) {
				end_timestamp = deadtime_expired ? 0 : user.checkpoint + TIME_STEP;
				countdown_sec = deadtime_expired ? 0 : user.checkpoint + TIME_STEP - block.timestamp;
			} else {
				countdown_sec = 0;
				end_timestamp = 0;
				for (uint256 i = 0; i < user.deposits.length; i++) {
					if (user.checkpoint < user.deposits[i].finish) {
						countdown_sec = block.timestamp > user.deposits[i].finish ? 0 : user.deposits[i].finish - block.timestamp;
						end_timestamp = user.deposits[i].finish;
						break;
					}
				}
				// If the time is less than deadtime, set as deadtime. Otherwise keep the same
				uint deadtime = user.checkpoint + TIME_STEP - block.timestamp;
				end_timestamp = countdown_sec < deadtime ? user.checkpoint + TIME_STEP : end_timestamp;
				countdown_sec = countdown_sec < deadtime ? deadtime : countdown_sec;	
			}
		} else {
			if (user.deposits.length > 0) {
				countdown_sec = block.timestamp > user.deposits[0].finish ? 0 : user.deposits[0].finish - block.timestamp;
				end_timestamp = user.deposits[0].finish;
			} else {
				countdown_sec = 0;
				end_timestamp = 0;
			}	
		} 
	}


	// Returns contract balance
	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}


	// Return current plan details (time and base percent, before increments)
	function getPlanInfo() public view returns(uint256 time, uint16 percent) {
		time = plan.time;
		percent = plan.percent;
	}
	

	// Get deposit info for a single deposit of a user
	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint16 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish) {
	    User storage user = users[userAddress];
		percent = user.deposits[index].percent;
		amount = user.deposits[index].amount;
		profit = user.deposits[index].profit;
		start = user.deposits[index].start;
		finish = user.deposits[index].finish;
	}


	// Get all deposit info of a user
	function getAllUserDepositInfo(address userAddress) public view returns(uint16[] memory percents, uint256[] memory amounts, uint256[] memory profits, uint256[] memory starts, uint256[] memory finishs) {
		uint256 deposits_len = users[userAddress].deposits.length;
	    percents = new uint16[](deposits_len);
		amounts = new uint256[](deposits_len);
		profits = new uint256[](deposits_len);
		starts = new uint256[](deposits_len);
		finishs = new uint256[](deposits_len);
		for (uint16 i = 0; i < deposits_len; i++) {
			(percents[i], amounts[i], profits[i], starts[i], finishs[i]) = getUserDepositInfo(userAddress, i);
		}
	}


	// Check if address is a contract or not
	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}