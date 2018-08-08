pragma solidity ^0.4.11;

contract ForeignToken {
  function balanceOf(address _owner) constant returns (uint256);
  function transfer(address _to, uint256 _value) returns (bool);
}

/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

contract CardboardUnicorns {
  using SafeMath for uint;
  
  string public name = "HorseWithACheapCardboardHorn";
  string public symbol = "HWACCH";
  uint public decimals = 0;
  uint public totalSupply = 0;
  mapping(address => uint) balances;
  mapping (address => mapping (address => uint)) allowed;
  address public owner = msg.sender;

  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
  event Minted(address indexed owner, uint value);

  /**
   * Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint size) {
    if(msg.data.length < size + 4) {
      throw;
    }
    _;
  }
  
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }
  
  /**
   * Change ownership of the token
   */
  function changeOwner(address _newOwner) onlyOwner {
    owner = _newOwner;
  }

  function withdraw() onlyOwner {
    owner.transfer(this.balance);
  }
  function withdrawForeignTokens(address _tokenContract) onlyOwner {
    ForeignToken token = ForeignToken(_tokenContract);
    uint256 amount = token.balanceOf(address(this));
    token.transfer(owner, amount);
  }

  /**
   * Generate new tokens.
   * Can only be done by the owner of the contract
   */
  function mint(address _who, uint _value) onlyOwner {
    balances[_who] = balances[_who].add(_value);
    totalSupply = totalSupply.add(_value);
    Minted(_who, _value);
  }

  /**
   * Get the token balance of the specified address
   */
  function balanceOf(address _who) constant returns (uint balance) {
    return balances[_who];
  }
  
  /**
   * Transfer token to another address
   */
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
    require(_to != address(this)); // Don&#39;t send tokens back to the contract!
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }
  
  
  /**
   * Transfer tokens from an different address to another address.
   * Need to have been granted an allowance to do this before triggering.
   */
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // if (_value > _allowance) throw;

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }
  
  /**
   * Approve the indicated address to spend the specified amount of tokens on the sender&#39;s behalf
   */
  function approve(address _spender, uint _value) {
    // Ensure allowance is zero if attempting to set to a non-zero number
    // This helps manage an edge-case race condition better: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729 
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;
    
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }
  
  /**
   * Check how many tokens the indicated address can spend on behalf of the owner
   */
  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}