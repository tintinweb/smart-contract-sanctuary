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

    // Notifies sender
    event notify(string message);

    function newEscrow(uint256 _id, address payable _seller, address payable _buyer) external {

        // Check a contract doesnt already exist with that ID
        require(!this.exists(_id), 'Sorry a contract with that ID already exist.');

        // Check _seller, _buyer are not empty inputs
        require(_seller != address(0) && _buyer != address(0), 'Ensure buyer and seller address are valid.');

        // Create new contract
        Escrow e = new Escrow(_seller,_buyer);

        // Store contract in mapping
        escrows[_id] = e;

    }

    function buyerDeposit(uint256 _id) external payable {

        // Check a contract doesnt already exist with that ID
        require(this.exists(_id), "Sorry a contract with that ID doesn't exist.");

        // Ensure value deposited is greater than 0
        require(msg.value > 0, 'Please ensure amount depositied is greater than 0.');

        // Get contract
        Escrow e = escrows[_id];

        // Check msg.sender is the buyer of the contract
        require(msg.sender == e.getBuyer(), 'Only the defined buyer of this contract can deposit to pot.');

        // Check contract is in a state ready to accept buyer deposit
        require(e.getState() == contractState.AWAITING_BUYER_PAYMENT, 'Contract is not in a state to accept any funds.');

        // Move funds to escrow contract
        (bool success, ) = address(e).call{value:msg.value}('');
        require(success, 'Could not transfer funds to escrow contract');

        // Update contract state
        e.setState(contractState.AWAITNG_SELLER_ACCEPTANCE);

    }

    function getContractValue(uint256 _id) public view returns (uint256) {
        
        // Check a contract doesnt already exist with that ID
        require(this.exists(_id), "Sorry a contract with that ID doesn't exist.");

        // Get contract
        Escrow e = escrows[_id];

        return address(e).balance;

    }

    function getContractAddress(uint256 _id) public view returns (address) {

        // Check a contract doesnt already exist with that ID
        require(this.exists(_id), "Sorry a contract with that ID doesn't exist.");

        // Get contract
        Escrow e = escrows[_id];

        return address(e);

    }

    // function buyerCancel(uint256 _id, bool _cancel) public {

    //     // Check a contract doesnt already exist with that ID
    //     require(this.exists(_id), "Sorry a contract with that ID doesn't exist.");

    //     // Get contract
    //     Escrow e = escrows[_id];

    //     // Check msg.sender is the buyer
    //     require(msg.sender == e.getBuyer(), 'Only the buyer of this contract can cancel offer');

    //     // Require 3 days have passed before buyer can cancel
    //     require((block.timestamp-e.getDepositTime()) > 3 days, 'Please allow 3 days for seller to accept before being able to cancel');

    //     // Attempt to cancel contract
    //     require(_cancel && e.cancel(), 'Contract was unable to be cancelled');

    // }



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

    uint256 buyerDepositTimeStamp;

    contractState state;

    modifier onlyBuyer {
        require(msg.sender == buyer);
        _;
    }

    modifier onlySeller {
        require(msg.sender == seller);
        _;
    }

    constructor(address payable _seller, address payable _buyer) {
        seller = _seller;
        buyer = _buyer;

        state = contractState.AWAITING_BUYER_PAYMENT;
    }

    function getDepositTime() public view returns (uint256) {
        return buyerDepositTimeStamp;
    }

    function getBuyer() public view returns (address) {
        return buyer;
    }

    function getState() public view returns (contractState) {
        return state;
    }

    function setState(contractState _state) public {
        state = _state;
    }

    fallback() onlyBuyer external payable {
        buyerDepositTimeStamp = block.timestamp;
    }

    // function cancel() onlyBuyer external returns (bool) {
    //     (bool success, ) = address(this).call{value:address(this).balance}('');
    //     require(success, 'Could not transfer funds to escrow contract');
    //     return true;
    // }

}

// Author: Etienne Cellier-Clarke