pragma solidity ^0.4.20; // solhint-disable-line

// similar as bankerfarmer, with three changes:
// A. one third of your bankers die when you sell eggs
// B. you can transfer ownership of the devfee through sacrificing bankers
// C. the "free" 300 bankers cost 0.001 eth (in line with the mining fee)

// bots should have a harder time, and whales can compete for the devfee

contract BankerFarmer{
    //uint256 EGGS_PER_BANKER_PER_SECOND=1;
    uint256 public EGGS_TO_HATCH_1BANKER=86400;//for final version should be seconds in a day
    uint256 public STARTING_BANKER=300;
    uint256 PSN=10000;
    uint256 PSNH=5000;
    bool public initialized=false;
    address public ceoAddress;
    mapping (address => uint256) public hatcheryBanker;
    mapping (address => uint256) public claimedEggs;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    uint256 public marketEggs;
    uint256 public bankermasterReq=100000;
    function BankerFarmer() public{
        ceoAddress=msg.sender;
    }
    function becomeBankermaster() public{
        require(initialized);
        require(hatcheryBanker[msg.sender]>=bankermasterReq);
        hatcheryBanker[msg.sender]=SafeMath.sub(hatcheryBanker[msg.sender],bankermasterReq);
        bankermasterReq=SafeMath.add(bankermasterReq,100000);//+100k bankers each time
        ceoAddress=msg.sender;
    }
    function hatchEggs(address ref) public{
        require(initialized);
        if(referrals[msg.sender]==0 && referrals[msg.sender]!=msg.sender){
            referrals[msg.sender]=ref;
        }
        uint256 eggsUsed=getMyEggs();
        uint256 newBanker=SafeMath.div(eggsUsed,EGGS_TO_HATCH_1BANKER);
        hatcheryBanker[msg.sender]=SafeMath.add(hatcheryBanker[msg.sender],newBanker);
        claimedEggs[msg.sender]=0;
        lastHatch[msg.sender]=now;
        
        //send referral eggs
        claimedEggs[referrals[msg.sender]]=SafeMath.add(claimedEggs[referrals[msg.sender]],SafeMath.div(eggsUsed,5));
        
        //boost market to nerf banker hoarding
        marketEggs=SafeMath.add(marketEggs,SafeMath.div(eggsUsed,10));
    }
    function sellEggs() public{
        require(initialized);
        uint256 hasEggs=getMyEggs();
        uint256 eggValue=calculateEggSell(hasEggs);
        uint256 fee=devFee(eggValue);
        // kill one third of the owner&#39;s bankers on egg sale
        hatcheryBanker[msg.sender]=SafeMath.mul(SafeMath.div(hatcheryBanker[msg.sender],3),2);
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
    function getFreeBanker() public payable{
        require(initialized);
        require(msg.value==0.001 ether); //similar to mining fee, prevents bots
        ceoAddress.transfer(msg.value); //bankermaster gets this entrance fee
        require(hatcheryBanker[msg.sender]==0);
        lastHatch[msg.sender]=now;
        hatcheryBanker[msg.sender]=STARTING_BANKER;
    }
    function getBalance() public view returns(uint256){
        return this.balance;
    }
    function getMyBanker() public view returns(uint256){
        return hatcheryBanker[msg.sender];
    }
    function getBankermasterReq() public view returns(uint256){
        return bankermasterReq;
    }
    function getMyEggs() public view returns(uint256){
        return SafeMath.add(claimedEggs[msg.sender],getEggsSinceLastHatch(msg.sender));
    }
    function getEggsSinceLastHatch(address adr) public view returns(uint256){
        uint256 secondsPassed=min(EGGS_TO_HATCH_1BANKER,SafeMath.sub(now,lastHatch[adr]));
        return SafeMath.mul(secondsPassed,hatcheryBanker[adr]);
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