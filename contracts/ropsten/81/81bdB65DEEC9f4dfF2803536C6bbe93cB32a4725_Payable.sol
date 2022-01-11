/**
 *Submitted for verification at Etherscan.io on 2022-01-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Payable {
    address owner;
    struct Refund {
        address toAddress;
        uint refundAmount;
    }
    mapping(address => uint) accounts;
    mapping(address => Refund) refundable;

    // this is where we send the tax on all transactions
    address taxable;
    uint tax_rate = 2;

    constructor() payable {
        owner = msg.sender;
        taxable = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function authorizeTransaction(address _to) public payable {
        // now we add a value to a specific payable address and refundable address
        uint amount = msg.value;

        accounts[_to] += amount;
        refundable[msg.sender] = Refund(_to, refundable[msg.sender].refundAmount + amount);
    }

    function captureTransaction(uint _amount) public payable {
        // convert amount to wei
        _amount *= 1e18;

        // validate that the amount associated with the specific account matches
        require(accounts[msg.sender] >= _amount, "Not enough Funds");

        // every time we deposit into the account we tax the transaction 2%
        uint tax_amount = _amount * tax_rate / 100;
        uint amount = _amount - tax_amount;

        // tax the value on transaction
        (bool taxed, ) = taxable.call{value: tax_amount}("");
        require(taxed, "Failed to tax deposit");

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Failed to capture funds");

        // after capturing the transactions let's remove the funds from the mapping
        accounts[msg.sender] -= _amount;
    }

    function refundTransaction(address payable _to, uint _amount) public {
        // convert amount to wei
        _amount *= 1e18;

        // validate that the refunded has enough to refund
        require(refundable[_to].refundAmount >= _amount, "Not enough Funds");

        // only the payee or payer can process a refund
        require(msg.sender == _to || msg.sender == refundable[_to].toAddress, "Invalid contract address");

        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Failed to refund value");

        // after the refund remove value from mapping  
        refundable[_to].refundAmount -= _amount;

        // also decrement the to address
        accounts[refundable[_to].toAddress] -= _amount;
    }

    function getBalance() public view returns (uint) {
        return accounts[msg.sender] / 1e18;
    }

    function getRefundAmount() public view returns (uint) {
        return refundable[msg.sender].refundAmount / 1e18;
    }

    function getContractBalance() public onlyOwner view returns (uint) {
        return address(this).balance / 1e18;
    }

    function setTaxRate(uint _rate) public onlyOwner {
        tax_rate = _rate;
    }
}