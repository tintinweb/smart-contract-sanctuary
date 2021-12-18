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

    event playerCured(address player_address, string player_name, uint8 current_health, uint points_left);
    event attackImproved(address player_address, string player_name, uint8 current_damage, uint points_left);
    event playerAttacked(address atacker_address, string attacker_name, address victim_address, string victim_name, uint8 damage, uint8 health_left);
    event playerDefeated(address atacker_address, string attacker_name, address victim_address, string victim_name, uint current_level, uint current_points);

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
        emit playerAttacked(address(this), name, enemy_address, Player(enemy_address).name(), damage, Player(enemy_address).health());
        if (Player(enemy_address).health() == 0) {
            ++level;
            points += 5;
            defeatedPlayers.push(Player(enemy_address).name());
            emit playerDefeated(address(this), name, enemy_address, Player(enemy_address).name(), level, points);
        }
    }

    function cure() public onlyOwnerIsAlive onlyHasPoints {
        health += 5;
        --points;
        emit playerCured(address(this), name, health, points);
    }

    function improveAttack() public onlyOwnerIsAlive onlyHasPoints {
        ++damage;
        --points;
        emit attackImproved(address(this), name, damage, points);
    }

    function getDefeatedPlayer() public view returns(string[] memory) {
        return defeatedPlayers;
    }
}