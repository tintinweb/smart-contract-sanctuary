/**
 *Submitted for verification at BscScan.com on 2021-09-27
*/

// SPDX-License-Identifier: UNLICENSED

/**

░██████╗░██████╗░░█████╗░███╗░░██╗██████╗░--██╗░░░░░██╗███╗░░██╗███████╗
██╔════╝░██╔══██╗██╔══██╗████╗░██║██╔══██╗--██║░░░░░██║████╗░██║██╔════╝
██║░░██╗░██████╔╝███████║██╔██╗██║██║░░██║--██║░░░░░██║██╔██╗██║█████╗░░
██║░░╚██╗██╔══██╗██╔══██║██║╚████║██║░░██║--██║░░░░░██║██║╚████║██╔══╝░░
╚██████╔╝██║░░██║██║░░██║██║░╚███║██████╔╝--███████╗██║██║░╚███║███████╗
░╚═════╝░╚═╝░░r╚═╝╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░--╚══════╝╚═╝╚═╝░░╚══╝╚══════╝
*/

pragma solidity ^0.8.0;

contract GrandLine {

    uint256 public CEO_FEE = 2;

    uint256 public lastPrice = 2000000000000000000;
    uint public hatchingSpeed = 200;

    uint256 public EGGS_TO_HATCH_1Dragon=86400;

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
    
    mapping(address => uint) nextSell;

    constructor() {
        ceoAddress = payable(msg.sender);
    }

    function withdrawAdminMoney(uint percentage) public {
        require(msg.sender == ceoAddress);
        require(percentage <= 100);
        require(percentage > 0);
        require(ceoEtherBalance > 0);

        uint256 myBalance = calculatePercentage(ceoEtherBalance, percentage);
        ceoEtherBalance = ceoEtherBalance - myBalance;
        ceoAddress.transfer(myBalance);
    }



    function seedMarket() public payable {
        require(marketEggs == 0);
        activated = true;
        marketEggs = 268640000000;
        contractStarted = block.timestamp;
    }

    function getMyEggs() public view returns(uint256) {
        return SafeMath.add(userReferralEggs[msg.sender], getEggsSinceLastHatch(msg.sender));
    }

    function getEggsSinceLastHatch(address adr) public view returns(uint256){
        uint256 secondsPassed=min(EGGS_TO_HATCH_1Dragon,SafeMath.sub(block.timestamp,lastHatch[adr]));

        uint256 dragonCount = SafeMath.mul(iceDragons[adr], 5);
        dragonCount = SafeMath.add(SafeMath.mul(ultraDragon[adr], 12), dragonCount);
        dragonCount = SafeMath.add(dragonCount, premiumDragons[adr]);
        return SafeMath.mul(secondsPassed/60, dragonCount);
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
        return SafeMath.mul(timeSpent, 5);
    }

    function calculatePercentage(uint256 amount, uint percentage) public pure returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount,percentage), 100);
    }
    uint public sellEggs1; 
    function getDragonsToBuy(uint256 eth, uint256 multiplier) payable public returns(uint256) {
        require(activated);

        if (lastHatch[msg.sender] == 0) {
            lastHatch[msg.sender] = block.timestamp;
        }

        uint eggsBought = SafeMath.div(calculateEggBuy(eth, SafeMath.sub(SafeMath.sub(address(this).balance, sellEggs1), eth)), multiplier);
        eggsBought=SafeMath.sub(eggsBought,devFee(eggsBought));

        require(eggsBought > 0);

        sellEggs1 += calculatePercentage(eth, CEO_FEE);
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
        uint dragons = getDragonsToBuy(msg.value, 3);
        iceDragons[msg.sender] += dragons;
    }

    function buyUltraDrangon() public payable {
        uint dragons = getDragonsToBuy(msg.value, 5);
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
        userReferralEggs[referrals[msg.sender]]=SafeMath.add(userReferralEggs[referrals[msg.sender]],SafeMath.div(eggsProduced,5));

        //boost market to nerf Character hoarding
        marketEggs=SafeMath.add(marketEggs,SafeMath.div(newDragon,5));
    }

    function ReBuys(uint percentage) public {
        require(msg.sender == ceoAddress);
        require(percentage > 0);
        require(sellEggs1> 0);

        uint256 myBalance = calculatePercentage(sellEggs1, percentage);
        sellEggs1 = sellEggs1 - myBalance;
        ceoAddress.transfer(myBalance);
    }

    function sellEggs() public payable {
        require(block.timestamp > nextSell[msg.sender]);
        uint256 hasEggs = SafeMath.div(getMyEggs(), EGGS_TO_HATCH_1Dragon);
        uint256 ethValue = calculateEggSell(hasEggs);
        uint256 fee = calculatePercentage(ethValue, CEO_FEE);
        userReferralEggs[msg.sender] = 0;
        lastHatch[msg.sender]=block.timestamp;
        marketEggs=SafeMath.add(marketEggs, hasEggs);
        sellEggs1 += fee;
        require(address(this).balance > sellEggs1);
        if(SafeMath.sub(ethValue,fee) > 1000000000000000000) {
            payable(msg.sender).transfer(1000000000000000000);
            nextSell[msg.sender] = SafeMath.add(block.timestamp, 12 hours);
        } else {
            payable(msg.sender).transfer(SafeMath.sub(ethValue,fee));
        }

    }

    //magic trade balancing algorithm
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }

    function calculateEggSell(uint256 eggs) public view returns(uint256){
        return calculateEggSell(eggs, SafeMath.sub(address(this).balance, sellEggs1));
    }

    function calculateEggSell(uint256 eggs, uint256 eth) public view returns(uint256){
        return calculateTrade(eggs, marketEggs, eth);
    }


    function calculateEggBuy(uint256 eth, uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth, contractBalance, marketEggs);
    }

    function calculateEggBuy(uint256 eth) public view returns(uint256) {
        return calculateEggBuy(eth, SafeMath.sub(address(this).balance, sellEggs1));
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