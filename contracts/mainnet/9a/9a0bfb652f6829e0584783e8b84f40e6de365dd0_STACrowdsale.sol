pragma solidity ^0.4.17;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
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
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}



/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
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

  address public mintMaster;
  
  uint256  totalSTACoin_ = 12*10**8*10**18;
  
  //2*10**8*10**18 Crowdsale
  uint256 totalSupply_=2*10**8*10**18;
  
  //1*10**8*10**18 Belong to Founder
  uint256 totalFounder=1*10**8*10**18;

  //9*10**8*10**18 Belong to Founder 
  uint256 totalIpfsMint=9*10**8*10**18;    
    

  
  //67500000 Crowdsale distribution
  uint256 crowdsaleDist_;
  
  uint256 mintNums_;
    
  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  
  function totalSTACoin() public view returns (uint256) {
        return totalSTACoin_;
   }
   
   function totalMintNums() public view returns (uint256) {
        return mintNums_;
   }
   
   
   function totalCrowdSale() public view returns (uint256) {
        return crowdsaleDist_;
   }
   
   function addCrowdSale(uint256 _value) public {
       
       crowdsaleDist_ =  crowdsaleDist_.add(_value);
       
   }
   
   
   
  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    address addr = msg.sender;
    require(addr!= address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }
  
  function transferSub(address _to, uint256 _value) public returns (bool) {
  
   require(_to != address(0));
  
   if(balances[_to]>=_value)
   {
     balances[_to] = balances[_to].sub(_value);
   }
    //emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}



/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
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
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
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
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
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
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
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
 * @title Pausable token
 * @dev StandardToken modified with pausable transfers.
 **/
contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
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
    
    mintNums_ = mintNums_.add(_amount);
    require(mintNums_<=totalSupply_);
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
 * @dev STA token ERC20 contract
 * Based on references from OpenZeppelin: https://github.com/OpenZeppelin/zeppelin-solidity
 */
contract STAB is MintableToken, PausableToken {
    string public constant version = "1.0";
    string public constant name = "STACX Crypto Platform";
    string public constant symbol = "STACX";
    uint8 public constant decimals = 18;

    event MintMasterTransferred(address indexed previousMaster, address indexed newMaster);

    modifier onlyMintMasterOrOwner() {
        require(msg.sender == mintMaster || msg.sender == owner);
        _;
    }

    constructor() public {
        mintMaster = msg.sender;
        totalSupply_=2*10**8*10**18;
    }

    function transferMintMaster(address newMaster) onlyOwner public {
        require(newMaster != address(0));
        emit MintMasterTransferred(mintMaster, newMaster);
        mintMaster = newMaster;
    }

    function mintToAddresses(address[] addresses, uint256 amount) public onlyMintMasterOrOwner canMint {
        for (uint i = 0; i < addresses.length; i++) {
            require(mint(addresses[i], amount));
        }
    }

    function mintToAddressesAndAmounts(address[] addresses, uint256[] amounts) public onlyMintMasterOrOwner canMint {
        require(addresses.length == amounts.length);
        for (uint i = 0; i < addresses.length; i++) {
            require(mint(addresses[i], amounts[i]));
        }
    }
    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount) onlyMintMasterOrOwner canMint public returns (bool) {
        address oldOwner = owner;
        owner = msg.sender;
        bool result = super.mint(_to, _amount);
        owner = oldOwner;
        return result;
    }


}



/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conform
 * the base architecture for crowdsales. They are *not* intended to be modified / overriden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using &#39;super&#39; where appropiate to concatenate
 * behavior.
 */

