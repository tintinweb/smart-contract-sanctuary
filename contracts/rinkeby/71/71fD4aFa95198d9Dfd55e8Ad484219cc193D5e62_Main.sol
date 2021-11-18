// SPDX-License-Identifier: None

pragma solidity ^0.8.6;

interface ISecondary {
    function doEmit() external;
}

contract Main {
    event MainEvent();

    function callSecondary(address contract_) external {
        emit MainEvent();

        ISecondary(contract_).doEmit();
    }
}