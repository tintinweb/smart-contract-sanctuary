/**
 *Submitted for verification at Etherscan.io on 2021-03-04
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

contract Test {
    
   struct Bond{
       uint256 id;
       string name;
   }
    
    function test() public pure returns(Bond[] memory a){
        Bond[] memory bonds;
        for(uint256 i = 0; i < 10; i++){
            bonds[i] = Bond(i, "Hi");
        }
        return bonds;
    }
}