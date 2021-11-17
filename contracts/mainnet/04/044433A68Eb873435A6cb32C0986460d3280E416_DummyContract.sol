// SPDX-License-Identifier: MIT
// Smart Contract Written by: Ian Olson

pragma solidity ^0.8.4;
pragma abicoder v2;

contract DummyContract {

    // ---
    // Properties
    // ---
    address private _payoutAddress;

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
        _payoutAddress = msg.sender;
        isAdmin[msg.sender] = true; // imnotArt Deployer Address
    }

    // ---
    // Receive Payments
    // ---

    // @dev Receive ETH - to test out existing .transfer() methods calling a better proxy contract
    // @author Ian Olson
    receive() payable external {
        require(msg.value > 0, "Must send more than 0.");
        payable(_payoutAddress).transfer(msg.value);
    }

    // ---
    // Get Functions
    // ---

    // @dev Get the payout address
    // @author Ian Olson
    function payoutAddress() public view returns (address) {
        return _payoutAddress;
    }

    // ---
    // Update Functions
    // ---

    // @dev Update the payout address.
    // @author Ian Olson
    function updatePayoutAddress(address payoutAddress) public onlyAdmin {
        _payoutAddress = payoutAddress;
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