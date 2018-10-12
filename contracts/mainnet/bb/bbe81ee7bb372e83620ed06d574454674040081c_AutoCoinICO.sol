pragma solidity 0.4.17;
/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address internal owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}
/*
 * @title AutoCoinICO
 * @dev AutoCoinCrowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them ATC tokens based
 * on a ATC token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
  mapping(address => uint256) balances;
  mapping(address => bool) blockListed;
  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    
    require(
        balances[msg.sender] >= _value
        && _value > 0
        && !blockListed[_to]
        && !blockListed[msg.sender]
    );
    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }
  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }
}
/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {
  mapping (address => mapping (address => uint256)) allowed;
  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(
            balances[msg.sender] >= _value
            && balances[_from] >= _value
            && _value > 0
            && !blockListed[_to]
            && !blockListed[msg.sender]
    );
    uint256 _allowance = allowed[_from][msg.sender];
    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }
  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }
  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
}
/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
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
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(msg.sender, _to, _amount);
    return true;
  }
  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
    function addBlockeddUser(address user) public onlyOwner {
        blockListed[user] = true;
    }
    function removeBlockeddUser(address user) public onlyOwner  {
        blockListed[user] = false;
    }
}
/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();
  bool public paused = false;
  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }
  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }
  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }
  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}
/*
 * @title AutoCoin Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract Crowdsale is Ownable, Pausable {
  using SafeMath for uint256;
  /*
   *  @MintableToken token - Token Object
   *  @address wallet - Wallet Address
   *  @uint8 rate - Tokens per Ether
   *  @uint256 weiRaised - Total funds raised in Ethers
  */
  MintableToken internal token;
  address internal wallet;
  uint256 public rate;
  uint256 internal weiRaised;
  /*
   *  @uint256 privateSaleStartTime - Private-Sale Start Time
   *  @uint256 privateSaleEndTime - Private-Sale End Time
   *  @uint256 preSaleStartTime - Pre-Sale Start Time
   *  @uint256 preSaleEndTime - Pre-Sale End Time
   *  @uint256 preICOStartTime - Pre-ICO Start Time
   *  @uint256 preICOEndTime - Pre-ICO End Time
   *  @uint256 ICOstartTime - ICO Start Time
   *  @uint256 ICOEndTime - ICO End Time
  */
  
  uint256 public privateSaleStartTime;
  uint256 public privateSaleEndTime;
  uint256 public preSaleStartTime;
  uint256 public preSaleEndTime;
  uint256 public preICOStartTime;
  uint256 public preICOEndTime;
  uint256 public ICOstartTime;
  uint256 public ICOEndTime;
  
  /*
   *  @uint privateBonus - Private Bonus
   *  @uint preSaleBonus - Pre-Sale Bonus
   *  @uint preICOBonus - Pre-Sale Bonus
   *  @uint firstWeekBonus - ICO 1st Week Bonus
   *  @uint secondWeekBonus - ICO 2nd Week Bonus
   *  @uint thirdWeekBonus - ICO 3rd Week Bonus
   *  @uint forthWeekBonus - ICO 4th Week Bonus
   *  @uint fifthWeekBonus - ICO 5th Week Bonus
  */
  uint256 internal privateSaleBonus;
  uint256 internal preSaleBonus;
  uint256 internal preICOBonus;
  uint256 internal firstWeekBonus;
  uint256 internal secondWeekBonus;
  uint256 internal thirdWeekBonus;
  uint256 internal forthWeekBonus;
  uint256 internal fifthWeekBonus;
  uint256 internal weekOne;
  uint256 internal weekTwo;
  uint256 internal weekThree;
  uint256 internal weekFour;
  uint256 internal weekFive;
  uint256 internal privateSaleTarget;
  uint256 public preSaleTarget;
  uint256 internal preICOTarget;
  /*
   *  @uint256 totalSupply - Total supply of tokens 
   *  @uint256 publicSupply - Total public Supply 
   *  @uint256 bountySupply - Total Bounty Supply
   *  @uint256 reservedSupply - Total Reserved Supply 
   *  @uint256 privateSaleSupply - Total Private Supply from Public Supply  
   *  @uint256 preSaleSupply - Total PreSale Supply from Public Supply 
   *  @uint256 preICOSupply - Total PreICO Supply from Public Supply
   *  @uint256 icoSupply - Total ICO Supply from Public Supply
  */
  uint256 public totalSupply = SafeMath.mul(400000000, 1 ether);
  uint256 internal publicSupply = SafeMath.mul(SafeMath.div(totalSupply,100),55);
  uint256 internal bountySupply = SafeMath.mul(SafeMath.div(totalSupply,100),6);
  uint256 internal reservedSupply = SafeMath.mul(SafeMath.div(totalSupply,100),39);
  uint256 internal privateSaleSupply = SafeMath.mul(24750000, 1 ether);
  uint256 public preSaleSupply = SafeMath.mul(39187500, 1 ether);
  uint256 internal preICOSupply = SafeMath.mul(39187500, 1 ether);
  uint256 internal icoSupply = SafeMath.mul(116875000, 1 ether);
  /*
   *  @bool checkUnsoldTokens - Tokens will be added to bounty supply
   *  @bool upgradePreSaleSupply - Boolean variable updates when the PrivateSale tokens added to PreSale supply
   *  @bool upgradePreICOSupply - Boolean variable updates when the PreSale tokens added to PreICO supply
   *  @bool upgradeICOSupply - Boolean variable updates when the PreICO tokens added to ICO supply
   *  @bool grantFounderTeamSupply - Boolean variable updates when Team and Founder tokens minted
  */
  bool public checkUnsoldTokens;
  bool internal upgradePreSaleSupply;
  bool internal upgradePreICOSupply;
  bool internal upgradeICOSupply;
  /*
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value Wei&#39;s paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  /*
   * function Crowdsale - Parameterized Constructor
   * @param _startTime - StartTime of Crowdsale
   * @param _endTime - EndTime of Crowdsale
   * @param _rate - Tokens against Ether
   * @param _wallet - MultiSignature Wallet Address
   */
  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) internal {
    
    require(_wallet != 0x0);
    token = createTokenContract();
    //privateSaleStartTime = _startTime;
    //privateSaleEndTime = 1537952399;
    preSaleStartTime = _startTime;
    preSaleEndTime = 1541581199;
    preICOStartTime = 1541581200;
    preICOEndTime = 1544000399; 
    ICOstartTime = 1544000400;
    ICOEndTime = _endTime;
    rate = _rate;
    wallet = _wallet;
    //privateSaleBonus = SafeMath.div(SafeMath.mul(rate,50),100);
    preSaleBonus = SafeMath.div(SafeMath.mul(rate,30),100);
    preICOBonus = SafeMath.div(SafeMath.mul(rate,30),100);
    firstWeekBonus = SafeMath.div(SafeMath.mul(rate,20),100);
    secondWeekBonus = SafeMath.div(SafeMath.mul(rate,15),100);
    thirdWeekBonus = SafeMath.div(SafeMath.mul(rate,10),100);
    forthWeekBonus = SafeMath.div(SafeMath.mul(rate,5),100);
    
    weekOne = SafeMath.add(ICOstartTime, 14 days);
    weekTwo = SafeMath.add(weekOne, 14 days);
    weekThree = SafeMath.add(weekTwo, 14 days);
    weekFour = SafeMath.add(weekThree, 14 days);
    weekFive = SafeMath.add(weekFour, 14 days);
    privateSaleTarget = SafeMath.mul(4500, 1 ether);
    preSaleTarget = SafeMath.mul(7125, 1 ether);
    preICOTarget = SafeMath.mul(7125, 1 ether);
    checkUnsoldTokens = false;
    upgradeICOSupply = false;
    upgradePreICOSupply = false;
    upgradePreSaleSupply = false;
  
  }
  /*
   * function createTokenContract - Mintable Token Created
   */
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }
  
  /*
   * function Fallback - Receives Ethers
   */
  function () payable {
    buyTokens(msg.sender);
  }
    /*
   * function preSaleTokens - Calculate Tokens in PreSale
   */
  // function privateSaleTokens(uint256 weiAmount, uint256 tokens) internal returns (uint256) {
        
  //   require(privateSaleSupply > 0);
  //   require(weiAmount <= privateSaleTarget);
  //   tokens = SafeMath.add(tokens, weiAmount.mul(privateSaleBonus));
  //   tokens = SafeMath.add(tokens, weiAmount.mul(rate));
  //   require(privateSaleSupply >= tokens);
  //   privateSaleSupply = privateSaleSupply.sub(tokens);        
  //   privateSaleTarget = privateSaleTarget.sub(weiAmount);
  //   return tokens;
  // }
  /*
   * function preSaleTokens - Calculate Tokens in PreSale
   */
  function preSaleTokens(uint256 weiAmount, uint256 tokens) internal returns (uint256) {
        
    require(preSaleSupply > 0);
    require(weiAmount <= preSaleTarget);
    if (!upgradePreSaleSupply) {
      preSaleSupply = SafeMath.add(preSaleSupply, privateSaleSupply);
      preSaleTarget = SafeMath.add(preSaleTarget, privateSaleTarget);
      upgradePreSaleSupply = true;
    }
    tokens = SafeMath.add(tokens, weiAmount.mul(preSaleBonus));
    tokens = SafeMath.add(tokens, weiAmount.mul(rate));
    require(preSaleSupply >= tokens);
    preSaleSupply = preSaleSupply.sub(tokens);        
    preSaleTarget = preSaleTarget.sub(weiAmount);
    return tokens;
  }
  /*
    * function preICOTokens - Calculate Tokens in PreICO
    */
  function preICOTokens(uint256 weiAmount, uint256 tokens) internal returns (uint256) {
        
    require(preICOSupply > 0);
    require(weiAmount <= preICOTarget);
    if (!upgradePreICOSupply) {
      preICOSupply = SafeMath.add(preICOSupply, preSaleSupply);
      preICOTarget = SafeMath.add(preICOTarget, preSaleTarget);
      upgradePreICOSupply = true;
    }
    tokens = SafeMath.add(tokens, weiAmount.mul(preICOBonus));
    tokens = SafeMath.add(tokens, weiAmount.mul(rate));
    
    require(preICOSupply >= tokens);
    
    preICOSupply = preICOSupply.sub(tokens);        
    preICOTarget = preICOTarget.sub(weiAmount);
    return tokens;
  }
  /*
   * function icoTokens - Calculate Tokens in ICO
   */
  
  function icoTokens(uint256 weiAmount, uint256 tokens, uint256 accessTime) internal returns (uint256) {
        
    require(icoSupply > 0);
    if (!upgradeICOSupply) {
      icoSupply = SafeMath.add(icoSupply,preICOSupply);
      upgradeICOSupply = true;
    }
    
    if (accessTime <= weekOne) {
      tokens = SafeMath.add(tokens, weiAmount.mul(firstWeekBonus));
    } else if (accessTime <= weekTwo) {
      tokens = SafeMath.add(tokens, weiAmount.mul(secondWeekBonus));
    } else if ( accessTime < weekThree ) {
      tokens = SafeMath.add(tokens, weiAmount.mul(thirdWeekBonus));
    } else if ( accessTime < weekFour ) {
      tokens = SafeMath.add(tokens, weiAmount.mul(forthWeekBonus));
    } else if ( accessTime < weekFive ) {
      tokens = SafeMath.add(tokens, weiAmount.mul(fifthWeekBonus));
    }
    
    tokens = SafeMath.add(tokens, weiAmount.mul(rate));
    icoSupply = icoSupply.sub(tokens);        
    return tokens;
  }
  /*
  * function buyTokens - Collect Ethers and transfer tokens
  */
  function buyTokens(address beneficiary) whenNotPaused internal {
    require(beneficiary != 0x0);
    require(validPurchase());
    uint256 accessTime = now;
    uint256 tokens = 0;
    uint256 weiAmount = msg.value;
    require((weiAmount >= (100000000000000000)) && (weiAmount <= (20000000000000000000)));
    if ((accessTime >= preSaleStartTime) && (accessTime < preSaleEndTime)) {
      tokens = preSaleTokens(weiAmount, tokens);
    } else if ((accessTime >= preICOStartTime) && (accessTime < preICOEndTime)) {
      tokens = preICOTokens(weiAmount, tokens);
    } else if ((accessTime >= ICOstartTime) && (accessTime <= ICOEndTime)) { 
      tokens = icoTokens(weiAmount, tokens, accessTime);
    } else {
      revert();
    }
    
    publicSupply = publicSupply.sub(tokens);
    weiRaised = weiRaised.add(weiAmount);
    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    forwardFunds();
  }
  /*
   * function forwardFunds - Transfer funds to wallet
   */
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }
  /*
   * function validPurchase - Checks the purchase is valid or not
   * @return true - Purchase is withPeriod and nonZero
   */
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= privateSaleStartTime && now <= ICOEndTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }
  /*
   * function hasEnded - Checks the ICO ends or not
   * @return true - ICO Ends
   */
  
  function hasEnded() public constant returns (bool) {
    return now > ICOEndTime;
  }
  /*
   * function unsoldToken - Function used to transfer all 
   *               unsold public tokens to reserve supply
   */
  function unsoldToken() onlyOwner public {
    require(hasEnded());
    require(!checkUnsoldTokens);
    
    checkUnsoldTokens = true;
    bountySupply = SafeMath.add(bountySupply, publicSupply);
    publicSupply = 0;
  }
  /* 
   * function getTokenAddress - Get Token Address 
   */
  function getTokenAddress() onlyOwner public returns (address) {
    return token;
  }
}
/*
 * @title AutoCoinToken 
 */
 
