// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;

import "./2_character.sol";
import "./3_weapon.sol";

contract Player is Character, Weapon {
    string[] public defeatedPlayers;    
    string wasDefeated;
    uint public level;
    uint public points;

    modifier onlyOwnerIsAlive {
        require(msg.sender == owner, "You're not the owner");
        require(health > 0, "You're dead");
        _;
    }

    modifier onlyHasPoints {
        require(points > 0, "You have no points");
        _;
    }

    constructor(string memory _name, string memory _race, string memory _class, string memory _weapon_name) {
        damage = 10;
        health = 100;
        level = 1;
        points = 0;
        name = _name;
        race = _race;
        class = _class;
        weapon_name = _weapon_name;
        wasDefeated = "was not defeated";
        owner = msg.sender;
    }

    function setHealth(uint8 _damage) external override {
        if (health <= _damage) {
            health = 0;
            wasDefeated = Player(msg.sender).name();
        } else {
            health -= _damage;
        }
    }

    function attack(address enemy_address) public onlyOwnerIsAlive {
        require(Player(enemy_address).health() > 0, "The player is dead");
        Player(enemy_address).setHealth(damage);
        if (Player(enemy_address).health() == 0) {
            ++level;
            points += 5;
            defeatedPlayers.push(Player(enemy_address).name());
        }
    }

    function cure() public onlyOwnerIsAlive onlyHasPoints {
        health += 5;
        --points;
    }

    function improveAttack() public onlyOwnerIsAlive onlyHasPoints {
        ++damage;
        --points;
    }

    function getDefeatedPlayer() public view returns(string[] memory) {
        return defeatedPlayers;
    }
}