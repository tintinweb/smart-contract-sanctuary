/**
 *Submitted for verification at BscScan.com on 2021-10-11
*/

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed
interface IMinerToken {    
	function balanceOf(address account) external view returns (uint256);
	function allowance(address owner, address spender) external view returns (uint256);
}

interface IMiner {
	function getBalance() external returns(uint256);
	function lastHatch(address adr) external  returns(uint256);
	function hatcheryMiners(address adr) external  returns(uint256);
	function claimedEggs(address adr) external  returns(uint256);
	function getEggsSinceLastHatch(address adr) external  returns(uint256);
	function calculateTrade(uint256 rt,uint256 rs, uint256 bs) external returns(uint256);
	function marketEggs() external returns(uint256);
	function marketEggs1Test() external returns(uint256);
	function devFee(uint256 amount) external returns(uint256);
	function calculateEggBuySimple(uint256 eth) external returns(uint256);
	
}
contract MyTest{
	IMinerToken minerTokenApp; 
    constructor() public{
    }
	
	function updateBuyPrice(uint256 getterType, uint256 eth, address contract_address) public  returns (uint256, uint256) {
		if(getterType==1) {
			uint256 x = IMiner(contract_address).calculateEggBuySimple(eth);
			uint256 y = IMiner(contract_address).devFee(x);
			return (x,y);
		}
		return (0,0);
	}
	
	function getTokenData(uint256 getterType, IMinerToken _minerTokenApp, address adr, address contract_address) public view returns(uint256, uint256) {
		if(getterType==1) {
			return ( _minerTokenApp.allowance(address(adr), address(contract_address)),  _minerTokenApp.balanceOf(address(adr)));
			}
			return (0,0);
	}
	
	function getMinerData( uint256 getterType, address adr, address contract_address) public  returns(uint256, uint256, uint256,uint256, uint256,uint256) {
		
		uint256 eggs;
		uint256 calculateEggSellNew;
		uint256 devFeeNew;
		
		if(getterType==1) {
			eggs = SafeMath.add(IMiner(contract_address).claimedEggs(adr),IMiner(contract_address).getEggsSinceLastHatch(adr));			
			if(eggs > 0) {
				calculateEggSellNew=IMiner(contract_address).calculateTrade(eggs,IMiner(contract_address).marketEggs(),IMiner(contract_address).getBalance());
			}			
			if(calculateEggSellNew>0) {
				devFeeNew=IMiner(contract_address).devFee(calculateEggSellNew);
			}
			return ( 
			IMiner(contract_address).getBalance(),  
			IMiner(contract_address).hatcheryMiners(adr), 
			IMiner(contract_address).lastHatch(adr),  
			eggs,
			calculateEggSellNew,
			devFeeNew
			);
		}
		
		return (0,0,0,0,0,0);
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