pragma solidity ^0.4.18; // solhint-disable-line

contract GoTDragonFarm {
    uint256 public EGGS_TO_HATCH_1DRAGON = 43200; // every 12 hours
    
    uint256 PSN = 10000;
    uint256 PSNH = 5000;
    
    bool public initialized = false;
    
    address public ceoAddress;
    
    mapping (address => uint256) public hatchery;
    mapping (address => uint256) public claimedEggs;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    
    uint256 public marketEggs;
    
    event Buy(address _from, uint256 _eggs);
    event Sell(address _from, uint256 _eggs);
    event Hatch(address _from, uint256 _eggs, uint256 _dragons);
    
    constructor() public {
        ceoAddress=msg.sender;
    }
    
    function hatchEggs(address ref) public {
        require(initialized);
        
        if(referrals[msg.sender] == 0 && referrals[msg.sender] != msg.sender){
            referrals[msg.sender] = ref;
        }
        
        uint256 eggsUsed = getMyEggs();
        
        uint256 newDragons = SafeMath.div(eggsUsed, EGGS_TO_HATCH_1DRAGON);
        hatchery[msg.sender] = SafeMath.add(hatchery[msg.sender], newDragons);
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = now;
        
        //send referral eggs
        claimedEggs[referrals[msg.sender]] = SafeMath.add(claimedEggs[referrals[msg.sender]],SafeMath.div(eggsUsed,5));
        
        //boost market to nerf dragon hoarding
        marketEggs=SafeMath.add(marketEggs,SafeMath.div(eggsUsed,10));
        
        emit Hatch(msg.sender, eggsUsed, newDragons);
    }
    
    function sellEggs() public {
        require(initialized);
        
        uint256 hasEggs = getMyEggs();
        uint256 eggValue = calculateEggSell(hasEggs);
        
        uint256 fee = calculateDevFee(eggValue);
        
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = now;
        marketEggs = SafeMath.add(marketEggs,hasEggs);
        
        ceoAddress.transfer(fee);
        
        msg.sender.transfer(SafeMath.sub(eggValue,fee));
        
        emit Sell(msg.sender, hasEggs);
    }
    
    function buyEggs() public payable {
        require(initialized);
        
        uint256 eggsBought = calculateEggBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
        eggsBought = SafeMath.sub(eggsBought, calculateDevFee(eggsBought));
        
        ceoAddress.transfer(calculateDevFee(msg.value));
        
        claimedEggs[msg.sender] = SafeMath.add(claimedEggs[msg.sender], eggsBought);
        
        emit Buy(msg.sender, eggsBought);
    }
    
    //magic trade balancing algorithm
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    
    function calculateEggSell(uint256 eggs) public view returns(uint256){
        return calculateTrade(eggs,marketEggs, address(this).balance);
    }
    
    function calculateEggBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth,contractBalance,marketEggs);
    }
    
    function calculateEggBuySimple(uint256 eth) public view returns(uint256){
        return calculateEggBuy(eth, address(this).balance);
    }
    
    function calculateDevFee(uint256 amount) public view returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,4),100);
    }
    
    function seedMarket(uint256 eggs) public payable {
        require(msg.sender == ceoAddress);
        require(marketEggs == 0);
        initialized = true;
        marketEggs = eggs;
    }
    
    function claimFreeDragon() public{
        require(initialized);
        require(hatchery[msg.sender] == 0);
        lastHatch[msg.sender] = now;
        hatchery[msg.sender] = 300;
    }
    
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
    
    function getMyDragons() public view returns(uint256){
        return hatchery[msg.sender];
    }
    
    function getMyEggs() public view returns(uint256){
        return SafeMath.add(claimedEggs[msg.sender], getEggsSinceLastHatch(msg.sender));
    }
    
    function getEggsSinceLastHatch(address _address) public view returns(uint256){
        uint256 secondsPassed = min(EGGS_TO_HATCH_1DRAGON, SafeMath.sub(now, lastHatch[_address]));
        return SafeMath.mul(secondsPassed, hatchery[_address]);
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