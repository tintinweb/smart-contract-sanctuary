pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

/// ----------------------------------------------------------------------------
/// @title Standard ERC20 token
/// @dev Implementation of the basic standard token.
/// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
/// ----------------------------------------------------------------------------

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract StandardToken {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public owner;
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowed;
    mapping (address => bool) public frozenAccount;

    constructor(uint256 initialSupply, string tokenName, string tokenSymbol, uint8 tokenDecimals) public {
        totalSupply = initialSupply;
        name = tokenName;
        symbol = tokenSymbol;
        decimals = tokenDecimals;
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed _from, uint256 _value);
    event FrozenFunds(address target, bool frozen);
    

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
   
    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not 
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != 0);
        require(!frozenAccount[msg.sender], "source account frozen");
        require(!frozenAccount[_to], "destination account frozen");
        //require(balances[msg.sender] >= _value, "insufficient balance");
        //require(balances[_to] + _value >= balances[_to], "overflow");
 
        //balances[msg.sender] -= _value;
        balances[msg.sender] = balances[msg.sender].sub(_value);
        //balances[_to] += _value;
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != 0);
        require(!frozenAccount[_from], "source account frozen");
        require(!frozenAccount[_to], "destination account frozen");
        //require(balances[_from] >= _value, "insufficient balance");
        //require(allowed[_from][msg.sender] >= _value, "insufficient allowance banlance");
        //require(balances[_to] + _value >= balances[_to], "overflow");
        
        //balances[_from] -= _value;
        balances[_from] = balances[_from].sub(_value);
        //balances[_to] += _value;
        balances[_to] = balances[_to].add(_value);
        //allowed[_from][msg.sender] -= _value;
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        
        emit Transfer(_from, _to, _value);
        
        return true;
    }

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /// @notice Remove `_value` tokens from the system irreversibly
    /// @param _value the amount of money to burn
    function burn(uint256 _value) public returns (bool success) {
        //require(balances[msg.sender] >= _value, "insufficient balance");
        //balances[msg.sender] -= _value;
        balances[msg.sender] = balances[msg.sender].sub(_value);
        //totalSupply -= _value;
        totalSupply = totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }

    /// @notice Remove `_value` tokens from the system irreversibly on behalf of `_from`.
    /// @param _from the address of the sender
    /// @param _value the amount of money to burn
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        //require(balances[_from] >= _value, "insufficient balance");
        //require(allowed[_from][msg.sender] >= _value, "insufficient allowance");
        //balances[_from] -= _value;
        balances[_from] = balances[_from].sub(_value);
        //allowed[_from][msg.sender] -= _value;
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        //totalSupply -= _value;
        totalSupply = totalSupply.sub(_value);
        emit Burn(_from, _value);
        return true;
    }

    /// @notice Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
    /// @param _spender The address authorized to spend
    /// @param _value the max amount they can spend
    /// @param _extraData some extra information to send to the approved contract
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /// @notice Create `mintedAmount` tokens and send it to `target`
    /// @param target Address to receive the tokens
    /// @param mintedAmount the amount of tokens it will receive
    function mintToken(address target, uint256 mintedAmount) public {
        require(msg.sender == owner, "permission denied");
        require(target != 0);
        //balances[target] += mintedAmount;
        balances[target] = balances[target].add(mintedAmount);
        //totalSupply += mintedAmount;
        totalSupply = totalSupply.add(mintedAmount);
        emit Transfer(0, msg.sender, mintedAmount);
        emit Transfer(msg.sender, target, mintedAmount);
    }

    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param target Address to be frozen
    /// @param freeze either to freeze it or not
    function freezeAccount(address target, bool freeze) public {
        require(msg.sender == owner, "permission denied");
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    function distribute(address[] _toAddrs, uint256[] _values, uint8 count) public returns (bool success) {
        require(!frozenAccount[msg.sender], "source account frozen");

        uint i;
        uint256 total = 0;
        for (i = 0; i < count; i++) {
            require(_toAddrs[i] != 0);
            require(!frozenAccount[_toAddrs[i]], "destination account frozen");
            total = total.add(_values[i]);
        }
        require(balances[msg.sender] >= total);
        
        for (i = 0; i < count; i++){
            balances[msg.sender] = balances[msg.sender].sub(_values[i]);
            balances[_toAddrs[i]] = balances[_toAddrs[i]].add(_values[i]);
            emit Transfer(msg.sender, _toAddrs[i], _values[i]);
        }
        
        return true;
    }
}