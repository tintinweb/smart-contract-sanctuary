pragma solidity ^0.4.21;


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
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

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
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

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
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/openzeppelin-solidity/issues/120
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


contract LittlePhilCoin is MintableToken, PausableToken {
    string public name = "Little Phil Coin";
    string public symbol = "LPC";
    uint8 public decimals = 18;

    constructor () public {
        // Pause token on creation and only unpause after ICO
        pause();
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
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );

    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
  }

  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------

  /**
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
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






/**
 * @title TokenTimelock
 * @dev TokenTimelock is a token holder contract that will allow a
 * beneficiary to extract the tokens after a given release time
 */
contract TokenTimelock {
  using SafeERC20 for ERC20Basic;

  // ERC20 basic token contract being held
  ERC20Basic public token;

  // beneficiary of tokens after they are released
  address public beneficiary;

  // timestamp when token release is enabled
  uint256 public releaseTime;

  function TokenTimelock(ERC20Basic _token, address _beneficiary, uint256 _releaseTime) public {
    // solium-disable-next-line security/no-block-members
    require(_releaseTime > block.timestamp);
    token = _token;
    beneficiary = _beneficiary;
    releaseTime = _releaseTime;
  }

  /**
   * @notice Transfers tokens held by timelock to beneficiary.
   */
  function release() public {
    // solium-disable-next-line security/no-block-members
    require(block.timestamp >= releaseTime);

    uint256 amount = token.balanceOf(this);
    require(amount > 0);

    token.safeTransfer(beneficiary, amount);
  }
}



