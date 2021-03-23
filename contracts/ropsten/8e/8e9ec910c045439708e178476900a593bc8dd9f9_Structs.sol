/**
 *Submitted for verification at Etherscan.io on 2021-03-23
*/

pragma solidity ^0.4.24;

contract Structs {
    struct User {
        string name;
        string email;
    }

    User[] public users;

    function addUser(string _name, string _email) public {
        users.push(User(_name, _email));
    }
    function getUser(uint _id) public view returns (string, string) {
        User storage u = users[_id];
        u.name = "terry";
        return (users[_id].name, users[_id].email);
    }
}