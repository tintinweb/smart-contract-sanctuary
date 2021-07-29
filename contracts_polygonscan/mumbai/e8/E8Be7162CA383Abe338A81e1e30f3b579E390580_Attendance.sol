/**
 *Submitted for verification at polygonscan.com on 2021-07-29
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract Attendance {
    address public owner;
    mapping(address => bool) public whitelist;

    enum Status {checkIn, checkOut }

    struct Employee {
        bool exists;
        string employeeName;
        string designation;
        uint256 addedAt;
        Status status;
    }

    mapping(uint32 => Employee) public employees;

    event AttendanceLog(uint32 indexed employeeId, bool checkin, uint256 timestamp);

    constructor() {
        owner = msg.sender;
        whitelist[owner] = true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner has access");
        _;
    }

    modifier onlyWhiteList() {
        require(whitelist[msg.sender], "Only private whitelist as access");
        _;
    }

    function addAddressToWhitelist(address newAddress) public onlyOwner {
        whitelist[newAddress] = true;
    }

    function removeAddressFromWhitelist(address newAddress) public onlyOwner {
        require(
            newAddress != owner,
            "Owner cannot remove self. Transfer ownership and try again"
        );
        whitelist[newAddress] = false;
    }

    function transferContractOwnership(address newAddress) public onlyOwner {
        owner = newAddress;
    }

    function addEmployee(
        uint32 employeeId,
        string memory employeeName,
        string memory designation
    ) public onlyWhiteList {
        require(!employees[employeeId].exists, "Employee already exists");

        employees[employeeId].exists = true;
        employees[employeeId].employeeName = employeeName;
        employees[employeeId].designation = designation;
        employees[employeeId].addedAt = block.timestamp;
        employees[employeeId].status = Status.checkOut;
    }

    function recordAttendance(uint32 employeeId, bool checkin)
        public
        onlyWhiteList
    {
        require(employees[employeeId].exists, "Employee should exist");
        if (checkin) {
            require(employees[employeeId].status == Status.checkOut , "Employee should be in checkout status to checkin");
            employees[employeeId].status = Status.checkIn;
        } else {
            require(employees[employeeId].status == Status.checkIn , "Employee should be in checkin status to checkout");
            employees[employeeId].status = Status.checkOut;
        }
        
        emit AttendanceLog(employeeId, checkin, block.timestamp);
    }

    function destroy() public onlyOwner {
        address payable addr = payable(address(owner));
        selfdestruct(addr);
    }
}