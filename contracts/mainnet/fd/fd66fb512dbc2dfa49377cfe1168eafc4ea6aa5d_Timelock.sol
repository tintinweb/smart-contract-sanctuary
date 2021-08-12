/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

contract Ownable {

  address public owner;
  address public pendingOwner;

  event OwnershipTransferInitiated(address indexed previousOwner, address indexed newOwner);
  event OwnershipTransferConfirmed(address indexed previousOwner, address indexed newOwner);

  constructor() {
    owner = msg.sender;
    emit OwnershipTransferConfirmed(address(0), owner);
  }

  modifier onlyOwner() {
    require(isOwner(), "Ownable: caller is not the owner");
    _;
  }

  function isOwner() public view returns (bool) {
    return msg.sender == owner;
  }

  function transferOwnership(address _newOwner) external onlyOwner {
    require(_newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferInitiated(owner, _newOwner);
    pendingOwner = _newOwner;
  }

  function acceptOwnership() external {
    require(msg.sender == pendingOwner, "Ownable: caller is not pending owner");
    emit OwnershipTransferConfirmed(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

contract Timelock is Ownable {

  event NewDelay(uint indexed newDelay);
  event CancelTransaction(bytes32 indexed txHash, address indexed target,  bytes data, uint eta);
  event ExecuteTransaction(bytes32 indexed txHash, address indexed target,  bytes data, uint eta);
  event QueueTransaction(bytes32 indexed txHash, address indexed target, bytes data, uint eta);

  uint public constant GRACE_PERIOD = 14 days;
  uint public constant MINIMUM_DELAY = 12 hours;
  uint public constant MAXIMUM_DELAY = 30 days;

  uint public delay;

  mapping (bytes32 => bool) public queuedTransactions;

  receive() external payable { }

  constructor(uint _delay) {
    require(_delay >= MINIMUM_DELAY, "Timelock::constructor: Delay must exceed minimum delay.");
    require(_delay <= MAXIMUM_DELAY, "Timelock::constructor: Delay must not exceed maximum delay.");

    delay = _delay;
  }

  function setDelay(uint _delay) external {
    require(msg.sender == address(this), "Timelock::setDelay: Call must come from Timelock.");
    require(_delay >= MINIMUM_DELAY, "Timelock::setDelay: Delay must exceed minimum delay.");
    require(_delay <= MAXIMUM_DELAY, "Timelock::setDelay: Delay must not exceed maximum delay.");
    delay = _delay;

    emit NewDelay(delay);
  }

  function queueTransaction(address _target, bytes memory _data, uint _eta) external onlyOwner returns (bytes32) {
    require(_eta >= block.timestamp + delay, "Timelock::queueTransaction: Estimated execution block must satisfy delay.");

    bytes32 txHash = keccak256(abi.encode(_target, _data, _eta));
    queuedTransactions[txHash] = true;

    emit QueueTransaction(txHash, _target, _data, _eta);
    return txHash;
  }

  function cancelTransaction(address _target, bytes memory _data, uint _eta) external onlyOwner {
    bytes32 txHash = keccak256(abi.encode(_target, _data, _eta));
    queuedTransactions[txHash] = false;

    emit CancelTransaction(txHash, _target, _data, _eta);
  }

  function executeTransaction(address _target, bytes memory _data, uint _eta) external payable onlyOwner returns (bytes memory) {
    bytes32 txHash = keccak256(abi.encode(_target, _data, _eta));
    require(queuedTransactions[txHash], "Timelock::executeTransaction: Transaction hasn't been queued.");
    require(block.timestamp >= _eta, "Timelock::executeTransaction: Transaction hasn't surpassed time lock.");
    require(block.timestamp <= _eta + GRACE_PERIOD, "Timelock::executeTransaction: Transaction is stale.");

    queuedTransactions[txHash] = false;

    (bool success, bytes memory returnData) = _target.delegatecall(_data);
    require(success, "Timelock::executeTransaction: Transaction execution reverted.");

    emit ExecuteTransaction(txHash, _target, _data, _eta);

    return returnData;
  }
}