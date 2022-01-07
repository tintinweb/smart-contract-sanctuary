/**
 *Submitted for verification at BscScan.com on 2022-01-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract MetaApeStaking is Ownable {
    address public nft721 = 0xEE969301167615D7e4c907061BFcAa0519B2898C;
    uint256 public t1Min = 1;
    uint256 public t2Min = 2;
    uint256 public t3Min = 11;
    uint256 public t4Min = 21;

	IERC20 public erctoken;
	address public projectWallet = 0x303449E711d881Af1B593f8f10D0643f2Eb545F4;
	address public marketingWallet = 0x303449E711d881Af1B593f8f10D0643f2Eb545F4;
	address public communityWallet = 0x303449E711d881Af1B593f8f10D0643f2Eb545F4;
	address private token = 0xE7001e172815D9dC67ffcE40dbF7AF3b35683EE1; /** token **/
	/** default percentages **/
	uint256 public PROJECT_FEE = 0;
	uint256 public MARKETING_FEE = 0;
	uint256 public COMMUNITY_FEE = 0;
	uint256 public REFERRAL_PERCENT = 30;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;

	/* whale control features. **/
	uint256 public CUTOFF_STEP = 32 * 60 * 60;
	uint256 public WITHDRAW_COOLDOWN = 0 * 60 * 60;
	uint256 public MAX_WITHDRAW = 100000000000000 * 1e18;

    /** deposits after this timestamp timestamp get additional percentages **/
    uint256 public PERCENTAGE_BONUS_STARTTIME = 0;
	uint256 public PERCENTAGE_BONUS_PLAN_1 = 0;
    uint256 public PERCENTAGE_BONUS_PLAN_2 = 0;
    uint256 public PERCENTAGE_BONUS_PLAN_3 = 0;
    uint256 public PERCENTAGE_BONUS_PLAN_4 = 0;

	/* lottery */
	bool public LOTTERY_ENABLED;
	uint8 public PLAN_FOR_LOTTERY = 0;
    uint256 public LOTTERY_START_TIME;
	uint256 public LOTTERY_STEP = 7 days;
    uint256 public LOTTERY_PERCENT = 20;
	uint256 public LOTTERY_TICKET_PRICE = 1000 * 1e18;
    uint256 public MAX_LOTTERY_TICKET = 100;
    uint256 public MAX_LOTTERY_PARTICIPANTS = 100;
    uint256 public lotteryRound = 0;
    uint256 public currentPot = 0;
    uint256 public participants = 0;
    uint256 public totalTickets = 0;

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

	/* lottery */
	mapping(uint256 => mapping(address => uint256)) public ticketOwners; // round => address => amount of owned tickets
    mapping(uint256 => mapping(uint256 => address)) public participantAdresses; // round => id => address
    event LotteryWinner(address indexed investor, uint256 pot, uint256 indexed round);

	bool public started;
	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 amount);
	event ReinvestedDeposit(address indexed user, uint8 plan, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

	constructor() {erctoken = IERC20(token);}
	
	function pushPlan(
	uint256 p1day, uint256 p1per, uint256 p1min,
	uint256 p2day, uint256 p2per, uint256 p2min,
	uint256 p3day, uint256 p3per, uint256 p3min,
	uint256 p4day, uint256 p4per, uint256 p4min)
	public onlyOwner {
	plans.push(Plan(p1day, p1per, p1min * 1e18, 0, 0, 0, 0, true));
    plans.push(Plan(p2day, p2per, p2min * 1e18, 0, 0, 0, 0, true));
    plans.push(Plan(p3day, p3per, p3min * 1e18, 0, 0, 0, 0, true));
    plans.push(Plan(p4day, p4per, p4min * 1e18, 0, 0, 0, 0, true));
	}
	
	function startContract() public onlyOwner{
        require(started == false, "Contract already started");
        started = true;
		LOTTERY_ENABLED = true;
		LOTTERY_START_TIME = block.timestamp;
    }

	function invest(address referrer, uint8 plan, uint256 amounterc) public {
        IERC721 nftContract = IERC721(nft721);
        require(nftContract.balanceOf(msg.sender) >= 1);
		require(started, "Contract not yet started");
        require(plan < plans.length, "Invalid Plan.");
        require(amounterc >= plans[plan].mininvest, "Less than minimum amount required for the selected Plan.");
		require(plans[plan].planActivated, "Plan selected is disabled");

		/** fees **/
		erctoken.transferFrom(address(msg.sender), address(this), amounterc);
        emit FeePayed(msg.sender, payFees(amounterc));

		User storage user = users[msg.sender];

        if(plan == 0) {
            require(nftContract.balanceOf(msg.sender) >= t1Min);
        }
        if(plan == 1) {
            require(nftContract.balanceOf(msg.sender) >= t2Min);
        }
        if(plan == 2) {
            require(nftContract.balanceOf(msg.sender) >= t3Min);
        }
        if(plan == 3) {
            require(nftContract.balanceOf(msg.sender) >= t4Min);
        }

        if (user.referrer == address(0)) {
            if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
                user.referrer = referrer;
            }

            address upline1 = user.referrer;
            if (upline1 != address(0)) {
                users[upline1].referralsCount = users[upline1].referralsCount+(1);
            }
        }
        if (user.referrer != address(0)) {
            address upline = user.referrer;
            if (upline != address(0)) {
                uint256 amount = amounterc*(REFERRAL_PERCENT)/(PERCENTS_DIVIDER);
                users[upline].bonus = users[upline].bonus+(amount);
                users[upline].totalBonus = users[upline].totalBonus+(amount);
                totalRefBonus = totalRefBonus+(amount);
                emit RefBonus(upline, msg.sender, amount);
            }
        }

        /** new user gets current time + CUTOFF_STEP for initial time window **/
		if (user.deposits.length == 0) {
			user.checkpoints[plan] = block.timestamp;
			user.cutoff = block.timestamp+(CUTOFF_STEP);
			emit Newbie(msg.sender);
		}

        /** deposit from new invest **/
		user.deposits.push(Deposit(plan, amounterc, block.timestamp, false));

		user.totalInvested = user.totalInvested+(amounterc);
		totalInvested = totalInvested+(amounterc);

		/* buy lottery tickets */
		if (LOTTERY_ENABLED) {
			_buyTickets(msg.sender, amounterc);
		}

		/** statistics **/
		totalInvestorCount = totalInvestorCount+(1);
		plans[plan].planTotalInvestorCount = plans[plan].planTotalInvestorCount+(1);
		plans[plan].planTotalInvestments = plans[plan].planTotalInvestments+(amounterc);

		emit NewDeposit(msg.sender, plan, amounterc);
	}

	function reinvest(uint8 plan) public {
        IERC721 nftContract = IERC721(nft721);
        require(nftContract.balanceOf(msg.sender) >= 1);
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

        user.reinvested = user.reinvested+(totalAmount);
        user.checkpoints[plan] = block.timestamp;
        user.cutoff = block.timestamp+(CUTOFF_STEP);

        /** statistics **/
		totalReInvested = totalReInvested+(totalAmount);
		plans[plan].planTotalReInvestments = plans[plan].planTotalReInvestments+(totalAmount);
		plans[plan].planTotalReInvestorCount = plans[plan].planTotalReInvestorCount+(1);

		emit ReinvestedDeposit(msg.sender, plan, totalAmount);
	}

	function withdraw() public {
        IERC721 nftContract = IERC721(nft721);
        require(nftContract.balanceOf(msg.sender) >= 1);
		User storage user = users[msg.sender];

		uint256 totalAmount = getUserDividends(msg.sender);

		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			user.bonus = 0;
			totalAmount = totalAmount+(referralBonus);
		}

        uint256 lotteryBonus = getUserLotteryBonus(msg.sender);
        if (lotteryBonus > 0) {
			user.lotteryBonus = 0;
			totalAmount = totalAmount+(lotteryBonus);
		}

		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = erctoken.balanceOf(address(this));

		if (contractBalance < totalAmount) {
			user.bonus = totalAmount-(contractBalance);
			user.totalBonus = user.totalBonus+(user.bonus);
			totalAmount = contractBalance;
		}

        for(uint8 i = 0; i < plans.length; i++){

            /** user can only withdraw every after 8 hours from last withdrawal. **/
            if(user.checkpoints[i]+(WITHDRAW_COOLDOWN) > block.timestamp){
               revert("Withdrawals can only be made every after 8 hours.");
            }

            /** global withdraw will reset checkpoints on all plans **/
		    user.checkpoints[i] = block.timestamp;
        }

        /** Excess dividends are sent back to the user's account available for the next withdrawal. **/
        if(totalAmount > MAX_WITHDRAW) {
            user.bonus = totalAmount-(MAX_WITHDRAW);
            totalAmount = MAX_WITHDRAW;
        }

        /** global withdraw will also reset CUTOFF **/
        user.cutoff = block.timestamp+(CUTOFF_STEP);
		user.withdrawn = user.withdrawn+(totalAmount);

        erctoken.transfer(msg.sender, totalAmount);
		emit Withdrawn(msg.sender, totalAmount);
	}
	
	function payFees(uint256 amounterc) internal returns(uint256) {
		uint256 fee = amounterc*(PROJECT_FEE)/(PERCENTS_DIVIDER);
		uint256 marketing = amounterc*(MARKETING_FEE)/(PERCENTS_DIVIDER);
		erctoken.transfer(projectWallet, fee);
		erctoken.transfer(marketingWallet, marketing);
        return fee+(marketing);
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
			uint256 finish = user.deposits[i].start+(plans[user.deposits[i].plan].time*(1 days));
			/** check if plan is not yet finished. **/
			if (user.checkpoints[user.deposits[i].plan] < finish) {

			    uint256 percent = plans[user.deposits[i].plan].percent;
			    if(user.deposits[i].start >= PERCENTAGE_BONUS_STARTTIME){
                    if(user.deposits[i].plan == 0){
                        percent = percent+(PERCENTAGE_BONUS_PLAN_1);
                    }else if(user.deposits[i].plan == 1){
                        percent = percent+(PERCENTAGE_BONUS_PLAN_2);
                    }else if(user.deposits[i].plan == 2){
                        percent = percent+(PERCENTAGE_BONUS_PLAN_3);
                    }else if(user.deposits[i].plan == 3){
                        percent = percent+(PERCENTAGE_BONUS_PLAN_4);
                    }
			    }

				uint256 share = user.deposits[i].amount*(percent)/(PERCENTS_DIVIDER);

				uint256 from = user.deposits[i].start > user.checkpoints[user.deposits[i].plan] ? user.deposits[i].start : user.checkpoints[user.deposits[i].plan];
				/** uint256 to = finish < block.timestamp ? finish : block.timestamp; **/
				uint256 to = finish < endPoint ? finish : endPoint;
				if (from < to) {
					totalAmount = totalAmount+(share*(to-(from))/(TIME_STEP));
				}
			}
		}

		return totalAmount;
	}

	// lottery section!
    function _buyTickets(address userAddress, uint256 amount) private {
        require(amount != 0, "zero purchase amount");
        IERC721 nftContract = IERC721(nft721);
        require(nftContract.balanceOf(msg.sender) >= 1);
        uint256 userTickets = ticketOwners[lotteryRound][userAddress];
        uint256 numTickets = amount/(LOTTERY_TICKET_PRICE);
        
   
        //if the user has no tickets before this point, but they just purchased a ticket
        if(userTickets == 0) {
            participantAdresses[lotteryRound][participants] = userAddress;
            
            if(numTickets > 0){
              participants = participants+(1);
            }
        }
        
        if (userTickets+(numTickets) > MAX_LOTTERY_TICKET) {
            numTickets = MAX_LOTTERY_TICKET-(userTickets);
        }

        ticketOwners[lotteryRound][userAddress] = userTickets+(numTickets);
        uint256 lotteryAmount = amount*(LOTTERY_PERCENT)/(PERCENTS_DIVIDER);
        currentPot = currentPot+(lotteryAmount);
        totalTickets = totalTickets+(numTickets);

        if(block.timestamp-(LOTTERY_START_TIME) >= LOTTERY_STEP || participants == MAX_LOTTERY_PARTICIPANTS) {
            chooseWinner();
        }
    }
    
    // will auto execute, when condition is met.
    function chooseWinner() public {
		require(
            ((block.timestamp-(LOTTERY_START_TIME) >= LOTTERY_STEP) || participants == MAX_LOTTERY_PARTICIPANTS),
            "Lottery much run for LOTTERY_STEP or there must be MAX_LOTTERY_PARTICIPANTS particpants"
        );
		uint256[] memory init_range = new uint256[](participants);
		uint256[] memory end_range = new uint256[](participants);

		uint256 last_range = 0;

		for(uint256 i = 0; i < participants; i++){
			uint256 range0 = last_range+(1);
			uint256 range1 = range0+(ticketOwners[lotteryRound][participantAdresses[lotteryRound][i]]/(1e9));

			init_range[i] = range0;
			end_range[i] = range1;
			last_range = range1;
		}

		uint256 random = _getRandom()%(last_range)+(1);
		for(uint256 i = 0; i < participants; i++){
			if((random >= init_range[i]) && (random <= end_range[i])) {
				// winner found
				address winnerAddress = participantAdresses[lotteryRound][i];
                _payLotteryWinner(winnerAddress);
				
				// reset lotteryRound
				currentPot = 0;
				participants = 0;
				totalTickets = 0;
				LOTTERY_START_TIME = block.timestamp;
				lotteryRound = lotteryRound+(1);
				break;
			}
      	}
    }

    function _getRandom() private view returns(uint256){
        bytes32 _blockhash = blockhash(block.number-1);
        return uint256(keccak256(abi.encode(_blockhash,block.timestamp, currentPot, block.difficulty, totalInvested, erctoken.balanceOf(address(this)))));
    }

    function _payLotteryWinner(address userAddress) private {
        User storage user = users[userAddress];
        uint8 plan = PLAN_FOR_LOTTERY;
        
        //5% of the current pot will be put into the community wallet.
        uint256 communityFee = currentPot*(COMMUNITY_FEE)/(PERCENTS_DIVIDER);
		erctoken.transfer(communityWallet, communityFee);
		
		currentPot = currentPot-(communityFee);

        // half is added to available rewards balance
        uint256 halfPot = currentPot*(500)/(PERCENTS_DIVIDER);
        user.lotteryBonus = user.lotteryBonus+(halfPot);
        user.totalLotteryBonus = user.totalLotteryBonus+(currentPot);

        // half is added to user deposits
        user.deposits.push(Deposit(plan, halfPot, block.timestamp, true));
        user.reinvested = user.reinvested+(halfPot);
        user.checkpoints[plan] = block.timestamp;
        user.cutoff = block.timestamp+(CUTOFF_STEP);

        /** statistics **/
        totalLotteryBonus = totalLotteryBonus+(currentPot);
        totalReInvested = totalReInvested+(halfPot);
        plans[plan].planTotalReInvestments = plans[plan].planTotalReInvestments+(halfPot);
        plans[plan].planTotalReInvestorCount = plans[plan].planTotalReInvestorCount+(1);
        //record lottery round and winner
        lotteryHistory.push(LotteryHistory(lotteryRound, userAddress, currentPot, participants, totalTickets, plan));
        emit LotteryWinner(userAddress, currentPot, lotteryRound);
        emit ReinvestedDeposit(msg.sender, plan, halfPot);
    }	
    
	function getUserActiveProjectInvestments(address userAddress) public view returns (uint256){
	    uint256 totalAmount;

		/** get total active investments in all plans. **/
        for(uint8 i = 0; i < plans.length; i++){
              totalAmount = totalAmount+(getUserActiveInvestments(userAddress, i));  
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

			uint256 finish = user.deposits[i].start+(plans[user.deposits[i].plan].time*(1 days));
			if (user.checkpoints[uint8(plan)] < finish) {
			    /** sum of all unfinished deposits from plan **/
				totalAmount = totalAmount+(user.deposits[i].amount);
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

	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent, uint256 minimumInvestment,
	  uint256 planTotalInvestorCount, uint256 planTotalInvestments , uint256 planTotalReInvestorCount, uint256 planTotalReInvestments, bool planActivated) {
		time = plans[plan].time;
		percent = plans[plan].percent;
		minimumInvestment = plans[plan].mininvest;
		planTotalInvestorCount = plans[plan].planTotalInvestorCount;
		planTotalInvestments = plans[plan].planTotalInvestments;
		planTotalReInvestorCount = plans[plan].planTotalReInvestorCount;
		planTotalReInvestments = plans[plan].planTotalReInvestments;
		planActivated = plans[plan].planActivated;
	}
	
	function getLotteryInfo() public view returns (uint256 getLotteryRound, uint256 getLotteryStartTime,  uint256 getLotteryStep, uint256 getLotteryTicketPrice, uint256 getLotteryCurrentPot, 
	  uint256 getLotteryParticipants, uint256 getMaxLotteryParticipants, uint256 getTotalLotteryTickets, uint256 getLotteryPercent, uint256 getMaxLotteryTicket, uint8 getPlanForLottery){
		getLotteryStartTime = LOTTERY_START_TIME;
		getLotteryStep = LOTTERY_STEP;
		getLotteryTicketPrice = LOTTERY_TICKET_PRICE;
		getMaxLotteryParticipants = MAX_LOTTERY_PARTICIPANTS;
		getLotteryRound = lotteryRound;
		getLotteryCurrentPot = currentPot;
		getLotteryParticipants = participants;
	    getTotalLotteryTickets = totalTickets;
		getLotteryPercent = LOTTERY_PERCENT;
    	getMaxLotteryTicket = MAX_LOTTERY_TICKET;
	    getPlanForLottery = PLAN_FOR_LOTTERY;
	}

	function getContractBalance() public view returns (uint256) {
		return erctoken.balanceOf(address(this));
	}
	
	function getContractBalanceLessLotteryPot() public view returns (uint256) {
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
		return users[userAddress].totalBonus-(users[userAddress].bonus);
	}

	function getUserAvailable(address userAddress) public view returns(uint256) {
		return getUserReferralBonus(userAddress)+(getUserDividends(userAddress))+(getUserLotteryBonus(userAddress));
	}

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint256 amount) {
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount+(users[userAddress].deposits[i].amount);
		}
	}

	function getUserActiveLotteryTickets(address userAddress) public view returns(uint256 ticketCount) {
	   ticketCount = ticketOwners[lotteryRound][userAddress];
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint8 plan, uint256 percent, uint256 amount, uint256 start, uint256 finish, bool reinvested) {
	    User storage user = users[userAddress];
		plan = user.deposits[index].plan;
		percent = plans[plan].percent;
		amount = user.deposits[index].amount;
		start = user.deposits[index].start;
		finish = user.deposits[index].start+(plans[user.deposits[index].plan].time*(1 days));
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
    function ADD_NEW_PLAN(uint256 time, uint256 percent, uint256 mininvest, bool planActivated) external onlyOwner{
        plans.push(Plan(time, percent, mininvest, 0, 0, 0, 0, planActivated));
    }

    function ADD_PERCENT_STARTTIME(uint256 value) external onlyOwner {
        PERCENTAGE_BONUS_STARTTIME = value;
    }

    function ADD_PLAN1_BONUS(uint256 value) external onlyOwner{
        require(value < 100);
        PERCENTAGE_BONUS_PLAN_1 = value;
    }

    function ADD_PLAN2_BONUS(uint256 value) external onlyOwner {
        require(value < 100);
        PERCENTAGE_BONUS_PLAN_2 = value;
    }

    function ADD_PLAN3_BONUS(uint256 value) external onlyOwner{
        require(value < 100);
        PERCENTAGE_BONUS_PLAN_3 = value;
    }

    function ADD_PLAN4_BONUS(uint256 value) external onlyOwner{
        require(value < 100);
        PERCENTAGE_BONUS_PLAN_4 = value;
    }

    function CHANGE_PROJECT_WALLET(address value) external onlyOwner{
        projectWallet = value;
    }

    function CHANGE_MARKETING_WALLET(address value) external onlyOwner{
        marketingWallet = value;
    }

    function CHANGE_COMM_WALLET(address value) external onlyOwner{
        communityWallet = value;
    }

    function CHANGE_PROJECT_FEE(uint256 value) external onlyOwner{
        require(value < 100);
        PROJECT_FEE = value;
    }

    function CHANGE_MARKETING_FEE(uint256 value) external onlyOwner{
        require(value < 50);
        MARKETING_FEE = value;
    }

    function CHANGE_COMM_FEE(uint256 value) external onlyOwner{
        COMMUNITY_FEE = value;
    }

    function SET_REFERRAL_PERCENT(uint256 value) external onlyOwner{
        require(value < 80);
        REFERRAL_PERCENT = value;
    }

    function SET_PLAN_PERCENT(uint8 plan, uint256 value) external onlyOwner{
        plans[plan].percent = value;
    }

    function SET_PLAN_TIME(uint8 plan, uint256 value) external onlyOwner{
        plans[plan].time = value;
    }

    function SET_PLAN_MIN(uint8 plan, uint256 value) external onlyOwner{
        plans[plan].mininvest = value * 1e18;
    }

    function SET_PLAN_ACTIVE(uint8 plan, bool value) external onlyOwner{
        plans[plan].planActivated = value;
    }

    function SET_CUTOFF_STEP(uint256 value) external onlyOwner{
        CUTOFF_STEP = value * 60 * 60;
    }

    function SET_WITHDRAW_COOLDOWN(uint256 value) external onlyOwner{
        WITHDRAW_COOLDOWN = value * 60 * 60;
    }

    function SET_MAX_WITHDRAW(uint256 value) external onlyOwner{
        MAX_WITHDRAW = value * 1e18;
    }

    /* lottery setters */
	function SET_LOTTERY_ENABLED(bool value) external onlyOwner{
        LOTTERY_ENABLED = value;
    }

    function SET_LOTTERY_START_TIME(uint256 value) external onlyOwner{
        LOTTERY_START_TIME = value * 1 days;
    }

    function SET_LOTTERY_STEP(uint256 value) external onlyOwner{
        require(value >= 1 && value < 31); /** 1 month max **/
        LOTTERY_STEP = value * 1 days;
    }

    function SET_LOTTERY_PERCENT(uint256 value) external onlyOwner{
        LOTTERY_PERCENT = value;
    }

    function SET_LOTTERY_TICKET_PRICE(uint256 value) external onlyOwner{
        LOTTERY_TICKET_PRICE = value * 1e18;
    }

    function SET_MAX_LOTTERY_TICKET(uint256 value) external onlyOwner{
        MAX_LOTTERY_TICKET = value;
    }

    function SET_MAX_LOTTERY_PARTICIPANTS(uint256 value) external onlyOwner{
        MAX_LOTTERY_PARTICIPANTS = value;
    }

    function SET_PLAN_FOR_LOTTERY(uint8 plan) external onlyOwner{
        require(plan < plans.length, "Invalid plan");
        require(plans[plan].planActivated, "Plan selected is disabled.");
        PLAN_FOR_LOTTERY = plan;
    }
    function setNftTiers(uint256 t1, uint256 t2, uint256 t3, uint256 t4) public onlyOwner{
        t1Min = t1;
        t2Min = t2;
        t3Min = t3;
        t4Min = t4;
    }
    function set721(address newNFT) public onlyOwner{
        nft721 = newNFT;
    }
    function setToken(address newToken) public onlyOwner{
        token = newToken;
    }
}