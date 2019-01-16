pragma solidity ^0.4.2;

contract Login {

    event LoginAttempt(address sender, string challenge);

    function login(string challenge) {
        emit LoginAttempt(msg.sender, challenge);
    }

}