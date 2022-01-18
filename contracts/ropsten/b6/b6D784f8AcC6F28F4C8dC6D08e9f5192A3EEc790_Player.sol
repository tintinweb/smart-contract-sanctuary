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

    modifier hasPoints()
    {
        require(points > 0);
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

    function attack(address otherPlayerAddr) public onlyOwner returns(string memory)
    {
        if (health == 0)
        {
            return "You are dead";
        }
        Player otherPlayer = Player(otherPlayerAddr);
        if (otherPlayer.health() == 0)
        {
            return "The player is dead";
        }
        otherPlayer.setHealth(weaponAttack, name);
        if (otherPlayer.health() == 0)
        {
            ++level;
            points += 5;
            defeatedPlayers.push(otherPlayer.name());
        }
        return "OK";
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
    }

    function improveAttack() public onlyOwner hasPoints
    {
        ++weaponAttack;
        --points;
    }

    function getDefeatedPlayers() public view returns(string[] memory)
    {
        return defeatedPlayers;
    }
}