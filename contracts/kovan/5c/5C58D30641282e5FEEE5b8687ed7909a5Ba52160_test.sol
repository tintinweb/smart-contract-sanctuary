/**
 *Submitted for verification at Etherscan.io on 2021-09-18
*/

pragma solidity ^0.5.17;

contract test {
    
    struct hero {
        address owner;
        uint id;
        uint blood;
        uint power;
    }
    
    hero[] public heros;
    uint public heroNumber;
    
    function mint() public {
        heros.push(hero({
            owner:msg.sender,
            id:heroNumber,
            blood:200,
            power:200
        }));
        heroNumber++;
    }
    
}