/**
 *Submitted for verification at BscScan.com on 2022-01-19
*/

/**

  GOLDBNB Mining Game

  ~ 4% daily interest contract basis.
  ~ 11.5% Referral Bonus.
  ~ 3% Compound bonus per day, max of 10 straight days. (30%)
  ~ 0.005 BNB Minimum Investment.
      
  Community Lottery:
  ~ 1% of each deposit or compound will be put in the pot money.
  ~ Amount will not be deducted to the user, it will be a bonus.
  ~ Lottery will run every 4hours or 100 participants.
  ~ 50 tickets max per user. 0.25 BNB = 50 tickets.
  ~ 0.005 bnb = 1 per ticket. based on user deposit/compound.
  ~ 90% of the pot will be given to the winning address.
  
  http://goldbnbmine.bitcoinbetyar.com/

*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract GOLDBNBMINE {
    using SafeMath for uint256;

    /** base parameters **/
    uint256 public GOLDS_TO_HIRE_1MINERS = 2160000;
    uint256 public GOLDS_TO_HIRE_1MINERS_COMPOUND = 864000;
    uint256 public REFERRAL = 115;
    uint256 public PERCENTS_DIVIDER = 1000;
    uint256 public PARTNER = 10;
    uint256 public PROJECT = 50;
    uint256 public MARKETING = 15;
    uint256 public LOTTERY = 100;
    uint256 public PROJECT_SELL = 50;
    uint256 public MARKETING_SELL = 15;
    uint256 public MARKET_GOLDS_DIVISOR = 5;
    uint256 public MARKET_GOLDS_DIVISOR_SELL = 3;

    /** bonus **/
	uint256 public COMPOUND_BONUS = 30; /** 3% **/
	uint256 public COMPOUND_BONUS_MAX_DAYS = 10; /** 10% **/
    uint256 public COMPOUND_STEP = 24 * 60 * 60; /** every 24 hours. **/

    /* lottery */
	bool public LOTTERY_ACTIVATED;
    uint256 public LOTTERY_START_TIME;
    uint256 public LOTTERY_PERCENT = 10;
    uint256 public LOTTERY_STEP = 4 * 60 * 60; /** every 4 hours. **/
    uint256 public LOTTERY_TICKET_PRICE = 5 * 1e15; /** 0.005 ether **/
    uint256 public MAX_LOTTERY_TICKET = 50;
    uint256 public MAX_LOTTERY_PARTICIPANTS = 100;
    uint256 public lotteryRound = 0;
    uint256 public currentPot = 0;
    uint256 public participants = 0;
    uint256 public totalTickets = 0;

    /* statistics */
    uint256 public totalStaked;
    uint256 public totalDeposits;
    uint256 public totalCompound;
    uint256 public totalRefBonus;
    uint256 public totalWithdrawn;
    uint256 public totalLotteryBonus;

    /* miner parameters */
    uint256 public marketGolds;
    uint256 public PSNS = 50000;
    uint256 PSN = 10000;
    uint256 PSNH = 5000;
    bool public contractStarted;

    /** whale control features **/
	uint256 public CUTOFF_STEP = 36 * 60 * 60; /** 36 hours  **/
    uint256 public MIN_INVEST = 5 * 1e15; /** 0.005 BNB  **/
	uint256 public WITHDRAW_COOLDOWN = 6 * 60 * 60; /** 6 hours  **/
    uint256 public WITHDRAW_LIMIT = 10 ether; /** 10 BNB  **/

    /* addresses */
    address payable public owner;
    address payable public project;
    address payable public partner;
    address payable public marketing;

    struct User {
        uint256 initialDeposit;
        uint256 userDeposit;
        uint256 miners;
        uint256 claimedGolds;
        uint256 totalLotteryBonus;
        uint256 lastClaim;
        address referrer;
        uint256 referralsCount;
        uint256 referralGoldRewards;
        uint256 totalWithdrawn;
        uint256 dailyCompoundBonus;
    }

    struct LotteryHistory {
        uint256 round;
        address winnerAddress;
        uint256 pot;
        uint256 totalLotteryParticipants;
        uint256 totalLotteryTickets;
    }

    LotteryHistory[] internal lotteryHistory;
    mapping(address => User) public users;
    mapping(uint256 => mapping(address => uint256)) public ticketOwners; /** round => address => amount of owned points **/
    mapping(uint256 => mapping(uint256 => address)) public participantAdresses; /** round => id => address **/
    event LotteryWinner(address indexed investor, uint256 pot, uint256 indexed round);

    constructor(address payable _owner, address payable _project, address payable _partner, address payable _marketing) {
        owner = _owner;
        project = _project;
        partner = _partner;
        marketing = _marketing;
    }

    function claimGolds(address ref, bool isCompound) public {
        require(contractStarted);
        User storage user = users[msg.sender];

        if (user.referrer == address(0)) {
            if (ref != msg.sender) {
                user.referrer = ref;
            }

            address upline1 = user.referrer;
            if (upline1 != address(0)) {
                users[upline1].referralsCount = users[upline1].referralsCount.add(1);
            }
        }

        uint256 goldsUsed = getMyGolds();
        uint256 goldsForReferrers = goldsUsed;
        /** isCompound -- only true when compounding. **/
        if(isCompound) {
            uint256 dailyCompoundBonus = getDailyCompoundBonus(msg.sender, goldsUsed);
            goldsUsed = goldsUsed.add(dailyCompoundBonus);
            uint256 goldsUsedValue = calculateGoldSell(goldsUsed);
            user.userDeposit = user.userDeposit.add(goldsUsedValue);
            totalCompound = totalCompound.add(goldsUsedValue);

            /** use goldsUsedValue if lottery entry is from compound, bonus will be included.
                check the value if it can buy a ticket. if not, skip lottery. **/
            if (LOTTERY_ACTIVATED && goldsUsedValue >= LOTTERY_TICKET_PRICE) {
                _buyTickets(msg.sender, goldsUsedValue);
            }
        } 

        /** compounding bonus add day count. **/
        if(block.timestamp.sub(user.lastClaim) >= COMPOUND_STEP) {
            if(user.dailyCompoundBonus < COMPOUND_BONUS_MAX_DAYS) {
                user.dailyCompoundBonus = user.dailyCompoundBonus.add(1);
            }
        }

        /**  miner increase -- check if for compound, new deposit and compound can have different percentage basis. **/
        uint256 newMiners;
        if(isCompound) {
            newMiners = goldsUsed.div(GOLDS_TO_HIRE_1MINERS_COMPOUND);
        }else{
            newMiners = goldsUsed.div(GOLDS_TO_HIRE_1MINERS);
        }
        user.miners = user.miners.add(newMiners);
        user.claimedGolds = 0;
        user.lastClaim = block.timestamp;
        
        if (user.referrer != address(0)) {
            address upline = user.referrer;
            if (upline != address(0)) {
                uint256 amount = goldsForReferrers.mul(REFERRAL).div(PERCENTS_DIVIDER);
                users[upline].claimedGolds = users[upline].claimedGolds.add(amount);
                users[upline].referralGoldRewards = users[upline].referralGoldRewards.add(amount);
                totalRefBonus = totalRefBonus.add(amount);
            }
        }

    /** lower the increase of marketGolds value for every compound/deposit, this will make the inflation slower.  20%(5) to 8%(12). **/
        marketGolds = marketGolds.add(goldsUsed.div(MARKET_GOLDS_DIVISOR));
    }

    function sellGolds() public{
        require(contractStarted);
        User storage user = users[msg.sender];
        uint256 hasGolds = getMyGolds();
        uint256 goldValue = calculateGoldSell(hasGolds);

        if(user.lastClaim.add(WITHDRAW_COOLDOWN) > block.timestamp) revert("Withdrawals can only be done after withdraw cooldown.");

        /** Excess amount will be sent back to user claimedGolds available for next withdrawal
            if WITHDRAW_LIMIT is not 0 and goldValue is greater than or equal WITHDRAW_LIMIT **/
        if(WITHDRAW_LIMIT != 0 && goldValue >= WITHDRAW_LIMIT) {
            user.claimedGolds = goldValue.sub(WITHDRAW_LIMIT);
            goldValue = WITHDRAW_LIMIT;
        }else{
            /** reset claim. **/
            user.claimedGolds = 0;
        }
        
        /** reset claim time. **/      
        user.lastClaim = block.timestamp;
        
        /** reset daily compound bonus. **/
        user.dailyCompoundBonus = 0;

        /** lowering the amount of golds that is being added to the total golds supply to only 5% for each sell **/
        marketGolds = marketGolds.add(hasGolds.div(MARKET_GOLDS_DIVISOR_SELL));
        
        /** check if contract has enough funds to pay -- one last ride. **/
        if(getBalance() < goldValue) {
            goldValue = getBalance();
        }
        uint256 goldsPayout = goldValue.sub(payFeesSell(goldValue));
        
        payable(address(msg.sender)).transfer(goldsPayout);
        user.totalWithdrawn = user.totalWithdrawn.add(goldsPayout);
        totalWithdrawn = totalWithdrawn.add(goldsPayout);

        /** if no new investment or compound, sell will also trigger lottery. **/
        if(block.timestamp.sub(LOTTERY_START_TIME) >= LOTTERY_STEP || participants >= MAX_LOTTERY_PARTICIPANTS){
            chooseWinner();
        }
    }

    /** transfer amount of bnb **/
    function buyGolds(address ref) public payable{
        User storage user = users[msg.sender];
        if (!contractStarted) {
    		if (msg.sender == owner) {
    		    require(marketGolds == 0);
    			contractStarted = true;
                marketGolds = 120000000000;
                LOTTERY_ACTIVATED = true;
                LOTTERY_START_TIME = block.timestamp;
    		} else revert("Contract not yet started.");
    	}
        require(msg.value >= MIN_INVEST, "Mininum investment not met.");
        uint256 goldsBought = calculateGoldBuy(msg.value, address(this).balance.sub(msg.value));
        user.userDeposit = user.userDeposit.add(msg.value);
        user.initialDeposit = user.initialDeposit.add(msg.value);
        user.claimedGolds = user.claimedGolds.add(goldsBought);
        totalStaked = totalStaked.add(msg.value);
        totalDeposits = totalDeposits.add(1);
        
        /** if lottery entry is from new deposit use deposit amount. **/
        if (LOTTERY_ACTIVATED) {
			_buyTickets(msg.sender, msg.value);
		}
        
        payFees(msg.value);
        claimGolds(ref, false);
    }

    function payFees(uint256 goldValue) internal {
        (uint256 projectFee, uint256 partnerFee, uint256 marketingFee) = getFees(goldValue);
        project.transfer(projectFee);
        partner.transfer(partnerFee);
        marketing.transfer(marketingFee);
    }

    function payFeesSell(uint256 goldValue) internal returns(uint256){
        uint256 prj = goldValue.mul(PROJECT_SELL).div(PERCENTS_DIVIDER);
        uint256 mkt = goldValue.mul(MARKETING_SELL).div(PERCENTS_DIVIDER);
        project.transfer(prj);
        marketing.transfer(mkt);
        return prj.add(mkt);
    }

    function getFees(uint256 goldValue) public view returns(uint256 _projectFee, uint256 _partnerFee, uint256 _marketingFee) {
        _projectFee = goldValue.mul(PROJECT).div(PERCENTS_DIVIDER);
        _partnerFee = goldValue.mul(PARTNER).div(PERCENTS_DIVIDER);
        _marketingFee = goldValue.mul(MARKETING).div(PERCENTS_DIVIDER);
    }

    /** lottery section! **/
    function _buyTickets(address userAddress, uint256 amount) private {
        require(amount != 0, "zero purchase amount");
        uint256 userTickets = ticketOwners[lotteryRound][userAddress];
        uint256 numTickets = amount.div(LOTTERY_TICKET_PRICE);

        /** if the user has no tickets before this point, but they just purchased a ticket **/
        if(userTickets == 0) {
            participantAdresses[lotteryRound][participants] = userAddress;

            if(numTickets > 0){
              participants = participants.add(1);
            }
        }

        if (userTickets.add(numTickets) > MAX_LOTTERY_TICKET) {
            numTickets = MAX_LOTTERY_TICKET.sub(userTickets);
        }

        ticketOwners[lotteryRound][userAddress] = userTickets.add(numTickets);
        /** percentage of deposit/compound amount will be put into the pot **/
        currentPot = currentPot.add(amount.mul(LOTTERY_PERCENT).div(PERCENTS_DIVIDER));
        totalTickets = totalTickets.add(numTickets);

        if(block.timestamp.sub(LOTTERY_START_TIME) >= LOTTERY_STEP || participants >= MAX_LOTTERY_PARTICIPANTS){
            chooseWinner();
        }
    }

   /** will auto execute, when condition is met. buy, claim and sell, can be triggered manually by admin if theres no user action. **/
    function chooseWinner() public {
       require(((block.timestamp.sub(LOTTERY_START_TIME) >= LOTTERY_STEP) || participants >= MAX_LOTTERY_PARTICIPANTS),
        "Lottery must run for LOTTERY_STEP or there must be MAX_LOTTERY_PARTICIPANTS particpants");
        /** only draw winner if participant > 0. **/
        if(participants != 0){
            uint256[] memory init_range = new uint256[](participants);
            uint256[] memory end_range = new uint256[](participants);

            uint256 last_range = 0;

            for(uint256 i = 0; i < participants; i++){
                uint256 range0 = last_range.add(1);
                uint256 range1 = range0.add(ticketOwners[lotteryRound][participantAdresses[lotteryRound][i]].div(1e18));

                init_range[i] = range0;
                end_range[i] = range1;
                last_range = range1;
            }

            uint256 random = _getRandom().mod(last_range).add(1);

            for(uint256 i = 0; i < participants; i++){
                if((random >= init_range[i]) && (random <= end_range[i])){

                    /** winner found **/
                    address winnerAddress = participantAdresses[lotteryRound][i];
                    User storage user = users[winnerAddress];

                    /** winner will have the prize in their claimable rewards. **/
                    uint256 golds = currentPot.mul(9).div(10);
                    uint256 goldsReward = calculateGoldBuy(golds, address(this).balance.sub(golds));
                    user.claimedGolds = user.claimedGolds.add(goldsReward);

                    /** record users total lottery rewards **/
                    user.totalLotteryBonus = user.totalLotteryBonus.add(goldsReward);
                    totalLotteryBonus = totalLotteryBonus.add(goldsReward);
                    uint256 proj = currentPot.mul(LOTTERY).div(PERCENTS_DIVIDER);
                    project.transfer(proj);

                    /** record round **/
                    lotteryHistory.push(LotteryHistory(lotteryRound, winnerAddress, golds, participants, totalTickets));
                    emit LotteryWinner(winnerAddress, golds, lotteryRound);

                    /** reset lotteryRound **/
                    currentPot = 0;
                    participants = 0;
                    totalTickets = 0;
                    LOTTERY_START_TIME = block.timestamp;
                    lotteryRound = lotteryRound.add(1);
                    break;
                }
            }
        }else{
            /** if lottery step is done but no participant, reset lottery start time. **/
            LOTTERY_START_TIME = block.timestamp;
        }
       
    }

    /**  select lottery winner **/
    function _getRandom() private view returns(uint256){
        bytes32 _blockhash = blockhash(block.number-1);
        return uint256(keccak256(abi.encode(_blockhash,block.timestamp,currentPot,block.difficulty, marketGolds, address(this).balance)));
    }

    function getDailyCompoundBonus(address _adr, uint256 amount) public view returns(uint256){
        if(users[_adr].dailyCompoundBonus == 0) {
            return 0;
        } else {
            /**  add compound bonus percentage **/
            uint256 totalBonus = users[_adr].dailyCompoundBonus.mul(COMPOUND_BONUS); 
            uint256 result = amount.mul(totalBonus).div(PERCENTS_DIVIDER);
            return result;
        }
    }

    function getLotteryHistory(uint256 index) public view returns(uint256 round, address winnerAddress, uint256 pot,
	  uint256 totalLotteryParticipants, uint256 totalLotteryTickets) {
		round = lotteryHistory[index].round;
		winnerAddress = lotteryHistory[index].winnerAddress;
		pot = lotteryHistory[index].pot;
		totalLotteryParticipants = lotteryHistory[index].totalLotteryParticipants;
		totalLotteryTickets = lotteryHistory[index].totalLotteryTickets;
	}

    function getLotteryInfo() public view returns (uint256 lotteryStartTime,  uint256 lotteryStep, uint256 lotteryCurrentPot,
	  uint256 lotteryParticipants, uint256 maxLotteryParticipants, uint256 totalLotteryTickets, uint256 lotteryTicketPrice, 
      uint256 maxLotteryTicket, uint256 lotteryPercent, uint256 round){
		lotteryStartTime = LOTTERY_START_TIME;
		lotteryStep = LOTTERY_STEP;
		lotteryTicketPrice = LOTTERY_TICKET_PRICE;
		maxLotteryParticipants = MAX_LOTTERY_PARTICIPANTS;
		round = lotteryRound;
		lotteryCurrentPot = currentPot;
		lotteryParticipants = participants;
	    totalLotteryTickets = totalTickets;
        maxLotteryTicket = MAX_LOTTERY_TICKET;
        lotteryPercent = LOTTERY_PERCENT;
	}

    function getUserInfo(address _adr) public view returns(uint256 _initialDeposit, uint256 _userDeposit, uint256 _miners,
     uint256 _claimedGolds, uint256 _totalLotteryBonus, uint256 _lastClaim, address _referrer, uint256 _referrals,
	 uint256 _totalWithdrawn,uint256 _referralGoldRewards, uint256 _dailyCompoundBonus) {
         User storage user = users[_adr];
         _initialDeposit = user.initialDeposit;
         _userDeposit = user.userDeposit;
         _miners = user.miners;
         _claimedGolds = user.claimedGolds;
         _totalLotteryBonus = user.totalLotteryBonus;
         _lastClaim = user.lastClaim;
         _referrer = user.referrer;
         _referrals = user.referralsCount;
         _totalWithdrawn = user.totalWithdrawn;
         _referralGoldRewards = user.referralGoldRewards;
         _dailyCompoundBonus = user.dailyCompoundBonus;
	}

    function getTimeStamp() public view returns (uint256) {
        return block.timestamp;
    }

    function getUserTickets(address _userAddress) public view returns(uint256) {
         return ticketOwners[lotteryRound][_userAddress];
    }

    function getLotteryTimer() public view returns(uint256) {
        return LOTTERY_START_TIME.add(LOTTERY_STEP);
    }

    function getAvailableEarnings(address _adr) public view returns(uint256) {
        uint256 userGolds = users[_adr].claimedGolds.add(getGoldsSinceLastClaim(_adr));
        return calculateGoldSell(userGolds);
    }

    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }

    function calculateGoldSell(uint256 golds) public view returns(uint256){
        return calculateTrade(golds,marketGolds, address(this).balance);
    }

    function calculateGoldBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth,contractBalance,marketGolds);
    }

    function calculateGoldBuySimple(uint256 eth) public view returns(uint256){
        return calculateGoldBuy(eth, address(this).balance);
    }

    function getBalance() public view returns(uint256){
        return address(this).balance;
    }

    /** How many miners and golds per day user will recieve for 1 BNB deposit **/
    function getGoldsYield() public view returns(uint256,uint256) {
        uint256 goldsAmount = calculateGoldBuy(1 ether , address(this).balance.add(1 ether).sub(1 ether));
        uint256 miners = goldsAmount.div(GOLDS_TO_HIRE_1MINERS);
        uint256 day = 1 days;
        uint256 goldsPerDay = day.mul(miners);
        uint256 earningsPerDay = calculateGoldSellForYield(goldsPerDay);
        return(miners, earningsPerDay);
    }

    function getSiteInfo() public view returns (uint256 _totalStaked, uint256 _totalDeposits, uint256 _totalCompound, uint256 _totalRefBonus, uint256 _totalLotteryBonus) {
        return (totalStaked, totalDeposits, totalCompound, totalRefBonus, totalLotteryBonus);
    }

    function calculateGoldSellForYield(uint256 golds) public view returns(uint256){
        return calculateTrade(golds,marketGolds, address(this).balance.add(1 ether));
    }

    function getMyMiners() public view returns(uint256){
        return users[msg.sender].miners;
    }

    function getMyGolds() public view returns(uint256){
        return users[msg.sender].claimedGolds.add(getGoldsSinceLastClaim(msg.sender));
    }

    function getGoldsSinceLastClaim(address adr) public view returns(uint256){
        uint256 secondsSinceLastClaim = block.timestamp.sub(users[adr].lastClaim);
                            /** get min time. **/
        uint256 cutoffTime = min(secondsSinceLastClaim, CUTOFF_STEP);
        uint256 secondsPassed = min(GOLDS_TO_HIRE_1MINERS, cutoffTime);
        return secondsPassed.mul(users[adr].miners);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    /** lottery enabler **/
    function ENABLE_LOTTERY() public {
        require(msg.sender == owner, "Admin use only.");
        require(contractStarted);
        LOTTERY_ACTIVATED = true;
        LOTTERY_START_TIME = block.timestamp;
    }

    function DISABLE_LOTTERY() public {
        require(msg.sender == owner, "Admin use only.");
        require(contractStarted);
        LOTTERY_ACTIVATED = false;
    }

    /** wallet addresses **/
    function CHANGE_OWNERSHIP(address value) external {
        require(msg.sender == owner, "Admin use only.");
        owner = payable(value);
    }

    function CHANGE_PROJECT(address value) external {
        require(msg.sender == owner, "Admin use only.");
        project = payable(value);
    }

    function CHANGE_PARTNER(address value) external {
        require(msg.sender == owner, "Admin use only.");
        partner = payable(value);
    }

    function CHANGE_MARKETING(address value) external {
        require(msg.sender == owner, "Admin use only.");
        marketing = payable(value);
    }

    /** percentage **/

    /**
    
        2592000 - 3%
        2160000 - 4%
        1728000 - 5%
        1440000 - 6%
        1200000 - 7%
        1080000 - 8%
         959000 - 9%
         864000 - 10%
         720000 - 12%

    **/
    function PRC_GOLDS_TO_HIRE_1MINERS(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        require(value >= 720000 && value <= 2592000); /** min 3% max 12%**/
        GOLDS_TO_HIRE_1MINERS = value;
    }

    function PRC_GOLDS_TO_HIRE_1MINERS_COMPOUND(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        require(value >= 720000 && value <= 2592000); /** min 3% max 12%**/
        GOLDS_TO_HIRE_1MINERS_COMPOUND = value;
    }

    function PRC_MARKET_GOLDS_DIVISOR(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        require(value >= 5 && value <= 20); /** 20 = 5% **/
        MARKET_GOLDS_DIVISOR = value;
    }

    function PRC_MARKET_GOLDS_DIVISOR_SELL(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        require(value >= 5 && value <= 20); /** 20 = 5% **/
        MARKET_GOLDS_DIVISOR_SELL = value;
    }

    /* lottery setters */

    function SET_LOTTERY_STEP(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
         /** hour conversion **/
        LOTTERY_STEP = value * 60 * 60;
    }

    function SET_LOTTERY_PERCENT(uint256 value) external {
        require(msg.sender == owner, "Admin use only");
        require(value >= 10 && value <= 50); /** 5% max **/
        LOTTERY_PERCENT = value;
    }

    function SET_LOTTERY_TICKET_PRICE(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        require(value >= 1 && value <= 10);
        LOTTERY_TICKET_PRICE = value * 1e15;
    }

    function SET_MAX_LOTTERY_TICKET(uint256 value) external {
        require(msg.sender == owner, "Admin use only");
        require(value >= 1 && value <= 100);
        MAX_LOTTERY_TICKET = value;
    }

    function SET_MAX_LOTTERY_PARTICIPANTS(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        require(value >= 2 && value <= 200); /** min 10, max 200 **/
        MAX_LOTTERY_PARTICIPANTS = value;
    }

    function SET_INVEST_MIN(uint256 value) external {
        require(msg.sender == owner, "Admin use only");
        MIN_INVEST = value * 1e15;
    }

    function SET_CUTOFF_STEP(uint256 value) external {
        require(msg.sender == owner, "Admin use only");
        require(value >= 24 && value <= 48); /** min 24, max 48 **/
        CUTOFF_STEP = value * 60 * 60;
    }
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}