/**
 *Submitted for verification at Etherscan.io on 2021-08-13
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.7;

contract MeowStuff {
    address constant meow = 0x650F44eD6F1FE0E1417cb4b3115d52494B4D9b6D;
    address constant stuff = 0x596533397B1Beee249080FC4fDA9166d4032b5Da;
    mapping(address => bool) public meowed;

    function meowStuff() external {
        require(!meowed[msg.sender], "already claimed you sneaky cat");
        /// @dev transfer stuff to caller ~~
        meow.call(abi.encodeWithSelector(0xa9059cbb, msg.sender, 10_000 ether));
        /// @dev mark claim so less sneaky biz ~~
        meowed[msg.sender] = true;
    }
}