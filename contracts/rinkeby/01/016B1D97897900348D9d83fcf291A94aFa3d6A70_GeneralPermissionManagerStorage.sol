/**
 *Submitted for verification at Etherscan.io on 2021-12-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract GeneralPermissionManagerStorage {

    // Mapping used to hold the permissions on the modules provided to delegate, module add => delegate add => permission bytes32 => bool
    mapping (address => mapping (address => mapping (bytes32 => bool))) public perms;
    // Mapping hold the delagate details
    mapping (address => bytes32) public delegateDetails;
    // Array to track all delegates
    address[] public allDelegates;

}