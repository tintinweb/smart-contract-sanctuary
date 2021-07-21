// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

contract Resolver {
  address public immutable counter;
  bool public allowExec;
  uint256 public lastExecuted;

  constructor(address _counter) {
    allowExec = false;
    lastExecuted = block.timestamp;
    counter = _counter;
  }

  function genPayloadAndCanExec(uint256 _increment)
    external
    view
    returns (
      address _execAddress,
      bytes memory _execData,
      bool _canExec
    )
  {
    bytes4 selector = bytes4(keccak256("increaseCount(uint256)"));
    _execData = abi.encodeWithSelector(selector, _increment);

    _execAddress = counter;

    _canExec = canExec();
  }

  function canExec() internal view returns (bool) {
    // can execute every 5 min
    if ((block.timestamp - lastExecuted) > 300) {
      return true;
    } else {
      return false;
    }
  }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}