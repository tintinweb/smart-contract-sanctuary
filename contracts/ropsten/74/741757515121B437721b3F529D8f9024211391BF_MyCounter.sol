// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.7;

import "./Counter.sol";

contract MyCounter {
    function incrementCounter(address _counter) external {
        ICounter(_counter).increment();
    }

    function getCount(address _counter) external view returns (uint) {
        return ICounter(_counter).count();
    }
}