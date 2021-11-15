/**
 *Submitted for verification at Etherscan.io on 2021-11-14
*/

// SPDX-License-Identifier: Unlicense

pragma solidity^0.8.7;

contract CorruptionsDataChannel {
    event Message(string indexed message);
    
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    function postMessage(string memory message) public {
        require(msg.sender == owner, "CorruptionsDataChannel: not owner");
        emit Message(message);
    }
}