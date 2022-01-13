/**
 *Submitted for verification at BscScan.com on 2022-01-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/**
 * @dev Interface of the BEP20 standard as defined in the EIP.
 */
interface IROUTER {

    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
}


contract PTEST {
    
    
     uint public _totalSupply;
         IROUTER PanRouter;
    constructor()  {
         PanRouter = IROUTER(address(0xD99D1c33F9fC3444f8101754aBC46c52416550D1));
    }


    function getAmount(uint amountIn, address[] memory path) public view returns (uint[] memory amounts) {
        return PanRouter.getAmountsOut(amountIn, path);
    }
    
  
}