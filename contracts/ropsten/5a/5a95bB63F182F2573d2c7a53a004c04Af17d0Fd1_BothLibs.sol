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

    string message = "0x4C74BFb12AFF667D2c31e6E88678E14503bb510A1";

    constructor() {}

    function getNumber(uint256 aNumber) pure public returns (uint256) {
        return NormalLib.libDo(aNumber);
    }
}

contract OnlyConstructorLib {

    uint256 public someNumber;
    string message = "0x4C74BFb12AFF667D2c31e6E88678E14503bb510A2";

    constructor(uint256 aNumber) {
        someNumber = ConstructorLib.libDo(aNumber);
    }
}

contract BothLibs {

    uint256 public someNumber;
    string message = "0x4C74BFb12AFF667D2c31e6E88678E14503bb510A3";

    constructor(uint256 aNumber) {
        someNumber = ConstructorLib.libDo(aNumber);
    }

    function getNumber(uint256 aNumber) pure public returns (uint256) {
        return NormalLib.libDo(aNumber);
    }
}