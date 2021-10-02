/**
 *Submitted for verification at Etherscan.io on 2021-10-01
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Registry {
    
    address private owner;
    mapping(string => address) private registry;
    
    constructor() {
        owner = msg.sender;
    }
    
    function registerContract(string calldata name, address addr) external {
        require(msg.sender == owner, "Registry: only owner");
        registry[name] = addr;
    }

    function getContractAddress(string calldata name) external view returns (address) {
        return registry[name];
    }
}