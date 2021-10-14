pragma solidity ^0.6.0;

contract MyContract {

    struct User {
        string name;
        uint256 age;
    }

    User   public adminUser;

    constructor() public {
        adminUser.name = "Ryan";
        adminUser.age = 30;
    }

    function setAge(uint256 _age) public view {
        User memory user = adminUser;
        user.age = _age;
    }
}