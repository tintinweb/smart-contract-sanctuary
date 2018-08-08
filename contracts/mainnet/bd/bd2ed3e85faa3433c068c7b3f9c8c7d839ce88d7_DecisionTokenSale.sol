pragma solidity ^0.4.15;


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
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }

}


/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() onlyPendingOwner {
    owner = pendingOwner;
    pendingOwner = 0x0;
  }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) returns (bool) {
    require(_to != address(0));

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
  function balanceOf(address _owner) constant returns (uint256 balance) {
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

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    require(_to != address(0));

    var _allowance = allowed[_from][msg.sender];

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
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

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
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
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
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
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

/*
* Horizon State Decision Token Contract
*
* Version 0.9
*
* Author Nimo Naamani
*
* This smart contract code is Copyright 2017 Horizon State (https://Horizonstate.com)
*
* Licensed under the Apache License, version 2.0: http://www.apache.org/licenses/LICENSE-2.0
*
* @title Horizon State Token
* @dev ERC20 Decision Token (HST)
* @author Nimo Naamani
*
* HST tokens have 18 decimal places. The smallest meaningful (and transferable)
* unit is therefore 0.000000000000000001 HST. This unit is called a &#39;danni&#39;.
*
* 1 HST = 1 * 10**18 = 1000000000000000000 dannis.
*
* Maximum total HST supply is 1 Billion.
* This is equivalent to 1000000000 * 10**18 = 1e27 dannis.
*
* HST are mintable on demand (as they are being purchased), which means that
* 1 Billion is the maximum.
*/

// @title The Horizon State Decision Token (HST)
contract DecisionToken is MintableToken, Claimable {

  using SafeMath for uint256;

  // Name to appear in ERC20 wallets
  string public constant name = "Decision Token";

  // Symbol for the Decision Token to appear in ERC20 wallets
  string public constant symbol = "HST";

  // Version of the source contract
  string public constant version = "1.0";

  // Number of decimals for token display
  uint8 public constant decimals = 18;

  // Release timestamp. As part of the contract, tokens can only be transfered
  // 10 days after this trigger is set
  uint256 public triggerTime = 0;

  // @title modifier to allow actions only when the token can be released
  modifier onlyWhenReleased() {
    require(now >= triggerTime);
    _;
  }


  // @dev Constructor for the DecisionToken.
  // Initialise the trigger (the sale contract will init this to the expected end time)
  function DecisionToken() MintableToken() {
    owner = msg.sender;
  }

  // @title Transfer tokens.
  // @dev This contract overrides the transfer() function to only work when released
  function transfer(address _to, uint256 _value) onlyWhenReleased returns (bool) {
    return super.transfer(_to, _value);
  }

  // @title Allow transfers from
  // @dev This contract overrides the transferFrom() function to only work when released
  function transferFrom(address _from, address _to, uint256 _value) onlyWhenReleased returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  // @title finish minting of the token.
  // @dev This contract overrides the finishMinting function to trigger the token lock countdown
  function finishMinting() onlyOwner returns (bool) {
    require(triggerTime==0);
    triggerTime = now.add(10 days);
    return super.finishMinting();
  }
}

/**
* Horizon State Token Sale Contract
*
* Version 0.9
*
* @author Nimo Naamani
*
* This smart contract code is Copyright 2017 Horizon State (https://Horizonstate.com)
*
* Licensed under the Apache License, version 2.0: http://www.apache.org/licenses/LICENSE-2.0
*
*/

// @title The DC Token Sale contract
// @dev A crowdsale contract with stages of tokens-per-eth based on time elapsed
// Capped by maximum number of tokens; Time constrained
contract DecisionTokenSale is Claimable {
  using SafeMath for uint256;

  // Start timestamp where investments are open to the public.
  // Before this timestamp - only whitelisted addresses allowed to buy.
  uint256 public startTime;

  // End time. investments can only go up to this timestamp.
  // Note that the sale can end before that, if the token cap is reached.
  uint256 public endTime;

  // Presale (whitelist only) buyers receive this many tokens per ETH
  uint256 public constant presaleTokenRate = 3750;

  // 1st day buyers receive this many tokens per ETH
  uint256 public constant earlyBirdTokenRate = 3500;

  // Day 2-8 buyers receive this many tokens per ETH
  uint256 public constant secondStageTokenRate = 3250;

  // Day 9-16 buyers receive this many tokens per ETH
  uint256 public constant thirdStageTokenRate = 3000;

  // Maximum total number of tokens ever created, taking into account 18 decimals.
  uint256 public constant tokenCap =  10**9 * 10**18;

  // Initial HorizonState allocation (reserve), taking into account 18 decimals.
  uint256 public constant tokenReserve = 4 * (10**8) * 10**18;

  // The Decision Token that is sold with this token sale
  DecisionToken public token;

  // The address where the funds are kept
  address public wallet;

  // Holds the addresses that are whitelisted to participate in the presale.
  // Sales to these addresses are allowed before saleStart
  mapping (address => bool) whiteListedForPresale;

  // @title Event for token purchase logging
  event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);

  // @title Event to log user added to whitelist
  event LogUserAddedToWhiteList(address indexed user);

  //@title Event to log user removed from whitelist
  event LogUserUserRemovedFromWhiteList(address indexed user);


  // @title Constructor
  // @param _startTime: A timestamp for when the sale is to start.
  // @param _wallet - The wallet where the token sale proceeds are to be stored
  function DecisionTokenSale(uint256 _startTime, address _wallet) {
    require(_startTime >= now);
    require(_wallet != 0x0);
    startTime = _startTime;
    endTime = startTime.add(14 days);
    wallet = _wallet;

    // Create the token contract itself.
    token = createTokenContract();

    // Mint the reserve tokens to the owner of the sale contract.
    token.mint(owner, tokenReserve);
  }

  // @title Create the token contract from this sale
  // @dev Creates the contract for token to be sold.
  function createTokenContract() internal returns (DecisionToken) {
    return new DecisionToken();
  }

  // @title Buy Decision Tokens
  // @dev Use this function to buy tokens through the sale
  function buyTokens() payable {
    require(msg.sender != 0x0);
    require(msg.value != 0);
    require(whiteListedForPresale[msg.sender] || now >= startTime);
    require(!hasEnded());

    // Calculate token amount to be created
    uint256 tokens = calculateTokenAmount(msg.value);

    if (token.totalSupply().add(tokens) > tokenCap) {
      revert();
    }

    // Add the new tokens to the beneficiary
    token.mint(msg.sender, tokens);

    // Notify that a token purchase was performed
    TokenPurchase(msg.sender, msg.value, tokens);

    // Put the funds in the token sale wallet
    wallet.transfer(msg.value);
  }

  // @dev This is fallback function can be used to buy tokens
  function () payable {
    buyTokens();
  }

  // @title Calculate how many tokens per Ether
  // The token sale has different rates based on time of purchase, as per the token
  // sale whitepaper and Horizon State&#39;s Token Sale page.
  // Presale:  : 3750 tokens per Ether
  // Day 1     : 3500 tokens per Ether
  // Days 2-8  : 3250 tokens per Ether
  // Days 9-16 : 3000 tokens per Ether
  //
  // A note for calculation: As the number of decimals on the token is 18, which
  // is identical to the wei per eth - the calculation performed here can use the
  // number of tokens per ETH with no further modification.
  //
  // @param _weiAmount : How much wei the buyer wants to spend on tokens
  // @return the number of tokens for this purchase.
  function calculateTokenAmount(uint256 _weiAmount) internal constant returns (uint256) {
    if (now >= startTime + 8 days) {
      return _weiAmount.mul(thirdStageTokenRate);
    }
    if (now >= startTime + 1 days) {
      return _weiAmount.mul(secondStageTokenRate);
    }
    if (now >= startTime) {
      return _weiAmount.mul(earlyBirdTokenRate);
    }
    return _weiAmount.mul(presaleTokenRate);
  }

  // @title Check whether this sale has ended.
  // @dev This is a utility function to help consumers figure out whether the sale
  // has already ended.
  // The sale is considered done when the token&#39;s minting finished, or when the current
  // time has passed the sale&#39;s end time
  // @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
    return now > endTime;
  }

  // @title White list a buyer for the presale.
  // @dev Allow the owner of this contract to whitelist a buyer.
  // Whitelisted buyers may buy in the presale, i.e before the sale starts.
  // @param _buyer : The buyer address to whitelist
  function whiteListAddress(address _buyer) onlyOwner {
    require(_buyer != 0x0);
    whiteListedForPresale[_buyer] = true;
    LogUserAddedToWhiteList(_buyer);
  }

  // @title Whitelist an list of buyers for the presale
  // @dev Allow the owner of this contract to whitelist multiple buyers in batch.
  // Whitelisted buyers may buy in the presale, i.e before the sale starts.
  // @param _buyers : The buyer addresses to whitelist
  function addWhiteListedAddressesInBatch(address[] _buyers) onlyOwner {
    require(_buyers.length < 1000);
    for (uint i = 0; i < _buyers.length; i++) {
      whiteListAddress(_buyers[i]);
    }
  }

  // @title Remove a buyer from the whitelist.
  // @dev Allow the owner of this contract to remove a buyer from the white list.
  // @param _buyer : The buyer address to remove from the whitelist
  function removeWhiteListedAddress(address _buyer) onlyOwner {
    whiteListedForPresale[_buyer] = false;
  }

  // @title Terminate the contract
  // @dev Allow the owner of this contract to terminate it
  // It also transfers the token ownership to the owner of the sale contract.
  function destroy() onlyOwner {
    token.finishMinting();
    token.transferOwnership(msg.sender);
    selfdestruct(owner);
  }
}