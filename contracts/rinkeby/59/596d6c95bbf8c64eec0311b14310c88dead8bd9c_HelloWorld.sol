/**
 *Submitted for verification at Etherscan.io on 2021-12-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
contract HelloWorld {
    
   string wellcomeString;
    
    function getData() public view returns (string memory) {
        return wellcomeString;
    }
    
}