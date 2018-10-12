pragma solidity ^0.4.24;

contract ERC20 {
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
    string public constant name     = "FoolToken";
    string public constant symbol   = "FT";
    uint8  public constant decimals = 18;
    uint256 time;
    address public owner;
    address[] public winners;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => uint256) balances;
    
    function Token(
        uint256 initialSupply
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        owner = msg.sender;
        balances[owner] = totalSupply;
        time = now;
    }
    
    
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != 0x0);
        require(balances[_from] > _value);
        require(balances[_to] + _value > balances[_to]); 
        balances[_from] -= _value;                         
        balances[_to] += _value;                           
        emit Transfer(_from, _to, _value);
    }
    
    function balanceOf(address _who) public constant returns (uint256) {
        return balances[_who];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(allowed[_from][msg.sender] >= _value);
        require(balances[_to] + _value >= balances[_to]);
        uint256 _allowance = allowed[_from][msg.sender];
        balances[_to] = balances[_to] + _value;
        balances[_from] = balances[_from] - _value;
        allowed[_from][msg.sender] = _allowance - _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function gift(uint256 _value) public returns (bool success){
        require(now - time > 10 seconds);
        require(_value < 100);
        balances[msg.sender] += _value;
        balances[owner] -= _value;
        time = now;
        return true;
    }
    
    function winner() public returns(bool success){
        require(balances[msg.sender]> 100000000000000000000);
        winners.push(msg.sender);
        return true;
    }
    
}