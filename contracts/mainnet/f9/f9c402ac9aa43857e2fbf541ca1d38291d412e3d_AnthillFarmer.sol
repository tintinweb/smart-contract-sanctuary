pragma solidity ^0.4.18; // solhint-disable-line



contract AnthillFarmer{
    //uint256 ANTS_PER_ANTHILL_PER_SECOND=1;
    uint256 public ANTS_TO_COLLECT_1ANTHILL=86400;//for final version should be seconds in a day
    uint256 public STARTING_ANTHILL=300;
    uint256 PSN=10000;
    uint256 PSNH=5000;
    bool public initialized=false;
    address public ceoAddress;
    mapping (address => uint256) public Anthills;
    mapping (address => uint256) public claimedAnts;
    mapping (address => uint256) public lastCollect;
    mapping (address => address) public referrals;
    uint256 public marketAnts;
    function AnthillFarmer() public{
        ceoAddress=msg.sender;
    }
    function collectAnts(address ref) public{
        require(initialized);
        if(referrals[msg.sender]==0 && referrals[msg.sender]!=msg.sender){
            referrals[msg.sender]=ref;
        }
        uint256 antsUsed=getMyAnts();
        uint256 newAnthill=SafeMath.div(antsUsed,ANTS_TO_COLLECT_1ANTHILL);
        Anthills[msg.sender]=SafeMath.add(Anthills[msg.sender],newAnthill);
        claimedAnts[msg.sender]=0;
        lastCollect[msg.sender]=now;
        
        //send referral ants
        claimedAnts[referrals[msg.sender]]=SafeMath.add(claimedAnts[referrals[msg.sender]],SafeMath.div(antsUsed,5));
        
        //boost market to nerf anthill hoarding
        marketAnts=SafeMath.add(marketAnts,SafeMath.div(antsUsed,10));
    }
    function sellAnts() public{
        require(initialized);
        uint256 hasAnts=getMyAnts();
        uint256 antValue=calculateAntSell(hasAnts);
        uint256 fee=devFee(antValue);
        claimedAnts[msg.sender]=0;
        lastCollect[msg.sender]=now;
        marketAnts=SafeMath.add(marketAnts,hasAnts);
        ceoAddress.transfer(fee);
        msg.sender.transfer(SafeMath.sub(antValue,fee));
    }
    function buyAnts() public payable{
        require(initialized);
        uint256 antsBought=calculateAntBuy(msg.value,SafeMath.sub(this.balance,msg.value));
        antsBought=SafeMath.sub(antsBought,devFee(antsBought));
        ceoAddress.transfer(devFee(msg.value));
        claimedAnts[msg.sender]=SafeMath.add(claimedAnts[msg.sender],antsBought);
    }
    //magic trade balancing algorithm
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    function calculateAntSell(uint256 ants) public view returns(uint256){
        return calculateTrade(ants,marketAnts,this.balance);
    }
    function calculateAntBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth,contractBalance,marketAnts);
    }
    function calculateAntBuySimple(uint256 eth) public view returns(uint256){
        return calculateAntBuy(eth,this.balance);
    }
    function devFee(uint256 amount) public view returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,4),100);
    }
    function seedMarket(uint256 ants) public payable{
        require(marketAnts==0);
        initialized=true;
        marketAnts=ants;
    }
    function getFreeAnthill() public{
        require(initialized);
        require(Anthills[msg.sender]==0);
        lastCollect[msg.sender]=now;
        Anthills[msg.sender]=STARTING_ANTHILL;
    }
    function getBalance() public view returns(uint256){
        return this.balance;
    }
    function getMyAnthill() public view returns(uint256){
        return Anthills[msg.sender];
    }
    function getMyAnts() public view returns(uint256){
        return SafeMath.add(claimedAnts[msg.sender],getAntsSinceLastCollect(msg.sender));
    }
    function getAntsSinceLastCollect(address adr) public view returns(uint256){
        uint256 secondsPassed=min(ANTS_TO_COLLECT_1ANTHILL,SafeMath.sub(now,lastCollect[adr]));
        return SafeMath.mul(secondsPassed,Anthills[adr]);
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