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
        bonds[0] = Bond(0, "Hi");
        bonds[1] = Bond(1, "Hi");
        bonds[2] = Bond(2, "Hi");
        bonds[3] = Bond(3, "Hi");
        return bonds;
    }
}