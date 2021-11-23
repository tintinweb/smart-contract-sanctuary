// SPDX-License-Identifier: Unlicense

pragma solidity^0.8.1;

contract CorruptionsCompendium {
    event Record(string indexed topic, string indexed content);
    event Revoke(string indexed topic);
    
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    function record(string memory topic, string memory content) public {
        require(msg.sender == owner, "CorruptionsCompendium: not owner");
        emit Record(topic, content);
    }

    function revoke(string memory topic) public {
        require(msg.sender == owner, "CorruptionsCompendium: not owner");
        emit Revoke(topic);
    }
}