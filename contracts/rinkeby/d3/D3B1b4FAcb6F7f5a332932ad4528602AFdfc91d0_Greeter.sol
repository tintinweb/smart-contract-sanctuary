/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

contract Greeter {
    string private greeting;
    address internal owner;

    event ChangeGreeting(string _greeting);

    modifier OnlyOwner() {
        require(msg.sender == owner, "no permission");

        _;
    }

    constructor(string memory _greeting) {
        greeting = _greeting;
        owner = msg.sender;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) external OnlyOwner {
        greeting = _greeting;

        emit ChangeGreeting(_greeting);
    }
}