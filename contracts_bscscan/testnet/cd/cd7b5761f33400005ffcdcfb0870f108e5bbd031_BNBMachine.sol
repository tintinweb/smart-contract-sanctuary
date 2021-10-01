/**
 *Submitted for verification at BscScan.com on 2021-09-30
*/

/**
 *Website: https://bnbmachine.finance
*/

pragma solidity ^0.4.26; // solhint-disable-line

contract BNBMachine {
    //uint256 GOLD_PER_MACHINE_PER_SECOND = 1;
    uint256 public GOLD_TO_GENERATE_1_MACHINE = 2592000;//for final version should be seconds in a day
    uint256 PSN = 10000;
    uint256 PSNH = 5000;
    bool public initialized = false;
    address public Community;
    address public Marketing;
    mapping (address => uint256) public boostedMachines;
    mapping (address => uint256) public claimedGold;
    mapping (address => uint256) public lastBoost;
    mapping (address => address) public referrals;
    uint256 public marketGold;

    constructor() public {
        Community = msg.sender;
        Marketing = address(0x100f1044ee6B49491C277ce9FA3580dAD0d29a87);
    }

    function boostMachines(address ref) public {
        require(initialized);
        if (ref == msg.sender) {
            ref = 0;
        }
        if (referrals[msg.sender] == 0 && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }
        uint256 goldUsed = getMyGold();
        uint256 newMachines = SafeMath.div(goldUsed,GOLD_TO_GENERATE_1_MACHINE);
        boostedMachines[msg.sender] = SafeMath.add(boostedMachines[msg.sender],newMachines);
        claimedGold[msg.sender] = 0;
        lastBoost[msg.sender] = now;
        
        //send referral gold
        claimedGold[referrals[msg.sender]] = SafeMath.add(claimedGold[referrals[msg.sender]],SafeMath.div(goldUsed,10));
        
        //boost market to nerf machines hoarding
        marketGold = SafeMath.add(marketGold,SafeMath.div(goldUsed,5));
    }

    function sellGold() public {
        require(initialized);
        uint256 hasGold = getMyGold();
        uint256 goldValue = calculateGoldSell(hasGold);
        uint256 fee = devFee(goldValue);
        uint256 fee2 = fee / 2;
        claimedGold[msg.sender] = 0;
        lastBoost[msg.sender] = now;
        marketGold = SafeMath.add(marketGold,hasGold);
        Community.transfer(fee2);
        Marketing.transfer(fee-fee2);
        msg.sender.transfer(SafeMath.sub(goldValue,fee));
    }

    function buyMachines(address ref) public payable {
        require(initialized);
        uint256 machinesBought = calculateMachineBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
        machinesBought = SafeMath.sub(machinesBought,devFee(machinesBought));
        uint256 fee = devFee(msg.value);
        uint256 fee2 = fee / 2;
        Community.transfer(fee2);
        Marketing.transfer(fee-fee2);
        claimedGold[msg.sender] = SafeMath.add(claimedGold[msg.sender],machinesBought);
        boostMachines(ref);
    }

    //magic trade balancing algorithm
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256) {
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }

    function calculateGoldSell(uint256 gold) public view returns(uint256) {
        return calculateTrade(gold,marketGold,address(this).balance);
    }

    function calculateMachineBuy(uint256 eth,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth,contractBalance,marketGold);
    }

    function calculateMachineBuySimple(uint256 eth) public view returns(uint256) {
        return calculateMachineBuy(eth,address(this).balance);
    }

    function devFee(uint256 amount) public pure returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount,5),100);
    }

    function seedMarket() public payable {
        require(marketGold == 0);
        initialized = true;
        marketGold = 259200000000;
    }

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function getMyMachines() public view returns(uint256) {
        return boostedMachines[msg.sender];
    }

    function getMyGold() public view returns(uint256) {
        return SafeMath.add(claimedGold[msg.sender],getGoldSinceLastBoost(msg.sender));
    }

    function getGoldSinceLastBoost(address adr) public view returns(uint256) {
        uint256 secondsPassed = min(GOLD_TO_GENERATE_1_MACHINE,SafeMath.sub(now,lastBoost[adr]));
        return SafeMath.mul(secondsPassed,boostedMachines[adr]);
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
}