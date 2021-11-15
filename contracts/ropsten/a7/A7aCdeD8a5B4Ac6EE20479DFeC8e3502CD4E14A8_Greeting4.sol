pragma solidity ^0.5.16;

contract Greeting4 {

    string greeting;
    address owner;

    constructor(string memory _greeting) public {
        greeting = _greeting;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'Only owner can execute this');
        _;
    }

    function greet() public view returns(string memory) {
        return greeting;
    }

    function getOwner() public view returns(address) {
        return owner;
    }

    function setGreeting(string memory _greeting) public onlyOwner {
        greeting = _greeting;
    }
}

