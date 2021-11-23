/**
 *Submitted for verification at Etherscan.io on 2021-11-22
*/

// SPDX-License-Identifier: WTFPL

pragma solidity ^0.8.10;

contract EthRegistry {
    event LogRegister(address addr, bytes32 key, string value);
    mapping(address => mapping(bytes32 => string)) public registry;

    function register(bytes32 key, string memory value) public {
        registry[msg.sender][key] = value;
        emit LogRegister(msg.sender, key, value);
    }

    function get(address addr, bytes32 key) public view returns(string memory) {
        return registry[addr][key];
    }
    
    function get(bytes32 key) public view returns(string memory) {
        return registry[msg.sender][key];
    }

}