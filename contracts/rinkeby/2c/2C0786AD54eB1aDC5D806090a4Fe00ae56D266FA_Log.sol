/**
 *Submitted for verification at Etherscan.io on 2021-08-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.16 <0.9.0;

contract Log {
    
    string constant TEXT = "abc";

    function logispog() public view returns (string memory) {
        return TEXT;
    }
}