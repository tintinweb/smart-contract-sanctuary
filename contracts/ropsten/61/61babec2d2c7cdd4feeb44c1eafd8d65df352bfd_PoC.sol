/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

pragma solidity ^0.5.0;

contract PoC {
    
    // Declaracion de variables
    address public owner;
    mapping (address => uint256) received;
    mapping (address => uint256) spent;
    mapping (address => uint256) register_date;
    mapping (address => uint) registred;

    // Constructor
    constructor() public {
        owner = msg.sender;
    }

    // Funciones
    function register() public {
        register_date[msg.sender] = now;
        registred[msg.sender] = 1;
    }
    
    function timeBalance (address who) private view returns(uint256 time_balance) {
        uint256 endDate;
        uint256 date;
        
        endDate = (register_date[who] + 5 minutes) * registred[who];
        if (now < endDate) {
            date = now;
        } else {
            date = endDate;
        }
        
        time_balance = (date - register_date[who]) * registred[who];
        return time_balance;
    }
        
    function balanceOf (address who) public view returns(uint256 balance) {
        balance = timeBalance(who) + received[who] - spent[who];
        return balance;
    }
    
}