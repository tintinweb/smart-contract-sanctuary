pragma solidity ^0.4.19;

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }
}

contract RakuRakuEth {
  using SafeMath for uint256;

  enum Status {
    Pending,
    Requested,
    Canceled,
    Paid,
    Rejected
  }
  
  struct Payment {
    uint256 amountJpy;
    uint256 amountWei;
    uint256 rateEthJpy;
    uint256 paymentDue;
    uint256 requestedTime;
    Status status; //0: pending, 1: requested, 2: canceled, 3: paid, 4: rejected
  }
  
  address public owner;
  address public creditor;
  address public debtor;
  uint256 ethWei = 10**18;

  Payment[] payments;
  mapping (address => uint256) balances;
  
  modifier onlyCreditor() {
    require(msg.sender == creditor);
    _;
  }
  
  modifier onlyDebtor() {
    require(msg.sender == debtor);
    _;
  }
  
  modifier onlyStakeholders() {
    require(msg.sender == debtor || msg.sender == creditor);
    _;
  }

  constructor (address _creditor, address _debtor) public {
    owner = msg.sender;
    creditor = _creditor;
    debtor = _debtor;
  }
  
  // Public Function (anyone can call)
  function getCurrentTimestamp () external view returns (uint256 timestamp) {
    return block.timestamp;
  }

  function collectPayment(uint256 _index) external returns (bool) {
    require(payments[_index].status == Status.Requested);
    require(payments[_index].requestedTime + 24*60*60 < block.timestamp);
    require(balances[debtor] >= payments[_index].amountWei);
    balances[debtor] = balances[debtor].sub(payments[_index].amountWei);
    balances[creditor] = balances[creditor].add(payments[_index].amountWei);
    payments[_index].status = Status.Paid;
    return true;
  }
  
  // Function for stakeholders (debtor or creditor)
  function getBalance(address _address) external view returns (uint256 balance) {
    return balances[_address];
  }
  
  function getPayment(uint256 _index) external view returns (uint256 amountJpy, uint256 amountWei, uint256 rateEthJpy, uint256 paymentDue, uint256 requestedTime, Status status) {
    Payment memory pm = payments[_index];
    return (pm.amountJpy, pm.amountWei, pm.rateEthJpy, pm.paymentDue, pm.requestedTime, pm.status);
  }
  
  function getNumPayments() external view returns (uint256 num) {
    return payments.length;
  }
  
  function withdraw(uint256 _amount) external returns (bool) {
    require(balances[msg.sender] >= _amount);
    msg.sender.transfer(_amount);
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    return true;
  }
  
  // Functions for creditor
  function addPayment(uint256 _amountJpy, uint256 _paymentDue) external onlyCreditor returns (uint256 index) {
    payments.push(Payment(_amountJpy, 0, 0, _paymentDue, 0, Status.Pending));
    return payments.length-1;
  }
  
  function requestPayment(uint256 _index, uint256 _rateEthJpy) external onlyCreditor returns (bool) {
    require(payments[_index].status == Status.Pending || payments[_index].status == Status.Rejected);
    require(payments[_index].paymentDue <= block.timestamp);
    payments[_index].rateEthJpy = _rateEthJpy;
    payments[_index].amountWei = payments[_index].amountJpy.mul(ethWei).div(_rateEthJpy);
    payments[_index].requestedTime = block.timestamp;
    payments[_index].status = Status.Requested;
    return true;
  }
  
  function cancelPayment(uint256 _index) external onlyCreditor returns (bool) {
    require(payments[_index].status != Status.Paid);
    payments[_index].status = Status.Canceled;
    return true;
  }

  // Function for debtor
  function () external payable onlyDebtor {
    balances[msg.sender] = balances[msg.sender].add(msg.value);
  }
  
  function rejectPayment(uint256 _index) external onlyDebtor returns (bool) {
    require(payments[_index].status == Status.Requested);
    require(payments[_index].requestedTime + 24*60*60 > block.timestamp);
    payments[_index].status = Status.Rejected;
    return true;
  }
  
  function approvePayment(uint256 _index) external onlyDebtor returns (bool) {
    require(payments[_index].status == Status.Requested);
    require(balances[debtor] >= payments[_index].amountWei);
    balances[debtor] = balances[debtor].sub(payments[_index].amountWei);
    balances[creditor] = balances[creditor].add(payments[_index].amountWei);
    payments[_index].status = Status.Paid;
    return true;
  }

}