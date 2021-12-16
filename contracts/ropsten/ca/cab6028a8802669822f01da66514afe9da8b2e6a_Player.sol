// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;

import "./2_weaponContract.sol";
import "./3_characterContract.sol";

contract Player is Character,Weapon{
    uint public playerLevel;
    uint public playerPoints;

    string public wasDefeated;
    string[] defeatedPlayers;

    event atackEvent(address, address, uint8, uint8);
    event battleEvent(address, address, uint, uint);
    event cureEvent(uint8, uint);
    event improveEvent(uint, uint);

    modifier onlyOwner{
        require(owner == msg.sender);
        _;
    }

    modifier havePoints{
        require(playerPoints != 0);
        _;
    }
    
    constructor(string memory _name, string memory _race,  string memory _class, string memory _weaponName){
        owner = msg.sender;
        characterName = _name;
        characterRace = _race;
        characterClass = _class;
        weaponName = _weaponName;

        characterHp = 100;
        weaponDamage = 10;
        playerLevel = 1;
        playerPoints = 0;
        wasDefeated = "was not defeated";
    }

    function attack(address _add)public onlyOwner{
        require(characterHp > 0, "You are dead");
        require(Player(_add).characterHp() > 0, "The player is dead");
        Player opp = Player(_add);
        opp.setHealth(weaponDamage);
        if(opp.characterHp() == 0){
            playerLevel += 1;
            playerPoints += 5;
            defeatedPlayers.push(opp.characterName());
            emit battleEvent(msg.sender, _add, playerLevel, playerPoints);
        }
        emit atackEvent(msg.sender, _add, weaponDamage, opp.characterHp());
    }

    function cure() public onlyOwner havePoints{
        characterHp += 5;
        playerPoints -= 1;
        emit cureEvent(characterHp, playerPoints);
    }

    function improveAttack()public onlyOwner havePoints{
        weaponDamage += 1;
        playerPoints -= 1;
        emit improveEvent(weaponDamage, playerPoints);
    }

    function setHealth(uint8 _harm) external override{
        if(_harm >= characterHp){
            characterHp = 0;
            wasDefeated = Player(msg.sender).characterName();
            emit battleEvent(msg.sender, owner, Player(msg.sender).playerLevel(), Player(msg.sender).playerPoints());
        }else{
            characterHp -= _harm;
        }
        emit atackEvent(msg.sender, owner, Player(msg.sender).weaponDamage(), characterHp);
    }

    function getDefeatedPlayers() public view returns(string[] memory){
        return defeatedPlayers;
    }

}