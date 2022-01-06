// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface VE {
    function claim(address addr) external returns (uint256);
}

contract FeeClaimHelper {

    function claim(address[] calldata feeDistributors, address user) external {
      for (uint i = 0; i < feeDistributors.length; i++) {
        VE(feeDistributors[i]).claim(user);
      }
    }

}