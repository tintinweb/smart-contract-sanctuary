pragma solidity ^0.4.23;

contract User {

    uint[] public users;

    constructor() public {
        users.push(100);
        users.push(200);
    }
}