/**
 *Submitted for verification at Etherscan.io on 2022-01-14
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
    uint tax_rate = 200;

    // events of the contract
    event AuthEv(address _from, address _to, uint _value);
    event CaptureEv(address _to, uint _value, uint _tax, uint _taxedamount);
    event RefundEv(address _initiator, address _to, uint _value);
    event TaxChangeEv(uint _oldvalue, uint _newvalue);

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

        // emit event
        emit AuthEv(msg.sender, _to, amount);
    }

    function captureTransaction(uint _amount) public payable {
        // validate that the amount associated with the specific account matches
        require(accounts[msg.sender] >= _amount, "Not enough Funds");

        // every time we deposit into the account we tax the transaction 2%
        uint tax_amount = _amount * tax_rate / 10000;
        uint amount = _amount - tax_amount;

        // tax the value on transaction
        (bool taxed, ) = taxable.call{value: tax_amount}("");
        require(taxed, "Failed to tax deposit");

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Failed to capture funds");

        // after capturing the transactions let's remove the funds from the mapping
        accounts[msg.sender] -= _amount;

        // emit event
        emit CaptureEv(msg.sender, _amount, tax_amount, amount);
    }

    function refundMyTransaction() public {
        uint _amount = refundable[msg.sender].refundAmount;
        // only the payee or payer can process a refund
        require(refundable[msg.sender].refundAmount == 0, "Nothing to refund");

        (bool success, ) = msg.sender.call{value: _amount }("");
        require(success, "Failed to refund value");

        // after the refund remove value from mapping  
        refundable[msg.sender].refundAmount -= _amount;

        // also decrement the to address
        accounts[refundable[msg.sender].toAddress] -= _amount;

        //emit event
        emit RefundEv(msg.sender, msg.sender, _amount);
    }

    function refundTransaction(address payable _to, uint _amount) public {
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

        //emit event
        emit RefundEv(msg.sender, _to, _amount);
    }

    function getBalance() public view returns (uint) {
        return accounts[msg.sender];
    }

    function getRefundAmount() public view returns (uint) {
        return refundable[msg.sender].refundAmount;
    }

    function getContractBalance() public onlyOwner view returns (uint) {
        return address(this).balance;
    }

    function setTaxRate(uint _rate) public onlyOwner {
        uint _old_rate = tax_rate;
        tax_rate = _rate * 100;

        emit TaxChangeEv(_old_rate / 100, tax_rate / 100);
    }
}