pragma solidity 0.4.23;

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: zeppelin-solidity/contracts/math/SafeMath.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/BasicToken.sol

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
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

// File: zeppelin-solidity/contracts/token/ERC20/ERC20.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/StandardToken.sol

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
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

// File: zeppelin-solidity/contracts/token/ERC20/MintableToken.sol

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
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

// File: zeppelin-solidity/contracts/lifecycle/Pausable.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/PausableToken.sol

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

// File: contracts/REBToken.sol

/**
 * @title REB Token contract - ERC20 compatible token contract.
 */
contract REBToken is PausableToken, MintableToken {
    string public name = "REBGLO Token";
    string public symbol = "REB";
    uint8 public decimals = 18;

    /**
     * @dev Contract constructor function to start token paused for transfer
     */
    function REBToken() public {
        pause();
    }

    /**
     * @dev check user&#39;s REB balance tier
     * @param holderAddress Token holder address
     * @return string representing the milestone tier
     */
    function checkBalanceTier(address holderAddress) public view returns(string) {
        uint256 holderBalance = balanceOf(holderAddress);

        if (holderBalance >= 1000000e18) {
            return "Platinum tier";
        } else if (holderBalance >= 700000e18) {
            return "Gold tier";
        } else if (holderBalance >= 300000e18) {
            return "Titanium tier";
        } else if (holderBalance == 0) {
            return "Possess no REB";
        }

        return "Free tier";
    }
}

// File: contracts/LockTokenAllocation.sol

/**
 * @title LockTokenAllocation contract
 */
contract LockTokenAllocation is Ownable {
    using SafeMath for uint;
    uint256 public unlockedAt;
    uint256 public canSelfDestruct;
    uint256 public tokensCreated;
    uint256 public allocatedTokens;
    uint256 public totalLockTokenAllocation;

    mapping (address => uint256) public lockedAllocations;

    REBToken public REB;

    /**
     * @dev constructor function that sets token, totalTokenSupply, unlock time, and selfdestruct timestamp
     * for the LockTokenAllocation contract
     */
    function LockTokenAllocation
        (
            REBToken _token,
            uint256 _unlockedAt,
            uint256 _canSelfDestruct,
            uint256 _totalLockTokenAllocation
        )
        public
    {
        require(_token != address(0));

        REB = REBToken(_token);
        unlockedAt = _unlockedAt;
        canSelfDestruct = _canSelfDestruct;
        totalLockTokenAllocation = _totalLockTokenAllocation;
    }

    /**
     * @dev Adds founders&#39; token allocation
     * @param beneficiary Ethereum address of a person
     * @param allocationValue Number of tokens allocated to person
     * @return true if address is correctly added
     */
    function addLockTokenAllocation(address beneficiary, uint256 allocationValue)
        external
        onlyOwner
        returns(bool)
    {
        require(lockedAllocations[beneficiary] == 0 && beneficiary != address(0)); // can only add once.

        allocatedTokens = allocatedTokens.add(allocationValue);
        require(allocatedTokens <= totalLockTokenAllocation);

        lockedAllocations[beneficiary] = allocationValue;
        return true;
    }


    /**
     * @dev Allow unlocking of allocated tokens by transferring them to whitelisted addresses.
     * Need to be called by each address
     */
    function unlock() external {
        require(REB != address(0));
        assert(now >= unlockedAt);

        // During first unlock attempt fetch total number of locked tokens.
        if (tokensCreated == 0) {
            tokensCreated = REB.balanceOf(this);
        }

        uint256 transferAllocation = lockedAllocations[msg.sender];
        lockedAllocations[msg.sender] = 0;

        // Will fail if allocation (and therefore toTransfer) is 0.
        require(REB.transfer(msg.sender, transferAllocation));
    }

    /**
     * @dev allow for selfdestruct possibility and sending funds to owner
     */
    function kill() public onlyOwner {
        require(now >= canSelfDestruct);
        uint256 balance = REB.balanceOf(this);

        if (balance > 0) {
            REB.transfer(msg.sender, balance);
        }

        selfdestruct(owner);
    }
}

