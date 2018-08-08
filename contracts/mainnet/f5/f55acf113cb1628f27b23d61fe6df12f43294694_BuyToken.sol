pragma solidity ^0.4.14;

/* &#169;RomanLanskoj 2017
I can create the cryptocurrency Ethereum-token for you, with any total or initial supply,  enable the owner to create new tokens or without it,  custom currency rates (can make the token&#39;s value be backed by ether (or other tokens) by creating a fund that automatically sells and buys them at market value) and other features. 
Full support and privacy

Only you will be able to issue it and only you will have all the copyrights!

Price is only 0.33 ETH  (if you will gift me a small % of issued coins I will be happy:)).

skype open24365
+35796229192 Cyprus
viber+telegram +375298563585
viber +375298563585
telegram +375298563585
gmail <span class="__cf_email__" data-cfemail="c5b7aaa8a4aba9a4abb6aeaaaf85a2a8a4aca9eba6aaa8">[email&#160;protected]</span>



the example: https://etherscan.io/address/0x178AbBC1574a55AdA66114Edd68Ab95b690158FC

The information I need:
- name for your coin (token)
- short name
- total supply or initial supply
- minable or not (fixed)
- the number of decimals (0.001 = 3 decimals)
- any comments you wanna include in the code (no limits for readme)

After send  please  at least 0.25-0.33 ETH to 0x4BCc85fa097ad0f5618cb9bb5bc0AFfbAEC359B5 

Adding your coin to EtherDelta exchange, code-verification and github are included  

There is no law stronger then the code
*/

library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }
  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }
  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }
  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }
  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }
  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}

contract Ownable {
    address public owner;
    function Ownable() {
        owner = msg.sender;
    }
    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }
    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
}
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

contract newToken is ERC20Basic {
  
  using SafeMath for uint;
  
  mapping(address => uint) balances;
  

  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }
  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }
}

contract StandardToken is newToken, ERC20 {
  mapping (address => mapping (address => uint)) allowed;
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
    var _allowance = allowed[_from][msg.sender];
    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // if (_value > _allowance) throw;
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }
  function approve(address _spender, uint _value) {
    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling approve(_spender, 0) if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }
  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }
}

contract Order is StandardToken, Ownable {
  string public constant name = "Order";
  string public constant symbol = "ETH";
  uint public constant decimals = 3;
  uint256 public initialSupply;
    
  // Constructor
  function Order () { 
     totalSupply = 120000 * 10 ** decimals;
      balances[msg.sender] = totalSupply;
      initialSupply = totalSupply; 
        Transfer(0, this, totalSupply);
        Transfer(this, msg.sender, totalSupply);
  }
}

contract BuyToken is Ownable, Order {

uint256 public constant sellPrice = 333 szabo;
uint256 public constant buyPrice = 333 finney;

    function buy() payable returns (uint amount)
    {
        amount = msg.value / buyPrice;
        if (balances[this] < amount) throw; 
        balances[msg.sender] += amount;
        balances[this] -= amount;
        Transfer(this, msg.sender, amount);
    }

    function sell(uint256 amount) {
        if (balances[msg.sender] < amount ) throw;
        balances[this] += amount;
        balances[msg.sender] -= amount;
        if (!msg.sender.send(amount * sellPrice)) {
            throw;
        } else {
            Transfer(msg.sender, this, amount);
        }               
    }
    
  function transfer(address _to, uint256 _value) {
        require(balances[msg.sender] > _value);
        require(balances[_to] + _value > balances[_to]);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
    }

   function mintToken(address target, uint256 mintedAmount) onlyOwner {
        balances[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }
   
    function () payable {
        buy();
    }
}