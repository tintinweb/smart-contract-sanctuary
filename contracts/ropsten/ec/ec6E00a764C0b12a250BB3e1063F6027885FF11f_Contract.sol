/**
 *Submitted for verification at Etherscan.io on 2021-06-25
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

contract Contract {
    string public name = "Krymis";
    string public symbol = "KMIS";
    uint8 public decimals = 6;
    uint public totalSupply = 0;
    
    mapping(address => uint) balances;
    
    address owner;
    
    mapping(address => mapping(address => uint)) allowed;
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }
    
    event Transfer(address _from, address _to, uint count);
    event Approval(address _from, address _to, uint count);
    
    function mint(address addr, uint count) public onlyOwner payable {
        require(totalSupply + count >= totalSupply && balances[addr] + count >= balances[addr]);
        balances[addr] += count;
        totalSupply += count; 
    }
    function balanceOf(address addr) public view returns(uint) {
        return balances[addr];
    }
    function balanceOf() public view returns(uint) {
        return balances[msg.sender];
    }
    function approve(address _to, uint count) public payable {
        allowed[msg.sender][_to] = count;
        emit Approval(msg.sender, _to, count);
    }
    function allowance(address _to, address _from) public view returns(uint) {
        return allowed[_from][_to];
    }
    function transfer(address addr, uint count) public payable {
        require(balances[msg.sender] >= count && balances[addr] + count >= balances[addr]);
        balances[msg.sender] -= count;
        balances[addr] += count;
        emit Transfer(msg.sender, addr, count);
    }
    function transferFrom(address _to, address _from, uint count) public payable {
        require(balances[_from] >= count && balances[_to] + count >= balances[_to]);
        require(allowed[_from][_to] >= count);
        balances[_from] -= count;
        balances[_to] += count;
        allowed[_from][msg.sender] -= count;
        emit Transfer(_from, _to, count);
        emit Approval(_from, msg.sender, count);
    }
}