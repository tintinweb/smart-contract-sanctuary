pragma solidity ^0.4.20; // solhint-disable-line

// similar as squirrelfarmer, with three changes:
// A. one third of your squirrels die when you sell eggs
// B. you can transfer ownership of the devfee through sacrificing squirrels
// C. the "free" 300 squirrels cost 0.001 eth (in line with the mining fee)

// bots should have a harder time, and whales can compete for the devfee

contract SquirrelFarmer{
    //uint256 EGGS_PER_SQUIRREL_PER_SECOND=1;
    uint256 public EGGS_TO_HATCH_1SQUIRREL=86400;//for final version should be seconds in a day
    uint256 public STARTING_SQUIRREL=300;
    uint256 PSN=10000;
    uint256 PSNH=5000;
    bool public initialized=false;
    address public ceoAddress;
    mapping (address => uint256) public hatcherySquirrel;
    mapping (address => uint256) public claimedEggs;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    uint256 public marketEggs;
    uint256 public squirrelmasterReq=100000;
    function SquirrelFarmer() public{
        ceoAddress=msg.sender;
    }
    function becomeSquirrelmaster() public{
        require(initialized);
        require(hatcherySquirrel[msg.sender]>=squirrelmasterReq);
        hatcherySquirrel[msg.sender]=SafeMath.sub(hatcherySquirrel[msg.sender],squirrelmasterReq);
        squirrelmasterReq=SafeMath.add(squirrelmasterReq,100000);//+100k squirrels each time
        ceoAddress=msg.sender;
    }
    function hatchEggs(address ref) public{
        require(initialized);
        if(referrals[msg.sender]==0 && referrals[msg.sender]!=msg.sender){
            referrals[msg.sender]=ref;
        }
        uint256 eggsUsed=getMyEggs();
        uint256 newSquirrel=SafeMath.div(eggsUsed,EGGS_TO_HATCH_1SQUIRREL);
        hatcherySquirrel[msg.sender]=SafeMath.add(hatcherySquirrel[msg.sender],newSquirrel);
        claimedEggs[msg.sender]=0;
        lastHatch[msg.sender]=now;
        
        //send referral eggs
        claimedEggs[referrals[msg.sender]]=SafeMath.add(claimedEggs[referrals[msg.sender]],SafeMath.div(eggsUsed,5));
        
        //boost market to nerf squirrel hoarding
        marketEggs=SafeMath.add(marketEggs,SafeMath.div(eggsUsed,10));
    }
    function sellEggs() public{
        require(initialized);
        uint256 hasEggs=getMyEggs();
        uint256 eggValue=calculateEggSell(hasEggs);
        uint256 fee=devFee(eggValue);
        // kill one third of the owner&#39;s squirrels on egg sale
        hatcherySquirrel[msg.sender]=SafeMath.mul(SafeMath.div(hatcherySquirrel[msg.sender],3),2);
        claimedEggs[msg.sender]=0;
        lastHatch[msg.sender]=now;
        marketEggs=SafeMath.add(marketEggs,hasEggs);
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
        return SafeMath.div(SafeMath.mul(amount,4),100);
    }
    function seedMarket(uint256 eggs) public payable{
        require(marketEggs==0);
        initialized=true;
        marketEggs=eggs;
    }
    function getFreeSquirrel() public payable{
        require(initialized);
        require(msg.value==0.001 ether); //similar to mining fee, prevents bots
        ceoAddress.transfer(msg.value); //squirrelmaster gets this entrance fee
        require(hatcherySquirrel[msg.sender]==0);
        lastHatch[msg.sender]=now;
        hatcherySquirrel[msg.sender]=STARTING_SQUIRREL;
    }
    function getBalance() public view returns(uint256){
        return this.balance;
    }
    function getMySquirrel() public view returns(uint256){
        return hatcherySquirrel[msg.sender];
    }
    function getSquirrelmasterReq() public view returns(uint256){
        return squirrelmasterReq;
    }
    function getMyEggs() public view returns(uint256){
        return SafeMath.add(claimedEggs[msg.sender],getEggsSinceLastHatch(msg.sender));
    }
    function getEggsSinceLastHatch(address adr) public view returns(uint256){
        uint256 secondsPassed=min(EGGS_TO_HATCH_1SQUIRREL,SafeMath.sub(now,lastHatch[adr]));
        return SafeMath.mul(secondsPassed,hatcherySquirrel[adr]);
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