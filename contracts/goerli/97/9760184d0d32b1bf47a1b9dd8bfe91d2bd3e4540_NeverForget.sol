/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7;

contract NeverForget {
    bytes32 private result;
    
    function setResult(bytes32 _record) public {
        result = _record;
    }
    
    function getResult() public view returns (bytes32) {
        return result;
    }
    
}