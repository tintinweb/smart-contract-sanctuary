pragma solidity ^0.4.16;

interface token_recipient { function approved(address _from, uint256 _value, address _token, bytes _data) public; }

contract ERC20 {
    string public name;
    string public symbol;
    uint8 public decimals = 2;
    uint256 public totalSupply;
    address public owner;
    mapping (address => uint256) public balance;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Burn(address indexed from, uint256 value);
    
    function ERC20 (string token_name, string token_symbol, uint256 supply) public {
        name = token_name;
        symbol = token_symbol;
        totalSupply = supply * 10 ** uint256(decimals);
        owner = msg.sender;
        balance[msg.sender] = totalSupply;
    }
    
    modifier owned {
        require(msg.sender == owner); 
        _;
    }

    function _transfer (address _from, address _to, uint256 _value) internal {
        require(_to != 0x0);
        require(balance[_from] >= _value);
        require(balance[_to] + _value > balance[_to]);
        uint prev_balances = balance[_from] + balance[_to];
        balance[_from] -= _value;
        balance[_to] += _value;
        Transfer(_from, _to, _value);
        assert(balance[_from] + balance[_to] == prev_balances);
    }
    
    function approve (address _spender, uint256 _value, bytes _data) public {
        allowance[msg.sender][_spender] = _value;
        token_recipient spender = token_recipient(_spender);
        spender.approved(msg.sender, _value, this, _data);
    }
    
    function transfer (address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    
    function burn(uint256 _value) public returns (bool success) {
        require(balance[msg.sender] >= _value); 
        balance[msg.sender] -= _value;
        totalSupply -= _value; 
        Burn(msg.sender, _value);
        return true;
    }
    
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balance[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]); 
        balance[_from] -= _value;
        allowance[_from][msg.sender] -= _value; 
        totalSupply -= _value; 
        Burn(_from, _value);
        return true;
    }
    
    function mint(address target, uint256 mint_value) public owned {
        balance[target] += mint_value;
        totalSupply += mint_value;
        Transfer(0, this, mint_value);
        Transfer(this, target, mint_value);
    }
}