pragma solidity ^0.4.18; // solhint-disable-line
/**
*
Starting at 50 free lobsters modifiable by ceoAddress
* 
Eggs hatching in 1 day
*
devFee 2%
*
**/
contract LobsterFarm{
    uint256 public EGGS_TO_HATCH_1LOBSTER=86400;
    uint256 public STARTING_LOBSTER=50;
    uint256 PSN=10000;
    uint256 PSNH=5000;
    bool public initialized=false;
    address public ceoAddress;
    mapping (address => uint256) public hatcheryLobster;
    mapping (address => uint256) public claimedEggs;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    uint256 public marketEggs;
    
    function LobsterFarm() public{
        ceoAddress=msg.sender;
    }
    
    event onHatchEggs(
        address indexed customerAddress,
        uint256 Lobsters,
        address indexed referredBy                
    );
    
    event onSellEggs(
        address indexed customerAddress,
        uint256 eggs,
        uint256 ethereumEarned   
    );

    event onBuyEggs(
        address indexed customerAddress,
        uint256 eggs,
        uint256 incomingEthereum
    );
    
    function hatchEggs(address ref) public{
        require(initialized);
        if(referrals[msg.sender]==0 && referrals[msg.sender]!=msg.sender){
            referrals[msg.sender]=ref;
        }
        uint256 eggsUsed=getMyEggs();
        uint256 newLobster=SafeMath.div(eggsUsed,EGGS_TO_HATCH_1LOBSTER);
        hatcheryLobster[msg.sender]=SafeMath.add(hatcheryLobster[msg.sender],newLobster);
        claimedEggs[msg.sender]=0;
        lastHatch[msg.sender]=now;
        //send referral eggs
        claimedEggs[referrals[msg.sender]]=SafeMath.add(claimedEggs[referrals[msg.sender]],SafeMath.div(eggsUsed,5));
        //boost market to nerf shrimp hoarding
        marketEggs=SafeMath.add(marketEggs,SafeMath.div(eggsUsed,10));
        //
        onHatchEggs(msg.sender, newLobster, ref);
    }
    
    function sellEggs() public{
        require(initialized);
        uint256 hasEggs=getMyEggs();
        uint256 eggValue=calculateEggSell(hasEggs);
        uint256 fee=devFee(eggValue);
        claimedEggs[msg.sender]=0;
        lastHatch[msg.sender]=now;
        marketEggs=SafeMath.add(marketEggs,hasEggs);
        ceoAddress.transfer(fee);
        //
        uint256 ethereumEarned = SafeMath.sub(eggValue,fee);
        msg.sender.transfer(ethereumEarned);
        //
        onSellEggs(msg.sender, hasEggs, ethereumEarned);
    }
    
    function buyEggs() public payable{
        require(initialized);
        uint256 eggsBought=calculateEggBuy(msg.value,SafeMath.sub(this.balance,msg.value));
        eggsBought=SafeMath.sub(eggsBought,devFee(eggsBought));
        uint256 fee = devFee(msg.value);
        uint256 incomingEthereum = SafeMath.sub(msg.value, fee);
        ceoAddress.transfer(fee);
        claimedEggs[msg.sender]=SafeMath.add(claimedEggs[msg.sender],eggsBought);
        //
        onBuyEggs(msg.sender, eggsBought, incomingEthereum);
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
    
    function devFee(uint256 amount) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,2),100);
    }

    function seedMarket(uint256 eggs) public payable{
        require(marketEggs==0);
        //
        initialized=true;
        marketEggs=eggs;
    }

    function setFreeLobster(uint16 _newFreeLobster) public{
        require(msg.sender==ceoAddress);
        //
        STARTING_LOBSTER=_newFreeLobster;
    }    

    function getFreeLobster() public{
        require(initialized);
        //
        lastHatch[msg.sender]=now;
        hatcheryLobster[msg.sender]=STARTING_LOBSTER;
    }    
    
    function getBalance() public view returns(uint256){
        return this.balance;
    }
    
    function getMyLobster() public view returns(uint256){
        return hatcheryLobster[msg.sender];
    }
    
    function getMyEggs() public view returns(uint256){
        return SafeMath.add(claimedEggs[msg.sender],getEggsSinceLastHatch(msg.sender));
    }
    
    function getEggsSinceLastHatch(address adr) public view returns(uint256){
        uint256 secondsPassed=min(EGGS_TO_HATCH_1LOBSTER,SafeMath.sub(now,lastHatch[adr]));
        return SafeMath.mul(secondsPassed,hatcheryLobster[adr]);
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