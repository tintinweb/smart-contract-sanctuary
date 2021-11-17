// SPDX-License-Identifier: MIT
// Smart Contract Written by: Ian Olson

pragma solidity ^0.8.4;
pragma abicoder v2;

contract ProxyPayout {

    // ---
    // Properties
    // ---
    address public payoutAddress;

    // ---
    // Mappings
    // ---
    mapping(address => bool) isAdmin;

    // ---
    // Modifiers
    // ---
    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Only admins.");
        _;
    }

    // ---
    // Constructor
    // ---

    constructor() {
        payoutAddress = address(0x711c0385795624A338E0399863dfdad4523C46b3); // Brendan Fernandes Gnosis Safe

        isAdmin[msg.sender] = true; // imnotArt Deployer Address
        isAdmin[address(0x12b66baFc99D351f7e24874B3e52B1889641D3f3)] = true; // imnotArt Gnosis Safe
        isAdmin[payoutAddress] = true; // Brendan Fernandes Address
    }

    // ---
    // Receive Payments
    // ---

    // @dev Royalty contract can receive ETH via transfer.
    // @author Ian Olson
    receive() payable external {
        (bool success, ) = payable(payoutAddress).call{value: msg.value}("");
        require(success, "Transfer failed.");
    }

    // ---
    // Update Functions
    // ---

    // @dev Update the payout address.
    // @author Ian Olson
    function updatePayoutAddress(address _payoutAddress) public onlyAdmin {
        payoutAddress = _payoutAddress;
    }

    // ---
    // Withdraw
    // ---

    // @dev Withdraw the balance of the contract.
    // @author Ian Olson
    function withdraw() public onlyAdmin {
        uint256 amount = address(this).balance;
        require(amount > 0, "Contract balance empty.");
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed.");
    }
}