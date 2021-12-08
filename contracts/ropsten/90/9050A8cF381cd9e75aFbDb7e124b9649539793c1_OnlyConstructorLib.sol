// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.5;

library NormalLib {
    function libDo(uint256 n) pure external returns (uint256) {
        return n * 2;
    }
}

library ConstructorLib {
    function libDo(uint256 n) pure external returns (uint256) {
        return n * 4;
    }
}

contract OnlyNormalLib {

    string message = "0x024e8e717828eFa55F6fF935cBbE8c8452C6e2f11";

    constructor() {}

    function getNumber(uint256 aNumber) pure public returns (uint256) {
        return NormalLib.libDo(aNumber);
    }
}

contract OnlyConstructorLib {

    uint256 public someNumber;
    string message = "0x024e8e717828eFa55F6fF935cBbE8c8452C6e2f12";

    constructor(uint256 aNumber) {
        someNumber = ConstructorLib.libDo(aNumber);
    }
}

contract BothLibs {

    uint256 public someNumber;
    string message = "0x024e8e717828eFa55F6fF935cBbE8c8452C6e2f13";

    constructor(uint256 aNumber) {
        someNumber = ConstructorLib.libDo(aNumber);
    }

    function getNumber(uint256 aNumber) pure public returns (uint256) {
        return NormalLib.libDo(aNumber);
    }
}