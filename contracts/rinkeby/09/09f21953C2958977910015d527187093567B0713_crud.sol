/**
 *Submitted for verification at Etherscan.io on 2021-09-18
*/

pragma solidity ^0.8.0;

contract crud{
    
    struct User{
        uint  id;
        string name;
    }
    
    User[] users;
    uint nextId = 1;
    
    function create(string memory name) public {
      
        users.push(User(nextId, name));
        nextId++;
    }
    
    function read(uint _id) public view returns(uint, string memory){
        require(_id <= users.length, "Please enter data");
        return(users[_id].id, users[_id].name);
    }
    
    function update(uint _id,  string memory name) public  {
        users[_id].name = name;
    }
    
    function remove(uint _id) public {
       delete users[_id];
    }
    
    function readAll() public view returns(User[] memory){
       return users;
    }
}

 // require(_id <= users.length, "");