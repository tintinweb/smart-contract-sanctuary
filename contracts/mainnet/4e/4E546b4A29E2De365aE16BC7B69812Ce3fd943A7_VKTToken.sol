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

contract VKTToken is StandardToken, Ownable {

  string public name = &#39;VKTToken&#39;;
  string public symbol = &#39;VKT&#39;;
  uint8 public decimals = 18;



  // address where funds are collected
  address public wallet;

  // how many token units a buyer gets per ether
  uint256 public rate;

  // amount of raised money in wei
  uint256 public weiRaised;

  // locked token balance each address
  mapping(address => uint256) lockedBalances;

  // address is locked:true, can&#39;t transfer token
  mapping (address => bool) public lockedAccounts;

  // token cap
  uint256 public tokenCap = 1 * 10 ** 27;

    /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  

  /**
   * event for rate update logging
   * @param preRate previouse rate per ether
   * @param newRate new rate per ether
   */
  event RateUpdated(uint256 preRate, uint256 newRate);


  /**
   * event for wallet update logging
   * @param preWallet previouse wallet that collect fund
   * @param newWallet new wallet collect fund
   */
  event WalletUpdated(address indexed preWallet, address indexed newWallet);


  /**
   * event for lock account logging
   * @param target affected account
   * @param lock true:account is locked. false: unlocked
   */
  event LockAccount(address indexed target, bool lock);

  event Mint(address indexed to, uint256 amount);

  event MintWithLocked(address indexed to, uint256 amount, uint256 lockedAmount);

  event ReleaseLockedBalance(address indexed to, uint256 amount);


  function VKTToken(uint256 _rate, address _wallet) public {
    require(_rate > 0);
    require(_wallet != address(0));

    rate = _rate;
    wallet = _wallet;
  }


  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner public returns (bool) {
    require(_to != address(0));
    require(totalSupply_.add(_amount) <= tokenCap);

    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }


  /**
   * @dev Function to mint tokens with some locked
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @param _lockedAmount The amount of tokens locked.
   * @return A boolean that indicates if the operation was successful.
   */
  function mintWithLocked(address _to, uint256 _amount, uint256 _lockedAmount) onlyOwner public returns (bool) {
    require(_to != address(0));
    require(totalSupply_.add(_amount) <= tokenCap);
    require(_amount >= _lockedAmount);

    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    lockedBalances[_to] = lockedBalances[_to].add(_lockedAmount);
    MintWithLocked(_to, _amount, _lockedAmount);
    return true;
  }

  /**
   * @dev Function to release some locked tokens
   * @param _to The address that tokens will be released.
   * @param _amount The amount of tokens to release.
   * @return A boolean that indicates if the operation was successful.
   */
  function releaseLockedBalance(address _to, uint256 _amount) onlyOwner public returns (bool) {
    require(_to != address(0));
    require(_amount <= lockedBalances[_to]);

    lockedBalances[_to] = lockedBalances[_to].sub(_amount);
    ReleaseLockedBalance(_to, _amount);
    return true;
  }

    /**
  * @dev Gets the balance of locked the specified address.
  * @param _owner The address to query the the balance of locked.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOfLocked(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }


    /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(!lockedAccounts[msg.sender]);
    require(_value <= balances[msg.sender].sub(lockedBalances[msg.sender]));
    return super.transfer(_to, _value);
  }


    /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(!lockedAccounts[_from]);
    require(_value <= balances[_from].sub(lockedBalances[_from]));
    return super.transferFrom(_from, _to, _value);
  }

    /**
   * @dev lock or unlock for one address to transfer tokens
   * @param target affected address
   * @param lock true: set target locked, fasle:unlock

   */
  function lockAccount(address target, bool lock) onlyOwner public returns (bool) {
    require(target != address(0));
    lockedAccounts[target] = lock;
    LockAccount(target, lock);
    return true;
  }

    // fallback function can be used to buy tokens
  function () external payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(msg.value != 0);

    uint256 weiAmount = msg.value;

    // calculate token amount to be created
    uint256 tokens = getTokenAmount(weiAmount);

    if (msg.value >= 50 * 10 ** 18 && msg.value < 100 * 10 ** 18) {
      tokens = tokens.mul(100).div(95);
    }

    if (msg.value >= 100 * 10 ** 18) {
      tokens = tokens.mul(10).div(9);
    }


    require(totalSupply_.add(tokens) <= tokenCap);

    // update state
    weiRaised = weiRaised.add(weiAmount);
    totalSupply_ = totalSupply_.add(tokens);
    balances[beneficiary] = balances[beneficiary].add(tokens);
    Mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

  // Override this method to have a way to add business logic to your crowdsale when buying
  function getTokenAmount(uint256 weiAmount) internal view returns(uint256) {
    return weiAmount.mul(rate);
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }


    /**
   * @dev update token mint rate per eth
   * @param _rate token rate per eth
   */
  function updateRate(uint256 _rate) onlyOwner public returns (bool) {
    require(_rate != 0);

    RateUpdated(rate, _rate);
    rate = _rate;
    return true;
  }


    /**
   * @dev update wallet
   * @param _wallet wallet that collect fund
   */
  function updateWallet(address _wallet) onlyOwner public returns (bool) {
    require(_wallet != address(0));
    
    WalletUpdated(wallet, _wallet);
    wallet = _wallet;
    return true;
  }
}