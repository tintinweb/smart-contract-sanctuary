/**
 *Submitted for verification at BscScan.com on 2022-01-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract TeamPepa {
    uint256 public idCount;

    constructor() {
        idCount = 0;
    }

    struct Team {
        uint256 id;
        string name;
        string skill;
    }

    mapping(uint256 => Team) team;

    function joinTeam(string calldata _name, string calldata _skill) public {
        team[idCount] = Team(idCount, _name, _skill);
        idCount++;
    }

    function getTeam() public view returns (string[] memory, string[] memory) {
        string[] memory name = new string[](idCount);
        string[] memory skill = new string[](idCount);

        for (uint256 i = 0; i < idCount; i++) {
            Team storage people = team[i];
            name[i] = people.name;
            skill[i] = people.skill;
        }

        return (name, skill);
    }
}