// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import './IPearProof.sol';

// import 'hardhat/console.sol';
// Add support for multiple collection ids

contract ClaimFreeMinter {
  IPearProof public _pearproofAddress;
  address private _signerAddress;
  uint256 _collectionId;
  mapping(bytes32 => bool) private _claimedCodes;

  // Setting of the address has to be in the constructor and set only once.
  constructor(
    address pearproofAddress,
    address signerAddress,
    uint256 collectionId
  ) {
    _pearproofAddress = IPearProof(pearproofAddress);
    _signerAddress = signerAddress;
    _collectionId = collectionId;
  }

  function mint(string memory code, bytes memory signature) public {
    bytes32 codeKey = keccak256(abi.encodePacked(code));
    require(!_claimedCodes[codeKey], 'Code already used');
    require(verifySignature(code, signature), 'Invalid code');
    // require code and proof to return the public address
    // add claimed code to the mapping
    _pearproofAddress.safeMint(msg.sender, _collectionId);
    _claimedCodes[codeKey] = true;
  }

  function verifySignature(string memory code, bytes memory signature)
    public
    view
    returns (bool)
  {
    // We can simplify verification if the message is signed as a regular message and not through an eth-based tool
    bytes32 messageBytes = ethMessageHash(code);
    address recoverAddress = verify(messageBytes, signature);

    return recoverAddress == _signerAddress;
  }

  /**
   * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:" and hash the result
   */
  function ethMessageHash(string memory message)
    internal
    pure
    returns (bytes32)
  {
    return
      keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n6', message));
  }

  /*
   * @dev: Verify
   *
   */
  function verify(bytes32 h, bytes memory signature)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

    // Check the signature length
    if (signature.length != 65) {
      return (address(0));
    }

    // Divide the signature in r, s and v variables
    // ecrecover takes the signature parameters, and the only way to get them
    // currently is to use assembly.
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      r := mload(add(signature, 32))
      s := mload(add(signature, 64))
      v := byte(0, mload(add(signature, 96)))
    }

    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }

    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      // solium-disable-next-line arg-overflow
      return ecrecover(h, v, r, s);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface IPearProof {
  function safeMint(address to, uint256 id) external;
}