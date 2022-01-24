/**
 *Submitted for verification at BscScan.com on 2022-01-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//Compiler 0.8.7+commi.e28d00a7
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract CyberGPU {
    mapping(address => uint) public balances;
    uint public totalSupply = 100000000 *10 **18; 
    string public name = "CyberGPU";
    string public symbol = "CGPU";
    uint public decimals = 18;


//Detect transfer when it's done
event Transfer(address indexed from, address indexed to, uint value);
event Approval(address indexed owner, address indexed spender, uint value);


    constructor() {
        balances[msg.sender] = totalSupply; // 100 000 000 Token for Reward Pool
    }

    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }

    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'Balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value); //Event
        return true;
    }


        //Delagated transfer smart contract
        mapping(address => mapping(address => uint)) public allowance;

        function transferFrom(address from, address to, uint value) public returns(bool) {
            require(balanceOf(from) >= value, 'Balance too low');
            require(allowance[from][msg.sender] >= value, 'allowance too low');
            balances[to] += value;
            balances[from] -= value;

            emit Transfer(from, to, value); //Event
            return true;
        }

        function approve(address spender, uint value) public returns(bool) {
            allowance[msg.sender][spender] = value;
            emit Approval(msg.sender, spender, value); //Event
            return true;
        }

}