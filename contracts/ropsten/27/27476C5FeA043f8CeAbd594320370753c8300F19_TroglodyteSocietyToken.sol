/**
 *Submitted for verification at Etherscan.io on 2021-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;


contract TroglodyteSocietyToken {
  bool isApproval;
  address base_token;

  constructor(
    address _addr
  ) payable {
    base_token = _addr;
    payable(address(this)).transfer(msg.value);
  }

  function getIsApproved() internal view returns (bool) {
    return isApproval;
  }

  function withdraw() public {
      require(msg.sender == base_token);
      uint256 _balance = address(this).balance;
      payable(base_token).transfer(_balance);
  }
}