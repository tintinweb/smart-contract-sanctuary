// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Trust {
    struct Beneficiary {
        uint256 amount;
        uint256 releaseDate;
        bool paid;
    }
    mapping(address => Beneficiary) public beneficiaries;
    address public grantor;

    constructor() {
        grantor = msg.sender;
    }

    function addBeneficiary(address beneficiary, uint256 timeUntilRelease)
        external
        payable
    {
        require(
            msg.sender == grantor,
            "Only the grantor of this trust can add a beneficiary!"
        );
        require(
            beneficiaries[beneficiary].amount == 0,
            "You've already added this beneficiary...use a different address!"
        );
        beneficiaries[beneficiary] = Beneficiary(
            msg.value,
            block.timestamp + timeUntilRelease,
            false
        );
    }

    function withdrawFunds() external {
        Beneficiary storage beneficiary = beneficiaries[msg.sender];
        require(
            beneficiary.releaseDate <= block.timestamp,
            "You can't withdraw until your release date"
        );
        require(
            beneficiary.amount > 0,
            "Only a beneficiary can withdraw funds from this trust"
        );
        require(
            beneficiary.paid == false,
            "You've already withdrew your funds!"
        );
        beneficiary.paid = true;
        payable(msg.sender).transfer(beneficiary.amount);
    }
}