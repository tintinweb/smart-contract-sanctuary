/**
 *Submitted for verification at Etherscan.io on 2019-07-05
*/

pragma solidity ^0.4.24;

contract Test{
    struct User{
        uint256 id;
        string name;
        bool exist;
    }
    address public owner;
    mapping (address => User) public users;
    
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    constructor() public{
        owner = msg.sender;
    }
    function createUser(address userAddress, uint256 userId, string name) onlyOwner public{
        require(!users[userAddress].exist);
        
        users[userAddress] = User({
            id: userId,
            name: name,
            exist: true
        });
    }
    function updateUser(address userAddress, uint256 userId, string name) onlyOwner public{
        require(users[userAddress].exist);
        
        users[userAddress].id = userId;
        users[userAddress].name = name;
    }
    function removeUser(address userAddress) onlyOwner public{
        require(users[userAddress].exist);
        delete users[userAddress];
    }
}