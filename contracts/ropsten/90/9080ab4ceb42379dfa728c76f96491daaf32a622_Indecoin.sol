pragma solidity ^0.4.23;

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

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

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
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

// File: openzeppelin-solidity/contracts/payment/PullPayment.sol

/**
 * @title PullPayment
 * @dev Base contract supporting async send for pull payments. Inherit from this
 * contract and use asyncSend instead of send or transfer.
 */
contract PullPayment {
  using SafeMath for uint256;

  mapping(address => uint256) public payments;
  uint256 public totalPayments;

  /**
  * @dev Withdraw accumulated balance, called by payee.
  */
  function withdrawPayments() public {
    address payee = msg.sender;
    uint256 payment = payments[payee];

    require(payment != 0);
    require(address(this).balance >= payment);

    totalPayments = totalPayments.sub(payment);
    payments[payee] = 0;

    payee.transfer(payment);
  }

  /**
  * @dev Called by the payer to store the sent amount as credit to be pulled.
  * @param dest The destination address of the funds.
  * @param amount The amount to transfer.
  */
  function asyncSend(address dest, uint256 amount) internal {
    payments[dest] = payments[dest].add(amount);
    totalPayments = totalPayments.add(amount);
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/BasicToken.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol

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

// File: contracts/Dividend.sol

/**
 * Indeco, Inc.
 * All rights reserved.
 * The Dividend contract is a bit what it sounds like: it allows payments to
 * be made to a contract and for them to be withdrawn. The trick of it is that
 * one can only withdraw the latest payment.
 */
pragma solidity ^0.4.21;






contract Dividend is Ownable, StandardToken {
  using SafeMath for uint256;

  uint constant pointMultiplier = 10e18;

  /** @dev Object used to deliver payments to token holders upon disbursement
    * by contract owner.
    */
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

  modifier collectsDividends() {
    collectsAccountDividends(msg.sender);
    _;
  }

  /** @dev Find the dividends owed to an account, in the token&#39;s points
    * (by default, this is done in the token&#39;s variant of ether&#39;s wei. Done by
    * finding the new unclaimed dividendPoints. These dividendPoints already
    * have been divided by the total balance to spread dividends to, so
    * it is necessary multiply by the address owner&#39;s portion (balances[account]).
    *
    * @param  account The account to check dividends owed
    * @return owed The amount owed, once converted
    */
  function dividendsOwing(address account) internal view returns(uint owed) {
    if(account == owner) return 0;
    uint newDividendPoints = totalDividendPoints -
      dividends[account].lastDividendPoints;
    return (balances[account] * newDividendPoints) / pointMultiplier;
  }

  /** @dev Collects dividends for a given address and deposits them in the
    * address&#39;s dividend account (not the main wallet).
    * @param account Address to collect dividends for
    */
  function collectsAccountDividends(address account) internal {
    uint owing = dividendsOwing(account);
    if(owing > 0) {
      unclaimedDividends -= owing;
      dividends[account].balance += owing;
      emit DividendCollected(account, owing);
    }
    dividends[account].lastDividendPoints = totalDividendPoints;
  }

  /** @dev Find the unclaimed dividends (in the dividend account) of the calling
    * user.
    * @return the unclaimed payment balance
    */
  function dividendBalance() public collectsDividends returns (uint){
    return dividends[msg.sender].balance;
  }

  /** @dev Add payment to be disbursed to the contract. This will eventually be
    * distributed proportionally by ownership stake to token holders. Increments
    * totalDividendPoints by total disbursement multipled by a large number to
    * only use ints, then divided by the total amount of valid so that future
    * calls to collectsAccountDividends can mulitply by the account&#39;s token
    * holdings to give the proper proportion for disbursement.
    */
  function disburse() public payable onlyOwner {
    uint excluded = balances[owner];
    uint included = totalSupply_ - excluded;
    require(included > 0);
    totalDividendPoints += (msg.value * pointMultiplier / included);
    unclaimedDividends += msg.value;
    emit DividendDisbursed(msg.sender, msg.value);
  }

  /**
    * @dev Allows any non-owner token holder to withdraw owed dividends and
    * deposit them in their main wallet address. When called, will only disburse
    * entire balance at once.
    */
  function withdrawDividends() public {
    address payee = msg.sender;
    uint amount = dividendBalance();
    require(payee != owner);
    require(amount > 0);
    dividends[payee].balance = 0;
    assert(payee.send(amount));
    emit DividendWithdrawn(payee, amount);
  }

  /** @dev Implements StandardToken&#39;s tranfer after collecting dividends for
    * both the sender and receiver.
    * @param _to The address to send funds to
    * @param _value The amount of tokens to be transferred
    */
  function transfer(address _to, uint256 _value) public collectsDividends
    returns (bool) {
    collectsAccountDividends(_to);
    return super.transfer(_to, _value);
  }

  /** @dev Implements StandardToken&#39;s tranfer after collecting dividends for
    * both the sender and receiver.
    * @param _from The address to get funds from
    * @param _to The address to send funds to
    * @param _value The amount of tokens to be transferred
    */
  function transferFrom(address _from, address _to, uint256 _value) public
    returns (bool) {
    collectsAccountDividends(_from);
    collectsAccountDividends(_to);
    return super.transferFrom(_from, _to, _value);
  }

}

// File: openzeppelin-solidity/contracts/lifecycle/Destructible.sol

/**
 * @title Destructible
 * @dev Base contract that can be destroyed by owner. All funds in contract will be sent to the owner.
 */
contract Destructible is Ownable {

  constructor() public payable { }

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

// File: openzeppelin-solidity/contracts/Bounty.sol

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
  function() external payable {
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
    emit TargetCreated(target);
    return target;
  }

  /**
   * @dev Sends the contract funds to the researcher that proved the contract is broken.
   * @param target contract
   */
  function claim(Target target) public {
    address researcher = researchers[target];
    require(researcher != 0);
    // Check Target contract invariants
    require(!target.checkInvariant());
    asyncSend(researcher, address(this).balance);
    claimed = true;
  }

  /**
   * @dev Internal function to deploy the target contract.
   * @return A target contract address
   */
  function deployContract() internal returns(address);

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

// File: contracts/Indecoin.sol

/**
 * (C) 2017 Indeco, Inc.
 * All rights reserved.
 */
pragma solidity ^0.4.21;







contract Indecoin is Ownable, Target, StandardToken, Dividend {
    using SafeMath for uint256;

    /** public data from our other classes:
    *   address public owner;       // from Ownable
    *   uint256 public totalSupply_; // from ERC20Basic
    */

    // Expected of ERC20
    string public constant name     = &quot;LaunchCoinTest v0.2&quot;;
    // TODO: Refactor once done with testnet
    string public constant symbol   = &quot;LC_t&quot;;
    uint8  public constant decimals = 18;

    bool public compromised; // In testing, true means the contract was breached


    constructor() public {
      compromised = false;
    }

    // Now we have the Bounty code, as the contract is Bounty.

    /**
     * @dev Check if the contract has been compromised by testing an invariant
     * @return true if the invariant fails, false if the invariant still holds
     */

    function checkInvariant() public returns (bool) {
      // Check the compromised flag.
      if (compromised == true) {
        return false;
      }
      return true;
    }

    /**
      * @dev Add tokens to an account, and increase total supply.
      * Can only be done by contract owner.
      * @param _to The address of the recipient
      * @param _value The value to transfer
      */
    function mintTokens(address _to, uint256 _value)
    public onlyOwner returns (bool){
        totalSupply_ += _value;
        balances[_to] += _value;
        emit Transfer(0x0, _to, _value);
        return true;
    }

    /**
      * @dev Set contract to be comprimised. Use to test bounty program
      */
    function compromiseContract() public onlyOwner {
        compromised = true;
    }
}