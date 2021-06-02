contract Upkeep {
  bool public shouldPerformUpkeep;
  bytes public bytesToSend;
  bytes public receivedBytes;
  function setShouldPerformUpkeep(bool _should) public {
    shouldPerformUpkeep = _should;
  }
  function setBytesToSend(bytes memory _bytes) public {
    bytesToSend = _bytes;
  }
  function checkUpkeep(bytes calldata data) external returns (bool, bytes memory) {
    return (shouldPerformUpkeep, bytesToSend);
  }
  function performUpkeep(bytes calldata data) external {
    shouldPerformUpkeep = false;
    receivedBytes = data;
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