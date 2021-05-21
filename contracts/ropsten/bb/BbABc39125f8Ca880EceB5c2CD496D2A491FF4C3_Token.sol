/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

pragma solidity ^0.8.0;


contract Token {
    
    string private _symbol = "CS188";
    string private _name = "905303766";
    uint8 private _decimals = 18;
    uint256 public _totalSupply;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    //constructor
    constructor() public {
        _balances[msg.sender] = 3;
        _totalSupply += 3;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
       return _totalSupply; 
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return _balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_value <= _balances[msg.sender]);
        require(_to != address(0));
        require(_value >= 0);

        _balances[msg.sender] -= _value;
        _balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_from != address(0));
        require(_value <= _balances[_from]);
        require(_to != address(0));
        require(_value >= 0);

        _balances[_from] -= _value;
        _balances[_to] += _value;
        
        emit Transfer(_from, _to, _value);
        return true;
        
        
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_value >= 0);
        require(_spender != address(0));
        _allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;

        
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return _allowances[_owner][_spender];
    }

}