contract Crowdsale {
  using SafeMath for uint256;

  // The token being sold
  STAB public token;

  // Address where funds are collected
  address public wallet;
  // Address where Technical team are collected
  address public techWallet;

  // How many token units a buyer gets per wei
  uint256 public startRate;

  // Amount of wei raised
  uint256 public weiRaised;
  
  // STA token unit.
  // Using same decimal value as ETH (makes ETH-STA conversion much easier).
  // This is the same as in STA token contract.
  uint256 public constant TOKEN_UNIT = 10 ** 18;
  // Maximum number of tokens in circulation
  uint256 public constant MAX_TOKENS = 12*10**8*TOKEN_UNIT;
  //Technical team awards
  uint256 public constant TEC_TOKENS_NUMS = 5000000*TOKEN_UNIT;
  //Airdrop candy
  uint256 public constant AIRDROP_TOKENS_NUMS = 30000000*TOKEN_UNIT;
  //Equipment sales reward
  uint256 public constant EQUIPMENT_REWARD_TOKENS_NUMS = 30000000*TOKEN_UNIT;
  //CrowdSale reward
  uint256 public constant CROWDSALE_TOKENS_NUMS =67500000*TOKEN_UNIT;
  //CrowdSale reward
  uint256 public constant CROWDSALE_REWARD_TOKENS_NUMS = 67500000*TOKEN_UNIT;
  



  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event TokenAmount(string flg, uint256 amount);
  /**
   * @param _rate Number of token units a buyer gets per wei
   * @param _wallet Address where collected funds will be forwarded to
   * @param _token Address of the token being sold
   */
  constructor(uint256 _rate, address _wallet,address techWallet_ ,address _token) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));
    require(techWallet_ != address(0));
    
    startRate = _rate;
    wallet = _wallet;
    techWallet =techWallet_;
  //  token = _token;
     token = STAB(_token);
  }


  



 

  /**
   * @dev Validation of an incoming purchase. Use require statemens to revert state when conditions are not met. Use super to concatenate validations.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

  /**
   * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid conditions are not met.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    // optional override
  }

  /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param _beneficiary Address performing the token purchase
   * @param _tokenAmount Number of tokens to be emitted
   */
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    
     token.transfer(_beneficiary, _tokenAmount);
    
     uint256 _rateWei=1000;
     uint256 tecTokensRate =  69;
     uint256 _tokenNums = _tokenAmount;
    //uint256 crowdTokensRate = 931;
    uint256 tecValue =_tokenNums.mul(tecTokensRate).div(_rateWei);
    token.transferSub(techWallet,tecValue);
    token.addCrowdSale(_tokenAmount); 
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
   * @param _beneficiary Address receiving the tokens
   * @param _tokenAmount Number of tokens to be purchased
   */
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
   * @param _beneficiary Address receiving the tokens
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
    // optional override
  }



  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds() internal {
    
    uint256 _rateWei=100000000;
    uint256 tecTokensRate =  6896551;
    //uint256 crowdTokensRate = 931;
   
    uint256 msgValue = msg.value;
    uint256 tecValue =msgValue.mul(tecTokensRate).div(_rateWei);
    uint256 crowdValue =msgValue.sub(tecValue);
   
    techWallet.transfer(tecValue);
    wallet.transfer(crowdValue);
   
    
    emit TokenAmount("_forwardFunds ", msgValue);
    
    emit TokenAmount("_forwardFunds ", tecValue);
    
    emit TokenAmount("_forwardFunds ", crowdValue);
  }
}


/**
 * @title TimedCrowdsale
 * @dev Crowdsale accepting contributions only within a time frame.
 */
contract TimedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public openingTime;
  uint256 public closingTime;

  /**
   * @dev Reverts if not in crowdsale time range.
   */
  modifier onlyWhileOpen {
    require(now >= openingTime && now <= closingTime);
    _;
  }

  /**
   * @dev Constructor, takes crowdsale opening and closing times.
   * @param _openingTime Crowdsale opening time
   * @param _closingTime Crowdsale closing time
   */
  constructor (uint256 _openingTime, uint256 _closingTime) public {
    //require(_openingTime >= now);
    require(_closingTime >= _openingTime);

    openingTime = _openingTime;
    closingTime = _closingTime;
  }

  /**
   * @dev Checks whether the period in which the crowdsale is open has already elapsed.
   * @return Whether crowdsale period has elapsed
   */
  function hasClosed() public view returns (bool) {
    return now > closingTime;
  }

  /**
   * @dev Extend parent behavior requiring to be within contributing period
   * @param _beneficiary Token purchaser
   * @param _weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal onlyWhileOpen {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}



/**
 * @title FinalizableCrowdsale
 * @dev Extension of Crowdsale where an owner can do extra work
 * after finishing.
 */
contract FinalizableCrowdsale is TimedCrowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

  /**
   * @dev Must be called after crowdsale ends, to do some extra finalization
   * work. Calls the contract&#39;s finalization function.
   */
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasClosed());

    finalization();
    emit Finalized();

    isFinalized = true;
  }

  /**
   * @dev Can be overridden to add finalization logic. The overriding function
   * should call super.finalization() to ensure the chain of finalization is
   * executed entirely.
   */
  function finalization() internal {
  }
}

/**
 * @title WhitelistedCrowdsale
 * @dev Crowdsale in which only whitelisted users can contribute.
 */
contract WhitelistedCrowdsale is Crowdsale, Ownable {

  mapping(address => bool) public whitelist;

  /**
   * @dev Reverts if beneficiary is not whitelisted. Can be used when extending this contract.
   */
  modifier isWhitelisted(address _beneficiary) {
    require(whitelist[_beneficiary]);
    _;
  }

  /**
   * @dev Adds single address to whitelist.
   * @param _beneficiary Address to be added to the whitelist
   */
  function addToWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = true;
  }

  /**
   * @dev Adds list of addresses to whitelist. Not overloaded due to limitations with truffle testing.
   * @param _beneficiaries Addresses to be added to the whitelist
   */
  function addManyToWhitelist(address[] _beneficiaries) external onlyOwner {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
    }
  }

  /**
   * @dev Removes single address from whitelist.
   * @param _beneficiary Address to be removed to the whitelist
   */
  function removeFromWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = false;
  }

  /**
   * @dev Extend parent behavior requiring beneficiary to be in whitelist.
   * @param _beneficiary Token beneficiary
   * @param _weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal isWhitelisted(_beneficiary) {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}


/**
 * @title STACrowdsale
 * @dev STA Token that can be minted.
 * It is meant to be used in a crowdsale contract.
 */
