/**
 *Submitted for verification at Etherscan.io on 2021-04-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

contract Fomo3D {
    
    address owner;
    uint random = block.timestamp * 0xdeadbeef;
    bool counting = false;
    uint starttime = 0;
    address last_holder;
    address winner;
    
    event SendFlag(address);
    
    modifier getWinner() {
        if (counting && block.timestamp - starttime >= 3 minutes) {
            counting = false;
            starttime = 0;
            winner = last_holder;
            emit SendFlag(winner);
            return;
        }
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    receive() external payable getWinner {}
    fallback() external payable getWinner {}
    
    function start() public getWinner {
        require(counting == false && starttime == 0, "start(): Game already started.");
        starttime = block.timestamp;
        counting = true;
        last_holder = msg.sender;
    }
    
    function hold() public getWinner {
        require(counting == true && starttime != 0 , "hold(): Game not started.");
        last_holder = msg.sender;
        starttime = block.timestamp;
    }
    
    function win() public getWinner {}
    
    function kill() public {
        require(owner == msg.sender);
        selfdestruct(payable(owner));
    }
}