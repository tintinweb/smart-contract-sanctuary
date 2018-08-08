pragma solidity ^0.4.23;

/*


    (   )
  (   ) (
   ) _   )
    ( \_
  _(_\ \)__
 (____\___)) 
 
 
*/


// similar to ShrimpFarmer, with eight changes:
// 1. one third of your ShitClones die when you sell your time
// 2. the ownership of the devfee can transfer through sacrificing ShitClones
//  a. the new requirement will be how many remaining ShitClones you have after the sacrifice
//  b. you cannot sacrifice ShitClones if you are the ShitClonesLord
// 3. the "free" 500 ShitClones cost 0.001 eth (in line with the mining fee)
// bots should have a harder time, and whales can compete for the devfee
// 4. UI is for peasants, this is mew sniper territory. Step away to a safe distance.
// 5. I made some changes to the contract that might have fucked it, or not.
// https://bit.ly/2xc8v53
// 6. Join our discord @ https://discord.gg/RbgqjPd
// 7. Let&#39;s stop creating these and move on. M&#39;kay?
// 8. Drops the mic.

contract ShitCloneFarmer {

    uint256 public TIME_TO_MAKE_1_SHITCLONE = 86400;
    uint256 public STARTING_SHITCLONE = 100;
    uint256 PSN = 10000;
    uint256 PSNH = 5000;
    bool public initialized = true;
    address public ShitCloneslordAddress;
    uint256 public ShitCloneslordReq = 500000; // starts at 500k ShitClones
    mapping (address => uint256) public ballShitClone;
    mapping (address => uint256) public claimedTime;
    mapping (address => uint256) public lastEvent;
    mapping (address => address) public referrals;
    uint256 public marketTime;

    function ShitCloneFarmer() public {
        ShitCloneslordAddress = msg.sender;
    }

    function makeShitClone(address ref) public {
        require(initialized);

        if (referrals[msg.sender] == 0 && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }

        uint256 timeUsed = getMyTime();
        uint256 newShitClone = SafeMath.div(timeUsed, TIME_TO_MAKE_1_SHITCLONE);
        ballShitClone[msg.sender] = SafeMath.add(ballShitClone[msg.sender], newShitClone);
        claimedTime[msg.sender] = 0;
        lastEvent[msg.sender] = now;
        
        // send referral time
        claimedTime[referrals[msg.sender]] = SafeMath.add(claimedTime[referrals[msg.sender]], SafeMath.div(timeUsed, 5)); // +20%
        
        // boost market to prevent sprem hoarding
        marketTime = SafeMath.add(marketTime, SafeMath.div(timeUsed, 10)); // +10%
    }

    function sellShitClones() public {
        require(initialized);

        uint256 cellCount = getMyTime();
        uint256 cellValue = calculateCellSell(cellCount);
        uint256 fee = devFee(cellValue);
        
        // one third of your ShitClones die :&#39;(
        ballShitClone[msg.sender] = SafeMath.mul(SafeMath.div(ballShitClone[msg.sender], 3), 2); // =66%
        claimedTime[msg.sender] = 0;
        lastEvent[msg.sender] = now;

        // put them on the market
        marketTime = SafeMath.add(marketTime, cellCount);

        // ALL HAIL THE SHITCLONELORD!
        ShitCloneslordAddress.transfer(fee);
        msg.sender.transfer(SafeMath.sub(cellValue, fee));
    }

    function buyShitClones() public payable {
        require(initialized);

        uint256 timeBought = calculateCellBuy(msg.value, SafeMath.sub(this.balance, msg.value));
        timeBought = SafeMath.sub(timeBought, devFee(timeBought));
        claimedTime[msg.sender] = SafeMath.add(claimedTime[msg.sender], timeBought);

        // ALL HAIL THE SHITCLONELORD!
        ShitCloneslordAddress.transfer(devFee(msg.value));
    }

    // magic trade balancing algorithm
    function calculateTrade(uint256 rt, uint256 rs, uint256 bs) public view returns(uint256) {
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }

    function calculateCellSell(uint256 time) public view returns(uint256) {
        return calculateTrade(time, marketTime, this.balance);
    }

    function calculateCellBuy(uint256 eth, uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth, contractBalance, marketTime);
    }

    function calculateCellBuySimple(uint256 eth) public view returns(uint256) {
        return calculateCellBuy(eth, this.balance);
    }

    function devFee(uint256 amount) public view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount, 4), 100); // 4%
    }

    function seedMarket(uint256 time) public payable {
        require(marketTime == 0);
        require(ShitCloneslordAddress == msg.sender);
        marketTime = time;
    }

    function getFreeShitClone() public payable {
        require(initialized);
        require(msg.value == 0.001 ether); // similar to mining fee, prevents bots
        ShitCloneslordAddress.transfer(msg.value); // the ShitCloneslord gets the entry fee ;)

        require(ballShitClone[msg.sender] == 0);
        lastEvent[msg.sender] = now;
        ballShitClone[msg.sender] = STARTING_SHITCLONE;
    }

    function getBalance() public view returns(uint256) {
        return this.balance;
    }

    function getMyShitClone() public view returns(uint256) {
        return ballShitClone[msg.sender];
    }

    function becomeShitClonelord() public {
        require(initialized);
        require(msg.sender != ShitCloneslordAddress);
        require(ballShitClone[msg.sender] >= ShitCloneslordReq);

        ballShitClone[msg.sender] = SafeMath.sub(ballShitClone[msg.sender], ShitCloneslordReq);
        ShitCloneslordReq = ballShitClone[msg.sender]; // the requirement now becomes the balance at that time
        ShitCloneslordAddress = msg.sender;
    }

    function getShitClonelordReq() public view returns(uint256) {
        return ShitCloneslordReq;
    }

    function getMyTime() public view returns(uint256) {
        return SafeMath.add(claimedTime[msg.sender], getTimeSinceLastEvent(msg.sender));
    }

    function getTimeSinceLastEvent(address adr) public view returns(uint256) {
        uint256 secondsPassed = min(TIME_TO_MAKE_1_SHITCLONE, SafeMath.sub(now, lastEvent[adr]));
        return SafeMath.mul(secondsPassed, ballShitClone[adr]);
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
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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
}