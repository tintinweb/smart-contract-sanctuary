/**
 *Submitted for verification at BscScan.com on 2021-10-08
*/

// File: contracts/Test.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

contract Test {
    address public wantAddress;
    address public crabFarmAddress;

    uint256 public balance;
    
     constructor(
        address _wantAddress,
        address _crabFarmAddress
    ) public {
        wantAddress = _wantAddress;
        crabFarmAddress = _crabFarmAddress;
    }

    function setBalance(uint256 _bal) public {
        balance = _bal;
    } 
}