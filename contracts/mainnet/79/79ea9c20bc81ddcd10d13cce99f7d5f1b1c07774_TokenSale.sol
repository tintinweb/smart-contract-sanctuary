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
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


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
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}




contract Distributable {

  using SafeMath for uint256;

  bool public distributed;
  //Not all actual addresses
  address[] public partners = [
  0xb68342f2f4dd35d93b88081b03a245f64331c95c,
  0x16CCc1e68D2165fb411cE5dae3556f823249233e,
  0x8E176EDA10b41FA072464C29Eb10CfbbF4adCd05, //Auditors Traning
  0x7c387c57f055993c857067A0feF6E81884656Cb0, //Reserve
  0x4F21c073A9B8C067818113829053b60A6f45a817, //Airdrop
  0xcB4b6B7c4a72754dEb99bB72F1274129D9C0A109, //Alex
  0x7BF84E0244c05A11c57984e8dF7CC6481b8f4258, //Adam
  0x20D2F4Be237F4320386AaaefD42f68495C6A3E81, //JG
  0x12BEA633B83aA15EfF99F68C2E7e14f2709802A9, //Rob S
  0xC1a29a165faD532520204B480D519686B8CB845B, //Nick
  0xf5f5Eb6Ab1411935b321042Fa02a433FcbD029AC, //Rob H
  0xaBff978f03d5ca81B089C5A2Fc321fB8152DC8f1]; //Ed

  address[] public partnerFixedAmount = [
  0xA482D998DA4d361A6511c6847562234077F09748,
  0xFa92F80f8B9148aDFBacC66aA7bbE6e9F0a0CD0e
  ];

  mapping(address => uint256) public percentages;
  mapping(address => uint256) public fixedAmounts;

  constructor() public{
    percentages[0xb68342f2f4dd35d93b88081b03a245f64331c95c] = 40;
    percentages[0x16CCc1e68D2165fb411cE5dae3556f823249233e] = 5;
    percentages[0x8E176EDA10b41FA072464C29Eb10CfbbF4adCd05] = 100; //Auditors Training
    percentages[0x7c387c57f055993c857067A0feF6E81884656Cb0] = 50; //Reserve
    percentages[0x4F21c073A9B8C067818113829053b60A6f45a817] = 10; //Airdrop

    percentages[0xcB4b6B7c4a72754dEb99bB72F1274129D9C0A109] = 20; //Alex
    percentages[0x7BF84E0244c05A11c57984e8dF7CC6481b8f4258] = 20; //Adam
    percentages[0x20D2F4Be237F4320386AaaefD42f68495C6A3E81] = 20; //JG
    percentages[0x12BEA633B83aA15EfF99F68C2E7e14f2709802A9] = 20; //Rob S

    percentages[0xC1a29a165faD532520204B480D519686B8CB845B] = 30; //Nick
    percentages[0xf5f5Eb6Ab1411935b321042Fa02a433FcbD029AC] = 30; //Rob H

    percentages[0xaBff978f03d5ca81B089C5A2Fc321fB8152DC8f1] = 52; //Ed

    fixedAmounts[0xA482D998DA4d361A6511c6847562234077F09748] = 886228 * 10**16;
    fixedAmounts[0xFa92F80f8B9148aDFBacC66aA7bbE6e9F0a0CD0e] = 697 ether;
  }
}











