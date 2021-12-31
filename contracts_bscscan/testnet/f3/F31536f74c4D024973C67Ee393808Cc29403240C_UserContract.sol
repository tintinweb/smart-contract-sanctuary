pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

contract UserContract {
    address payable owner;

    constructor () {
         owner = payable(msg.sender);
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    struct User {
        bool verify;
        string name;
        address user_address;
    }

    mapping (address => User) public users;

    function createUser(string memory _name, address _user_address) public {
        require(bytes(_name).length >= 4, 'name should have at least 4 characters');
        require(users[_user_address].user_address != _user_address, "User already exists,cannot update");
        users[_user_address] = User(false,_name,_user_address);
    }

    function getUser(address _user_address ) view public 
	returns(bool verify,string memory name,address user_address) {
      User memory u = users[_user_address];
      return(u.verify,u.name,u.user_address);
    }

    function verifyUser(address _user_address) public onlyOwner {
         User storage u = users[_user_address];
         require(u.verify == false, 'user is already verified' );
         u.verify = true;
    }

     receive() external payable onlyOwner{
        require(msg.sender.balance >= msg.value );
            owner.transfer(msg.value);
    }
}