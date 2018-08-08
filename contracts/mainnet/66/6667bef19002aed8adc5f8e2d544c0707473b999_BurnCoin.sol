pragma solidity ^0.4.11;

contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner 
  {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

contract Contactable is Ownable {

    string public contactInformation;

    function setContactInformation(string info) onlyOwner 
    {
      contactInformation = info;
    }
}

contract Destructible is Ownable {

  function Destructible() payable 
  { 

  } 

  function destroy() onlyOwner 
  {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner 
  {
    selfdestruct(_recipient);
  }
}

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused() {
    require(paused);
    _;
  }

  function pause() onlyOwner whenNotPaused 
  {
    paused = true;
    Pause();
  }

  function unpause() onlyOwner whenPaused 
  {
    paused = false;
    Unpause();
  }
}


contract ERC20 {
    uint256 public totalSupply;
    function balanceOf(address who) constant returns (uint256);
    
    function transfer(address to, uint256 value) returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    function allowance(address owner, address spender) constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) returns (bool);
    
    function approve(address spender, uint256 value) returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract StandardToken is ERC20 {
    using SafeMath for uint256;
    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;


 
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }


  function approve(address _spender, uint256 _value) returns (bool) {

    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}


contract BurnCoin is Ownable, Destructible, Contactable, MintableToken {
    
    using SafeMath for uint256;

    uint256 public startBlock;
    uint256 public endBlock;

    address public wallet;

    uint256 public rate;

    uint256 public weiRaised;

    uint256 constant maxavailable = 10000000000000000000000;

    string public name = "BurnCoin";

    string public symbol = "BRN";
    uint public decimals = 18;
    uint public ownerstake = 5001000000000000000000;
    address public owner;
    bool public locked;
    
    modifier onlyUnlocked() {

      if (owner != msg.sender) {
        require(false == locked);
      }
      _;
    }

  function BurnCoin() {
      startBlock = block.number;
      endBlock = startBlock + 10000000;
        
      require(endBlock >= startBlock);
        
      rate = 1;
      wallet = msg.sender;
      locked = true;
      owner = msg.sender;
      totalSupply = maxavailable;
      balances[owner] = maxavailable;
      contactInformation = "BurnCoin (BRN) : Burn Fiat. Make Coin.";
  }

  function unlock() onlyOwner 
    {
      require(locked);
      locked = false;
  }
  
  
  function transferFrom(address _from, address _to, uint256 _value) onlyUnlocked returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }
  
   function transfer(address _to, uint256 _value) onlyUnlocked returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    function () payable 
    {
        buyTokens(msg.sender);
    }

    function buyTokens(address beneficiary) payable
     {
        require(beneficiary != 0x0);
        require(validPurchase());
        uint256 weiAmount = msg.value;
        uint256 tokens = weiAmount.mul(rate);
        weiRaised = weiRaised.add(weiAmount);
        balances[owner] = balances[owner].sub(tokens);
        balances[beneficiary] = balances[beneficiary].add(tokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
        forwardFunds();
        
    }

    function forwardFunds() internal 
    {
        wallet.transfer(msg.value);
    }

    function validPurchase() internal constant returns (bool) {
        uint256 current = block.number;
        bool withinPeriod = current >= startBlock && current <= endBlock;
        bool nonZeroPurchase = msg.value != 0;
        bool nonMaxPurchase = msg.value <= 1000 ether;
        bool maxavailableNotReached = balances[owner] > ownerstake;
        return withinPeriod && nonZeroPurchase && nonMaxPurchase && maxavailableNotReached;
    }

    function hasEnded() public constant returns (bool) {
        return block.number > endBlock;
    }

   function burn(uint _value) onlyOwner 
   {
        require(_value > 0);
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }

    event Burn(address indexed burner, uint indexed value);

}