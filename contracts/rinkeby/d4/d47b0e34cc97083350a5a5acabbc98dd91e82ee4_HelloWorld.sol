/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

pragma solidity ^0.5.0;  
pragma experimental ABIEncoderV2;

contract HelloWorld {

    struct User {
        string name;
        uint age;
    }

    User[] users;


    function addUser(User memory user_) public  {
        users.push(user_);
    }

    function getUser(uint index) public view returns(User memory) {
        require(index >=0 && index < users.length);
        return users[index];
    }
}