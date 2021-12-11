// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;

import "./2_character.sol";
import "./3_weapon.sol";

contract Player is Character, Weapon{
    int public level;
    int public score;
    constructor(string memory _name, string memory _race, string memory _class, string memory _name_of_weapon) {
        owner = msg.sender;
        name = _name;
        race = _race;
        class = _class;
        name_of_weapon = _name_of_weapon;
        health = 100;
        damage = 10;
        level = 1;
        score = 0;
    }

    function attack(address _atacked_player) public {
        require(msg.sender == owner, "You are not an owner");
        require(health >= 0, "You are dead");
        require(Player(_atacked_player).health() > 0, "He is already dead");
        Player player_attack = Player(_atacked_player);
        player_attack.setHealth(damage);
        if (player_attack.health() == 0) {
            level += 1;
            score += 5;
        }
    }
    function cure() public {
        require(msg.sender == owner, "You are not an owner");
        require(score >= 1, "You don't have enough score");
        health += 5;
        score -= 1;
    }
    function improveAttack() public {
        require(msg.sender == owner, "You are not an owner");
        require(score >= 1, "You don't have enough score");
        damage += 1;
        score -= 1;
    }
}