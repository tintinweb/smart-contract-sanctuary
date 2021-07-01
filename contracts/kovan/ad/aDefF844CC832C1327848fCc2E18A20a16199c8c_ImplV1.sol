// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.3;

import "./ImplV0.sol";

contract ImplV1 is ImplV0 {
    function doubleVar(uint256 _newValue) public {
        someVar = _newValue * 2;
    }
}