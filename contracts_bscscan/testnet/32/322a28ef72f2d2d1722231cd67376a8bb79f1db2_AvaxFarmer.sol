/**
 *Submitted for verification at BscScan.com on 2021-11-22
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-21
*/

/**

PLANS:
 plan 1 2% 200 days 400% total = 300% / 200 = 1.5% per day.
 plan 2 2.5% 90 days 224% total = 125% / 90 = 1.39% per day.
 plan 3 3% 60 days 180% total = 80% / 60 = 1.33% per day.
 plan 4 3.5% 40 days 140% total = 40% / 40 = 1% per day.
		
 plan 1 - minimum investment of 0.08 AVAX ($10), maximum investment of 80 AVAX ($11,000)
 plan 2 - minimum investment of 0.08 AVAX ($10), maximum investment of 65 AVAX ($9,000)
 plan 3 - minimum investment of 0.08 AVAX ($10), maximum investment of 50 AVAX ($7,000)
 plan 4 - minimum investment of 0.08 AVAX ($10), maximum investment of 35 AVAX ($5,000)
 
 * Users can only have a maximum active investment per plan.

DEVELOPMENT AND MARKETING FEE:
 10% fee for every investment. 6% Project Fee, 2% for lottery, and 2% Marketing Fee.
   
LOTTERY:
 For every deposit or compound 2% of the amount will be used to buy lottery tickets. which will cost 0.08 AVAX ($10) per ticket.
 Lottery will run for 1 week or if the number LOTTERY_PARTICIPANTS reaches 100. the lottery draw will automatically start and will choose the winner.
 Winners will have half of the prize pot available for withdrawal and half will be auto invested into the plan setted for the raffle draw.
 
REFERRAL SYSTEM:
 1 level referral bonus of 3%.

ANTI-WHALE CONTROL FEATURES:
 Adjustable cut off time. Initial cut off time set to 32hrs.
 Adjustable withdrawal cooldown. Initial timer set to 8 hours
 Max wallet active total deposit limit of 220 AVAX ($30,000)
 Max withdrawal amount limit.
 * Users can only withdraw a maximum of 37 AVAX ($5,000) per day, excess amount will be available for next withdrawal after the cooldown.

CONTRACT FEATURES:
 Compounding function per plan.
 Adjustable plan rewards.
 Add pool function.
 Project and plan statistics.

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

contract AvaxFarmer {
	using SafeMath for uint256;

	IERC20 public erctoken;
	// address erctoken = 0x1CE0c2827e2eF14D5C4f29a091d735A204794041; /** AVAX **/
	address token =  0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7; /** testnet BUSD **/

	/** default percentages **/
	uint256 public PROJECT_FEE = 60;
	uint256 public MARKETING_FEE = 20;
	uint256 public COMMUNITY_FEE = 50;
	uint256 public REFERRAL_PERCENT = 30;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;

	/* whale control features. **/
	uint256 public CUTOFF_STEP = 32 * 60 * 60; /** 32 hrs **/
	uint256 public WITHDRAW_COOLDOWN = 8 * 60 * 60; /** 8 hrs **/
	uint256 public MAX_WITHDRAW = 37 ether; /** 37 AVAX ~ $5,000.00 **/
	uint256 public WALLET_LIMIT = 220 ether; /** 220 AVAX ~ $30,000.00 **/

	/* adjust percentage per plan. **/
	uint256 public PERCENTAGE_BONUS_PLAN_1 = 0;
    uint256 public PERCENTAGE_BONUS_PLAN_2 = 0;
    uint256 public PERCENTAGE_BONUS_PLAN_3 = 0;
    uint256 public PERCENTAGE_BONUS_PLAN_4 = 0;
    uint256 public PERCENTAGE_BONUS_STARTTIME = 0; /** deposits after this timestamp timestamp get additional percentages **/

	/* lottery */
	bool public LOTTERY_ENABLED;
	uint8 public PLAN_FOR_LOTTERY = 0;
    uint256 public LOTTERY_START_TIME;
	uint256 public LOTTERY_STEP = 7 days;
    uint256 public LOTTERY_PERCENT = 20;
	uint256 public LOTTERY_TICKET_PRICE = 80 * 1e15; /** 0.08 AVAX ~ $10 **/
    uint256 public MAX_LOTTERY_TICKET = 100;
    uint256 public MAX_LOTTERY_PARTICIPANTS = 100;
    uint256 public LOTTERY_ROUND = 0;
    uint256 public LOTTERY_CURRENT_POT = 0;
    uint256 public LOTTERY_PARTICIPANTS = 0;
    uint256 public TOTAL_LOTTERY_TICKETS = 0;

    /* project statistics **/
	uint256 public totalInvested;
	uint256 public totalReInvested;
	uint256 public totalRefBonus;
    uint256 public totalLotteryBonus;
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
    
	struct Deposit {
        uint8 plan;
		uint256 amount;
		uint256 start;
		bool reinvested;
	}
	
	struct LotteryHistory {
        uint256 round;
        address winnerAddress; 
        uint256 pot;
        uint256 totalLotteryParticipants;
        uint256 totalLotteryTickets;
        uint8 investedPlan;
        
    }
    
    Plan[] internal plans;
    LotteryHistory[] internal lotteryHistory;

	struct User {
		Deposit[] deposits;
		mapping (uint8 => uint256) checkpoints; /** a checkpoint for each plan **/
		uint256 cutoff;
		uint256 totalInvested;
		address referrer;
		uint256 referralsCount;
		uint256 bonus;
		uint256 totalBonus;
		uint256 withdrawn;
		uint256 reinvested;
        uint256 lotteryBonus;
        uint256 totalLotteryBonus;
		uint256 totalDepositAmount;
	}

	mapping (address => User) internal users;

	/* more lottery */
	mapping(uint256 => mapping(address => uint256)) public ticketOwners; // round => address => amount of owned tickets
    mapping(uint256 => mapping(uint256 => address)) public participantAdresses; // round => id => address
    event LotteryWinner(address indexed investor, uint256 pot, uint256 indexed round);

	bool public started;
	address payable public projectWallet;
	address payable public marketingWallet;
	address payable public communityWallet;
	address public contractOwner;
	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 amount);
	event ReinvestedDeposit(address indexed user, uint8 plan, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

	constructor(address ownerAddress, address payable projectAddress, address payable marketingAddress, address payable communityAddress) {
		require(!isContract(ownerAddress));
		erctoken = IERC20(token);
		contractOwner = ownerAddress;
		projectWallet = projectAddress;
		marketingWallet = marketingAddress;
		communityWallet = communityAddress;
		
		/** 
		 
		 plan 1 2% 200 days 400% total = 300% / 200 = 1.5%
         plan 2 2.5% 90 days 224% total = 125% / 90 = 1.39%
         plan 3 3% 60 days 180% total = 80% / 60 = 1.33%
         plan 4 3.5% 40 days 140% total = 40% / 40 = 1%
		
		 plan 1 - minimum investment of 0.08 AVAX ($10), maximum investment of 80 AVAX ($11,000)
         plan 2 - minimum investment of 0.08 AVAX ($10), maximum investment of 65 AVAX ($9,000)
         plan 3 - minimum investment of 0.08 AVAX ($10), maximum investment of 50 AVAX ($7,000)
         plan 4 - minimum investment of 0.08 AVAX ($10), maximum investment of 35 AVAX ($5,000)
		
		**/

        plans.push(Plan(200, 20, 80 * 1e15, 80 ether, 0, 0, 0, 0, true));
        plans.push(Plan(90,  25, 80 * 1e15, 65 ether, 0, 0, 0, 0, true));
        plans.push(Plan(60,  30, 80 * 1e15, 50 ether, 0, 0, 0, 0, true));
        plans.push(Plan(40,  35, 80 * 1e15, 35 ether, 0, 0, 0, 0, true));
	}


	// best to have explicit control over when contract starts
	function startContract() public {
        require(msg.sender == contractOwner, "Admin use only");
        require(started == false, "Contract already started");
        started = true;
		LOTTERY_ENABLED = true;
		LOTTERY_START_TIME = block.timestamp;
    }

	function invest(address referrer, uint8 plan, uint256 amounterc) public {
		require(started, "Contract not yet started");
        require(plan < plans.length, "Invalid Plan.");
        require(amounterc >= plans[plan].mininvest, "Less than minimum amount required for the selected Plan.");
        require(amounterc <= plans[plan].maxinvest, "More than maximum amount required for the selected Plan.");
		require(plans[plan].planActivated, "Plan selected is disabled");

		/** fees **/
		erctoken.transferFrom(address(msg.sender), address(this), amounterc);
        emit FeePayed(msg.sender, payFees(amounterc));

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

        /** new user gets current time + CUTOFF_STEP for initial time window **/
		if (user.deposits.length == 0) {
			user.checkpoints[plan] = block.timestamp;
			user.cutoff = block.timestamp.add(CUTOFF_STEP);
			emit Newbie(msg.sender);
		}

        /** deposit from new invest **/
		user.deposits.push(Deposit(plan, amounterc, block.timestamp, false));

        // added this so we don't have to loop through user deposits
		user.totalInvested = user.totalInvested.add(amounterc);
		totalInvested = totalInvested.add(amounterc);

		/* buy lottery tickets */
		if (LOTTERY_ENABLED) {
			_buyTickets(msg.sender, amounterc);
		}

		/** statistics **/
		totalInvestorCount = totalInvestorCount.add(1);
		plans[plan].planTotalInvestorCount = plans[plan].planTotalInvestorCount.add(1);
		plans[plan].planTotalInvestments = plans[plan].planTotalInvestments.add(amounterc);

		emit NewDeposit(msg.sender, plan, amounterc);
	}

	function reinvest(uint8 plan) public {
		require(started, "Not started yet");
        require(plan < plans.length, "Invalid plan");
        require(plans[plan].planActivated, "Plan selected is disabled.");


        User storage user = users[msg.sender];
        uint256 totalAmount = getUserDividends(msg.sender, int8(plan));

		user.deposits.push(Deposit(plan, totalAmount, block.timestamp, true));

		/* buy lottery tickets */
		if (LOTTERY_ENABLED) {
			_buyTickets(msg.sender, totalAmount);
		}

        user.reinvested = user.reinvested.add(totalAmount);
        user.checkpoints[plan] = block.timestamp;
        user.cutoff = block.timestamp.add(CUTOFF_STEP);

        /** statistics **/
		totalReInvested = totalReInvested.add(totalAmount);
		plans[plan].planTotalReInvestments = plans[plan].planTotalReInvestments.add(totalAmount);
		plans[plan].planTotalReInvestorCount = plans[plan].planTotalReInvestorCount.add(1);

		emit ReinvestedDeposit(msg.sender, plan, totalAmount);
	}

	function withdraw() public {
		User storage user = users[msg.sender];

		uint256 totalAmount = getUserDividends(msg.sender);

		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			user.bonus = 0;
			totalAmount = totalAmount.add(referralBonus);
		}

        uint256 lotteryBonus = getUserLotteryBonus(msg.sender);
        if (lotteryBonus > 0) {
			user.lotteryBonus = 0;
			totalAmount = totalAmount.add(lotteryBonus);
		}

		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = erctoken.balanceOf(address(this));

		if (contractBalance < totalAmount) {
			user.bonus = totalAmount.sub(contractBalance);
			user.totalBonus = user.totalBonus.add(user.bonus);
			totalAmount = contractBalance;
		}

        for(uint8 i = 0; i < plans.length; i++){

            /** user can only withdraw every after 8 hours from last withdrawal. **/
            if(user.checkpoints[i].add(WITHDRAW_COOLDOWN) > block.timestamp){
               revert("Withdrawals can only be made every after 8 hours.");
            }

            /** global withdraw will reset checkpoints on all plans **/
		    user.checkpoints[i] = block.timestamp;
        }

        /** Excess dividends are sent back to the user's account available for the next withdrawal. **/
        if(totalAmount > MAX_WITHDRAW) {
            user.bonus = totalAmount.sub(MAX_WITHDRAW);
            totalAmount = MAX_WITHDRAW;
        }

        /** global withdraw will also reset CUTOFF **/
        user.cutoff = block.timestamp.add(CUTOFF_STEP);
		user.withdrawn = user.withdrawn.add(totalAmount);

        erctoken.transfer(msg.sender, totalAmount);
		emit Withdrawn(msg.sender, totalAmount);
	}
	
	function payFees(uint256 amounterc) internal returns(uint256) {
	    
		uint256 fee = amounterc.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
		uint256 marketing = amounterc.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
		
		erctoken.transfer(projectWallet, fee);
		erctoken.transfer(marketingWallet, marketing);
		
        return fee.add(marketing);
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
			    if(user.deposits[i].start >= PERCENTAGE_BONUS_STARTTIME){
                    if(user.deposits[i].plan == 0){
                        percent = percent.add(PERCENTAGE_BONUS_PLAN_1);
                    }else if(user.deposits[i].plan == 1){
                        percent = percent.add(PERCENTAGE_BONUS_PLAN_2);
                    }else if(user.deposits[i].plan == 2){
                        percent = percent.add(PERCENTAGE_BONUS_PLAN_3);
                    }else if(user.deposits[i].plan == 3){
                        percent = percent.add(PERCENTAGE_BONUS_PLAN_4);
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

	// lottery section!
    function _buyTickets(address userAddress, uint256 amount) private {
        require(amount != 0, "zero purchase amount");

		// TODO figure out how to not allow fractions of a ticket -- fractions of ticket will be considered.
        uint256 userTickets = ticketOwners[LOTTERY_ROUND][userAddress];
        if(userTickets == 0) {
            participantAdresses[LOTTERY_ROUND][LOTTERY_PARTICIPANTS] = userAddress;
            LOTTERY_PARTICIPANTS = LOTTERY_PARTICIPANTS.add(1);
        }

        uint256 numTickets = amount.div(LOTTERY_TICKET_PRICE);
        if (userTickets.add(numTickets) > MAX_LOTTERY_TICKET) {
            numTickets = MAX_LOTTERY_TICKET.sub(userTickets);
        }

        ticketOwners[LOTTERY_ROUND][userAddress] = userTickets.add(numTickets);
        uint256 lotteryAmount = amount.mul(LOTTERY_PERCENT).div(PERCENTS_DIVIDER);
        LOTTERY_CURRENT_POT = LOTTERY_CURRENT_POT.add(lotteryAmount);
        TOTAL_LOTTERY_TICKETS = TOTAL_LOTTERY_TICKETS.add(numTickets);

        //choose winner after 7 days -- TODO remove, makes gas way too high
        if(block.timestamp.sub(LOTTERY_START_TIME) >= LOTTERY_STEP || LOTTERY_PARTICIPANTS == MAX_LOTTERY_PARTICIPANTS) {
            chooseWinner();
        }
    }
    
    // will auto execute, when condition is met.
    function chooseWinner() public {
		require(
            ((block.timestamp.sub(LOTTERY_START_TIME) >= LOTTERY_STEP) || LOTTERY_PARTICIPANTS == MAX_LOTTERY_PARTICIPANTS),
            "Lottery much run for LOTTERY_STEP or there must be MAX_LOTTERY_PARTICIPANTS particpants"
        );
		uint256[] memory init_range = new uint256[](LOTTERY_PARTICIPANTS);
		uint256[] memory end_range = new uint256[](LOTTERY_PARTICIPANTS);

		uint256 last_range = 0;

		for(uint256 i = 0; i < LOTTERY_PARTICIPANTS; i++){
			uint256 range0 = last_range.add(1);
			uint256 range1 = range0.add(ticketOwners[LOTTERY_ROUND][participantAdresses[LOTTERY_ROUND][i]].div(1e18));

			init_range[i] = range0;
			end_range[i] = range1;
			last_range = range1;
		}

		uint256 random = _getRandom().mod(last_range).add(1);
		for(uint256 i = 0; i < LOTTERY_PARTICIPANTS; i++){
			if((random >= init_range[i]) && (random <= end_range[i])) {
				// winner found
				address winnerAddress = participantAdresses[LOTTERY_ROUND][i];
                _payLotteryWinner(winnerAddress);
				// reset LOTTERY_ROUND
				LOTTERY_CURRENT_POT = 0;
				LOTTERY_ROUND = LOTTERY_ROUND.add(1);
				LOTTERY_PARTICIPANTS = 0;
				TOTAL_LOTTERY_TICKETS = 0;
				LOTTERY_START_TIME = block.timestamp;
				break;
			}
      	} 	
    }

    function _getRandom() private view returns(uint256){
        bytes32 _blockhash = blockhash(block.number-1);
        return uint256(keccak256(abi.encode(_blockhash,block.timestamp, LOTTERY_CURRENT_POT, block.difficulty, totalInvested, erctoken.balanceOf(address(this)))));
    }

    function _payLotteryWinner(address userAddress) private {
        User storage user = users[userAddress];
        uint8 plan = PLAN_FOR_LOTTERY;
        
        //5% of the current pot will be put into the community wallet.
        uint256 communityFee = LOTTERY_CURRENT_POT.mul(COMMUNITY_FEE).div(PERCENTS_DIVIDER);
		erctoken.transfer(communityWallet, communityFee);
		
		LOTTERY_CURRENT_POT = LOTTERY_CURRENT_POT.sub(communityFee);

        // half is added to available rewards balance
        uint256 halfPot = LOTTERY_CURRENT_POT.mul(500).div(PERCENTS_DIVIDER);
        user.lotteryBonus = user.lotteryBonus.add(halfPot);
        user.totalLotteryBonus = user.totalLotteryBonus.add(LOTTERY_CURRENT_POT);

        // half is added to user deposits
        user.deposits.push(Deposit(plan, halfPot, block.timestamp, true));
        user.reinvested = user.reinvested.add(halfPot);
        user.checkpoints[plan] = block.timestamp;
        user.cutoff = block.timestamp.add(CUTOFF_STEP);

        /** statistics **/
        totalLotteryBonus = totalLotteryBonus.add(LOTTERY_CURRENT_POT);
        totalReInvested = totalReInvested.add(halfPot);
        plans[plan].planTotalReInvestments = plans[plan].planTotalReInvestments.add(halfPot);
        plans[plan].planTotalReInvestorCount = plans[plan].planTotalReInvestorCount.add(1);
        
		//record lottery round and winner
		lotteryHistory.push(LotteryHistory(LOTTERY_ROUND, userAddress, LOTTERY_CURRENT_POT, LOTTERY_PARTICIPANTS, TOTAL_LOTTERY_TICKETS, plan));
        emit LotteryWinner(userAddress, LOTTERY_CURRENT_POT, LOTTERY_ROUND);
        emit ReinvestedDeposit(msg.sender, plan, halfPot);
    }
    
	function getUserActiveProjectInvestments(address userAddress) public view returns (uint256){
	    uint256 totalAmount;

		/** get total active investments in all plans. **/
        for(uint8 i = 0; i < plans.length; i++){
              totalAmount = totalAmount.add(getUserActiveInvestments(userAddress, i));  
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

	function getLotteryHistory(uint256 index) public view returns(uint256 round, address winnerAddress, uint256 pot, 
	  uint256 totalLotteryParticipants, uint256 totalLotteryTickets, uint8 investedPlan) {
		round = lotteryHistory[index].round;
		winnerAddress = lotteryHistory[index].winnerAddress;
		pot = lotteryHistory[index].pot;
		totalLotteryParticipants = lotteryHistory[index].totalLotteryParticipants;
		totalLotteryTickets = lotteryHistory[index].totalLotteryTickets;
		investedPlan = lotteryHistory[index].investedPlan;
	}

	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent, uint256 minimumInvestment, uint256 maximumInvestment,
	  uint256 planTotalInvestorCount, uint256 planTotalInvestments , uint256 planTotalReInvestorCount, uint256 planTotalReInvestments, bool planActivated) {
		time = plans[plan].time;
		percent = plans[plan].percent;
		minimumInvestment = plans[plan].mininvest;
		maximumInvestment = plans[plan].maxinvest;
		planTotalInvestorCount = plans[plan].planTotalInvestorCount;
		planTotalInvestments = plans[plan].planTotalInvestments;
		planTotalReInvestorCount = plans[plan].planTotalReInvestorCount;
		planTotalReInvestments = plans[plan].planTotalReInvestments;
		planActivated = plans[plan].planActivated;
	}
	
	function getLotteryInfo() public view returns (uint256 lotteryRound, uint256 lotteryStartTime,  uint256 lotteryStep, uint256 lotteryTicketPrice, uint256 lotteryCurrentPot, 
	  uint256 lotteryParticipants, uint256 maxLotteryParticipants, uint256 totalLotteryTickets, uint256 lotteryPercent, uint256 maxLotteryTicket, uint8 planForLottery){
		lotteryStartTime = LOTTERY_START_TIME;
		lotteryStep = LOTTERY_STEP;
		lotteryTicketPrice = LOTTERY_TICKET_PRICE;
		maxLotteryParticipants = MAX_LOTTERY_PARTICIPANTS;
		lotteryRound = LOTTERY_ROUND;
		lotteryCurrentPot = LOTTERY_CURRENT_POT;
		lotteryParticipants = LOTTERY_PARTICIPANTS;
		totalLotteryTickets = TOTAL_LOTTERY_TICKETS;
		lotteryPercent = LOTTERY_PERCENT;
    	maxLotteryTicket = MAX_LOTTERY_TICKET;
	    planForLottery = PLAN_FOR_LOTTERY;
	}

	function getContractBalance() public view returns (uint256) {
		return erctoken.balanceOf(address(this));
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
	    return getUserDividends(userAddress, -1);
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

    function getUserTotalReferrals(address userAddress) public view returns (uint256){
        return users[userAddress].referralsCount;
    }

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
	    return users[userAddress].bonus;
	}

    function getUserLotteryBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].lotteryBonus;
	}

    function getUserTotalLotteryBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].totalLotteryBonus;
	}

	function getUserReferralTotalBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus;
	}

	function getUserReferralWithdrawn(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus.sub(users[userAddress].bonus);
	}

	function getUserAvailable(address userAddress) public view returns(uint256) {
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress)).add(getUserLotteryBonus(userAddress));
	}

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint256 amount) {
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount.add(users[userAddress].deposits[i].amount);
		}
	}

	function getUserActiveLotteryTickets(address userAddress) public view returns(uint256 ticketCount) {
	   ticketCount = ticketOwners[LOTTERY_ROUND][userAddress];
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

    function getSiteInfo() public view returns (uint256 _totalInvested, uint256 _totalBonus, uint256 _totalLotteryBonus) {
        return (totalInvested, totalRefBonus, totalLotteryBonus);
    }

	function getUserInfo(address userAddress) public view returns(uint256 totalDeposit, uint256 totalWithdrawn, uint256 totalReferrals, uint256 totalLottery) {
		return(getUserTotalDeposits(userAddress), getUserTotalWithdrawn(userAddress), getUserTotalReferrals(userAddress), getUserTotalLotteryBonus(userAddress));
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
    function ADD_NEW_PLAN(uint256 time, uint256 percent, uint256 mininvest, uint256 maxinvest, bool planActivated) external {
        require(msg.sender == contractOwner);
        plans.push(Plan(time, percent, mininvest, maxinvest, 0, 0, 0, 0, planActivated));
    }

    function ADD_PERCENT_STARTTIME(uint256 value) external {
        require(msg.sender == contractOwner);
        PERCENTAGE_BONUS_STARTTIME = value;
    }

    function ADD_PLAN1_BONUS(uint256 value) external {
        require(msg.sender == contractOwner);
        require(value < 100); /** 100 = 10% **/
        PERCENTAGE_BONUS_PLAN_1 = value;
    }

    function ADD_PLAN2_BONUS(uint256 value) external {
        require(msg.sender == contractOwner);
        require(value < 100); /** 100 = 10% **/
        PERCENTAGE_BONUS_PLAN_2 = value;
    }

    function ADD_PLAN3_BONUS(uint256 value) external {
        require(msg.sender == contractOwner);
        require(value < 100); /** 100 = 10% **/
        PERCENTAGE_BONUS_PLAN_3 = value;
    }

    function ADD_PLAN4_BONUS(uint256 value) external {
        require(msg.sender == contractOwner);
        require(value < 100); /** 100 = 10% **/
        PERCENTAGE_BONUS_PLAN_4 = value;
    }

    function CHANGE_OWNERSHIP(address value) external {
        require(msg.sender == contractOwner);
        contractOwner = payable(value);
    }

    function CHANGE_PROJECT_WALLET(address value) external {
        require(msg.sender == contractOwner);
        projectWallet = payable(value);
    }

    function CHANGE_MARKETING_WALLET(address value) external {
        require(msg.sender == contractOwner);
        marketingWallet = payable(value);
    }

    function CHANGE_PROJECT_FEE(uint256 value) external {
        require(msg.sender == contractOwner);
        require(value < 100);
        PROJECT_FEE = value;
    }

    function CHANGE_MARKETING_FEE(uint256 value) external {
        require(msg.sender == contractOwner);
        require(value < 50);
        MARKETING_FEE = value;
    }

    function SET_REFERRAL_PERCENT(uint256 value) external {
        require(msg.sender == contractOwner);
        require(value < 80);
        REFERRAL_PERCENT = value;
    }

    function SET_PLAN_PERCENT(uint8 plan, uint256 value) external {
        require(msg.sender == contractOwner);
        plans[plan].percent = value;
    }

    function SET_PLAN_TIME(uint8 plan, uint256 value) external {
        require(msg.sender == contractOwner);
        plans[plan].time = value;
    }

    function SET_PLAN_MIN(uint8 plan, uint256 value) external {
        require(msg.sender == contractOwner);
        plans[plan].mininvest = value * 1e15;
    }

    function SET_PLAN_MAX(uint8 plan, uint256 value) external {
        require(msg.sender == contractOwner);
        plans[plan].maxinvest = value * 1 ether;
    }

    function SET_PLAN_ACTIVE(uint8 plan, bool value) external {
        require(msg.sender == contractOwner);
        plans[plan].planActivated = value;
    }

    function SET_CUTOFF_STEP(uint256 value) external {
        require(msg.sender == contractOwner);
        CUTOFF_STEP = value * 60 * 60;
    }

    function SET_WITHDRAW_COOLDOWN(uint256 value) external {
        require(msg.sender == contractOwner);
        WITHDRAW_COOLDOWN = value * 60 * 60;
    }

    function SET_MAX_WITHDRAW(uint256 value) external {
        require(msg.sender == contractOwner);
        MAX_WITHDRAW = value * 1 ether;
    }

    function SET_WALLET_LIMIT(uint256 value) external {
        require(msg.sender == contractOwner);
        WALLET_LIMIT = value * 1 ether;
    }

    /* lottery setters */
	function SET_LOTTERY_ENABLED(bool value) external {
        require(msg.sender == contractOwner, "Admin use only");
        LOTTERY_ENABLED = value;
    }

    function SET_LOTTERY_START_TIME(uint256 value) external {
        require(msg.sender == contractOwner, "Admin use only");
        LOTTERY_START_TIME = value * 1 days;
    }

    function SET_LOTTERY_STEP(uint256 value) external {
        require(msg.sender == contractOwner, "Admin use only");
        require(value >= 1 && value < 31); /** 1 month max **/
        LOTTERY_STEP = value * 1 days;
    }

    function SET_LOTTERY_PERCENT(uint256 value) external {
        require(msg.sender == contractOwner, "Admin use only");
        LOTTERY_PERCENT = value;
    }

    function SET_LOTTERY_TICKET_PRICE(uint256 value) external {
        require(msg.sender == contractOwner, "Admin use only");
        LOTTERY_TICKET_PRICE = value * 1e15;
    }

    function SET_MAX_LOTTERY_TICKET(uint256 value) external {
        require(msg.sender == contractOwner, "Admin use only");
        MAX_LOTTERY_TICKET = value;
    }

    function SET_MAX_LOTTERY_PARTICIPANTS(uint256 value) external {
        require(msg.sender == contractOwner, "Admin use only");
        MAX_LOTTERY_PARTICIPANTS = value;
    }

    function SET_PLAN_FOR_LOTTERY(uint8 plan) external {
        require(msg.sender == contractOwner, "Admin use only");
        require(plan < plans.length, "Invalid plan");
        require(plans[plan].planActivated, "Plan selected is disabled.");

        PLAN_FOR_LOTTERY = plan;
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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}