/**
 *Submitted for verification at Etherscan.io on 2020-11-17
*/

pragma solidity 0.7.4;
// SPDX-License-Identifier: GPL-3.0-or-later
contract PrenupRegistry {
    uint256 prenupCount = prenups.length;
    string[] public prenups;
    event RecordPrenup(address indexed recorder, string indexed prenup);
    
    function recordPrenup(string calldata prenup) external {
        prenups.push(prenup);
        emit RecordPrenup(msg.sender, prenup);
    }
}