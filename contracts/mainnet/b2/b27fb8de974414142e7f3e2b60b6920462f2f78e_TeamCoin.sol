pragma solidity ^0.4.11;

contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner 
  {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

contract Contactable is Ownable {

    string public contactInformation;

    /**
     * @dev Allows the owner to set a string with their contact information.
     * @param info The contact information to attach to the contract.
     */
    function setContactInformation(string info) onlyOwner 
    {
         contactInformation = info;
     }
}

contract Destructible is Ownable {

  function Destructible() payable 
  { 

  } 

  /**
   * @dev Transfers the current balance to the owner and terminates the contract. 
   */
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


  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused 
  {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
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
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
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

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
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


contract TeamCoin is Ownable, Destructible, Contactable, MintableToken {
    using SafeMath for uint256;


       // start and end timestamps where investments are allowed (both inclusive)
    uint256 public startBlock;
    uint256 public endBlock;

    // address where funds are collected
    address public wallet;

    // how many token units a buyer gets per wei
    uint256 public rate;

    // amount of raised money in wei
    uint256 public weiRaised;

    //Constant of max suppliable tokens
    uint256 constant MAXSUPPLY = 2000000000000000000000000;


  string public name = "TeamCoin";
  string public symbol = "TMC";
  uint public decimals = 18;
  uint public OWNER_SUPPLY = 1200000000000000000000000;
  address public owner;
  bool public locked;

    modifier onlyUnlocked() {

      if (owner != msg.sender) {
        require(false == locked);
      }
      _;
    }

  function TeamCoin() {
      startBlock = block.number + 800;
      endBlock = startBlock + 50000;
        
      require(endBlock >= startBlock);
        
      rate = 25;
      wallet = msg.sender;
      locked = true;
      owner = msg.sender;
      totalSupply = MAXSUPPLY;
      balances[owner] = MAXSUPPLY;
      contactInformation = "http://www.teamco.in";
  }

  function unlock() onlyOwner 
    {
      require(locked);   // to allow only 1 call
      locked = false;
  }
  
  
  function transferFrom(address _from, address _to, uint256 _value) onlyUnlocked returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

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

    // low level token purchase function
    function buyTokens(address beneficiary) payable
     {
        require(beneficiary != 0x0);
        require(validPurchase());
        uint256 weiAmount = msg.value;
        // calculate token amount to be created
        uint256 tokens = weiAmount.mul(rate);
        // update state
        weiRaised = weiRaised.add(weiAmount);
        balances[owner] = balances[owner].sub(tokens);
        balances[beneficiary] = balances[beneficiary].add(tokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        forwardFunds(); // funds are forward finally 
        
    }

    // send ether to the fund collection wallet
    // override to create custom fund forwarding mechanisms
    function forwardFunds() internal 
    {
        wallet.transfer(msg.value);
    }

    function validPurchase() internal constant returns (bool) {
        uint256 current = block.number;
        bool withinPeriod = current >= startBlock && current <= endBlock;
        bool nonZeroPurchase = msg.value != 0;
        bool nonMaxPurchase = msg.value <= 1000 ether;
        bool maxSupplyNotReached = balances[owner] > OWNER_SUPPLY; // check if the balance of the owner hasnt reached the initial supply
        return withinPeriod && nonZeroPurchase && nonMaxPurchase && maxSupplyNotReached;
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