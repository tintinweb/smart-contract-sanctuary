pragma solidity ^0.4.24;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
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
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
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












/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

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



/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
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
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
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
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
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
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
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






contract Whitelist is Ownable {

  mapping (address => mapping (address => bool)) public list;

  event LogWhitelistAdded(address indexed participant, uint256 timestamp);
  event LogWhitelistDeleted(address indexed participant, uint256 timestamp);

  constructor() public {}

  function isWhite(address _contract, address addr) public view returns (bool) {
    return list[_contract][addr];
  }

  function addWhitelist(address _contract, address[] addrs) public onlyOwner returns (bool) {
    for (uint256 i = 0; i < addrs.length; i++) {
      list[_contract][addrs[i]] = true;

      emit LogWhitelistAdded(addrs[i], now);
    }

    return true;
  }

  function delWhitelist(address _contract, address[] addrs) public onlyOwner returns (bool) {
    for (uint256 i = 0; i < addrs.length; i++) {
      list[_contract][addrs[i]] = false;

      emit LogWhitelistDeleted(addrs[i], now);
    }

    return true;
  }
}



contract MultiSigWallet {

  /*
   *  Events
   */
  event Confirmation(address indexed sender, uint indexed transactionId, uint timestamp);
  event Revocation(address indexed sender, uint indexed transactionId, uint timestamp);
  event Submission(uint indexed transactionId, uint timestamp);
  event Execution(uint indexed transactionId, uint timestamp);
  event ExecutionFailure(uint indexed transactionId, uint timestamp);
  event Deposit(address indexed sender, uint value, uint timestamp);
  event OwnerAddition(address indexed owner, uint timestamp);
  event OwnerRemoval(address indexed owner, uint timestamp);
  event RequirementChange(uint required, uint timestamp);

  /*
   *  Constants
   */
  uint constant public MAX_OWNER_COUNT = 50;

  /*
   *  Storage
   */
  mapping (uint => Transaction) public transactions;
  mapping (uint => mapping (address => bool)) public confirmations;
  mapping (address => bool) public isOwner;
  address[] public owners;
  uint public required;
  uint public transactionCount;

  struct Transaction {
    address destination;
    uint value;
    bytes data;
    bool executed;
  }

  /*
   *  Modifiers
   */
  modifier onlyWallet() {
    require(msg.sender == address(this));
    _;
  }

  modifier ownerDoesNotExist(address owner) {
    require(!isOwner[owner]);
    _;
  }

  modifier ownerExists(address owner) {
    require(isOwner[owner]);
    _;
  }

  modifier transactionExists(uint transactionId) {
    require(transactions[transactionId].destination != 0);
    _;
  }

  modifier confirmed(uint transactionId, address owner) {
    require(confirmations[transactionId][owner]);
    _;
  }

  modifier notConfirmed(uint transactionId, address owner) {
    require(!confirmations[transactionId][owner]);
    _;
  }

  modifier notExecuted(uint transactionId) {
    require(!transactions[transactionId].executed);
    _;
  }

  modifier notNull(address _address) {
    require(_address != 0);
    _;
  }

  modifier validRequirement(uint ownerCount, uint _required) {
    require(ownerCount <= MAX_OWNER_COUNT
            && _required <= ownerCount
            && _required != 0
            && ownerCount != 0);
            _;
  }

  /* @dev Fallback function allows to deposit ether. */
  function() public payable
  {
    if (msg.value > 0)
      emit Deposit(msg.sender, msg.value, now);
  }

  /*
  * Public functions
  */
  /* @dev Contract constructor sets initial owners and required number of confirmations.
  /* @param _owners List of initial owners.
  /* @param _required Number of required confirmations. */
  constructor(address[] _owners, uint _required)
  public
  validRequirement(_owners.length, _required)
  {
    for (uint i=0; i<_owners.length; i++) {
      require(!isOwner[_owners[i]] && _owners[i] != 0);
      isOwner[_owners[i]] = true;
    }
    owners = _owners;
    required = _required;
  }

  /* @dev Allows to add a new owner. Transaction has to be sent by wallet. */
  /* @param owner Address of new owner. */
  function addOwner(address owner)
  public
  onlyWallet
  ownerDoesNotExist(owner)
  notNull(owner)
  validRequirement(owners.length + 1, required)
  {
    isOwner[owner] = true;
    owners.push(owner);
    emit OwnerAddition(owner, now);
  }

  /* @dev Allows to remove an owner. Transaction has to be sent by wallet. */
  /* @param owner Address of owner. */
  function removeOwner(address owner)
  public
  onlyWallet
  ownerExists(owner)
  {
    isOwner[owner] = false;
    for (uint i=0; i<owners.length - 1; i++)
    if (owners[i] == owner) {
      owners[i] = owners[owners.length - 1];
      break;
    }
    owners.length -= 1;
    if (required > owners.length)
      changeRequirement(owners.length);
    emit OwnerRemoval(owner, now);
  }

  /* @dev Allows to replace an owner with a new owner. Transaction has to be sent by wallet. */
  /* @param owner Address of owner to be replaced. */
  /* @param newOwner Address of new owner. */
  function replaceOwner(address owner, address newOwner)
  public
  onlyWallet
  ownerExists(owner)
  ownerDoesNotExist(newOwner)
  {
    for (uint i=0; i<owners.length; i++)
    if (owners[i] == owner) {
      owners[i] = newOwner;
      break;
    }
    isOwner[owner] = false;
    isOwner[newOwner] = true;
    emit OwnerRemoval(owner, now);
    emit OwnerAddition(newOwner, now);
  }

  /* @dev Allows to change the number of required confirmations. Transaction has to be sent by wallet. */
  /* @param _required Number of required confirmations. */
  function changeRequirement(uint _required)
  public
  onlyWallet
  validRequirement(owners.length, _required)
  {
    required = _required;
    emit RequirementChange(_required, now);
  }

  /* @dev Allows an owner to submit and confirm a transaction. */
  /* @param destination Transaction target address. */
  /* @param value Transaction ether value. */
  /* @param data Transaction data payload. */
  /* @return Returns transaction ID. */
  function submitTransaction(address destination, uint value, bytes data)
  public
  returns (uint transactionId)
  {
    transactionId = addTransaction(destination, value, data);
    confirmTransaction(transactionId);
  }

  /* @dev Allows an owner to confirm a transaction. */
  /* @param transactionId Transaction ID. */
  function confirmTransaction(uint transactionId)
  public
  ownerExists(msg.sender)
  transactionExists(transactionId)
  notConfirmed(transactionId, msg.sender)
  {
    confirmations[transactionId][msg.sender] = true;
    emit Confirmation(msg.sender, transactionId, now);
    executeTransaction(transactionId);
  }

  /* @dev Allows an owner to revoke a confirmation for a transaction. */
  /* @param transactionId Transaction ID. */
  function revokeConfirmation(uint transactionId)
  public
  ownerExists(msg.sender)
  confirmed(transactionId, msg.sender)
  notExecuted(transactionId)
  {
    confirmations[transactionId][msg.sender] = false;
    emit Revocation(msg.sender, transactionId, now);
  }

  /* @dev Allows anyone to execute a confirmed transaction. */
  /* @param transactionId Transaction ID. */
  function executeTransaction(uint transactionId)
  public
  ownerExists(msg.sender)
  confirmed(transactionId, msg.sender)
  notExecuted(transactionId)
  {
    if (isConfirmed(transactionId)) {
      Transaction storage txn = transactions[transactionId];
      txn.executed = true;
      if (external_call(txn.destination, txn.value, txn.data.length, txn.data))
        emit Execution(transactionId, now);
      else {
        emit ExecutionFailure(transactionId, now);
        txn.executed = false;
      }
    }
  }

  /* call has been separated into its own function in order to take advantage */
  /* of the Solidity&#39;s code generator to produce a loop that copies tx.data into memory. */
  function external_call(address destination, uint value, uint dataLength, bytes data) private returns (bool) {
    bool result;
    assembly {
      let x := mload(0x40)   /* "Allocate" memory for output (0x40 is where "free memory" pointer is stored by convention) */
      let d := add(data, 32) /* First 32 bytes are the padded length of data, so exclude that */
      result := call(
        sub(gas, 34710),   /* 34710 is the value that solidity is currently emitting */
        /* It includes callGas (700) + callVeryLow (3, to pay for SUB) + callValueTransferGas (9000) + */
        /* callNewAccountGas (25000, in case the destination address does not exist and needs creating) */
        destination,
        value,
        d,
        dataLength,        /* Size of the input (in bytes) - this is what fixes the padding problem */
        x,
        0                  /* Output is ignored, therefore the output size is zero */
      )
    }
    return result;
  }

  /* @dev Returns the confirmation status of a transaction. */
  /* @param transactionId Transaction ID. */
  /* @return Confirmation status. */
  function isConfirmed(uint transactionId)
  public
  constant
  returns (bool)
  {
    uint count = 0;
    for (uint i=0; i<owners.length; i++) {
      if (confirmations[transactionId][owners[i]])
        count += 1;
      if (count == required)
        return true;
    }
  }

  /*
  * Internal functions
  */
  /* @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet. */
  /* @param destination Transaction target address. */
  /* @param value Transaction ether value. */
  /* @param data Transaction data payload. */
  /* @return Returns transaction ID. */
  function addTransaction(address destination, uint value, bytes data)
  internal
  notNull(destination)
  returns (uint transactionId)
  {
    transactionId = transactionCount;
    transactions[transactionId] = Transaction({
      destination: destination,
      value: value,
      data: data,
      executed: false
    });
    transactionCount += 1;
    emit Submission(transactionId, now);
  }

  /*
  * Web3 call functions
  */
  /* @dev Returns number of confirmations of a transaction. */
  /* @param transactionId Transaction ID. */
  /* @return Number of confirmations. */
  function getConfirmationCount(uint transactionId)
  public
  constant
  returns (uint count)
  {
    for (uint i=0; i<owners.length; i++)
    if (confirmations[transactionId][owners[i]])
      count += 1;
  }

  /* @dev Returns total number of transactions after filers are applied. */
  /* @param pending Include pending transactions. */
  /* @param executed Include executed transactions. */
  /* @return Total number of transactions after filters are applied. */
  function getTransactionCount(bool pending, bool executed)
  public
  constant
  returns (uint count)
  {
    for (uint i=0; i<transactionCount; i++)
    if (   pending && !transactions[i].executed
      || executed && transactions[i].executed)
    count += 1;
  }

  /* @dev Returns list of owners. */
  /* @return List of owner addresses. */
  function getOwners()
  public
  constant
  returns (address[])
  {
    return owners;
  }

  /* @dev Returns array with owner addresses, which confirmed transaction. */
  /* @param transactionId Transaction ID. */
  /* @return Returns array of owner addresses. */
  function getConfirmations(uint transactionId)
  public
  constant
  returns (address[] _confirmations)
  {
    address[] memory confirmationsTemp = new address[](owners.length);
    uint count = 0;
    uint i;
    for (i=0; i<owners.length; i++)
    if (confirmations[transactionId][owners[i]]) {
      confirmationsTemp[count] = owners[i];
      count += 1;
    }
    _confirmations = new address[](count);
    for (i=0; i<count; i++) {
      _confirmations[i] = confirmationsTemp[i];
    }
  }

  /* @dev Returns list of transaction IDs in defined range. */
  /* @param from Index start position of transaction array. */
  /* @param to Index end position of transaction array. */
  /* @param pending Include pending transactions. */
  /* @param executed Include executed transactions. */
  /* @return Returns array of transaction IDs. */
  function getTransactionIds(uint from, uint to, bool pending, bool executed)
  public
  constant
  returns (uint[] _transactionIds)
  {
    uint[] memory transactionIdsTemp = new uint[](transactionCount);
    uint count = 0;
    uint i;
    for (i=0; i<transactionCount; i++)
    if (   pending && !transactions[i].executed
      || executed && transactions[i].executed)
    {
      transactionIdsTemp[count] = i;
      count += 1;
    }
    _transactionIds = new uint[](to - from);
    for (i=from; i<to; i++)
    _transactionIds[i - from] = transactionIdsTemp[i];
  }
}





