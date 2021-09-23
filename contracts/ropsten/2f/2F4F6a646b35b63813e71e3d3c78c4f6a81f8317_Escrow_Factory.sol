/**
 *Submitted for verification at Etherscan.io on 2021-09-23
*/

/**
 *Submitted for verification at Etherscan.io on 2021-09-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// Create an enum which defines what states the contract can be in
enum contractState{AWAITING_BUYER_PAYMENT,AWAITNG_SELLER_ACCEPTANCE,AWAITING_BUYER_SATISFACTION,COMPLETED}

contract Escrow_Factory {

    address payable public contractOwner;

    mapping(uint256 => Escrow) public escrows;

    constructor() {
        contractOwner = payable(msg.sender);
    }

    function newEscrow(uint256 _id, address payable _seller, address payable _buyer) external {

        // Check a contract doesnt already exist with that ID
        require(!this.exists(_id), 'Sorry a contract with that ID already exists.');

        // Check _seller, _buyer are not empty inputs
        require(_seller != address(0) && _buyer != address(0), 'Ensure buyer and seller address are valid.');

        // Create new contract
        Escrow e = new Escrow(_seller,_buyer);

        // Store contract in mapping
        escrows[_id] = e;

    }

    function buyerDeposit(uint256 _id) external payable {

        // Check a contract doesnt already exist with that ID
        require(this.exists(_id), "Sorry a contract with that ID doesn't exists.");

        // Get contract
        Escrow e = escrows[_id];

        // Ensure value deposited is greater than 0
        require(msg.value > 0, 'Please ensure amount depositied is greater than 0.');

        // Check msg.sender is the buyer of the contract
        require(msg.sender == e.getBuyer(), 'Only the defined buyer of this contract can deposit to pot.');

        // Check contract is in a state ready to accept buyer deposit
        require(e.getState() == contractState.AWAITING_BUYER_PAYMENT, 'Contract is not in a state to accept any funds.');

        // Move funds to escrow contract
        (bool success, ) = address(e).call{value:msg.value}('');
        require(success, 'Could not transfer funds to escrow contract');

    }

    function getContractValue(uint256 _id) public view returns (uint256) {
        
        // Check a contract doesnt already exist with that ID
        require(this.exists(_id), "Sorry a contract with that ID doesn't exists.");

        // Get contract
        Escrow e = escrows[_id];

        return address(e).balance;

    }

    function getContractAddress(uint256 _id) public view returns (address) {

        // Check a contract doesnt already exist with that ID
        require(this.exists(_id), "Sorry a contract with that ID doesn't exists.");

        // Get contract
        Escrow e = escrows[_id];

        return address(e);

    }



    // Checks if a contract is already allocated a unique ID
    function exists(uint256 _id) public view returns (bool) {
        if(address(escrows[_id]) != address(0)) {
            return true;
        } else {
            return false;
        }
    }

}

contract Escrow {

    address payable public seller;
    address payable public buyer;

    contractState state;

    constructor(address payable _seller, address payable _buyer) {
        seller = _seller;
        buyer = _buyer;

        state = contractState.AWAITING_BUYER_PAYMENT;
    }

    function getBuyer() public view returns (address) {
        return buyer;
    }

    function getState() public view returns (contractState) {
        return state;
    }

    fallback() external payable {
        require(msg.sender == buyer);
    }

}

// Author: Etienne Cellier-Clarke