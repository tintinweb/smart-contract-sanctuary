// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;
 
import "./2_character.sol";
import "./3_weapon.sol";

contract Player is Character, Weapon{
    uint8 public level = 0;
    uint8 public points = 0;
    string public wasDefeated;
    string[] defeatedPlayers; 
    
    // проверка на владельца
    modifier onlyOwner(address _adr){
        require(owner == _adr);
        _;
    }
    
    // проверка на наличие очков
    modifier havePoints(){
        require(points > 0);
        _;
    }
    
    constructor(string memory _name, string memory _race, string memory _class, string memory _weaponName){
        owner = msg.sender;
        name = _name;
        race = _race;
        class = _class;
        weaponName = _weaponName;
        wasDefeated = "was not defeated";
        health = 100;
        force = 10;
    }
    
    function setHealth(uint8 _health)external override{
        // здоровье специально сделано uint,
        // чтобы нельзя было передать отрицательнео значение
        // но uint сломается если (health -= _health) < 0,
        // поэтому делаем проверку
        if(_health >= health){
            health = 0;
            // метод вызывается из контракта другого игрока
            // соответственно в msg.cender - адрес контракта
            // приводим к типу контракта, получаем имя и записываем куда надо
            wasDefeated = Player(msg.sender).name();
        }
        else{
            health -= _health;
        }
    }
    
    function attack(address _playerAddres)public onlyOwner(msg.sender){
        // у нас тут некромантии, по этому атаковать и быть атакованными
        // могут только живые игроки
        require(health > 0, "You are dead");
        require(Player(_playerAddres).health() > 0, "The player is dead");
        // сама атака происходит тут
        Player(_playerAddres).setHealth(force);
        //если победили игрока - получаем новыый уровень и очки
        if(Player(_playerAddres).health() == 0){
            level += 1;
            points += 5;
            // из адреса контракта другого игрока достаём имя и добавляем в массив
            defeatedPlayers.push(Player(_playerAddres).name());
        }
    }
    
    // функция лечения
    function cure()public onlyOwner(msg.sender) havePoints{
        health += 5;
        points -= 1;
    }
    
    // функция прокачки
    function improveAttack()public onlyOwner(msg.sender) havePoints{
        force += 1;
        points -=1;
    }
    
    // возвращаем массив поверженных игроков
    function getdefeatedPlayers()public view returns(string[] memory){
        return defeatedPlayers;
    }
}