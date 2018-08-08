pragma solidity ^0.4.13;

contract ERC20Interface {
    uint256 public totalSupply;
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
 
contract Multibot is ERC20Interface {
    address public owner;

    string public constant symbol = "MBT";
    string public constant name = "Multibot";
    uint8 public constant decimals = 8;
    uint256 initialSupply = 2500000000000000;
    
    uint256 public shareholdersBalance;
    uint256 public totalShareholders;
    mapping (address => bool) registeredShareholders;
    mapping (uint => address) public shareholders;
    
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) public allowed;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function isToken() public constant returns (bool weAre) {
        return true;
    }
    
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }
 
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Burn(address indexed from, uint256 value);
    
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function Multibot() {
        owner = msg.sender;
        balances[owner] = initialSupply;
        totalSupply=initialSupply;
        totalShareholders = 0;
		shareholdersBalance = 0;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }
    
    /// @notice Send `_value` tokens to `_to` from your account
    /// @param _to The address of the recipient
    /// @param _value the amount to send
    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) returns (bool success) {
        if(_to != 0x0 && _value > 0 && balances[msg.sender] >= _value && balances[_to] + _value > balances[_to])
        {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            
            if (msg.sender == owner && _to != owner) {
                shareholdersBalance += _value;
            }
            if (msg.sender != owner && _to == owner) {
                shareholdersBalance -= _value;
            }
            if (owner != _to) {
                insertShareholder(_to);
            }
            
            Transfer(msg.sender, _to, _value);
            return true;
        }
        else 
        {
            return false;
        }
    }

    /// @notice Send `_value` tokens to `_to` in behalf of `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value the amount to send
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0 && balances[_to] + _value > balances[_to]) {
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            balances[_to] += _value;
            
            if (_from == owner && _to != owner) {
                shareholdersBalance += _value;
            }
            if (_from != owner && _to == owner) {
                shareholdersBalance -= _value;
            }
            if (owner != _to) {
                insertShareholder(_to); 
            }
            
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    /// @notice Allows `_spender` to spend no more than `_value` tokens in your behalf
    /// @param _spender The address authorized to spend
    /// @param _value the max amount they can spend
    function approve(address _spender, uint256 _value) returns (bool success) {
        if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) 
        {
            return false;
        }
        
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /// @notice Remove `_value` tokens from the system irreversibly
    /// @param _value the amount of money to burn
    function burn(uint256 _value) onlyOwner returns (bool success) {
        require (balances[msg.sender] > _value);            // Check if the sender has enough
        balances[msg.sender] -= _value;                      // Subtract from the sender
        totalSupply -= _value;                                // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }
    
    function insertShareholder(address _shareholder) internal returns (bool) {
        if (registeredShareholders[_shareholder] == true) {
            return false;
        } else {
            totalShareholders += 1;
            shareholders[totalShareholders] = _shareholder;
            registeredShareholders[_shareholder] = true;
            return true;
        }
        return false;
    }
    
    function shareholdersBalance() public returns (uint256) {
        return shareholdersBalance;
    }
    
    function totalShareholders() public returns (uint256) {
        return totalShareholders;
    }
    
    function getShareholder(uint256 _index) public returns (address) {
        return shareholders[_index];
    }
}