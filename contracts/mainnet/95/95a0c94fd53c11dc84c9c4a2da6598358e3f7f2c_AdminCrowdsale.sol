pragma solidity ^0.4.24;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

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
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
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
    Transfer(msg.sender, _to, _value);
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
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

contract StandardToken is ERC20, BurnableToken {

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


contract EVOAIToken is StandardToken {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor() public {
    name = "EVOAI";
    symbol = "EVOT";
    decimals = 18;
    totalSupply_ = 10000000000000000000000000;
    balances[msg.sender] = totalSupply_;
  }
}

library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an address access to this role
   */
  function add(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = true;
  }

  /**
   * @dev remove an address&#39; access to this role
   */
  function remove(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = false;
  }

  /**
   * @dev check if an address has this role
   * // reverts
   */
  function check(Role storage role, address addr)
    view
    internal
  {
    require(has(role, addr));
  }

  /**
   * @dev check if an address has this role
   * @return bool
   */
  function has(Role storage role, address addr)
    view
    internal
    returns (bool)
  {
    return role.bearer[addr];
  }
}

contract Crowdsale is Ownable {
  using SafeMath for uint256;

  // The token being sold
  EVOAIToken public token;

  address public walletForETH;

  // How many token units a buyer gets per wei.
  // The rate is the conversion between wei and the smallest and indivisible token unit.
  // So, if you are using a rate of 1 with a DetailedERC20 token with 3 decimals called TOK
  // 1 wei will give you 1 unit, or 0.001 TOK.
  uint256 public rate;

  // Amount of wei raised
  uint256 public weiRaised;
  uint256 public weiRaisedRound;
  uint256 public tokensRaisedRound;
  uint256 public unsoldTokens;

  bool public privateStage;
  bool public preICOStage;
  bool public icoRound1;
  bool public icoRound2;
  bool public icoRound3;
  bool public icoRound4;
  bool public icoRound5;
  bool public icoRound6;




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

  constructor(address _wallet, address _walletForETH) public {
    require(_wallet != address(0));
    require(_walletForETH != address(0));
    walletForETH = _walletForETH;

    token = new EVOAIToken();

    token.transfer(_wallet, 3200000000000000000000000);
    privateStage = true;
  }

  // -----------------------------------------
  // Crowdsale external interface
  // -----------------------------------------

  function changeWalletForETH(address _walletForETH) onlyOwner public {
     require(_walletForETH != address(0));
     walletForETH = _walletForETH;
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

    uint256 tokens = _getTokenAmount(weiAmount);

    if (privateStage) {
      require(tokensRaisedRound.add(tokens) < 300000000000000000000000);
      require (tokens >= 5000000000000000000000 && tokens <= 25000000000000000000000);
      tokensRaisedRound = tokensRaisedRound.add(tokens);
         } 
    
    else if (preICOStage) {
            require(tokensRaisedRound.add(tokens) < 500000000000000000000000);
            tokensRaisedRound = tokensRaisedRound.add(tokens);
         }  
    
    else if (icoRound1) {
            require (tokensRaisedRound.add(tokens) < 1000000000000000000000000);
            tokensRaisedRound = tokensRaisedRound.add(tokens);
         }  
     
    else if (icoRound2) {
            require (tokensRaisedRound.add(tokens) < 1000000000000000000000000);
            tokensRaisedRound = tokensRaisedRound.add(tokens);
         } 
    
    else if (icoRound3) {
            require (tokensRaisedRound.add(tokens) < 1000000000000000000000000);
            tokensRaisedRound = tokensRaisedRound.add(tokens);
         } 

    else if (icoRound4) {
            require (tokensRaisedRound.add(tokens) < 1000000000000000000000000);
            tokensRaisedRound = tokensRaisedRound.add(tokens);
         } 
    else if (icoRound5) {
            require (tokensRaisedRound.add(tokens) < 1000000000000000000000000);
            tokensRaisedRound = tokensRaisedRound.add(tokens);
         } 
    else if (icoRound6) {
            require (tokensRaisedRound.add(tokens) < 1000000000000000000000000);
            tokensRaisedRound = tokensRaisedRound.add(tokens);
         }

    // update state
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );

    _forwardFunds();
  }


  function burnUnsoldTokens() onlyOwner public {

    require (unsoldTokens > 0);
    
    token.burn(unsoldTokens);
    unsoldTokens = 0;
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

    if (privateStage && weiRaisedRound.add(_weiAmount) <= 276000000000000000000) {
            rate = 1087;
            weiRaisedRound = weiRaisedRound.add(_weiAmount);
         } 
    
    else if (preICOStage && weiRaisedRound.add(_weiAmount) <= 775000000000000000000) {
            rate = 870;
            weiRaisedRound = weiRaisedRound.add(_weiAmount);
         }  
    
    else if (icoRound1 && weiRaisedRound.add(_weiAmount) <= 1380000000000000000000) {
            rate = 725;
            weiRaisedRound = weiRaisedRound.add(_weiAmount);
         }  
     
    else if (icoRound2 && weiRaisedRound.add(_weiAmount) <= 1610000000000000000000) {
            rate = 621;
            weiRaisedRound = weiRaisedRound.add(_weiAmount);
         } 
    
    else if (icoRound3 && weiRaisedRound.add(_weiAmount) <= 1840000000000000000000) {
            rate = 544;
            weiRaisedRound = weiRaisedRound.add(_weiAmount);
         } 

    else if (icoRound4 && weiRaisedRound.add(_weiAmount) <= 2070000000000000000000) {
            rate = 484;
            weiRaisedRound = weiRaisedRound.add(_weiAmount);
         } 
    else if (icoRound5 && weiRaisedRound.add(_weiAmount) <= 2300000000000000000000) {
            rate = 435;
            weiRaisedRound = weiRaisedRound.add(_weiAmount);
         } 
    else if (icoRound6 && weiRaisedRound.add(_weiAmount) <= 2530000000000000000000) {
            rate = 396;
            weiRaisedRound = weiRaisedRound.add(_weiAmount);
         }
  }

  function nextRound() onlyOwner public {
    if(privateStage){
       privateStage = false;
       preICOStage = true;
       weiRaisedRound = 0;
       unsoldTokens = unsoldTokens.add(276000000000000000000 - tokensRaisedRound);
       tokensRaisedRound = 0;

    } 
    else if(preICOStage){
            preICOStage = false;
            icoRound1 = true;
            weiRaisedRound = 0;
            unsoldTokens = unsoldTokens.add(775000000000000000000 - tokensRaisedRound);
            tokensRaisedRound = 0;
    }
    else if(icoRound1){
            icoRound1 = false;
            icoRound2 = true;
            weiRaisedRound = 0;
            unsoldTokens = unsoldTokens.add(1380000000000000000000 - tokensRaisedRound);
            tokensRaisedRound = 0;
    }
    else if(icoRound2){
            icoRound2 = false;
            icoRound3 = true;
            weiRaisedRound = 0;
            unsoldTokens = unsoldTokens.add(1610000000000000000000 - tokensRaisedRound);
            tokensRaisedRound = 0;
    }
    else if(icoRound3){
            icoRound3 = false;
            icoRound4 = true;
            weiRaisedRound = 0;
            unsoldTokens = unsoldTokens.add(1840000000000000000000 - tokensRaisedRound);
            tokensRaisedRound = 0;
    }
    else if(icoRound4){
            icoRound4 = false;
            icoRound5 = true;
            weiRaisedRound = 0;
            unsoldTokens = unsoldTokens.add(2070000000000000000000 - tokensRaisedRound);
            tokensRaisedRound = 0;
    }
    else if(icoRound5){
            icoRound5 = false;
            icoRound6 = true;
            weiRaisedRound = 0;
            unsoldTokens = unsoldTokens.add(2300000000000000000000 - tokensRaisedRound);
            tokensRaisedRound = 0;
    }
    else if(icoRound6){
            icoRound6 = false;
            unsoldTokens = unsoldTokens.add(2530000000000000000000 - tokensRaisedRound);
    }
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
    walletForETH.transfer(msg.value);
  }

}

contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

  constructor(address _wallet, address _walletForETH) public Crowdsale(_wallet, _walletForETH){
    cap = 12781000000000000000000;
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
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
    require(weiRaised.add(_weiAmount) <= cap);
  }

}

contract AdminCrowdsale is CappedCrowdsale {
  using SafeMath for uint256;

  bool public open;

  modifier onlyWhileOpen {

    require(open);
    _;
  }


  constructor(address _wallet, address _walletForETH) public CappedCrowdsale(_wallet, _walletForETH){
    //open will be false by default;
    open = false;
  }

  function endCrowdsale() onlyOwner public {
    open = false;
  }

  function startCrowdsale() onlyOwner public {
    // solium-disable-next-line security/no-block-members
    open = true;
  }

  /**
   * @dev Extend parent behavior requiring to be within contributing period
   * @param _beneficiary Token purchaser
   * @param _weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
    onlyWhileOpen
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}