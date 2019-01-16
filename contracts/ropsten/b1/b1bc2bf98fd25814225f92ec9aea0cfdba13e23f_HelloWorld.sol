pragma solidity ^0.5.0;

/**
 * @title HelloWorld
 * @dev This contract implements a function which prints "Hello World!"
 * This is the entry point in the world of smart contract development
 */

contract HelloWorld {
    address owner;
    uint age;
    string name;
    
    constructor (uint _age, string memory _name, address _owner) public{
        owner = _owner;
        age = _age;
        name = _name;
    }

    /**
     * @dev Prints "Hello World!" 
     */
    
    function print() public pure returns (string memory){
        return "Hello World!";
    }
}