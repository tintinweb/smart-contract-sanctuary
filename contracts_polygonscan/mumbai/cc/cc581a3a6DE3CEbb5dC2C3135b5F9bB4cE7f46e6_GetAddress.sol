/**
 *Submitted for verification at polygonscan.com on 2022-01-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract GetAddress {
    address immutable private _ownaddress;

    constructor() {
        _ownaddress = address(this);
    }

    function getaddress() public view returns (address) {
        return _ownaddress;
    }
}