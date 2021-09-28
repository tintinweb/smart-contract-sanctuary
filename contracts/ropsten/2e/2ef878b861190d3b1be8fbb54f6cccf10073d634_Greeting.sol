/**
 *Submitted for verification at Etherscan.io on 2021-09-28
*/

pragma solidity ^0.5.16;

contract Greeting {

    string greeting;
    address owner;

    constructor(string memory _greeting) public {
        greeting = _greeting;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function greet() public view returns(string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public onlyOwner {
        greeting = _greeting;
    }
}