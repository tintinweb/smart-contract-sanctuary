/**
 *Submitted for verification at Etherscan.io on 2021-11-20
*/

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed
interface IMinerToken {    
	function balanceOf(address account) external view returns (uint256);
	function allowance(address owner, address spender) external view returns (uint256);
}
interface IMinerCommon {
	//getterType =1 
	//functions
	function getMultiplier() external returns(uint256);
	function getBalance() external returns(uint256);
	function getEggsSinceLastHatch(address adr) external  returns(uint256);
	function calculateTrade(uint256 rt,uint256 rs, uint256 bs) external returns(uint256);
	function devFee(uint256 amount) external returns(uint256);
	function calculateEggBuy(uint256 eth,uint256 contractBalance) external returns(uint256);
	//public variables
	function deposited(address adr) external  returns(uint256);
	function withdrawn(address adr) external  returns(uint256);
	function referrals(address adr) external  returns(address);
	function refBonus(address adr) external  returns(uint256);
	function lastHatch(address adr) external  returns(uint256);
	function hatcheryMiners(address adr) external  returns(uint256);
	function claimedEggs(address adr) external  returns(uint256);
	function marketEggs() external returns(uint256);
	function EGGS_TO_HATCH_1MINERS()  external returns(uint256);
	
	// no exist functions test
	function marketEggs1Test() external returns(uint256);
}

contract ICOTest{
	IMinerToken minerTokenApp; 
    constructor() public{
    }
	
	function getContractBalanceNonNative(IMinerToken _minerTokenApp,address adr) public view returns(uint256) {
		return (  _minerTokenApp.balanceOf(address(adr)));
	}
	
	function getContractBalance(address adr) public view returns(uint256) {
		return (  address(adr).balance);
	}
	
	/////////////////////getterType=1////////////////////////////
	function getTokenData1(IMinerToken _minerTokenApp, address adr, address contract_address) public view returns(uint256, uint256) {
			return ( _minerTokenApp.allowance(address(adr), address(contract_address)),  _minerTokenApp.balanceOf(address(adr)));
	}
	function getMinerPriceAndContractBalance1(uint256 eth, address contract_address) public  returns (uint256, uint256, uint256, uint256) {
			uint256 balance;uint256 x;uint256 y;uint256 eggsHatch1Miners;			
			balance = IMinerCommon(contract_address).getBalance();
			x = IMinerCommon(contract_address).calculateEggBuy(eth, balance);			
			y = IMinerCommon(contract_address).devFee(x);			
			eggsHatch1Miners=IMinerCommon(contract_address).EGGS_TO_HATCH_1MINERS();			
			return (x,y, eggsHatch1Miners, balance);
	}
	function getMinerData1( address adr, address contract_address) public  returns(uint256, uint256, uint256,uint256, uint256,uint256,uint256) {
				uint256 eggs;uint256 calculateEggSellNew;
				eggs = SafeMath.add(IMinerCommon(contract_address).claimedEggs(adr),IMinerCommon(contract_address).getEggsSinceLastHatch(adr));	
				if(eggs > 0) {
						calculateEggSellNew=IMinerCommon(contract_address).calculateTrade(eggs,IMinerCommon(contract_address).marketEggs(),IMinerCommon(contract_address).getBalance());
				}			
				return ( 
				IMinerCommon(contract_address).getBalance(),  
				IMinerCommon(contract_address).hatcheryMiners(adr), 
				IMinerCommon(contract_address).lastHatch(adr),  
				eggs,
				calculateEggSellNew,
				IMinerCommon(contract_address).devFee(calculateEggSellNew),
				IMinerCommon(contract_address).marketEggs()
				);
	}
	function getMinerData2( address adr, address contract_address) public  returns(uint256, uint256, uint256,uint256) {
				return ( 
				IMinerCommon(contract_address).claimedEggs(adr),
				IMinerCommon(contract_address).lastHatch(adr),  
				IMinerCommon(contract_address).getEggsSinceLastHatch(adr),
				SafeMath.add(IMinerCommon(contract_address).claimedEggs(adr),IMinerCommon(contract_address).getEggsSinceLastHatch(adr))
				);
	}
	function getMinerData3( address adr, address contract_address) public  returns(uint256, uint256, address,uint256,uint256) {
				return ( 
				IMinerCommon(contract_address).deposited(adr),
				IMinerCommon(contract_address).withdrawn(adr),  
				IMinerCommon(contract_address).referrals(adr),
				IMinerCommon(contract_address).refBonus(adr),
				IMinerCommon(contract_address).getMultiplier()
				);
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