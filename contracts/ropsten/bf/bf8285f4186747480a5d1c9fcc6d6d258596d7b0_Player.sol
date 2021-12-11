// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;

import "./2_weaponContract.sol";
import "./3_characterContract.sol";

contract Player is Character,Weapon{
    uint public playerLevel;
    uint public playerPoints;

    string public wasDefeated;
    string[] defeatedPlayers;

    modifier onlyOwner{
        require(owner == msg.sender);
        _;
    }

    modifier havePoints{
        require(playerPoints != 0);
        _;
    }
    
    constructor(string memory _name, string memory _race,  string memory _class, string memory _weaponName){
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
        }
    }

    function cure() public onlyOwner havePoints{
        characterHp += 5;
        playerPoints -= 1;
    }

    function improveAttack()public onlyOwner havePoints{
        weaponDamage += 1;
        playerPoints -= 1;
    }

    function setHealth(uint8 _harm) external override{
        if(_harm >= characterHp){
            characterHp = 0;
            wasDefeated = Player(msg.sender).characterName();
        }else{
            characterHp -= _harm;
        }
    }

    function getDefeatedPlayers() public view returns(string[] memory){
        return defeatedPlayers;
    }

}