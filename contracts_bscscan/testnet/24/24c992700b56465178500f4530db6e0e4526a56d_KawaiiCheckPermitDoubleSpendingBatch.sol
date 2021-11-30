/**
 *Submitted for verification at BscScan.com on 2021-11-30
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.12;

interface Signed {
  function checkPermitDoubleSpendingBatch(bytes32[] memory _datas) external view returns (bool[] memory);
}

contract KawaiiCheckPermitDoubleSpendingBatch {
  function checkPermitDoubleSpendingBatchOfSignedContract(Signed _signedContract, bytes32[] memory _data) external view returns (bool[] memory) {
    require (_data.length > 0, "data must not null");
    bool[] memory res = new bool[](_data.length);
    res =  Signed(_signedContract).checkPermitDoubleSpendingBatch(_data);
    return res;
  }
}