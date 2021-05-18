/**
 *Submitted for verification at Etherscan.io on 2021-05-17
*/

//SPDX-License-Identifier: GPL-3.0;

pragma solidity ^0.6.3;


interface Token {
    function totalSupply() external view returns(uint256 supply);  // the total amount of tokens, declared when creating the contract.
    function balanceOf(address _owner) external view returns(uint256 balance);
    
    function allowance(address _owner, address _spender) external view returns(uint256 remaining);
    function transfer(address _to, uint256 _value) external returns (bool didOperationSucceed);
    
    function approve(address _spender, uint256 _value) external returns (bool didOperationSucceed);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool didOperationSucceed);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event Approval(address indexed Owner, address indexed spender, uint256 value);
}

contract StandardToken is Token {
    mapping(address => uint256) internal _balances;
    mapping(address => mapping (address => uint256)) internal _allowed;
    uint256 internal _totalSupply;
    
    function totalSupply() external view override returns (uint256 supply) {
        return _totalSupply;
    }
    
    function balanceOf(address _owner) public view override returns(uint256) {
        return _balances[_owner];
    }
    
    function allowance(address _owner, address _spender) public view override returns(uint256) {
        return _allowed[_owner][_spender];
    }
    
    function transfer(address _to, uint256 _value) public override returns (bool) {
        require(_value <= _balances[msg.sender]);
        require(_to != address(0));
        
        require(_balances[_to] + _value > 0);
        
        _balances[msg.sender] -= _value;
        _balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public override returns (bool) {
        require(_spender != address(0));
        
        _allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public override returns(bool) {
        require(_value <= _balances[_from]);
        require(_value <= _allowed[_from][msg.sender]);
        require(_to != address(0));
        require(_balances[_to] + _value > 0);
        
        _balances[_from] -= _value;
        _allowed[_from][msg.sender] += _value;
        _balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}

contract BlockchainDevToken is StandardToken {
    string public name;
    uint8 public decimals;
    string public symbol;
    uint256 public unitsOneEthCanBuy;
    uint256 public totalRaisedEthInWei;
    address payable public owner;
    
    constructor() public {
        decimals = 18;
        _totalSupply = (1000 * 10^18);
        _balances[msg.sender] = _totalSupply;
        
        name = "Blockchain Dev Token";
        symbol = "BDT";
        unitsOneEthCanBuy = 10;
        
        owner = msg.sender;
    }
    
    receive() external payable {
        totalRaisedEthInWei = totalRaisedEthInWei + msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy;
        require(_balances[owner] >= amount);
        _balances[owner] -= amount;
        _balances[msg.sender] += amount;
        Transfer(owner, msg.sender, amount);
        owner.transfer(msg.value);
    }
    
    
}