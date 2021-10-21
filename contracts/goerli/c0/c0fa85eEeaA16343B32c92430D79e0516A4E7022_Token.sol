/**
 *Submitted for verification at Etherscan.io on 2021-10-20
*/

//SPDX-License-Identifier: MIT

pragma solidity = 0.8.9;

interface ERC{
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function mint(address _to, uint _value) external returns (bool success);
    function burn(address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function increaseAllowances(address _spender, uint _value) external returns(bool);
    function decreaseAllowances(address _spender, uint _value) external returns(bool);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract Token is ERC{
    string private _name;
    string private _symbol;
    uint private _totalSupply;
    uint8 private _decimals;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowances;
    constructor(string memory _tempName, string memory _tempSymbol, address _owner){
        _name = _tempName;
        _symbol = _tempSymbol;
        _decimals = 5;
        _totalSupply = 100000000000;
        balances[_owner] = _totalSupply;
    }
    function name() public view override returns(string memory){
        return _name;
    }
    function symbol() public view override returns(string memory){
        return _symbol;
    }
    function totalSupply() public view override returns(uint){
        return _totalSupply;
    }
    function decimals() public view override returns(uint8){
        return _decimals;
    }
    function balanceOf(address _owner) public override view returns (uint){
        return balances[_owner];
    }
    function transfer(address _to, uint _value) public override returns (bool){
        require(balances[msg.sender] >= _value, "Don't have that much of token to transfer");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    function approve(address _spender, uint _value) public override returns (bool){
        require(balances[msg.sender] >= _value,"Cannot set a limit bcoz you don't have that much balance");
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function allowance(address _owner, address _spender) public override view returns (uint){
        return allowances[_owner][_spender];
    }
    function transferFrom(address _from, address _to, uint _value) public override returns (bool success){
        require(allowances[_from][_to] >= _value);
        require(balances[_from] >= _value);
        balances[_from] -= _value;
        balances[_to] += _value;
        allowances[_from][_to] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    function increaseAllowances(address _spender, uint _value) public override returns(bool){
        require(balances[msg.sender] >= allowances[msg.sender][_spender]+_value, "Don't have enough balance to increase");
        allowances[msg.sender][_spender] += _value;
        emit Approval(msg.sender, _spender, allowances[msg.sender][_spender]+_value);
        return true;
    }
    function decreaseAllowances(address _spender, uint _value) public override returns(bool){
        allowances[msg.sender][_spender] -= _value;
        emit Approval(msg.sender, _spender, allowances[msg.sender][_spender]-_value);
        return true;
    }
    function burn(address _to, uint _value) public override returns (bool success){
        require(_to != address(0),"You cannot burn the token from contract itself");
        require(balances[_to] <= _value, "You don't have that much of token to burn");
        balances[_to] -= _value;
        _totalSupply -= _value;
        emit Transfer(_to, address(0),_value);
        return true;
    }
    function mint(address _to, uint _value) public override returns (bool success){
        require(_to != address(0),"You cannot mine the token from contract itself");
        _totalSupply += _value;
        balances[_to] += _value;
        emit Transfer(address(0),_to,_value);
        return true;
    }

}