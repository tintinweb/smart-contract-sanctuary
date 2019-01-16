pragma solidity ^0.5.0;

/**
 * @title HelloWorld
 * @dev This contract implements a function which prints "Hello World!"
 * This is the entry point in the world of smart contract development
 */

contract HelloWorld {

    /**
     * @dev Prints "Hello World!" 
     */
    
    function print() public pure returns (string memory){
        return "Hello World!";
    }
}