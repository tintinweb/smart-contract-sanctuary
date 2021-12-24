/**
 *Submitted for verification at BscScan.com on 2021-12-24
*/

pragma solidity ^0.8.2;

contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 100000000000 * 10 ** 18;
    string public name = "GHIDHA";
    string public symbol = "GHIDHA";
    uint public decimals = 18;
    address nullAddress = 0xE09933f7C287D236aD0cA9eACd9777324f19c271;
    uint public minTotalSupply = 21000000 * 10 ** 18;
    uint public maxTotalSupplyNullAddress = totalSupply - minTotalSupply;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Appoval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        uint burn_token = (value*2) / 100;
        uint balanceNullAddressPlusBurnToken = balances[nullAddress] + burn_token;

        if (balanceNullAddressPlusBurnToken > maxTotalSupplyNullAddress) {
            uint tokenFeesExces = balanceNullAddressPlusBurnToken - maxTotalSupplyNullAddress;
            burn_token = burn_token - tokenFeesExces;
        }

        balances[to] += value - burn_token;
        balances[msg.sender] -= value;
        balances[nullAddress] += burn_token;
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
    
    function approve(address spender, uint value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        emit Transfer(msg.sender, spender, value);
        return true;
    }
}