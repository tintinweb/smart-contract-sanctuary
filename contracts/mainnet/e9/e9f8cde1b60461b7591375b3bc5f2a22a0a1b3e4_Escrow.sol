pragma solidity ^0.4.18;

// File: contracts/IEscrow.sol

/**
 * @title Escrow interface
 *
 * @dev https://send.sd/token
 */
interface IEscrow {

  event Created(
    address indexed sender,
    address indexed recipient,
    address indexed arbitrator,
    uint256 transactionId
  );
  event Released(address indexed arbitrator, address indexed sentTo, uint256 transactionId);
  event Dispute(address indexed arbitrator, uint256 transactionId);
  event Paid(address indexed arbitrator, uint256 transactionId);

  function create(
      address _sender,
      address _recipient,
      address _arbitrator,
      uint256 _transactionId,
      uint256 _tokens,
      uint256 _fee,
      uint256 _expiration
  ) public;

  function fund(
      address _sender,
      address _arbitrator,
      uint256 _transactionId,
      uint256 _tokens,
      uint256 _fee
  ) public;

}

// File: contracts/ISendToken.sol

/**
 * @title ISendToken - Send Consensus Network Token interface
 * @dev token interface built on top of ERC20 standard interface
 * @dev see https://send.sd/token
 */
interface ISendToken {
  function transfer(address to, uint256 value) public returns (bool);

  function isVerified(address _address) public constant returns(bool);

  function verify(address _address) public;

  function unverify(address _address) public;

  function verifiedTransferFrom(
      address from,
      address to,
      uint256 value,
      uint256 referenceId,
      uint256 exchangeRate,
      uint256 fee
  ) public;

  function issueExchangeRate(
      address _from,
      address _to,
      address _verifiedAddress,
      uint256 _value,
      uint256 _referenceId,
      uint256 _exchangeRate
  ) public;

  event VerifiedTransfer(
      address indexed from,
      address indexed to,
      address indexed verifiedAddress,
      uint256 value,
      uint256 referenceId,
      uint256 exchangeRate
  );
}

// File: zeppelin-solidity/contracts/math/SafeMath.sol

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

// File: contracts/Escrow.sol

/**
 * @title Vesting contract for SDT
 * @dev see https://send.sd/token
 */