contract SmallWallet is Ownable {

  address public cap_address;

  event LogSmallRedeemed(address indexed participant, uint256 value, uint256 timestamp);
  event LogSmallWithdraw(uint256 value, uint256 timestamp);
  event LogSmallCAPAddressSet(address cap_address, uint256 timestamp);

  modifier onlyCAP() {
    require(msg.sender == cap_address);
    _;
  }

  constructor() public {
  }

  function () public payable {
    require(msg.value > 0);
  }

  function redeem(address _to, uint256 _value) onlyCAP external returns (bool) {
    require(_to != address(0));
    require(address(this).balance > _value);

    _to.transfer(_value);

    emit LogSmallRedeemed(_to, _value, now);

    return true;
  }

  function withdraw(uint256 _value) onlyOwner external returns (bool) {
    require(_value > 0);

    msg.sender.transfer(_value);

    emit LogSmallWithdraw(_value, now);
  }

  function setCAPAddress(address _cap) onlyOwner external returns (bool) {
    cap_address = _cap;

    emit LogSmallCAPAddressSet(_cap, now);
  }
}





contract LargeWallet is MultiSigWallet {

  address public cap_address;

  event LogRequestLargeRedeem(address indexed participant, uint256 value, uint256 tx_id);
  event LogLargeCAPAddressSet(address cap_address, uint256 timestamp);

  modifier onlyCAP() {
    require(msg.sender == cap_address);
    _;
  }

  constructor(address[] _owners, uint _required) public MultiSigWallet(_owners, _required) {
  }

  function redeem(address _to, uint256 _value) public onlyCAP returns(bool) {
    require(_to != address(0));

    bytes memory dataBytes;
    uint256 transactionId = addTransaction(_to, _value, dataBytes);
    emit LogRequestLargeRedeem(_to, _value, transactionId);

    return true;
  }

  function setCAPAddress(address _cap) external ownerExists(msg.sender) returns (bool) {
    cap_address = _cap;

    emit LogLargeCAPAddressSet(cap_address, now);
  }
}



