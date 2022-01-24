/**
 *Submitted for verification at Etherscan.io on 2022-01-23
*/

// SPDX-License-Identifier: MIT


pragma solidity >=0.8.11 <0.9.0;

contract BettingGame {

    address payable owner;
    event YouWin();
    event YouLose();
    
    constructor() {
        owner = payable(msg.sender);
    }

    receive() external payable{}

    function withdraw() external {
        require(owner == msg.sender, "No");
        owner.transfer(address(this).balance);
    }

    function balance() external view returns (uint256) {
        return address(this).balance;
    }

    function bet(uint8 theBet) payable external{
        uint8 rand = uint8(block.timestamp %2);
        if (theBet == rand) {
            payable(msg.sender).transfer(msg.value * 2);
            emit YouWin();
        } else {
            emit YouLose();
        }
    }
}