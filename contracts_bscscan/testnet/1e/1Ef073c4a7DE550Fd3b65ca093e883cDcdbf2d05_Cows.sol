/**
 *Submitted for verification at BscScan.com on 2022-01-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.8.8;

contract Cows {
    
    mapping(string => bool) public created;
    mapping(string => uint) public cows;
    mapping(string => uint) public scores;
    string[] public names;
    uint public totalCows;
    
    function getTotalCows() public view returns(uint) {
        return totalCows;
    }
    
    function getScore(string memory name) public view returns(uint) {
        return scores[name];
    }
    
    function getCows(string memory name) public view returns(uint) {
        return cows[name];
    }
    
    function increaseCow(string memory name) public {
        if (cows[name] >= 5) {
            cows[name] = 0;
            revert("You cannot have more than 5 cows!");
        }
        
        if (created[name] == false) {
            names.push(name);
            created[name] = true;
        }
        
        totalCows += 1;
        cows[name] += 1;
    }
    
    function reset() public {
        for (uint i=0; i<names.length; i++) {
            cows[names[i]] = 0;
            scores[names[i]] = 0;
        }
        totalCows = 0;
    }
    
    function increasePoints(uint seed) public returns(uint) {
        uint maxAdd;
        uint add;
        uint randSeed = seed;
        uint temp;
        string memory name;
        uint amountEaten = 0;
        for (uint i=0; i<names.length; i++) {
            name = names[i];
            maxAdd = (cows[name] * 10);
            temp = scores[name];
            add = (maxAdd * randSeed) % (maxAdd+1);
            temp += add;
            amountEaten += add;
            scores[name] = temp;
            randSeed += scores[name];
        }
        return amountEaten;
    }
}