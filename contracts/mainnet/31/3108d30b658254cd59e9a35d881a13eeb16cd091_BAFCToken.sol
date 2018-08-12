pragma solidity ^0.4.24;
 
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);  
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    uint c = a / b;
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

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}


contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
  
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}


contract BasicToken is ERC20Basic {
  using SafeMath for uint;
    
  address public owner;
  
  /// This is a switch to control the liquidity
  bool public transferable = true;
  
  mapping(address => uint) balances;

  //The frozen accounts 
  mapping (address => bool) public frozenAccount;

  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }
  
  modifier unFrozenAccount{
      require(!frozenAccount[msg.sender]);
      _;
  }
  
  modifier onlyOwner {
      if (owner == msg.sender) {
          _;
      } else {
          InvalidCaller(msg.sender);
          throw;
        }
  }
  
  modifier onlyTransferable {
      if (transferable) {
          _;
      } else {
          LiquidityAlarm("The liquidity is switched off");
          throw;
      }
  }
  
  /// Emitted when the target account is frozen
  event FrozenFunds(address target, bool frozen);
  
  /// Emitted when a function is invocated by unauthorized addresses.
  event InvalidCaller(address caller);

  /// Emitted when some TOKEN coins are burn.
  event Burn(address caller, uint value);
  
  /// Emitted when the ownership is transferred.
  event OwnershipTransferred(address indexed from, address indexed to);
  
  /// Emitted if the account is invalid for transaction.
  event InvalidAccount(address indexed addr, bytes msg);
  
  /// Emitted when the liquity of TOKEN is switched off
  event LiquidityAlarm(bytes msg);
  
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) unFrozenAccount onlyTransferable {
    if (frozenAccount[_to]) {
        InvalidAccount(_to, "The receiver account is frozen");
    } else {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
    } 
  }

  function balanceOf(address _owner) view returns (uint balance) {
    return balances[_owner];
  }

  ///@notice `freeze? Prevent | Allow` `target` from sending & receiving TOKEN preconditions
  ///@param target Address to be frozen
  ///@param freeze To freeze the target account or not
  function freezeAccount(address target, bool freeze) onlyOwner public {
      frozenAccount[target]=freeze;
      FrozenFunds(target, freeze);
    }
  
  function accountFrozenStatus(address target) view returns (bool frozen) {
      return frozenAccount[target];
  }
  
  function transferOwnership(address newOwner) onlyOwner public {
      if (newOwner != address(0)) {
          address oldOwner=owner;
          owner = newOwner;
          OwnershipTransferred(oldOwner, owner);
        }
  }
  
  function switchLiquidity (bool _transferable) onlyOwner returns (bool success) {
      transferable=_transferable;
      return true;
  }
  
  function liquidityStatus () view returns (bool _transferable) {
      return transferable;
  }
}


contract StandardToken is BasicToken {

  mapping (address => mapping (address => uint)) allowed;

  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) unFrozenAccount onlyTransferable{
    var _allowance = allowed[_from][msg.sender];

    // Check account _from and _to is not frozen
    require(!frozenAccount[_from]&&!frozenAccount[_to]);
    
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

  function approve(address _spender, uint _value) unFrozenAccount {
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

  function allowance(address _owner, address _spender) view returns (uint remaining) {
    return allowed[_owner][_spender];
  }
  
}


contract BAFCToken is StandardToken {
    string public name = "Business Alliance Financial Circle";
    string public symbol = "BAFC";
    uint public decimals = 18;
    /**
     * CONSTRUCTOR, This address will be : 0x...
     */
    function BAFCToken() {
        owner = msg.sender;
        totalSupply = 1.9 * 10 ** 26;
        balances[owner] = totalSupply;
    }

    function () public payable {
        revert();
    }
}