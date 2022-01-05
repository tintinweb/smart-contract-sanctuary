/**
 *Submitted for verification at Etherscan.io on 2022-01-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

contract Company {

    address public owner;
    address[] public employees;
    mapping(address => bool) public isEmployee;
    mapping(address => bool) public hasWithdrawedSalary;

    constructor() payable {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can send salaries to employees.");
        _;
    }

    function registerEmployee(address employee) external onlyOwner {
        employees.push(employee);
        isEmployee[employee] = true;
        hasWithdrawedSalary[employee] = false;
    }


    /* === vulnerable functions === */

    // 1. DoS vulnerability
    function sendSalaries() external onlyOwner {
        for (uint256 i=0;i<employees.length;i++) {
            payable(employees[i]).transfer(0.1 ether);
        }
    }

    // 2. Reentrancy vulnerability
    function withdrawSalary() external {
        require(isEmployee[msg.sender], "Only employees can withdraw salary.");
        require(!hasWithdrawedSalary[msg.sender], "Employee has already withdrawn the salary.");
        payable(msg.sender).call{value: 0.1 ether}("");
        hasWithdrawedSalary[msg.sender] = true;
    }

}