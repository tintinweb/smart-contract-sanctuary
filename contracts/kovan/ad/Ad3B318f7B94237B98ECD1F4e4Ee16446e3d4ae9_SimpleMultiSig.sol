/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

// SPDX-License-Identifier: (Apache-2.0 AND MIT AND BSD-4-Clause)

pragma solidity ^0.8.0;


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
        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else if (signature.length == 64) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let vs := mload(add(signature, 0x40))
                r := mload(add(signature, 0x20))
                s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                v := add(shr(255, vs), 27)
            }
        } else {
            revert("ECDSA: invalid signature length");
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
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
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;
    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(bytes32 typeHash, bytes32 name, bytes32 version) private view returns (bytes32) {
        return keccak256(
            abi.encode(
                typeHash,
                name,
                version,
                block.chainid,
                address(this)
            )
        );
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}



interface ISimpleMultiSig {

    event Executed(
          uint indexed nonce
        , bool succeeded
        , bytes returnData
        , string revertMsg
        );

    function getChainId() view external returns (uint256 id);
    function getOwnersArrLength() view external returns (uint256);
    function domainSeparatorV4() view external returns (bytes32);
    function getTypedDataHashV4 (bytes32 structHash) view external returns(bytes32);
    function getTxTypeHash() external view returns(bytes32);
    function getNonce() external view returns(uint256);
    function getThreshold() external view returns(uint256);
    function getOwners() external view returns(address[] memory);
    function getIsOwner(address addr) external view returns(bool);

    function execute(
          bytes[] calldata signatures
        , address destination
        , uint value
        , bytes memory data
        , address executor
        )
        external
        returns (bool success);
}

contract SimpleMultiSig is EIP712, ISimpleMultiSig {

    bytes32 public immutable TXTYPE_HASH;
    uint public nonce;                 // (only) mutable state
    uint public immutable threshold;             // immutable state
    mapping (address => bool) public isOwner; // immutable state
    address[] public ownersArr;        // immutable state

    function getChainId() override view external returns (uint256 id) {
        assembly { id := chainid() }
    }

    function getOwnersArrLength() override view external returns (uint256) {
        return ownersArr.length;
    }

    function domainSeparatorV4() override view external returns (bytes32) {
        return _domainSeparatorV4();
    }

    function getTypedDataHashV4 (bytes32 structHash) override view external returns(bytes32) {
        return _hashTypedDataV4(structHash);
    }

    function getTxTypeHash() override external view returns(bytes32) {
        return TXTYPE_HASH;
    }

    function getNonce() override external view returns(uint256) {
        return nonce;
    }

    function getThreshold() override external view returns(uint256) {
        return threshold;
    }

    function getOwners() override external view returns(address[] memory) {
        return ownersArr;
    }

    function getIsOwner(address addr) override external view returns(bool) {
        return isOwner[addr];
    }

    // Note that owners_ must be strictly increasing, in order to prevent duplicates
    constructor(uint threshold_, address[] memory owners_)
        EIP712("Simple MultiSig", "1")
    {
        require(owners_.length <= 10 && threshold_ <= owners_.length && threshold_ > 0);

        address lastAdd = address(0);
        for (uint i = 0; i < owners_.length; i++) {
            require(owners_[i] > lastAdd);
            isOwner[owners_[i]] = true;
            lastAdd = owners_[i];
        }
        ownersArr = owners_;
        threshold = threshold_;

        TXTYPE_HASH =  keccak256("MultiSigTransaction(address destination,uint256 value,bytes data,uint256 nonce,address executor)");
    }

    function execute(
          bytes[] calldata signatures
        , address destination
        , uint value
        , bytes memory data
        , address executor
        //, uint gasLimit
        )
        override
        external
        returns (bool success)
    {
        require(signatures.length == threshold);
        require(executor == msg.sender || executor == address(0), "unexpected executor");

        // EIP712 scheme: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md
        bytes32 txInputHash = keccak256(abi.encode(TXTYPE_HASH, destination, value, keccak256(data), nonce, executor));
        bytes32 totalHash = _hashTypedDataV4(txInputHash);

        address lastAdd = address(0); // cannot have address(0) as an owner
        for (uint i = 0; i < threshold; i++) {
            address recovered = ECDSA.recover(totalHash, signatures[i]);
            require(recovered > lastAdd && isOwner[recovered]);
            lastAdd = recovered;
        }

        // If we make it here all signatures are accounted for.
        // The address.call() syntax is no longer recommended, see:
        // https://github.com/ethereum/solidity/issues/2884
        nonce = nonce + 1;
        bytes memory returnData;
        string memory revertMsg;

        // ===============================================================
        // @notice Reverting **WHEN** contract-to-contract call reverts:
        assembly {
            function allocate(size_) -> y {
                y := mload(0x40)
                // new "memory end" including padding
                mstore(0x40, add(y, and(add(size_, 0x1f), not(0x1f))))
            }

            function getRawReturnData() -> y {
                let size := returndatasize()
                y := allocate(add(size, 0x20))
                mstore(y, size)
                returndatacopy(add(y, 0x20), 0, size)
            }

            success := call(gas(), destination, value, add(data, 0x20), mload(data), 0, 0)

            let size := returndatasize()

            switch success
            case 0 {
                // @notice In this case (revert), it is beneficial detect, if return(= revert) data are encoded
                // in the **EXPECTED** format, which is ABI encoded call to `Error(string)`:
                //  * IF they **ARE**, then revert string msg can be extracted,
                //  * OR if they are **NOT**, then **WHOLE** return data will be copied *as is*, exactly as returned
                //    from call to the dest. contract.
                // Below is example of **correctly** encoded revert data = abi encoded `Error(string)` call
                // together with input parameters data(= revert message string):
                // https://docs.soliditylang.org/en/v0.8.0/control-structures.html
                // 0x08c379a0                                                         // Function selector for Error(string)
                // 0x0000000000000000000000000000000000000000000000000000000000000020 // Data offset
                // 0x000000000000000000000000000000000000000000000000000000000000001a // String length
                // 0x4e6f7420656e6f7567682045746865722070726f76696465642e000000000000 // String data
                //
                switch gt(size, 0x24)
                case 0 {
                    returnData := getRawReturnData()
                }
                default {
                    let selector_data := allocate(0x24)
                    returndatacopy(selector_data, 0, 0x24)
                    let selector := mload(selector_data)

                    let dataOffset := mload(add(selector_data, 4))

                    switch and(
                                eq(selector, 0x08c379a000000000000000000000000000000000000000000000000000000000),
                                eq(dataOffset, 0x20)
                            )
                    case 0 {
                        returnData := getRawReturnData()
                    }
                    default {
                        let size_rev := sub(size, 0x24)
                        revertMsg := allocate(size_rev)
                        returndatacopy(revertMsg, 0x24, size_rev)
                    }
                }
            }
            default {
                returnData := getRawReturnData()
            }
        }

        emit Executed(
              nonce
            , success
            , returnData
            , revertMsg
            );
    }

    receive() external payable {}
}