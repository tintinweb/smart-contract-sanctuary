// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Signature {
  address public owner = msg.sender;
  event Original(bytes32 _hash);
  event ABIEncoded(bytes32 _abiEncoded);
  event ABIPacked(bytes32 _abiPacked);
  event Restored(bytes32 _message, address _address);

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

  function recover(
    bytes32 _message,
    uint8 _sigV,
    bytes32 _sigR,
    bytes32 _sigS
  ) public restricted {
    address addressFromSig = ecrecover(_message, _sigV, _sigR, _sigS);
    emit Restored(_message, addressFromSig);
  }
}

