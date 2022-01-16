/**
 *Submitted for verification at Etherscan.io on 2022-01-16
*/

// File: contracts/utils/ECDSA.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.21 <0.6.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
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
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

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

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert("ECDSA: invalid signature 's' value");
        }

        if (v != 27 && v != 28) {
            revert("ECDSA: invalid signature 'v' value");
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// File: contracts/utils/Ownable.sol

pragma solidity >=0.4.21 <0.6.0;

contract Ownable {
    address private _contract_owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = msg.sender;
        _contract_owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _contract_owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_contract_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_contract_owner, newOwner);
        _contract_owner = newOwner;
    }
}

// File: contracts/core/market/interface/KeyVerifierInterface.sol

pragma solidity >=0.4.21 <0.6.0;
contract KeyVerifierInterface{
  function verify_pkey(bytes memory _pkey, bytes memory _pkey_sig) public view returns(bool);
}

// File: contracts/core/market/SignatureVerifier.sol

pragma solidity >=0.4.21 <0.6.0;


library SignatureVerifier{
  using ECDSA for bytes32;
  function verify_signature(bytes32 hash, bytes memory sig, bytes memory pkey) internal pure returns (bool){
    address expected = getAddressFromPublicKey(pkey);
    return hash.recover(sig) == expected;
  }

  function getAddressFromPublicKey(bytes memory _publicKey) internal pure returns (address addr) {
    bytes32 hash = keccak256(_publicKey);
    assembly {
      mstore(0, hash)
      addr := mload(0)
    }
  }

}

// File: contracts/core/market/SGXKeyVerifier.sol

pragma solidity >=0.4.21 <0.6.0;





contract SGXKeyVerifier is Ownable, KeyVerifierInterface{
  using ECDSA for bytes32;
  using SignatureVerifier for bytes;

  mapping (address => bool) public verifier_addrs;
  uint256 public available_verifiers_num;

  constructor() public{}

  event SetVerifierAddr(address addr, bool to_add);
  function set_verifier_addr(address addr, bool to_add) public onlyOwner{
    if(to_add && verifier_addrs[addr]){
      return ;
    }
    if(!to_add && !verifier_addrs[addr]){
      return ;
    }

    if(to_add){
      available_verifiers_num = available_verifiers_num + 1;
    }else{
      require(verifier_addrs[addr], "invalid to remove");
      available_verifiers_num = available_verifiers_num - 1;
    }
    verifier_addrs[addr] = to_add;
    emit SetVerifierAddr(addr, to_add);
  }

  function set_verifier_pkey(bytes memory _pkey, bool to_add) public onlyOwner{
    set_verifier_addr(_pkey.getAddressFromPublicKey(), to_add);
  }

  function verify_pkey(bytes memory _pkey, bytes memory _pkey_sig) public view returns(bool){
    bytes32 hash = keccak256(abi.encodePacked(_pkey)).toEthSignedMessageHash();
    address addr = hash.recover(_pkey_sig);
    return verifier_addrs[addr];
  }
}

contract SGXKeyVerifierFactory{
  event NewSGXKeyVerifier(address addr);
  function createSGXKeyVerifier() public returns(address){
    SGXKeyVerifier m = new SGXKeyVerifier();
    m.transferOwnership(msg.sender);
    emit NewSGXKeyVerifier(address(m));
    return address(m);
  }
}