// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract WebacyMembership {

    uint8 public version;

    mapping(address => bool) public memberbershipPaid;

    constructor(uint8 _version) {
        version = _version;
    }

    function payMembership() external {
        memberbershipPaid[msg.sender] = true;
    }

    function unpayMembership() external {
        memberbershipPaid[msg.sender] = false;
    }

}