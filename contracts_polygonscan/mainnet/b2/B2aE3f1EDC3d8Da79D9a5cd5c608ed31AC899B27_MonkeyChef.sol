pragma solidity 0.6.12;

contract MonkeyChef {
    function monkeyHelp() external view returns (uint) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
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