/**
 *Submitted for verification at Etherscan.io on 2021-08-22
*/

pragma solidity ^0.8.0;

contract HelloWorld {
    // product property
    string public name = 'Wuddy';
    uint256 public age = 25;
    
    //Authorization
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    function updateName(string memory newName) public {
        //require(owner == msg.sender, 'sender is not owner!!!');
        name = newName;
    }
    
    function updateAge(uint256 newAge) public {
         //Authorization
        age = newAge;
    }
    
}