contract InitialSupplyCrowdsale is Crowdsale, Ownable {

    using SafeMath for uint256;

    uint256 public constant decimals = 18;

    // Wallet properties
    address public companyWallet;
    address public teamWallet;
    address public projectWallet;
    address public advisorWallet;
    address public bountyWallet;
    address public airdropWallet;

    // Team locked tokens
    TokenTimelock public teamTimeLock1;
    TokenTimelock public teamTimeLock2;

    // Reserved tokens
    uint256 public constant companyTokens    = SafeMath.mul(150000000, (10 ** decimals));
    uint256 public constant teamTokens       = SafeMath.mul(150000000, (10 ** decimals));
    uint256 public constant projectTokens    = SafeMath.mul(150000000, (10 ** decimals));
    uint256 public constant advisorTokens    = SafeMath.mul(100000000, (10 ** decimals));
    uint256 public constant bountyTokens     = SafeMath.mul(30000000, (10 ** decimals));
    uint256 public constant airdropTokens    = SafeMath.mul(20000000, (10 ** decimals));

    bool private isInitialised = false;

    constructor(
        address[6] _wallets
    ) public {
        address _companyWallet  = _wallets[0];
        address _teamWallet     = _wallets[1];
        address _projectWallet  = _wallets[2];
        address _advisorWallet  = _wallets[3];
        address _bountyWallet   = _wallets[4];
        address _airdropWallet  = _wallets[5];

        require(_companyWallet != address(0));
        require(_teamWallet != address(0));
        require(_projectWallet != address(0));
        require(_advisorWallet != address(0));
        require(_bountyWallet != address(0));
        require(_airdropWallet != address(0));

        // Set reserved wallets
        companyWallet = _companyWallet;
        teamWallet = _teamWallet;
        projectWallet = _projectWallet;
        advisorWallet = _advisorWallet;
        bountyWallet = _bountyWallet;
        airdropWallet = _airdropWallet;

        // Lock team tokens in wallet over time periods
        teamTimeLock1 = new TokenTimelock(token, teamWallet, uint64(now + 182 days));
        teamTimeLock2 = new TokenTimelock(token, teamWallet, uint64(now + 365 days));
    }

    /**
     * Function: Distribute initial token supply
     */
    function setupInitialSupply() internal onlyOwner {
        require(isInitialised == false);
        uint256 teamTokensSplit = teamTokens.mul(50).div(100);

        // Distribute tokens to reserved wallets
        LittlePhilCoin(token).mint(companyWallet, companyTokens);
        LittlePhilCoin(token).mint(projectWallet, projectTokens);
        LittlePhilCoin(token).mint(advisorWallet, advisorTokens);
        LittlePhilCoin(token).mint(bountyWallet, bountyTokens);
        LittlePhilCoin(token).mint(airdropWallet, airdropTokens);
        LittlePhilCoin(token).mint(address(teamTimeLock1), teamTokensSplit);
        LittlePhilCoin(token).mint(address(teamTimeLock2), teamTokensSplit);

        isInitialised = true;
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
 * @title MintedCrowdsale
 * @dev Extension of Crowdsale contract whose tokens are minted in each purchase.
 * Token ownership should be transferred to MintedCrowdsale for minting.
 */
contract MintedCrowdsale is Crowdsale {

  /**
   * @dev Overrides delivery by minting tokens upon purchase.
   * @param _beneficiary Token purchaser
   * @param _tokenAmount Number of tokens to be minted
   */
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    require(MintableToken(token).mint(_beneficiary, _tokenAmount));
  }
}












/**
 * @title CappedCrowdsale
 * @dev Crowdsale with a limit for total contributions.
 */
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

  /**
   * @dev Constructor, takes maximum amount of wei accepted in the crowdsale.
   * @param _cap Max amount of wei to be contributed
   */
  function CappedCrowdsale(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

  /**
   * @dev Checks whether the cap has been reached.
   * @return Whether the cap was reached
   */
  function capReached() public view returns (bool) {
    return weiRaised >= cap;
  }

  /**
   * @dev Extend parent behavior requiring purchase to respect the funding cap.
   * @param _beneficiary Token purchaser
   * @param _weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    super._preValidatePurchase(_beneficiary, _weiAmount);
    require(weiRaised.add(_weiAmount) <= cap);
  }

}



/**
 * @title TokenCappedCrowdsale
 * @dev Crowdsale with a limit for total minted tokens.
 */
contract TokenCappedCrowdsale is Crowdsale {
    using SafeMath for uint256;

    uint256 public tokenCap = 0;

    // Amount of LPC raised
    uint256 public tokensRaised = 0;

    // event for manual refund of cap overflow
    event CapOverflow(address indexed sender, uint256 weiAmount, uint256 receivedTokens, uint256 date);

    /**
     * Checks whether the tokenCap has been reached.
     * @return Whether the tokenCap was reached
     */
    function capReached() public view returns (bool) {
        return tokensRaised >= tokenCap;
    }

    /**
     * Accumulate the purchased tokens to the total raised
     */
    function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
        require(_beneficiary != address(0));
        super._updatePurchasingState(_beneficiary, _weiAmount);
        uint256 purchasedTokens = _getTokenAmount(_weiAmount);
        tokensRaised = tokensRaised.add(purchasedTokens);

        if(capReached()) {
            // manual process unused eth amount to sender
            emit CapOverflow(_beneficiary, _weiAmount, purchasedTokens, now);
        }
    }

}




/**
 * @title TieredCrowdsale
 * @dev Extension of Crowdsale contract that decreases the number of LPC tokens purchases dependent on the current number of tokens sold.
 */
contract TieredCrowdsale is TokenCappedCrowdsale, Ownable {

    using SafeMath for uint256;

    /**
    SalesState enum for use in state machine to manage sales rates
    */
    enum SaleState {
        Initial,              // All contract initialization calls
        PrivateSale,          // Private sale for industy and closed group investors
        FinalisedPrivateSale, // Close private sale
        PreSale,              // Pre sale ICO (40% bonus LPC hard-capped at 180 million tokens)
        FinalisedPreSale,     // Close presale
        PublicSaleTier1,      // Tier 1 ICO public sale (30% bonus LPC capped at 85 million tokens)
        PublicSaleTier2,      // Tier 2 ICO public sale (20% bonus LPC capped at 65 million tokens)
        PublicSaleTier3,      // Tier 3 ICO public sale (10% bonus LPC capped at 45 million tokens)
        PublicSaleTier4,      // Tier 4 ICO public sale (standard rate capped at 25 million tokens)
        FinalisedPublicSale,  // Close public sale
        Closed                // ICO has finished, all tokens must have been claimed
    }
    SaleState public state = SaleState.Initial;

    struct TierConfig {
        string stateName;
        uint256 tierRatePercentage;
        uint256 hardCap;
    }

    mapping(bytes32 => TierConfig) private tierConfigs;

    // event for manual refund of cap overflow
    event IncrementTieredState(string stateName);

    /**
    * checks the state when validating a purchase
    */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
        require(_beneficiary != address(0));
        super._preValidatePurchase(_beneficiary, _weiAmount);
        require(
            state == SaleState.PrivateSale ||
            state == SaleState.PreSale ||
            state == SaleState.PublicSaleTier1 ||
            state == SaleState.PublicSaleTier2 ||
            state == SaleState.PublicSaleTier3 ||
            state == SaleState.PublicSaleTier4
        );
    }

    /**
    * @dev Constructor
    * Caveat emptor: this base contract is intended for inheritance by the Little Phil crowdsale only
    */
    constructor() public {
        // setup the map of bonus-rates for each SaleState tier
        createSalesTierConfigMap();
    }

    /**
    * @dev Overrides parent method taking into account variable rate (as a percentage).
    * @param _weiAmount The value in wei to be converted into tokens
    * @return The number of tokens _weiAmount wei will buy at present time.
    */
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        uint256 currentTierRate = getCurrentTierRatePercentage();

        uint256 requestedTokenAmount = _weiAmount.mul(rate).mul(currentTierRate).div(100);

        uint256 remainingTokens = tokenCap.sub(tokensRaised);

        // return number of LPC to provide
        if(requestedTokenAmount > remainingTokens ) {
            return remainingTokens;
        }

        return requestedTokenAmount;
    }

    /**
    * @dev setup the map of bonus-rates (as a percentage) and total hardCap for each SaleState tier
    * to be called by the constructor.
    */
    function createSalesTierConfigMap() private {

        tierConfigs [keccak256(SaleState.Initial)] = TierConfig({
            stateName: "Initial",
            tierRatePercentage:0,
            hardCap: 0
        });
        tierConfigs [keccak256(SaleState.PrivateSale)] = TierConfig({
            stateName: "PrivateSale",
            tierRatePercentage:100,
            hardCap: SafeMath.mul(400000000, (10 ** 18))
        });
        tierConfigs [keccak256(SaleState.FinalisedPrivateSale)] = TierConfig({
            stateName: "FinalisedPrivateSale",
            tierRatePercentage:0,
            hardCap: 0
        });
        tierConfigs [keccak256(SaleState.PreSale)] = TierConfig({
            stateName: "PreSale",
            tierRatePercentage:140,
            hardCap: SafeMath.mul(180000000, (10 ** 18))
        });
        tierConfigs [keccak256(SaleState.FinalisedPreSale)] = TierConfig({
            stateName: "FinalisedPreSale",
            tierRatePercentage:0,
            hardCap: 0
        });
        tierConfigs [keccak256(SaleState.PublicSaleTier1)] = TierConfig({
            stateName: "PublicSaleTier1",
            tierRatePercentage:130,
            hardCap: SafeMath.mul(265000000, (10 ** 18))
        });
        tierConfigs [keccak256(SaleState.PublicSaleTier2)] = TierConfig({
            stateName: "PublicSaleTier2",
            tierRatePercentage:120,
            hardCap: SafeMath.mul(330000000, (10 ** 18))
        });
        tierConfigs [keccak256(SaleState.PublicSaleTier3)] = TierConfig({
            stateName: "PublicSaleTier3",
            tierRatePercentage:110,
            hardCap: SafeMath.mul(375000000, (10 ** 18))
        });
        tierConfigs [keccak256(SaleState.PublicSaleTier4)] = TierConfig({
            stateName: "PublicSaleTier4",
            tierRatePercentage:100,
            hardCap: SafeMath.mul(400000000, (10 ** 18))
        });
        tierConfigs [keccak256(SaleState.FinalisedPublicSale)] = TierConfig({
            stateName: "FinalisedPublicSale",
            tierRatePercentage:0,
            hardCap: 0
        });
        tierConfigs [keccak256(SaleState.Closed)] = TierConfig({
            stateName: "Closed",
            tierRatePercentage:0,
            hardCap: SafeMath.mul(400000000, (10 ** 18))
        });

    }

    /**
    * @dev get the current bonus-rate for the current SaleState
    * @return the current rate as a percentage (e.g. 140 = 140% bonus)
    */
    function getCurrentTierRatePercentage() public view returns (uint256) {
        return tierConfigs[keccak256(state)].tierRatePercentage;
    }

    /**
    * @dev get the current hardCap for the current SaleState
    * @return the current hardCap
    */
    function getCurrentTierHardcap() public view returns (uint256) {
        return tierConfigs[keccak256(state)].hardCap;
    }

    /**
    * @dev only allow the owner to modify the current SaleState
    */
    function setState(uint256 _state) onlyOwner public {
        state = SaleState(_state);

        // update cap when state changes
        tokenCap = getCurrentTierHardcap();

        if(state == SaleState.Closed) {
            crowdsaleClosed();
        }
    }

    function getState() public view returns (string) {
        return tierConfigs[keccak256(state)].stateName;
    }

    /**
    * @dev only allow onwer to modify the current SaleState
    */
    function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
        require(_beneficiary != address(0));
        super._updatePurchasingState(_beneficiary, _weiAmount);

        if(capReached()) {
            if(state == SaleState.PrivateSale) {
                state = SaleState.FinalisedPrivateSale;
                tokenCap = getCurrentTierHardcap();
                emit IncrementTieredState(getState());
            }
            else if(state == SaleState.PreSale) {
                state = SaleState.FinalisedPreSale;
                tokenCap = getCurrentTierHardcap();
                emit IncrementTieredState(getState());
            }
            else if(state == SaleState.PublicSaleTier1) {
                state = SaleState.PublicSaleTier2;
                tokenCap = getCurrentTierHardcap();
                emit IncrementTieredState(getState());
            }
            else if(state == SaleState.PublicSaleTier2) {
                state = SaleState.PublicSaleTier3;
                tokenCap = getCurrentTierHardcap();
                emit IncrementTieredState(getState());
            }
            else if(state == SaleState.PublicSaleTier3) {
                state = SaleState.PublicSaleTier4;
                tokenCap = getCurrentTierHardcap();
                emit IncrementTieredState(getState());
            }
            else if(state == SaleState.PublicSaleTier4) {
                state = SaleState.FinalisedPublicSale;
                tokenCap = getCurrentTierHardcap();
                emit IncrementTieredState(getState());
            }

        }

    }

    /**
     * Override for extensions that require an internal notification when the crowdsale has closed
     */
    function crowdsaleClosed () internal {
        // optional override
    }

}





