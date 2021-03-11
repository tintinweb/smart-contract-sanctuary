/**
 *Submitted for verification at Etherscan.io on 2021-03-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

interface ITestContract {
    function requestRandomness() external;
    function getNextHash() external view returns (bytes32);
    function getPendingRequest() external view returns (address);
    function removePendingRequest(address adr, bytes32 nextHash) external;
    function provideRandomness(uint256 random, bytes32 nextHash) external;
}

contract TestContract is ITestContract {

  address public requestor;
  bytes32 public expectedNextHash;
  uint256 public randomNum;

  constructor() {
    expectedNextHash = 0x387a8233c96e1fc0ad5e284353276177af2186e7afa85296f106336e376669f7;
  }

  function requestRandomness() external override {
    requestor = msg.sender;
  }

  function getNextHash() external override view returns (bytes32) {
    return expectedNextHash;
  }

  function getPendingRequest() external override view returns (address) {
    return requestor;
  }

  function removePendingRequest(address adr, bytes32 nextHash) external override {
    require(adr == requestor, "Error");
    requestor = address(0);
    expectedNextHash = nextHash;
  }

  function provideRandomness(uint256 random, bytes32 nextHash) external override {
    require(keccak256(abi.encodePacked(random)) == expectedNextHash, "Error");
    requestor = address(0);
    randomNum = random;
    expectedNextHash = nextHash;
  }
}