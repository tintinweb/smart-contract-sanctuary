pragma solidity ^0.4.18; // solhint-disable-line

// PepeFarmer 2.0
// Anti-bot 50 Starting.
// Anti-whale 25% reduction in shrimp eggs when selling shrimp.
// Combat inflation as people Sell by not adding to total marketEggs.

// 50 Tokens, seeded market of 8640000000 Eggs
contract ShrimpFarmer{
    //uint256 EGGS_PER_SHRIMP_PER_SECOND=1;
    uint256 public EGGS_TO_HATCH_1SHRIMP=86400;//for final version should be seconds in a day
    uint256 public STARTING_SHRIMP=50;
    uint256 PSN=10000;
    uint256 PSNH=5000;
    bool public initialized=false;
    address public ceoAddress;
    uint256 public ceoDevfund;
    mapping (address => uint256) public hatcheryShrimp;
    mapping (address => uint256) public claimedEggs;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    uint256 public marketEggs;
    function ShrimpFarmer() public{
        ceoAddress=msg.sender;
    }
    /**
     * Sends accumulated devFee to ceoAddress
     * Doing it this way will save on transaction fees for users
     */
    function payCeo() payable public {
      require(msg.sender == ceoAddress);
      require(ceoDevfund > 0);
      ceoAddress.transfer(ceoDevfund);
      ceoDevfund = 0;
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
        marketEggs=SafeMath.add(marketEggs,eggsUsed);
    }
    function sellEggs() public{
        require(initialized);
        uint256 hasEggs=getMyEggs();
        uint256 eggValue=calculateEggSell(hasEggs);
        uint256 fee=devFee(eggValue);
        hatcheryShrimp[msg.sender]=SafeMath.mul(SafeMath.div(hatcheryShrimp[msg.sender],4),3);
        claimedEggs[msg.sender]=0;
        lastHatch[msg.sender]=now;
        // Instead of adding marketEggs let&#39;s not adding marketEggs
        // marketEggs=SafeMath.add(marketEggs,hasEggs);
        // To save on fees put devFee in a pot to be removed by ceo instead of per transaction
        // Old function: ceoAddress.transfer(fee);
        ceoDevfund += fee;
        msg.sender.transfer(SafeMath.sub(eggValue,fee));
    }
    function buyEggs() public payable{
        require(initialized);
        uint256 eggsBought=calculateEggBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
        eggsBought=SafeMath.sub(eggsBought,devFee(eggsBought));
        // To save on fees put devFee in a pot to be removed by ceo instead of per transaction
        // Old function: ceoAddress.transfer(devFee(msg.value));
        ceoDevfund += devFee(msg.value);
        claimedEggs[msg.sender]=SafeMath.add(claimedEggs[msg.sender],eggsBought);
    }
    //magic trade balancing algorithm
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    function calculateEggSell(uint256 eggs) public view returns(uint256){
        return calculateTrade(eggs,marketEggs,address(this).balance);
    }
    function calculateEggBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth,contractBalance,marketEggs);
    }
    function calculateEggBuySimple(uint256 eth) public view returns(uint256){
        return calculateEggBuy(eth,address(this).balance);
    }
    function devFee(uint256 amount) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,4),100);
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
        return address(this).balance;
    }
    function getMyShrimp() public view returns(uint256){
        return hatcheryShrimp[msg.sender];
    }
    function getMyEggs() public view returns(uint256){
        return SafeMath.add(claimedEggs[msg.sender],getEggsSinceLastHatch(msg.sender));
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