contract CAPOpenDev is StandardToken, Ownable {
  using SafeMath for uint256;

  string public constant name = "CAPOpen";
  string public constant symbol = "CAPO";
  uint256 public constant decimals = 18;

  uint256 public constant BASE = 10000;
  uint256 public minimum = 0.01 ether;
  uint256 public platform_fee = 200;
  uint256 public roi = 10500;
  uint256 public performance_bonus = 2000;
  uint256 public redeem_level = 3 ether;
  uint256 public max_request_quota = 55;

  uint256 public request_buy_limit = 3;
  uint256 public request_buy_limit_interval = 3 minutes;
  uint256 public request_redeem_limit = 3;
  uint256 public request_redeem_limit_interval = 3 minutes;

  uint256 public start_time = 0;
  uint256 public end_time = 0;
  uint256 public period = 100 days;
  uint256 public wei_raised = 0;
  uint256 public token_issued = 0;
  uint256 public soft_cap = 1 ether;
  uint256 public nav = 10000;
  uint256 public initial_nav = 10000;
  uint256 public request_quota = 0;

  bool public isFixed = false;
  bool public tradeable = false;
  bool public issuable = false;
  bool public is_fund_raising_period = true;
  bool public soft_cap_reached = true;

  address public operator;
  address public vault;
  address public fee_wallet;
  SmallWallet public small_wallet;
  LargeWallet public large_wallet;
  Whitelist public whitelist;

  Request[] public redeem_requests;
  Request[] public buy_requests;
  mapping (address => Member) public members;
  mapping (address => RequestTime) public redeem_time_records;
  mapping (address => RequestTime) public buy_time_records;

  struct Member {
    bool buy_status;
    bool redeem_status;
    uint256 self_nav;
  }

  struct RequestTime {
    uint256 count;
    uint256 time;
  }

  struct Request {
    address participant;
    uint256 token;
    uint256 timestamp;
  }


  event LogStart(uint256 timestamp);
  event LogRestart(uint256 start_time, uint256 timestamp);
  event LogFinalize(uint256 timestamp);
  event LogTradingEnabled(uint256 timestamp);
  event LogTradingDisabled(uint256 timestamp);
  event LogNavUpdated(uint256 indexed old_nav, uint256 indexed new_nav, uint256 timestamp);
  event LogVaultChanged(address indexed sender, address vault, uint256 timestamp);
  event LogTokenBurned(address indexed burner, uint256 indexed  value, uint256 timestamp);
  event LogIsFixedSet(uint256 timestamp);
  event LogMinimumSet(uint256 minimum, uint256 timestamp);
  event LogPlatformFeeSet(uint256 platform_fee, uint256 timestamp);
  event LogROISet(uint256 roi, uint256 timestamp);
  event LogPerformanceBonusSet(uint256 performance_bonus, uint256 timestamp);
  event LogRedeemLevelSet(uint256 redeem_level, uint256 timestamp);
  event LogMaxRequestQuotaSet(uint256 max_request_quota, uint256 timestamp);
  event LogBuyRequestLimitSet(uint256 request_buy_limit, uint256 timestamp);
  event LogBuyRequestLimitIntervalSet(uint256 request_buy_limit_interval, uint256 timestamp);
  event LogRedeemRequestLimitSet(uint256 request_redeem_limit, uint256 timestamp);
  event LogRedeemRequestLimitIntervalSet(uint256 request_redeem_limit_interval, uint256 timestamp);
  event LogVaultAddressSet(address vault, uint256 timestamp);
  event LogFeeWalletAddressSet(address fee_wallet, uint256 timestamp);
  event LogLargeWalletAddressSet(address large_wallet, uint256 timestamp);
  event LogSmallWalletAddressSet(address small_wallet, uint256 timestamp);
  event LogWhitelistAddressSet(address whitelist, uint256 timestamp);
  event LogOperatorAddressSet(address operator, uint256 timestamp);
  event LogRedeem(address indexed sender, uint256 tokens, uint256 nav, uint256 value, uint256 timestamp);
  event LogRequestRedeem(address indexed sender, uint256 tokens, uint256 timestamp);
  event LogTokenBought(address indexed participant, uint256 value, uint256 nav, uint256 timestamp);
  event LogRequestBuy(address indexed sender, uint256 tokens, uint256 timestamp);
  event LogRequestRedeemFull(uint256 timestamp);
  event LogRequestBuyFull(uint256 timestamp);
  event LogAddressLocked(address indexed participant, uint256 timestamp);

  modifier onlyWhitelist {
    require(isWhitelist(msg.sender));
    _;
  }

  modifier onlyOperator {
    require(msg.sender == operator);
    _;
  }

  modifier validAddress(address addr) {
    require(addr != address(0));
    _;
  }
  modifier requestQuotaNotReached() {
    require(request_quota <= max_request_quota);
    _;
  }
  modifier NotFixed() {
    require(!isFixed);
    _;
  }


  /**
   * Constructor
   */
  constructor(
    address _vault, 
    address _fee_wallet, 
    address _small_wallet, 
    address _large_wallet, 
    address _whitelist, 
    address _operator, 
    uint256 _totalSupply
  )
  validAddress(_vault)
  public
  {
    totalSupply_ = _totalSupply;
    vault = _vault;
    fee_wallet = _fee_wallet;
    operator = _operator;
    small_wallet = SmallWallet(_small_wallet);
    large_wallet = LargeWallet(_large_wallet);
    whitelist = Whitelist(_whitelist);
    balances[owner] = totalSupply_;
  }

  function () public payable {
    require(msg.value >= 0);
  }

  /**
   * Status functions
   */

  function getTokenAmount(uint256 _value) public view returns (uint256) {
    require(_value >= minimum);

    return _value;
  }

  function getRedeemValue(uint256 tokens, address participant) public view returns (uint256) {
    require(tokens > 0);

    if (nav.mul(BASE).div(members[participant].self_nav) < roi.add(10000)) {
      return tokens.mul(nav).div(BASE);
    } 

    uint256 contractCoefficient = nav.mul(BASE.sub(performance_bonus)).div(BASE);
    uint256 walletCoefficient = members[participant].self_nav.mul(performance_bonus).div(BASE);

    return tokens.mul(walletCoefficient.add(contractCoefficient)).div(BASE);
  }

  function getBuyRequestsLength() public view returns (uint256) {
    return buy_requests.length;
  }

  function getRedeemRequestsLength() public view returns (uint256) {
    return redeem_requests.length;
  }

  function isBuyLocked(address participant) public view returns (bool) {
    if (buy_time_records[participant].count + 1 <= request_buy_limit) {
      return false;
    }
    return true;
  }

  function isRedeemLocked(address participant) public view returns (bool) {
    if (redeem_time_records[participant].count + 1 <= request_redeem_limit) {
      return false;
    }
    return true;
  }

  function isWhitelist(address addr) public view returns (bool) {
    return whitelist.isWhite(address(this), addr);
  }

  /**
   * Owner functions
   */
  function start() external onlyOwner returns (bool) {
    require(issuable == false);
    require(start_time == 0);
    
    issuable = true;
    start_time = block.timestamp;
    end_time = block.timestamp + period;

    emit LogStart(block.timestamp);

    return true;
  }
  
  function finalize() external onlyOwner {
    require(start_time != 0);

    if (wei_raised > soft_cap) {
      uint256 value = address(this).balance;
    } else {
      soft_cap_reached = false;
    }
    nav = 9800;
    is_fund_raising_period = false;

    emit LogFinalize(block.timestamp);
    emit LogNavUpdated(0, nav, block.timestamp);
  }

  function freeze() external onlyOwner returns (bool){
    require(issuable == true);

    issuable = false;

    return true;
  }

  function enableTrading() external onlyOwner returns (bool) {

    tradeable = true;

    emit LogTradingEnabled(block.timestamp);
    return true;
  }

  function disableTrading() external onlyOwner returns (bool) {

    tradeable = false;

    emit LogTradingDisabled(block.timestamp);
    return true;
  }

  function clearRequests() external onlyOwner returns (bool) {

    delete buy_requests;
    delete redeem_requests;

    return true;
  }

  function restart(uint256 _period) external onlyOwner NotFixed returns (bool) {
    issuable = true;
    start_time = block.timestamp;
    period = _period;
    end_time = block.timestamp + period;

    emit LogRestart(start_time, period);

    return true;
  }

  function setIsFixed() external onlyOwner NotFixed returns (bool) {
    isFixed = true;
    emit LogIsFixedSet(block.timestamp);
    return true;
  }

  function setMinimum(uint256 _minimum) external onlyOwner NotFixed returns (bool) {
    minimum = _minimum;
    emit LogMinimumSet(minimum, block.timestamp);
    return true;
  }
  function setPlatformFee(uint256 _platform_fee) external onlyOwner NotFixed returns (bool) {
    platform_fee = _platform_fee;
    emit LogPlatformFeeSet(platform_fee, block.timestamp);
    return true;
  }
  function setROI(uint256 _roi) external onlyOwner NotFixed returns (bool) {
    roi = _roi;
    emit LogROISet(roi, block.timestamp);
    return true;
  }
  function setPerformanceBonus(uint256 _performance_bonus) external onlyOwner NotFixed returns (bool) {
    performance_bonus = _performance_bonus;
    emit LogPerformanceBonusSet(performance_bonus, block.timestamp);
    return true;
  }
  function setRedeemLevel(uint256 _redeem_level) external onlyOwner NotFixed returns (bool) {
    redeem_level = _redeem_level;
    emit LogRedeemLevelSet(redeem_level, block.timestamp);
    return true;
  }
  function setMaxRequestQuota(uint256 _max_request_quota) external onlyOwner NotFixed returns (bool) {
    max_request_quota = _max_request_quota;
    emit LogMaxRequestQuotaSet(max_request_quota, block.timestamp);
    return true;
  }
  function setBuyRequestLimit(uint256 _request_buy_limit) external onlyOwner NotFixed returns (bool) {
    request_buy_limit = _request_buy_limit;
    emit LogBuyRequestLimitSet(request_buy_limit, block.timestamp);
    return true;
  }
  function setBuyRequestLimitInterval(uint256 _request_buy_limit_interval) external onlyOwner NotFixed returns (bool) {
    request_buy_limit_interval = _request_buy_limit_interval;
    emit LogBuyRequestLimitIntervalSet(request_buy_limit_interval, block.timestamp);
    return true;
  }
  function setRedeemRequestLimit(uint256 _request_redeem_limit) external onlyOwner NotFixed returns (bool) {
    request_redeem_limit = _request_redeem_limit;
    emit LogRedeemRequestLimitSet(request_redeem_limit, block.timestamp);
    return true;
  }
  function setRedeemRequestLimitInterval(uint256 _request_redeem_limit_interval) external onlyOwner NotFixed returns (bool) {
    request_redeem_limit_interval = _request_redeem_limit_interval;
    emit LogRedeemRequestLimitIntervalSet(request_redeem_limit_interval, block.timestamp);
    return true;
  }

  function setVaultAddress(address _vault) external onlyOwner returns (bool) {
    vault = _vault;
    emit LogVaultAddressSet(vault, block.timestamp);
    return true;
  }
  function setFeeWalletAddress(address _fee_wallet) external onlyOwner returns (bool) {
    fee_wallet = _fee_wallet;
    emit LogFeeWalletAddressSet(fee_wallet, block.timestamp);
    return true;
  }
  function setLargeWalletAddress(address _large_wallet) external onlyOwner returns (bool) {
    large_wallet = LargeWallet(_large_wallet);
    emit LogLargeWalletAddressSet(large_wallet, block.timestamp);
    return true;
  }
  function setSmallWalletAddress(address _small_wallet) external onlyOwner returns (bool) {
    small_wallet = SmallWallet(_small_wallet);
    emit LogSmallWalletAddressSet(small_wallet, block.timestamp);
    return true;
  }
  function setWhitelistAddress(address _whitelist) external onlyOwner returns (bool) {
    whitelist = Whitelist(_whitelist);
    emit LogWhitelistAddressSet(whitelist, block.timestamp);
    return true;
  }
  function setOperatorAddress(address _operator) external onlyOwner returns (bool) {
    operator = _operator;
    emit LogOperatorAddressSet(operator, block.timestamp);
    return true;
  }

}