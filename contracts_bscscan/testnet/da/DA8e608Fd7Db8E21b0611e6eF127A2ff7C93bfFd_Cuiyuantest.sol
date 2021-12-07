/**
 *Submitted for verification at BscScan.com on 2021-12-07
*/

pragma solidity >=0.7.0 <0.9.0;

contract Cuiyuantest {
    struct User{
        uint id;
        string name;
    }

    mapping(uint=>User) users;

    event addUserEvent(uint id, string name);
    
    function addUser(uint id, string memory name) public {
        emit addUserEvent(id, name);
        users[id] = User(id, name);
    }

    function getUser(uint id) public view returns (uint, string memory) {
        User memory user = users[id];
        return (id, user.name);
    }
}