pragma solidity ^0.4.18;
contract hello {
    string greeting = "fuck you";

    function say() constant public returns (string) {
        return greeting;
    }
}