/**
 *Submitted for verification at BscScan.com on 2021-12-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Token{

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;

    address public admin;

    // Token configuration
    uint public supply = 10000000;
    string public name = "EGEND Coin";
    string public symbol = "EGD";
    uint public decimals = 2;
    uint public totalSupply = supply * 10 ** decimals;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(){
        // Send all tokens to deployer and give admin privileges
        balances[msg.sender] = totalSupply;
        admin = msg.sender;
    }

    // Returns balance of a wallet
    function balanceOf(address owner) public view returns(uint){
        return balances[owner];
    }

    // Returns allowance
    function allowanceOf(address owner, address spender) public view returns (uint256) {
        return allowance[owner][spender];
    }

    // Transfer tokens between two wallets
    function transfer(address to, uint value) public returns(bool){
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    // Approval transfers
    function approve(address spender, uint value) public returns (bool){
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    // Transfer after approval
    function transferFrom(address from, address to, uint value) public returns(bool){
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }


    // Decrease token supply
    function destroyTokens(uint value) public returns (bool){
        require(msg.sender == admin, 'Only admin can do it');
        balances[msg.sender] -= value;
        supply -= value;
        return true;
    }


    // Transfer ownership to 0 address
    function resignOwnership() public returns (bool) {
        if(msg.sender == admin){
            admin = address(0);
            emit OwnershipTransferred(admin, address(0));  
            return true;
        }
        return false;
    }

}