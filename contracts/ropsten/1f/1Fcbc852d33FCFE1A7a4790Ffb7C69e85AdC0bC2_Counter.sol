pragma solidity 0.5.12;

contract Counter {
  uint256 count = 0;

  event CountedTo(uint256 number);

  function countUp() public {
    uint256 newCount = count + 1;
    require(newCount > count, "Uint256 overflow");
    count = newCount;
    emit CountedTo(count);
  }

  function countDown() public {
    uint256 newCount = count - 1;
    require(newCount < count, "Uint256 underflow");
    count = newCount;
    emit CountedTo(count);
  }

  function getCount() public view returns (uint256) {
    return count;
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