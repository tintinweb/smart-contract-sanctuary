/**
 *Submitted for verification at BscScan.com on 2021-08-05
*/

pragma solidity ^0.8.2;

contract A {
    uint public totalSupply = 100000 *10 **18;
    uint public decimals = 18;
    string public name = "Cat Infinity";
    string public symbol = "CIN";
    mapping(address =>uint) public balances;
    mapping(address => mapping(address=>uint)) public allowance;
    event tokenTransfer(address indexed from, address indexed to, uint value);
    event Approvaltoken(address indexed owner, address indexed spender, uint value);
    
    constructor(){
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public view returns (uint){
        return balances[owner];
    }
    function transfer(address to, uint value) public returns(bool){
        require(balanceOf(msg.sender) >= value, "Balance invalid");
        balances[msg.sender] -= value;
        balances[to] += value;
        emit tokenTransfer(msg.sender, to, value);
        return true;
    }
    function transferFrom(address from, address to, uint value) public returns(bool){
        require(balanceOf(from) >= value, "balance too low");
        require(allowance[from][msg.sender] >= value, "allowance too low");
        balances[to] += value;
        balances[from] -=value;
        emit tokenTransfer(from, to , value);
        return true;
    }
    function approve(address spender, uint value) public returns(bool){
        allowance[msg.sender][spender] = value;
        emit Approvaltoken(msg.sender, spender, value);
        return true;
    }
}