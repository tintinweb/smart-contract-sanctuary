pragma solidity ^0.4.18; // solhint-disable-line



contract EtherCartel{
    //uint256 EGGS_TO_HATCH_1SHRIMP=1;
    uint256 public EGGS_TO_HATCH_1SHRIMP=86400;//for final version should be seconds in a day
    uint256 public STARTING_SHRIMP=300;
    uint256 PSN=10000;
    uint256 PSNH=5000;
    bool public initialized=false;
    address public ceoAddress;
    mapping (address => uint256) public hatcheryShrimp;
    mapping (address => uint256) public claimedEggs;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    uint256 public marketEggs;


    // Additions 
    mapping(address => bool) public hasDoubler;
    uint256 public CurrentIcePrice = 0.01 ether;
    uint256 public CurrentIceDelta = 0.001 ether;
    uint256 public CurrentGoldPrice = 0.2 ether;
    uint256 public CurrentGoldPercentIncrease = 200; // 200 = doubles in price 
    uint256 public CurrentDevFee = 7;
    address public GoldOwner;


    constructor() public{
        ceoAddress=msg.sender;
        GoldOwner=msg.sender;
    }

    function BuyDoubler() public payable{
        require(initialized);
        require(msg.value >= CurrentIcePrice);
        uint256 left;
        uint256 excess=0;
        if (msg.value > CurrentIcePrice){
            excess = msg.value - CurrentIcePrice;
            left = CurrentIcePrice;
        }
        else{
            left = msg.value;
        }


        // save current eggs into the wallet of user 
        uint256 eggs = getMyEggs();
        claimedEggs[msg.sender] = SafeMath.add(claimedEggs[msg.sender], eggs);
        // shrimp production all moved into claimed eggs 
        lastHatch[msg.sender] = now;
        hasDoubler[msg.sender] = true;
        CurrentIcePrice = CurrentIcePrice + CurrentIceDelta;
        ceoAddress.transfer(devFee(left));
        if (excess > 0){
            msg.sender.transfer(excess);
        }
    }

    function BuyGold() public payable{
        require(initialized);
        require(msg.value >= CurrentGoldPrice);
        require(msg.sender != GoldOwner);
        uint256 left;
        uint256 excess=0;
        if (msg.value > CurrentGoldPrice){
            excess = msg.value - CurrentGoldPrice;
            left = CurrentGoldPrice;
        }
        else{
            left = msg.value;
        }

        left = SafeMath.sub(left, devFee(left));

        uint256 eggs = getMyEggs();
        claimedEggs[msg.sender] = SafeMath.add(claimedEggs[msg.sender], eggs);
        // shrimp production all moved into claimed eggs 
        lastHatch[msg.sender] = now;

        eggs = getEggsOff(GoldOwner);
        claimedEggs[GoldOwner] = SafeMath.add(claimedEggs[GoldOwner], eggs);
        // shrimp production all moved into claimed eggs 
        lastHatch[GoldOwner] = now;


        CurrentGoldPrice = SafeMath.div(SafeMath.mul(CurrentGoldPrice,CurrentGoldPercentIncrease),100);
        address oldOwner = GoldOwner;
        GoldOwner = msg.sender;

        oldOwner.transfer(left);
        if (excess > 0){
            msg.sender.transfer(excess);
        }
    }


    function hatchEggs(address ref) public{
        require(initialized);
        if(referrals[msg.sender]==0 && referrals[msg.sender]!=msg.sender){
            referrals[msg.sender]=ref;
        }
        uint256 eggsUsed=getMyEggs();
        uint256 newShrimp=SafeMath.div(eggsUsed,EGGS_TO_HATCH_1SHRIMP);
        hatcheryShrimp[msg.sender]=SafeMath.add(hatcheryShrimp[msg.sender],newShrimp);
        claimedEggs[msg.sender]=0;
        lastHatch[msg.sender]=now;
        
        //send referral eggs
        claimedEggs[referrals[msg.sender]]=SafeMath.add(claimedEggs[referrals[msg.sender]],SafeMath.div(eggsUsed,5));
        
        //boost market to nerf shrimp hoarding
        marketEggs=SafeMath.add(marketEggs,SafeMath.div(eggsUsed,10));
    }
    function sellEggs() public{
        require(initialized);
        uint256 hasEggs=getMyEggs();
        uint256 eggValue=calculateEggSell(hasEggs);
        uint256 fee=devFee(eggValue);
        claimedEggs[msg.sender]=0;
        lastHatch[msg.sender]=now;
        marketEggs=SafeMath.add(marketEggs,hasEggs);
        hatcheryShrimp[msg.sender]=SafeMath.div(SafeMath.mul(hatcheryShrimp[msg.sender],3),4);
        ceoAddress.transfer(fee);
        msg.sender.transfer(SafeMath.sub(eggValue,fee));
    }
    function buyEggs() public payable{
        require(initialized);
        uint256 eggsBought=calculateEggBuy(msg.value,SafeMath.sub(this.balance,msg.value));
        eggsBought=SafeMath.sub(eggsBought,devFee(eggsBought));
        ceoAddress.transfer(devFee(msg.value));
        claimedEggs[msg.sender]=SafeMath.add(claimedEggs[msg.sender],eggsBought);
    }
    //magic trade balancing algorithm
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    function calculateEggSell(uint256 eggs) public view returns(uint256){
        return calculateTrade(eggs,marketEggs,this.balance);
    }
    function calculateEggBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth,contractBalance,marketEggs);
    }
    function calculateEggBuySimple(uint256 eth) public view returns(uint256){
        return calculateEggBuy(eth,this.balance);
    }
    function devFee(uint256 amount) public view returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,CurrentDevFee),100);
    }
    function seedMarket(uint256 eggs) public payable{
        require(marketEggs==0);
        initialized=true;
        marketEggs=eggs;
    }
    function getFreeShrimp() public{
        require(initialized);
        require(hatcheryShrimp[msg.sender]==0);
        lastHatch[msg.sender]=now;
        hatcheryShrimp[msg.sender]=STARTING_SHRIMP;
    }
    function getBalance() public view returns(uint256){
        return this.balance;
    }
    function getMyShrimp() public view returns(uint256){
        return hatcheryShrimp[msg.sender];
    }

    function getEggsOff(address adr) public view returns (uint256){
        uint256 ret = SafeMath.add(claimedEggs[adr],getEggsSinceLastHatch(adr));
        if (hasDoubler[adr]){
            ret = SafeMath.mul(ret,2);
        }
        if (adr == GoldOwner){
            ret = SafeMath.mul(ret,4);
        }
        return ret;
    
    }


    function getMyEggs() public view returns(uint256){
        uint256 ret = SafeMath.add(claimedEggs[msg.sender],getEggsSinceLastHatch(msg.sender));
        if (hasDoubler[msg.sender]){
            ret = SafeMath.mul(ret,2);
        }
        if (msg.sender == GoldOwner){
            ret = SafeMath.mul(ret,4);
        }
        return ret;
    }
    function getEggsSinceLastHatch(address adr) public view returns(uint256){
        uint256 secondsPassed=min(EGGS_TO_HATCH_1SHRIMP,SafeMath.sub(now,lastHatch[adr]));
        return SafeMath.mul(secondsPassed,hatcheryShrimp[adr]);
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