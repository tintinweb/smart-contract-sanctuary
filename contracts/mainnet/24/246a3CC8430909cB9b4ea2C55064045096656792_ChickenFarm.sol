pragma solidity ^0.4.18; // solhint-disable-line

contract ChickenFarm{
    
    uint256 public EGGS_TO_HATCH_1CHICKEN = 86400;
    uint256 public STARTING_CHICKEN = 300;
    uint256 PSN = 10000;
    uint256 PSNH = 5000;
    bool public initialized = false;
    address public ceoAddress;
    mapping (address => uint256) public hatcheryCHICKEN;
    mapping (address => uint256) public claimedEggs;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    uint256 public marketEggs;
    
    function ChickenFarm() public{
        ceoAddress = msg.sender;
    }
    function hatchEggs(address ref) public{
        require(initialized);
        if(referrals[msg.sender] == 0 && referrals[msg.sender] != msg.sender){
            referrals[msg.sender] = ref;
        }
        uint256 eggsUsed = getMyEggs();
        uint256 newCHICKEN = SafeMath.div(eggsUsed,EGGS_TO_HATCH_1CHICKEN);
        hatcheryCHICKEN[msg.sender] = SafeMath.add(hatcheryCHICKEN[msg.sender], newCHICKEN);
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = now;
        
        claimedEggs[referrals[msg.sender]] = SafeMath.add(claimedEggs[referrals[msg.sender]], SafeMath.div(eggsUsed, 5));
        
        marketEggs = SafeMath.add(marketEggs, SafeMath.div(eggsUsed, 10));
    }
    function sellEggs() public{
        require(initialized);
        uint256 hasEggs = getMyEggs();
        uint256 eggValue = calculateEggSell(hasEggs);
        uint256 fee = devFee(eggValue);
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = now;
        marketEggs = SafeMath.add(marketEggs, hasEggs);
        ceoAddress.transfer(fee);
        msg.sender.transfer(SafeMath.sub(eggValue, fee));
    }
    function buyEggs() public payable{
        require(initialized);
        uint256 eggsBought = calculateEggBuy(msg.value,SafeMath.sub(this.balance,msg.value));
        eggsBought = SafeMath.sub(eggsBought,devFee(eggsBought));
        ceoAddress.transfer(devFee(msg.value));
        claimedEggs[msg.sender] = SafeMath.add(claimedEggs[msg.sender],eggsBought);
    }
    
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    function calculateEggSell(uint256 eggs) public view returns(uint256){
        return calculateTrade(eggs, marketEggs, this.balance);
    }
    function calculateEggBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth, contractBalance, marketEggs);
    }
    function calculateEggBuySimple(uint256 eth) public view returns(uint256){
        return calculateEggBuy(eth, this.balance);
    }
    function devFee(uint256 amount) public view returns(uint256){
        return SafeMath.div(SafeMath.mul(amount, 4), 100);
    }
    function seedMarket(uint256 eggs) public payable{
        require(marketEggs == 0 && msg.sender == ceoAddress);
        initialized = true;
        marketEggs = eggs;
    }
    function getFreeCHICKEN() public {
        require(initialized);
        require(hatcheryCHICKEN[msg.sender] == 0);
        lastHatch[msg.sender] = now;
        hatcheryCHICKEN[msg.sender] = STARTING_CHICKEN;
    }
    function getBalance() public view returns(uint256){
        return this.balance;
    }
    function getMyChicken() public view returns(uint256){
        return hatcheryCHICKEN[msg.sender];
    }
    function getMyEggs() public view returns(uint256){
        return SafeMath.add(claimedEggs[msg.sender],getEggsSinceLastHatch(msg.sender));
    }
    function getEggsSinceLastHatch(address adr) public view returns(uint256){
        uint256 secondsPassed = min(EGGS_TO_HATCH_1CHICKEN, SafeMath.sub(now, lastHatch[adr]));
        return SafeMath.mul(secondsPassed, hatcheryCHICKEN[adr]);
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