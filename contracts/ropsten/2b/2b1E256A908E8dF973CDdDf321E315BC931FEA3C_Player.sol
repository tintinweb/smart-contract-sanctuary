// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;

import "./2_character.sol";
import "./3_weapon.sol";

contract Player is Character, Weapon
{
    string[] defeatedPlayers;
    string public wasDefeated;
    uint8 public level;
    uint8 public score;

    constructor(string memory _character_name, string memory _race, string memory _class, string memory _weapon_name)
    {
        owner = msg.sender;
        character_name = _character_name;
        race = _race;
        class = _class;
        health = 100;
        weapon_name = _weapon_name;
        damage = 10;
        wasDefeated = "was not defeated";
        level = 1;
        score = 0;
    }

    function attack(address player) public
    {
        require(msg.sender == owner, "You are not the owner");
        require(health > 0, "You are dead");
        require(Player(player).health() > 0, "The player is dead");

        Player(player).setHealth(damage);

        if (Player(player).health() == 0)
        {
            defeatedPlayers.push(Player(player).character_name());
            ++level;
            score += 5;
        }
    }

    function cure() public
    {
        require(msg.sender == owner, "You are not the owner");
        require(score > 0, "Your score is zero");

        health += 5;
        --score;
    }

    function improveAttack() public
    {
        require(msg.sender == owner, "You are not the owner");
        require(score > 0, "Your score is zero");

        ++damage;
        --score;
    }

    function getdefeatedPlayers() public view returns(string[] memory _defeatedPlayers)
    {
        return defeatedPlayers;
    }

    function setHealth(uint8 damage) external override
    {
        if (damage >= health)
        {
            health = 0;
            wasDefeated = Player(msg.sender).character_name();
        }
        else
            health -= damage;
    }
}