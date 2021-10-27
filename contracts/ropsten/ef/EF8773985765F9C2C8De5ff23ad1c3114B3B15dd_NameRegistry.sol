// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract NameRegistry {
    event NameSet(address account, string name);

    mapping(address => string) public names;
    mapping(string => bool) public nameUsed;

    function setName(string memory name) external {
        require(!nameUsed[name], "Name already used");
        delete nameUsed[names[msg.sender]];
        names[msg.sender] = name;
        nameUsed[name] = true;
        emit NameSet(msg.sender, name);
    }

    function readName(address account) external view returns (string memory) {
        return names[account];
    }
}