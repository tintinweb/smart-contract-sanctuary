/**
 *Submitted for verification at polygonscan.com on 2021-12-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract CoffeePortal {
    uint256 totalCoffee;

    address payable public owner; 

    event NewCoffee(
        address indexed from,
        uint256 timestamp,
        string message,
        string name
    );

    constructor() payable {
        // user who is calling this function address
        owner = payable(msg.sender);
    }

    struct Coffee {
        address giver; // The address of the user who buys me a coffee.
        string message; // The message the user sent.
        string name; // The name of the user who buys me a coffee.
        uint256 timestamp; // The timestamp when the user buys me a coffee.
    }

    /*
     * I declare variable coffee that lets me store an array of structs.
     * This is what lets me hold all the coffee anyone ever sends to me!
     */
    Coffee[] coffee;

    /*
     * I added a function getAllCoffee which will return the struct array, coffee, to us.
     * This will make it easy to retrieve the coffee from our website!
     */
    function getAllCoffee() public view returns (Coffee[] memory) {
        return coffee;
    }

    // Get All coffee bought
    function getTotalCoffee() public view returns (uint256) {
        return totalCoffee;
    }

    /*
     * You'll notice I changed the buyCoffee function a little here as well and
     * now it requires a string called _message. This is the message our user
     * sends us from the front end!
     */
    function buyCoffee(
        string memory _message,
        string memory _name,
        uint256 _payAmount
    ) public payable {
        uint256 cost = 0.001 ether;
        require(_payAmount <= cost, "Insufficient Ether provided");

        totalCoffee += 1;

        /*
         * This is where I actually store the coffee data in the array.
         */
        coffee.push(Coffee(msg.sender, _message, _name, block.timestamp));

        (bool success, ) = owner.call{value: _payAmount}("");
        require(success, "Failed to send money");

        emit NewCoffee(msg.sender, block.timestamp, _message, _name);
    }
}