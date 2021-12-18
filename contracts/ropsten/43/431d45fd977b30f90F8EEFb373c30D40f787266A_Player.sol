// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;

import "./2_character.sol";
import "./3_weapon.sol";

contract Player is Character, Weapon {
    uint8 public level;
    uint8 public points;
    string public wasDefeated;
    string[] public defeatedPlayers;

    constructor(string memory _name, string memory _race, string memory _class, string memory _weapon) {
        owner = msg.sender;
        name = _name;
        race = _race;
        class = _class;
        weapon = _weapon;
        wasDefeated = "Was not defeated";
        health = 100;
        force = 10;
        level = 1;
        points = 0;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "You aren't owner");
        _;
    }

    modifier havePoints(){
        require(points > 0);
        _;
    }

    function setHealth(uint8 _damage) external override {
        health -= _damage;
        if (health < 0){
            health = 0;
            wasDefeated = Player(msg.sender).name();
        }
    }

    function attack(address _playerAddress) public onlyOwner {
        require(health > 0, "You are dead");
        require(Player(_playerAddress).health() > 0, "The player is dead");
        Player player = Player(_playerAddress);
        player.setHealth(force);
        if (player.health() == 0){
            level += 1;
            points += 5;
            defeatedPlayers.push(player.name());
        }
    }

    function cure() public onlyOwner havePoints{
        health += 5;
        points -= 1;
    }

    function improveAttack() public onlyOwner havePoints{
        force += 1;
        points -= 1;
    }
}