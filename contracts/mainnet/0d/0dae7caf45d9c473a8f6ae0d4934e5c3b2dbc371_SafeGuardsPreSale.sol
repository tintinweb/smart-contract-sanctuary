pragma solidity ^0.4.22;

// File: contracts/ERC223/ERC223_receiving_contract.sol

/**
* @title Contract that will work with ERC223 tokens.
*/

contract ERC223ReceivingContract {
    /**
     * @dev Standard ERC223 function that will handle incoming token transfers.
     *
     * @param _from  Token sender address.
     * @param _value Amount of tokens.
     * @param _data  Transaction metadata.
     */
    function tokenFallback(address _from, uint _value, bytes _data) public;
}

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
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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
    emit Transfer(msg.sender, _to, _value);
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

// File: zeppelin-solidity/contracts/token/ERC20/CappedToken.sol

/**
 * @title Capped token
 * @dev Mintable token with a token cap.
 */
contract CappedToken is MintableToken {

  uint256 public cap;

  constructor(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    require(totalSupply_.add(_amount) <= cap);

    return super.mint(_to, _amount);
  }

}

// File: contracts/SafeGuardsToken.sol

contract SafeGuardsToken is CappedToken {

    string constant public name = "SafeGuards Coin";
    string constant public symbol = "SGCT";
    uint constant public decimals = 18;

    // address who can burn tokens
    address public canBurnAddress;

    // list with frozen addresses
    mapping (address => bool) public frozenList;

    // timestamp until investors in frozen list can&#39;t transfer tokens
    uint256 public frozenPauseTime = now + 180 days;

    // timestamp until investors can&#39;t burn tokens
    uint256 public burnPausedTime = now + 180 days;


    constructor(address _canBurnAddress) CappedToken(61 * 1e6 * 1e18) public {
        require(_canBurnAddress != 0x0);
        canBurnAddress = _canBurnAddress;
    }


    // ===--- Presale frozen functionality ---===

    event ChangeFrozenPause(uint256 newFrozenPauseTime);

    /**
     * @dev Function to mint frozen tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mintFrozen(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        frozenList[_to] = true;
        return super.mint(_to, _amount);
    }

    function changeFrozenTime(uint256 _newFrozenPauseTime) onlyOwner public returns (bool) {
        require(_newFrozenPauseTime > now);

        frozenPauseTime = _newFrozenPauseTime;
        emit ChangeFrozenPause(_newFrozenPauseTime);
        return true;
    }


    // ===--- Override transfers with implementation of the ERC223 standard and frozen logic ---===

    event Transfer(address indexed from, address indexed to, uint value, bytes data);

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint _value) public returns (bool) {
        bytes memory empty;
        return transfer(_to, _value, empty);
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    * @param _data Optional metadata.
    */
    function transfer(address _to, uint _value, bytes _data) public returns (bool) {
        require(now > frozenPauseTime || !frozenList[msg.sender]);

        super.transfer(_to, _value);

        if (isContract(_to)) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
            emit Transfer(msg.sender, _to, _value, _data);
        }

        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        bytes memory empty;
        return transferFrom(_from, _to, _value, empty);
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint the amount of tokens to be transferred
     * @param _data Optional metadata.
     */
    function transferFrom(address _from, address _to, uint _value, bytes _data) public returns (bool) {
        require(now > frozenPauseTime || !frozenList[msg.sender]);

        super.transferFrom(_from, _to, _value);

        if (isContract(_to)) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(_from, _value, _data);
        }

        emit Transfer(_from, _to, _value, _data);
        return true;
    }

    function isContract(address _addr) private view returns (bool) {
        uint length;
        assembly {
        //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return (length>0);
    }


    // ===--- Burnable functionality ---===

    event Burn(address indexed burner, uint256 value);
    event ChangeBurnPause(uint256 newBurnPauseTime);

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public {
        require(burnPausedTime < now || msg.sender == canBurnAddress);

        require(_value <= balances[msg.sender]);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(burner, _value);
        emit Transfer(burner, address(0), _value);
    }

    function changeBurnPausedTime(uint256 _newBurnPauseTime) onlyOwner public returns (bool) {
        require(_newBurnPauseTime > burnPausedTime);

        burnPausedTime = _newBurnPauseTime;
        emit ChangeBurnPause(_newBurnPauseTime);
        return true;
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
    emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

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
  constructor(uint256 _openingTime, uint256 _closingTime) public {
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

// File: zeppelin-solidity/contracts/crowdsale/validation/CappedCrowdsale.sol

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
  constructor(uint256 _cap) public {
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

// File: contracts/SafeGuardsPreSale.sol

contract SafeGuardsPreSale is FinalizableCrowdsale, CappedCrowdsale {
    using SafeMath for uint256;

    // amount of tokens that was sold on the crowdsale
    uint256 public tokensSold;

    // if minimumGoal will not be reached till _closingTime, buyers will be able to refund ETH
    uint256 public minimumGoal;

    // how much wei we have returned back to the contract after a failed crowdfund
    uint public loadedRefund;

    // how much wei we have given back to buyers
    uint public weiRefunded;

    // how much ETH each address has bought to this crowdsale
    mapping (address => uint) public boughtAmountOf;

    // minimum amount of wel, that can be contributed
    uint256 constant public minimumAmountWei = 1e16;

    // timestamp until presale investors can&#39;t transfer tokens
    uint256 public presaleTransfersPaused = now + 180 days;

    // timestamp until investors can&#39;t burn tokens
    uint256 public presaleBurnPaused = now + 180 days;

    // ---====== BONUSES for presale users ======---

    // time presale bonuses
    uint constant public preSaleBonus1Time = 1535155200; // 
    uint constant public preSaleBonus1Percent = 25;
    uint constant public preSaleBonus2Time = 1536019200; // 
    uint constant public preSaleBonus2Percent = 15;
    uint constant public preSaleBonus3Time = 1536883200; // 
    uint constant public preSaleBonus3Percent = 5;

    // amount presale bonuses
    uint constant public preSaleBonus1Amount = 155   * 1e15;
    uint constant public preSaleBonus2Amount = 387   * 1e15;
    uint constant public preSaleBonus3Amount = 1550  * 1e15;
    uint constant public preSaleBonus4Amount = 15500 * 1e15;

    // ---=== Addresses of founders, team and bounty ===---
    address constant public w_futureDevelopment = 0x4b297AB09bF4d2d8107fAa03cFF5377638Ec6C83;
    address constant public w_Reserv = 0xbb67c6E089c7801ab3c7790158868970ea0d8a7C;
    address constant public w_Founders = 0xa3b331037e29540F8BD30f3DE4fF4045a8115ff4;
    address constant public w_Team = 0xa8324689c94eC3cbE9413C61b00E86A96978b4A7;
    address constant public w_Advisers = 0x2516998954440b027171Ecb955A4C01DfF610F2d;
    address constant public w_Bounty = 0x1792b603F233220e1E623a6ab3FEc68deFa15f2F;


    event AddBonus(address indexed addr, uint256 amountWei, uint256 date, uint bonusType);

    struct Bonus {
        address addr;
        uint256 amountWei;
        uint256 date;
        uint bonusType;
    }

    struct Bonuses {
        address addr;
        uint256 numBonusesInAddress;
        uint256[] indexes;
    }

    /**
     * @dev Get all bonuses by account address
     */
    mapping(address => Bonuses) public bonuses;

    /**
     * @dev Bonuses list
     */
    Bonus[] public bonusList;

    /**
     * @dev Count of bonuses in list
     */
    function numBonuses() public view returns (uint256)
    { return bonusList.length; }

    /**
     * @dev Count of members in archive
     */
    function getBonusByAddressAndIndex(address _addr, uint256 _index) public view returns (uint256)
    { return bonuses[_addr].indexes[_index]; }


    /**
     * @param _rate Number of token units a buyer gets per one ETH
     * @param _wallet Address where collected funds will be forwarded to
     * @param _token Address of the token being sold
     * @param _openingTime Crowdsale opening time
     * @param _closingTime Crowdsale closing time
     * @param _minimumGoal Funding goal (soft cap)
     * @param _cap Max amount of ETH to be contributed (hard cap)
     */
    constructor(
        uint256 _rate,
        address _wallet,
        ERC20 _token,
        uint256 _openingTime,
        uint256 _closingTime,
        uint256 _minimumGoal,
        uint256 _cap
    )
    Crowdsale(_rate * 1 ether, _wallet, _token)
    TimedCrowdsale(_openingTime, _closingTime)
    CappedCrowdsale(_cap * 1 ether)
    public
    {
        require(_rate > 0);
        require(_wallet != address(0));

        rate = _rate;
        wallet = _wallet;

        minimumGoal = _minimumGoal * 1 ether;
    }

    /**
     * @dev Allows the current owner to transfer token&#39;s control to a newOwner.
     * @param _newTokenOwner The address to transfer token&#39;s ownership to.
     */
    function changeTokenOwner(address _newTokenOwner) external onlyOwner {
        require(_newTokenOwner != 0x0);
        require(hasClosed());

        SafeGuardsToken(token).transferOwnership(_newTokenOwner);
    }

    /**
   * @dev finalization task, called when owner calls finalize()
   */
    function finalization() internal {
        require(isMinimumGoalReached());

        SafeGuardsToken(token).mint(w_futureDevelopment, tokensSold.mul(20).div(43));
        SafeGuardsToken(token).mint(w_Reserv, tokensSold.mul(20).div(43));
        SafeGuardsToken(token).mint(w_Founders, tokensSold.mul(7).div(43));
        SafeGuardsToken(token).mint(w_Team, tokensSold.mul(5).div(43));
        SafeGuardsToken(token).mint(w_Advisers, tokensSold.mul(3).div(43));
        SafeGuardsToken(token).mint(w_Bounty, tokensSold.mul(2).div(43));

        super.finalization();
    }

    /**
   * @dev Validation of an incoming purchase.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
        require(_weiAmount >= minimumAmountWei);

        super._preValidatePurchase(_beneficiary, _weiAmount);
    }

    /**
     * @dev Overrides delivery by minting tokens upon purchase.
     * @param _beneficiary Token purchaser
     * @param _tokenAmount Number of tokens to be minted
     */
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        require(SafeGuardsToken(token).mintFrozen(_beneficiary, _tokenAmount));
        tokensSold = tokensSold.add(_tokenAmount);
    }

    function changeTransfersPaused(uint256 _newFrozenPauseTime) onlyOwner public returns (bool) {
        require(_newFrozenPauseTime > now);

        presaleTransfersPaused = _newFrozenPauseTime;
        SafeGuardsToken(token).changeFrozenTime(_newFrozenPauseTime);
        return true;
    }

    function changeBurnPaused(uint256 _newBurnPauseTime) onlyOwner public returns (bool) {
        require(_newBurnPauseTime > presaleBurnPaused);

        presaleBurnPaused = _newBurnPauseTime;
        SafeGuardsToken(token).changeBurnPausedTime(_newBurnPauseTime);
        return true;
    }


    // ===--- Bonuses functionality ---===

    /**
     * @dev add bonuses for users
     * @param _beneficiary Address receiving the tokens
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
        require(_weiAmount >= minimumAmountWei);

        boughtAmountOf[msg.sender] = boughtAmountOf[msg.sender].add(_weiAmount);

        if (_weiAmount >= preSaleBonus1Amount) {
            if (_weiAmount >= preSaleBonus2Amount) {
                if (_weiAmount >= preSaleBonus3Amount) {
                    if (_weiAmount >= preSaleBonus4Amount) {
                        addBonusToUser(msg.sender, _weiAmount, preSaleBonus4Amount, 4);
                    } else {
                        addBonusToUser(msg.sender, _weiAmount, preSaleBonus3Amount, 3);
                    }
                } else {
                    addBonusToUser(msg.sender, _weiAmount, preSaleBonus2Amount, 2);
                }
            } else {
                addBonusToUser(msg.sender, _weiAmount, preSaleBonus1Amount, 1);
            }
        }
    }

    function addBonusToUser(address _addr, uint256 _weiAmount, uint256 _bonusAmount, uint _bonusType) internal {
        uint256 countBonuses = _weiAmount.div(_bonusAmount);

        Bonus memory b;
        b.addr = _addr;
        b.amountWei = _weiAmount;
        b.date = now;
        b.bonusType = _bonusType;

        for (uint256 i = 0; i < countBonuses; i++) {
            bonuses[_addr].addr = _addr;
            bonuses[_addr].numBonusesInAddress++;
            bonuses[_addr].indexes.push(bonusList.push(b) - 1);

            emit AddBonus(_addr, _weiAmount, now, _bonusType);
        }
    }

    /**
   * @dev Returns the rate of tokens per wei at the present time.
   * Note that, as price _increases_ with time, the rate _decreases_.
   * @return The number of tokens a buyer gets per wei at a given time
   */
    function getCurrentRate() public view returns (uint256) {
        if (now > preSaleBonus3Time) {
            return rate;
        }

        if (now < preSaleBonus1Time) {
            return rate.add(rate.mul(preSaleBonus1Percent).div(100));
        }

        if (now < preSaleBonus2Time) {
            return rate.add(rate.mul(preSaleBonus2Percent).div(100));
        }

        if (now < preSaleBonus3Time) {
            return rate.add(rate.mul(preSaleBonus3Percent).div(100));
        }

        return rate;
    }

    /**
     * @dev Overrides parent method taking into account variable rate.
     * @param _weiAmount The value in wei to be converted into tokens
     * @return The number of tokens _weiAmount wei will buy at present time
     */
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        uint256 currentRate = getCurrentRate();
        return currentRate.mul(_weiAmount);
    }


    // ===--- Refund functionality ---===

    // a refund was processed for an buyer
    event Refund(address buyer, uint weiAmount);
    event RefundLoaded(uint amount);

    // return true if the crowdsale has raised enough money to be a successful.
    function isMinimumGoalReached() public constant returns (bool) {
        return weiRaised >= minimumGoal;
    }

    /**
    * Allow load refunds back on the contract for the refunding.
    *
    * The team can transfer the funds back on the smart contract in the case the minimum goal was not reached.
    */
    function loadRefund() external payable {
        require(msg.sender == wallet);
        require(msg.value > 0);
        require(!isMinimumGoalReached());

        loadedRefund = loadedRefund.add(msg.value);

        emit RefundLoaded(msg.value);
    }

    /**
    * Buyers can claim refund.
    *
    * Note that any refunds from proxy buyers should be handled separately,
    * and not through this contract.
    */
    function refund() external {
        require(!isMinimumGoalReached() && loadedRefund > 0);

        uint weiValue = boughtAmountOf[msg.sender];
        require(weiValue > 0);
        require(weiValue <= loadedRefund);

        boughtAmountOf[msg.sender] = 0;
        weiRefunded = weiRefunded.add(weiValue);
        msg.sender.transfer(weiValue);

        emit Refund(msg.sender, weiValue);
    }
}