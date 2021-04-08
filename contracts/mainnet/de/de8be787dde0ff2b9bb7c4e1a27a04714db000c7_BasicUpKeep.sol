/**
 *Submitted for verification at Etherscan.io on 2021-04-07
*/

contract BasicUpKeep {
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
    //decide if an upkeep is needed and return bool accordingly
    return (shouldPerformUpkeep, bytesToSend);
  }

  function performUpkeep(bytes calldata data) external {
    receivedBytes = data;
    shouldPerformUpkeep = false;
    //do something useful here
  }
}