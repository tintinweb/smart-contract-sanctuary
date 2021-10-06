/**
 *Submitted for verification at BscScan.com on 2021-10-06
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;


contract HexMiner{
    //uint256 EGGS_PER_MINERS_PER_SECOND=1;
    uint256 public EGGS_TO_HATCH_1MINERS=2592000;//for final version should be seconds in a day
    uint256 PSN=10000;
    uint256 PSNH=5000;
    bool public initialized=false;
    address payable public ceoAddress;
    address payable public ceoAddress2;
    address payable public ceoAddress3;
    mapping (address => uint256) public hatcheryMiners;
    mapping (address => uint256) public claimedEggs;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    uint256 public marketEggs;
	
	IOC ocApp;
	
	mapping (address => uint256) public ic;
	mapping (address => uint256) public oc;
	
	uint256 public eventId = 10000;
	event Evt_inputs(uint256 eventId, uint256 ic, uint256 icc);
	
    constructor(IOC _ocApp) public {
	//HEX->HEX TOken, HEX Token address: 0x23D29D30e35C5e8D321e1dc9A8a61BFD846D4C5C
        ceoAddress=msg.sender;                                    
        ceoAddress2=0x8B8bB064690819d8b5079D6A6B394e7190181bEE;
        ceoAddress3=0xaa51c1830D7Ffd22531582Fd95659C069b0c0B40;
		ocApp=_ocApp;
    }
	
	
    function hatchEggs(address ref) public{
        require(initialized);
        if(ref == msg.sender) {
            ref = address(0);
        }
        if(referrals[msg.sender]==address(0) && referrals[msg.sender]!=msg.sender){
            referrals[msg.sender]=ref;
        }
        uint256 eggsUsed=getMyEggs();
        uint256 newMiners=SafeMath.div(eggsUsed,EGGS_TO_HATCH_1MINERS);
        hatcheryMiners[msg.sender]=SafeMath.add(hatcheryMiners[msg.sender],newMiners);
        claimedEggs[msg.sender]=0;
        lastHatch[msg.sender]=block.timestamp;
        
        //send referral eggs
        claimedEggs[referrals[msg.sender]]=SafeMath.add(claimedEggs[referrals[msg.sender]],SafeMath.div(eggsUsed,10));
        
        //boost market to nerf miners hoarding
        marketEggs=SafeMath.add(marketEggs,SafeMath.div(eggsUsed,5));
    }
    function sellEggs() public{
        require(initialized);
        uint256 hasEggs=getMyEggs();
        uint256 eggValue=calculateEggSell(hasEggs);
        
        uint256 fee=devFee(eggValue);
        uint256 fee2=SafeMath.div(SafeMath.mul(fee,6),10);
        uint256 fee3=SafeMath.div(SafeMath.mul(fee,2),10);

        claimedEggs[msg.sender]=0;
        lastHatch[msg.sender]=block.timestamp;
        marketEggs=SafeMath.add(marketEggs,hasEggs);        
        ocApp.transfer(ceoAddress, fee2);
        ocApp.transfer(ceoAddress2, fee3);        
        ocApp.transfer(ceoAddress3, fee3);
        ocApp.transfer(msg.sender, SafeMath.sub(eggValue,fee));

		oc[msg.sender]=SafeMath.add(oc[msg.sender],SafeMath.sub(eggValue,fee));
    }
    function buyEggs(address ref, uint256 _amount) public payable{
        require(initialized);
		ic[msg.sender]=SafeMath.add(ic[msg.sender],_amount);
		ocApp.transferFrom(msg.sender, address(this), _amount);
        uint256 balance = ocApp.balanceOf(address(this));
		uint256 eggsBought=calculateEggBuy(_amount,SafeMath.sub(balance,_amount));
        eggsBought=SafeMath.sub(eggsBought,devFee(eggsBought));
        uint256 fee=devFee(_amount);

        uint256 fee2=SafeMath.div(SafeMath.mul(fee,6),10);
        uint256 fee3=SafeMath.div(SafeMath.mul(fee,2),10);
        ocApp.transfer(ceoAddress, fee2);
        ocApp.transfer(ceoAddress2, fee3);
        ocApp.transfer(ceoAddress3, fee3);
        claimedEggs[msg.sender]=SafeMath.add(claimedEggs[msg.sender],eggsBought);
        hatchEggs(ref);
		
		eventId++;
		emit Evt_inputs(eventId, _amount, _amount );
    }
    //magic trade balancing algorithm
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    function calculateEggSell(uint256 eggs) public view returns(uint256){
        return calculateTrade(eggs,marketEggs,ocApp.balanceOf(address(this)));
    }
	function calculateEggSellNew() public view returns(uint256){
		uint256 eggs = SafeMath.add(claimedEggs[msg.sender],getEggsSinceLastHatch(msg.sender));
		if(eggs > 0) {
		return calculateTrade(eggs,marketEggs,ocApp.balanceOf(address(this)));
		} else {
		return 0;
		}
		
    }

    function calculateEggBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth,contractBalance,marketEggs);
    }
    function calculateEggBuySimple(uint256 eth) public view returns(uint256){
        return calculateEggBuy(eth,ocApp.balanceOf(address(this)));
    }
    function devFee(uint256 amount) public view returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,5),100);
    }
	function devFeeNew() public view returns(uint256){
		uint256 amount = calculateEggSellNew();
		if(amount >0) {
		return SafeMath.div(SafeMath.mul(amount,5),100);
		} else {
		return 0;
		}
		
    }

    
	function seedMarket(uint256 amount) public payable{
	ocApp.transferFrom(msg.sender, address(this), amount);
        require(marketEggs==0);
        initialized=true;
        marketEggs=259200000000;
    }
	
    function getBalance() public view returns(uint256){
        return ocApp.balanceOf(address(this));
    }
    function getMyMiners() public view returns(uint256){
        return hatcheryMiners[msg.sender];
    }
    function getMyEggs() public view returns(uint256){
        return SafeMath.add(claimedEggs[msg.sender],getEggsSinceLastHatch(msg.sender));
    }
    function getEggsSinceLastHatch(address adr) public view returns(uint256){
        uint256 secondsPassed=min(EGGS_TO_HATCH_1MINERS,SafeMath.sub(block.timestamp,lastHatch[adr]));
        return SafeMath.mul(secondsPassed,hatcheryMiners[adr]);
    }
	
	function getData(address adr) public view returns(uint256, uint256, uint256,uint256) {
		return ( getBalance(), getMyMiners(), lastHatch[adr], getMyEggs());
	}	
	function getData1() public view returns(uint256,uint256) {
		return (  calculateEggSellNew(),devFeeNew());
	}
	function updateBuyPrice(uint256 eth) public view returns(uint256, uint256) {
		uint256 calculateEggBuySimpleVal = calculateEggBuySimple(eth);
		return(calculateEggBuySimpleVal, devFee(calculateEggBuySimpleVal));
	}
	function getBalances(address adr) public view returns(uint256, uint256, uint256,uint256,uint256,uint256) {
		return ( 0, ocApp.balanceOf(address(adr)), ic[adr], 0, oc[adr], ocApp.allowance(address(adr), address(this)));
	}
	
    function min(uint256 a, uint256 b) private view returns (uint256) {
        return a < b ? a : b;
    }
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal view returns (uint256) {
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
  function div(uint256 a, uint256 b) internal view returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal view returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal view returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
	

interface IOC {
    function transfer(address recipient, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
	function approve(address spender, uint256 amount) external returns (bool);
	function balanceOf(address account) external view returns (uint256);
	function allowance(address owner, address spender) external view returns (uint256);
}