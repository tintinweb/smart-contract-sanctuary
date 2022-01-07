// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract WebacyProxy {
    bool public isUnlock = true;

    function lockContract() external {
        isUnlock = false;
    }

    function unlockContract() external {
        isUnlock = true;
    }
}