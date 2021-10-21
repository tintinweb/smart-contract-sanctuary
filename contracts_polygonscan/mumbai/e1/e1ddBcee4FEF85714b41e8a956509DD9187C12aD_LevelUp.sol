// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract LevelUp {
    struct Player {
        uint256 lvl;
        uint256 xp;
    }

    mapping(address => Player) players;

    constructor() {}

    function doTask() public {
        _addXp(6541);
    }

    function _addXp(uint256 xp) private {
        uint256 playerLvl = players[msg.sender].lvl;
        uint256 playerXp = players[msg.sender].xp + xp;
        uint256 xpToNextLevel = _nextLvlXp(playerLvl);

        while (playerXp >= xpToNextLevel) {
            playerLvl += 1;
            playerXp -= xpToNextLevel;
            xpToNextLevel = _nextLvlXp(playerLvl);
        }

        players[msg.sender].lvl = playerLvl;
        players[msg.sender].xp = playerXp;
    }

    function _nextLvlXp(uint256 level) private pure returns (uint256) {
        return (((161803399 * ((level + 1) ** 3)) / 500000000) + 1) * 271828 / 1000;
    }
}