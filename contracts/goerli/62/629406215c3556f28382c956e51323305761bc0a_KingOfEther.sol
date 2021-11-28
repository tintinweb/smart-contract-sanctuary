/**
 *Submitted for verification at Etherscan.io on 2021-11-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract KingOfEther {

    address public current_king;
    mapping(address => King) public kings;
    struct King {
        address addr;
        string name;
        uint256 amount;
        uint256 withdraw_amount;
    }
    
    address[] public king_history;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    event NewKing(address indexed king, string name, uint256 amount);

    function replace_king(string memory name) public payable {
        if(king_history.length != 0) {
            require(msg.value > kings[current_king].amount + 0.1 ether, "You need to pay more than current king");
            require(current_king != msg.sender, "You are already the current king");
            
            kings[current_king].withdraw_amount += msg.value;  // Add new king's input amount to old king's withdraw amount
        }

        current_king = msg.sender;  // Record current king
        kings[msg.sender] = King(msg.sender, name, msg.value, 0);  //  Record current king's information
        king_history.push(msg.sender);  //  Record on king history

        emit NewKing(msg.sender, name, msg.value);
    }

    function player_withdraw() public {
        require(kings[msg.sender].withdraw_amount > 0, "You have to be a retired king");

        uint256 amount = kings[msg.sender].withdraw_amount - 0.05 ether;  // Calculate the amount of withdrawal (- fee)
        payable(msg.sender).transfer(amount);  // transfer

        kings[msg.sender].withdraw_amount = 0;  // Change withdrawer's withdraw amount to 0
    }

    function owner_withdraw() external {
        require(msg.sender == owner, "Only owner can collect all fees");

        payable(msg.sender).transfer(address(this).balance); // transfer
    }
}