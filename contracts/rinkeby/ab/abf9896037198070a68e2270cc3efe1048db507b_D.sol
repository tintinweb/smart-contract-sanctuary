/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract D {
    address public sender;
    
    function callE(address e, address a) public returns(bool, bytes memory) {
        return address(e).delegatecall(
            abi.encodeWithSignature("callA(address)", a)
        );
    }
}