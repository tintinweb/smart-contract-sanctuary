/**
 *Submitted for verification at polygonscan.com on 2022-01-09
*/

// SPDX-License-Identifier: MIT


// Coffe Token AirDrop Official smart contract / Date: 10th of January 2022


pragma solidity ^0.8.4;

contract CoffeToken_AirDrop {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}