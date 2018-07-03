pragma solidity ^0.4.23;

contract MessageOfTheDay {
    string public message;

    function setMessage(string _message) public  returns (bool) {
        message = _message;
        return true;
    }
}