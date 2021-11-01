// COPIED FROM https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/GovernorAlpha.sol
// Copyright 2020 Compound Labs, Inc.
// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// Ctrl+f for XXX to see all the modifications.

// XXX: pragma solidity ^0.5.16;
pragma solidity 0.6.6;

import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

contract Timelock is ReentrancyGuard {
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
  uint256 public constant MINIMUM_DELAY = 1 days;
  uint256 public constant MAXIMUM_DELAY = 30 days;

  address public admin;
  address public pendingAdmin;
  uint256 public delay;
  bool public admin_initialized;

  mapping(bytes32 => bool) public queuedTransactions;

  // delay_ in seconds
  constructor(address admin_, uint256 delay_) public {
    require(delay_ >= MINIMUM_DELAY, "Timelock::constructor: Delay must exceed minimum delay.");
    require(delay_ <= MAXIMUM_DELAY, "Timelock::constructor: Delay must not exceed maximum delay.");

    admin = admin_;
    delay = delay_;
    admin_initialized = false;
  }

  // XXX: function() external payable { }
  receive() external payable {}

  function setDelay(uint256 delay_) external {
    require(msg.sender == address(this), "Timelock::setDelay: Call must come from Timelock.");
    require(delay_ >= MINIMUM_DELAY, "Timelock::setDelay: Delay must exceed minimum delay.");
    require(delay_ <= MAXIMUM_DELAY, "Timelock::setDelay: Delay must not exceed maximum delay.");
    delay = delay_;

    emit NewDelay(delay);
  }

  function acceptAdmin() external {
    require(msg.sender == pendingAdmin, "Timelock::acceptAdmin: Call must come from pendingAdmin.");
    admin = msg.sender;
    pendingAdmin = address(0);

    emit NewAdmin(admin);
  }

  function setPendingAdmin(address pendingAdmin_) external {
    // allows one time setting of admin for deployment purposes
    if (admin_initialized) {
      require(msg.sender == address(this), "Timelock::setPendingAdmin: Call must come from Timelock.");
    } else {
      require(msg.sender == admin, "Timelock::setPendingAdmin: First call must come from admin.");
      admin_initialized = true;
    }
    pendingAdmin = pendingAdmin_;

    emit NewPendingAdmin(pendingAdmin);
  }

  function queueTransaction(
    address target,
    uint256 value,
    string calldata signature,
    bytes calldata data,
    uint256 eta
  ) external returns (bytes32) {
    require(msg.sender == admin, "Timelock::queueTransaction: Call must come from admin.");
    require(
      eta >= getBlockTimestamp().add(delay),
      "Timelock::queueTransaction: Estimated execution block must satisfy delay."
    );

    bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
    queuedTransactions[txHash] = true;

    emit QueueTransaction(txHash, target, value, signature, data, eta);
    return txHash;
  }

  function cancelTransaction(
    address target,
    uint256 value,
    string calldata signature,
    bytes calldata data,
    uint256 eta
  ) external {
    require(msg.sender == admin, "Timelock::cancelTransaction: Call must come from admin.");

    bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
    queuedTransactions[txHash] = false;

    emit CancelTransaction(txHash, target, value, signature, data, eta);
  }

  // XXX: add _getRevertMsg to get revert message from call stack
  function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
    // If the _res length is less than 68, then the transaction failed silently (without a revert message)
    if (_returnData.length < 68) return "Transaction reverted silently";

    assembly {
      // Slice the sighash.
      _returnData := add(_returnData, 0x04)
    }
    return abi.decode(_returnData, (string)); // All that remains is the revert string
  }

  function executeTransaction(
    address target,
    uint256 value,
    string calldata signature,
    bytes calldata data,
    uint256 eta
  ) external payable nonReentrant returns (bytes memory) {
    require(msg.sender == admin, "Timelock::executeTransaction: Call must come from admin.");

    bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
    require(queuedTransactions[txHash], "Timelock::executeTransaction: Transaction hasn't been queued.");
    require(getBlockTimestamp() >= eta, "Timelock::executeTransaction: Transaction hasn't surpassed time lock.");
    require(getBlockTimestamp() <= eta.add(GRACE_PERIOD), "Timelock::executeTransaction: Transaction is stale.");

    queuedTransactions[txHash] = false;

    bytes memory callData;

    if (bytes(signature).length == 0) {
      callData = data;
    } else {
      callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
    }

    // solium-disable-next-line security/no-call-value
    (bool success, bytes memory returnData) = target.call{ value: value }(callData);
    require(success, _getRevertMsg(returnData));

    emit ExecuteTransaction(txHash, target, value, signature, data, eta);

    return returnData;
  }

  function getBlockTimestamp() internal view returns (uint256) {
    // solium-disable-next-line security/no-block-members
    return block.timestamp;
  }
}