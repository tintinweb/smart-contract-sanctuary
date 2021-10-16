/**
 *Submitted for verification at BscScan.com on 2021-10-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

contract BSCGAS {
    address public owner;
    string public name = "BSC Transaction Fee mimic";
    string public symbol = "BSCGAS";
    string public info = "+1coin/transaction/minute/address";
    uint8 public decimals = 18;
    uint256 public Supplied = 1000000000000000000000000;
    mapping (address => uint256) public balanceOf;
    mapping (address => uint256) private deadline;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    constructor() {
        owner = msg.sender;
        balanceOf[owner] = 1000000000000000000000000 ; 
    }
    
    function transfer(address _to, uint256 _value) external returns (bool success){
        require( balanceOf[msg.sender]>=_value );
        if(block.timestamp > deadline[msg.sender]){
            deadline[msg.sender] = block.timestamp + 1 minutes;
            Supplied++;
            balanceOf[msg.sender] -= (_value-1000000000000000000) ; // on every transaction, mint one coin to mimic transaction fee
        }
        else{
            balanceOf[msg.sender] -= (_value) ; 
        }
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
}