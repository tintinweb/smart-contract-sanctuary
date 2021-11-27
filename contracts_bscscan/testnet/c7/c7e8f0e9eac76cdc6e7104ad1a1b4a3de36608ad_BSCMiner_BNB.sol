/**
 *Submitted for verification at BscScan.com on 2021-11-26
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-26
*/

/**

 BSC Miner - BNB  

 5% daily interest. 
 Compounding bonus, 3% additional for every compound stackable up to 10 straight days. (30%)
 5% Referral Bonus.

 Launch Event Bonuses:
 Referral bonus from 5% -> 7%
 Compounding bonus to 3% -> 5%
 
 Upcoming Features:
 Lottery, 2% worth of every deposit / compound will be computed to get tickets for the lottery. 
    ~ every 12 hours.
    ~ withdrawable rewards.
 Mini Games:
    ~ Profits after fees will all go to the smart contract. more details soon!
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9; 

contract BSCMiner_BNB {
    using SafeMath for uint256;
    uint256 public EGGS_TO_HIRE_1MINERS = 1728000;
    uint256 public REFERRAL_PERCENT = 50;
    uint256 public PERCENTS_DIVIDER = 1000;
    uint256 public MARKETING = 10;
    uint256 public COMMUNITY = 30;
    uint256 public PROJECT = 40;
	
    /** bonus **/
	uint256 DAILY_COMPOUND_BONUS_PERCENTAGE = 30; // 3%
	uint256 DAILY_COMPOUND_BONUS_MAX_DAYS = 10;

    /* lottery */
	bool public LOTTERY_ACTIVATED;
	uint256 public constant MINER_PER_TICKET = 1e17; 
    uint256 public lotteryRound = 0;
    uint256 public currentPot = 0;
    uint256 public participants = 0;
    uint256 public totalPoints = 0;
    uint256 public LOTTERY_STEP = 12 * 60 * 60; //every 12 hours.
    uint256 public LOTTERY_START_TIME;
    uint256 public LOTTERY_PERCENT = 20;
    uint256 public MAX_LOTTERY_PARTICIPANTS = 100;
    uint256 public totalTickets = 0;
    
    uint256 public totalStaked;
    uint256 public totalDeposits;
    uint256 public totalCompound;
    uint256 public totalRefBonus;

    uint256 public marketEggs;
    uint256 PSN = 10000;
    uint256 PSNH = 5000;

    bool public initialized = false;

    address payable public contractOwner;
    address payable public projectWallet;
    address payable public marketingWallet;
    address payable public insuranceWallet;

    struct User {
        uint256 initialDeposit;
        uint256 userDeposit;
        uint256 miners;
        uint256 claimedEggs;
        uint256 lastHatch;
        address referrer;
        uint256 referrals;
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

    constructor(address payable _owner,address payable _project, address payable _marketing, address payable _insurance) {
        contractOwner = _owner;
        projectWallet = _project;
        marketingWallet = _marketing; 
        insuranceWallet = _insurance;   
    }

    function hatchEggs(address ref, bool useCompoundBonus) public {
        require(initialized);
        User storage user = users[msg.sender];

        if (user.referrer == address(0)) {
            if (ref != msg.sender) {
                user.referrer = ref;
            }

            address upline1 = user.referrer;
            if (upline1 != address(0)) {
                users[upline1].referrals = users[upline1].referrals.add(1);
            }
        }

        uint256 eggsUsed = getMyEggs();
        uint256 eggsUsedForReferrer = eggsUsed;
        
        //if lottery is activated.
        if (LOTTERY_ACTIVATED) {
            uint256 lotteryTicket = eggsUsed.mul(LOTTERY_PERCENT).div(PERCENTS_DIVIDER);
			_buyTickets(msg.sender, lotteryTicket);
		}

        //useCompoundBonus -- only true when compounding.
        if(useCompoundBonus) {
            uint256 dailyCompoundBonus = getDailyCompoundBonus(msg.sender, eggsUsed);
            eggsUsed = eggsUsed.add(dailyCompoundBonus);
            
            uint256 eggsUsedValue = calculateEggSell(eggsUsed);
            user.userDeposit = user.userDeposit.add(eggsUsedValue);  
        }
        
        uint256 eggValue = calculateEggSell(eggsUsed);

        //send fee
         if(!useCompoundBonus) {
            payFees(eggValue);
         }
         
        eggsUsed = eggsUsed.mul(9).div(10);
        
         //for each compounding the user will have additional 2 percent in the next compound for 15 consecutive days max,
         // bonus will reset after every withdrawal.
        if(block.timestamp.sub(user.lastHatch) >= 1 days) {
            if(user.dailyCompoundBonus < DAILY_COMPOUND_BONUS_MAX_DAYS) {
                user.dailyCompoundBonus = user.dailyCompoundBonus.add(1);
            }
        }



        //miner increase
        uint256 newMiners = SafeMath.div(eggsUsed,EGGS_TO_HIRE_1MINERS);
        user.miners = SafeMath.add(user.miners, newMiners);
        user.claimedEggs = 0;
        user.lastHatch = block.timestamp;

        if (user.referrer != address(0)) {
            address upline = user.referrer;
            if (upline != address(0)) {
                uint256 amount = eggsUsedForReferrer.mul(REFERRAL_PERCENT).div(PERCENTS_DIVIDER);
                users[upline].claimedEggs = users[upline].claimedEggs.add(amount);
                users[upline].referralEggRewards = users[upline].referralEggRewards.add(amount);
            }
        }
                
        //boost market to nerf miners hoarding
        marketEggs = SafeMath.add(marketEggs,SafeMath.div(eggsUsed,5));
    }
    
    function sellEggs() public{
        require(initialized);
        User storage user = users[msg.sender];
        uint256 hasEggs = getMyEggs();
        uint256 eggValue = calculateEggSell(hasEggs);

        user.claimedEggs = 0;
        user.lastHatch = block.timestamp;
        
        // reset daily compound bonus
        user.dailyCompoundBonus = 0;

        marketEggs = SafeMath.add(marketEggs,hasEggs);
        
        // check if contract has enough funds to pay -- one last ride.
        if(getBalance() < eggValue) {
            eggValue = getBalance();
        }
        uint256 project = eggValue.mul(PROJECT).div(PERCENTS_DIVIDER);
        projectWallet.transfer(project);
        payable(address(msg.sender)).transfer(eggValue.sub(project));
    }

    function payFees(uint256 eggValue) internal returns(uint256) {
		uint256 project = eggValue.mul(PROJECT).div(PERCENTS_DIVIDER);
        uint256 marketing = eggValue.mul(MARKETING).div(PERCENTS_DIVIDER);
        projectWallet.transfer(project);
        marketingWallet.transfer(marketing);
        return project.add(marketing);
    }
  
    //transfer amount of bnb 
    function buyEggs(address ref) public payable{
        User storage user = users[msg.sender];
        if (!initialized) {
    		if (msg.sender == contractOwner) {
    		    require(marketEggs == 0);
    			initialized = true;
                marketEggs = 172800000000;
    		} else revert("Contract not yet started.");
    	}
        
        uint256 eggsBought = calculateEggBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
        user.userDeposit = user.userDeposit.add(msg.value);
        user.initialDeposit = user.initialDeposit.add(msg.value); 
        user.claimedEggs = SafeMath.add(user.claimedEggs,eggsBought);
        totalStaked = totalStaked.add(msg.value);
        totalDeposits = totalDeposits.add(1);
        hatchEggs(ref, false);
    }

    // lottery section!
    function _buyTickets(address userAddress, uint256 amount) private {
        require(amount != 0, "zero purchase amount");

        //calculate how many tickets
        uint256 tickets = amount.mul(1e18).div(MINER_PER_TICKET);
        
        if(ticketOwners[lotteryRound][userAddress] == 0) {
            participantAdresses[lotteryRound][participants] = userAddress;
            participants = participants.add(1);
        }

        ticketOwners[lotteryRound][userAddress] = ticketOwners[lotteryRound][userAddress].add(tickets);
        currentPot = currentPot.add(amount);
        totalTickets = totalTickets.add(tickets);

        if(block.timestamp.sub(LOTTERY_START_TIME) >= LOTTERY_STEP || participants == MAX_LOTTERY_PARTICIPANTS){
            _chooseWinner();
        }
        //end here
    }
    
    // will auto execute, when condition is met.
    function _chooseWinner() private {
       require(((block.timestamp.sub(LOTTERY_START_TIME) >= LOTTERY_STEP) 
                    || participants == MAX_LOTTERY_PARTICIPANTS),
        "Lottery must run for LOTTERY_STEP or there must be MAX_LOTTERY_PARTICIPANTS particpants"); 
        
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
               _payLotteryWinner(winnerAddress);
              
               // reset lotteryRound
               currentPot = 0;
               participants = 0;
               totalPoints = 0;
               LOTTERY_START_TIME = block.timestamp;
               lotteryRound = lotteryRound.add(1);
               break;
           }
       }
    }
    
    function _payLotteryWinner(address userAddress) private {
        User storage user = users[userAddress];
        //winner will have the prize in their claimable rewards.
        uint256 eggsReward = currentPot.mul(9).div(10);
        user.claimedEggs = user.claimedEggs.add(eggsReward);

        uint256 eggValue = calculateEggSell(currentPot);
        uint256 community = eggValue.mul(COMMUNITY).div(PERCENTS_DIVIDER);
        insuranceWallet.transfer(community);

        //record round
        lotteryHistory.push(LotteryHistory(lotteryRound, userAddress, eggsReward, participants, totalTickets));
        emit LotteryWinner(userAddress, currentPot, lotteryRound);
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
            uint256 totalBonus = users[_adr].dailyCompoundBonus.mul(DAILY_COMPOUND_BONUS_PERCENTAGE); // How many % 
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

    function getLotteryInfo() public view returns (uint256 lotteryStartTime,  uint256 lotteryStep, uint256 minerPerTicket, uint256 lotteryCurrentPot, 
	  uint256 lotteryParticipants, uint256 maxLotteryParticipants, uint256 totalLotteryTickets, uint256 lotteryPercent, uint256 round){
		lotteryStartTime = LOTTERY_START_TIME;
		lotteryStep = LOTTERY_STEP;
		minerPerTicket = MINER_PER_TICKET;
		maxLotteryParticipants = MAX_LOTTERY_PARTICIPANTS;
		lotteryCurrentPot = currentPot;
		lotteryParticipants = participants;
	    totalLotteryTickets = totalTickets;
		lotteryPercent = LOTTERY_PERCENT;
		round = lotteryRound;
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
    
    //How many miners and eggs per day user will recieve for 0.01 BNB deposit
    function getEggsYield() public view returns(uint256,uint256) {
        uint256 eggsAmount = calculateEggBuy(0.01 ether ,SafeMath.sub(address(this).balance.add(0.01 ether),0.01 ether));
        uint256 miners = SafeMath.div(eggsAmount,EGGS_TO_HIRE_1MINERS);
        uint256 day = 1 days;
        uint256 eggsPerDay = day.mul(miners);
        uint256 earningsPerDay = calculateEggSellForYield(eggsPerDay);
        return(miners, earningsPerDay);
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
        uint256 secondsPassed=min(EGGS_TO_HIRE_1MINERS,SafeMath.sub(block.timestamp,users[adr].lastHatch));
        return SafeMath.mul(secondsPassed,users[adr].miners);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function getTimeStamp() public view returns (uint256) {
        return block.timestamp;
    }
    

    /** event activation **/
     function SET_LOTTERY(bool value) public {
        require(initialized);
        require(msg.sender == contractOwner);
        if(value = true){
            LOTTERY_ACTIVATED = true;
            LOTTERY_START_TIME = block.timestamp;
        }else{
            LOTTERY_ACTIVATED = false;
        }  
    }

    /** wallet addresses **/

    function changeProjectWallet(address value) external {
        require(msg.sender == contractOwner, "Admin use only");
        projectWallet = payable(value);
    }

    function changeOwnership(address value) external {
        require(msg.sender == contractOwner, "Admin use only");
        contractOwner = payable(value);
    }

    function changeMarketingWallet(address value) external {
        require(msg.sender == contractOwner, "Admin use only");
        marketingWallet = payable(value);
    }

    function changeInsuranceWallet(address value) external {
        require(msg.sender == contractOwner, "Admin use only");
        insuranceWallet = payable(value);
    }

    /** percentage **/
    function prc_PROJECT(uint256 value) external {
        require(msg.sender == contractOwner, "Admin use only");
        require(value < 100); /** 10% max **/
        PROJECT = value;
    }
    function prc_MARKETING(uint256 value) external {
        require(msg.sender == contractOwner, "Admin use only");
        require(value < 50); /** 5% max **/
        MARKETING = value;
    }

    function SET_REFERRAL_PERCENT(uint256 value) external {
        require(msg.sender == contractOwner, "Admin use only");
        require(value < 80); /** 8% max **/
        REFERRAL_PERCENT = value;
    }

    /** bonus **/
    function BONUS_DAILY_COMPOUND_BONUS_PERCENTAGE(uint256 value) external {
        require(msg.sender == contractOwner, "Admin use only");
        require(value < 7); /** 7 max **/
        DAILY_COMPOUND_BONUS_PERCENTAGE = value;
    }

    function BONUS_DAILY_COMPOUND_BONUS_MAX_DAYS(uint256 value) external {
        require(msg.sender == contractOwner, "Admin use only");
        require(value < 10); /** 10 days max **/
        DAILY_COMPOUND_BONUS_MAX_DAYS = value;
    }

    /* lottery setters */
    function SET_LOTTERY_START_TIME(uint256 value) external {
        require(msg.sender == contractOwner, "Admin use only");
        LOTTERY_START_TIME = value * 1 days;
    }

    function SET_LOTTERY_STEP(uint256 value) external {
        require(msg.sender == contractOwner, "Admin use only");
        require(value >= 1 && value < 31); /** 1 month max **/
        LOTTERY_STEP = value  * 60 * 60;
    }

    function SET_LOTTERY_PERCENT(uint256 value) external {
        require(msg.sender == contractOwner, "Admin use only");
        require(value < 50); /** 50 max **/
        LOTTERY_PERCENT = value;
    }

    function SET_MAX_LOTTERY_PARTICIPANTS(uint256 value) external {
        require(msg.sender == contractOwner, "Admin use only");
        MAX_LOTTERY_PARTICIPANTS = value;
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