/* solium-disable security/no-block-members */









/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period. Optionally revocable by the
 * owner.
 */
contract TokenVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;

  event Released(uint256 amount);
  event Revoked();

  // beneficiary of tokens after they are released
  address public beneficiary;

  uint256 public cliff;
  uint256 public start;
  uint256 public duration;

  bool public revocable;

  mapping (address => uint256) public released;
  mapping (address => bool) public revoked;

  /**
   * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
   * _beneficiary, gradually in a linear fashion until _start + _duration. By then all
   * of the balance will have vested.
   * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
   * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
   * @param _duration duration in seconds of the period in which the tokens will vest
   * @param _revocable whether the vesting is revocable or not
   */
  function TokenVesting(
    address _beneficiary,
    uint256 _start,
    uint256 _cliff,
    uint256 _duration,
    bool _revocable
  )
    public
  {
    require(_beneficiary != address(0));
    require(_cliff <= _duration);

    beneficiary = _beneficiary;
    revocable = _revocable;
    duration = _duration;
    cliff = _start.add(_cliff);
    start = _start;
  }

  /**
   * @notice Transfers vested tokens to beneficiary.
   * @param token ERC20 token which is being vested
   */
  function release(ERC20Basic token) public {
    uint256 unreleased = releasableAmount(token);

    require(unreleased > 0);

    released[token] = released[token].add(unreleased);

    token.safeTransfer(beneficiary, unreleased);

    emit Released(unreleased);
  }

  /**
   * @notice Allows the owner to revoke the vesting. Tokens already vested
   * remain in the contract, the rest are returned to the owner.
   * @param token ERC20 token which is being vested
   */
  function revoke(ERC20Basic token) public onlyOwner {
    require(revocable);
    require(!revoked[token]);

    uint256 balance = token.balanceOf(this);

    uint256 unreleased = releasableAmount(token);
    uint256 refund = balance.sub(unreleased);

    revoked[token] = true;

    token.safeTransfer(owner, refund);

    emit Revoked();
  }

  /**
   * @dev Calculates the amount that has already vested but hasn&#39;t been released yet.
   * @param token ERC20 token which is being vested
   */
  function releasableAmount(ERC20Basic token) public view returns (uint256) {
    return vestedAmount(token).sub(released[token]);
  }

  /**
   * @dev Calculates the amount that has already vested.
   * @param token ERC20 token which is being vested
   */
  function vestedAmount(ERC20Basic token) public view returns (uint256) {
    uint256 currentBalance = token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(released[token]);

    if (block.timestamp < cliff) {
      return 0;
    } else if (block.timestamp >= start.add(duration) || revoked[token]) {
      return totalBalance;
    } else {
      return totalBalance.mul(block.timestamp.sub(start)).div(duration);
    }
  }
}



