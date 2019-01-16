/**
 * This smart contract code is Copyright 2018 TokenMarket Ltd. For more information see https://tokenmarket.net
 *
 * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
 */


pragma solidity 0.4.25;


/**
 * @dev Split ether between parties.
 * @author TokenMarket Ltd. /  Ville Sundell <ville at tokenmarket.net>
 *
 * Allows splitting payments between parties.
 * Ethers are split to parties, each party has slices they are entitled to.
 * Ethers of this smart contract are divided into slices upon split().
 */

/**
 * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
 *
 * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
 */




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


contract Recoverable is Ownable {

  /// @dev Empty constructor (for now)
  constructor() public {
  }

  /// @dev This will be invoked by the owner, when owner wants to rescue tokens
  /// @param token Token which will we rescue to the owner from the contract
  function recoverTokens(ERC20Basic token) onlyOwner public {
    token.transfer(owner, tokensToBeReturned(token));
  }

  /// @dev Interface function, can be overwritten by the superclass
  /// @param token Token which balance we will check and return
  /// @return The amount of tokens (in smallest denominator) the contract owns
  function tokensToBeReturned(ERC20Basic token) public view returns (uint) {
    return token.balanceOf(this);
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


contract PaymentSplitter is Recoverable {
  using SafeMath for uint256; // We use only uint256 for safety reasons (no boxing)

  /// @dev Describes a party (address and amount of slices the party is entitled to)
  struct Party {
    address addr;
    uint256 slices;
  }

  /// @dev This is just a failsafe, so we can&#39;t initialize a contract where
  ///      splitting would not be succesful in the future (for example because
  ///      of decreased block gas limit):
  uint256 constant MAX_PARTIES = 100;
  /// @dev How many slices there are in total:
  uint256 public totalSlices;
  /// @dev Array of "Party"s for each party&#39;s address and amount of slices:
  Party[] public parties;

  /// @dev This event is emitted when someone makes a payment:
  ///      (Gnosis MultiSigWallet compatible event)
  event Deposit(address indexed sender, uint256 value);
  /// @dev This event is emitted when someone splits the ethers between parties:
  ///      (emitted once per call)
  event Split(address indexed who, uint256 value);
  /// @dev This event is emitted for every party we send ethers to:
  event SplitTo(address indexed to, uint256 value);

  /// @dev Constructor: takes list of parties and their slices.
  /// @param addresses List of addresses of the parties
  /// @param slices Slices of the parties. Will be added to totalSlices.
  constructor(address[] addresses, uint[] slices) public {
    require(addresses.length == slices.length, "addresses and slices must be equal length.");
    require(addresses.length > 0 && addresses.length < MAX_PARTIES, "Amount of parties is either too many, or zero.");

    for(uint i=0; i<addresses.length; i++) {
      parties.push(Party(addresses[i], slices[i]));
      totalSlices = totalSlices.add(slices[i]);
    }
  }

  /// @dev Split the ethers, and send to parties according to slices.
  ///      This can be intentionally invoked by anyone: if some random person
  ///      wants to pay for the gas, that&#39;s good for us.
  function split() external {
    uint256 totalBalance = address(this).balance;
    uint256 slice = totalBalance.div(totalSlices);

    for(uint i=0; i<parties.length; i++) {
      uint256 amount = slice.mul(parties[i].slices);

      parties[i].addr.transfer(amount);
      emit SplitTo(parties[i].addr, amount);
    }

    emit Split(msg.sender, totalBalance);
  }

  /// @dev Fallback function, intentionally designed to fit to the gas stipend.
  function() public payable {
    emit Deposit(msg.sender, msg.value);
  }
}