pragma solidity ^0.4.11;

/*
--------------------------------------------------------------------------------

ERC20: https://github.com/ethereum/EIPs/issues/20
ERC223: https://github.com/ethereum/EIPs/issues/223

MIT Licence
--------------------------------------------------------------------------------
*/

/*
* Contract that is working with ERC223 tokens
*/

contract ContractReceiver {
  function tokenFallback(address _from, uint _value, bytes _data) {
    /* Fix for Mist warning */
    _from;
    _value;
    _data;
  }
}


contract FLTToken {
    /* Contract Constants */
    string public constant _name = "FLTcoin";
    string public constant _symbol = "FLT";
    uint8 public constant _decimals = 8;

    /* The supply is initially 100,000,000MGO to the precision of 8 decimals */
    uint256 public constant _initialSupply = 49800000000000000;

    /* Contract Variables */
    address public owner;
    uint256 public _currentSupply;
    mapping(address => uint256) public balances;
    mapping(address => mapping (address => uint256)) public allowed;

    /* Constructor initializes the owner&#39;s balance and the supply  */
    function FLTToken() {
        owner = msg.sender;
        _currentSupply = _initialSupply;
        balances[owner] = _initialSupply;
    }

    /* ERC20 Events */
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, address indexed to, uint256 value);

    /* ERC223 Events */
    event Transfer(address indexed from, address indexed to, uint value, bytes data);

    /* Non-ERC Events */
    event Burn(address indexed from, uint256 amount, uint256 currentSupply, bytes data);

    /* ERC20 Functions */
    /* Return current supply in smallest denomination (1MGO = 100000000) */
    function totalSupply() constant returns (uint256 totalSupply) {
        return _initialSupply;
    }

    /* Returns the balance of a particular account */
    function balanceOf(address _address) constant returns (uint256 balance) {
        return balances[_address];
    }

    /* Transfer the balance from the sender&#39;s address to the address _to */
    function transfer(address _to, uint _value) returns (bool success) {
        if (balances[msg.sender] >= _value
            && _value > 0
            && balances[_to] + _value > balances[_to]) {
            bytes memory empty;
            if(isContract(_to)) {
                return transferToContract(_to, _value, empty);
            } else {
                return transferToAddress(_to, _value, empty);
            }
        } else {
            return false;
        }
    }

    /* Withdraws to address _to form the address _from up to the amount _value */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value
            && allowed[_from][msg.sender] >= _value
            && _value > 0
            && balances[_to] + _value > balances[_to]) {
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    /* Allows _spender to withdraw the _allowance amount form sender */
    function approve(address _spender, uint256 _allowance) returns (bool success) {
        if (_allowance <= _currentSupply) {
            allowed[msg.sender][_spender] = _allowance;
            Approval(msg.sender, _spender, _allowance);
            return true;
        } else {
            return false;
        }
    }

    /* Checks how much _spender can withdraw from _owner */
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /* ERC223 Functions */
    /* Get the contract constant _name */
    function name() constant returns (string name) {
        return _name;
    }

    /* Get the contract constant _symbol */
    function symbol() constant returns (string symbol) {
        return _symbol;
    }

    /* Get the contract constant _decimals */
    function decimals() constant returns (uint8 decimals) {
        return _decimals;
    }

    /* Transfer the balance from the sender&#39;s address to the address _to with data _data */
    function transfer(address _to, uint _value, bytes _data) returns (bool success) {
        if (balances[msg.sender] >= _value
            && _value > 0
            && balances[_to] + _value > balances[_to]) {
            if(isContract(_to)) {
                return transferToContract(_to, _value, _data);
            } else {
                return transferToAddress(_to, _value, _data);
            }
        } else {
            return false;
        }
    }

    /* Transfer function when _to represents a regular address */
    function transferToAddress(address _to, uint _value, bytes _data) internal returns (bool success) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        Transfer(msg.sender, _to, _value, _data);
        return true;
    }

    /* Transfer function when _to represents a contract address, with the caveat
    that the contract needs to implement the tokenFallback function in order to receive tokens */
    function transferToContract(address _to, uint _value, bytes _data) internal returns (bool success) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        Transfer(msg.sender, _to, _value);
        Transfer(msg.sender, _to, _value, _data);
        return true;
    }

    /* Infers if whether _address is a contract based on the presence of bytecode */
    function isContract(address _address) internal returns (bool is_contract) {
        uint length;
        if (_address == 0) return false;
        assembly {
            length := extcodesize(_address)
        }
        if(length > 0) {
            return true;
        } else {
            return false;
        }
    }

    /* Non-ERC Functions */
    /* Remove the specified amount of the tokens from the supply permanently */
    function burn(uint256 _value, bytes _data) returns (bool success) {
        if (balances[msg.sender] >= _value
            && _value > 0) {
            balances[msg.sender] -= _value;
            _currentSupply -= _value;
            Burn(msg.sender, _value, _currentSupply, _data);
            return true;
        } else {
            return false;
        }
    }

    /* Returns the total amount of tokens in supply */
    function currentSupply() constant returns (uint256 currentSupply) {
        return _currentSupply;
    }

    /* Returns the total amount of tokens ever burned */
    function amountBurned() constant returns (uint256 amountBurned) {
        return _initialSupply - _currentSupply;
    }

    /* Stops any attempt to send Ether to this contract */
    function () {
        throw;
    }
}