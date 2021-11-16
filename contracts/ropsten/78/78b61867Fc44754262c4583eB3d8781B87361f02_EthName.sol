//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract EthName {
    mapping(address => string) names;
    mapping(bytes32 => address) hashNames;

    function readName(address _add) public view returns (string memory) {
        return names[_add];
    }

    function setName(string memory name) external {
        bytes32 hashName = keccak256(bytes(name));
        require(hashNames[hashName] == address(0), "Name already taken");
        bytes32 currentHash = keccak256(bytes(names[msg.sender]));
        delete (hashNames[currentHash]);
        names[msg.sender] = name;
        hashNames[hashName] = msg.sender;
    }
}