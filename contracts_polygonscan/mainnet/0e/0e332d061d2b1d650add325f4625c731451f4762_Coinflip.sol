/**
 *Submitted for verification at polygonscan.com on 2021-09-08
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title Coinflip
 */
contract Coinflip {

    address payable owner;
    
    uint edge;
    uint calls;
    uint wins;
    uint losses;
    
    event flipped(address addr, bool winner, uint wager, uint amount);

    constructor() payable {
        owner = payable(msg.sender);
        edge = 2;
    }

    function balance () public view returns (uint) {
        return address(this).balance;
    }
    
    function deposit () public payable returns (uint) {
        require(msg.value > 0, "Send value with this function call.");
        return balance();
    }
    
    function withdraw (uint amount) public returns (uint) {
        require(msg.sender == owner, "Only owner may call this function.");
        require(amount <= address(this).balance);
        owner.transfer(amount);
        return balance();
    }
    
    function getEdge () public view returns (uint) {
        return edge;
    }
    
    function setEdge (uint e) public {
        require(e >= 0 && e <= 100, "");
        require(msg.sender == owner, "Only owner may call this function.");
        edge = e;
    }
    
    function flip () public payable returns (bool, uint) {
        uint win = ((msg.value / 100) * (100 - edge)) * 2;
        require(win < address(this).balance, "Bank cannot payout a win of this size.");
        calls++;
        bool result = (keccak256(abi.encodePacked(block.number, block.timestamp, block.difficulty, wins, losses, calls)) >> 255) > 0;
        if (result) {
            payable(msg.sender).transfer(win);
            wins++;
        } else {
            win = 0;
            losses++;
        }
        emit flipped(msg.sender, result, msg.value, win);
        return (result, win);
    }
}