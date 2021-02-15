/**
 *Submitted for verification at Etherscan.io on 2021-02-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

contract Owner {
    string private data = "Hello ABCD, welcome to the world! We love you very much";
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    function show() external view returns (string memory) {
        return data;
    }
    
}