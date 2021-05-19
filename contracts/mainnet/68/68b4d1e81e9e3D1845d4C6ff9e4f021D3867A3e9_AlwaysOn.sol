/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

contract AlwaysOn {
  bool public shouldPerformUpkeep;
  bytes public bytesToSend;
  bytes public receivedBytes;

  function checkUpkeep(bytes calldata data) external view returns (bool, bytes memory) {
    //decide if an upkeep is needed and return bool accordingly
    return (shouldPerformUpkeep, bytesToSend);
  }

  function performUpkeep(bytes calldata data) external {
    receivedBytes = data;
    //do something useful here
  }

  function setShouldPerformUpkeep(bool _should) public {
    shouldPerformUpkeep = _should;
  }

  function setBytesToSend(bytes memory _bytes) public {
    bytesToSend = _bytes;
  }
}