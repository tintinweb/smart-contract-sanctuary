/**
 *Submitted for verification at Etherscan.io on 2022-01-20
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract DepositTokens {
    // Payable address can receive Ether
    address payable public owner;
    address payable public bondBuyers;
    address payable public syntheticStocksBuyers;


    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);


    // Payable constructor can receive Ether
    constructor() payable {
        owner = payable(msg.sender);
    }

    // Function to deposit Ether into this contract.
    // Call this function along with some Ether.
    // The balance of this contract will be automatically updated.
    function depositIt() public payable {
    
    }

    //get balance from
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // Call this function along with some Ether.
    // The function will throw an error since this function is not payable.
    function notPayableTo() public {}

    // Function to withdraw all Ether from this contract.
    function withdrawIt() public {
        // get the amount of Ether stored in this contract
        uint amount = address(this).balance;

        // send all Ether to owner
        // Owner can receive Ether since the address of owner is payable
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Failed to send Ether");
    
    }

    // Function to transfer Ether from this contract to address from input
    function transferIt(address payable _to, uint _amount) public {
        // Note that "to" is declared as payable
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Failed to send Ether");
    }
}