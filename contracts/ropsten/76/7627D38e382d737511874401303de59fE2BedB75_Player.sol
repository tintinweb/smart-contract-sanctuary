// Эта строка необходима для правильной работы с JSON
// SPDX-License-Identifier: GPL-3.0
// Устанавливаем версии компилятора
pragma solidity >=0.8.7;
import "./2_character.sol";
import "./3_weapon.sol";
// Делаем контракт - набор состояний и переходов
contract Player is Character, Weapon{
    uint8 public level;
    uint8 public points;
    string public wasDefeated;
    string[] defeatedPlayers;

    constructor(string memory _name, string memory _race, string memory _class, string memory _weaponName){
        name = _name;
        race = _race;
        class = _class;
        weponName = _weaponName;
        health = 100;
        force = 10;
        level = 1;
        points = 0;
        wasDefeated = "was not defeated";
    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    modifier havePoints(){
        require(points > 0);
        _;
    }

    function setHealth(uint8 _damage) override external{
        if (_damage >= health){
            health = 0;
            wasDefeated = name;
        }
        else health -= _damage;
    }

    function attack(address _playAddress) public onlyOwner{
        require(health > 0, "You are dead");
        require(Player(_playAddress).health() > 0, "This player is dead");
        Player player = Player(_playAddress);
        player.setHealth(force);
        if (player.health() <= 0){
            level += 1;
            points += 5;
            defeatedPlayers.push(player.name());
        }
    }

    function cure() public onlyOwner havePoints{
        health += 5;
        points -= 1;
    }

    function improveAttack()public onlyOwner havePoints{
        force += 1;
        points -= 1;
    }

    function getDefeatedPlayers() onlyOwner public view returns(string[] memory){
        return defeatedPlayers;
    }
}