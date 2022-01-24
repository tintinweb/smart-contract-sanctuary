/**
 *Submitted for verification at Etherscan.io on 2022-01-24
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.11 <0.9.0;

contract BettingGame {
    
    event Result(string result);
    
    address payable owner;

    constructor() {
        owner = payable(msg.sender);
    }

    receive() external payable {}
    
    function withdraw() external {
        require(owner == msg.sender, "You can't do this!");
        owner.transfer(address(this).balance);
    }

    function balance() external view returns (uint256) {
        return address(this).balance;
    }

    function bet(uint8 theBet) payable external {
        //msg.value , msg.sender
        require(address(this).balance > 2* msg.value, "Sorry, no fund!");
        
        uint8 rand = uint8(block.timestamp %2);
        if (theBet == rand) { //win
            payable(msg.sender).transfer(2* msg.value);
            emit Result("You win!");
        } else {
            emit Result("You lose!");
        }
    }

}