/**
 *Submitted for verification at Etherscan.io on 2020-11-17
*/

pragma solidity 0.7.4;
// SPDX-License-Identifier: GPL-3.0-or-later
contract PrenupRegistry {
    string[] public prenups;
    event RegisterPrenup(address indexed caller, string indexed prenup);
    function registerPrenup(string calldata prenup) external {
        prenups.push(prenup);
        emit RegisterPrenup(msg.sender, prenup);
    }
}