/*
  8888888 .d8888b.   .d88888b.   .d8888b.  888                     888                 888      
    888  d88P  Y88b d88P" "Y88b d88P  Y88b 888                     888                 888      
    888  888    888 888     888 Y88b.      888                     888                 888      
    888  888        888     888  "Y888b.   888888  8888b.  888d888 888888      .d8888b 88888b.  
    888  888        888     888     "Y88b. 888        "88b 888P"   888        d88P"    888 "88b 
    888  888    888 888     888       "888 888    .d888888 888     888        888      888  888 
    888  Y88b  d88P Y88b. .d88P Y88b  d88P Y88b.  888  888 888     Y88b.  d8b Y88b.    888  888 
  8888888 "Y8888P"   "Y88888P"   "Y8888P"   "Y888 "Y888888 888      "Y888 Y8P  "Y8888P 888  888 

  Rocket startup for your ICO

  The innovative platform to create your initial coin offering (ICO) simply, safely and professionally.
  All the services your project needs: KYC, AI Audit, Smart contract wizard, Legal template,
  Master Nodes management, on a single SaaS platform!
*/
pragma solidity ^0.4.21;

// File: contracts\zeppelin-solidity\contracts\ownership\Ownable.sol

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

// File: contracts\zeppelin-solidity\contracts\lifecycle\Pausable.sol

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

// File: contracts\zeppelin-solidity\contracts\math\SafeMath.sol

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

// File: contracts\zeppelin-solidity\contracts\token\ERC20\ERC20Basic.sol

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

// File: contracts\zeppelin-solidity\contracts\token\ERC20\ERC20.sol

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

// File: contracts\ICOStartReservation.sol

contract ICOStartSaleInterface {
  ERC20 public token;
}

contract ICOStartReservation is Pausable {
  using SafeMath for uint256;

  ICOStartSaleInterface public sale;
  uint256 public cap;
  uint8 public feePerc;
  address public manager;
  mapping(address => uint256) public deposits;
  uint256 public weiCollected;
  uint256 public tokensReceived;
  bool public canceled;
  bool public paid;

  event Deposited(address indexed depositor, uint256 amount);
  event Withdrawn(address indexed beneficiary, uint256 amount);
  event Paid(uint256 netAmount, uint256 fee);
  event Canceled();

  function ICOStartReservation(ICOStartSaleInterface _sale, uint256 _cap, uint8 _feePerc, address _manager) public {
    require(_sale != (address(0)));
    require(_cap != 0);
    require(_feePerc >= 0);
    if (_feePerc != 0) {
      require(_manager != 0x0);
    }

    sale = _sale;
    cap = _cap;
    feePerc = _feePerc;
    manager = _manager;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is accepting
   * deposits.
   */
  modifier whenOpen() {
    require(isOpen());
    _;
  }

  /**
   * @dev Modifier to make a function callable only if the reservation was not canceled.
   */
  modifier whenNotCanceled() {
    require(!canceled);
    _;
  }

  /**
   * @dev Modifier to make a function callable only if the reservation was canceled.
   */
  modifier whenCanceled() {
    require(canceled);
    _;
  }

  /**
   * @dev Modifier to make a function callable only if the reservation was not yet paid.
   */
  modifier whenNotPaid() {
    require(!paid);
    _;
  }

  /**
   * @dev Modifier to make a function callable only if the reservation was paid.
   */
  modifier whenPaid() {
    require(paid);
    _;
  }

  /**
   * @dev Checks whether the cap has been reached. 
   * @return Whether the cap was reached
   */
  function capReached() public view returns (bool) {
    return weiCollected >= cap;
  }

  /**
   * @dev A reference to the sale&#39;s token contract. 
   * @return The token contract.
   */
  function getToken() public view returns (ERC20) {
    return sale.token();
  }

  /**
   * @dev Modifier to make a function callable only when the contract is accepting
   * deposits.
   */
  function isOpen() public view returns (bool) {
    return !paused && !capReached() && !canceled && !paid;
  }

  /**
   * @dev Shortcut for deposit() and claimTokens() functions.
   * Send 0 to claim, any other value to deposit.
   */
  function () external payable {
    if (msg.value == 0) {
      claimTokens(msg.sender);
    } else {
      deposit(msg.sender);
    }
  }

  /**
   * @dev Deposit ethers in the contract keeping track of the sender.
   * @param _depositor Address performing the purchase
   */
  function deposit(address _depositor) public whenOpen payable {
    require(_depositor != address(0));
    require(weiCollected.add(msg.value) <= cap);
    deposits[_depositor] = deposits[_depositor].add(msg.value);
    weiCollected = weiCollected.add(msg.value);
    emit Deposited(_depositor, msg.value);
  }

  /**
   * @dev Allows the owner to cancel the reservation thus enabling withdraws.
   * Contract must first be paused so we are sure we are not accepting deposits.
   */
  function cancel() public onlyOwner whenPaused whenNotPaid {
    canceled = true;
  }

  /**
   * @dev Allows the owner to cancel the reservation thus enabling withdraws.
   * Contract must first be paused so we are sure we are not accepting deposits.
   */
  function pay() public onlyOwner whenNotCanceled {
    require(weiCollected > 0);
  
    uint256 fee;
    uint256 netAmount;
    (fee, netAmount) = _getFeeAndNetAmount(weiCollected);

    require(address(sale).call.value(netAmount)(this));
    tokensReceived = getToken().balanceOf(this);

    if (fee != 0) {
      manager.transfer(fee);
    }

    paid = true;
    emit Paid(netAmount, fee);
  }

  /**
   * @dev Allows a depositor to withdraw his contribution if the reservation was canceled.
   */
  function withdraw() public whenCanceled {
    uint256 depositAmount = deposits[msg.sender];
    require(depositAmount != 0);
    deposits[msg.sender] = 0;
    weiCollected = weiCollected.sub(depositAmount);
    msg.sender.transfer(depositAmount);
    emit Withdrawn(msg.sender, depositAmount);
  }

  /**
   * @dev After the reservation is paid, transfers tokens from the contract to the
   * specified address (which must have deposited ethers earlier).
   * @param _beneficiary Address that will receive the tokens.
   */
  function claimTokens(address _beneficiary) public whenPaid {
    require(_beneficiary != address(0));
    
    uint256 depositAmount = deposits[_beneficiary];
    if (depositAmount != 0) {
      uint256 tokens = tokensReceived.mul(depositAmount).div(weiCollected);
      assert(tokens != 0);
      deposits[_beneficiary] = 0;
      getToken().transfer(_beneficiary, tokens);
    }
  }

  /**
   * @dev Emergency brake. Send all ethers and tokens to the owner.
   */
  function destroy() onlyOwner public {
    uint256 myTokens = getToken().balanceOf(this);
    if (myTokens != 0) {
      getToken().transfer(owner, myTokens);
    }
    selfdestruct(owner);
  }

  /*
   * Internal functions
   */

  /**
   * @dev Returns the current period, or null.
   */
   function _getFeeAndNetAmount(uint256 _grossAmount) internal view returns (uint256 _fee, uint256 _netAmount) {
      _fee = _grossAmount.div(100).mul(feePerc);
      _netAmount = _grossAmount.sub(_fee);
   }
}