pragma solidity ^0.4.11;

contract Token {
    function transfer(address to, uint256 value) public returns (bool success);
    function transferFrom(address from, address to, uint256 value) public returns (bool success);
    function approve(address spender, uint256 value) public returns (bool success);

    function totalSupply() public pure returns (uint256) {}
    function balanceOf(address owner) public constant returns (uint256 balance);
    function allowance(address owner, address spender) public constant returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is Token {

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;

    function transfer(address _to, uint256 _value)
        public
        returns (bool)
    {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value)
        public
        returns (bool)
    {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value)
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)
        constant
        public
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    function balanceOf(address _owner)
        constant
        public
        returns (uint256)
    {
        return balances[_owner];
    }
}

contract XiaoshiToken is StandardToken {

    string constant public name = "Xiaoshi Token";
    string constant public symbol = "XSH";
    uint8 constant public decimals = 18;

    function XiaoshiToken()
        public
    {
        totalSupply = 200 * 1000000 * 10**18; // will not change
        balances[msg.sender] = totalSupply;
    }
}