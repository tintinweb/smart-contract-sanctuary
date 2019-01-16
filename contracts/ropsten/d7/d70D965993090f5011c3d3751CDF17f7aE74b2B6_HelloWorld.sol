pragma solidity ^0.5.0;

/**
 * @title HelloWorld
 * @dev This contract implements a function which prints "Hello World!"
 * This is the entry point in the world of smart contract development
 */

contract HelloWorld {
    address public owner;
    
    
    constructor (address _owner) public{
        owner = _owner;
        
    }

}