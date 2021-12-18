// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;

import "./2_character.sol";
import "./3_weapon.sol";

contract Player is Character, Weapon {
    uint8 public level;
    uint8 public points;
    string public wasDefeated;
    string[] public defeatedPlayers;

    event attacker(string _attacker);
    event damageCounter(uint _force);
    event healthLeft(uint playerHealthLeft);

    event healing(uint healthCured);
    event improvingAttack(uint imporve);

    event winner(string _Wname);
    event looser(string _Lname);
    event new_level(uint _level);
    event new_points(uint _points);

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
            emit winner(Player(msg.sender).name());
            emit looser(name);
        }
        emit healthLeft(health);
        emit damageCounter(_damage);
        emit attacker(Player(msg.sender).name());
    }

    function attack(address _playerAddress) public onlyOwner {
        require(health > 0, "You are dead");
        require(Player(_playerAddress).health() > 0, "The player is dead");
        Player player = Player(_playerAddress);
        player.setHealth(force);
        emit attacker(name);
        emit damageCounter(force);
        emit healthLeft(health);
        if (player.health() == 0){
            level += 1;
            points += 5;
            defeatedPlayers.push(player.name());
            emit looser(player.name());
            emit winner(name);
            emit new_level(level);
            emit new_points(points);
        }
    }

    function cure() public onlyOwner havePoints{
        health += 5;
        points -= 1;
        emit healing(5);
    }

    function improveAttack() public onlyOwner havePoints{
        force += 1;
        points -= 1;
        emit improvingAttack(1);
    }
}