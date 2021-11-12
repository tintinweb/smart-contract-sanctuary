/**
 *Submitted for verification at BscScan.com on 2021-11-12
*/

// File: contracts/arcadia/game/APWarsTreasureHuntEventHandler.sol

// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.6.0;

contract APWarsTreasureHuntEventHandler {
    function onJoin(
        address _sender,
        address _player,
        uint256 _huntId,
        uint256 _worldId,
        uint256 _x,
        uint256 _y,
        uint256 _innerX,
        uint256 _innerY
    ) public {}

    function onDistributeReward(
        address _sender,
        address _player,
        uint256 _huntId,
        address _winner
    ) public {}
}