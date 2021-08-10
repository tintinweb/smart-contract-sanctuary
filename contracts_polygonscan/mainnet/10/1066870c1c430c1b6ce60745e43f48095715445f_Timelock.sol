/**
 *Submitted for verification at polygonscan.com on 2021-08-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

library SafeMath {
  function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    uint256 c = a + b;
    if (c < a) return (false, 0);
    return (true, c);
  }
  function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    if (b > a) return (false, 0);
    return (true, a - b);
  }
  function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    if (a == 0) return (true, 0);
    uint256 c = a * b;
    if (c / a != b) return (false, 0);
    return (true, c);
  }
  function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    if (b == 0) return (false, 0);
    return (true, a / b);
  }
  function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    if (b == 0) return (false, 0);
    return (true, a % b);
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "error");
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "error");
    return a - b;
  }
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) return 0;
    uint256 c = a * b;
    require(c / a == b, "error");
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "error");
    return a / b;
  }
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "error");
    return a % b;
  }
  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    return a - b;
  }
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    return a / b;
  }
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    return a % b;
  }
}
contract Timelock {
  using SafeMath for uint;
  event NewAdmin(address indexed newAdmin);
  event NewPendingAdmin(address indexed newPendingAdmin);
  event NewDelay(uint indexed newDelay);
  event CancelTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint eta);
  event ExecuteTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint eta);
  event QueueTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature, bytes data, uint eta);
  uint public constant GRACE_PERIOD = 14 days;
  uint public constant MINIMUM_DELAY = 2 hours;
  uint public constant MAXIMUM_DELAY = 30 days;
  address public admin;
  address public pendingAdmin;
  uint public delay;
  bool public admin_initialized;
  mapping (bytes32 => bool) public queuedTransactions;
  constructor(address admin_, uint delay_) public {
    require(delay_ >= MINIMUM_DELAY, "error");
    require(delay_ <= MAXIMUM_DELAY, "error");
    admin = admin_;
    delay = delay_;
    admin_initialized = false;
  }
  receive() external payable { }
  function setDelay(uint delay_) public {
    require(msg.sender == address(this), "error");
    require(delay_ >= MINIMUM_DELAY, "error");
    require(delay_ <= MAXIMUM_DELAY, "error");
    delay = delay_;
    emit NewDelay(delay);
  }
  function acceptAdmin() public {
      require(msg.sender == pendingAdmin, "error");
      admin = msg.sender;
      pendingAdmin = address(0);
      emit NewAdmin(admin);
  }
  function setPendingAdmin(address pendingAdmin_) public {
    if (admin_initialized) {
        require(msg.sender == address(this), "error");
    } else {
        require(msg.sender == admin, "error");
        admin_initialized = true;
    }
    pendingAdmin = pendingAdmin_;
    emit NewPendingAdmin(pendingAdmin);
  }
  function queueTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public returns (bytes32) {
    require(msg.sender == admin, "error");
    require(eta >= getBlockTimestamp().add(delay), "error");
    bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
    queuedTransactions[txHash] = true;
    emit QueueTransaction(txHash, target, value, signature, data, eta);
    return txHash;
  }
  function cancelTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public {
    require(msg.sender == admin, "error");
    bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
    queuedTransactions[txHash] = false;
    emit CancelTransaction(txHash, target, value, signature, data, eta);
  }
  function executeTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public payable returns (bytes memory) {
    require(msg.sender == admin, "error");
    bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
    require(queuedTransactions[txHash], "error");
    require(getBlockTimestamp() >= eta, "error");
    require(getBlockTimestamp() <= eta.add(GRACE_PERIOD), "error");
    queuedTransactions[txHash] = false;
    bytes memory callData;
    if (bytes(signature).length == 0) {
      callData = data;
    } else {
      callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
    }
    // solium-disable-next-line security/no-call-value
    (bool success, bytes memory returnData) = target.call{value: value}(callData);
    require(success, "error");
    emit ExecuteTransaction(txHash, target, value, signature, data, eta);
    return returnData;
  }
  function getBlockTimestamp() internal view returns (uint) {
    // solium-disable-next-line security/no-block-members
    return block.timestamp;
  }
}