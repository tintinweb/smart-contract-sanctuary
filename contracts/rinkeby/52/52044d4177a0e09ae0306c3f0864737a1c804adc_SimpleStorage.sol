/**
 *Submitted for verification at Etherscan.io on 2021-12-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

contract SimpleStorage {
    
    uint256 number;

    struct Employee {
        uint256 id;
        string employeeName;
    }

    Employee[] public employees;
    mapping(uint256 => string) public idToName;

    function addEmployee(uint256 _id, string memory _name) public {
        employees.push(Employee(_id, _name));
        idToName[_id] = _name;
    } 
}