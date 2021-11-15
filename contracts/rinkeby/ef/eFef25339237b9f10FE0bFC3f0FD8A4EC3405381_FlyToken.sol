// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/**
 * @title FlyToken
 * @author gotbit
 */

interface IERC20 {
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value)  external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender  , uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ERC20 is IERC20 {
    uint constant private MAX_UINT = 2**256 - 1;
    mapping (address => uint) public balances;
    mapping (address => mapping (address => uint)) public allowed;
    uint public totalSupply;

    string public name;
    uint8 public decimals;
    string public symbol;

    constructor(uint _initialAmount, string memory _tokenName, uint8 _decimalUnits, string  memory _tokenSymbol) {
        balances[msg.sender] = _initialAmount;
        totalSupply = _initialAmount;
        name = _tokenName;
        decimals = _decimalUnits;
        symbol = _tokenSymbol;
    }

    function transfer(address _to, uint _value) 
    public
    override 
    returns (bool success) {
        require(balances[msg.sender] >= _value, '[ERC20]: token balance is lower than the value requested');
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) 
    public 
    override 
    returns (bool success) {
        uint allowance_ = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance_ >= _value, '[ERC20]: token balance or allowance is lower than amount requested');
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance_ < MAX_UINT) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) 
    public 
    override 
    view 
    returns (uint balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint _value) 
    public 
    override 
    returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) 
    public 
    override 
    view 
    returns (uint remaining) {
        return allowed[_owner][_spender];
    }
}

contract FlyToken is ERC20 {

    constructor() 
    ERC20(1e28, 'FlyToken', 18, 'FLY') { }
}

