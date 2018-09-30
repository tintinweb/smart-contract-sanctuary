pragma solidity ^0.4.16;

contract SafeMath {
    function safeAdd(uint256 x, uint256 y) internal pure returns(uint256) {
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

contract Token {
     /// total amount of tokens
    uint256 public totalSupply;
    
    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant public returns (uint256  balance);
    
    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success);
    
     /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    
    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);
    
    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/*  ERC 20 token */
contract StandardToken is Token ,SafeMath{
    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] = safeSubtract(balances[msg.sender],_value);
            balances[_to] = safeAdd(balances[_to],_value) ;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] = safeAdd(balances[_to],_value) ;
            balances[_from] = safeSubtract(balances[_from],_value) ;
            allowed[_from][msg.sender] = safeSubtract(allowed[_from][msg.sender],_value);
            emit Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
       emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract POCCToken is StandardToken  {
    // metadata
    string  public constant name = "POCC Token";
    string  public constant symbol = "POCC";                                
    uint256 public constant decimals = 18;
    string  public version = "1.0";
    uint256 public tokenExchangeRate = 80000;                              // 80000  tokens per 1 ETH
    
    address public owner; //owner
    
    // events 
    event DecreaseSupply(uint256 _value);

    // constructor
    constructor(address _owner) public {
        owner = _owner;
        totalSupply = safeMult(10000000000,10 ** decimals);
        balances[owner] = totalSupply;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
   
     /// @dev decrease the token&#39;s supply
    function decreaseSupply (uint256 _value) onlyOwner  public{
        if (balances[owner] < _value)  revert();
        uint256 value = safeMult(_value , 10 ** decimals);
        balances[owner] = safeSubtract(balances[owner],value);
        totalSupply = safeSubtract(totalSupply, value);
        emit DecreaseSupply(value);
    }
    
}