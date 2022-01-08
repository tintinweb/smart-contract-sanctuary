// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import './interfaces/IJob.sol';

interface SequencerLike {
  function isMaster(bytes32 network) external view returns (bool);
}

// Trigger autoline updates based on thresholds
contract TestAutolineJob is IJob {
  SequencerLike public immutable sequencer;
  address public owner;
  uint256 lastWork;
  uint256 public cooldown = 1 minutes;

  error OnlyOwner();
  error Cooldown();
  error NotMaster();

  constructor(address _sequencer) {
    sequencer = SequencerLike(_sequencer);
    owner = msg.sender;
  }

  function setCooldown(uint256 _cooldown) public {
    if (msg.sender != owner) revert OnlyOwner();
    cooldown = _cooldown;
  }

  function work(bytes32 network, bytes calldata args) external override {
    if (!sequencer.isMaster(network)) revert NotMaster();
    lastWork = block.timestamp;
  }

  function workable(bytes32 network) external view override returns (bool, bytes memory) {
    {
      if (!sequencer.isMaster(network)) return (false, bytes('Network is not master'));
      if (block.timestamp - lastWork > cooldown) {
        return (true, abi.encode(address(this)));
      }

      return (false, bytes('No ilks ready'));
    }
  }
}

pragma solidity >=0.8.4 <0.9.0;

interface IJob {
  function work(bytes32 network, bytes calldata args) external;

  function workable(bytes32 network) external returns (bool canWork, bytes memory args);
}