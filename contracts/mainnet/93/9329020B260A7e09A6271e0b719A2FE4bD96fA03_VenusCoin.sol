pragma solidity ^0.4.11;
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
/*
 *  an emergency  mechanism.
 */
contract Pausable is Ownable {
  bool public stopped;
  modifier stopInEmergency {
    if (stopped) {
      throw;
    }
    _;
  }
  
  modifier onlyInEmergency {
    if (!stopped) {
      throw;
    }
    _;
  }
  // called by the owner on emergency, triggers stopped state
  function emergencyStop() external onlyOwner {
    stopped = true;
  }
  // called by the owner on end of emergency, returns to normal state
  function release() external onlyOwner onlyInEmergency {
    stopped = false;
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

contract BasicToken is ERC20Basic {
  
  using SafeMath for uint;
  
  mapping(address => uint) balances;
  
  /*
   * Fix for the ERC20 short address attack  
  */
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
contract StandardToken is BasicToken, ERC20 {
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
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
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
/**
 *  VenusCoin token contract. Implements
 */
contract VenusCoin is StandardToken, Ownable {
  string public constant name = "VenusCoin";
  string public constant symbol = "Venus";
  uint public constant decimals = 0;
  // Constructor
  function VenusCoin() {
      totalSupply = 50000000000;
      balances[msg.sender] = totalSupply; // Send all tokens to owner
  }
  /**
   *  Burn away the specified amount of VenusCoin tokens
   */
  function burn(uint _value) onlyOwner returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    totalSupply = totalSupply.sub(_value);
    Transfer(msg.sender, 0x0, _value);
    return true;
  }
}
/*
  Tokensale Smart Contract for the VenusCoin project
  This smart contract collects ETH
*/
contract Tokensale is Pausable {
    
    using SafeMath for uint;
    struct Beneficiar {
        uint weiReceived; // Amount of Ether
        uint coinSent;
    }
    
    /* Minimum amount to accept */
    uint public constant MIN_ACCEPT_ETHER = 50000000000000 wei; // min sale price is 1/20000 ETH = 5*10**13 wei = 0.00005 ETH
    /* Number of VenusCoins per Ether */
    uint public constant COIN_PER_ETHER = 20000; // 20,000 VenusCoins
    /*
    * Variables
    */
    /* VenusCoin contract reference */
    VenusCoin public coin;
    /* Multisig contract that will receive the Ether */
    address public multisigEther;
    /* Number of Ether received */
    uint public etherReceived;
    /* Number of VenusCoins sent to Ether contributors */
    uint public coinSentToEther;
    /* Tokensale start time */
    uint public startTime;
    /*  Beneficiar&#39;s Ether indexed by Ethereum address */
    mapping(address => Beneficiar) public beneficiars;
  
    /*
     * Event
    */
    event LogReceivedETH(address addr, uint value);
    event LogCoinsEmited(address indexed from, uint amount);
    /*
     * Constructor
    */
    function Tokensale(address _venusCoinAddress, address _to) {
        coin = VenusCoin(_venusCoinAddress);
        multisigEther = _to;
    }
    /* 
     * The fallback function corresponds to a donation in ETH
     */
    function() stopInEmergency payable {
        receiveETH(msg.sender);
    }
    /* 
     * To call to start the Token&#39;s sale
     */
    function start() onlyOwner {
        if (startTime != 0) throw; // Token&#39;s sale was already started
        startTime = now ;              
    }
    
    function receiveETH(address beneficiary) internal {
        if (msg.value < MIN_ACCEPT_ETHER) throw; // Don&#39;t accept funding under a predefined threshold
        
        uint coinToSend = bonus(msg.value.mul(COIN_PER_ETHER).div(1 ether)); // Compute the number of VenusCoin to send 
        Beneficiar beneficiar = beneficiars[beneficiary];
        coin.transfer(beneficiary, coinToSend); // Transfer VenusCoins right now 
        beneficiar.coinSent = beneficiar.coinSent.add(coinToSend);
        beneficiar.weiReceived = beneficiar.weiReceived.add(msg.value); // Update the total wei collected     
        etherReceived = etherReceived.add(msg.value); // Update the total wei collected 
        coinSentToEther = coinSentToEther.add(coinToSend);
        // Send events
        LogCoinsEmited(msg.sender ,coinToSend);
        LogReceivedETH(beneficiary, etherReceived); 
    }
    
    /*
     *Compute the VenusCoin bonus according to the bonus period
     */
    function bonus(uint amount) internal constant returns (uint) {
        if (now < startTime.add(2 days)) return amount.add(amount.div(10));   // bonus 10%
        return amount;
    }
    
    /*  
    * Failsafe drain
    */
    function drain() onlyOwner {
        if (!owner.send(this.balance)) throw;
    }
    /**
     * Allow to change the team multisig address in the case of emergency.
     */
    function setMultisig(address addr) onlyOwner public {
        if (addr == address(0)) throw;
        multisigEther = addr;
    }
    /**
     * Manually back VenusCoin owner address.
     */
    function backVenusCoinOwner() onlyOwner public {
        coin.transferOwnership(owner);
    }
  
    
    
}