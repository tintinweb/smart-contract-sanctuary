pragma solidity ^0.4.23;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 ownerBalance) {
    return balances[_owner];
  }

}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

/**
 * @title Mintable token
 */
contract CappedMintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  event MintingAgentChanged(address addr, bool state);

  uint256 public cap;

  bool public mintingFinished = false;
  mapping (address => bool) public mintAgents;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }
  
  modifier onlyMintAgent() {
    // crowdsale contracts or owner are allowed to mint new tokens
    if(!mintAgents[msg.sender] || (msg.sender == owner)) {
        revert();
    }
    _;
  }


  constructor(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }


  /**
   * Owner can allow a crowdsale contract to mint new tokens.
   */
  function setMintAgent(address addr, bool state) onlyOwner canMint public {
    mintAgents[addr] = state;
    emit MintingAgentChanged(addr, state);
  }
  
  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyMintAgent canMint public returns (bool) {
    require(totalSupply_.add(_amount) <= cap);
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}


/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

/**
 * @title Standard Burnable Token
 * @dev Adds burnFrom method to ERC20 implementations
 */
contract StandardBurnableToken is BurnableToken, StandardToken {

  /**
   * @dev Burns a specific amount of tokens from the target address and decrements allowance
   * @param _from address The address which you want to send tokens from
   * @param _value uint256 The amount of token to be burned
   */
  function burnFrom(address _from, uint256 _value) public {
    require(_value <= allowed[_from][msg.sender]);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    _burn(_from, _value);
  }
}


/**
 * @title ODXToken
 * @dev Simple ERC20 Token,   
 * Tokens are mintable and burnable.
 * No initial token upon creation
 * Added max token supply
 */
contract ODXToken is CappedMintableToken, StandardBurnableToken {

  string public constant name = "ODX Test Token"; 
  string public constant symbol = "ODXX"; 
  uint8 public constant decimals = 18; 

  uint256 public constant MAX_TOKEN_SUPPLY = 10000000 * (10 ** uint256(decimals));
  
  /**
   * @dev set totalSupply_ = 0;
   */
  constructor() public CappedMintableToken(MAX_TOKEN_SUPPLY) {
    totalSupply_ = 0;
  }
  
  function () payable public {
      revert();
  }

}


/**
 * @title PrivateSaleRules
 * @dev Specifically use for private sale with lockup.
 */
