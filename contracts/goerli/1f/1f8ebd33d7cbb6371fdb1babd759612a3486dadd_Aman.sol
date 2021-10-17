/**
 *Submitted for verification at Etherscan.io on 2021-10-17
*/

//SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.0;

interface ERC{
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Aman is ERC{
    string public constant _name = "Aman";
    string public constant _symbol = "an";
    uint public constant _decimals = 7;
    uint public constant _totalSupply = 1000000;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    constructor(address _to){
        balances[_to] = _totalSupply;
    }
    function name() public override pure returns(string memory){
        return _name;
    }
    function symbol() public override pure returns(string memory){
        return _symbol;
    }
    function decimals() public override pure returns(uint){
        return _decimals;
    }
    function totalSupply() public override pure returns(uint){
        return _totalSupply;
    }
    function balanceOf(address _owner) public override view returns(uint){
        return balances[_owner];
    }
    function transfer(address _to, uint256 _value) public override returns(bool){
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    function approve(address _spender, uint256 _value) public override returns (bool){
        require(balances[msg.sender] >= _value);
        require(_value > 0);
        allowed [msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function allowance(address _owner, address _spender) public override view returns (uint){
        return allowed[_owner][_spender];
    }
    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool){
        require(allowed[_from][_to] >= _value);
        require(balances[_from] >= _value);
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][_to] -= _value;
        return true;
    }
}