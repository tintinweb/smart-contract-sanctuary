/**
 *Submitted for verification at Etherscan.io on 2021-12-13
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6 <0.9.0;

contract Bank {

    mapping(address => uint256) public addressToAmountFunded;
    address[] public depositors;

    function deposit() public payable {
        addressToAmountFunded[msg.sender] += msg.value;
        depositors.push(msg.sender);
    }

    modifier onlyDepositor {
        require(addressToAmountFunded[msg.sender] > 0);
        _;
    }

    function withdraw(uint ethAmount) payable onlyDepositor public {
        ethAmount = ethAmount * 1000000000000000000;
        require(ethAmount <= addressToAmountFunded[msg.sender], "not enough balance");
        msg.sender.transfer(ethAmount);
        addressToAmountFunded[msg.sender] -= ethAmount;
    }

    function bankTransfer(uint ethAmount, address recipient) payable onlyDepositor public {
        ethAmount = ethAmount * 1000000000000000000;
        require(ethAmount <= addressToAmountFunded[msg.sender], "not enough balance");
        addressToAmountFunded[msg.sender] -= ethAmount;
        addressToAmountFunded[recipient] += ethAmount;
    }
}