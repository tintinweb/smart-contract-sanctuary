// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

import "./2_character.sol";
import "./3_weapon.sol";

contract Player is Weapon, Character {
    uint8 public pl_level;
    uint8 public char_points;
    string public wasDefeated = "was not defeated";
    string[] defeatedPlayers;

    event saveAttackInf(string attacker, string defender, uint dealt_dmg, uint reamin_hp);
    event Fight_res(string winner, string loser, uint lvl_of_winner, uint points);
    event heal_inf(string who_has_healed, uint how_much, uint new_health);
    event attack_imp(string who_improved, uint what_was_it, uint new_attack);

    constructor(string memory _name, string memory _race, string memory _class, string memory _weap_name){
        owner = msg.sender;
        name = _name;
        race = _race;
        class = _class;
        weap_name = _weap_name;
        health = 100;
        attack_dmg = 10;
        pl_level = 1;
        char_points = 0;

    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    
    modifier havePoints(){
        require(char_points > 0);
        _;
    }
    function attack(address other_pl) public onlyOwner{
        require(health > 0, "You are dead");
        require(Player(other_pl).health() > 0, "The player is dead");
        Player player = Player(other_pl);
        player.setHealth(attack_dmg);
        emit saveAttackInf(name, player.name(), attack_dmg, player.health()-attack_dmg);
        if (player.health() == 0){
            pl_level += 1;
            char_points += 5;
            defeatedPlayers.push(player.name());
            emit Fight_res(name, player.name(), pl_level, char_points);
        }
    }

    function setHealth(uint8 dmg) public override{
        Player attacker = Player(msg.sender);
        if (dmg >= health){
            health = 0;
            wasDefeated = Player(msg.sender).name();
            emit Fight_res(attacker.name(), name, attacker.pl_level() + 1, attacker.char_points() + 5);
        }
        else{
            emit saveAttackInf(attacker.name(), name, attacker.attack_dmg(), health -= dmg);
            health -= dmg;
            }
    }

    function cure() public onlyOwner havePoints{
        emit heal_inf(name, health, health + 5);
        health += 5;
        char_points -= 1;
    }

    function improveAttack() public onlyOwner havePoints{
        emit attack_imp(name, attack_dmg, attack_dmg + 1);
            attack_dmg += 1;
            char_points -= 1;
    }
}