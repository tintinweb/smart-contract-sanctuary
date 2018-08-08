pragma solidity ^0.4.21;



/* ************************************************ */
/* ********** Zeppelin Solidity - v1.5.0 ********** */
/* ************************************************ */



/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
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
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() onlyPendingOwner public {
    OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}



/* *********************************** */
/* ********** Xmoneta Token ********** */
/* *********************************** */



/**
 * @title XmonetaToken
 * @author Xmoneta.com
 *
 * ERC20 Compatible token
 * Zeppelin Solidity - v1.5.0
 */

contract XmonetaToken is StandardToken, Claimable {

  /* ********** Token Predefined Information ********** */

  string public constant name = "Xmoneta Token";
  string public constant symbol = "XMN";
  uint256 public constant decimals = 18;

  /* ********** Defined Variables ********** */

  // Total tokens supply 1 000 000 000
  // For ethereum wallets we added decimals constant
  uint256 public constant INITIAL_SUPPLY = 1000000000 * (10 ** decimals);
  // Vault where tokens are stored
  address public vault = msg.sender;
  // Sales agent who has permissions to manipulate with tokens
  address public salesAgent;

  /* ********** Events ********** */

  event SalesAgentAppointed(address indexed previousSalesAgent, address indexed newSalesAgent);
  event SalesAgentRemoved(address indexed currentSalesAgent);
  event Burn(uint256 valueToBurn);

  /* ********** Functions ********** */

  // Contract constructor
  function XmonetaToken() public {
    owner = msg.sender;
    totalSupply = INITIAL_SUPPLY;
    balances[vault] = totalSupply;
  }

  // Appoint sales agent of token
  function setSalesAgent(address newSalesAgent) onlyOwner public {
    SalesAgentAppointed(salesAgent, newSalesAgent);
    salesAgent = newSalesAgent;
  }

  // Remove sales agent from token
  function removeSalesAgent() onlyOwner public {
    SalesAgentRemoved(salesAgent);
    salesAgent = address(0);
  }

  // Transfer tokens from vault to account if sales agent is correct
  function transferTokensFromVault(address fromAddress, address toAddress, uint256 tokensAmount) public {
    require(salesAgent == msg.sender);
    balances[vault] = balances[vault].sub(tokensAmount);
    balances[toAddress] = balances[toAddress].add(tokensAmount);
    Transfer(fromAddress, toAddress, tokensAmount);
  }

  // Allow the owner to burn a specific amount of tokens from the vault
  function burn(uint256 valueToBurn) onlyOwner public {
    require(valueToBurn > 0);
    balances[vault] = balances[vault].sub(valueToBurn);
    totalSupply = totalSupply.sub(valueToBurn);
    Burn(valueToBurn);
  }

}



/* ************************************** */
/* ************ Xmoneta Sale ************ */
/* ************************************** */



/**
 * @title XmonetaSale
 * @author Xmoneta.com
 *
 * Zeppelin Solidity - v1.5.0
 */

contract XmonetaSale {

  using SafeMath for uint256;

  /* ********** Defined Variables ********** */

  // The token being sold
  XmonetaToken public token;
  // Crowdsale start timestamp - 03/13/2018 at 12:00pm (UTC)
  uint256 public startTime = 1520942400;
  // Crowdsale end timestamp - 05/31/2018 at 12:00pm (UTC)
  uint256 public endTime = 1527768000;
  // Addresses where ETH are collected
  address public wallet1 = 0x36A3c000f8a3dC37FCD261D1844efAF851F81556;
  address public wallet2 = 0x8beDBE45Aa345938d70388E381E2B6199A15B3C3;
  // How many token per wei
  uint256 public rate = 20000;
  // Cap in ethers
  uint256 public cap = 8000 * 1 ether;
  // Amount of raised wei
  uint256 public weiRaised;

  // Round B start timestamp - 05/04/2018 at 12:00pm (UTC)
  uint256 public round_b_begin_date = 1522929600;
  // Round B start timestamp - 30/04/2018 at 12:00pm (UTC)
  uint256 public round_c_begin_date = 1525089600;

  /* ********** Events ********** */

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 weiAmount, uint256 tokens);

  /* ********** Functions ********** */

  // Contract constructor
  function XmonetaSale() public {
    token = XmonetaToken(0x99705A8B60d0fE21A4B8ee54DB361B3C573D18bb);
  }

  // Fallback function to buy tokens
  function () public payable {
    buyTokens(msg.sender);
  }

  // Bonus calculation for transaction
  function bonus_calculation() internal returns (uint256, uint256) {
    // Round A Standard bonus & Extra bonus
    uint256 bonusPercent = 30;
    uint256 extraBonusPercent = 50;

    if (now >= round_c_begin_date) {
      // Round C Standard bonus & Extra bonus
      bonusPercent = 10;
      extraBonusPercent = 30;
    } else if (now >= round_b_begin_date) {
      // Round B Standard bonus & Extra bonus
      bonusPercent = 20;
      extraBonusPercent = 40;
    }

    return (bonusPercent, extraBonusPercent);
  }

  // Token purchase function
  function buyTokens(address beneficiary) public payable {
    require(validPurchase());

    uint256 weiAmount = msg.value;

    // Send spare wei back if investor sent more that cap
    uint256 tempWeiRaised = weiRaised.add(weiAmount);
    if (tempWeiRaised > cap) {
      uint256 spareWeis = tempWeiRaised.sub(cap);
      weiAmount = weiAmount.sub(spareWeis);
      beneficiary.transfer(spareWeis);
    }

    // Define standard and extra bonus variables
    uint256 bonusPercent;
    uint256 extraBonusPercent;

    // Execute calculation
    (bonusPercent, extraBonusPercent) = bonus_calculation();

    // Accept extra bonus if beneficiary send more that 1 ETH
    if (weiAmount >= 1 ether) {
      bonusPercent = extraBonusPercent;
    }

    // Token calculations with bonus
    uint256 additionalPercentInWei = rate.div(100).mul(bonusPercent);
    uint256 rateWithPercents = rate.add(additionalPercentInWei);

    // Calculate token amount to be sold
    uint256 tokens = weiAmount.mul(rateWithPercents);

    // Update state
    weiRaised = weiRaised.add(weiAmount);

    // Tranfer tokens from vault
    token.transferTokensFromVault(msg.sender, beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds(weiAmount);
  }

  // Send wei to the fund collection wallets
  function forwardFunds(uint256 weiAmount) internal {
    uint256 value = weiAmount.div(2);

    // If buyer send amount of wei that can not be divided to 2 without float point, send all weis to first wallet
    if (value.mul(2) != weiAmount) {
      wallet1.transfer(weiAmount);
    } else {
      wallet1.transfer(value);
      wallet2.transfer(value);
    }
  }

  // Validate if the transaction can be success
  function validPurchase() internal constant returns (bool) {
    bool withinCap = weiRaised < cap;
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase && withinCap;
  }

  // Show if crowdsale has ended or no
  function hasEnded() public constant returns (bool) {
    return now > endTime || weiRaised >= cap;
  }

}