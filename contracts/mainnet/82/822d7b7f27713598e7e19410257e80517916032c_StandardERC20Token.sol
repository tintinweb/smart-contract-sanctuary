/**
 *Submitted for verification at Etherscan.io on 2020-03-16
*/

pragma solidity ^0.5.12;

contract Token {
    function balanceOf(address _owner) public view returns (uint256 balance) {}

    function transfer(address _to, uint256 _value) public returns (bool success) {}

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {}

    function approve(address _spender, uint256 _value) public returns (bool success) {}

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardERC20Token is Token {
    
    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    uint256 public totalSupply;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
   
    string public name;
    uint8 public decimals;
    string public symbol;

    constructor(uint256 _initialAmount, string memory _tokenName, uint8 _decimalUnits, string  memory _tokenSymbol) public {
        totalSupply = _initialAmount * 10 ** uint256(decimals);     // Update total supply with the decimal amount
        balances[msg.sender] = totalSupply;                         // Give the creator all initial tokens
        name = _tokenName;                                          // Set the name for display purposes
        decimals = _decimalUnits;                                   // Amount of decimals for display purposes
        symbol = _tokenSymbol;                                      // Set the symbol for display purposes
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}