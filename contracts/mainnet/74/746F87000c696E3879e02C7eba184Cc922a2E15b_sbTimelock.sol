// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import './SafeMath.sol';

contract sbTimelock {
  using SafeMath for uint256;

  event NewAdmin(address indexed newAdmin);
  event NewPendingAdmin(address indexed newPendingAdmin);
  event NewDelay(uint256 indexed newDelay);
  event CancelTransaction(
    bytes32 indexed txHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 eta
  );
  event ExecuteTransaction(
    bytes32 indexed txHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 eta
  );
  event QueueTransaction(
    bytes32 indexed txHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 eta
  );

  uint256 public constant GRACE_PERIOD = 14 days;
  uint256 public constant MINIMUM_DELAY = 2 days;
  uint256 public constant MAXIMUM_DELAY = 30 days;

  address public admin;
  address public pendingAdmin;
  uint256 public delay;

  bool internal initDone;

  mapping(bytes32 => bool) public queuedTransactions;

  function init(address admin_, uint256 delay_) public {
    require(!initDone, 'sbTimelock::init: Init has already been called.');
    require(delay_ >= MINIMUM_DELAY, 'sbTimelock::init: Delay must exceed minimum delay.');
    require(delay_ <= MAXIMUM_DELAY, 'sbTimelock::init: Delay must not exceed maximum delay.');

    admin = admin_;
    delay = delay_;
    initDone = true;
  }

  receive() external payable {}

  function setDelay(uint256 delay_) public {
    require(msg.sender == address(this), 'sbTimelock::setDelay: Call must come from sbTimelock.');
    require(delay_ >= MINIMUM_DELAY, 'sbTimelock::setDelay: Delay must exceed minimum delay.');
    require(delay_ <= MAXIMUM_DELAY, 'sbTimelock::setDelay: Delay must not exceed maximum delay.');
    delay = delay_;

    emit NewDelay(delay);
  }

  function acceptAdmin() public {
    require(msg.sender == pendingAdmin, 'sbTimelock::acceptAdmin: Call must come from pendingAdmin.');
    admin = msg.sender;
    pendingAdmin = address(0);

    emit NewAdmin(admin);
  }

  function setPendingAdmin(address pendingAdmin_) public {
    require(msg.sender == address(this), 'sbTimelock::setPendingAdmin: Call must come from sbTimelock.');
    pendingAdmin = pendingAdmin_;

    emit NewPendingAdmin(pendingAdmin);
  }

  function queueTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 eta
  ) public returns (bytes32) {
    require(msg.sender == admin, 'sbTimelock::queueTransaction: Call must come from admin.');
    require(
      eta >= getBlockTimestamp().add(delay),
      'sbTimelock::queueTransaction: Estimated execution block must satisfy delay.'
    );

    bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
    queuedTransactions[txHash] = true;

    emit QueueTransaction(txHash, target, value, signature, data, eta);
    return txHash;
  }

  function cancelTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 eta
  ) public {
    require(msg.sender == admin, 'sbTimelock::cancelTransaction: Call must come from admin.');

    bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
    queuedTransactions[txHash] = false;

    emit CancelTransaction(txHash, target, value, signature, data, eta);
  }

  function executeTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 eta
  ) public payable returns (bytes memory) {
    require(msg.sender == admin, 'sbTimelock::executeTransaction: Call must come from admin.');

    bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
    require(queuedTransactions[txHash], "sbTimelock::executeTransaction: Transaction hasn't been queued.");
    require(getBlockTimestamp() >= eta, "sbTimelock::executeTransaction: Transaction hasn't surpassed time lock.");
    require(getBlockTimestamp() <= eta.add(GRACE_PERIOD), 'sbTimelock::executeTransaction: Transaction is stale.');

    queuedTransactions[txHash] = false;

    bytes memory callData;

    if (bytes(signature).length == 0) {
      callData = data;
    } else {
      callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
    }

    // solium-disable-next-line security/no-call-value
    (bool success, bytes memory returnData) = target.call{ value: value }(callData);
    require(success, 'sbTimelock::executeTransaction: Transaction execution reverted.');

    emit ExecuteTransaction(txHash, target, value, signature, data, eta);

    return returnData;
  }

  function getBlockTimestamp() internal view returns (uint256) {
    // solium-disable-next-line security/no-block-members
    return block.timestamp;
  }
}
