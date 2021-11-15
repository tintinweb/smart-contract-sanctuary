// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Greeter {

    string public greetings;

    event GreetingSet(string indexed newGreet);

    function setGreeting(string memory newGreet) external {
        greetings = newGreet;
        emit GreetingSet(newGreet);
    }

}

