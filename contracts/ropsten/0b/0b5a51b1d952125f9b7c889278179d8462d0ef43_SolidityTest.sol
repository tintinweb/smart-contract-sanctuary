/**
 *Submitted for verification at Etherscan.io on 2021-05-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title SolidityTest
 * @dev SolidityTest & retrieve value in a variable
 */
contract SolidityTest {
    
    /**
     * @dev Return value 
     * @return value of 'result'
     */
   function retrieve() public pure returns (uint256){
      uint256 a = 1;
      uint256 b = 2;
      uint256 result = a + b;
      return result;
   }
}