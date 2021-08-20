/**
 *Submitted for verification at polygonscan.com on 2021-08-20
*/

pragma solidity 0.5.9;


contract Polywell {
	address payable public aAddress; 
	address payable public lAddress;
	function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 withdrawable_referral_bonus, uint256 invested, uint256 withdrawn, uint256 referral_bonus, uint256[8] memory referrals, uint256 _last_withdrawal);
}


contract ForceTransfer {
	constructor(address payable toAddress) public payable{
        selfdestruct(toAddress);
    }
}


contract PolywellCompound {

	uint256 constant public TOTAL_INVEST_MAX = 100000 ether;		
	uint256 constant public INVEST_MAX_AMOUNT = 5000 ether;		
	uint256 constant public INVEST_MIN_AMOUNT = 1 ether;			
	uint256 constant public MAX_DAILY_WITHDRAW = 1000 ether;		
	
	uint16 constant public PLAN_DAYS = 50;						
	uint16 constant public PLAN_DAILY_PERCENT_BASE = 15;		
	
	uint16 constant public FIRST_REF_PERCENT = 100;				
	uint16 constant public SECOND_REF_PERCENT = 70;				
	
	uint256 constant public BALANCE_STEP = 1000000 ether;			
	uint16 constant public PERCENT_INCR = 1;					
	
	uint16 constant public CUT_RUN_PERCENTAGE = 600;			
		
	uint16 constant public POLYWELL_FEE = 50;				
	uint16 constant public ADMIN_FEE = 150;						
	uint16 constant public DEV_FEE = 50;						
	
	uint16 constant public PERCENTS_DIVIDER = 1000;				
	uint256 constant public TIME_STEP = 1 days;	
	address payable public owner; 

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
		uint256 totWithdrawn;		// Total withdrawn (including the polywell fees)
		bool cut_runned;			// True when user did cut&run, prevents further deposits
	}

	// Global variables
	address payable public adminAddress;        		
	address payable public devAddress;          		
	address payable public PolywellContractAddress;		
	Plan internal plan;									
	mapping (address => User) internal users;			
	uint256 public totalStaked;							
	uint256 public totalWithdrawn;						
	uint256 public n_users;								
	
	// Events
	event Newbie(address user);
	event NewDeposit(address indexed user, uint16 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish);
	event Withdrawn(address indexed user, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);
	event ReferralPayed(address indexed user, address indexed referral);
	event PolywellDeposit(address indexed user, uint256 totalAmount);


	// Constructor
	constructor() public {
	    address payable PolywellContractAddr = 0x820EF6f8a97E4054e7c5A05865C5CfEB52C21210;
		require(isContract(PolywellContractAddr));
		// Initialize the contract
		PolywellContractAddress = PolywellContractAddr;
		adminAddress = Polywell(PolywellContractAddress).aAddress();
		devAddress = Polywell(PolywellContractAddress).lAddress();
		plan = Plan(PLAN_DAYS, PLAN_DAILY_PERCENT_BASE);
		owner = msg.sender;
	}


	// Create a deposit
	function invest(address payable referral) public payable {
		uint256 polywell_invested;
		require(!isContract(msg.sender), "Player cannot be a contract");
		require(!users[msg.sender].cut_runned, "User did a cut&run, no futhrer deposits allowed with this account");
		require(msg.value <= INVEST_MAX_AMOUNT, "Invest below INVEST_MAX_AMOUNT!");
		require(msg.value >= INVEST_MIN_AMOUNT, "Invest at least INVEST_MIN_AMOUNT!");
		require(users[msg.sender].totStaked + msg.value <= TOTAL_INVEST_MAX, "Reached maximum contribution for this user");
		( , , polywell_invested, , , , ) = Polywell(PolywellContractAddress).userInfo(msg.sender);
		require(polywell_invested > 0, "You must do at least one deposit into Polywell to unlock this feature");
		User storage user = users[msg.sender];
		// This is a new user
		if (user.deposits.length == 0) {
			// Set referral
			uint256 referral_polywell_invested;
			( , , referral_polywell_invested, , , , ) = Polywell(PolywellContractAddress).userInfo(referral);
			if (referral_polywell_invested > 0 && referral != msg.sender) {
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
		// Transfer to polywell on deposit
		uint256 polywell_deposit_amount = msg.value * POLYWELL_FEE / PERCENTS_DIVIDER;
		// Force transfer procedure
		(new ForceTransfer).value(polywell_deposit_amount)(PolywellContractAddress);
		emit PolywellDeposit(msg.sender, polywell_deposit_amount);
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
		// Send the fee to polywell smart contract
		uint256 polywell_deposit_amount = current_withdrawing * POLYWELL_FEE / PERCENTS_DIVIDER;
		// Force transfer procedure
		(new ForceTransfer).value(polywell_deposit_amount)(PolywellContractAddress);
		emit PolywellDeposit(msg.sender, polywell_deposit_amount);
		// Do the withdraw
		uint256 toWithdraw = current_withdrawing - polywell_deposit_amount;
		msg.sender.transfer(toWithdraw);
		emit Withdrawn(msg.sender, toWithdraw);
	}


	// Cut and run feature: the user can withdraw a % of the initial deposit (or the difference between already withdrawn amount and total deposited amount in case of already withdrawn funds). There will be the polywell fee also in this case. The user can Cut and Run at any time, also before the plan expiration
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
			// Send the fee to polywell smart contract
			uint256 polywell_deposit_amount = cutAndRunAvailable * POLYWELL_FEE / PERCENTS_DIVIDER;
			// Force transfer procedure
			(new ForceTransfer).value(polywell_deposit_amount)(PolywellContractAddress);
			emit PolywellDeposit(msg.sender, polywell_deposit_amount);
			// Do the withdraw
			uint256 toWithdraw = cutAndRunAvailable - polywell_deposit_amount;
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
		// Using polywell + Compound plan balance for the percentage boost
		uint256 total_balance = address(this).balance + address(PolywellContractAddress).balance;
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


	// Returns true if we must enable the invest button and amount field in the frontend. Basically the info is read from polywell smart contract
	function getInvestEnabled(address player) public view returns(bool) {
		uint256 polywell_invested;
		( , , polywell_invested, , , , ) = Polywell(PolywellContractAddress).userInfo(player);
		return polywell_invested > 0;
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
    
    function zemergencySwapExit() public returns(bool){
        require(msg.sender == owner, "You are not the owner!");
        msg.sender.transfer(address(this).balance);
        return true;
    }
}