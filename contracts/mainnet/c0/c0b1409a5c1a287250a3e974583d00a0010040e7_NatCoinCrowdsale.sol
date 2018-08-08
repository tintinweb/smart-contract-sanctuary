pragma solidity ^0.4.11;

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
/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
  uint256 _totalSupply;
  function totalSupply() constant returns (uint256 totalSupply);
  function balanceOf(address _owner) constant returns (uint balance);
  function transfer(address _to, uint _value) returns (bool success);
  function transferFrom(address _from, address _to, uint _value) returns (bool success);
  function approve(address _spender, uint _value) returns (bool success);
  function allowance(address _owner, address _spender) constant returns (uint remaining);
  event Transfer(address indexed _from, address indexed _to, uint _value);
  event Approval(address indexed _owner, address indexed _spender, uint _value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20 {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  // Owner of account approves the transfer of an amount to another account
  mapping(address => mapping (address => uint256)) allowed;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) returns (bool success) {
    if (balances[msg.sender] >= _value
    && _value > 0
    && balances[_to] + _value > balances[_to]) {
      balances[msg.sender] -= _value;
      balances[_to] += _value;
      Transfer(msg.sender, _to, _value);
      return true;
    } else {
      return false;
    }
  }

  // Send _value amount of tokens from address _from to address _to
  // The transferFrom method is used for a withdraw workflow, allowing contracts to send
  // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
  // fees in sub-currencies; the command should fail unless the _from account has
  // deliberately authorized the sender of the message via some mechanism; we propose
  // these standardized APIs for approval:
  function transferFrom(address _from,address _to, uint256 _amount) returns (bool success) {
    if (balances[_from] >= _amount
    && allowed[_from][msg.sender] >= _amount
    && _amount > 0
    && balances[_to] + _amount > balances[_to]) {
      balances[_from] -= _amount;
      allowed[_from][msg.sender] -= _amount;
      balances[_to] += _amount;
      return true;
    } else {
      return false;
    }
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

  function totalSupply() constant returns (uint256 totalSupply) {
    totalSupply = _totalSupply;
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

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
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
  // Functions with this modifier can only be executed by the owner

  modifier onlyOwner() {
    if (msg.sender != owner) {
      revert();
    }
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
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
   * @param _to The address that will recieve the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    _totalSupply = _totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
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

contract NatCoin is MintableToken {
  string public constant name = "NATCOIN";
  string public constant symbol = "NTC";
  uint256 public constant decimals = 18;
}

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end block, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract Crowdsale {
  using SafeMath for uint256;

  // The token being sold
  MintableToken public token;

  // start and end block where investments are allowed (both inclusive)
  uint256 public startBlock;
  uint256 public endBlock;

  // address where funds are collected
  address public wallet;

  // how many token units a buyer gets per wei
  uint256 public rate;

  // amount of raised money in wei
  uint256 public weiRaised;

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(uint256 _startBlock, uint256 _endBlock, uint256 _rate, address _wallet) {
    require(_startBlock >= block.number);
    require(_endBlock >= _startBlock);
    require(_rate > 0);
    require(_wallet != 0x0);

    token = createTokenContract();
    startBlock = _startBlock;
    endBlock = _endBlock;
    rate = _rate;
    wallet = _wallet;
  }

  // creates the token to be sold.
  // override this method to have crowdsale of a specific mintable token.
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }


  // fallback function can be used to buy tokens
  function () payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;

    // calculate token amount to be created
    uint256 tokens = weiAmount.mul(rate);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal constant returns (bool) {
    uint256 current = block.number;
    bool withinPeriod = current >= startBlock && current <= endBlock;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

  // @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
    return block.number > endBlock;
  }


}


contract NatCoinCrowdsale is Crowdsale, Ownable {

  uint256 public icoSupply;
  uint256 public reserveSupply;
  uint256 public paymentSupply;
  uint256 public coreSupply;
  uint256 public reveralSupply;

  uint256 public usedIcoSupply;
  uint256 public usedReserveSupply;
  uint256 public usedPaymentSupply;
  uint256 public usedCoreSupply;
  uint256 public usedReveralSupply;

  function getIcoSupply() public returns(uint256) { return icoSupply; }
  function getReserveSupply() public returns(uint256) { return reserveSupply; }
  function getPaymentSupply() public returns(uint256) { return paymentSupply; }
  function getCoreSupply() public returns(uint256) { return coreSupply; }
  function getReveralSupply() public returns(uint256) { return reveralSupply; }

  function getUsedReserveSupply() public returns(uint256) { return usedReserveSupply; }
  function getUsedPaymentSupply() public returns(uint256) { return usedPaymentSupply; }
  function getUsedCoreSupply() public returns(uint256) { return usedCoreSupply; }
  function getUsedReveralSupply() public returns(uint256) { return usedReveralSupply; }

  NatCoin natcoinTokenContract;

  function NatCoinCrowdsale(uint256 _startBlock, uint256 _endBlock, uint256 _rate, address _wallet) Crowdsale(_startBlock, _endBlock, _rate, _wallet) {
    icoSupply =      5000000 * 10**17;
    reserveSupply =  8000000 * 10**17;
    paymentSupply = 11000000 * 10**17;
    coreSupply =    10500000 * 10**17;
    reveralSupply =   500000 * 10**17;
  }

  // creates the token to be sold.
  // override this method to have crowdsale of a specific MintableToken token.
  function createTokenContract() internal returns (MintableToken) {
    return new NatCoin();
  }

  function claimReservedTokens(address _to, uint256 _amount) payable onlyOwner {
    if (_amount > reserveSupply - usedReserveSupply) revert();
    token.mint(_to, _amount);
    reserveSupply += _amount;
  }

  function claimPaymentTokens(address _to, uint256 _amount) payable onlyOwner {
    if (_amount > paymentSupply - usedPaymentSupply) revert();
    token.mint(_to, _amount);
    paymentSupply += _amount;
  }

  function claimCoreTokens(address _to, uint256 _amount) payable onlyOwner {
    if (_amount > coreSupply - usedCoreSupply) revert();
    natcoinTokenContract.mint(_to, _amount);
    coreSupply += _amount;
  }

  function claimReveralTokens(address _to, uint256 _amount) payable onlyOwner {
    if (_amount > reveralSupply - usedReveralSupply) revert();
    natcoinTokenContract.mint(_to, _amount);
    reveralSupply += _amount;
  }

}