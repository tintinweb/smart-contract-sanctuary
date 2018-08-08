pragma solidity ^0.4.18;

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

// File: zeppelin-solidity/contracts/lifecycle/Pausable.sol

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

// File: contracts/crowdsale/SaleTracker.sol

/*
 This is a simple contract that is used to track incoming payments.
 As soon as a payment is received, an event is triggered to log the transaction.
 All funds are immediately forwarded to the owner.
 The sender must include a payment code as a payload and the contract can conditionally enforce the
 sending address matches the payment code.
 The payment code is the first 8 bytes of the keccak/sha3 hash of the address that the user has specified in the sale.
*/
contract SaleTracker is Pausable {
  using SafeMath for uint256;

  // Event to allow monitoring incoming payments
  event PurchaseMade (address indexed _from, bytes8 _paymentCode, uint256 _value);

  // Tracking of purchase total in wei made per sending address
  mapping(address => uint256) public purchases;

  // Tracking of purchaser addresses for lookup offline
  address[] public purchaserAddresses;

  // Flag to enforce payments source address matching the payment code
  bool public enforceAddressMatch;

  // Constructor to start the contract in a paused state
  function SaleTracker(bool _enforceAddressMatch) public {
    enforceAddressMatch = _enforceAddressMatch;
    pause();
  }

  // Setter for the enforce flag - only updatable by the owner
  function setEnforceAddressMatch(bool _enforceAddressMatch) onlyOwner public {
    enforceAddressMatch = _enforceAddressMatch;
  }

  // Purchase function allows incoming payments when not paused - requires payment code
  function purchase(bytes8 paymentCode) whenNotPaused public payable {

    // Verify they have sent ETH in
    require(msg.value != 0);

    // Verify the payment code was included
    require(paymentCode != 0);

    // If payment from addresses are being enforced, ensure the code matches the sender address
    if (enforceAddressMatch) {

      // Get the first 8 bytes of the hash of the address
      bytes8 calculatedPaymentCode = bytes8(keccak256(msg.sender));

      // Fail if the sender code does not match
      require(calculatedPaymentCode == paymentCode);
    }

    // Save off the existing purchase amount for this user
    uint256 existingPurchaseAmount = purchases[msg.sender];

    // If they have not purchased before (0 value), then save it off
    if (existingPurchaseAmount == 0) {
      purchaserAddresses.push(msg.sender);
    }

    // Add the new purchase value to the existing value already being tracked
    purchases[msg.sender] = existingPurchaseAmount.add(msg.value);    

    // Transfer out to the owner wallet
    owner.transfer(msg.value);

    // Trigger the event for a new purchase
    PurchaseMade(msg.sender, paymentCode, msg.value);
  }

  // Allows owner to sweep any ETH somehow trapped in the contract.
  function sweep() onlyOwner public {
    owner.transfer(this.balance);
  }

  // Get the number of addresses that have contributed to the sale
  function getPurchaserAddressCount() public constant returns (uint) {
    return purchaserAddresses.length;
  }

}