/**
 *Submitted for verification at BscScan.com on 2021-12-07
*/

pragma solidity >=0.7.0 <0.9.0;

contract Cuiyuantest {
    struct User{
        uint id;
        string name;
    }

    mapping(uint=>User) public users;

    event addUserEvent(uint id, string name);
    event getUserEvent(uint id, string name);
    
    function addUser(uint id, string memory name) public {
        emit addUserEvent(id, name);
        users[id] = User(id, name);
    }

    function getUser(uint id) public payable returns (uint, string memory) {
        string memory name1 = users[id].name;
        emit getUserEvent(id,name1);
        return (id, name1);
    }
}