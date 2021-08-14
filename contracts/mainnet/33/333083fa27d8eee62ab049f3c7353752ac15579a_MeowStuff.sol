/**
 *Submitted for verification at Etherscan.io on 2021-08-14
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.7;

contract MeowStuff {
    address constant meow = 0x650F44eD6F1FE0E1417cb4b3115d52494B4D9b6D;
    address constant stuff = 0x18bf2741375678750cF3C0aE27777c537d6b224F;
    mapping(address => bool) public meowed;

    function meowStuff() external {
        /// @dev check caller mark ~~
        require(!meowed[msg.sender], "already meowed you sneaky cat");
        /// @dev check caller balance ~~
        (, bytes memory data) = meow.staticcall(abi.encodeWithSelector(0x70a08231, msg.sender));
        uint256 amount = abi.decode(data, (uint256));
        require(amount >= 1_000_000 ether, "meow too quiet");
        /// @dev transfer stuff to caller ~~
        (bool success, ) = stuff.call(abi.encodeWithSelector(0xa9059cbb, msg.sender, 10_000 ether));
        require(success, "tapped out");
        /// @dev mark caller so less sneaky biz ~~
        meowed[msg.sender] = true;
    }
}