/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
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

  // How many token units a buyer gets per wei.
  // The rate is the conversion between wei and the smallest and indivisible token unit.
  // So, if you are using a rate of 1 with a DetailedERC20 token with 3 decimals called TOK
  // 1 wei will give you 1 unit, or 0.001 TOK.
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
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

  /**
   * @param _rate Number of token units a buyer gets per wei
   * @param _wallet Address where collected funds will be forwarded to
   * @param _token Address of the token being sold
   */
  constructor(uint256 _rate, address _wallet, ERC20 _token) public {
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
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

  /**
   * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid conditions are not met.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _postValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    // optional override
  }

  /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param _beneficiary Address performing the token purchase
   * @param _tokenAmount Number of tokens to be emitted
   */
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    token.transfer(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
   * @param _beneficiary Address receiving the tokens
   * @param _tokenAmount Number of tokens to be purchased
   */
  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
   * @param _beneficiary Address receiving the tokens
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    // optional override
  }

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 _weiAmount)
    internal view returns (uint256)
  {
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
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
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
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
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
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
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
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
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

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address _to,
    uint256 _amount
  )
    hasMintPermission
    canMint
    public
    returns (bool)
  {
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
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    require(MintableToken(token).mint(_beneficiary, _tokenAmount));
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
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
    isWhitelisted(_beneficiary)
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}





