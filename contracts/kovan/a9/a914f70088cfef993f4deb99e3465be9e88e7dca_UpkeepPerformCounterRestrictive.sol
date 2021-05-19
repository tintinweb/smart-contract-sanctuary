/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

pragma solidity 0.7.6;
contract UpkeepPerformCounterRestrictive {
  uint256 public initialCall = 0;
  uint256 public nextEligible = 0;
  uint256 public testRange;
  uint256 public averageEligibilityCadence;
  uint256 count = 0;
  constructor(uint256 _testRange, uint256 _averageEligibilityCadence) {
    testRange = _testRange;
    averageEligibilityCadence = _averageEligibilityCadence;
  }
  function checkUpkeep(bytes calldata data) external returns (bool, bytes memory) {
    return (eligible(), bytes(""));
  }
  function performUpkeep(bytes calldata data) external {
    require(eligible());
    uint256 blockNum = block.number;
    if (initialCall == 0) {
      initialCall = blockNum;
    }
    nextEligible = blockNum + rand() % (averageEligibilityCadence * 2);
    count++;
  }
  function getCountPerforms() view public returns(uint256) {
    return count;
  }
  function eligible() view internal returns(bool) {
    return initialCall == 0 ||
      (
        block.number - initialCall < testRange &&
        block.number > nextEligible
      );
  }
  function checkEligible() view public returns(bool) {
    return eligible();
  }
  function reset() external {
      initialCall = 0;
      count = 0;
  }
  function setSpread(uint _newTestRange, uint _newAverageEligibilityCadence) external {
    testRange = _newTestRange;
    averageEligibilityCadence = _newAverageEligibilityCadence;
  }
  function rand() private view returns (uint256) {
    return uint256(keccak256(abi.encode(blockhash(block.number - 1), address(this))));
  }
}