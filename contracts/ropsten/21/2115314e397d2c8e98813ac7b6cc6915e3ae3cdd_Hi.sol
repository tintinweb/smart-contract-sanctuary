/**
 *Submitted for verification at Etherscan.io on 2021-11-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;
contract Hi{
    string public name;
    function set(string memory _name)public {
        name = _name;
    }
}