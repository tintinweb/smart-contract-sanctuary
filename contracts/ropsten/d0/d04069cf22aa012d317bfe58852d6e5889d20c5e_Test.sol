// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import './test2.sol';

contract Test is Test2 {
    function two() pure external returns(uint256) {
        return one() + one();
    }
}