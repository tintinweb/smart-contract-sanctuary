pragma solidity ^0.4.18;
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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}


contract TwoXMachine is Ownable, Pausable {

  // Address of the contract creator
  address public contractOwner;

  // FIFO queue
  BuyIn[] public buyIns;

  // The current BuyIn queue index
  uint256 public index;

  // Total invested for entire contract
  uint256 public contractTotalInvested;

  // Total invested for a given address
  mapping (address => uint256) public totalInvested;

  // Total value for a given address
  mapping (address => uint256) public totalValue;

  // Total paid out for a given address
  mapping (address => uint256) public totalPaidOut;

  struct BuyIn {
    uint256 value;
    address owner;
  }

  /**
   * Fallback function to handle ethereum that was send straight to the contract
   */
  function() whenNotPaused() public payable {
    purchase();
  }

  function purchase() whenNotPaused() public payable {
    // I don&#39;t want no scrub
    require(msg.value >= 0.01 ether);

    // Take a 2% fee
    uint256 value = SafeMath.div(SafeMath.mul(msg.value, 98), 100);

    // HNNNNNNGGGGGG
    uint256 valueMultiplied = SafeMath.div(SafeMath.mul(msg.value, 150), 100);

    contractTotalInvested += msg.value;
    totalInvested[msg.sender] += msg.value;

    while (index < buyIns.length && value > 0) {
      BuyIn storage buyIn = buyIns[index];

      if (value < buyIn.value) {
        buyIn.owner.transfer(value);
        totalPaidOut[buyIn.owner] += value;
        totalValue[buyIn.owner] -= value;
        buyIn.value -= value;
        value = 0;
      } else {
        buyIn.owner.transfer(buyIn.value);
        totalPaidOut[buyIn.owner] += buyIn.value;
        totalValue[buyIn.owner] -= buyIn.value;
        value -= buyIn.value;
        buyIn.value = 0;
        index++;
      }
    }

    // if buyins have been exhausted, return the remaining
    // funds back to the investor
    if (value > 0) {
      msg.sender.transfer(value);
      valueMultiplied -= value;
      totalPaidOut[msg.sender] += value;
    }

    totalValue[msg.sender] += valueMultiplied;

    buyIns.push(BuyIn({
      value: valueMultiplied,
      owner: msg.sender
    }));
  }

  function payout() onlyOwner() public {
    owner.transfer(this.balance);
  }
}

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