/**
 *Submitted for verification at Etherscan.io on 2019-07-06
*/

pragma solidity 0.5.9;

interface IHomeWork {
  function isDeployable(bytes32) external returns (bool);
}


contract DeployableChecker {
  address private constant HOMEWORK = address(
    0x0000000000001b84b1cb32787B0D64758d019317
  );

  function areDeployable(bytes32[] calldata keys) external returns (bool[] memory deployable) {
    IHomeWork homework = IHomeWork(HOMEWORK);
    for (uint256 i = 0; i < keys.length; i++) {
      deployable[i] = homework.isDeployable(keys[i]);
    }
  }
}