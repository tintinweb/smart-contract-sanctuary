// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;

import "./2_character.sol";
import "./3_weapon.sol";

contract Player is Character, Weapon
{
    uint public level;
    uint public points;
    string public wasDefeated;
    string[] defeatedPlayers;

    event attackProtocol(address, address, uint8, uint8);
    event defeatsProtocol(address, address, uint, uint);
    event cureProtocol(uint8, uint);
    event attackImprovementProtocol(uint8, uint);

    modifier hasPoints()
    {
        require(points > 0, "Don't have any points");
        _;
    }

    constructor(string memory name_, string memory race_, string memory class_, string memory weaponName_)
    {
        name = name_;
        race = race_;
        class = class_;
        weaponName = weaponName_;
        health = 100;
        weaponAttack = 10;
        level = 1;
        points = 0;

        wasDefeated = "Was not defeated";
    }

    function callAttackProtocol(address attacker, address defender, uint8 damage, uint8 leftHealth) public
    {
        emit attackProtocol(attacker, defender, damage, leftHealth);
    }

    function callDefeatsProtocol(address winner, address loser, uint newLevel, uint newPoints) public
    {
        emit defeatsProtocol(winner, loser, newLevel, newPoints);
    }

    function attack(address otherPlayerAddr) public onlyOwner
    {
        require(health > 0, "You are dead");
        Player otherPlayer = Player(otherPlayerAddr);
        require(otherPlayer.health() > 0, "The player is dead");
        otherPlayer.setHealth(weaponAttack, name);
        callAttackProtocol(address(this), otherPlayerAddr, weaponAttack, otherPlayer.health());
        otherPlayer.callAttackProtocol(address(this), otherPlayerAddr, weaponAttack, otherPlayer.health());
        if (otherPlayer.health() == 0)
        {
            ++level;
            points += 5;
            defeatedPlayers.push(otherPlayer.name());

            callDefeatsProtocol(address(this), otherPlayerAddr, level, points);
            otherPlayer.callDefeatsProtocol(address(this), otherPlayerAddr, level, points);
        }
    }

    function setHealth(uint8 damage, string calldata damager) public
    {
        if (health <= damage)
        {
            health = 0;
            wasDefeated = damager;
        }
        else
        {
            health -= damage;
        }
    } 

    function cure() public onlyOwner hasPoints
    {
        health += 5;
        --points;
        emit cureProtocol(health, points);
    }

    function improveAttack() public onlyOwner hasPoints
    {
        ++weaponAttack;
        --points;
        emit attackImprovementProtocol(weaponAttack, points);
    }

    function getDefeatedPlayers() public view returns(string[] memory)
    {
        return defeatedPlayers;
    }
}