/**
 *Submitted for verification at Etherscan.io on 2021-06-27
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

contract Token{
    string public constant name = "Dubovitskiy's First Token";
    string public constant symbol = "DFT";
    uint8 public constant decimals = 6;
    uint public totalSupply = 0;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    address owner;
    
    modifier onlyOwner(){
        require(msg.sender == owner, "Only owner can do this!");
        _;
    }
    
    modifier canTransact(address _from, address _to, uint _value){
        require(balances[_from] >= _value && totalSupply + _value >= totalSupply && balances[_to] + _value >= balances[_to]);
        _;
    }
    
    constructor(){
        owner = msg.sender;
    }
    
    event Transfer(address _addressFrom, address _addressTo, uint _tokenNum);
    event Approval(address _addressFrom, address _addressSpender, uint _tokenNum);
    
    function mint(address _address, uint _NumOfDec) public onlyOwner payable{
        require(totalSupply + _NumOfDec >= totalSupply && balances[_address] + _NumOfDec >= balances[_address]);
        totalSupply += _NumOfDec;
        balances[_address] += _NumOfDec;
    }
    
    function balanceOf(address _address) public view returns(uint){
        return balances[_address];
    }
    
    function balanceOf()public view returns(uint){
        return balances[msg.sender];
    }
    

    
    function transfer(address _addressTo, uint _tokenNum) public canTransact(msg.sender, _addressTo, _tokenNum) payable{
        balances[msg.sender] -= _tokenNum;
        balances[_addressTo] += _tokenNum;
        emit Transfer(msg.sender, _addressTo, _tokenNum);
    }
    
    function transferFrom(address _addressFrom, address _addressTo, uint _tokenNum) public canTransact(_addressFrom, _addressTo, _tokenNum) payable{
        balances[_addressFrom] -= _tokenNum;
        balances[_addressTo] += _tokenNum;
        allowed[msg.sender][_addressFrom] -= _tokenNum;
        emit Transfer(_addressFrom, _addressTo, _tokenNum);
        emit Approval(_addressFrom, _addressTo, _tokenNum);
    }
    
    function approve(address _addressSpender, uint _tokenNum) public payable{
        allowed[msg.sender][_addressSpender] = _tokenNum;
        emit Approval(msg.sender, _addressSpender, _tokenNum);
    }
    
    function allowance(address _addressFrom, address _addressSpender) public view returns(uint){
        return allowed[_addressFrom][_addressSpender];
    }
}