/**
 *Submitted for verification at Etherscan.io on 2021-09-22
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;
contract Minion {
    address immutable controller;
    constructor() {controller = msg.sender;}
    receive() external payable {}
    function attack(address target, uint256 value, bytes[] calldata orders) external {
        require(msg.sender == controller);
        for (uint256 i=0; i<orders.length; i++) {
            target.call{value: value}(orders[i]);
        }
    }
}