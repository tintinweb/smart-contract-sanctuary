// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

/**
* @title Mock Oracle contract used for testing.
*/
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MockOracleState{

    string public trackingAssetSymbol;

    uint internal lastPrice;

    uint public oraclePriceDecimals;

    uint public lastTimestampUpdate;

    uint public maxDelay = 3 * 60;

    address public trustedSigner;
}

contract MockOracle is Ownable, MockOracleState {
    using ECDSA for bytes32;

    constructor (
        string memory _trackingassetSymbol,
        uint _oraclePriceDecimals
    ) {
        trackingAssetSymbol = _trackingassetSymbol;
        oraclePriceDecimals = _oraclePriceDecimals;
    }

    function getLastPrice() external view returns(uint){
        return lastPrice;
    }

    function setMaxDelay(uint256 _maxDelay) onlyOwner external {
        maxDelay = _maxDelay;
    }

    function setPrice(uint newPrice) external onlyOwner {
        lastPrice = newPrice;
        lastTimestampUpdate = block.timestamp;
    }

    function redstoneGetLastPrice() external view returns(uint) {
        return getPriceFromMsg(bytes32("MXNUSD=X"));
    }

    // The following events and functions are taken from Redstone-Flash-Storage
    // This mock oracle does not implement functionally the Redstone Oracle

    /**
    * @dev emitted after the owner updates trusted signer
    * @param newSigner the address of the new signer
    **/
    event TrustedSignerChanged(address indexed newSigner);

    function authorizeSigner(address _trustedSigner) onlyOwner external {
    require(_trustedSigner != address(0));
    trustedSigner = _trustedSigner;
    emit TrustedSignerChanged(trustedSigner);
    }

    function getPriceFromMsg(bytes32 symbol) internal view returns(uint256) {
        //The structure of calldata witn n - data items:
        //The data that is signed (symbols, values, timestamp) are inside the {} brackets
        //[origina_call_data| ?]{[[symbol | 32][value | 32] | n times][timestamp | 32]}[size | 1][signature | 65]
        
    
        //1. First we extract dataSize - the number of data items (symbol,value pairs) in the message
        uint8 dataSize; //Number of data entries    
        assembly { 
        //Calldataload loads slots of 32 bytes
        //The last 65 bytes are for signature
        //We load the previous 32 bytes and automatically take the 2 least significant ones (casting to uint16)
        dataSize := calldataload(sub(calldatasize(), 97))
        }  
    
    
        // 2. We calculate the size of signable message expressed in bytes
        // ((symbolLen(32) + valueLen(32)) * dataSize + timeStamp length
        uint16 messageLength = uint16(dataSize) * 64 + 32; //Length of data message in bytes    
        
        // 3. We extract the signableMessage

        //(That's the high level equivalent 2k gas more expensive)
        //bytes memory rawData = msg.data.slice(msg.data.length - messageLength - 65, messageLength);
    
        bytes memory signableMessage;
        assembly {
        signableMessage := mload(0x40)
        mstore(signableMessage, messageLength)
        //The starting point is callDataSize minus length of data(messageLength), signature(65) and size(1) = 66
        calldatacopy(add(signableMessage, 0x20), sub(calldatasize(), add(messageLength, 66)), messageLength)
        mstore(0x40, add(signableMessage, 0x20))
        }    
    
    
        // 4. We first hash the raw message and then hash it again with the prefix
        // Following the https://github.com/ethereum/eips/issues/191 standard
        bytes32 hash = keccak256(signableMessage);
        bytes32 hashWithPrefix = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));

        // 5. We extract the off-chain signature from calldata
        
        //(That's the high level equivalent 2k gas more expensive)
        //bytes memory signature = msg.data.slice(msg.data.length - 65, 65);
        bytes memory signature;
        assembly {
        signature := mload(0x40)
        mstore(signature, 65)
        calldatacopy(add(signature, 0x20), sub(calldatasize(), 65), 65)
        mstore(0x40, add(signature, 0x20))
        }
    
        // 6. We verify the off-chain signature against on-chain hashed data
        
        address signer = hashWithPrefix.recover(signature);
        require(signer == trustedSigner, "Signer not authorized");

        //7. We extract timestamp from callData
        
        uint256 dataTimestamp;
        assembly {
        //Calldataload loads slots of 32 bytes
        //The last 65 bytes are for signature + 1 for data size
        //We load the previous 32 bytes
        dataTimestamp := calldataload(sub(calldatasize(), 98))
        }

        require(block.timestamp - dataTimestamp < maxDelay, "Data is too old");
        
        //Debugging logs (to be removed)
        //    console.log("Len: ", messageLength);
        //    console.logBytes(rawData);
        //    console.logBytes32(hash);
        //    console.logBytes(signature);
        //    console.log("Signer: ", signer);

        
        //8. We iterate directly through call data to extract the value for a given symbol

        uint256 val;
        uint256 max = dataSize;
        bytes32 currentSymbol;
        uint256 i;
        assembly {
        let start := sub(calldatasize(), add(messageLength, 66))
            for { i := 0 } lt(i, max) { i := add(i, 1) } {
                currentSymbol := calldataload(add(start, mul(i, 64)))        
                if eq(currentSymbol, symbol) {
                    val := calldataload(add(start, add(32, mul(i, 64))))
                    i := max
                }
            }
        }
    
    return val;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}