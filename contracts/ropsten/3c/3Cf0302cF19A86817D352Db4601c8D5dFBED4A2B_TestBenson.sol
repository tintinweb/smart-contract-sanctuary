// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

//means extends contract
contract TestBenson {
    address public owner;

    // constructor
    constructor() public {
        owner = msg.sender;
    }

    //ownerOnly modifier
    modifier ownerOnly() {
        require(msg.sender == owner);
        _;
    }    
    function sayHello() public pure returns (string memory) {        
        return ("Hello World");
    }

    function echo(string memory name) public pure returns (string memory) {
        return name;
    }

    function onlyOwner(string memory str) public view ownerOnly returns (string memory) {
        return str;
    }
}