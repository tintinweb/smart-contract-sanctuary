/**
 *Submitted for verification at polygonscan.com on 2022-01-21
*/

pragma solidity ^0.4.26; // solhint-disable-line

contract GANJA_FARM{
    //uint256 seeds_PER_PLANTS_PER_SECOND=1;
    uint256 public SEEDS_TO_GROW1PLANT=2592000;//for final version should be seconds in a day
    uint256 PSN=10000;
    uint256 PSNH=5000;
    bool public initialized=false;
    address public ceoAddress;
    address public ceoAddress2;
    mapping (address => uint256) public growPlants;
    mapping (address => uint256) public claimedSeeds;
    mapping (address => uint256) public lastGrow;
    mapping (address => address) public referrals;
    uint256 public marketSeeds;
    constructor() public{
        ceoAddress=msg.sender;
    }
    function grownSeeds(address ref) public{
        require(initialized);
        if(ref == msg.sender) {
            ref = 0;
        }
        if(referrals[msg.sender]==0 && referrals[msg.sender]!=msg.sender){
            referrals[msg.sender]=ref;
        }
        uint256 seedsUsed=getMySeeds();
        uint256 newMiners=SafeMath.div(seedsUsed,SEEDS_TO_GROW1PLANT);
        growPlants[msg.sender]=SafeMath.add(growPlants[msg.sender],newMiners);
        claimedSeeds[msg.sender]=0;
        lastGrow[msg.sender]=now;
        
        //send referral seeds
        claimedSeeds[referrals[msg.sender]]=SafeMath.add(claimedSeeds[referrals[msg.sender]],SafeMath.div(seedsUsed,10));
        
        //boost market to nerf plant hoarding
        marketSeeds=SafeMath.add(marketSeeds,SafeMath.div(seedsUsed,5));
    }
    function sellseeds() public{
        require(initialized);
        uint256 hasSeeds=getMySeeds();
        uint256 seedValue=calculateSeedSell(hasSeeds);
        uint256 fee=devFee(seedValue);
        uint256 fee2=fee/2;
        claimedSeeds[msg.sender]=0;
        lastGrow[msg.sender]=now;
        marketSeeds=SafeMath.add(marketSeeds,hasSeeds);
        ceoAddress.transfer(fee2);
        ceoAddress2.transfer(fee-fee2);
        msg.sender.transfer(SafeMath.sub(seedValue,fee));
    }
    function buySeeds(address ref) public payable{
        require(initialized);
        uint256 seedsBought=calculateSeedBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
        seedsBought=SafeMath.sub(seedsBought,devFee(seedsBought));
        uint256 fee=devFee(msg.value);
        uint256 fee2=fee/2;
        ceoAddress.transfer(fee2);
        ceoAddress2.transfer(fee-fee2);
        claimedSeeds[msg.sender]=SafeMath.add(claimedSeeds[msg.sender],seedsBought);
        grownSeeds(ref);
    }
    //magic trade balancing algorithm
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    function calculateSeedSell(uint256 seeds) public view returns(uint256){
        return calculateTrade(seeds,marketSeeds,address(this).balance);
    }
    function calculateSeedBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth,contractBalance,marketSeeds);
    }
    function calculateSeedBuySimple(uint256 eth) public view returns(uint256){
        return calculateSeedBuy(eth,address(this).balance);
    }
    function devFee(uint256 amount) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,5),100);
    }
    function seedMarket() public payable{
        require(marketSeeds==0);
        initialized=true;
        marketSeeds=259200000000;
    }
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
    function getMyPlants() public view returns(uint256){
        return growPlants[msg.sender];
    }
    function getMySeeds() public view returns(uint256){
        return SafeMath.add(claimedSeeds[msg.sender],getseedsSinceLastGrow(msg.sender));
    }
    function getseedsSinceLastGrow(address adr) public view returns(uint256){
        uint256 secondsPassed=min(SEEDS_TO_GROW1PLANT,SafeMath.sub(now,lastGrow[adr]));
        return SafeMath.mul(secondsPassed,growPlants[adr]);
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