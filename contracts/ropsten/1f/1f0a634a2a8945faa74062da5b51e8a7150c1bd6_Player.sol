// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.7 <0.9.0;

import "./1_Character.sol";
import "./2_Weapon.sol";

contract Player is Character, Weapon {
    uint8 public level;
    uint8 public score;
    string defeatedBy;
    address[] defeatedPlayers;

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not owner");
        _;
    }

    modifier alive() {
        require(health > 0, "You are already dead");
        _;
    }

    modifier hasScore() {
        require(score > 0, "Your score is zero");
        _;
    }

    constructor(string memory _name, string memory _race, string memory _class, string memory _weapon) {
       owner = msg.sender;
       name = _name;
       race = _race;
       class = _class;
       weapon = _weapon;
       health = 100;
       attack = 10;
       level = 1;
       score = 0;
       defeatedBy = "was not defeated";
    }

    function setHealth(uint8 _damage, Player _attacker) public virtual {
        if (_damage >= health){
            health = 0;
            defeatedBy = _attacker.name();
        } else {
            health -= _damage;
        }
    }

    function attackPlayer(address _otherPlayer) public onlyOwner alive {
        Player otherPlayer = Player(_otherPlayer);
        otherPlayer.setHealth(attack, Player(address(this)));
        if (otherPlayer.health() == 0) {
            defeatedPlayers.push(_otherPlayer);
            level += 1;
            score += 5;
        }
    }

    function getDefeatedBy() public view returns(string memory) {
        return defeatedBy;
    }

    function getDefeatedPlayers() public view returns(address[] memory) {
        return defeatedPlayers;
    }

    function cure() public onlyOwner alive hasScore {
        health += 5;
        score -= 1;
    }

    function improveAttack() public onlyOwner alive hasScore {
        attack += 1;
        score -= 1;
    }
}