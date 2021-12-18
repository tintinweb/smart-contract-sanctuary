// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;


import "./2_character.sol";
import "./3_weapon.sol";



contract Player is Weapon, Character {
    uint8 public level;
    uint8 public XP;
    event curing();
    event improvingAttack();

    constructor(string memory _name, string memory _race,  string memory _class, string memory _weaponName) {
        health = 100;
        weaponDamage = 10;
        level = 1;
        XP = 0;
        name = _name;
        race = _race;
        class = _class;
        weaponName = _weaponName;
        owner = msg.sender;
    }

    function attack(address enemyAddr) public returns (string memory){
        require(msg.sender == owner);

        if (health <= 0){
            return "You are dead";
        }
        Player enemy = Player(enemyAddr);

        if(enemy.health() <= 0){
            return "The player is dead";
        }

        enemy.setHealth(weaponDamage);
        emit attacking(owner, enemyAddr, weaponDamage, enemy.health());
        if (enemy.health() == 0){
            level += 1;
            XP += 5;
            emit win(owner, enemyAddr, level, XP);
        }
        return "OK";
    }

    function cure() public {
        require(msg.sender == owner);
        require(XP > 0);
        health += 5;
        XP -= 1;
        emit curing();
    }

    function improveAttack() public {
        require(msg.sender == owner);
        require(XP > 0);
        weaponDamage += 1;
        XP -= 1;
        emit improvingAttack();
    }

}