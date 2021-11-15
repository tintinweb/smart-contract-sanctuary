contract InvariantCheckUpkeep {
  bool public shouldPerformUpkeep;
  bytes public bytesToSend;
  bytes public receivedBytes;
  uint public value;

  constructor (uint _value) public {
    value = _value;
  }

  function setValue(uint _value) public {
    value = _value;
  }

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
  function getLastBytesSent() external returns (bytes memory) {
    return bytesToSend;
  }
}

