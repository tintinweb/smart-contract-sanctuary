pragma solidity ^0.4.13;


/**
 * Base contract for work orders on the Provide platform.
 */
contract ProvideWorkOrder {
  using SafeMath for uint;

  /** Status of the work order contract. **/
  enum Status { Pending, InProgress, Completed, Paid }

  /** Provide platform robot. */
  address public prvd;

  /** Provide platform wallet where payment amounts owed to providers are escrowed. */
  address public paymentEscrow;

  /** Peer requesting and purchasing service. */
  address public peer;

  /** Peer providing service; compensated in PRVD tokens. */
  address public provider;

  /** Provide platform work order identifier (UUIDv4). */
  uint128 public identifier;

  /** Current status of the work order contract. **/
  Status public status;

  /** Total amount of Provide (PRVD) tokens payable to provider, expressed in wei. */
  uint256 public amount;

  /** Encoded transaction details. */
  string public details;

  /** Emitted when the work order has been started. */
  event WorkOrderStarted(uint128 _identifier);

  /** Emitted when the work order has been completed. */
  event WorkOrderCompleted(uint128 _identifier, uint256 _amount, string _details);

  /** Emitted when the transaction has been completed. */
  event TransactionCompleted(uint128 _identifier, uint256 _paymentAmount, uint256 feeAmount, string _details);

  /**
   * @param _prvd Provide platform robot contract address
   * @param _paymentEscrow Provide platform wallet where payment amounts owed to providers are escrowed
   * @param _peer Address of party purchasing services
   * @param _identifier Provide platform work order identifier (UUIDv4)
   */
  function ProvideWorkOrder(
    address _prvd,
    address _paymentEscrow,
    address _peer,
    uint128 _identifier
  ) {
    if (_prvd == 0x0) revert();
    if (_paymentEscrow == 0x0) revert();
    if (_peer == 0x0) revert();

    prvd = _prvd;
    paymentEscrow = _paymentEscrow;
    peer = _peer;
    identifier = _identifier;

    status = Status.Pending;
  }

  /**
   * Set the address of the party providing service and start the work order.
   * @param _provider Address of the party providing service
   */
  function start(address _provider) public onlyPrvd onlyPending {
    if (provider != 0x0) revert();
    provider = _provider;
    status = Status.InProgress;
    WorkOrderStarted(identifier);
  }

  /**
   * Complete the work order.
   * @param _amount Total amount of Provide (PRVD) tokens payable to provider, expressed in wei
   * @param _details Encoded transaction details
   */
  function complete(uint256 _amount, string _details) public onlyProvider onlyInProgress {
    amount = _amount;
    details = _details;
    status = Status.Completed;
    WorkOrderCompleted(identifier, amount, details);
  }

  /**
   * Complete the transaction by remitting the exact amount of PRVD tokens due.
   * The service provider&#39;s payment is escrowed in the payment escrow wallet
   * and the platform fee is remitted to Provide.
   *
   * Partial payments will be rejected.
   */
  function completeTransaction() public onlyPurchaser onlyCompleted payable {
    if (msg.value != amount) revert();

    uint paymentAmount = msg.value.mul(uint(95).div(100));
    paymentEscrow.transfer(paymentAmount);

    uint feeAmount = msg.value.sub(paymentAmount);
    prvd.transfer(feeAmount);

    status = Status.Paid;
    TransactionCompleted(identifier, paymentAmount, feeAmount, details);
  }

  /**
   * Only allow the Provide platform robot to execute a contract function.
   */
  modifier onlyPrvd() {
    if (msg.sender != prvd) revert();
    _;
  }

  /**
   * Only allow the peer purchasing services to execute a contract function.
   */
  modifier onlyPurchaser() {
    if (msg.sender != peer) revert();
    _;
  }

  /**
   * Only allow the service provider to execute a contract function.
   */
  modifier onlyProvider() {
    if (msg.sender != provider) revert();
    _;
  }

  /**
   * Only allow execution of a contract function if the work order is pending.
   */
  modifier onlyPending() {
    if (uint(status) != uint(Status.Pending)) revert();
    _;
  }

  /**
   * Only allow execution of a contract function if the work order is started.
   */
  modifier onlyInProgress() {
    if (uint(status) != uint(Status.InProgress)) revert();
    _;
  }

  /**
   * Only allow execution of a contract function if the work order is complete.
   */
  modifier onlyCompleted() {
    if (uint(status) != uint(Status.Completed)) revert();
    _;
  }
}

/**
 * Math operations with safety checks
 */
library SafeMath {

  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    return a / b;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assertTrue(bool val) internal {
    assert(val);
  }

  function assertFalse(bool val) internal {
    assert(!val);
  }
}