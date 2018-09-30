pragma solidity ^0.4.16;

contract SafeMath {
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}


contract ERC20 is SafeMath {
    uint256 public totalSupply;
    function balanceOf( address who ) constant public returns (uint256 value);

    function transfer( address to, uint256 value) public returns (bool ok);
    function transferFrom( address from, address to, uint256 value) public returns (bool ok);
    function approve( address spender, uint256 value ) public returns (bool ok);

    event Transfer( address indexed from, address indexed to, uint256 value);
    event Approval( address indexed owner, address indexed spender, uint256 value);
}

 
contract Token is ERC20 {
    string public constant version  = "1.0";
    string public constant name     = "X";
    string public constant symbol   = "X";
    uint8  public constant decimals = 18;


    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => uint256) balances;

    function Token(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balances[msg.sender] = totalSupply;
        tokenName = name; 
        tokenSymbol = symbol; 
    }
    
    
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != 0x0);                               
        require(balances[_from] >= _value);                
        require(balances[_to] + _value > balances[_to]); 
        balances[_from] -= _value;                         
        balances[_to] += _value;                           
        emit Transfer(_from, _to, _value);
    }
    
    function balanceOf(address _who) public constant returns (uint256) {
        return balances[_who];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 _allowance = allowed[_from][msg.sender];
        balances[_to] = safeAdd(balances[_to], _value);
        balances[_from] = safeSub(balances[_from], _value);
        allowed[_from][msg.sender] = safeSub(_allowance, _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

}