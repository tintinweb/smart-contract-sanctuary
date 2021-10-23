/**
 *Submitted for verification at Etherscan.io on 2021-10-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.7.4;

/**
 * @title Mymath
 * @dev Calculate & retrieve value in a variable
 */

contract Mymath{
    
    uint totalsum;
    uint totalproduct;
    
    /**
     * @dev calculate value in variable
     * @param n,k value to calculate
     */

    function totalSP(uint n, uint k) public{
    uint a = 0;
    uint b = 1;
    for(uint i = n; i<=k ; i++){
        a += i;
    }
    for(uint i = n; i<=k ; i++){
        b *= i;
    }
    (totalsum, totalproduct) = (a,b);
    }

    /**
     * @dev Return value 
     * @return value of 'totalsum'
     */
     
    function retrievesum() public view returns (uint){
        return totalsum;
    }
    
    /**
     * @dev Return value 
     * @return value of 'totalproduct'
     */
    
    function retrieveproduct() public view returns (uint){
        return totalproduct;
    }
}