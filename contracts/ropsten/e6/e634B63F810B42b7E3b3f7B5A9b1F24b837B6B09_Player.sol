pragma solidity >=0.8.7;

import "./2_character.sol";
import "./3_weapon.sol";

contract Player is Character, Weapon {
    uint8 public player_level;
    uint16 public player_score;

    modifier onlyOwner(address _adr){
        require(_adr == owner_address);
        _;
    }

    constructor(string memory _character_name, string memory _character_species, string memory _character_class, string memory _weapon_name){
        character_name = _character_name;
        character_species = _character_species;
        character_class = _character_class;
        weapon_name = _weapon_name;

        health_point = 100;
        weapon_damage = 10;
        player_level = 1;
        player_score = 0;
    }

    function Player_attack(address enemy_address) public onlyOwner(msg.sender){

        require(health_point > 0, "You are dead");
            require(Player(enemy_address).health_point() > 0, "The player is dead");

                Player enemy = Player(enemy_address);
                enemy.Character_setHealth(weapon_damage);

                if (enemy.health_point() == 0){
                    player_level += 1;
                    player_score += 5;
                }
    }

    function Player_cure() public onlyOwner(msg.sender){
        require(player_score > 0);

            health_point += 5;
            player_score -= 1;
    }

    function Player_improveAttack() public onlyOwner(msg.sender){
        require(player_score > 0);

            weapon_damage += 1;
            player_score -= 1;
    }
}