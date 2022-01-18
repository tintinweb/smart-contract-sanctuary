/**
 *Submitted for verification at polygonscan.com on 2022-01-17
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract React {
    uint256 public number;
    address public user;

    function setNumber(uint256 _number) public {
        number = _number;
    }

    function setUser(address _user) public {
        user = _user;
    }
}