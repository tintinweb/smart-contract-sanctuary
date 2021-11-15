// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Signature {
  address public owner = msg.sender;
  event Original(bytes32 _hash);
  event ABIEncoded(bytes32 _abiEncoded);
  event ABIPacked(bytes32 _abiPacked);

  modifier restricted() {
    require(
      msg.sender == owner,
      "This function is restricted to the contract's owner"
    );
    _;
  }

  function getHash(bytes32 _hash) public restricted {
    bytes32 _abiEncoded = keccak256(abi.encode(_hash));
    bytes32 _abiPacked = keccak256(abi.encodePacked(_hash));
    emit Original(_hash);
    emit ABIEncoded(_abiEncoded);
    emit ABIPacked(_abiPacked);
  }
}

