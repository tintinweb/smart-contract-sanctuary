/**
 *Submitted for verification at Etherscan.io on 2021-09-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

contract A {
    uint256 public i;

    constructor() public {
        i = 0;
    }

    function increment() external {
        i = i + 1;
    }
}

contract B {
    A public contractA;

    constructor(A _contractA) public {
        contractA = _contractA;
    }

    function useA() external {
        contractA.increment();
        contractA.increment();
        contractA.increment();
        contractA.increment();
        contractA.increment();
    }

    function useA_() external {
        A _contractA = contractA;
        _contractA.increment();
        _contractA.increment();
        _contractA.increment();
        _contractA.increment();
        _contractA.increment();
    }
}