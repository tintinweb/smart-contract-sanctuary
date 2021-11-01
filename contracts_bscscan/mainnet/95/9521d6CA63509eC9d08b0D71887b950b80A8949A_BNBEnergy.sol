/**
 *Submitted for verification at BscScan.com on 2021-11-01
*/

// bnbenergy.finance




// ████──█──█─████──███─█──█─███─████─████─██─██
// █──██─██─█─█──██─█───██─█─█───█──█─█─────███
// ████──█─██─████──███─█─██─███─████─█─██───█
// █──██─█──█─█──██─█───█──█─█───█─█──█──█───█
// ████──█──█─████──███─█──█─███─█─█──████───█
// ──────────────────────────────────────────█

pragma solidity ^0.5.8; 

contract BNBEnergy{
    using SafeMath for uint256;

    uint256 public POWER_TO_HIRE_1MINERS=2592000;
    uint256[] public REFERRAL_PERCENTS = [50, 25, 5]; //5% - 2.5% - 0.5%
    uint256 constant public PERCENTS_DIVIDER = 1000;
    uint256 constant public PROJECT_FEE = 50;
	uint256 constant public DEVELOPER_FEE = 20;
	uint256 constant public MARKETING_FEE = 30;
	
	uint256 constant public TRIAL_VIP = 3 days;
	uint256 constant public COMPOUND_VIP_BONUS = 900; // 90%
	uint256 constant public REFERRAL_VIP_BONUS = 50; // 5%
	uint256 constant public POINTS_VIP_BONUS = 100; // 10%
	
	uint256 constant public VIP_PRICE_DAY = 20; // 2% from deposit
	uint256 constant public VIP_DISCOUNT_7DAYS = 70; // 7%
	uint256 constant public VIP_DISCOUNT_30DAYS = 170; // 17%
	
	uint256 constant DAILY_COMPOUND_BONUS_STEP = 20; // 2%
	uint256 constant DAYLY_COMPOUND_BONUS_MAX = 10; // 10 days
	
	uint256 public constant POWER_PER_POINT = 1e17; 
    uint256 public lotteryRound = 0;
    uint256 public currentPot = 0;
    uint256 public participants = 0;
    uint256 public totalPoints = 0;
    uint256 public LOTTERY_STEP = 6 hours; 
    uint256 public LOTTERY_START_TIME;
    
    uint256 public POINTS_FOR_LOTTERY = 20; //2%
    
    uint256 public totalStaked;
    uint256 public totalDeposits;

    uint256 PSN=10000;
    uint256 PSNH=5000;

    bool public initialized = false;

    address payable private wallet;
    address payable private devAddress;
    address payable public marketing;

    struct User {
        uint256 initialBnbDeposit;
        uint256 userBnbDeposit;
        uint256 miners;
        uint256 claimedPower;
        uint256 lastUpgrade;
        address referrer;
        uint256 referrals;
        uint256 refRewardsPower;
        uint256 vipBuyTime;
        uint256 vipBoughtDays;
        uint256 dailyCompoundBonus;
    }

    mapping (address => User) public users;
    
    mapping(uint256 => mapping(address => uint256)) public pointsOwners; // round => address => amount of owned points
    mapping(uint256 => mapping(uint256 => address)) public participantAdresses; // round => id => address


    uint256 public marketPower;
    
    event onLotteryWinner(address indexed investor, uint256 pot, uint256 indexed round);

    constructor(address payable _dev, address payable _wallet, address payable _marketing) public{
        wallet = _wallet;
        devAddress = _dev;
        marketing = _marketing;    
    }


    function upgradePower(address ref, bool useCompoundVipBonus) public {
        require(initialized);
        
        _checkVIP(msg.sender);

        User storage user = users[msg.sender];

        if (user.referrer == address(0)) {
			if (ref != msg.sender) {
				user.referrer = ref;
			}

			address upline = user.referrer;
			for (uint256 i = 0; i < REFERRAL_PERCENTS.length; i++) { 
				if (upline != address(0)) {
					users[upline].referrals = users[upline].referrals.add(1);
					upline = users[upline].referrer;
				} else break;
			}
		}

        uint256 powerUsed=getMyPower();
        uint256 powerForReferrers = powerUsed;
        
        uint256 lotteryPower = powerUsed.mul(POINTS_FOR_LOTTERY).div(PERCENTS_DIVIDER);
        
        if(user.vipBoughtDays != 0) {
            //user has VIP
            lotteryPower = lotteryPower.add(lotteryPower.mul(POINTS_VIP_BONUS).div(PERCENTS_DIVIDER));
        }
        
        _buyPoints(msg.sender, lotteryPower);
		
        //VIP compound bonus
        if(useCompoundVipBonus) {
            
            uint256 _dailyCompoundBonus = getDailyCompoundBonus(msg.sender, powerUsed);
             
            if(user.vipBoughtDays != 0) {
                //user has VIP
                powerUsed = powerUsed.add(powerUsed.mul(COMPOUND_VIP_BONUS).div(PERCENTS_DIVIDER));
            }
            
          
            
            powerUsed = powerUsed.add(_dailyCompoundBonus);
            
            uint256 powerUsedValue = calculatePowerSell(powerUsed);
            user.userBnbDeposit = user.userBnbDeposit.add(powerUsedValue);
            
        }
        
        

        //send commissions
        uint256 powerValue = calculatePowerSell(powerUsed);

        uint256 walletFee = powerValue.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
        wallet.transfer(walletFee);
        uint256 devFee = powerValue.mul(DEVELOPER_FEE).div(PERCENTS_DIVIDER);
        devAddress.transfer(devFee);
        uint256 marketingFee = powerValue.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
        marketing.transfer(marketingFee);

        //update final power
        powerUsed = powerUsed.mul(9).div(10);
        
         //update daily compound bonus
        if(now.sub(user.lastUpgrade) >= 1 days) {
            if(user.dailyCompoundBonus <10) {
                user.dailyCompoundBonus = user.dailyCompoundBonus.add(1);
            }
        }

        //power accrual
        uint256 newMiners=SafeMath.div(powerUsed,POWER_TO_HIRE_1MINERS);
        user.miners=SafeMath.add(user.miners,newMiners);
        user.claimedPower = 0;
        user.lastUpgrade=now;
        
        //send referral powers

        if (user.referrer != address(0)) {
			address upline = user.referrer;
			for (uint256 i = 0; i < REFERRAL_PERCENTS.length; i++) {  
				if (upline != address(0)) {
				        
    					uint256 powerAmount = powerForReferrers.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
    					
    					if(users[upline].vipBoughtDays != 0) {
				            //user has VIP
				            powerAmount = powerAmount.add(powerAmount.mul(REFERRAL_VIP_BONUS).div(PERCENTS_DIVIDER));
				        }
    					
    					users[upline].claimedPower = users[upline].claimedPower.add(powerAmount);
                        users[upline].refRewardsPower = users[upline].refRewardsPower.add(powerAmount);
					
					upline = users[upline].referrer;
				} else break;
			}

		}

        
        //boost market to nerf miners hoarding
        marketPower=SafeMath.add(marketPower,SafeMath.div(powerUsed,5));
    }
    
    
    
    function sellPower() public{
        require(initialized);
        
        _checkVIP(msg.sender);

        uint256 hasPower=getMyPower();
        uint256 powerValue=calculatePowerSell(hasPower);
        
        uint256 lotteryPower = hasPower.mul(POINTS_FOR_LOTTERY).div(PERCENTS_DIVIDER);
        
        if(users[msg.sender].vipBoughtDays != 0) {
            //user has VIP
            
            lotteryPower = lotteryPower.add(lotteryPower.mul(POINTS_VIP_BONUS).div(PERCENTS_DIVIDER));
        }
        
        _buyPoints(msg.sender, lotteryPower);

        users[msg.sender].claimedPower = 0;
        users[msg.sender].lastUpgrade = now;
        
        // reset daily compound bonus
        users[msg.sender].dailyCompoundBonus = 0;

        marketPower=SafeMath.add(marketPower,hasPower);
        
        // check if contract has enough funds to pay
        if(getBalance() < powerValue) {
            powerValue = getBalance();
        }
        
        msg.sender.transfer(powerValue);
    }
    
  
    function buyPower(address ref) public payable{
        require(initialized);

        uint256 powerBought=calculatePowerBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
        
        //trial vip to a new user
        if(users[msg.sender].miners == 0) {
            users[msg.sender].vipBuyTime = now;
            users[msg.sender].vipBoughtDays = TRIAL_VIP;
        }
        
        users[msg.sender].userBnbDeposit = users[msg.sender].userBnbDeposit.add(msg.value);
        users[msg.sender].initialBnbDeposit = users[msg.sender].initialBnbDeposit.add(msg.value);
        users[msg.sender].claimedPower=SafeMath.add(users[msg.sender].claimedPower,powerBought);
        
        totalStaked = totalStaked.add(msg.value);
        totalDeposits = totalDeposits.add(1);
        
        upgradePower(ref, false);
    }
    
     function _buyPoints(address userAddress, uint256 amount) private { // amount - Power for purchase
    
        require(amount != 0, "zero purchase amount");
        
        uint256 points = amount.mul(1e18).div(POWER_PER_POINT);
        
        if(pointsOwners[lotteryRound][userAddress] == 0) {
            participantAdresses[lotteryRound][participants] = userAddress;
            participants = participants.add(1);
        }
        
        pointsOwners[lotteryRound][userAddress] = pointsOwners[lotteryRound][userAddress].add(points);
        currentPot = currentPot.add(amount);
        totalPoints = totalPoints.add(points);
        
        if(block.timestamp.sub(LOTTERY_START_TIME) >= LOTTERY_STEP || participants == 200){
            _chooseWinner();
        }
    }
    
    function _chooseWinner() private {
        
       uint256[] memory init_range = new uint256[](participants);
       uint256[] memory end_range = new uint256[](participants);
       
       uint256 last_range = 0;
       
       for(uint256 i = 0; i < participants; i++){
           uint256 range0 = last_range.add(1);
           uint256 range1 = range0.add(pointsOwners[lotteryRound][participantAdresses[lotteryRound][i]].div(1e18)); 
           
           init_range[i] = range0;
           end_range[i] = range1;
           
           last_range = range1;
       }
        
       uint256 random = _getRandom().mod(last_range).add(1); 
       
       for(uint256 i = 0; i < participants; i++){
           if((random >= init_range[i]) && (random <= end_range[i])){
               // winner found
               
               address winnerAddress = participantAdresses[lotteryRound][i];
               
               users[winnerAddress].claimedPower = users[winnerAddress].claimedPower.add(currentPot.mul(9).div(10));
               
               //fees
               
               uint256 powerValue = calculatePowerSell(currentPot);
    		   
    		   uint256 walletFee = powerValue.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
               wallet.transfer(walletFee);
               uint256 devFee = powerValue.mul(DEVELOPER_FEE).div(PERCENTS_DIVIDER);
               devAddress.transfer(devFee);
               uint256 marketingFee = powerValue.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
               marketing.transfer(marketingFee);
              
               // reset lotteryRound
               
               emit onLotteryWinner(winnerAddress, currentPot, lotteryRound);
               
               currentPot = 0;
               lotteryRound = lotteryRound.add(1);
               participants = 0;
               totalPoints = 0;
               LOTTERY_START_TIME = block.timestamp;
               
              

               break;
           }
       }
    }
    
    function _getRandom() private view returns(uint256){
        
        bytes32 _blockhash = blockhash(block.number-1);
        
        
        return uint256(keccak256(abi.encode(_blockhash,block.timestamp,currentPot,block.difficulty,marketPower, address(this).balance)));
    }
    
    function getDailyCompoundBonus(address _adr, uint256 amount) public view returns(uint256){
        if(users[_adr].dailyCompoundBonus == 0) {
            return 0;
        } else {
            uint256 totalBonus = users[_adr].dailyCompoundBonus.mul(DAILY_COMPOUND_BONUS_STEP); // How many % 
            uint256 result = amount.mul(totalBonus).div(PERCENTS_DIVIDER);
            
            return result;
        }
    }

    
    
    function buyVIP(uint256 day) public payable {
        
        require(day >= 1, "min. purchase is 1 day");
        require(users[msg.sender].miners > 0, "user doesnt have active deposit");
        require(users[msg.sender].userBnbDeposit >= 1.5 ether, "user deposit less 1.5 bnb");
        
        _checkVIP(msg.sender);
        
        User storage user = users[msg.sender];
        
        
        uint256 userFinalPrice = getFinalVipPrice(day,msg.sender);
        
        require(msg.value >= userFinalPrice, "insufficient amount for VIP purchase");
        
        
        
        // if user doesnt have VIP
        if(user.vipBoughtDays == 0) {
            user.vipBuyTime = now;
            user.vipBoughtDays = day.mul(1 days); // days amount * unix time in 1 day  
        } else {
            //if user already has VIP
            user.vipBoughtDays = user.vipBoughtDays.add(day.mul(1 days));
        }
        
        uint256 walletFee = msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
        wallet.transfer(walletFee);
        uint256 devFee = msg.value.mul(DEVELOPER_FEE).div(PERCENTS_DIVIDER);
        devAddress.transfer(devFee);
        uint256 marketingFee = msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
        marketing.transfer(marketingFee);
        
        
    }
    
    
     function getUserPoints(address _userAddress) public view returns(uint256) {
         
         return pointsOwners[lotteryRound][_userAddress];
    }
    
    function getLotteryTimer() public view returns(uint256) {
        return LOTTERY_START_TIME.add(LOTTERY_STEP);
    }
    
    function getVipRemainingTime(address adr) public view returns(uint256){
        if(users[adr].vipBoughtDays != 0) {
            
            uint256 time = users[adr].vipBuyTime.add(users[adr].vipBoughtDays);
            
            if(time > now ) {
                
                return time.sub(now);
                
            } else {
                
                return 0;
            }
            
        } else {
            return 0;
        }
    }
    
    function getAvailableEarnings(address _adr) public view returns(uint256) {
        uint256 userPower = SafeMath.add(users[_adr].claimedPower,getPowerSinceLastUpgrade(_adr));
        
        return calculatePowerSell(userPower);
    }
    
    function getFinalVipPrice(uint256 day, address adr) public view returns(uint256) {
        
        User storage user = users[adr];
        
        uint256 dailyPrice = user.userBnbDeposit.mul(VIP_PRICE_DAY).div(PERCENTS_DIVIDER);
        uint256 h = 1000;
        
        if(day < 7){
            return dailyPrice.mul(day);
        }
        if(day>=7 && day < 30) {
            return dailyPrice.mul(day).mul(h.sub(VIP_DISCOUNT_7DAYS)).div(PERCENTS_DIVIDER); // ( 1000 - 70 ) / 1000 = 93%
        }
        if(day>=30){
            return dailyPrice.mul(day).mul(h.sub(VIP_DISCOUNT_30DAYS)).div(PERCENTS_DIVIDER); // ( 1000 - 170 ) / 1000 = 83%
        }
    }
    
    
    
    
    //magic trade balancing algorithm
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    function calculatePowerSell(uint256 powers) public view returns(uint256){
        return calculateTrade(powers,marketPower,address(this).balance);
    }
    function calculatePowerBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth,contractBalance,marketPower);
    }
    function calculatePowerBuySimple(uint256 eth) public view returns(uint256){
        return calculatePowerBuy(eth,address(this).balance);
    }

    function seedMarket() public payable{
        require(marketPower==0);
        require(msg.sender == devAddress);
        initialized=true;
        marketPower=259200000000;
        
        LOTTERY_START_TIME = now;
    }
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
    
    function _checkVIP(address adr) private  {
        User storage user = users[adr];
        
        if(now.sub(user.vipBuyTime) > user.vipBoughtDays) {
            user.vipBoughtDays = 0;
            user.vipBuyTime = 0;
        }
    }
    
    //How many power and bnb per day user will recieve for 0.01 BNB deposit
    function getPowerYield() public view returns(uint256,uint256) {
        uint256 powerAmount=calculatePowerBuy(0.01 ether ,SafeMath.sub(address(this).balance.add(0.01 ether),0.01 ether));
        uint256 miners=SafeMath.div(powerAmount,POWER_TO_HIRE_1MINERS);
        uint256 day = 1 days;
        
        uint256 powerPerDay = day.mul(miners);
        uint256 bnbPerDay = calculatePowerSellForYield(powerPerDay);
        
        return(miners,bnbPerDay);
    }
    
    function calculatePowerSellForYield(uint256 powers) public view returns(uint256){
        return calculateTrade(powers,marketPower,address(this).balance.add(0.01 ether));
    }
    function getMyMiners() public view returns(uint256){
        return users[msg.sender].miners;
    }
    function getMyPower() public view returns(uint256){
        return SafeMath.add(users[msg.sender].claimedPower,getPowerSinceLastUpgrade(msg.sender));
    }
    function getPowerSinceLastUpgrade(address adr) public view returns(uint256){
        uint256 secondsPassed=min(POWER_TO_HIRE_1MINERS,SafeMath.sub(now,users[adr].lastUpgrade));
        return SafeMath.mul(secondsPassed,users[adr].miners);
    }
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
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