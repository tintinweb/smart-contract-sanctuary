// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

import "./2_character.sol";
import "./3_weapon.sol";
contract Player is Weapon, Character {
    uint8 public pl_level;
    uint8 public char_points;
    string public wasDefeated = "was not defeated";
    string[] defeatedPlayers;

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
        if (player.health() == 0){
            pl_level += 1;
            char_points += 5;
            defeatedPlayers.push(player.name());
        }
    }

    function setHealth(uint8 dmg) public override{
            if (dmg >= health){
                health = 0;
                wasDefeated = Player(msg.sender).name();
            }
            else{
                health -= dmg;
            }
    }

    function cure() public onlyOwner havePoints{
        health += 5;
        char_points -= 1;
    }

    function improveAttack() public onlyOwner havePoints{
            attack_dmg += 1;
            char_points -= 1;
    }
}