/**
 *Submitted for verification at Etherscan.io on 2021-06-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

contract token{
   
    address immutable owner;
    string constant public name = "Wiratinaf";
    string constant public symbol = "WIF";
    uint8 constant public decimals = 3; 
    uint public totalSupply = 0;
    
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) allowed;
    
    event Transfer(address _from, address _to, uint _value);
    event Approval(address _from, address _spender, uint _value);
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call that method");
        _;
    }
    modifier canTransact(address _from, address _to, uint _value) {
        require(balances[_from] >= _value && balances[_to] + _value >= balances[_to]);
        _;
    }
    
    
    function mint(address payable _addressToMint, uint8 _value) public onlyOwner {
        balances[_addressToMint] += _value;
        totalSupply +=  _value;
    }
    
    function balanceOf(address _address) public view returns(uint) {
        return balances[_address];
    }
    function balanceOf() public view returns(uint) {
        return balances[msg.sender];
    }
    
    function transfer(address _address, uint _value) public canTransact(msg.sender, _address, _value) payable {
        
        balances[msg.sender] -= _value;
        balances[_address] += _value;
        emit Transfer(msg.sender, _address, _value);
    }
    function transferFrom (address _from, address _to, uint _value) public canTransact(_from, _to, _value) payable {
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[msg.sender][_from] -= _value;
        emit Transfer(msg.sender, _to, _value);
        emit Approval(_from, msg.sender, _value);
    }
    
    function approve (address _spender, uint _value) public payable {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }
    function allowance(address _from, address _spender) public view returns(uint) {
        return allowed[_from][_spender];
    }
}