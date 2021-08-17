/**
 *Submitted for verification at Etherscan.io on 2021-08-17
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.0;

contract Erc20 {
    
    string private _name = "My Coin";
    string private _symbol = "MC";
    uint private _decimals = 18;
    uint private _totalSupply = 0;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowances;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function name() public view returns (string){
        return _name;
    }
    
    function symbol() public view returns (string){
        return _symbol;
    }

    function decimals() public view returns (uint){
        return _decimals;
    }

    function totalSupply() public view returns (uint256){
        return _totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256){
        return balances[_owner];
    }
    
    function _transfer(address _from, address _to, uint256 _value) private {
        require(_from != address(0));
        require(_to != address(0));
        uint balanceOfForm = balances[_from];
        require(balanceOfForm >= _value);
        balances[_from] = balanceOfForm - _value;
        balances[_to] +=_value;
        emit Transfer(msg.sender, _to, _value);
    }
    
    function _approve(address _owner, address _spender, uint256 _value) private {
        require(_owner != address(0));
        require(_spender != address(0));
        allowances[_owner][_spender]=_value;
        emit Approval(_owner, _spender, _value);
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success){
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        uint allowanceFromOwnerToSpender = allowances[_from][msg.sender];
        require(allowanceFromOwnerToSpender >= _value);
        _transfer(_from, _to, _value);
        _approve(_from, msg.sender, allowanceFromOwnerToSpender - _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success){
        _approve(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return allowances[_owner][_spender];
    }
    
    function() public payable{
        require(msg.sender != address(0));
        _totalSupply += msg.value;
        balances[msg.sender] += msg.value;
        emit Transfer(address(0), msg.sender, msg.value);
    }

}