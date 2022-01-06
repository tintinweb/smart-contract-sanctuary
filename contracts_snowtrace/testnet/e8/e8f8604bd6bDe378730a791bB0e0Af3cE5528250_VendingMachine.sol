/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-05
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.3;

contract VendingMachine {

    // Store the owner of this smart contract
    address owner;

    // A mapping is a key/value store. Here we store cupcake balance of this smart contract.
    mapping (address => uint) cupcakeBalances;

    // Events are necessary for The Graph to create entities
    event Refill(address owner, uint amount, uint remaining, uint timestamp, uint blockNumber);
    event Purchase(address buyer, uint amount, uint remaining, uint timestamp, uint blockNumber);

    // When 'VendingMachine' contract is deployed:
    // 1. set the deploying address as the owner of the contract
    // 2. set the deployed smart contract's cupcake balance to 100
    constructor() {
        owner = msg.sender;
        cupcakeBalances[address(this)] = 100;
    }

    // Allow the owner to increase the smart contract's cupcake balance
    function refill(uint amount) public onlyOwner {
        cupcakeBalances[address(this)] += amount;
        emit Refill(owner, amount, cupcakeBalances[address(this)], block.timestamp, block.number);
    }

    // Allow anyone to purchase cupcakes
    function purchase(uint amount) public payable {
        require(msg.value >= amount * 0.01 ether, "You must pay at least 0.01 ETH per cupcake");
        require(cupcakeBalances[address(this)] >= amount, "Not enough cupcakes in stock to complete this purchase");
        cupcakeBalances[address(this)] -= amount;
        cupcakeBalances[msg.sender] += amount;
        emit Purchase(msg.sender, amount, cupcakeBalances[address(this)], block.timestamp, block.number);
    }

    // Function modifiers are used to modify the behaviour of a function.
    // When "onlyOwner" modifier is added to a function, only the owner of this smart contract can execute that function.
    modifier onlyOwner {
        // Verifying that the owner is same as the one who called the function.
        require(msg.sender == owner, "Only owner callable");

        // This underscore character is called the "merge wildcard".
        // It will be replaced with the body of the function (to which we added the modifier),
        _;
    }
}