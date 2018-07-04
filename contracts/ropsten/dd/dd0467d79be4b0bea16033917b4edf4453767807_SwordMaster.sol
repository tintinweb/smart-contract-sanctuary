pragma solidity ^0.4.18; // solhint-disable-line

contract SwordMaster{    
    uint256 public GOLD_TO_COLLECT_1SWORD=86400;
    uint256 public SECONDS_OF_DAY=86400;
    uint256 public STARTING_SWORD=300;
    uint256 public MIN_GOLD_TO_UPGRADE = 300;
    uint256 PSN=10000;
    uint256 PSNH=5000;
    bool public initialized=false;
    address public ceoAddress;
    mapping (address => uint256) public swordLevel;
    mapping (address => uint256) public claimedGolds;
    mapping (address => uint256) public lastCollect;
    mapping (address => address) public referrals;
    uint256 public marketGolds;
    function SwordMaster() public{
        ceoAddress=msg.sender;
    }
    function upgradeSword(address ref) public{
        require(initialized);
        if(referrals[msg.sender]==0 && msg.sender!=ref){
            referrals[msg.sender]=ref;
        }
        uint256 goldUsed=getMyGolds();
        uint256 newGold=SafeMath.div(goldUsed,GOLD_TO_COLLECT_1SWORD);
        uint256 remainGold = newGold % MIN_GOLD_TO_UPGRADE;
        newGold = SafeMath.sub(newGold,remainGold);
        if(newGold <=0){
            return;
        } // upgrade failed
        swordLevel[msg.sender]=SafeMath.add(swordLevel[msg.sender],newGold);
        claimedGolds[msg.sender]=SafeMath.mul(remainGold,GOLD_TO_COLLECT_1SWORD);
        lastCollect[msg.sender]=now;
        
        //send referral gold
        claimedGolds[referrals[msg.sender]]=SafeMath.add(claimedGolds[referrals[msg.sender]],SafeMath.div(newGold * GOLD_TO_COLLECT_1SWORD,5));
        
        //boost market to nerf sword hoarding
        marketGolds=SafeMath.add(marketGolds,SafeMath.div(newGold * GOLD_TO_COLLECT_1SWORD,10));
    }
    function sellGolds() public{
        require(initialized);
        uint256 hasGolds=getMyGolds();
        uint256 goldValue=calculateGoldSell(hasGolds);
        uint256 fee=devFee(goldValue);
        claimedGolds[msg.sender]=0;
        lastCollect[msg.sender]=now;
        marketGolds=SafeMath.add(marketGolds,hasGolds);
        ceoAddress.transfer(fee);
        msg.sender.transfer(SafeMath.sub(goldValue,fee));
    }
    function buyGolds() public payable{
        require(initialized);
        uint256 goldsBought=calculateGoldBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
        goldsBought=SafeMath.sub(goldsBought,devFee(goldsBought));
        ceoAddress.transfer(devFee(msg.value));
        claimedGolds[msg.sender]=SafeMath.add(claimedGolds[msg.sender],goldsBought);
    }
    //magic trade balancing algorithm
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    function calculateGoldSell(uint256 golds) public view returns(uint256){
        return calculateTrade(golds,marketGolds,address(this).balance);
    }
    function calculateGoldBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth,contractBalance,marketGolds);
    }
    function calculateGoldBuySimple(uint256 eth) public view returns(uint256){
        return calculateGoldBuy(eth,address(this).balance);
    }
    function devFee(uint256 amount) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,4),100);
    }
    function seedMarket(uint256 golds) public payable{
        require(marketGolds==0);
        initialized=true;
        marketGolds=golds;
    }
    function getFreeSword() public{
        require(initialized);
        require(swordLevel[msg.sender]==0);
        lastCollect[msg.sender]=now;
        swordLevel[msg.sender]=STARTING_SWORD;
    }
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
    function getMySword() public view returns(uint256){
        return swordLevel[msg.sender];
    }
    function getMyGolds() public view returns(uint256){
        return SafeMath.add(claimedGolds[msg.sender],getGoldsSinceLastCollect(msg.sender));
    }
    function getGoldsSinceLastCollect(address adr) public view returns(uint256){
        uint256 secondsPassed=min(SECONDS_OF_DAY,SafeMath.sub(now,lastCollect[adr]));
        return SafeMath.mul(secondsPassed,swordLevel[adr]);
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