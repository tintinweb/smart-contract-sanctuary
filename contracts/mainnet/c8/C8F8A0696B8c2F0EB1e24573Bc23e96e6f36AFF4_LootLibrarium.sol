// SPDX-License-Identifier: Unlicense

/*
┬  ┌─┐┌─┐┌┬┐
│  │ ││ │ │ 
┴─┘└─┘└─┘ ┴ 
┬  ┬┌┐ ┬─┐┌─┐┬─┐┬┬ ┬┌┬┐
│  │├┴┐├┬┘├─┤├┬┘││ ││││
┴─┘┴└─┘┴└─┴ ┴┴└─┴└─┘┴ ┴

An unofficial collection of passages and recordings
that attempt to detail one incarnation of the
decentralized Lootverse.

PUBLIC DOMAIN. Use in any way that you want. 
Feel free to remix, reuse, or ignore entirely.
*/

pragma solidity^0.8.1;

contract LootLibrarium {
    event Record(string indexed topic, string indexed content);
    event Revoke(string indexed topic);
    
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    function record(string memory topic, string memory content) public {
        // records a topic
        // if a topic is re-recorded it should be treated as an edit or update
        require(msg.sender == owner, "LootLibrarium: not owner");
        emit Record(topic, content);
    }

    function revoke(string memory topic) public {
        // revokes a topic, should be treated as a delete
        require(msg.sender == owner, "LootLibrarium: not owner");
        emit Revoke(topic);
    }
}