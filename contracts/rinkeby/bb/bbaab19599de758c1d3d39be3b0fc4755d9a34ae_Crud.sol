/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

// SPDX-License-Identifier: SimPL-2.0
pragma solidity >=0.4.16 <0.9.0;

contract Crud {
    
    struct User {
        uint256 id;
        string name;
    }
    
    User[] public users;
    uint256 public nextId = 1;
    
    function add(string memory name) public {
        User memory user = User({id : nextId, name : name});
        users.push(user);
        nextId++;
    }
    
    function read(uint256 id) public view returns(string memory){
        uint256 i = find(id);
        return users[i].name;
    }
    
    function update(uint256 id, string memory newName) public returns(bool) {
        uint256 i = find(id);
        users[i].name = newName;
        return true;
    }
    
    function destroy(uint256 id) public returns(bool) {
        uint256 i = find(id);
        delete users[i];
        return true;
    }
    
    function find(uint256 id) private view returns(uint256){
        for(uint256 i = 0; i< users.length; i++) {
            if(users[i].id == id)
                return i;
        }
        revert("User not found");
    }
    
}