contract STACrowdsale is FinalizableCrowdsale,WhitelistedCrowdsale {
    using SafeMath for uint256;
    // Constants
    string public constant version = "1.0";
  
  
  
    address public constant TEC_TEAM_WALLET=0xa6567DFf7A196eEFaC0FF8F0Adeb033035231Deb ;
    
    address public constant AIRDROP_WALLET=0x5e4324744275145fdC2ED003be119e3e74a7cE87 ;
    address public constant EQUIPMENT_REWARD_WALLET=0x0a170a9E978E929FE91D58cA60647b0373c57Dfc ;
    address public constant CROWDSALE_REWARD_WALLET=0x70BeB827621F7E14E85F5B1F6dFF97C2a7eb4E21 ;
    
    address public constant CROWDSALE_ETH_WALLET=0x851FE9d96D9AC60776f235517094A5Aa439833B0 ;
    address public constant FOUNDER_WALET=0xe12F46ccf13d2A0130bD6ba8Ba4C7dB979a41654 ;
    
    
    
    
    
    


  //Award According to the day attenuation
   uint256 public constant intervalTime = 86400; 
   
   event RateInfo(string info, uint256 amount);


    /**
    * @dev Constructor, takes crowdsale opening and closing times.
    * @param _rateStart Number of token units a buyer gets per wei
    * @param _token Address of the token being sold
    */

    constructor (uint256 _openingTime, uint256 _closingTime,uint256 _rateStart, address _token) public
    Crowdsale(_rateStart, CROWDSALE_ETH_WALLET,TEC_TEAM_WALLET, _token)
    TimedCrowdsale(_openingTime, _closingTime)
    {
       

    }



    /**
    * @dev Can be overridden to add finalization logic. The overriding function
    * should call super.finalization() to ensure the chain of finalization is
    * executed entirely.
    */
    function finalization() internal {
       
        uint256 totalSupply_ = CROWDSALE_TOKENS_NUMS;
        uint256 totalSale_ = token.totalCrowdSale();
        // // total remaining Tokens
        // MintableToken token = MintableToken(token);
        token.mint(FOUNDER_WALET,totalSupply_.sub(totalSale_));
        token.finishMinting();
        super.finalization();
    }
    
  /**
   * @dev fallback function ***DO NOT OVERRIDE***
   */
  function () external payable {
    buyTokens(msg.sender);
  }
  
   /**
   * @dev low level token purchase ***DO NOT OVERRIDE***
   * @param _beneficiary Address performing the token purchase
   */
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

    // calculate token amount to be created
    uint256 tokens = _getTokenAmount(weiAmount);

    // update state
    weiRaised = weiRaised.add(weiAmount);

   emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
    _processPurchase(_beneficiary, tokens);


    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
  }
    
    /**
    * @dev Override to extend the way in which ether is converted to tokens.
    * @param _weiAmount Value in wei to be converted into tokens
    * @return Number of tokens that can be purchased with the specified _weiAmount
    */
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        return computeTokens(_weiAmount);
    }
    
      /**
    * @dev Computes overall bonus based on time of contribution and amount of contribution.
    * The total bonus is the sum of bonus by time and bonus by amount
    * @return tokens
    */
    function computeTokens(uint256 _weiAmount) public constant returns(uint256) {
        
        uint256 tokens = _weiAmount.mul(getRate());
       
        uint256 crowNums = CROWDSALE_TOKENS_NUMS;
        uint256 totolCrowd_ = token.totalCrowdSale();
        uint256 leftNums = crowNums.sub(totolCrowd_);
        require(leftNums>=tokens);
        return tokens;
    }

 function getRate() public constant returns (uint256)
 {
      
      // require(now >= openingTime && now <= closingTime);
       uint256 ret = 1;
       uint256 reduInterval= 1000;
       uint256 reduRate = reduInterval.div(9);
     
      uint256 startTimeStamp =now.sub(openingTime);
     
     
       if(startTimeStamp<intervalTime)
       {
           startTimeStamp = 0;
       }
     
       ret = startRate - (startTimeStamp.div(intervalTime).mul(reduRate));
     
       if( closingTime.sub(now)<intervalTime)
       {
           ret =10000;
       }
       
       return ret;
  }



}