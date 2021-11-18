// SPDX-License-Identifier: None

pragma solidity ^0.8.6;

contract Secondary {

    event SecondaryEvent();

    function doEmit() external {
        emit SecondaryEvent();
    }
}