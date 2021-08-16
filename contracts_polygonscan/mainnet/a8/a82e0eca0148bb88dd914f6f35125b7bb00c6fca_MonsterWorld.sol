/**
 *Submitted for verification at polygonscan.com on 2021-08-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;



contract MonsterWorld {
    enum MonsterType {
        WATER,
        FIRE,
        DARK,
        LIGHT
    }
    
    enum MonsterClass {
        HUMAN,
        ORC,
        UNDEAD,
        ELF
    }
    
    enum MonsterTier {
        C,
        B,
        A,
        S,
        SS,
        SSS
    }
    
    struct Monster {
        MonsterClass class;
        MonsterType mtype;
        uint level;
        MonsterTier tier;
        uint born_time;
        uint attack;
        uint hp;
        address owner;
    }
    
    Monster[] public monsters;
    address public manager;
    mapping (address => uint[]) public pets;
    
    
    constructor() {
        manager = msg.sender;
        
    }

    
    function buyMonster() payable public {
        require(msg.value == 0.005 ether, "You have to sent exactly 0.005 ether to buy a monster.");
        
        Monster memory newMonster = Monster({ 
            class: MonsterClass.HUMAN, 
            mtype: MonsterType.WATER, 
            level: 1, 
            tier: MonsterTier.B, 
            born_time: block.timestamp, 
            attack: 200, hp: 1000, 
            owner: msg.sender});
        
        // Monster memory newMonster;
        // newMonster.class = MonsterClass.HUMAN;
        
        monsters.push(newMonster);
    }
    
    // Where id1, id2 is monster index
    function Attack(uint id1, uint id2) public {
        //
        
    }

    
    function random() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, monsters.length)));
    }
    
    function getModulusRandom(uint256 k) private view returns (uint256) {
        return random() % k;
    }
   
}