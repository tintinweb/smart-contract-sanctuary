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
    if (newOwner != address(0)) {
      owner = newOwner;
    }
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
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

contract Auction is Ownable {
  using SafeMath for uint256;
  enum States { Setup, AcceptingBids, Paused, Ended }
  
  // Current state of the auction which starts at Setup.
  States public currentState = States.Setup;

  // Current highest bid data
  address public highestBidder;
  uint256 public highestBid;

  // Allowed withdrawals of previous bids
  mapping(address => uint256) pendingReturns;

  // Events that will be fired on changes
  event HighestBidIncreased(address bidder, uint256 amount);
  event AuctionStarted();
  event AuctionPaused();
  event AuctionResumed();
  event AuctionEnded(address winner, uint256 amount);

  modifier atState(States state) {
    require(currentState == state);
    _;
  }

  modifier notAtState(States state) {
    require(currentState != state);
    _;
  }

  /// Bid on the auction with the value sent with this transaction.
  /// The value will only be refunded if the auction is not won.
  function bid() payable atState(States.AcceptingBids) {
    require(msg.value > highestBid);

    if (highestBid != 0) {
      pendingReturns[highestBidder] = pendingReturns[highestBidder].add(highestBid);
    }

    highestBidder = msg.sender;
    highestBid = msg.value;
    HighestBidIncreased(msg.sender, msg.value);
  }

  /// Withdraw a bid that was overbid.
  function withdraw() notAtState(States.Setup) returns (bool) {
    uint256 amount = pendingReturns[msg.sender];
    if (amount > 0) {
      pendingReturns[msg.sender] = 0;
      if (!msg.sender.send(amount)) {
        pendingReturns[msg.sender] = amount;
        return false;
      }
    }
    return true;
  }

  /// Start the auction and allow bidding.
  function startAuction() onlyOwner atState(States.Setup) {
    currentState = States.AcceptingBids;
    AuctionStarted();
  }

  /// Pause the auction and temporarily disable bidding.
  function pauseAuction() onlyOwner atState(States.AcceptingBids) {
    currentState = States.Paused;
    AuctionPaused();
  }

  /// Resume the auction and allow bidding once again.
  function resumeAuction() onlyOwner atState(States.Paused) {
    currentState = States.AcceptingBids;
    AuctionResumed();
  }

  /// End the auction and send the highest bid to the owner
  function endAuction() onlyOwner notAtState(States.Ended) {
    currentState = States.Ended;
    AuctionEnded(highestBidder, highestBid);
    owner.transfer(highestBid);
  }
}

contract TulipToken is Auction, StandardToken {
    string public constant name = "TulipToken";
    string public constant symbol = "TLP";
    uint8 public constant decimals = 0;

    uint256 public constant INITIAL_SUPPLY = 1;

    function TulipToken() {
      totalSupply = INITIAL_SUPPLY;
      balances[owner] = INITIAL_SUPPLY;
    }

    /// Override Auction.endAuction to transfer
    /// The Tulip Token in the same transaction. 
    function endAuction() {
      transfer(highestBidder, 1);
      Auction.endAuction();
    }
}