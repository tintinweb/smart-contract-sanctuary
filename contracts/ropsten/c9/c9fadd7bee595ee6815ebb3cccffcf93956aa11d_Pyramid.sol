/**
 *Submitted for verification at Etherscan.io on 2021-05-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Pyramid{
    
    event event_add_funds(uint256 Value);
    event event_add_level(string Level, uint256 Value);
    
    address payable owner;
    uint256 funds;

    
    struct Level {
        string member;
        address payable member_address;
        uint256 member_funds;
        uint256 member_time;
    }
    
    address[] all_levels;
    
    mapping(address=>Level) get_member;
    
    constructor(string memory name, uint256 amount){
        owner = payable(msg.sender);
        funds = amount;
    }
    
    modifier IsOwner(){
        require(payable(msg.sender) == owner, "You are not the owner!");
        _;
    }
    
    // add funds to their level
    function add_funds (uint256 value) public returns(uint256){
        get_member[payable(msg.sender)].member_funds += value;
        emit event_add_funds(value);
        reset_time(); // would start the timer
        return value;
    }
    
    // add another person to the pyramid
    function add_level (string memory name, uint256 amount) public{
        all_levels.push(payable(msg.sender));
        get_member[payable(msg.sender)].member = name;
        get_member[payable(msg.sender)].member_address = payable(msg.sender);
        get_member[payable(msg.sender)].member_funds = amount;
        get_member[payable(msg.sender)].member_time = block.timestamp;
        emit event_add_level(name, amount);
    }
    
    //get the total amount of money in the pyramid
    function get_total_funds () external view IsOwner returns(uint256){
        uint256 sum = 0;
        for (uint256 i=0; i<all_levels.length;i++){
            address tmp = all_levels[i];
            sum += get_member[tmp].member_funds;
        }
        return sum + funds;
    }

    //add interest
    function add_interest() public returns(uint256) {
        if ((block.timestamp -  get_member[payable(msg.sender)].member_time) >= 1 days){
            uint256 temp = get_member[payable(msg.sender)].member_funds;
            temp = temp + temp/10;
            get_member[payable(msg.sender)].member_funds = temp;
        }
        return get_member[payable(msg.sender)].member_funds;
    }
    
    // resart timer to start at time funds are added
    function reset_time() public {
        get_member[payable(msg.sender)].member_time = block.timestamp;
    }
    
    // destroy the pyramid and all funds are turned to the owner of the pyramid
    function Destroy() external IsOwner{
        selfdestruct(owner);
    }
    
}