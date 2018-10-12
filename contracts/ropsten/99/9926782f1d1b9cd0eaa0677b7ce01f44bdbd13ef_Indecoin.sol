pragma solidity ^0.4.13;
/**
 * (C) 2017 Indeco, Inc.
 * All rights reserved.
 */


/**
 * Indeco, Inc.
 * All rights reserved.
 * The Dividend contract is a bit what it sounds like: it allows payments to
 * be made to a contract and for them to be withdrawn. The trick of it is that
 * one can only withdraw the latest payment.
 */


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
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
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}
/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
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

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

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
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
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
 * @title PullPayment
 * @dev Base contract supporting async send for pull payments. Inherit from this
 * contract and use asyncSend instead of send.
 */
contract PullPayment {
  using SafeMath for uint256;

  mapping(address => uint256) public payments;
  uint256 public totalPayments;

  /**
  * @dev Called by the payer to store the sent amount as credit to be pulled.
  * @param dest The destination address of the funds.
  * @param amount The amount to transfer.
  */
  function asyncSend(address dest, uint256 amount) internal {
    payments[dest] = payments[dest].add(amount);
    totalPayments = totalPayments.add(amount);
  }

  /**
  * @dev withdraw accumulated balance, called by payee.
  */
  function withdrawPayments() public {
    address payee = msg.sender;
    uint256 payment = payments[payee];

    require(payment != 0);
    require(this.balance >= payment);

    totalPayments = totalPayments.sub(payment);
    payments[payee] = 0;

    assert(payee.send(payment));
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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


contract Dividend is Ownable, StandardToken {
  using SafeMath for uint256;

  uint constant pointMultiplier = 10e18;

  struct Dividends {
    uint balance;
    uint lastDividendPoints;
  }

  mapping(address=>Dividends) dividends;
  uint totalDividendPoints;
  uint public unclaimedDividends;


  event DebugInt(string message, uint value);
  event DebugAddress(string message, address value);
  event DividendDisbursed(address indexed payer, uint256 amount);
  event DividendCollected(address indexed recipient, uint256 amount);
  event DividendWithdrawn(address indexed recipient, uint256 amount);

  function dividendsOwing(address account) internal returns(uint) {
    if(account == owner) return 0;
    uint newDividendPoints = totalDividendPoints - dividends[account].lastDividendPoints;
    return (balances[account] * newDividendPoints) / pointMultiplier;
  }

  function collectsAccountDividends(address account) internal {
    uint owing = dividendsOwing(account);
    if(owing > 0) {
      unclaimedDividends -= owing;
      dividends[account].balance += owing;
      DividendCollected(account, owing);
    }
    dividends[account].lastDividendPoints = totalDividendPoints;
  }

  modifier collectsDividends() {
    address account = msg.sender;
    collectsAccountDividends(account);
    _;
  }

  function dividendBalance() collectsDividends returns (uint){
    return dividends[msg.sender].balance;
  }

  function disburse() payable onlyOwner {
    uint excluded = balances[owner];
    uint included = totalSupply - excluded;
    require(included > 0);
    totalDividendPoints += (msg.value * pointMultiplier / included);
    unclaimedDividends += msg.value;
    DividendDisbursed(msg.sender, msg.value);
  }

  /**
  * @dev Withdraw the dividend.
  *
  */
  function withdrawDividends() public {
    address payee = msg.sender;
    uint amount = dividendBalance();
    require(payee != owner);
    require(amount > 0);
    assert(payee.send(amount));
    dividends[payee].balance = 0;
    DividendWithdrawn(payee, amount);
  }

  function transfer(address _to, uint256 _value) public
    collectsDividends
    returns (bool)
  {
    collectsAccountDividends(_to);
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public
    returns (bool)
  {
    collectsAccountDividends(_from);
    collectsAccountDividends(_to);
    return super.transferFrom(_from, _to, _value);
  }

}




/**
 * @title Destructible
 * @dev Base contract that can be destroyed by owner. All funds in contract will be sent to the owner.
 */
contract Destructible is Ownable {

  function Destructible() payable { }

  /**
   * @dev Transfers the current balance to the owner and terminates the contract.
   */
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
  }
}


/**
 * @title Bounty
 * @dev This bounty will pay out to a researcher if they break invariant logic of the contract.
 */
contract Bounty is PullPayment, Destructible {
  bool public claimed;
  mapping(address => address) public researchers;

  event TargetCreated(address createdAddress);

  /**
   * @dev Fallback function allowing the contract to receive funds, if they haven&#39;t already been claimed.
   */
  function() payable {
    require(!claimed);
  }

  /**
   * @dev Create and deploy the target contract (extension of Target contract), and sets the
   * msg.sender as a researcher
   * @return A target contract
   */
  function createTarget() public returns(Target) {
    Target target = Target(deployContract());
    researchers[target] = msg.sender;
    TargetCreated(target);
    return target;
  }

  /**
   * @dev Internal function to deploy the target contract.
   * @return A target contract address
   */
  function deployContract() internal returns(address);

  /**
   * @dev Sends the contract funds to the researcher that proved the contract is broken.
   * @param target contract
   */
  function claim(Target target) public {
    address researcher = researchers[target];
    require(researcher != 0);
    // Check Target contract invariants
    require(!target.checkInvariant());
    asyncSend(researcher, this.balance);
    claimed = true;
  }

}


/**
 * @title Target
 * @dev Your main contract should inherit from this class and implement the checkInvariant method.
 */
contract Target {

   /**
    * @dev Checks all values a contract assumes to be true all the time. If this function returns
    * false, the contract is broken in some way and is in an inconsistent state.
    * In order to win the bounty, security researchers will try to cause this broken state.
    * @return True if all invariant values are correct, false otherwise.
    */
  function checkInvariant() public returns(bool);
}

contract Indecoin is Ownable, Target, StandardToken, Dividend {
    using SafeMath for uint256;

    /** public data from our other classes:
    *   address public owner;       // from Ownable
    *   uint256 public totalSupply; // from ERC20Basic
    */

    // Expected of ERC20
    string public constant name     = "IndecoinTestV0";
    string public constant symbol   = "INDE";
    uint8  public constant decimals = 18;

    bool public compromised; // In testing, true means the contract was breached


    function Indecoin () {
      compromised = false;
    }

    // Now we have the Bounty code, as the contract is Bounty.

    /**
     * @dev Function to check if the contract has been compromised.
     */

    function checkInvariant() returns(bool) {
      // Check the compromised flag.
      if (compromised == true) {
        return false;
      }
      return true;
    }

    /**
    * @dev Add tokens to an account, and increase total supply. Mostly for testing
    * @param _to The address of the recipient
    * @param _value The value to transfer
    */
    function mintTokens(address _to, uint256 _value) onlyOwner returns (bool){
        totalSupply += _value;
        balances[_to] += _value;
        Transfer(0x0, _to, _value);
        return true;
    }

    /**
    * @dev Toggle the compromised flag. For testing the bounty program
    */
    function compromiseContract() onlyOwner {
        compromised = true;
    }
}

contract IndecoinBounty is Bounty  {

  address public owner;

  function IndecoinBounty () {
    owner = msg.sender;
  }

  function deployContract() internal returns(address) {
    Indecoin zyd = new Indecoin();
    zyd.transferOwnership(owner);
    return zyd;
  }

}