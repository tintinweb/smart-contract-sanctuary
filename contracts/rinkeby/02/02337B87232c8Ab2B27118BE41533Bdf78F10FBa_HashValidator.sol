/**
 *Submitted for verification at Etherscan.io on 2021-07-12
*/

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0;

contract HashValidator {
  function getHash(string memory proposalId, bytes32[] memory txHashes)
    public
    pure
    returns (bytes32)
  {
    string memory question = buildQuestion(proposalId, txHashes);
    bytes32 questionHash = keccak256(bytes(question));
    return questionHash;
  }

  /// @dev Build the question by combining the proposalId and the hex string of the hash of the txHashes
  /// @param proposalId Id of the proposal that proposes to execute the transactions represented by the txHashes
  /// @param txHashes EIP-712 Hashes of the transactions that should be executed
  function buildQuestion(string memory proposalId, bytes32[] memory txHashes)
    public
    pure
    returns (string memory)
  {
    string memory txsHash =
      bytes32ToAsciiString(keccak256(abi.encodePacked(txHashes)));
    return string(abi.encodePacked(proposalId, bytes3(0xe2909f), txsHash));
  }

  function bytes32ToAsciiString(bytes32 _bytes)
    internal
    pure
    returns (string memory)
  {
    bytes memory s = new bytes(64);
    for (uint256 i = 0; i < 32; i++) {
      uint8 b = uint8(bytes1(_bytes << (i * 8)));
      uint8 hi = uint8(b) / 16;
      uint8 lo = uint8(b) % 16;
      s[2 * i] = char(hi);
      s[2 * i + 1] = char(lo);
    }
    return string(s);
  }

  function char(uint8 b) internal pure returns (bytes1 c) {
    if (b < 10) return bytes1(b + 0x30);
    else return bytes1(b + 0x57);
  }
}