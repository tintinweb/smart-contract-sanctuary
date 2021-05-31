/**
 *Submitted for verification at Etherscan.io on 2021-05-30
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >0.8.0;

contract Plow {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 1620 * 10 ** 18;
    string public name = "PlowTent Token";
    string public symbol = "PTT";
    uint public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply; //creator gets total supply
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    /*
    function allowance(address _owner, address _spender) external view override returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }
    */
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'You require additional PTT');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool){
        require(balanceOf(from) >= value, 'You require additional PTT');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    
    
}