contract SolidToken is MintableToken {

  string public constant name = "SolidToken";
  string public constant symbol = "SOLID";
  uint8  public constant decimals = 18;

  uint256 constant private DECIMAL_PLACES = 10 ** 18;
  uint256 constant SUPPLY_CAP = 4000000 * DECIMAL_PLACES;

  bool public transfersEnabled = false;
  uint256 public transferEnablingDate;


  /**
   * @dev Sets the date that the tokens becomes transferable
   * @param date The timestamp of the date
   * @return A boolean that indicates if the operation was successful.
   */
  function setTransferEnablingDate(uint256 date) public onlyOwner returns(bool success) {
    transferEnablingDate = date;
    return true;
  }


  /**
   * @dev Enables the token transfer
   */
  function enableTransfer() public {
    require(transferEnablingDate != 0 && now >= transferEnablingDate);
    transfersEnabled = true;
  }



  // OVERRIDES
  /**
   * @dev Function to mint tokens. Overriden to check for supply cap.
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    require(totalSupply_.add(_amount) <= SUPPLY_CAP);
    require(super.mint(_to, _amount));
    return true;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(transfersEnabled, "Tranfers are disabled");
    require(super.transfer(_to, _value));
    return true;
  }


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(transfersEnabled, "Tranfers are disabled");
    require(super.transferFrom(_from, _to, _value));
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


contract TokenSale is MintedCrowdsale, WhitelistedCrowdsale, Pausable, Distributable {

  //Global Variables
  mapping(address => uint256) public contributions;
  Stages public currentStage;

  //CONSTANTS
  uint256 constant MINIMUM_CONTRIBUTION = 0.5 ether;  //the minimum conbtribution on Wei
  uint256 constant MAXIMUM_CONTRIBUTION = 100 ether;  //the maximum contribution on Wei
  uint256 constant BONUS_PERCENT = 250;                // The percentage of bonus in the fisrt stage, in;
  uint256 constant TOKENS_ON_SALE_PERCENT = 600;       //The percentage of avaiable tokens for sale;
  uint256 constant BONUSSALE_MAX_DURATION = 30 days ;
  uint256 constant MAINSALE_MAX_DURATION = 62 days;
  uint256 constant TOKEN_RELEASE_DELAY = 182 days;
  uint256 constant HUNDRED_PERCENT = 1000;            //100% considering one extra decimal

  //BONUSSALE VARIABLES
  uint256 public bonussale_Cap = 14400 ether;
  uint256 public bonussale_TokenCap = 1200000 ether;

  uint256 public bonussale_StartDate;
  uint256 public bonussale_EndDate;
  uint256 public bonussale_TokesSold;
  uint256 public bonussale_WeiRaised;

  //MAINSALE VARIABLES
  uint256 public mainSale_Cap = 18000 ether;
  uint256 public mainSale_TokenCap = 1200000 ether;

  uint256 public mainSale_StartDate;
  uint256 public mainSale_EndDate;
  uint256 public mainSale_TokesSold;
  uint256 public mainSale_WeiRaised;


  //TEMPORARY VARIABLES - USED TO AVOID OVERRIDING MORE OPEN ZEPPELING FUNCTIONS
  uint256 private changeDue;
  bool private capReached;

  enum Stages{
    SETUP,
    READY,
    BONUSSALE,
    MAINSALE,
    FINALIZED
  }

  /**
      MODIFIERS
  **/

  /**
    @dev Garantee that contract has the desired satge
  **/
  modifier atStage(Stages _currentStage){
      require(currentStage == _currentStage);
      _;
  }

  /**
    @dev Execute automatically transitions between different Stages
    based on time only
  **/
  modifier timedTransition(){
    if(currentStage == Stages.READY && now >= bonussale_StartDate){
      currentStage = Stages.BONUSSALE;
    }
    if(currentStage == Stages.BONUSSALE && now > bonussale_EndDate){
      finalizePresale();
    }
    if(currentStage == Stages.MAINSALE && now > mainSale_EndDate){
      finalizeSale();
    }
    _;
  }


  /**
      CONSTRUCTOR
  **/

  /**
    @param _rate The exchange rate(multiplied by 1000) of tokens to eth(1 token = rate * ETH)
    @param _wallet The address that recieves _forwardFunds
    @param _token A token contract. Will be overriden later(needed fot OZ constructor)
  **/
  constructor(uint256 _rate, address _wallet, ERC20 _token) public Crowdsale(_rate,_wallet,_token) {
    require(_rate == 15);
    currentStage = Stages.SETUP;
  }


  /**
      SETUP RELATED FUNCTIONS
  **/

  /**
   * @dev Sets the initial date and token.
   * @param initialDate A timestamp representing the start of the bonussale
    @param tokenAddress  The address of the deployed SolidToken
   */
  function setupSale(uint256 initialDate, address tokenAddress) onlyOwner atStage(Stages.SETUP) public {
    bonussale_StartDate = initialDate;
    bonussale_EndDate = bonussale_StartDate + BONUSSALE_MAX_DURATION;
    token = ERC20(tokenAddress);

    require(SolidToken(tokenAddress).totalSupply() == 0, "Tokens have already been distributed");
    require(SolidToken(tokenAddress).owner() == address(this), "Token has the wrong ownership");

    currentStage = Stages.READY;
  }


  /**
      STAGE RELATED FUNCTIONS
  **/

  /**
   * @dev Returns de ETH cap of the current currentStage
   * @return uint256 representing the cap
   */
  function getCurrentCap() public view returns(uint256 cap){
    cap = bonussale_Cap;
    if(currentStage == Stages.MAINSALE){
      cap = mainSale_Cap;
    }
  }

  /**
   * @dev Returns de ETH cap of the current currentStage
   * @return uint256 representing the raised amount in the stage
   */
  function getRaisedForCurrentStage() public view returns(uint256 raised){
    raised = bonussale_WeiRaised;
    if(currentStage == Stages.MAINSALE)
      raised = mainSale_WeiRaised;
  }

  /**
   * @dev Returns the sale status.
   * @return True if open, false if closed
   */
  function saleOpen() public timedTransition whenNotPaused returns(bool open) {
    open = ((now >= bonussale_StartDate && now < bonussale_EndDate) ||
           (now >= mainSale_StartDate && now <   mainSale_EndDate)) &&
           (currentStage == Stages.BONUSSALE || currentStage == Stages.MAINSALE);
  }



  /**
    FINALIZATION RELATES FUNCTIONS
  **/

  /**
   * @dev Checks and distribute the remaining tokens. Finish minting afterwards
   * @return uint256 representing the cap
   */
  function distributeTokens() public onlyOwner atStage(Stages.FINALIZED) {
    require(!distributed);
    distributed = true;

    uint256 totalTokens = (bonussale_TokesSold.add(mainSale_TokesSold)).mul(HUNDRED_PERCENT).div(TOKENS_ON_SALE_PERCENT); //sold token will represent 60% of all tokens
    for(uint i = 0; i < partners.length; i++){
      uint256 amount = percentages[partners[i]].mul(totalTokens).div(HUNDRED_PERCENT);
      _deliverTokens(partners[i], amount);
    }
    for(uint j = 0; j < partnerFixedAmount.length; j++){
      _deliverTokens(partnerFixedAmount[j], fixedAmounts[partnerFixedAmount[j]]);
    }
    require(SolidToken(token).finishMinting());
  }

  /**
   * @dev Finalizes the bonussale and sets up the break and public sales
   *
   */
  function finalizePresale() atStage(Stages.BONUSSALE) internal{
    bonussale_EndDate = now;
    mainSale_StartDate = now;
    mainSale_EndDate = mainSale_StartDate + MAINSALE_MAX_DURATION;
    mainSale_TokenCap = mainSale_TokenCap.add(bonussale_TokenCap.sub(bonussale_TokesSold));
    mainSale_Cap = mainSale_Cap.add(bonussale_Cap.sub(weiRaised.sub(changeDue)));
    currentStage = Stages.MAINSALE;
  }

  /**
   * @dev Finalizes the public sale
   *
   */
  function finalizeSale() atStage(Stages.MAINSALE) internal {
    mainSale_EndDate = now;
    require(SolidToken(token).setTransferEnablingDate(now + TOKEN_RELEASE_DELAY));
    currentStage = Stages.FINALIZED;
  }

  /**
      OPEN ZEPPELIN OVERRIDES
  **/

  /**
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) isWhitelisted(_beneficiary) internal {
    require(_beneficiary == msg.sender);
    require(saleOpen(), "Sale is Closed");

    // Check for edge cases
    uint256 acceptedValue = _weiAmount;
    uint256 currentCap = getCurrentCap();
    uint256 raised = getRaisedForCurrentStage();

    if(contributions[_beneficiary].add(acceptedValue) > MAXIMUM_CONTRIBUTION){
      changeDue = (contributions[_beneficiary].add(acceptedValue)).sub(MAXIMUM_CONTRIBUTION);
      acceptedValue = acceptedValue.sub(changeDue);
    }

    if(raised.add(acceptedValue) >= currentCap){
      changeDue = changeDue.add(raised.add(acceptedValue).sub(currentCap));
      acceptedValue = _weiAmount.sub(changeDue);
      capReached = true;
    }
    require(capReached || contributions[_beneficiary].add(acceptedValue) >= MINIMUM_CONTRIBUTION ,"Contribution below minimum");
  }

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256 amount) {
    amount = (_weiAmount.sub(changeDue)).mul(HUNDRED_PERCENT).div(rate); // Multiplication to account for the decimal cases in the rate
    if(currentStage == Stages.BONUSSALE){
      amount = amount.add(amount.mul(BONUS_PERCENT).div(HUNDRED_PERCENT)); //Add bonus
    }
  }

  /**
   * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid conditions are not met.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    if(currentStage == Stages.MAINSALE && capReached) finalizeSale();
    if(currentStage == Stages.BONUSSALE && capReached) finalizePresale();


    //Cleanup temp
    changeDue = 0;
    capReached = false;

  }

  /**
   * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
   * @param _beneficiary Address receiving the tokens
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
    uint256 tokenAmount = _getTokenAmount(_weiAmount);

    if(currentStage == Stages.BONUSSALE){
      bonussale_TokesSold = bonussale_TokesSold.add(tokenAmount);
      bonussale_WeiRaised = bonussale_WeiRaised.add(_weiAmount.sub(changeDue));
    } else {
      mainSale_TokesSold = mainSale_TokesSold.add(tokenAmount);
      mainSale_WeiRaised = mainSale_WeiRaised.add(_weiAmount.sub(changeDue));
    }

    contributions[_beneficiary] = contributions[_beneficiary].add(_weiAmount).sub(changeDue);
    weiRaised = weiRaised.sub(changeDue);
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds() internal {
    wallet.transfer(msg.value.sub(changeDue));
    msg.sender.transfer(changeDue); //Transfer change to _beneficiary
  }

}