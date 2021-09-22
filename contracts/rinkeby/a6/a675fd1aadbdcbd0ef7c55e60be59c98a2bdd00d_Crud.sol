/**
 *Submitted for verification at Etherscan.io on 2021-09-22
*/

pragma solidity 0.5.0 ;

contract Crud {
    struct User {
        uint id;
        string Name;
    }
    User [] public users;
    uint public nextId;
    
    function createUser (string memory name ) public {
        users.push (User(nextId++, name));
    }
    function readUser  (uint id) view public returns (uint, string memory){
        for (uint i = 0; i < users.length ; i++){
            if (users[i].id == id){
               return (users[i].id, users[i].Name) ;
            }
        }
        
    }

    function update (uint id, string memory name) public{
        for (uint i = 0; i < users.length ; i++){
            if (users[i].id == id){
                users[i].Name = name;
            }
        }
    }

    function Delete (uint id) public {
        delete users[id];
    }
    
}