// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.0;

import "./ArbSys.sol";

contract ArbGasTest {

    mapping(address => uint) myMapping;

    function giveMeStore() public returns (uint) {
        ArbSys arbSys = ArbSys(0x0000000000000000000000000000000000000064);
        return arbSys.getStorageGasAvailable();
    }
}