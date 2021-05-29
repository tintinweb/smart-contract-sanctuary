/**
 *Submitted for verification at Etherscan.io on 2021-05-29
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Lottery
 * @dev simple lottery
 */
contract Lottery {
    uint8 constant private maxParticipants = 5;
    uint8 private liveParticipants = 0;
    
    address payable private owner;
    address payable[maxParticipants] private participants;

    constructor() {
        owner = payable(msg.sender); 
    }

    function bid() public payable {
        require(msg.value == 1 gwei, "Please send 1 gwei");
        participants[liveParticipants]=payable(msg.sender);
        liveParticipants++;
        if (liveParticipants==maxParticipants) {
            withdraw();
        }
    }

    function withdraw() private {
        uint8 winner =  uint8(block.number % 5);
        owner.transfer(1 gwei/100);
        participants[winner].transfer(address(this).balance);
        liveParticipants=0;
    }
}