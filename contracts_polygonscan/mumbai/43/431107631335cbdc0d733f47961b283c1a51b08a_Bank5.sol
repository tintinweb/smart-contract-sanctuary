/**
 *Submitted for verification at polygonscan.com on 2022-01-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Bank5 {
    // Payable address can receive Ether
    address payable public owner;
    

    // Payable constructor can receive Ether
    constructor() payable {
        owner = payable(msg.sender);
    }

    // Function to deposit Ether into this contract.
    // Call this function along with some Ether.
    // The balance of this contract will be automatically updated.
    function deposit() public payable {}

    // Call this function along with some Ether.
    // The function will throw an error since this function is not payable.
    function notPayable() public {}

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    // Function to withdraw all Ether from this contract.
    function withdrawCryptoTo(address payable _to) public {
        _to.transfer(getBalance());
    }
    



    // Function to transfer Ether from this contract to address from input
    function transfer(address payable _to, uint _amount) public {
        // Note that "to" is declared as payable
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Failed to send Ether");
    }
}