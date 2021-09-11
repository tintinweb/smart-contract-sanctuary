/**
 *Submitted for verification at Etherscan.io on 2021-09-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


interface AutomaticMarketMaker {
    function calculatePurchaseReturn(uint256 etherAmount) external view returns (uint256);
    function calculateSaleReturn(uint256 tokenAmount) external view returns (uint256);
}


contract TestAMM {
    
    address payable ammAddr;
    
    function setAddr(address payable _ammAddr) external {
        ammAddr = _ammAddr;
    }
    
    function calculatePurchaseWrapper(uint256 etherAmount) public view returns (uint256) {
        AutomaticMarketMaker amm = AutomaticMarketMaker(ammAddr);
        return amm.calculatePurchaseReturn(etherAmount);
    }
    
    function calculateSaleWrapper(uint256 tokenAmount) public view returns (uint256) {
        AutomaticMarketMaker amm = AutomaticMarketMaker(ammAddr);
        return amm.calculateSaleReturn(tokenAmount);
    }

    function calculatePurchaseAmountIn(uint256 goal, uint256 eps) public view returns (uint256) {
        AutomaticMarketMaker amm = AutomaticMarketMaker(ammAddr);
	    uint256 upper = 1;
	    if (goal >= eps)
	        upper = eps >> 1;
	    uint256 amount = 0;
	    while (amount <= goal) {
	        upper <<= 1;
	        amount = amm.calculatePurchaseReturn(upper);
	    }
	    uint256 lower = upper >> 1;
	    uint256 mid;
	    while (true) {
	        mid = (lower + upper) >> 1;
	        amount = amm.calculatePurchaseReturn(mid);
	        if (amount <= goal) {
	            if (goal - amount <= eps)
	                return mid;
	            lower = mid;
	        }
	        else {
	            if (amount - goal <= eps)
	                return mid;
	            upper = mid;
	        }
	   }
    }
    
    function calculateSaleAmountIn(uint256 goal, uint256 eps) public view returns (uint256) {
        AutomaticMarketMaker amm = AutomaticMarketMaker(ammAddr);
	    uint256 upper = 1;
	    if (goal >= eps)
	        upper = eps >> 1;
	    uint256 amount = 0;
	    while (amount <= goal) {
	        upper <<= 1;
	        amount = amm.calculateSaleReturn(upper);
	    }
	    uint256 lower = upper >> 1;
	    uint256 mid;
	    while (true) {
	        mid = (lower + upper) >> 1;
	        amount = amm.calculateSaleReturn(mid);
	        if (amount <= goal) {
	            if (goal - amount <= eps)
	                return mid;
	            lower = mid;
	        }
	        else {
	            if (amount - goal <= eps)
	                return mid;
	            upper = mid;
	        }
	   }
    }
}