/**
 *Submitted for verification at Etherscan.io on 2021-07-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

contract MyContract {
    struct user{
        string name;
        address id;
    } 
    
    user[] private users;
    uint private count_people = 0;
    address owner;
    address payable wallet;
    mapping(address => uint256) public balances;
    
    constructor(address payable _wallet) payable{
       // get owner address    
       owner = msg.sender;
      
       //add default user
       users.push(user("caio" , owner));
       increment_count();
       
       //add wallet to send money
       wallet = _wallet;
    }
    
    //changed to become equal to user number, so it starts with 1
    
    function get_name(uint8 user_position) public view returns(string memory) {
        return users[user_position - 1].name;
    }
    
    function set_name(string memory _name , uint8 user_position) public {
        users[user_position - 1].name = _name;
    }
    
    function add_person(string memory _name , address _id) public{
        users.push(user(_name , _id));
        increment_count();
    }
    
    function get_owner() public view returns(address) {
        return owner;
    }
    
    function get_users_number() public view returns(uint) {
        return count_people;
    }
    
    function increment_count() internal {
        count_people++;
    }
    
    function send_money() public payable {
        balances[owner] += 1;
        wallet.transfer(msg.value);
    }
}