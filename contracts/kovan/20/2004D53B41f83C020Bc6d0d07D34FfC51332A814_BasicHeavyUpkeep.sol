/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

pragma solidity 0.7.6;
contract BasicHeavyUpkeep {
  bool public shouldPerformUpkeep;
  bytes public bytesToSend;
  bytes public receivedBytes;
  uint256 public checkGasToUse;
  uint256 public performGasToUse;
  constructor(uint256 _checkGasToUse, uint256 _performGasToUse) {
    checkGasToUse = _checkGasToUse;
    performGasToUse = _performGasToUse;
  }
  function setShouldPerformUpkeep(bool _should) public {
    shouldPerformUpkeep = _should;
  }
  function setBytesToSend(bytes memory _bytes) public {
    bytesToSend = _bytes;
  }
  function checkUpkeep(bytes calldata data) external returns (bool, bytes memory) {
    uint256 initialGas = gasleft();
    while (initialGas - gasleft() < checkGasToUse) {
      // keep in loop
    }
    return (shouldPerformUpkeep, bytesToSend);
  }
  function performUpkeep(bytes calldata data) external {
    uint256 initialGas = gasleft();
    // shouldPerformUpkeep = false;
    receivedBytes = data;
    while (initialGas - gasleft() < performGasToUse) {
      // keep in loop
    }
  }
}