contract TokenVestingCrowdsale is Crowdsale, Ownable {

    function addBeneficiaryVestor(
            address beneficiaryWallet,
            uint256 tokenAmount,
            uint256 vestingEpocStart,
            uint256 cliffInSeconds,
            uint256 vestingEpocEnd
        ) external onlyOwner {
        TokenVesting newVault = new TokenVesting(
            beneficiaryWallet,
            vestingEpocStart,
            cliffInSeconds,
            vestingEpocEnd,
            false
        );
        LittlePhilCoin(token).mint(address(newVault), tokenAmount);
    }

    function releaseVestingTokens(address vaultAddress) external onlyOwner {
        TokenVesting(vaultAddress).release(token);
    }

}

contract LittlePhilCrowdsale is MintedCrowdsale, TieredCrowdsale, InitialSupplyCrowdsale, WhitelistedCrowdsale, TokenVestingCrowdsale {

    /**
    * Event for rate-change logging
    * @param rate the new ETH-to_LPC exchange rate
    */
    event NewRate(uint256 rate);

    // Constructor
    constructor(
        uint256 _rate,
        address _fundsWallet,
        address[6] _wallets,
        LittlePhilCoin _token
    ) public
    Crowdsale(_rate, _fundsWallet, _token)
    InitialSupplyCrowdsale(_wallets) {}

    // Sets up the initial balances
    // This must be called after ownership of the token is transferred to the crowdsale
    function setupInitialState() external onlyOwner {
        setupInitialSupply();
    }

    // Ownership management
    function transferTokenOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0));
        // I assume the crowdsale contract holds a reference to the token contract.
        LittlePhilCoin(token).transferOwnership(_newOwner);
    }

    // Called at the end of the crowdsale when it is eneded
    function crowdsaleClosed () internal {
        uint256 remainingTokens = tokenCap.sub(tokensRaised);
        _deliverTokens(airdropWallet, remainingTokens);
        LittlePhilCoin(token).finishMinting();
    }

    /**
    * checks the state when validating a purchase
    */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
        require(_beneficiary != address(0));
        super._preValidatePurchase(_beneficiary, _weiAmount);
        require(_weiAmount >= 500000000000000000);
    }

    /**
     * @dev sets (updates) the ETH-to-LPC exchange rate
     * @param _rate ate that will applied to ETH to derive how many LPC to mint
     * does not affect, nor influenced by the bonus rates based on the current tier.
     */
    function setRate(int _rate) public onlyOwner {
        require(_rate > 0);
        rate = uint256(_rate);
        emit NewRate(rate);
    }

     /**
      * @dev allows for minting from owner account
      */
    function mintForPrivateFiat(address _beneficiary, uint256 _weiAmount) public onlyOwner {
        require(_beneficiary != address(0));
        // require(_weiAmount > 0);
        _preValidatePurchase(_beneficiary, _weiAmount);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(_weiAmount);

        // update state
        weiRaised = weiRaised.add(_weiAmount);
        tokensRaised = tokensRaised.add(tokens);

        if(capReached()) {
            // manual process unused eth amount to sender
            emit CapOverflow(_beneficiary, _weiAmount, tokens, now);
            emit IncrementTieredState(getState());
        }

        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase(
            msg.sender,
            _beneficiary,
            _weiAmount,
            tokens
        );

        _updatePurchasingState(_beneficiary, _weiAmount);

        _forwardFunds();
    }

}