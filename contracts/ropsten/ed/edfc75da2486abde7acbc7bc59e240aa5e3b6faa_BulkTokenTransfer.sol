/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^ 0.7.0;

contract BulkTokenTransfer {
    /* This contract is still in beta. Use this contract at your own risk */

    // Public variable; owns this contract
    address public owner;

    // Event which stores details of each individual transfer
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);

    // Constructor which sets the public variable (owner) to the external account address who deployed this contract
    constructor() {
        owner = msg.sender;
    }

    // Modifier to ensure only the owner can perform certain function calls
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // Given 100 external account addresses and 100 corresponding amounts in wei; Perform 100 transfers (as internal tx)
    function bulkSendEth(address payable[100] memory addresses, uint256[100] memory amounts) public payable onlyOwner returns(bool success) {
        /* This contract is still in beta. Use this contract at your own risk */
        // transfer to each address
        for (uint8 iter = 0; iter < 100; iter++) {
            if((addresses[iter] != address(0)) && (amounts[iter] * 1 wei) != 0){
                addresses[iter].transfer(amounts[iter] * 1 wei);
                emit Transfer(msg.sender, addresses[iter], amounts[iter] * 1 wei);
            }
        }

        return true;
    }

    // Check balance of any external account
    function getbalance(address addr) public view returns(uint value) {
        /* This contract is still in beta. Use this contract at your own risk */
        return addr.balance;
    }

    // Allow the owner of the contract to withdraw any left over network tokens
    function withdrawEther(address payable addr, uint amount) public onlyOwner returns(bool success) {
        /* This contract is still in beta. Use this contract at your own risk */
        addr.transfer(amount * 1 wei);
        return true;
    }

    // Allow the owner to destroy the contract and subsequently receive any left over network tokens
    function destroy(address payable _to) public onlyOwner {
        /* This contract is still in beta. Use this contract at your own risk */
        selfdestruct(_to);
    }
}