// File: zeppelin-solidity/contracts/crowdsale/Crowdsale.sol

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
  ERC20 public token;

  // Address where funds are collected
  address public wallet;

  // How many token units a buyer gets per wei
  uint256 public rate;

  // Amount of wei raised
  uint256 public weiRaised;

  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  /**
   * @param _rate Number of token units a buyer gets per wei
   * @param _wallet Address where collected funds will be forwarded to
   * @param _token Address of the token being sold
   */
  function Crowdsale(uint256 _rate, address _wallet, ERC20 _token) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    rate = _rate;
    wallet = _wallet;
    token = _token;
  }

  // -----------------------------------------
  // Crowdsale external interface
  // -----------------------------------------

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

    _processPurchase(_beneficiary, tokens);
    TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
  }

  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------

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
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    return _weiAmount.mul(rate);
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}

// File: zeppelin-solidity/contracts/crowdsale/validation/TimedCrowdsale.sol

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
  function TimedCrowdsale(uint256 _openingTime, uint256 _closingTime) public {
    require(_openingTime >= now);
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

// File: zeppelin-solidity/contracts/crowdsale/distribution/FinalizableCrowdsale.sol

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
    Finalized();

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

// File: zeppelin-solidity/contracts/crowdsale/validation/WhitelistedCrowdsale.sol

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

// File: contracts/REBCrowdsale.sol

/**
 * @title REB Crowdsale contract - crowdsale contract for the REB tokens.
 */
contract REBCrowdsale is FinalizableCrowdsale, WhitelistedCrowdsale, Pausable {
    uint256 constant public BOUNTY_SHARE =               125000000e18;   // 125 M
    uint256 constant public TEAM_SHARE =                 2800000000e18;  // 2.8 B
    uint256 constant public ADVISOR_SHARE =              1750000000e18;  // 1.75 B

    uint256 constant public AIRDROP_SHARE =              200000000e18;   // 200 M
    uint256 constant public TOTAL_TOKENS_FOR_CROWDSALE = 5125000000e18;  // 5.125 B

    uint256 constant public PUBLIC_CROWDSALE_SOFT_CAP =  800000000e18;  // 800 M

    address public bountyWallet;
    address public teamReserve;
    address public advisorReserve;
    address public airdrop;

    // remainderPurchaser and remainderTokens info saved in the contract
    // used for reference for contract owner to send refund if any to last purchaser after end of crowdsale
    address public remainderPurchaser;
    uint256 public remainderAmount;

    // external contracts

    event MintedTokensFor(address indexed investor, uint256 tokensPurchased);
    event TokenRateChanged(uint256 previousRate, uint256 newRate);

    /**
     * @dev Contract constructor function
     * @param _openingTime The timestamp of the beginning of the crowdsale
     * @param _closingTime Timestamp when the crowdsale will finish
     * @param _token REB token address
     * @param _rate The token rate per ETH
     * @param _wallet Multisig wallet that will hold the crowdsale funds.
     * @param _bountyWallet Ethereum address where bounty tokens will be minted to
     */
    function REBCrowdsale
        (
            uint256 _openingTime,
            uint256 _closingTime,
            REBToken _token,
            uint256 _rate,
            address _wallet,
            address _bountyWallet
        )
        public
        FinalizableCrowdsale()
        Crowdsale(_rate, _wallet, _token)
        TimedCrowdsale(_openingTime, _closingTime)
    {
        require(_bountyWallet != address(0));
        bountyWallet = _bountyWallet;

        require(REBToken(token).paused());
        // NOTE: Ensure token ownership is transferred to crowdsale so it able to mint tokens
    }

    /**
     * @dev change crowdsale rate
     * @param newRate Figure that corresponds to the new rate per token
     */
    function setRate(uint256 newRate) external onlyOwner {
        require(newRate != 0);

        TokenRateChanged(rate, newRate);
        rate = newRate;
    }

    /**
     * @dev Mint tokens investors that send fiat for token purchases.
     * The send of fiat will be off chain and custom minting happens in this function and it performed by the owner
     * @param beneficiaryAddress Address of beneficiary
     * @param amountOfTokens Number of tokens to be created
     */
    function mintTokensFor(address beneficiaryAddress, uint256 amountOfTokens)
        public
        onlyOwner
    {
        require(beneficiaryAddress != address(0));
        require(token.totalSupply().add(amountOfTokens) <= TOTAL_TOKENS_FOR_CROWDSALE);

        _deliverTokens(beneficiaryAddress, amountOfTokens);
        MintedTokensFor(beneficiaryAddress, amountOfTokens);
    }

    /**
     * @dev Set the address which should receive the vested team and advisors tokens plus airdrop shares on finalization
     * @param _teamReserve address of team and advisor allocation contract
     * @param _advisorReserve address of team and advisor allocation contract
     * @param _airdrop address of airdrop contract
     */
    function setTeamAndAdvisorAndAirdropAddresses
        (
            address _teamReserve,
            address _advisorReserve,
            address _airdrop
        )
        public
        onlyOwner
    {
        // only able to be set once
        require(teamReserve == address(0x0) && advisorReserve == address(0x0) && airdrop == address(0x0));
        // ensure that the addresses as params to the func are not empty
        require(_teamReserve != address(0x0) && _advisorReserve != address(0x0) && _airdrop != address(0x0));

        teamReserve = _teamReserve;
        advisorReserve = _advisorReserve;
        airdrop = _airdrop;
    }

    // overriding TimeCrowdsale#hasClosed to add cap logic
    // @return true if crowdsale event has ended
    function hasClosed() public view returns (bool) {
        if (token.totalSupply() > PUBLIC_CROWDSALE_SOFT_CAP) {
            return true;
        }

        return super.hasClosed();
    }

    /**
     * @dev Overrides delivery by minting tokens upon purchase.
     * @param _beneficiary Token purchaser
     * @param _tokenAmount Number of tokens to be minted
     */
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        require(MintableToken(token).mint(_beneficiary, _tokenAmount));
    }

    /**
     * @dev Override validation of an incoming purchase.
     * Use require statemens to revert state when conditions are not met. Use super to concatenate validations.
     * @param _beneficiary Address performing the token purchase
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount)
        internal
        isWhitelisted(_beneficiary)
        whenNotPaused
    {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
        require(token.totalSupply() < TOTAL_TOKENS_FOR_CROWDSALE);
    }

    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param _weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        uint256 tokensAmount = _weiAmount.mul(rate);

        // remainder logic
        if (token.totalSupply().add(tokensAmount) > TOTAL_TOKENS_FOR_CROWDSALE) {
            tokensAmount = TOTAL_TOKENS_FOR_CROWDSALE.sub(token.totalSupply());
            uint256 _weiAmountLocalScope = tokensAmount.div(rate);

            // save info so as to refund purchaser after crowdsale&#39;s end
            remainderPurchaser = msg.sender;
            remainderAmount = _weiAmount.sub(_weiAmountLocalScope);

            // update state here so when it is updated again in buyTokens the weiAmount reflects the remainder logic
            if (weiRaised > _weiAmount.add(_weiAmountLocalScope))
                weiRaised = weiRaised.sub(_weiAmount.add(_weiAmountLocalScope));
        }

        return tokensAmount;
    }

    /**
     * @dev finalizes crowdsale
     */
    function finalization() internal {
        // This must have been set manually prior to finalize().
        require(teamReserve != address(0x0) && advisorReserve != address(0x0) && airdrop != address(0x0));

        if (TOTAL_TOKENS_FOR_CROWDSALE > token.totalSupply()) {
            uint256 remainingTokens = TOTAL_TOKENS_FOR_CROWDSALE.sub(token.totalSupply());
            _deliverTokens(wallet, remainingTokens);
        }

        // final minting
        _deliverTokens(bountyWallet, BOUNTY_SHARE);
        _deliverTokens(teamReserve, TEAM_SHARE);
        _deliverTokens(advisorReserve, ADVISOR_SHARE);
        _deliverTokens(airdrop, AIRDROP_SHARE);

        REBToken(token).finishMinting();
        REBToken(token).unpause();
        super.finalization();
    }
}