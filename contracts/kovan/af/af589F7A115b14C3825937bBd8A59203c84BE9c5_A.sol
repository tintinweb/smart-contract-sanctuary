// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract A {
    B public b;

    constructor() public {
        b = new B();
    }
}

contract B {}

