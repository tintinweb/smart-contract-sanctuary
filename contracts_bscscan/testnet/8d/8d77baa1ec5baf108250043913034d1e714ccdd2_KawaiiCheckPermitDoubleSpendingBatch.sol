/**
 *Submitted for verification at BscScan.com on 2021-11-30
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.12;

interface Signed {
  function permitDoubleSpending(bytes32 _data) external view returns(bool);
}

contract KawaiiCheckPermitDoubleSpendingBatch {
  function checkPermitDoubleSpendingBatchOfSignedContract(Signed _signedContract, bytes32[] memory _datas) external view returns (bool[] memory) {
    require (_datas.length > 0, "data must not null");
    bool[] memory res = new bool[](_datas.length);
    for (uint256 i = 0; i < res.length; i ++) {
      res[i] = Signed(_signedContract).permitDoubleSpending(_datas[i]);
    }
    return res;
  }
}