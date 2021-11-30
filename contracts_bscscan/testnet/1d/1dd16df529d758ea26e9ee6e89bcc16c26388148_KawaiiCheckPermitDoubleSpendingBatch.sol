/**
 *Submitted for verification at BscScan.com on 2021-11-30
*/

pragma solidity 0.6.12;

interface Signed {
  function checkPermitDoubleSpendingBatch(bytes32[] memory _datas) external view returns (bool[] memory);
}

contract KawaiiCheckPermitDoubleSpendingBatch {
  function checkPermitDoubleSpendingBatchOfSignedContract(Signed _signedContract, bytes32[] memory _data) external view returns (bool[] memory) {
    return Signed(_signedContract).checkPermitDoubleSpendingBatch(_data);
  }
}