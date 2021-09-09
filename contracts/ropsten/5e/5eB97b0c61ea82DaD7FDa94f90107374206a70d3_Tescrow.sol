/**
 *Submitted for verification at Etherscan.io on 2021-09-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Tescrow {

    // Initialising variables
    address payable public buyer;
    address payable public seller;
    address payable contractOwner;

    uint256 fee;

    // Create an enum which defines what states the contract can be in
    enum contractState{AWAITING_PARTIES,AWAITING_BUYER_PAYMENT}

    // Initial state of contract
    contractState public state = contractState.AWAITING_PARTIES;

    // AWAITING_PARTIES
    // AWAITING_BUYER_PAYMENT

    constructor() {

        // Set contract owner when deployed to blockchain
        contractOwner = payable(msg.sender);
    }

    // Define parties within contract
    function set_parties(address payable _seller, address payable _buyer) public {

        // Check contract is in initial state
        require(state==contractState.AWAITING_PARTIES,'Parties have already been defined within this contract');

        // Define seller and buyer
        seller = _seller;
        buyer = _buyer;

        // Update contract state
        state = contractState.AWAITING_BUYER_PAYMENT;
    }

    // Buyer sets contract value by depositing ether
    function buyer_deposit() external payable {
        // Check contract is in state where buyer must deposit ether
        require(state == contractState.AWAITING_BUYER_PAYMENT,'Only avaiable when buyer has been defined and funds have not yet been deposited within this contract');
        // Check it is the defined buyer depositing ether
        require(msg.sender == buyer,'For the buyer only');
    }

    // Gets current value of contract
    function get_balance() public view returns (uint256) {
        return address(this).balance;
    }

}