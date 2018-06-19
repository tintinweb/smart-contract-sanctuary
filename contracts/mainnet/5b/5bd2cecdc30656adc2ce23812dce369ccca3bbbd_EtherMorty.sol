pragma solidity ^0.4.18; // solhint-disable-line



contract EtherMorty {
    
    address public superPowerFulDragonOwner;
    uint256 lastPrice = 200000000000000000;
    uint public hatchingSpeed = 100;
    uint256 public snatchedOn;
    bool public isEnabled = false;
    
    
    function withDrawMoney() public {
        require(msg.sender == ceoAddress);
        uint256 myBalance = ceoEtherBalance;
        ceoEtherBalance = 0;
        ceoAddress.transfer(myBalance);
    }
    
    function buySuperDragon() public payable {
        require(isEnabled);
        require(initialized);
        uint currenPrice = SafeMath.add(SafeMath.div(SafeMath.mul(lastPrice, 4),100),lastPrice);
        require(msg.value > currenPrice);
        
        uint256 timeSpent = SafeMath.sub(now, snatchedOn);
        userReferralEggs[superPowerFulDragonOwner] += SafeMath.mul(hatchingSpeed,timeSpent);
        
        hatchingSpeed += SafeMath.div(SafeMath.sub(now, contractStarted), 60*60*24);
        ceoEtherBalance += calculatePercentage(msg.value, 20);
        superPowerFulDragonOwner.transfer(msg.value - calculatePercentage(msg.value, 2));
        lastPrice = currenPrice;
        superPowerFulDragonOwner = msg.sender;
        snatchedOn = now;
    }
    
    function claimSuperDragonEggs() public {
        require(isEnabled);
        require (msg.sender == superPowerFulDragonOwner);
        uint256 timeSpent = SafeMath.sub(now, snatchedOn);
        userReferralEggs[superPowerFulDragonOwner] += SafeMath.mul(hatchingSpeed,timeSpent);
        snatchedOn = now;
    }
    
    uint256 public EGGS_TO_HATCH_1Dragon=86400;//for final version should be seconds in a day
    uint256 public STARTING_Dragon=100;
    
    uint256 PSN=10000;
    uint256 PSNH=5000;
    
    bool public initialized=false;
    address public ceoAddress = 0xdf4703369ecE603a01e049e34e438ff74Cd96D66;
    uint public ceoEtherBalance;
    
    mapping (address => uint256) public iceDragons;
    mapping (address => uint256) public premiumDragons;
    mapping (address => uint256) public normalDragon;
    mapping (address => uint256) public userHatchRate;
    
    mapping (address => uint256) public userReferralEggs;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    
    uint256 public marketEggs;
    uint256 public contractStarted;
        
    function seedMarket(uint256 eggs) public payable {
        require(marketEggs==0);
        initialized=true;
        marketEggs=eggs;
        contractStarted = now;
    }
    
    function getMyEggs() public view returns(uint256){
        return SafeMath.add(userReferralEggs[msg.sender], getEggsSinceLastHatch(msg.sender));
    }
    
    function getEggsSinceLastHatch(address adr) public view returns(uint256){
        uint256 secondsPassed = SafeMath.sub(now,lastHatch[adr]);
        uint256 dragonCount = SafeMath.mul(iceDragons[adr], 12);
        dragonCount = SafeMath.add(dragonCount, premiumDragons[adr]);
        dragonCount = SafeMath.add(dragonCount, normalDragon[adr]);
        return SafeMath.mul(secondsPassed, dragonCount);
    }
    
    function getEggsToHatchDragon() public view returns (uint) {
        uint256 timeSpent = SafeMath.sub(now,contractStarted); 
        timeSpent = SafeMath.div(timeSpent, 3600);
        return SafeMath.mul(timeSpent, 10);
    }
    
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
    
    function getMyNormalDragons() public view returns(uint256) {
        return SafeMath.add(normalDragon[msg.sender], premiumDragons[msg.sender]);
    }
    
    function getMyIceDragon() public view returns(uint256) {
        return iceDragons[msg.sender];
    }
    
    function setUserHatchRate() internal {
        if (userHatchRate[msg.sender] == 0) 
            userHatchRate[msg.sender] = SafeMath.add(EGGS_TO_HATCH_1Dragon, getEggsToHatchDragon());
    }
    
    function calculatePercentage(uint256 amount, uint percentage) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,percentage),100);
    }
    
    function getFreeDragon() public {
        require(initialized);
        require(normalDragon[msg.sender] == 0);
        
        lastHatch[msg.sender]=now;
        normalDragon[msg.sender]=STARTING_Dragon;
        setUserHatchRate();
    }
    
    function buyDrangon() public payable {
        require(initialized);
        require(userHatchRate[msg.sender] != 0);
        uint dragonPrice = getDragonPrice(userHatchRate[msg.sender], address(this).balance);
        uint dragonAmount = SafeMath.div(msg.value, dragonPrice);
        require(dragonAmount > 0);
        
        ceoEtherBalance += calculatePercentage(msg.value, 40);
        premiumDragons[msg.sender] += dragonAmount;
    }
    
    function buyIceDrangon() public payable {
        require(initialized);
        require(userHatchRate[msg.sender] != 0);
        uint dragonPrice = getDragonPrice(userHatchRate[msg.sender], address(this).balance) * 8;
        uint dragonAmount = SafeMath.div(msg.value, dragonPrice);
        require(dragonAmount > 0);
        
        ceoEtherBalance += calculatePercentage(msg.value, 40);
        iceDragons[msg.sender] += dragonAmount;
    }
    
    function hatchEggs(address ref) public {
        require(initialized);
        
        if(referrals[msg.sender] == 0 && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }
        
        uint256 eggsProduced = getMyEggs();
        
        uint256 newDragon = SafeMath.div(eggsProduced,userHatchRate[msg.sender]);
        
        uint256 eggsConsumed = SafeMath.mul(newDragon, userHatchRate[msg.sender]);
        
        normalDragon[msg.sender] = SafeMath.add(normalDragon[msg.sender],newDragon);
        userReferralEggs[msg.sender] = SafeMath.sub(eggsProduced, eggsConsumed); 
        lastHatch[msg.sender]=now;
        
        //send referral eggs
        userReferralEggs[referrals[msg.sender]]=SafeMath.add(userReferralEggs[referrals[msg.sender]],SafeMath.div(eggsConsumed,10));
        
        //boost market to nerf Dragon hoarding
        marketEggs=SafeMath.add(marketEggs,SafeMath.div(eggsProduced,10));
    }
    
    function sellEggs() public {
        require(initialized);
        uint256 hasEggs = getMyEggs();
        uint256 eggValue = calculateEggSell(hasEggs);
        uint256 fee = calculatePercentage(eggValue, 20);
        userReferralEggs[msg.sender] = 0;
        lastHatch[msg.sender]=now;
        marketEggs=SafeMath.add(marketEggs,hasEggs);
        ceoEtherBalance += fee;
        msg.sender.transfer(SafeMath.sub(eggValue,fee));
    }
    
    function getDragonPrice(uint eggs, uint256 eth) internal view returns (uint) {
        uint dragonPrice = calculateEggSell(eggs, eth);
        return calculatePercentage(dragonPrice, 140);
    }
    
    function getDragonPriceNo() public view returns (uint) {
        uint256 d = userHatchRate[msg.sender];
        if (d == 0) 
            d = SafeMath.add(EGGS_TO_HATCH_1Dragon, getEggsToHatchDragon());
        return getDragonPrice(d, address(this).balance);
    }
    
    //magic trade balancing algorithm
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    
    function calculateEggSell(uint256 eggs) public view returns(uint256){
        return calculateTrade(eggs,marketEggs,address(this).balance);
    }
    
    function calculateEggSell(uint256 eggs, uint256 eth) public view returns(uint256){
        return calculateTrade(eggs,marketEggs,eth);
    }
    
    
    function calculateEggBuy(uint256 eth, uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth,contractBalance,marketEggs);
    }
    
    function calculateEggBuySimple(uint256 eth) public view returns(uint256) {
        return calculateEggBuy(eth, address(this).balance);
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