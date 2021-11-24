/**
 *Submitted for verification at BscScan.com on 2021-11-24
*/

/**
 * 7% miner contract basis
 
 * 40% of the amount for withdrawal be auto re-invested. (+/- 4% if withdrawals are made daily.)
 
 * Compounding bonus. For every compound action, the users bonus increases by 3% per day. 
   (Max of 30% if compounding is done for 7 straight days.)
   LAUNCH EVENT. for the first 2 days, Compound bonus will be 4%!
 
 * 1 level referral bonus of 5%
   
 * Dynamic reward system.  

 * Lottery!
   User will be given tickets to take part of the lottery. 
   Lottery tickets will be replenished as follows.
   2% of amount from new deposits and compound action will be used to get the user tickets for the lottery. 0.008 bnb = 1 ticket.
    * every 0.008 bnb($5) of investment = 1 ticket.
   Winners will get half of the pot and half will be used to buy more miners.
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9; 

contract TheBNBInsider {
    using SafeMath for uint256;
    //address token =  0x000000000000000000DEAD000000000000000000000;
    uint256 public EGGS_TO_HIRE_1MINERS = 1200000;
    uint256 public REFERRAL_PERCENT = 50;
    uint256 public PERCENTS_DIVIDER = 1000;
    uint256 public MARKETING = 20;
    uint256 public COMMUNITY = 50;
    uint256 public BUY = 50;
    uint256 public SELL = 30;
	
    /** compound bonus **/
	uint256 DAILY_COMPOUND_BONUS_PERCENTAGE = 30; // 2%
	uint256 DAILY_COMPOUND_BONUS_MAX_DAYS = 15;
	
	/* lottery */
	bool public LOTTERY_ENABLED;
	uint256 public constant MINER_PER_POINT = 1e17; 
    uint256 public lotteryRound = 0;
    uint256 public currentPot = 0;
    uint256 public participants = 0;
    uint256 public totalPoints = 0;
    uint256 public LOTTERY_STEP = 1 days; 
    uint256 public LOTTERY_START_TIME;
    uint256 public LOTTERY_PERCENT = 20;
	uint256 public LOTTERY_TICKET_PRICE = 0.008 ether;
    uint256 public MAX_LOTTERY_TICKET = 100;
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
    address payable public communityWallet;

    struct User {
        uint256 initialTokenDeposit;
        uint256 userTokenDeposit;
        uint256 miners;
        uint256 claimedEggs;
        uint256 lastHatch;
        address referrer;
        uint256 referrals;
        uint256 refRewardsEggs;
        uint256 lotteryBonus;
        uint256 totalLotteryBonus;
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
    event onLotteryWinner(address indexed investor, uint256 pot, uint256 indexed round);

    constructor(address payable _owner,address payable _project, address payable _marketing, address payable _community) {
        contractOwner = _owner;
        projectWallet = _project;
        marketingWallet = _marketing; 
        communityWallet = _community;  
    }

    function hatchEggs(address ref, bool useCompoundBonus) public {
        require(initialized);
        User storage user = users[msg.sender];

        uint256 eggsUsed = getMyEggs();
        
        //uint256 lotteryTicket = eggsUsed.mul(LOTTERY_PERCENT).div(PERCENTS_DIVIDER);
        if (LOTTERY_ENABLED) {
			_buyTickets(msg.sender, eggsUsed);
		}
        
        //useCompoundBonus -- only true when compounding.
        if(useCompoundBonus) {
            uint256 dailyCompoundBonus = getDailyCompoundBonus(msg.sender, eggsUsed);
            eggsUsed = eggsUsed.add(dailyCompoundBonus);
            
            uint256 eggsUsedValue = calculateEggSell(eggsUsed);
            user.userTokenDeposit = user.userTokenDeposit.add(eggsUsedValue);  
        }
        
        //send commissions only on buy.
         if(!useCompoundBonus) {
            uint256 eggValue = calculateEggSell(eggsUsed);
            projectWallet.transfer(eggValue.mul(BUY).div(PERCENTS_DIVIDER));
         }
         
        eggsUsed = eggsUsed.mul(9).div(10);
        
         //for each compounding the user will have additional 2 percent in the next compound for 7 consecutive days max,
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
        
        //send referral eggs
        if (user.referrer == address(0)) {
            if (ref != msg.sender) {
                user.referrer = ref;
            }

            address upline = user.referrer;
            if (upline != address(0)) {
				upline = users[upline].referrer;
				users[upline].referrals = users[upline].referrals.add(1);
            }
        }
        
        uint256 amount;
        if (user.referrer != address(0)) {
            address upline = user.referrer;
            if (upline != address(0)) {
                amount = eggsUsed.mul(REFERRAL_PERCENT).div(PERCENTS_DIVIDER);
                users[upline].claimedEggs = users[upline].claimedEggs.add(amount);
                users[upline].refRewardsEggs = users[upline].refRewardsEggs.add(amount);
                totalRefBonus = totalRefBonus.add(amount);
            }
        }else{
		    amount = eggsUsed.mul(COMMUNITY).div(PERCENTS_DIVIDER);
		    users[communityWallet].claimedEggs = users[communityWallet].claimedEggs.add(amount);
            users[communityWallet].refRewardsEggs = users[communityWallet].refRewardsEggs.add(amount);
            totalRefBonus = totalRefBonus.add(amount);
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
        
        uint256 autoCompoundAmount = SafeMath.div(SafeMath.mul(eggValue,40),100);
        uint256 project = eggValue.mul(SELL).div(PERCENTS_DIVIDER);
        uint256 marketing = eggValue.mul(MARKETING).div(PERCENTS_DIVIDER);
        projectWallet.transfer(project);
        marketingWallet.transfer(marketing);
        payable(address(msg.sender)).transfer(eggValue.sub(project).sub(marketing).sub(autoCompoundAmount));
        //invest 40% of total earnings
        buyEggs(msg.sender, autoCompoundAmount, true);
    }

    function startContract() public {
        require(msg.sender == contractOwner, "Admin use only");
        require(initialized == false, "Contract already started");
        require(marketEggs == 0);
        initialized = true;
        marketEggs = 120000000000;
        LOTTERY_START_TIME = block.timestamp;
        LOTTERY_ENABLED = true;
    }
  
    //transfer amount of bnb 
    function buyEggs(address ref, uint256 amount, bool reinvest) public payable{
        User storage user = users[msg.sender];
        
    	/**
        if(!reinvest){
    	   ERC20(token).transferFrom(address(msg.sender), address(this), amount);  
    	}
    	**/
        
        uint256 eggsBought = calculateEggBuy(amount,SafeMath.sub(address(this).balance, amount));
        
        //only record user token deposit for compound and lottery winner
        if(reinvest){
          user.userTokenDeposit = user.userTokenDeposit.add(amount);
        }else{
          user.userTokenDeposit = user.userTokenDeposit.add(amount);
          user.initialTokenDeposit = user.initialTokenDeposit.add(amount); 
        }
        
        user.claimedEggs = SafeMath.add(user.claimedEggs,eggsBought);
        totalStaked = totalStaked.add(amount);
        totalDeposits = totalDeposits.add(1);
        hatchEggs(ref,false);
    }
    
    // lottery section!
    function _buyTickets(address userAddress, uint256 amount) private {
        require(amount != 0, "zero purchase amount");

        uint256 userTickets = ticketOwners[lotteryRound][userAddress];
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
        }

        ticketOwners[lotteryRound][userAddress] = userTickets.add(numTickets);
        uint256 lotteryAmount = amount.mul(LOTTERY_PERCENT).div(PERCENTS_DIVIDER);
        currentPot = currentPot.add(lotteryAmount);
        totalTickets = totalTickets.add(numTickets);

        if(block.timestamp.sub(LOTTERY_START_TIME) >= LOTTERY_STEP || participants == MAX_LOTTERY_PARTICIPANTS) {
            _chooseWinner();
        }
    }
    
    // will auto execute, when condition is met.
    function _chooseWinner() private {
       require(((block.timestamp.sub(LOTTERY_START_TIME) >= LOTTERY_STEP) 
                    || participants == MAX_LOTTERY_PARTICIPANTS),
        "Lottery much run for LOTTERY_STEP or there must be MAX_LOTTERY_PARTICIPANTS particpants"); 
        
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
        
        uint256 eggValue = calculateEggSell(currentPot);
        uint256 community = eggValue.mul(COMMUNITY).div(PERCENTS_DIVIDER);
        communityWallet.transfer(community);
		currentPot = currentPot.sub(community);

        // half is added to available rewards balance
        uint256 halfPot = currentPot.mul(500).div(PERCENTS_DIVIDER);
        user.lotteryBonus = user.lotteryBonus.add(halfPot);
        user.totalLotteryBonus = user.totalLotteryBonus.add(currentPot);

        // half will be used to buy more eggs.
        buyEggs(userAddress, halfPot, true);

        //record lottery round and winner
        lotteryHistory.push(LotteryHistory(lotteryRound, userAddress, currentPot, participants, totalTickets));
        emit LotteryWinner(userAddress, currentPot, lotteryRound);
    }	
    
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
    
    function getUserPoints(address _userAddress) public view returns(uint256) {
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
    
    //How many miners and eggs per day user will recieve for 1 Token deposit
    function getEggsYield() public view returns(uint256,uint256) {
        uint256 eggsAmount = calculateEggBuy(1 ether ,SafeMath.sub(address(this).balance.add(1 ether),1 ether));
        uint256 miners=SafeMath.div(eggsAmount,EGGS_TO_HIRE_1MINERS);
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
    
    
    /**DYNAMIC SETTERS **/

    /** wallet addresses **/
    function addr_ProjectWallet(address value) external {
        require(msg.sender == contractOwner, "Admin use only");
        projectWallet = payable(value);
    }
    function addr_contractOwner(address value) external {
        require(msg.sender == contractOwner, "Admin use only");
        contractOwner = payable(value);
    }
    function addr_marketingWallet(address value) external {
        require(msg.sender == contractOwner, "Admin use only");
        marketingWallet = payable(value);
    }
    function addr_CommunityWallet(address value) external {
        require(msg.sender == contractOwner, "Admin use only");
        communityWallet = payable(value);
    }

    /** percentages **/
    function prc_SELL(uint256 value) external {
        require(msg.sender == contractOwner, "Admin use only");
        require(value < 100); /** 10 max **/
        SELL = value;
    }
    function prc_BUY(uint256 value) external {
        require(msg.sender == contractOwner, "Admin use only");
        require(value < 100); /** 10 max **/
        BUY = value;
    }
    function prc_COMMUNITY(uint256 value) external {
        require(msg.sender == contractOwner, "Admin use only");
        require(value < 50); /** 5 max **/
        COMMUNITY = value;
    }

    /** bonus **/
    function prc_DAILY_COMPOUND_BONUS_PERCENTAGE(uint256 value) external {
        require(msg.sender == contractOwner, "Admin use only");
        require(value < 7); /** 7 max **/
        DAILY_COMPOUND_BONUS_PERCENTAGE = value;
    }
    function day_DAILY_COMPOUND_BONUS_MAX_DAYS(uint256 value) external {
        require(msg.sender == contractOwner, "Admin use only");
        require(value < 10); /** 10 days max **/
        DAILY_COMPOUND_BONUS_MAX_DAYS = value;
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
        require(value < 50); /** 50 max **/
        LOTTERY_PERCENT = value;
    }
    function SET_LOTTERY_TICKET_PRICE(uint256 value) external {
        require(msg.sender == contractOwner, "Admin use only");
        LOTTERY_TICKET_PRICE = value;
    }
    function SET_MAX_LOTTERY_TICKET(uint256 value) external {
        require(msg.sender == contractOwner, "Admin use only");
        MAX_LOTTERY_TICKET = value;
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