pragma solidity ^0.5.0;

/**
 * Syndicate
 *
 * A way to distribute ownership of ether in time
 **/

contract Syndicate {

  mapping (address => uint256) public balances;

  struct Payment {
    address sender;
    address payable receiver;
    uint256 timestamp;
    uint256 time;
    uint256 weiValue;
    uint256 weiPaid;
    bool isFork;
    uint256 parentIndex;
  }

  Payment[] public payments;

  // A mapping of Payment index to forked payments that have been created
  mapping (uint256 => uint256[2]) public forkIndexes;

  event PaymentUpdated(uint256 index);
  event PaymentCreated(uint256 index);
  event BalanceUpdated(address payable target);

  /**
   * Deposit to a given address over a certain amount of time.
   **/
  function deposit(address payable _receiver, uint256 _time) external payable {
    balances[msg.sender] += msg.value;
    emit BalanceUpdated(msg.sender);
    pay(_receiver, msg.value, _time);
  }

  /**
   * Pay from sender to receiver a certain amount over a certain amount of time.
   **/
  function pay(address payable _receiver, uint256 _weiValue, uint256 _time) public {
    // Verify that the balance is there and value is non-zero
    require(_weiValue <= balances[msg.sender] && _weiValue > 0);
    // Verify the time is non-zero
    require(_time > 0);
    payments.push(Payment({
      sender: msg.sender,
      receiver: _receiver,
      timestamp: block.timestamp,
      time: _time,
      weiValue: _weiValue,
      weiPaid: 0,
      isFork: false,
      parentIndex: 0
    }));
    // Update the balance value of the sender to effectively lock the funds in place
    balances[msg.sender] -= _weiValue;
    emit BalanceUpdated(msg.sender);
    emit PaymentCreated(payments.length - 1);
  }

  /**
   * Settle an individual payment at the current point in time.
   *
   * Can be called idempotently.
   **/
  function paymentSettle(uint256 index) public {
    uint256 owedWei = paymentWeiOwed(index);
    balances[payments[index].receiver] += owedWei;
    emit BalanceUpdated(payments[index].receiver);
    payments[index].weiPaid += owedWei;
    emit PaymentUpdated(index);
  }

  /**
   * Return the wei owed on a payment at the current block timestamp.
   **/
  function paymentWeiOwed(uint256 index) public view returns (uint256) {
    assertPaymentIndexInRange(index);
    Payment memory payment = payments[index];
    // Calculate owed wei based on current time and total wei owed/paid
    return max(payment.weiPaid, payment.weiValue * min(block.timestamp - payment.timestamp, payment.time) / payment.time) - payment.weiPaid;
  }

  /**
   * Forks a payment to another address for the duration of a payment. Allows
   * responsibility of funds to be delegated to other addresses by payment
   * recipient.
   *
   * Payment completion time is unaffected by forking, the only thing that
   * changes is recipient.
   *
   * Payments can be forked until weiValue is 0, at which point the Payment is
   * settled. Child payments can also be forked.
   **/
  function paymentFork(uint256 index, address payable _receiver, uint256 _weiValue) public {
    Payment memory payment = payments[index];
    // Make sure the payment owner is operating
    require(msg.sender == payment.receiver);

    uint256 remainingWei = payment.weiValue - payment.weiPaid;
    uint256 remainingTime = max(0, payment.time - (block.timestamp - payment.timestamp));

    // Ensure there is enough unsettled wei in the payment
    require(remainingWei >= _weiValue);
    require(_weiValue > 0);

    // Create a new Payment of _weiValue to _receiver over the remaining time of
    // Payment at index
    payments[index].weiValue = payments[index].weiPaid;
    emit PaymentUpdated(index);

    payments.push(Payment({
      sender: msg.sender,
      receiver: _receiver,
      timestamp: block.timestamp,
      time: remainingTime,
      weiValue: _weiValue,
      weiPaid: 0,
      isFork: true,
      parentIndex: index
    }));
    forkIndexes[index][0] = payments.length - 1;
    emit PaymentCreated(payments.length - 1);

    payments.push(Payment({
      sender: payment.receiver,
      receiver: payment.receiver,
      timestamp: block.timestamp,
      time: remainingTime,
      weiValue: remainingWei - _weiValue,
      weiPaid: 0,
      isFork: true,
      parentIndex: index
    }));
    forkIndexes[index][1] = payments.length - 1;
    emit PaymentCreated(payments.length - 1);
  }

  function paymentForkIndexes(uint256 index) public view returns (uint256[2] memory) {
    assertPaymentIndexInRange(index);
    return forkIndexes[index];
  }

  function isPaymentForked(uint256 index) public view returns (bool) {
    assertPaymentIndexInRange(index);
    return forkIndexes[index][0] != 0 && forkIndexes[index][1] != 0;
  }

  /**
   * Accessor for determining if a given payment is fully settled.
   **/
  function isPaymentSettled(uint256 index) public view returns (bool) {
    assertPaymentIndexInRange(index);
    Payment memory payment = payments[index];
    return payment.weiValue == payment.weiPaid;
  }

  /**
   * Reverts if the supplied payment index is out of range
   **/
  function assertPaymentIndexInRange(uint256 index) public view {
    require(index < payments.length);
  }

  /**
   * Withdraw target address balance from Syndicate to ether.
   **/
  function withdraw(address payable target, uint256 weiValue) public {
    require(balances[target] >= weiValue);
    balances[target] -= weiValue;
    emit BalanceUpdated(target);
    target.transfer(weiValue);
  }

  /**
   * One argument, target address.
   **/
  function withdraw(address payable target) public {
    withdraw(target, balances[target]);
  }

  /**
   * No arguments, withdraws full balance to sender from sender balance.
   **/
  function withdraw() public {
    withdraw(msg.sender, balances[msg.sender]);
  }

  /**
   * Accessor for array length
   **/
  function paymentCount() public view returns (uint) {
    return payments.length;
  }

  /**
   * Return the smaller of two values.
   **/
  function min(uint a, uint b) private pure returns (uint) {
    return a < b ? a : b;
  }

  /**
   * Return the larger of two values.
   **/
  function max(uint a, uint b) private pure returns (uint) {
    return a > b ? a : b;
  }
}