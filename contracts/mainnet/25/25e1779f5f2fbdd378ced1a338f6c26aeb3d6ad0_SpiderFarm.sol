// similar to shrimp/snail
// you lose one third of your spiders on sell                                                                                  anti-inflation + longevity
// freebies on a set price of 0.001 and only 50                                                                                anti-bot
// every three days the global eggs are reduced by 20%                                                                         anti-inflation
// you are able to compete for the spider queen which gives you 3% of the fees and the fixed 0.001 of the freebies             competition + longevity
// if you buy the title you lose a set amound of eggs, first title costs 100000 eggs, adding 100k each time                    anti-inflation + competition + longevity
// lower seed of 864000000 instead of 8640000000 to make the early game slower, more fair and stop hyperinflation              anti-inflation + competition + longevity
// lower referral (10%) to fight ref abuse as seen on shrimp                                                                   anti-inflation + anti-bot

contract SpiderFarm{
    //uint256 EGGS_PER_SHRIMP_PER_SECOND=1;
    uint256 public EGGS_TO_HATCH_1SHRIMP=86400;//for final version should be seconds in a day
    uint256 public STARTING_SHRIMP=50;
    uint256 PSN=10000;
    uint256 PSNH=5000;
    uint256 startTime;
    bool public initialized=false;
    address public ceoAddress;
    address public owner;
    mapping (address => uint256) public hatcheryShrimp;
    mapping (address => uint256) public claimedEggs;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    uint256 public marketEggs;
    uint256 public snailmasterReq=100000;
   
    function becomeSnailmaster() public{
        uint256 hasEggs=getMyEggs();
        uint256 eggCount=SafeMath.div(hasEggs,EGGS_TO_HATCH_1SHRIMP);
        require(initialized);
        require(msg.sender != ceoAddress);
        require(eggCount>=snailmasterReq);
        claimedEggs[msg.sender]=0;
        snailmasterReq=SafeMath.add(snailmasterReq,100000);//+100k shrimps each time
        ceoAddress=msg.sender;
    }
    function hatchEggs(address ref) public{
        require(initialized);
        if(referrals[msg.sender]==0 && referrals[msg.sender]!=msg.sender){
            referrals[msg.sender]=ref;
        }
        uint256 eggsUsed=getMyEggs();
        uint256 newShrimp=SafeMath.div(eggsUsed,EGGS_TO_HATCH_1SHRIMP);
        uint256 timer=tmp();
        hatcheryShrimp[msg.sender]=SafeMath.add(hatcheryShrimp[msg.sender],newShrimp);
        claimedEggs[msg.sender]=0;
        lastHatch[msg.sender]=now;
        if (timer>=1) {
        marketEggs=SafeMath.mul(SafeMath.div(marketEggs,5),4);
        startTime=now;
        }
        
        //send referral eggs
        claimedEggs[referrals[msg.sender]]=SafeMath.add(claimedEggs[referrals[msg.sender]],SafeMath.div(eggsUsed,10));
        
        //boost market to nerf hoarding
        marketEggs=SafeMath.add(marketEggs,SafeMath.div(eggsUsed,10));
        
    }
    function sellEggs() public{
        require(initialized);
        uint256 hasEggs=getMyEggs();
        uint256 eggValue=calculateEggSell(hasEggs);
        uint256 fee=devFee(eggValue);
        uint256 fee2=devFee2(eggValue);
        uint256 overallfee=SafeMath.add(fee,fee2);
        // one third of investors die on dump
        hatcheryShrimp[msg.sender]=SafeMath.mul(SafeMath.div(hatcheryShrimp[msg.sender],3),2);
        claimedEggs[msg.sender]=0;
        lastHatch[msg.sender]=now;
        marketEggs=SafeMath.add(marketEggs,hasEggs);
        ceoAddress.transfer(fee);
        owner.transfer(fee2);
        msg.sender.transfer(SafeMath.sub(eggValue,overallfee));
    }
    function buyEggs() public payable{
        require(initialized);
        uint256 fee=devFee(eggsBought);
        uint256 fee2=devFee2(eggsBought);
        uint256 overallfee=SafeMath.add(fee,fee2);
        uint256 eggsBought=calculateEggBuy(msg.value,SafeMath.sub(this.balance,msg.value));
        eggsBought=SafeMath.sub(eggsBought,overallfee);
        ceoAddress.transfer(devFee(msg.value));
        owner.transfer(devFee2(msg.value));
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
        return SafeMath.div(SafeMath.mul(amount,2),100);
    }
    function devFee2(uint256 amount) public view returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,3),100);
    }
    function seedMarket(uint256 eggs) public payable{
        require(marketEggs==0);
        initialized=true;
        marketEggs=eggs;
    }
    function getFreeShrimp() public payable{
        require(initialized);
        require(msg.value==0.001 ether);
        ceoAddress.transfer(msg.value); //goes to spider queen
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
    function getSnailmasterReq() public view returns(uint256){
        return snailmasterReq;
    }
    function getMyEggs() public view returns(uint256){
        return SafeMath.add(claimedEggs[msg.sender],getEggsSinceLastHatch(msg.sender));
    }
    function updateEggs() public view returns(uint256){
        return SafeMath.sub(claimedEggs[msg.sender],snailmasterReq);
    }
    function SpiderFarm() public{
        ceoAddress=msg.sender;
        owner=0xa76490c1f5fbf4d5101430c3cd2E63f33D21C738;
    }
    function getEggsSinceLastHatch(address adr) public view returns(uint256){
        uint256 secondsPassed=min(EGGS_TO_HATCH_1SHRIMP,SafeMath.sub(now,lastHatch[adr]));
        return SafeMath.mul(secondsPassed,hatcheryShrimp[adr]);
    }
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
    function tmp() public returns(uint){
         require(startTime != 0);
         return (now - startTime)/(4320 minutes);
    }
    function callThisToStart() public {
        if(owner != msg.sender) throw;
        startTime = now;
        
    }
    function callThisToStop() public {
        if(owner != msg.sender) throw;
        startTime = 0;
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