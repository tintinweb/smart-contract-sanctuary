pragma solidity ^0.4.24;

contract Oasis{
    function getBestOffer(address sell_gem, address buy_gem) public constant returns(uint256);
    function getOffer(uint id) public constant returns (uint, address, uint, address);
}

contract EtherShrimpFutures{
    using SafeMath for uint;
    Oasis market;
    address public dai = 0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359;
    address public weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 public EGGS_TO_HATCH_1SHRIMP=86400; //seconds in a day
    uint256 public STARTING_SHRIMP=300;
    uint256 internal PSN=10000;
    uint256 internal PSNH=5000;
    bool public initialized=false;
    uint256 public marketEggs;
    address public ceoAddress;
    uint256 public numberOfFarmers;
    mapping (address => uint256) public hatcheryShrimp;
    mapping (address => uint256) public claimedEggs;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    mapping (address => uint256) public lastHatchPrice;
    address[] farmers;
    constructor() public{
        ceoAddress=msg.sender;
        market = Oasis(0x14FBCA95be7e99C15Cc2996c6C9d841e54B79425);
    }
    function hatchEggs(address ref) public{
        require(initialized);
        if(referrals[msg.sender]==0 && referrals[msg.sender]!=msg.sender){
            referrals[msg.sender]=ref;
        }
        uint256 eggsUsed=getMyEggs();
        uint256 newShrimp=SafeMath.div(eggsUsed,EGGS_TO_HATCH_1SHRIMP);
        hatcheryShrimp[msg.sender]=SafeMath.add(hatcheryShrimp[msg.sender],newShrimp);
        claimedEggs[msg.sender]=0;
        lastHatch[msg.sender]=now;
        lastHatchPrice[msg.sender] = getPrice();
        //send referral eggs
        claimedEggs[referrals[msg.sender]]=SafeMath.add(claimedEggs[referrals[msg.sender]],SafeMath.div(eggsUsed,5));
        //boost market to nerf shrimp hoarding
        marketEggs=SafeMath.add(marketEggs,SafeMath.div(eggsUsed,10));
    }
    function sellEggs() public{
        require(initialized);
        uint256 hasEggs=getMyEggs();
        uint256 eggValue=calculateEggSell(hasEggs,msg.sender);
        require(eggValue>0);
        uint256 fee=devFee(eggValue);
        claimedEggs[msg.sender]=0;
        lastHatch[msg.sender]=now;
        marketEggs=SafeMath.add(marketEggs,hasEggs);
        ceoAddress.transfer(fee);
        msg.sender.transfer(SafeMath.sub(eggValue,fee));
    }
    function buyEggs() public payable{
        require(initialized);
        if(hatcheryShrimp[msg.sender] == 0){
            numberOfFarmers += 1;
            farmers.push(msg.sender);
        }
        uint256 eggsBought=calculateEggBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
        eggsBought=SafeMath.sub(eggsBought,devFee(eggsBought));
        ceoAddress.transfer(devFee(msg.value));
        claimedEggs[msg.sender]=SafeMath.add(claimedEggs[msg.sender],eggsBought);
    }
    //magic trade balancing algorithm
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        return SafeMath.div( SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    function calculateEggSell(uint256 eggs, address adr) public view returns(uint256){
        uint sellValue = calculateTrade(eggs,marketEggs,address(this).balance);
        uint currentPrice = getPrice();
        uint diff = getDiff(currentPrice,lastHatchPrice[adr]);
        uint bonusFactor = SafeMath.mul(diff,7);
        if(bonusFactor > 1e18) {
            bonusFactor = 1e18; //at max stay true to original
        }
        return SafeMath.mul(sellValue,bonusFactor).div(1e18);
    }
    function calculateEggBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth,contractBalance,marketEggs);
    }
    function calculateEggBuySimple(uint256 eth) public view returns(uint256){
        return calculateEggBuy(eth,address(this).balance);
    }
    function devFee(uint256 amount) public view returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,2),100);
    }
    function seedMarket(uint256 eggs) public payable{
        require(msg.sender==ceoAddress && eggs != 0);
        require(marketEggs==0);
        initialized=true;
        marketEggs=eggs;
    }
    function getFreeShrimp() public{
        require(initialized);
        require(hatcheryShrimp[msg.sender]==0);
        numberOfFarmers += 1;
        farmers.push(msg.sender);
        lastHatch[msg.sender]=now;
        lastHatchPrice[msg.sender] = getPrice();
        hatcheryShrimp[msg.sender]=STARTING_SHRIMP;
    }
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
    function getMyShrimp() public view returns(uint256){
        return hatcheryShrimp[msg.sender];
    }
    function getMyEggs() public view returns(uint256){
        return SafeMath.add(claimedEggs[msg.sender],getEggsSinceLastHatch(msg.sender));
    }
    function getEggsSinceLastHatch(address adr) public view returns(uint256){
        uint256 secondsPassed=min(EGGS_TO_HATCH_1SHRIMP,SafeMath.sub(now,lastHatch[adr]));
        return SafeMath.mul(secondsPassed,hatcheryShrimp[adr]);
    }
    function getLastHatchPrice(address adr) public view returns(uint256) {
        return lastHatchPrice[adr];
    }
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
    function getDiff(uint256 a, uint256 b) public view returns(uint256) {
        uint change;
        uint diff;
        if( a >= b ) change = a - b;
        else change = b - a;
        if( change != 0 ) diff = SafeMath.div(change*1e18, b); //b is the final value
        return diff;
    }
    function getPrice() public view returns(uint256) {
        uint id1 = market.getBestOffer(weth,dai);
        uint id2 = market.getBestOffer(dai,weth);
        uint payAmt;
        uint buyAmt;
        address payGem;
        address buyGem;
        (payAmt, payGem, buyAmt, buyGem) = market.getOffer(id1);
        uint price1 = SafeMath.div(buyAmt*1e18, payAmt);
        (payAmt, payGem, buyAmt, buyGem) = market.getOffer(id2);
        uint price2 = SafeMath.div(payAmt*1e18, buyAmt);
        uint avgPrice = SafeMath.add(price1,price2).div(2);
        return avgPrice;
    }
    function getPoolAvgHatchPrice() public view returns(uint256) {
        uint256 poolSum;
        for(uint i=0; i<farmers.length; i++) {
            poolSum = SafeMath.add(lastHatchPrice[farmers[i]],poolSum);
        }
        return SafeMath.div(poolSum,farmers.length);
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