contract Escrow is IEscrow, Ownable {
  using SafeMath for uint256;

  ISendToken public token;

  struct Lock {
    address sender;
    address recipient;
    uint256 value;
    uint256 fee;
    uint256 expiration;
    bool paid;
  }

  mapping(address => mapping(uint256 => Lock)) internal escrows;

  function Escrow(address _token) public {
    token = ISendToken(_token);
  }

  modifier tokenRestricted() {
    require(msg.sender == address(token));
    _;
  }

  function getStatus(address _arbitrator, uint256 _transactionId) 
      public view returns(address, address, uint256, uint256, uint256, bool) {
    return(
      escrows[_arbitrator][_transactionId].sender,
      escrows[_arbitrator][_transactionId].recipient,
      escrows[_arbitrator][_transactionId].value,
      escrows[_arbitrator][_transactionId].fee,
      escrows[_arbitrator][_transactionId].expiration,
      escrows[_arbitrator][_transactionId].paid
    );
  }

  function isUnlocked(address _arbitrator, uint256 _transactionId) public view returns(bool) {
    return escrows[_arbitrator][_transactionId].expiration == 1;
  }

  /**
   * @dev Create a record for held tokens
   * @param _arbitrator Address to be authorized to spend locked funds
   * @param _transactionId Intenral ID for applications implementing this
   * @param _tokens Amount of tokens to lock
   * @param _fee A fee to be paid to arbitrator (may be 0)
   * @param _expiration After this timestamp, user can claim tokens back.
   */
  function create(
      address _sender,
      address _recipient,
      address _arbitrator,
      uint256 _transactionId,
      uint256 _tokens,
      uint256 _fee,
      uint256 _expiration
  ) public tokenRestricted {

    require(_tokens > 0);
    require(_fee >= 0);
    require(escrows[_arbitrator][_transactionId].value == 0);

    escrows[_arbitrator][_transactionId].sender = _sender;
    escrows[_arbitrator][_transactionId].recipient = _recipient;
    escrows[_arbitrator][_transactionId].value = _tokens;
    escrows[_arbitrator][_transactionId].fee = _fee;
    escrows[_arbitrator][_transactionId].expiration = _expiration;

    Created(_sender, _recipient, _arbitrator, _transactionId);
  }

  /**
   * @dev Fund escrow record
   * @param _arbitrator Address to be authorized to spend locked funds
   * @param _transactionId Intenral ID for applications implementing this
   * @param _tokens Amount of tokens to lock
   * @param _fee A fee to be paid to arbitrator (may be 0)
   */
  function fund(
      address _sender,
      address _arbitrator,
      uint256 _transactionId,
      uint256 _tokens,
      uint256 _fee
  ) public tokenRestricted {

    require(escrows[_arbitrator][_transactionId].sender == _sender);
    require(escrows[_arbitrator][_transactionId].value == _tokens);
    require(escrows[_arbitrator][_transactionId].fee == _fee);
    require(escrows[_arbitrator][_transactionId].paid == false);

    escrows[_arbitrator][_transactionId].paid = true;

    Paid(_arbitrator, _transactionId);
  }

  /**
   * @dev Transfer a locked amount
   * @notice Only authorized address
   * @notice Exchange rate has 18 decimal places
   * @param _sender Address with locked amount
   * @param _recipient Address to send funds to
   * @param _transactionId App/user internal associated ID
   * @param _exchangeRate Rate to be reported to the blockchain
   */
  function release(
      address _sender,
      address _recipient,
      uint256 _transactionId,
      uint256 _exchangeRate
  ) public {

    Lock memory lock = escrows[msg.sender][_transactionId];

    require(lock.expiration != 1);
    require(lock.sender == _sender);
    require(lock.recipient == _recipient || lock.sender == _recipient);
    require(lock.paid);

    if (lock.fee > 0 && lock.recipient == _recipient) {
      token.transfer(_recipient, lock.value);
      token.transfer(msg.sender, lock.fee);
    } else {
      token.transfer(_recipient, lock.value.add(lock.fee));
    }

    delete escrows[msg.sender][_transactionId];

    token.issueExchangeRate(
      _sender,
      _recipient,
      msg.sender,
      lock.value,
      _transactionId,
      _exchangeRate
    );
    Released(msg.sender, _recipient, _transactionId);
  }

  /**
   * @dev Transfer a locked amount for timeless escrow
   * @notice Only authorized address
   * @notice Exchange rate has 18 decimal places
   * @param _sender Address with locked amount
   * @param _recipient Address to send funds to
   * @param _transactionId App/user internal associated ID
   * @param _exchangeRate Rate to be reported to the blockchain
   */
  function releaseUnlocked(
      address _sender,
      address _recipient,
      uint256 _transactionId,
      uint256 _exchangeRate
  ) public {

    Lock memory lock = escrows[msg.sender][_transactionId];

    require(lock.expiration == 1);
    require(lock.sender == _sender);
    require(lock.paid);

    if (lock.fee > 0 && lock.sender != _recipient) {
      token.transfer(_recipient, lock.value);
      token.transfer(msg.sender, lock.fee);
    } else {
      token.transfer(_recipient, lock.value.add(lock.fee));
    }

    delete escrows[msg.sender][_transactionId];

    token.issueExchangeRate(
      _sender,
      _recipient,
      msg.sender,
      lock.value,
      _transactionId,
      _exchangeRate
    );
    Released(msg.sender, _recipient, _transactionId);
  }

  /**
   * @dev Claim back locked amount after expiration time
   * @dev Cannot be claimed if expiration == 0 or expiration == 1
   * @notice Only works after lock expired
   * @param _arbitrator Authorized lock address
   * @param _transactionId transactionId ID from App/user
   */
  function claim(
      address _arbitrator,
      uint256 _transactionId
  ) public {
    Lock memory lock = escrows[_arbitrator][_transactionId];

    require(lock.sender == msg.sender);
    require(lock.paid);
    require(lock.expiration < block.timestamp);
    require(lock.expiration != 0);
    require(lock.expiration != 1);

    delete escrows[_arbitrator][_transactionId];

    token.transfer(msg.sender, lock.value.add(lock.fee));

    Released(
      _arbitrator,
      msg.sender,
      _transactionId
    );
  }

  /**
   * @dev Remove expiration time on a lock
   * @notice User wont be able to claim tokens back after this is called by arbitrator address
   * @notice Only authorized address
   * @param _transactionId App/user internal associated ID
   */
  function mediate(
      uint256 _transactionId
  ) public {
    require(escrows[msg.sender][_transactionId].paid);
    require(escrows[msg.sender][_transactionId].expiration != 0);
    require(escrows[msg.sender][_transactionId].expiration != 1);

    escrows[msg.sender][_transactionId].expiration = 0;

    Dispute(msg.sender, _transactionId);
  }

  /**
   This function is a way to get other ETC20 tokens
   back to their rightful owner if sent by mistake
   */
  function transferToken(address _tokenAddress, address _transferTo, uint256 _value) public onlyOwner {
    require(_tokenAddress != address(token));

    ISendToken erc20Token = ISendToken(_tokenAddress);
    erc20Token.transfer(_transferTo, _value);
  }
}