/**
 *Submitted for verification at Etherscan.io on 2021-12-29
*/

//SPDX-License-Identifier: GPL3
pragma solidity ^0.8;

contract Santa {

    struct Order {
        uint256 wei_amount;
        uint256 deadline;
        bool exists;
    }

    event Joined(address partecipant, uint256 amount);
    event Executed(address recipient, uint256 amount);

    mapping(address => mapping(address => Order)) order_map;
    mapping(address => address[]) user_map;

    function addOrder(address _recipient, uint256 _deadline_seconds) public payable{
        if (!order_map[msg.sender][_recipient].exists) {

            order_map[msg.sender][_recipient].exists = true;
            order_map[msg.sender][_recipient].wei_amount = msg.value;
            order_map[msg.sender][_recipient].deadline = block.timestamp + _deadline_seconds * 1 seconds;
            user_map[msg.sender].push(_recipient);

            emit Joined(msg.sender, msg.value);

        } else {
            sumOrder(_recipient);
        }
    }

    function sumOrder(address _recipient) public payable{
        order_map[msg.sender][_recipient].wei_amount += msg.value;
    }

    function checkOrderDate(address payable _recipient) public payable{
        if (block.timestamp <= order_map[msg.sender][_recipient].deadline){
            revert("The time for the gift is not due yet.");
        } else {
            uint amount = order_map[msg.sender][_recipient].wei_amount;
            _recipient.transfer(amount); //PAYMENT
            emit Executed(_recipient, amount);
        }
    }

    function dumpOrder(address _recipient) external view returns(Order memory){
        return order_map[msg.sender][_recipient];
    }

    function dumpRecipients() external view returns(address[] memory){
        return user_map[msg.sender];
    }

    function returnSender() external view returns(address){
        return msg.sender;
    }

    function returnTime() external view returns(uint256){
        return block.timestamp; 
    }


}