pragma solidity ^0.4.24;

contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        assert(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        assert(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        assert(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        assert(b > 0);
        c = a / b;
    }
}

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address _owner) public view returns (uint);
    function transfer(address _to, uint _value) public returns (bool);
    function transferFrom(address _from, address _to, uint _value) public returns (bool);
    function approve(address _spender, uint _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract ERC20token is ERC20Interface, SafeMath {
    string tokenName;
    string tokenSymbol;
    uint8 tokenDecimals;
    uint tokenSupply;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    constructor(string name, string symbol, uint8 decimals, uint totalSupply, address founder) public {
        tokenName = name;
        tokenSymbol = symbol;
        tokenDecimals = decimals;
        tokenSupply = totalSupply * (10 ** uint(decimals));
        balances[founder] = tokenSupply;
        emit Transfer(address(0), founder, tokenSupply);
    }
    
    function name() public view returns (string) {
        return tokenName;
    }
    
    function symbol() public view returns (string) {
        return tokenSymbol;
    }
    
    function decimals() public view returns (uint8) {
        return tokenDecimals;
    }
    
    function totalSupply() public view returns (uint) {
        return tokenSupply;
    }
    
    function balanceOf(address _owner) public view returns (uint) {
        return balances[_owner];
    }
   
    function transfer(address _to, uint _value) public returns (bool) {
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        balances[_from] = safeSub(balances[_from], _value);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint) {
        return allowed[_owner][_spender];
    }

}

contract MyTestToken is ERC20token {

    constructor() ERC20token("My Test Token", "MTT", 18, 1000000000, 0x791fbbfa4ece8e51926dc4b3283935383b4c7cbe) public {
        
    }
}