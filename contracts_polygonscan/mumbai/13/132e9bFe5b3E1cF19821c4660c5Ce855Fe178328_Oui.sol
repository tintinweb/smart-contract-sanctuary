//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Oui {

    uint256 OuiVar = 69;

    function get () view external returns (uint256) { return OuiVar; }
}