contract AutoCoinToken is MintableToken {
  /*
   *  @string name - Token Name
   *  @string symbol - Token Symbol
   *  @uint8 decimals - Token Decimals
   *  @uint256 _totalSupply - Token Total Supply
  */
    string public constant name = "AUTO COIN";
    string public constant symbol = "AUTO COIN";
    uint8 public constant decimals = 18;
    uint256 public constant _totalSupply = 400000000000000000000000000;
  
/* Constructor AutoCoinToken */
    function AutoCoinToken() public {
        totalSupply = _totalSupply;
    }
}
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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
contract CrowdsaleFunctions is Crowdsale {
 /* 
  * function bountyFunds - Transfer bounty tokens via AirDrop
  * @param beneficiary address where owner wants to transfer tokens
  * @param tokens value of token
  */
    function bountyFunds(address[] beneficiary, uint256[] tokens) public onlyOwner {
        for (uint256 i = 0; i < beneficiary.length; i++) {
            tokens[i] = SafeMath.mul(tokens[i],1 ether); 
            require(beneficiary[i] != 0x0);
            require(bountySupply >= tokens[i]);
            
            bountySupply = SafeMath.sub(bountySupply,tokens[i]);
            token.mint(beneficiary[i], tokens[i]);
        }
    }
  /* 
   * function grantReservedToken - Transfer advisor,team and founder tokens  
   */
    function grantReservedToken(address beneficiary, uint256 tokens) public onlyOwner {
        require(beneficiary != 0x0);
        require(reservedSupply > 0);
        tokens = SafeMath.mul(tokens,1 ether);
        require(reservedSupply >= tokens);
        reservedSupply = SafeMath.sub(reservedSupply,tokens);
        token.mint(beneficiary, tokens);
      
    }
/* 
 *.function transferToken - Used to transfer tokens to investors who pays us other than Ethers
 * @param beneficiary - Address where owner wants to transfer tokens
 * @param tokens -  Number of tokens
 */
    function singleTransferToken(address beneficiary, uint256 tokens) onlyOwner public {
        
        require(beneficiary != 0x0);
        require(publicSupply > 0);
        tokens = SafeMath.mul(tokens,1 ether);
        require(publicSupply >= tokens);
        publicSupply = SafeMath.sub(publicSupply,tokens);
        token.mint(beneficiary, tokens);
    }
  /* 
   * function multiTransferToken - Transfer tokens on multiple addresses 
   */
    function multiTransferToken(address[] beneficiary, uint256[] tokens) public onlyOwner {
        for (uint256 i = 0; i < beneficiary.length; i++) {
            tokens[i] = SafeMath.mul(tokens[i],1 ether); 
            require(beneficiary[i] != 0x0);
            require(publicSupply >= tokens[i]);
            
            publicSupply = SafeMath.sub(publicSupply,tokens[i]);
            token.mint(beneficiary[i], tokens[i]);
        }
    }
    function addBlockListed(address user) public onlyOwner {
        token.addBlockeddUser(user);
    }
    
    function removeBlockListed(address user) public onlyOwner {
        token.removeBlockeddUser(user);
    }
}
contract AutoCoinICO is Crowdsale, CrowdsaleFunctions {
  
    /* Constructor AutoCoinICO */
    function AutoCoinICO(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet)   
    Crowdsale(_startTime,_endTime,_rate,_wallet) 
    {
    }
    
    /* AutoCoinToken Contract */
    function createTokenContract() internal returns (MintableToken) {
        return new AutoCoinToken();
    }
}