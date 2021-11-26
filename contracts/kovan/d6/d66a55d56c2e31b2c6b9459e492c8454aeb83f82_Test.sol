/**
 *Submitted for verification at Etherscan.io on 2021-11-26
*/

pragma solidity ^0.6.12;

// SPDX-License-Identifier: Unlicensed

contract Test {

    bool myBoolean = false;

    function setMyBoolean(bool newBool) public returns(bool) {
        myBoolean = newBool;
        return true;
    }
}