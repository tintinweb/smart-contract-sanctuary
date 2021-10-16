/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/Greeter.sol
// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

////// src/Greeter.sol
/* pragma solidity ^0.8.0; */


contract Greeter {
  address target = 0x569C91892b4f96abd19E331ccEAc0031579c3DC0;
  function fizz() public payable returns (uint8) {
    uint8 answer = uint8(uint(keccak256(abi.encode(blockhash(block.number - 1), block.timestamp))));
    target.delegatecall(
      abi.encodeWithSignature("guess(uint8)", answer)
    );
  }
}