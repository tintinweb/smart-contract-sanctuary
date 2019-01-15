pragma solidity ^0.5.0;

/**
 * The Syndicate contract
 *
 * A way for distributed groups of people to work together and come to consensus
 * on use of funds.
 *
 * syndicate - noun
 * a group of individuals or syndicates combined to promote some common interest
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
  }

  Payment[] public payments;

  event PaymentUpdated(uint256 index);
  event PaymentCreated(uint256 index);

  /**
   * Deposit to a given address over a certain amount of time.
   **/
  function deposit(address payable _receiver, uint256 _time) external payable {
    balances[msg.sender] += msg.value;
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
      weiPaid: 0
    }));
    // Update the balance value of the sender to effectively lock the funds in place
    balances[msg.sender] -= _weiValue;
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
    return payment.weiValue * min(block.timestamp - payment.timestamp, payment.time) / payment.time - payment.weiPaid;
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
}