contract PrivateSaleRules is Ownable {
  using SafeMath for uint256;

  // private sale tracker of contribution
  uint256 public weiRaisedDuringPrivateSale;

  mapping(address => uint256[]) public lockedTokens;
  
  uint256[] public lockupTimes;
  mapping(address => uint256) public privateSale;
  
  mapping (address => bool) public privateSaleAgents;

  // The token being sold
  ERC20 public token;

  event AddLockedTokens(address indexed beneficiary, uint256 totalContributionAmount, uint256[] tokenAmount);
  event UpdateLockedTokens(address indexed beneficiary, uint256 totalContributionAmount, uint lockedTimeIndex, uint256 tokenAmount);
  event PrivateSaleAgentChanged(address addr, bool state);


  modifier onlyPrivateSaleAgent() {
    // crowdsale contracts or owner are allowed to whitelist address
    if(!privateSaleAgents[msg.sender] && (msg.sender != owner)) {
        revert();
    }
    _;
  }
  

  /**
   * @dev Constructor, sets goal, additionalTokenMultiplier and minContribution
   * @param _lockupTimes arraylist of lockup times
   * @param _token tokens to be minted
   */
  constructor(uint256[] _lockupTimes, ODXToken _token) public {
    require(_lockupTimes.length > 0);
    
    lockupTimes = _lockupTimes;
    token = _token;
  }

  /**
   * Owner can add an address to the privatesaleagents.
   */
  function setPrivateSaleAgent(address addr, bool state) onlyOwner public {
    privateSaleAgents[addr] = state;
    emit PrivateSaleAgentChanged(addr, state);
  }
  
  /**
   * @dev Overrides delivery by minting tokens upon purchase.
   * @param _beneficiary Token purchaser
   * @param _tokenAmount Number of tokens to be minted
   */
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    require(ODXToken(token).mint(_beneficiary, _tokenAmount));
    //require(MintableToken(token).mint(wallet, _tokenAmount));
  }
  
  /**
   * @dev claim locked tokens only after lockup time.
   */
   
  function claimLockedTokens() public {
    for (uint i=0; i<lockupTimes.length; i++) {
        uint256 lockupTime = lockupTimes[i];
        if (lockupTime < now){
            uint256 tokens = lockedTokens[msg.sender][i];
            if (tokens>0){
                lockedTokens[msg.sender][i] = 0;
                _deliverTokens(msg.sender, tokens);    
            }
        }
    }
  }


  /**
   * @dev release locked tokens only after lockup time.
   */
  function releaseLockedTokensByIndex(address _beneficiary, uint _lockedTimeIndex) onlyOwner public {
    require(lockupTimes[_lockedTimeIndex] < now);
    uint256 tokens = lockedTokens[_beneficiary][_lockedTimeIndex];
    if (tokens>0){
        lockedTokens[_beneficiary][_lockedTimeIndex] = 0;
        _deliverTokens(_beneficiary, tokens);    
    }
  }
  
  
  function releaseLockedTokens(address _beneficiary) onlyOwner public {
    for (uint i=0; i<lockupTimes.length; i++) {
        uint256 lockupTime = lockupTimes[i];
        if (lockupTime < now){
            uint256 tokens = lockedTokens[_beneficiary][i];
            if (tokens>0){
                lockedTokens[_beneficiary][i] = 0;
                _deliverTokens(_beneficiary, tokens);    
            }
        }
    }
    
  }
  
  function tokensReadyForRelease(uint releaseBatch) public view returns (bool) {
      bool forRelease = false;
      uint256 lockupTime = lockupTimes[releaseBatch];
      if (lockupTime < now){
        forRelease = true;
      }
      return forRelease;
  }

  /**
   * @dev Returns the locked tokens of a specific user.
   * @param _beneficiary Address whose locked tokens is to be checked
   * @return locked tokens for individual user
   */
  function getTotalLockedTokensPerUser(address _beneficiary) public view returns (uint256) {
    uint256 totalTokens = 0;
    uint256[] memory lTokens = lockedTokens[_beneficiary];
    for (uint i=0; i<lockupTimes.length; i++) {
        totalTokens += lTokens[i];
    }
    return totalTokens;
  }
  
  function getLockedTokensPerUser(address _beneficiary) public view returns (uint256[]) {
    return lockedTokens[_beneficiary];
  }

  function addPrivateSaleWithMonthlyLockup(address _beneficiary, uint256[] _atokenAmount, uint256 _totalContributionAmount) onlyPrivateSaleAgent public {
      require(_beneficiary != address(0));
      require(_totalContributionAmount > 0);
      uint tokenLen = _atokenAmount.length;
      require(tokenLen == lockupTimes.length);
      
      uint256 existingContribution = privateSale[_beneficiary];
      if (existingContribution > 0){
        revert();
        //updateLockedTokens(_beneficiary, _atokenAmount, _totalContributionAmount);
      }else{
        lockedTokens[_beneficiary] = _atokenAmount;
        privateSale[_beneficiary] = _totalContributionAmount;
          
        weiRaisedDuringPrivateSale = weiRaisedDuringPrivateSale.add(_totalContributionAmount);
          
        emit AddLockedTokens(
          _beneficiary,
          _totalContributionAmount,
          _atokenAmount
        );
          
      }
      
  }
  
  function getTotalTokensPerArray(uint256[] _tokensArray) internal pure returns (uint256) {
      uint256 totalTokensPerArray = 0;
      for (uint i=0; i<_tokensArray.length; i++) {
        totalTokensPerArray += _tokensArray[i];
      }
      return totalTokensPerArray;
  }


  /**
   * @dev update locked tokens per user 
   * @param _beneficiary Token purchaser
   * @param _lockedTimeIndex lockupTimes index
   * @param _atokenAmount Amount of tokens to be minted
   * @param _totalContributionAmount ETH equivalent of the contribution
   */
  function updatePrivateSaleWithMonthlyLockupByIndex(address _beneficiary, uint _lockedTimeIndex, uint256 _atokenAmount, uint256 _totalContributionAmount) onlyPrivateSaleAgent public {
      require(_beneficiary != address(0));
      require(_totalContributionAmount > 0);
      uint tokenLen = lockupTimes.length;
      //_lockedTimeIndex must be valid within the lockuptimes length
      require(_lockedTimeIndex < tokenLen);
      
      uint256 oldContributions = privateSale[_beneficiary];
      //make sure beneficiary has existing contribution otherwise use addPrivateSaleWithMonthlyLockup
      require(oldContributions > 0);

      //make sure lockuptime of the index is less than now (tokens were not yet released)
      require(!tokensReadyForRelease(_lockedTimeIndex));
      
      lockedTokens[_beneficiary][_lockedTimeIndex] = _atokenAmount;
      
      //subtract old contribution from weiRaisedDuringPrivateSale
      weiRaisedDuringPrivateSale = weiRaisedDuringPrivateSale.sub(oldContributions);
      
      //add new contribution to weiRaisedDuringPrivateSale
      privateSale[_beneficiary] = _totalContributionAmount;
      weiRaisedDuringPrivateSale = weiRaisedDuringPrivateSale.add(_totalContributionAmount);
            
      emit UpdateLockedTokens(
      _beneficiary,
      _totalContributionAmount,
      _lockedTimeIndex,
      _atokenAmount
    );
  }


}


/**
 * @title ODXPrivateSale
 * @dev This is for the private sale of ODX.  
 */
contract ODXPrivateSale is PrivateSaleRules {

  uint256[] alockupTimes = [now + 1 days, now + 2 days, now + 3 days];
  
  constructor(
    ODXToken _token
  )
    public
    PrivateSaleRules(alockupTimes, _token)
  {  }
  
}