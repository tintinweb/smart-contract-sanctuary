pragma solidity ^0.4.10;

contract SafeMath {

    function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x + y;
      assert((z >= x) && (z >= y));
      return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal returns(uint256) {
      assert(x >= y);
      uint256 z = x - y;
      return z;
    }

    function safeMult(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x * y;
      assert((x == 0)||(z/x == y));
      return z;
    }

}

contract ERC20Interface is SafeMath {

    uint256 public decimals = 0;
    uint256 public _totalSupply = 5;
    bool public constant isToken = true;

    address public owner;
    
    // Store the token balance for each user
    mapping(address => uint256) balances;

    mapping(address => mapping(address => uint256)) allowed;

    function ERC20Interface()
    {
        owner = msg.sender;
        balances[owner] = _totalSupply;
    }

    function transfer(address _to, uint256 _value)
        returns (bool success)
    {
        assert(balances[msg.sender] >= _value);
        balances[msg.sender] = safeSubtract(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value)
        returns (bool success)
    {
        assert(allowance(msg.sender, _from) >= _value);
        balances[_from] = safeSubtract(balances[_from], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        allowed[msg.sender][_from] = safeSubtract(allowed[msg.sender][_from], _value);
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) 
        constant returns (uint256 balance)
    {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) 
        returns (bool success)
    {
        assert(balances[msg.sender] >= _value);
        allowed[_spender][msg.sender] = safeAdd(allowed[_spender][msg.sender], _value);
        return true;
    }

    function allowance(address _owner, address _spender)
        constant returns (uint256 allowance)
    {
        return allowed[_owner][_spender];
    }
  
    // Triggered when tokens are transferred.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
  
    // Triggered whenever approve(address _spender, uint256 _value) is called.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Iou is ERC20Interface {
    string public constant symbol = "IOU";
    string public constant name = "I owe you";
    string public constant longDescription = "Buy or trade IOUs from Connor";

    // Basically a decorator _; is were the main function will go
    modifier onlyOwner() 
    {
        require(msg.sender == owner);
        _;
    }

    function Iou() ERC20Interface() {}

    function changeOwner(address _newOwner) 
        onlyOwner()
    {
        owner = _newOwner;
    }
}