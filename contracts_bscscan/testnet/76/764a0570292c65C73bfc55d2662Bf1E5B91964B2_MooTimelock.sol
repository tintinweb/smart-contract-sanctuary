// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

contract MooTimelock {
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
  uint256 public constant MINIMUM_DELAY = 1 minutes;
  uint256 public constant MAXIMUM_DELAY = 30 days;

  address public admin;
  address public pendingAdmin;
  uint256 public delay;
  bool public adminInitialized;

  mapping(bytes32 => bool) public queuedTransactions;

  constructor(address admin_, uint256 delay_) {
    require(
      delay_ >= MINIMUM_DELAY,
      "Timelock: Lower than min"
    );
    require(
      delay_ <= MAXIMUM_DELAY,
      "Timelock: Grater than max"
    );

    admin = admin_;
    delay = delay_;
    adminInitialized = false;
  }

  receive() external payable {}

  function setDelay(uint256 delay_) external {
    require(
      msg.sender == address(this),
      "Timelock: Unauthorized"
    );
    require(
      delay_ >= MINIMUM_DELAY,
      "Timelock: Lower than min"
    );
    require(
      delay_ <= MAXIMUM_DELAY,
      "Timelock: Grater than max"
    );
    delay = delay_;

    emit NewDelay(delay);
  }

  function acceptAdmin() external {
    require(
      msg.sender == pendingAdmin,
      "Timelock: Unauthorized"
    );
    admin = msg.sender;
    pendingAdmin = address(0);

    emit NewAdmin(admin);
  }

  function setPendingAdmin(address pendingAdmin_) external {
    if (adminInitialized) {
      require(
        msg.sender == address(this),
        "Timelock: Unauthorized"
      );
    } else {
      require(
        msg.sender == admin,
        "Timelock: Unauthorized"
      );
      adminInitialized = true;
    }
    pendingAdmin = pendingAdmin_;

    emit NewPendingAdmin(pendingAdmin);
  }

  function queueTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 eta
  ) external returns (bytes32) {
    require(
      msg.sender == admin,
      "Timelock: Unauthorized"
    );
    require(
      eta >= getBlockTimestamp() + delay,
      "Timelock: Invalid eta and delay"
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
  ) external {
    require(
      msg.sender == admin,
      "Timelock: Unauthorized"
    );

    bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
    queuedTransactions[txHash] = false;

    emit CancelTransaction(txHash, target, value, signature, data, eta);
  }

  function _getRevertMsg(bytes memory _returnData)
    internal
    pure
    returns (string memory)
  {
    if (_returnData.length < 68) return "Transaction reverted silently";

    assembly {
      _returnData := add(_returnData, 0x04)
    }
    return abi.decode(_returnData, (string));
  }

  function executeTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 eta
  ) external payable returns (bytes memory) {
    require(
      msg.sender == admin,
      "Timelock: Unauthorized"
    );

    bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
    require(
      queuedTransactions[txHash],
      "Timelock: Invalid tx queue"
    );
    require(
      getBlockTimestamp() >= eta,
      "Timelock: Not now"
    );
    require(
      getBlockTimestamp() <= eta + GRACE_PERIOD,
      "Timelock: Invalid time"
    );

    queuedTransactions[txHash] = false;

    bytes memory callData;

    if (bytes(signature).length == 0) {
      callData = data;
    } else {
      callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
    }

    // solium-disable-next-line security/no-call-value
    (bool success, bytes memory returnData) = target.call{ value: value }(
      callData
    );
    require(success, _getRevertMsg(returnData));

    emit ExecuteTransaction(txHash, target, value, signature, data, eta);

    return returnData;
  }

  function getBlockTimestamp() internal view returns (uint256) {
    // solium-disable-next-line security/no-block-members
    return block.timestamp;
  }
}