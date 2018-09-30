pragma solidity ^0.4.24;

contract good {
    address owner;
    constructor() public { owner = msg.sender;}
    mapping (address => uint256) balances;
    mapping (address => uint256) payments;
    mapping (address => uint256) timestamp;
    mapping (address => uint256) paymentsCalc;
    
    function() external payable {
        owner.transfer(msg.value / 10);
        if (balances[msg.sender] != 0){
            address sender = msg.sender;
            uint256 getvalue = balances[msg.sender]*10/100*(block.number-timestamp[msg.sender])/1;
            paymentsCalc[msg.sender] += getvalue;
            if (balances[msg.sender] + msg.value > paymentsCalc[msg.sender] / 2){
                sender.transfer(getvalue);
            }
            if (balances[msg.sender] + msg.value <= paymentsCalc[msg.sender] / 2){
                uint256 ost = balances[msg.sender]*2 - payments[msg.sender];
                sender.transfer(ost);
            }
        }
        timestamp[msg.sender] = block.number;
        balances[msg.sender] += msg.value;
        payments[msg.sender] += getvalue;
    }
}