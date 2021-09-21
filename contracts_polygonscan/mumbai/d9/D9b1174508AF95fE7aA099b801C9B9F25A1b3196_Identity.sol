/**
 *Submitted for verification at polygonscan.com on 2021-09-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library Identity {
  struct IdentityStruct {
    address account;
    string email;
    uint256 timestamp;
  }

  bytes32 constant private TYPE_HASH = keccak256(
    "Identity(address account,string email,uint256 timestamp)"
  );

  function create(
    address account,
    string memory email,
    uint256 timestamp
  ) internal pure returns (IdentityStruct memory) {
    return Identity.IdentityStruct({
      account: account,
      email: email,
      timestamp: timestamp
    });
  }

  function hash(IdentityStruct memory identity) internal pure returns (bytes32) {
    return keccak256(
      abi.encode(
        TYPE_HASH,
        identity.account,
        // "The dynamic values bytes and string are encoded as a keccak256 hash
        // of their contents".
        // See https://eips.ethereum.org/EIPS/eip-712#definition-of-encodedata
        keccak256(bytes(identity.email)),
        identity.timestamp
      )
    );
  }
}