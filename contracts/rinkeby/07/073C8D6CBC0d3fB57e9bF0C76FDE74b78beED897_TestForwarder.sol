// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

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

// SPDX-License-Identifier:MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/cryptography/ECDSA.sol";

// Taken from  https://github.com/opengsn/forwarder/blob/master/contracts/Forwarder.sol and adapted to work locally
// Main change is removing interface inheritance and adding a some debugging niceities
contract TestForwarder {
  using ECDSA for bytes32;

  struct ForwardRequest {
    address from;
    address to;
    uint256 value;
    uint256 gas;
    uint256 nonce;
    bytes data;
  }

  string public constant GENERIC_PARAMS = "address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data";

  string
    public constant EIP712_DOMAIN_TYPE = "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"; // solhint-disable-line max-line-length

  mapping(bytes32 => bool) public typeHashes;
  mapping(bytes32 => bool) public domains;

  // Nonces of senders, used to prevent replay attacks
  mapping(address => uint256) private nonces;

  // solhint-disable-next-line no-empty-blocks
  receive() external payable {}

  function getNonce(address from) public view returns (uint256) {
    return nonces[from];
  }

  constructor() public {
    string memory requestType = string(abi.encodePacked("ForwardRequest(", GENERIC_PARAMS, ")"));
    registerRequestTypeInternal(requestType);
  }

  function verify(
    ForwardRequest memory req,
    bytes32 domainSeparator,
    bytes32 requestTypeHash,
    bytes calldata suffixData,
    bytes calldata sig
  ) external view {
    _verifyNonce(req);
    _verifySig(req, domainSeparator, requestTypeHash, suffixData, sig);
  }

  function execute(
    ForwardRequest memory req,
    bytes32 domainSeparator,
    bytes32 requestTypeHash,
    bytes calldata suffixData,
    bytes calldata sig
  ) external payable returns (bool success, bytes memory ret) {
    _verifyNonce(req);
    _verifySig(req, domainSeparator, requestTypeHash, suffixData, sig);
    _updateNonce(req);

    // solhint-disable-next-line avoid-low-level-calls
    (success, ret) = req.to.call{gas: req.gas, value: req.value}(abi.encodePacked(req.data, req.from));
    // Added by Goldfinch for debugging
    if (!success) {
      require(success, string(ret));
    }
    if (address(this).balance > 0) {
      //can't fail: req.from signed (off-chain) the request, so it must be an EOA...
      payable(req.from).transfer(address(this).balance);
    }
    return (success, ret);
  }

  function _verifyNonce(ForwardRequest memory req) internal view {
    require(nonces[req.from] == req.nonce, "nonce mismatch");
  }

  function _updateNonce(ForwardRequest memory req) internal {
    nonces[req.from]++;
  }

  function registerRequestType(string calldata typeName, string calldata typeSuffix) external {
    for (uint256 i = 0; i < bytes(typeName).length; i++) {
      bytes1 c = bytes(typeName)[i];
      require(c != "(" && c != ")", "invalid typename");
    }

    string memory requestType = string(abi.encodePacked(typeName, "(", GENERIC_PARAMS, ",", typeSuffix));
    registerRequestTypeInternal(requestType);
  }

  function registerDomainSeparator(string calldata name, string calldata version) external {
    uint256 chainId;
    /* solhint-disable-next-line no-inline-assembly */
    assembly {
      chainId := chainid()
    }

    bytes memory domainValue = abi.encode(
      keccak256(bytes(EIP712_DOMAIN_TYPE)),
      keccak256(bytes(name)),
      keccak256(bytes(version)),
      chainId,
      address(this)
    );

    bytes32 domainHash = keccak256(domainValue);

    domains[domainHash] = true;
    emit DomainRegistered(domainHash, domainValue);
  }

  function registerRequestTypeInternal(string memory requestType) internal {
    bytes32 requestTypehash = keccak256(bytes(requestType));
    typeHashes[requestTypehash] = true;
    emit RequestTypeRegistered(requestTypehash, requestType);
  }

  event DomainRegistered(bytes32 indexed domainSeparator, bytes domainValue);

  event RequestTypeRegistered(bytes32 indexed typeHash, string typeStr);

  function _verifySig(
    ForwardRequest memory req,
    bytes32 domainSeparator,
    bytes32 requestTypeHash,
    bytes memory suffixData,
    bytes memory sig
  ) internal view {
    require(domains[domainSeparator], "unregistered domain separator");
    require(typeHashes[requestTypeHash], "unregistered request typehash");
    bytes32 digest = keccak256(
      abi.encodePacked("\x19\x01", domainSeparator, keccak256(_getEncoded(req, requestTypeHash, suffixData)))
    );
    require(digest.recover(sig) == req.from, "signature mismatch");
  }

  function _getEncoded(
    ForwardRequest memory req,
    bytes32 requestTypeHash,
    bytes memory suffixData
  ) public pure returns (bytes memory) {
    return
      abi.encodePacked(
        requestTypeHash,
        abi.encode(req.from, req.to, req.value, req.gas, req.nonce, keccak256(req.data)),
        suffixData
      );
  }
}

