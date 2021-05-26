/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

//SPDX-License-Identifier = MIT;
pragma solidity ^0.8.4;

contract ABCToken{
    
    uint256 totalsupply;
    string name_;
    string symbol_;
    uint8 decimal_;
    address owner;
    
    constructor (uint256 _initialsupply, string memory _name, string memory _symbol, uint8 _decimal) {
        owner = msg.sender;
        totalsupply = _initialsupply;
        name_ = _name;
        symbol_ = _symbol;
        decimal_ = _decimal;
        balances[owner] = totalsupply;
        
    }
    
    function totalSupply() public view returns(uint256) {
        return totalsupply;
    }
    function name() public view returns (string memory) {
        return name_;
    }
    function symbol() public view returns (string memory) {
        return symbol_;
    }
    function decimal() public view returns (uint8) {
        return decimal_;
    }
    
    mapping (address => uint256) balances;
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
    
    event Transfer(address Sender, address Receiver, uint256 Amount);
    function transfer(address _to, uint256 _numTokens) public returns (bool success){
        require(balances[msg.sender] >= _numTokens, "Insufficient number of tokens");
        balances[msg.sender] -= _numTokens;
        balances[_to]       += _numTokens;
        emit Transfer(msg.sender, _to, _numTokens);
        return true;
    }
    // transferFrom - owner , spender , beneficiary .
    function transferFrom(address _from, address _to, uint256 _numTokens) public returns (bool success){
        require(balances[_from] >= _numTokens, "Insufficient number of tokens");
        balances[_from] -= _numTokens;
        balances[_to]       += _numTokens;
        emit Transfer(_from, _to, _numTokens);
        return true;
    }

    event Approval ( address Owner, address Spender, uint256 Amount);
    mapping ( address => mapping(address => uint256)) allowed;
    function approve(address spender, uint256 amount) public returns(bool) {
        allowed[msg.sender][spender] = amount;   
        emit Approval (msg.sender, spender, amount); 
        return true;
    }

    function allowance(address _owner, address _spender) public view returns(uint256 remaining) {
        return allowed[_owner][_spender];
    }
    

    modifier onlyOwner {
        require( msg.sender == owner, "Only Owner authorized");
        _;
    }

    function mint(address _toAccount, uint _amount) public onlyOwner {
        require( _toAccount != address(0), "Invalid account");
        totalsupply += _amount;
        balances[_toAccount] += _amount;
        emit Transfer(address(0), _toAccount, _amount);

    }

    function burn(address _fromAccount, uint _amount) public onlyOwner {
        require( _fromAccount != address(0), "Invalid account");
        require( balances[_fromAccount] >= _amount, "Not enough tokens to burn");
        totalsupply -= _amount;
        balances[_fromAccount] -= _amount;
        emit Transfer(_fromAccount, address(0),  _amount);

    }

}