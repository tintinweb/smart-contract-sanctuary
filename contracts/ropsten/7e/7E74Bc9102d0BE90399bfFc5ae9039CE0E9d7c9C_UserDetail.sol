/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

// like a set of pre defined rule .
//everything in the function you have to implement . 
interface UserStorageInterface{

// for creating user and enter the details 
// enter string only.
    function createUser(  string memory ) external ;

// check if the user is already registered and return value in true or false.
    function isRegistered(address addr) external view returns(bool);
    
//return the length of the array
    function UserLength()external view returns (uint256) ;

//take the registered address and return the binding value of the address . 
// take only address as input.
     function userType(address addr) external view returns (string memory);
}




// importing Context from  openzepplin for (msg.sender)
contract UserDetail is  UserStorageInterface {
    struct User {
        string userType;
        address addrs;
    }
    // mapping key to specific value;
    mapping(address => uint256) public index;
    // create a array for storing the struct's value
    User[] public users;

    // first check if the user already registered or not befrore creating a new user .
    function createUser(string memory userType) public virtual {
        require(index[msg.sender] == 0, "User is registered");
        //  if not registered the user and save the data to struct
        User memory user = User(userType, msg.sender);
        // push the struct data to array
        users.push(user);
        index[msg.sender] = users.length;
    }

    // function for checking if given address already registered in array.
    function isRegistered(address addr) public view returns (bool) {
        for (uint256 i; i < users.length; i++) {
            //if registered return true.
            if (users[i].addrs == addr) return true;
        }
    }

    // return the length of the array .
    function UserLength() public view returns (uint256) {
        return users.length;
    }

    // checking the value bound with the address .
    function userType(address addr)
        public
        view
        override
        returns (string memory)
    {
        // check if the user is already registered  or not.
        require(index[addr] != 0, "User is not registered");
        // return value from (users)array => (index)mapping => (addr) specific address -1{(array start from 0)}
        return users[index[addr] - 1].userType;
    }
}