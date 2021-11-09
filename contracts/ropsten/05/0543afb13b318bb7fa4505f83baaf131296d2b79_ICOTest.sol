/**
 *Submitted for verification at Etherscan.io on 2021-11-09
*/

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed
interface IFarmerToken {    
	function balanceOf(address account) external view returns (uint256);
	function allowance(address owner, address spender) external view returns (uint256);
}
interface IFarmerCommon {
	//getterType =101
	
	//functions
	function getContractBalance() external returns(uint256);
	function getUserAvailable(address adr) external returns(uint256); // gives both available referral bonus and dividends
	function getUserInfo(address adr) external returns(uint256, uint256, uint256); // gives total deposiuted, total withdrawn, total referrals count
	function getUserReferralBonus(address adr) external returns(uint256); // referral bonus avaialable,  withdraw function gets both withdraw avaiable + referral avaiable
	function getUserReferralTotalBonus(address adr) external returns(uint256); // total referral bonus ,
	
	
	//public variables
	function totalInvested() external returns(uint256);
	function INVEST_MIN_AMOUNT() external returns(uint256);
	
}
interface IFarmer1 {
	//getterType =102
}

contract ICOTest{
	IFarmerToken farmerTokenApp; 
    constructor() public{
    }
	
		function getContractBalanceNonNative(IFarmerToken _farmerTokenApp,address adr) public view returns(uint256) {
		return (  _farmerTokenApp.balanceOf(address(adr)));
	}
	
	function getContractBalance(address adr) public view returns(uint256) {
		return (  address(adr).balance);
	}
	
	
	/////////////////////getterType=101////////////////////////////
	function getTokenData1(IFarmerToken _farmerTokenApp, address adr, address contract_address) public view returns(uint256, uint256) {
			return ( _farmerTokenApp.allowance(address(adr), address(contract_address)),  _farmerTokenApp.balanceOf(address(adr)));
	}
	
	function getFarmerData1_1( address contract_address) public  returns(uint256, uint256) {							
				return ( 
				IFarmerCommon(contract_address).getContractBalance(), 
				IFarmerCommon(contract_address).totalInvested()
				);
	}
	function getFarmerData1_2( address adr, address contract_address) public  returns(uint256, uint256, uint256,uint256,uint256) {							
				uint256 totalDeposit; uint256 totalWithdrawn; 
				(totalDeposit, totalWithdrawn, ) = IFarmerCommon(contract_address).getUserInfo(adr);
				return ( 
				totalDeposit, totalWithdrawn,			
				IFarmerCommon(contract_address).getUserAvailable(adr), 
				IFarmerCommon(contract_address).getUserReferralBonus(adr),
				IFarmerCommon(contract_address).getUserReferralTotalBonus(adr)
				
				
				);
	}
	/////////////////////getterType=102////////////////////////////
	

	
	/////////////////////getterType=3////////////////////////////
	
	
	/////////////////////getterType=4////////////////////////////
	
	/////////////////////getterType=5////////////////////////////
	
	/////////////////////getterType=6////////////////////////////
	
	
	///////////////////////////////////////////////////////////
	
	
	
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