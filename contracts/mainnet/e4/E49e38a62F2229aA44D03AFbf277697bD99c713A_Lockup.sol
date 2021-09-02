// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
}


contract Lockup {
  address public immutable recipient;
  address public immutable token;
  uint256 public immutable unlockAt;
  
  constructor(address _recipient, address _token, uint256 lockDuration) {
    recipient = _recipient;
    token = _token;
    unlockAt = block.timestamp + lockDuration;
  }

  function release() external {
    require(block.timestamp >= unlockAt, "Timelock has not passed");
    IERC20(token).transfer(recipient, IERC20(token).balanceOf(address(this)));
  }
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "none",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}