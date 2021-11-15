// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.3;

contract ImplV0 {
    uint256 public someVar = 111;

    function setVar(uint256 _newValue) public {
        someVar = _newValue;
    }
}

