/**
 *Submitted for verification at Etherscan.io on 2022-01-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Defiantium {
    mapping(string => uint) debts;
    function addDebtToName(string memory _name, uint _owed) public {
        debts[_name] += _owed;
    }
    function removeDebtFromName(string memory _name, uint _owed) public {
        require(debts[_name] > 0, "Can't remove debt from 0 owed");
        require(debts[_name] >= _owed, "Can't make debt go into the negatives");
        debts[_name] -= _owed;
    }
    function getDebt(string memory _name) public view returns (uint) {
        return debts[_name];
    }
}