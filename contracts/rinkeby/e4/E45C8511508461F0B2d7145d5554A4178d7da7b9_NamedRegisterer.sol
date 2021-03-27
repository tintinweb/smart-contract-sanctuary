/**
 *Submitted for verification at Etherscan.io on 2021-03-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.0;

interface Registerer {
    function registerMe() external pure returns(string memory);
}// end of interface Registerer

contract NamedRegisterer is Registerer {
    
    function registerMe() override external pure returns (string memory) {
        
        string memory studentName = "Joshua Brooks";
        
        return studentName;
        
    }// end of function registerMe
    
}// end of contract NamedRegisterer