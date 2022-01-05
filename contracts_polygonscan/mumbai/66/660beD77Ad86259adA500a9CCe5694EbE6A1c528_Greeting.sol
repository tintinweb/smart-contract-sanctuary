/**
 *Submitted for verification at polygonscan.com on 2022-01-05
*/

pragma solidity 0.6.0;

contract Greeting {
    address creator;
    string message;

    // functions that interact with state variables

    constructor (string memory _message) public {
        message = _message;
        creator = msg.sender;
    }

    function greet() public view returns (string memory) {
        return message;
    }

    function setGreeting(string memory _message) public {
        message = _message;
    }
}