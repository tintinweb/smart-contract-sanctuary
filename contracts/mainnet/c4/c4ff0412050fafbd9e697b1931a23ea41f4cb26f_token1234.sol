pragma solidity ^0.4.25;

contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract token1234 is owned{

using SafeMath for uint256;

string public constant symbol = "T1234";
string public constant name = "token1234";
uint8 public constant decimals = 18;
uint256 _initialSupply = 1000000 * 10 ** uint256(decimals);
uint256 _totalSupply;

// Owner of this contract
address public owner;

// Balances for each account
mapping(address => uint256) balances;

// Owner of account approves the transfer of an amount to another account
mapping(address => mapping (address => uint256)) allowed;




// Constructor
constructor() token1234() public {
   owner = msg.sender;
   _totalSupply = _initialSupply;
   balances[owner] = _totalSupply;
}

// ERC20
function mintToken(address target, uint256 mintedAmount) onlyOwner public {
    uint256 _mintedAmount = mintedAmount * 10 ** 18;
    balances[target] += _mintedAmount;
    _totalSupply += _mintedAmount;
    emit Transfer(0x0, owner, _mintedAmount);
    emit Transfer(owner, target, _mintedAmount);
}

function burn(uint256 value) public returns (bool success) {
    uint256 _value = value * 10 ** 18;
    require(balances[msg.sender] >= _value);   // Check if the sender has enough
    balances[msg.sender] -= _value;            // Subtract from the sender
    _totalSupply -= _value;                      // Updates totalSupply
    emit Burn(msg.sender, _value);
    return true;
}

function totalSupply() public view returns (uint256) {
   return _totalSupply;
}

function balanceOf(address _owner) public view returns (uint256 balance) {
   return balances[_owner];
}
/*function _transfer(address _from, address _to, uint _value) internal {
    require (_to != address(0x0));                          // Prevent transfer to 0x0 address. Use burn() instead
    require (balances[_from] >= _value);                   // Check if the sender has enough
    require (balances[_to] + _value >= balances[_to]);    // Check for overflows
    balances[_from] -= _value;                             // Subtract from the sender
    balances[_to] += _value;                               // Add the same to the recipient
    emit Transfer(_from, _to, _value);
    }*/

function transfer(address _to, uint256 _amount) public returns (bool success) {
   if (balances[msg.sender] >= _amount && _amount > 0) {
       balances[msg.sender] = balances[msg.sender].sub(_amount);
       balances[_to] = balances[_to].add(_amount);
       emit Transfer(msg.sender, _to, _amount);
       return true;
   } else {
       return false;
   }
}

function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
   if (balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount && _amount > 0) {
       balances[_from] = balances[_from].sub(_amount);
       allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
       balances[_to] = balances[_to].add(_amount);
       emit Transfer(_from, _to, _amount);
       return true;
   } else {
       return false;
   }
}

function approve(address _spender, uint256 _amount) public returns (bool success) {
   if(balances[msg.sender]>=_amount && _amount>0) {
       allowed[msg.sender][_spender] = _amount;
       emit Approval(msg.sender, _spender, _amount);
       return true;
   } else {
       return false;
   }
}

function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
   return allowed[_owner][_spender];
}

event Transfer(address indexed _from, address indexed _to, uint _value);
event Approval(address indexed _owner, address indexed _spender, uint _value);
event Burn(address indexed from, uint256 value);


// custom
function getMyBalance() public view returns (uint) {
   return balances[msg.sender];
}
}

library SafeMath {
function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
    }

function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
    }

function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
    }

function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
    }
}