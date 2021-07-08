/**
 *Submitted for verification at Etherscan.io on 2021-07-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract DicingGame {
    address public owner = msg.sender;

    function fund() public payable {}

    function removeFunds(uint256 amount) public {
        require(msg.sender == owner);
        if (amount > address(this).balance) {
            amount = address(this).balance;
        }

        payable(owner).transfer(amount);
    }

    function bet() public payable returns (uint256) {
        uint256 betValue = msg.value;
        uint256 remainder = 0;
        uint256 prevBalance = address(this).balance - msg.value;

        // Ensure that the bet cannot exceed the contract's balance.
        if (msg.value > prevBalance) {
            remainder = msg.value - prevBalance;
            betValue = prevBalance;
        }

        uint256 randomNumber = random();
        if (randomNumber > 54) {
            // Return the bet + winnings + remainder.
            payable(msg.sender).transfer(betValue * 2 + remainder);
        } else if (remainder > 0) {
            // Return the remainder.
            payable(msg.sender).transfer(remainder);
        }

        return randomNumber;
    }

    function random() private view returns (uint256) {
        // Generate a random number between 0 and 99.
        return
            uint256(
                keccak256(abi.encodePacked(block.difficulty, block.timestamp))
            ) % 100;
    }
}