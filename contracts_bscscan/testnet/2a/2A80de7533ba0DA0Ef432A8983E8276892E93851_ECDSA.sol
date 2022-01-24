// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

library ECDSA {
  function isMessageValid(bytes memory message) public pure returns (bool) {
    return message.length == 136;
  }

  function formMessage(address from, address to, uint amount, uint nonce) external pure 
    returns (bytes32)
  {
    bytes32 message = keccak256(abi.encodePacked(
      from,
      to, 
      amount,
      nonce
    ));
    return message;
  }

  /**
   * Accepts the (v,r,s) signature and the message and returns the 
   * address that signed the signature. It accounts for malleability issue
   * with the native ecrecover.
   */
  function getSigner(
    bytes32 message, 
    uint8 v,
    bytes32 r,
    bytes32 s
  ) private pure returns (address) {
    // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
    // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
    // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
    // signatures from current libraries generate a unique signature with an s-value in the lower half order.
    //
    // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
    // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
    // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
    // these malleable signatures as well.
    require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid signature 's' value");
    require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

    // If the signature is valid (and not malleable), return the signer address
    address signer = ecrecover(hashMessage(message), v, r, s);
    require(signer != address(0), "ECDSA:invalid signature");

    return signer;
  }

  function hashMessage(bytes32 message) internal pure returns (bytes32) {
    bytes memory prefix = "\x19Ethereum Signed Message:\n32";
    return keccak256(abi.encodePacked(prefix, message));
  }

  /**
    * @dev Returns the address that signed a hashed message (`hash`) with
    * `signature`. This address can then be used for verification purposes.
    *
    * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
    * this function rejects them by requiring the `s` value to be in the lower
    * half order, and the `v` value to be either 27 or 28.
    *
    * IMPORTANT: `hash` _must_ be the result of a hash operation for the
    * verification to be secure: it is possible to craft signatures that
    * recover to arbitrary addresses for non-hashed data. A safe way to ensure
    * this is by receiving a hash of the original message (which may otherwise
    * be too long), and then calling {toEthSignedMessageHash} on it.
    */
  function recoverAddress(
    bytes32 message, 
    bytes memory signature
  ) external view returns (address) {
    // Check the signature length
    require(signature.length == 65, "ECDSA: invalid signature length");

    // Divide the signature in r, s and v variables
    bytes32 r;
    bytes32 s;
    uint8 v;

    // ecrecover takes the signature parameters, and the only way to get them
    // currently is to use assembly.
    // solhint-disable-next-line no-inline-assembly
    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := byte(0, mload(add(signature, 0x60)))
    }

    return getSigner(message, v, r, s);
  }

  // layout of message :: bytes:
  // offset  0: 32 bytes :: uint256 - message length
  // offset 32: 20 bytes :: address - recipient address
  // offset 52: 32 bytes :: uint256 - value
  // offset 84: 32 bytes :: bytes32 - transaction hash
  // offset 116: 32 bytes :: uint256 - nonce
  // offset 136: 20 bytes :: address - contract address to prevent double spending

  // mload always reads 32 bytes.
  // so we can and have to start reading recipient at offset 20 instead of 32.
  // if we were to read at 32 the address would contain part of value and be corrupted.
  // when reading from offset 20 mload will read 12 bytes (most of them zeros) followed
  // by the 20 recipient address bytes and correctly convert it into an address.
  // this saves some storage/gas over the alternative solution
  // which is padding address to 32 bytes and reading recipient at offset 32.
  // for more details see discussion in:
  // https://github.com/paritytech/parity-bridge/issues/61
  function parseMessage(bytes memory message) internal view returns (
    address recipient, 
    uint256 amount, 
    uint256 txHash,
    uint256 nonce,
    address contractAddress
  ) {
    require(isMessageValid(message), "ECDSA: parse error invalid message");
    
    assembly {
      recipient := mload(add(message, 20))
      amount := mload(add(message, 52))
      txHash := mload(add(message, 84))
      nonce := mload(add(message, 116))
      contractAddress := mload(add(message, 136))
    }
  }
}