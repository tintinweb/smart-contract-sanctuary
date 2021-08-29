/**
 *Submitted for verification at Etherscan.io on 2021-08-29
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Game {

    uint ids;
    uint counter;

    mapping (uint => address) IdToOwner;
    mapping (address => uint[]) OwnertoId;
    mapping (uint => MemeFighter) public nft;

    struct MemeFighter {
        uint id;
        string rarity;
        uint hp;
        uint attack;
        uint defence;
        uint speed;
        uint luck;
    }

    function pseudRandom() private returns(uint) {
        uint rand = uint(keccak256(abi.encodePacked(counter,block.timestamp)));
        counter++;
        return rand;
    }

    function determineRarity() private returns(uint points,string memory class) {
        uint roll = 1+(pseudRandom()%100);
        uint determination;
        string memory cl;
        if(roll == 1) {
            determination = 60;
            cl = "Legendary";
        } else if(roll < 11) {
            determination = 56;
            cl = "Epic";
        } else if(roll < 40) {
            determination = 52;
            cl = "Rare";
        } else { determination = 50; cl = "Common";}
        return (determination, cl);
    }

    function calculateStat(uint points, uint seed) private returns(uint) {
        uint result;
        if(points > 3) {
            result = (uint(keccak256(abi.encodePacked(counter,seed))))%points+3;
            counter++;
        } else { result = points; }
        return result;
    }

    function createFighter() public {
        uint seed = pseudRandom();
        string memory rarity;
        uint points;
        (points,rarity) = determineRarity();
        uint hp = points;
        uint attack = 5;
        uint defence = 5;
        uint speed = 5;
        uint luck = 5;
        points = points - 20;
        while(points > 0) {
            //determine attack
            if(attack < 20) {
                if(points >= 10) {
                    uint result = calculateStat(10, seed);
                    if(attack + result <= 20){
                        attack = attack + result;
                        points = points - result;
                    } else {
                        uint remainder = 20 - attack;
                        attack = 20;
                        points = points - remainder;
                    }
                } else { 
                   uint result = calculateStat(points, seed);
                    if(attack + result <= 20){
                        attack = attack + result;
                        points = points - result;
                    } else {
                        uint remainder = 20 - attack;
                        attack = 20;
                        points = points - remainder;
                    }
                }
            }
            //determine defence
            if(defence < 20) {
                if(points >= 10) {
                    uint result = calculateStat(10, seed);
                    if(defence + result <= 20){
                        defence = defence + result;
                        points = points - result;
                    } else {
                        uint remainder = 20 - defence;
                        defence = 20;
                        points = points - remainder;
                    }
                } else { 
                   uint result = calculateStat(points, seed);
                    if(defence + result <= 20){
                        defence = defence + result;
                        points = points - result;
                    } else {
                        uint remainder = 20 - defence;
                        defence = 20;
                        points = points - remainder;
                    }
                }
            }
            //determine speed
            if(speed < 20) {
                if(points >= 10) {
                    uint result = calculateStat(10, seed);
                    if(speed + result <= 20){
                        speed = speed + result;
                        points = points - result;
                    } else {
                        uint remainder = 20 - speed;
                        speed = 20;
                        points = points - remainder;
                    }
                } else { 
                   uint result = calculateStat(points, seed);
                    if(speed + result <= 20){
                        speed = speed + result;
                        points = points - result;
                    } else {
                        uint remainder = 20 - speed;
                        speed = 20;
                        points = points - remainder;
                    }
                }
            }
            //determine luck
            if(luck < 20) {
                if(points >= 10) {
                    uint result = calculateStat(10, seed);
                    if(luck + result <= 20){
                        luck = luck + result;
                        points = points - result;
                    } else {
                        uint remainder = 20 - luck;
                        luck = 20;
                        points = points - remainder;
                    }
                } else { 
                   uint result = calculateStat(points, seed);
                    if(luck + result <= 20){
                        luck = luck + result;
                        points = points - result;
                    } else {
                        uint remainder = 20 - luck;
                        luck = 20;
                        points = points - remainder;
                    }
                }
            }
        }

        nft[ids] = MemeFighter(ids,rarity,hp,attack,defence,speed,luck);
        IdToOwner[ids] = msg.sender;
        OwnertoId[msg.sender].push(ids);
        ids++;
    }
    
    function round(uint one, uint two, uint hp, uint seed) private returns(uint) {
        MemeFighter memory first = nft[one];
        MemeFighter memory second = nft[two];
        uint damage;
        uint attackRoll = uint(keccak256(abi.encodePacked(seed, counter)))%first.attack+1;
        counter++;
        uint defenceRoll = uint(keccak256(abi.encodePacked(seed, counter)))%second.defence+1;
        counter++;
        uint luckOne = uint(keccak256(abi.encodePacked(seed, counter)))%(25-first.luck)+1;
        counter++;
        uint luckTwo = uint(keccak256(abi.encodePacked(seed, counter)))%(25-second.luck)+1;
        counter++;
        uint rounds;
        uint defenceRerolls;
        rounds = 1;
        if(first.speed >= (second.speed +5)) { rounds++; }
        if(first.speed >= (second.speed +10)) { rounds++; }
        if(second.speed >= (first.speed +5)) { defenceRerolls++; }
        if(second.speed >= (first.speed +10)) { defenceRerolls++; }
        //attack luck, 50% bonus
        //defence luck, half damage
        while(defenceRerolls > 0) {
            uint replacement = uint(keccak256(abi.encodePacked(seed, counter)))%second.defence+1;
            counter++;
            if(replacement > defenceRoll) { defenceRoll = replacement; }
            defenceRerolls--;
        }
        while(rounds > 0) {
            if(attackRoll > defenceRoll) {
                damage = attackRoll - defenceRoll;
                if(luckOne != 1 && luckTwo != 1) {
                    if(luckOne == 1) {
                        uint bonus = damage * 10 / 20;
                        damage = damage + bonus;
                    } else if(luckTwo == 1) {
                        damage = damage / 2;
                    }
                }
            } else {
                damage = 0;
            }
            if(damage > hp) {
                damage = hp;
            }
            rounds--;
        }
        return damage;
    }
    
    function fight(uint one, uint two) public returns(string memory) {
        MemeFighter memory fighter1 = nft[one];
        MemeFighter memory fighter2 = nft[two];
        require(fighter1.hp != 0 && fighter2.hp != 0, "Invalid fighters");
        uint seed = pseudRandom();
        uint hp1;
        uint hp2;
        string memory winner;
        hp1 = fighter1.hp;
        hp2 = fighter2.hp;
        if(uint(keccak256(abi.encodePacked(seed)))%2 == 0) {
            //fighter1 goes first
            while(hp1 > 0 && hp2 > 0) {
                uint damage;
                damage = round(one, two, hp2, seed);
                hp2 = hp2 - damage;
                damage = round(two, one, hp1, seed);
                hp1 = hp1 - damage;
            }
        } else {
            //figher2 goes first
            while(hp1 > 0 && hp2 > 0) {
                uint damage;
                damage = round(two, one, hp1, seed);
                hp1 = hp1 - damage;
                damage = round(one, two, hp2, seed);
                hp2 = hp2 - damage;
            }
        }
        if(hp1 == 0) {
            winner = "player two";
        } else if(hp2 == 0) {
            winner = "player one";
        }
        return winner;
    }

}