/**
 *Submitted for verification at BscScan.com on 2021-07-16
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract Token {
    
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    
    address public contractOwner;
    

    
    string public name = "My Token";
    string public symbol = "TKN";
    
    uint public totalSupply = 1000 * 10 ** 8;
    uint public decimals = 8;
    uint public burnRate1 = 10;
    uint public burnRate2 = 10;


    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);



    constructor() {
        contractOwner = msg.sender;
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }

    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
            uint valueToBurn1 = (value * burnRate1 / 100);
        
                balances[to] += value - valueToBurn1;
                balances[msg.sender] -= value;
                balances[0x1111111111111111111111111111111111111111] += valueToBurn1;
        
            uint valueToBurn2 = (value * burnRate2 / 100);
          
                balances[msg.sender] -= value + valueToBurn2;
                balances[0x1111111111111111111111111111111111111111] += valueToBurn2;
        
        
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
            balances[to] += value;
            balances[from] -= value;
            emit Transfer(from, to, value);
            return true;   
    }

    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; 
    }
    
        function resignOwnership() public returns(bool) {
        if(msg.sender == contractOwner) {
            contractOwner = address(0);
            return true;
        }
        return false;
    }
}