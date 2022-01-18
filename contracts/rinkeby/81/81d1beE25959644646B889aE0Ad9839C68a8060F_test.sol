// SPDX-Licence-Identifier: MIT
pragma solidity 0.8.7;

contract test {

    string public greet;

    constructor (string memory arg) {
        greet = arg;
    }

    function greetings () public view returns (string memory) {
        return greet;
    }
}