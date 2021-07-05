/**
 *Submitted for verification at Etherscan.io on 2021-07-05
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.7.6;

contract Demo {
    
}

contract Test {
    function create2() public returns (address pair) {
        bytes memory bytecode = type(Demo).creationCode;
        bytes32 salt = keccak256(abi.encodePacked());
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
    }
}