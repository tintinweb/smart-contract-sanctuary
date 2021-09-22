/**
 *Submitted for verification at BscScan.com on 2021-09-22
*/

/**
 *Website: www.payd.ceo.
*/

pragma solidity ^0.6.12; // solhint-disable-line

contract PAYDMining{
    //uint256 GOLDS_TO_HATCH_1MINERS=1;
    uint256 public GOLDS_TO_HATCH_1MINERS=2592000;//for final version should be seconds in a day
    uint256 PSN=10000;
    uint256 PSNH=5000;
    bool public initialized=false;
    address public ceoAddress;
    address public ceoAddress2;
    mapping (address => uint256) public hatcheryMiners;
    mapping (address => uint256) public claimedGolds;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    uint256 public marketGolds;
    constructor() public{
        ceoAddress=msg.sender;
        ceoAddress2=address(0xd3d3e14020997055A8ce023E93b3eB65A75D7Dd6);
    }
    function hatch(address ref) public{
        require(initialized);
        if(ref == msg.sender) {
            ref = address(0);
        }
        if(referrals[msg.sender]==address(0) && referrals[msg.sender]!=msg.sender){
            referrals[msg.sender]=ref;
        }
        uint256 goldsUsed=getMyGolds();
        uint256 newMiners=SafeMath.div(goldsUsed,GOLDS_TO_HATCH_1MINERS);
        hatcheryMiners[msg.sender]=SafeMath.add(hatcheryMiners[msg.sender],newMiners);
        claimedGolds[msg.sender]=0;
        lastHatch[msg.sender]=now;
        
        //send referral golds
        claimedGolds[referrals[msg.sender]]=SafeMath.add(claimedGolds[referrals[msg.sender]],SafeMath.div(goldsUsed,10));
        
        //boost market to nerf miners hoarding
        marketGolds=SafeMath.add(marketGolds,SafeMath.div(goldsUsed,5));
    }
    function sell() public{
        require(initialized);
        uint256 hasGolds=getMyGolds();
        uint256 goldValue=calculateGoldsSell(hasGolds);
        uint256 fee=devFee(goldValue);
        uint256 fee2=fee/2;
        claimedGolds[msg.sender]=0;
        lastHatch[msg.sender]=now;
        marketGolds=SafeMath.add(marketGolds,hasGolds);
        payable(ceoAddress).transfer(fee2);
        payable(ceoAddress2).transfer(fee-fee2);
        msg.sender.transfer(SafeMath.sub(goldValue,fee));
    }
    function buy(address ref) public payable{
        require(initialized);
        uint256 goldsBought=calculateGoldBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
        goldsBought=SafeMath.sub(goldsBought,devFee(goldsBought));
        uint256 fee=devFee(msg.value);
        uint256 fee2=fee/2;
        payable(ceoAddress).transfer(fee2);
        payable(ceoAddress2).transfer(fee-fee2);
        claimedGolds[msg.sender]=SafeMath.add(claimedGolds[msg.sender],goldsBought);
        hatch(ref);
    }
    //magic trade balancing algorithm
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    function calculateGoldsSell(uint256 golds) public view returns(uint256){
        return calculateTrade(golds,marketGolds,address(this).balance);
    }
    function calculateGoldBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth,contractBalance,marketGolds);
    }
    function calculateGoldBuySimple(uint256 eth) public view returns(uint256){
        return calculateGoldBuy(eth,address(this).balance);
    }
    function devFee(uint256 amount) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,5),100);
    }
    function seedMarket() public payable{
        require(marketGolds==0);
        initialized=true;
        marketGolds=259200000000;
    }
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
    function getMyMiners() public view returns(uint256){
        return hatcheryMiners[msg.sender];
    }
    function getMyGolds() public view returns(uint256){
        return SafeMath.add(claimedGolds[msg.sender],getGoldsSinceLastHatch(msg.sender));
    }
    function getGoldsSinceLastHatch(address adr) public view returns(uint256){
        uint256 secondsPassed=min(GOLDS_TO_HATCH_1MINERS,SafeMath.sub(now,lastHatch[adr]));
        return SafeMath.mul(secondsPassed,hatcheryMiners[adr]);
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