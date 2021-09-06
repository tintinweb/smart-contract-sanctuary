/**
 *Submitted for verification at Etherscan.io on 2021-09-06
*/

// Dependency file: @openzeppelin/contracts/security/ReentrancyGuard.sol

// SPDX-License-Identifier: MIT

// pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// Dependency file: @openzeppelin/contracts/utils/cryptography/ECDSA.sol


// pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
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
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
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
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
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


// Root file: contracts/NameRegistry.sol

pragma solidity 0.8.4;

// import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title NameRegistry
 * @author Phan Trung Sinh
 *
 * Smart contract for name registering system resistant against frontrunning
 */
contract NameRegistry is ReentrancyGuard {
    using ECDSA for bytes32;

    /* ============ Structs ============ */

    struct NameCommit {
        bytes32 nameHash;
        uint256 blockNumber;
    }

    struct Name {
        address owner;
        bytes32 name;
        uint256 registeredTime;
    }


    /* ============ Events ============ */

    event NameCommited(bytes32 _nameHash, uint256 _blockNumber);
    event NameRegistered(address indexed _owner, string _name, uint256 _registeredTime);
    event NameRenewed(address indexed _owner, string _name, uint256 _renewedTime);

    /* ============ State Variables ============ */

    uint256 immutable public lockDuration;
    uint256 immutable public lockAmount;
    uint256 immutable public blockFreeze;   // Name registration is available after some blocks of the commitment
    uint256 immutable public feeAmount;
    address public feeRecipient;

    NameCommit[] private nameCommits;
    Name[] private names;

    /* ============ Constructer ============ */

    /**
     * Initialize NameRegistry contract
     *
     * @param _lockDuration         One time name registration lock duration
     * @param _lockAmount           Amount to lock when register a name
     * @param _blockFreeze            Number of blocks for the registration after the commitment
     * @param _feeAmount            Fee amount to pay when register a name
     * @param _feeRecipient         Address to receive the fee
     */
    constructor(
        uint256 _lockDuration,
        uint256 _lockAmount,
        uint256 _blockFreeze,
        uint256 _feeAmount,
        address _feeRecipient
    ) {
        require(_lockDuration > 0, "invalid lock duration");
        require(_lockAmount > 0, "invalid lock amount");
        require(_blockFreeze > 0, "invalid freeze blocks");
        require(_feeAmount > 0, "invalid fee amount");
        require(_feeRecipient != address(0), "invalid fee recipient");

        lockDuration = _lockDuration;
        lockAmount = _lockAmount;
        feeAmount = _feeAmount;
        blockFreeze = _blockFreeze;
        feeRecipient = _feeRecipient;
    }

    /* ============ Public/External Functions ============ */

    /**
     * Commit name hash which including 
     *
     * @param _nameHash             Hash of the register, name, nounce
     */
    function commitName(
        bytes32 _nameHash
    ) external {
        uint256 currentBlockNumber = block.number;
        nameCommits.push(NameCommit({
            nameHash: _nameHash,
            blockNumber: currentBlockNumber
        }));

        emit NameCommited(_nameHash, currentBlockNumber);

        // for now, don't call unlockCall() for gas saving
        // unlockNames();
    }

    /**
     * Reveal and register Name
     *
     * @param _name                 Real name
     */
    function registerName(
        string memory _name,
        bytes memory _signature
    ) external payable nonReentrant {
        require(msg.value >= lockAmount + feeAmount, "insufficient amount");

        bytes32 nameHash = getNameHash(_name);
        // check if nameHash is included in the nameCommits
        (uint256 index, bool isFound) = _indexOfNameCommits(nameHash);
        require(isFound, "not commited name");
        
        uint256 commitedBlockNumber = nameCommits[index].blockNumber;
        require(commitedBlockNumber + blockFreeze < block.number, "should register after some blocks");

        bytes32 signedHash = nameHash.toEthSignedMessageHash();
        address signer = signedHash.recover(_signature);
        require(signer == msg.sender, "invalid signer");
        
        // register name
        names.push(Name({ owner:signer, name:_stringToBytes32(_name), registeredTime: block.timestamp }));
        // remove name commitment
        _removeNameCommitsAt(index);

        // send fee
        (bool sentFee, ) = feeRecipient.call{value: feeAmount}("");
        require(sentFee, "failed to send ether");

        // refund remaining
        if (msg.value > lockAmount + feeAmount) {
            (bool sentRemainng, ) = msg.sender.call{value: msg.value - lockAmount - feeAmount }("");
            require(sentRemainng, "failed to send remaining ether");
        }

        emit NameRegistered(signer, _name, block.timestamp);

        // for now, don't call unlockCall() for gas saving
        // unlockNames();
    }

    /**
     * Renew ownership of the name
     *
     * @param _name                 Real name
     */
    function renewName(string memory _name) external payable nonReentrant {
        require(msg.value >= feeAmount, "insufficient fee");
        require(bytes(_name).length <= 32, "name size should be less than 32 bytes");

        bytes32 nameBytes = _stringToBytes32(_name);
        (uint256 index, bool isFound) = _indexOfNames(nameBytes);
        require(isFound, "name not found");

        Name storage nameData = names[index];
        require(nameData.owner == msg.sender, "not the owner");

        uint256 currentTime = block.timestamp;
        require(nameData.registeredTime + lockDuration > currentTime, "registration expired already");

        // send fee
        (bool sentFee, ) = feeRecipient.call{value: feeAmount}("");
        require(sentFee, "failed to send ether");

        // refund remaining
        if (msg.value > feeAmount) {
            (bool sentRemainng, ) = msg.sender.call{value: msg.value - feeAmount }("");
            require(sentRemainng, "failed to send remaining ether");
        }

        emit NameRenewed(msg.sender, _name, currentTime);

        // for now, don't call unlockCall() for gas saving
        // unlockNames();
    }

    /**
     * Unlock names
     */
    function unlockNames() public nonReentrant {
        uint256 length = names.length;
        uint256 currentTime = block.timestamp;
        for (uint256 i = 0; i < length; i++) {
            if (names[i].registeredTime + lockDuration <= currentTime) {
                address previousOwner = names[i].owner;
                _removeNamesAt(i);

                // unlock previous owners balance
                (bool sent, ) = previousOwner.call{ value: lockAmount }("");
                require(sent, "failed to send ether");
            }
        }
    }

    /* ============ Public/External Getter Functions ============ */

    function getNameHash(string memory _name) public pure returns (bytes32) {
        require(bytes(_name).length <= 32, "name size should be less than 32 bytes");
        return keccak256(abi.encodePacked(_name));
    }

    /* ============ Internal Functions ============ */

    /**
     * Finds the index of the first occurrence of the given element in nameCommits
     *
     * @param _nameHash             The value to find
     *
     * @return                      Returns (index and isIn) for the first occurrence starting from index 0
     */
    function _indexOfNameCommits(bytes32 _nameHash) internal view returns (uint256, bool) {
        uint256 length = nameCommits.length;
        for (uint256 i = 0; i < length; i++) {
            if (nameCommits[i].nameHash == _nameHash) {
                return (i, true);
            }
        }
        return (type(uint256).max, false);
    }

    /**
     * Finds the index of the first occurrence of the given element in names
     *
     * @param _name                 The value to find
     *
     * @return                      Returns (index and isIn) for the first occurrence starting from index 0
     */
    function _indexOfNames(bytes32 _name) internal view returns (uint256, bool) {
        uint256 length = names.length;
        for (uint256 i = 0; i < length; i++) {
            if (names[i].name == _name) {
                return (i, true);
            }
        }
        return (type(uint256).max, false);
    }

    /**
    * Removes specified index from nameCommits array
    *
    * @param _index                 The index to remove
    *
    * @return                       Success or failure
    */
    function _removeNameCommitsAt(uint256 _index) internal returns (bool) {
        uint256 length = nameCommits.length;
        if (_index >= length) return false;

        for (uint i = _index; i < length - 1; i++){
            nameCommits[i] = nameCommits[i+1];
        }
        nameCommits.pop();
        return true;
    }

    /**
    * Removes specified index from names array
    *
    * @param _index                 The index to remove
    *
    * @return                       Success or failure
    */
    function _removeNamesAt(uint256 _index) internal returns (bool) {
        uint256 length = names.length;
        if (_index >= length) return false;

        for (uint i = _index; i < length - 1; i++){
            names[i] = names[i+1];
        }
        names.pop();
        return true;
    }

    /**
    * Convert string to bytes32
    *
    * @param _source                Source string
    *
    * @return result                bytes32 converted from the source string
    */
    function _stringToBytes32(string memory _source) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(_source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(_source, 32))
        }
    }
}