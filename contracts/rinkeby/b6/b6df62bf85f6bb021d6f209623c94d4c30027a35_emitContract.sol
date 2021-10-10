/**
 *Submitted for verification at Etherscan.io on 2021-10-09
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract emitContract {
  event forTesting(address testAddress, uint256 testUint256, string beHumble);

  function emitSomething() public {
      emit forTesting(0x0dd874F41cE844FcdaeBA33714B6197136D89B7F, 69, "lmao");
  }
}