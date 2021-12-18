// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;

import "./2_character.sol";
import "./3_weapon.sol";

contract Player is Character, Weapon{
    uint8 public level;
    uint8 public score;
    string public wasDefeated;
    string[] public defeatedPlayers;


    modifier onlyOwner(){
        require(msg.sender == owner, "You are not owner");
        _;
    }
    modifier havePoints(){
        require(score > 0);
        _;
    }
    constructor(string memory _name, string memory _race, string memory _class, string memory _weapon){
        owner = msg.sender;
        name = _name;
        race = _race;
        class = _class;
        weapon = _weapon;
        health = 100;
        force = 10;
        level = 1;
        score = 0;
        wasDefeated = "was not defeated";
    }

    function SetHealth(uint8 _damage) external{
        if(_damage > health && health > 0){
            health = 0;
            wasDefeated = Player(msg.sender).name();
        }
        else{
            health -= _damage;
        }
    }

    function attack(address _otherPlayer)public onlyOwner{
        require(health > 0, "You re dead");
        require(Player(_otherPlayer).health() > 0, "The player is dead");

        Player owner = Player(_otherPlayer);
        owner.SetHealth(force);

        if(owner.health() == 0){
            level += 1;
            score += 5;
            defeatedPlayers.push(owner.name());
        }
    }
    function cure()public onlyOwner havePoints{
        health += 1;
        score -= 1;
    }
    function improveAttack()public onlyOwner havePoints{
        force += 1;
        score -= 1;
    }
}