/**
 *Submitted for verification at Etherscan.io on 2021-10-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library GetAddr {
    
    function getData() public view returns(address) {
        
        return address(this);
    }
    
}

contract Testing {
    
    function getAddress() public view returns (address) {
        
        return GetAddr.getData();
    }
    
}