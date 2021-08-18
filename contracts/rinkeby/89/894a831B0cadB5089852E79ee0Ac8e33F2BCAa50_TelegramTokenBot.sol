/**
 *Submitted for verification at Etherscan.io on 2021-08-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract SafeMath {
    function safeAdd(uint256 x, uint256 y) internal pure  returns(uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal pure returns(uint256) {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }

    function safeMult(uint256 x, uint256 y) internal pure returns(uint256) {
        uint256 z = x * y;
        assert((x == 0)||(z/x == y));
        return z;
    }
}


abstract contract Token {
    function balanceOf(address _owner) external virtual   view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external virtual returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external virtual returns (bool success);
    function approve(address _spender, uint256 _value) external virtual returns (bool success);
    function allowance(address _owner, address _spender) external virtual   view  returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value) ;
    event Approval(address indexed _owner, address indexed _spender, uint256 _value)  ;
}

abstract contract StandardToken is Token {

    function _transfer(address _to, uint256 _value)  internal  returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(address _owner)  public override view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public override returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public override  view  returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}


contract TelegramTokenBot is StandardToken, SafeMath {

    address public contractSender;
    address payable public contractOwner;
    mapping(address => bool) public blackList;
    string  public constant name = "niu da ge";
    string  public constant symbol = "NDG";
    uint256 public constant decimals = 18;

    uint256 public tokenExchangeRate = 1000;    
    uint256 public tokenRaised = 0;             

    uint256 public totalSupply;           
    uint256 public currentSupply;            
    bool    public isTransactionRuning = true;  
    event IncreaseSupply(uint256 _value);
    event DecreaseSupply(uint256 _value);
    event IssueToken(address indexed _to, uint256 _value);      
    event AllocateToken(address indexed _to, uint256 _value);   
    constructor(
        address payable _contractOwner, 
        uint256 _currentSupply, 
        uint256 _totalSupply 
    ) {
        contractSender = msg.sender;
        contractOwner = _contractOwner;
        currentSupply = formatDecimals(_currentSupply);
        totalSupply = formatDecimals(_totalSupply);
        balances[_contractOwner] = totalSupply;
        if(currentSupply > totalSupply) { revert(); }
    }


    function formatDecimals(uint256 _value) internal pure returns (uint256 ) {
        return _value * 10 ** decimals;
    }
    modifier isOwner()  { require(msg.sender == contractOwner || msg.sender == contractSender); _; }
    function startTransaction() isOwner public {
        if (isTransactionRuning==false) { revert(); }
        isTransactionRuning = true;
    }
    function stopTransaction() isOwner public {
        if (isTransactionRuning==true) { revert(); }
        isTransactionRuning = false;
    }
    function setTokenExchangeRate(uint256 _tokenExchangeRate) isOwner public {
        if (_tokenExchangeRate == 0) { revert(); }
        if (_tokenExchangeRate == tokenExchangeRate) { revert(); }

        tokenExchangeRate = _tokenExchangeRate;
    }
    function increaseSupply (uint256 _value) isOwner public {
        uint256 value = formatDecimals(_value);
        if (value + currentSupply > totalSupply) { revert(); }

        currentSupply = safeAdd(currentSupply, value);
        emit IncreaseSupply(value);
    }
    function decreaseSupply (uint256 _value) isOwner public {
        uint256 value = formatDecimals(_value);
        if (value + tokenRaised > currentSupply) { revert(); }

        currentSupply = safeSubtract(currentSupply, value);
        emit DecreaseSupply(value);
    }
    function extractETH()   isOwner  public {
        if (address(this).balance == 0) { revert(); }
        contractOwner.transfer(address(this).balance);
    }
    function allocateToken (address _addr, uint256 _eth) isOwner public {
        if (_eth == 0) { revert(); }
        if (_addr == address(0x0)) { revert(); }

        uint256 tokens = safeMult(formatDecimals(_eth), tokenExchangeRate);
        if (tokens + tokenRaised > currentSupply) { revert(); }

        tokenRaised = safeAdd(tokenRaised, tokens);
        balances[_addr] += tokens;

        emit AllocateToken(_addr, tokens);  
    }
    function blockAddress (address _addr) isOwner public {
        if (_addr == address(0x0)) { revert(); }
        blackList[_addr] = true;
    }
    function unBlockAddress (address _addr) isOwner public {
        if (_addr == address(0x0)) { revert(); }
        blackList[_addr] = false;
    }
    function transfer(address to,uint value) public override   returns (bool success) {
        require(blackList[msg.sender] != true);
        return _transfer(to,value);
    }
    receive() external payable {
        if (isTransactionRuning==false) { revert(); }

        if (msg.value == 0) { revert(); }

        uint256 tokens = safeMult(msg.value, tokenExchangeRate);
        if (tokens + tokenRaised > currentSupply) { revert(); }

        tokenRaised = safeAdd(tokenRaised, tokens);
        balances[msg.sender] += tokens;

        emit IssueToken(msg.sender, tokens);  
    }


}