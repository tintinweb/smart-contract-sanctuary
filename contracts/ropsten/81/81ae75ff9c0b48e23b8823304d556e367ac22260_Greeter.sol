pragma solidity ^0.4.18;

contract Mortal {
    address owner;
    constructor() public { owner = msg.sender; }
    function kill() public {
        require(
            msg.sender == owner,
            "Only owner can call this functiona"
        ); 
        selfdestruct(owner);
    }
}

contract Greeter is Mortal {
    string greeting;
    constructor (string _greeting) public {
        greeting = _greeting;
    }
    function greet() public constant returns (string) {
        return greeting;
    }
}