/**
 *Submitted for verification at polygonscan.com on 2021-07-12
*/

pragma solidity ^0.6.0;

/**
    @author The Calystral Team
    @title The ERC1155CalystralMixedFungibleMintable' Interface
*/
interface IERC1155CalystralMixedFungibleMintable {
    /**
        @dev MUST emit when a release timestamp is set or updated.
        The `typeId` argument MUST be the id of a type.
        The `timestamp` argument MUST be the timestamp of the release in seconds.
    */
    event OnReleaseTimestamp(uint256 indexed typeId, uint256 timestamp);

    /**
        @notice Updates the metadata base URI.
        @dev Updates the `_metadataBaseURI`.
        @param uri The metadata base URI
    */
    function updateMetadataBaseURI(string calldata uri) external;

    /**
        @notice Creates a non-fungible type.
        @dev Creates a non-fungible type. This function only creates the type and is not used for minting.
        The type also has a maxSupply since there can be multiple tokens of the same type, e.g. 100x 'Pikachu'.
        Reverts if the `maxSupply` is 0 or exceeds the `MAX_TYPE_SUPPLY`.
        @param maxSupply        The maximum amount that can be created of this type, unlimited SHOULD be 2**128 (uint128) as the max. MUST NOT be set to 0
        @param releaseTimestamp The timestamp for the release time, SHOULD be set to 1337 for releasing it right away. MUST NOT be set to 0
        @return                 The `typeId`
    */
    function createNonFungibleType(uint256 maxSupply, uint256 releaseTimestamp)
        external
        returns (uint256);

    /**
        @notice Creates a fungible type.
        @dev Creates a fungible type. This function only creates the type and is not used for minting.
        Reverts if the `maxSupply` is 0 or exceeds the `MAX_TYPE_SUPPLY`.
        @param maxSupply        The maximum amount that can be created of this type, unlimited SHOULD be 2**128 (uint128) as the max. MUST NOT be set to 0
        @param releaseTimestamp The timestamp for the release time, SHOULD be set to 1337 for releasing it right away. MUST NOT be set to 0
        @return                 The `typeId`
    */
    function createFungibleType(uint256 maxSupply, uint256 releaseTimestamp)
        external
        returns (uint256);

    /**
        @notice Mints a non-fungible type.
        @dev Mints a non-fungible type.
        Reverts if type id is not existing.
        Reverts if out of stock.
        Emits the `TransferSingle` event.
        @param typeId   The type which should be minted
        @param toArr    An array of receivers
    */
    function mintNonFungible(uint256 typeId, address[] calldata toArr) external;

    /**
        @notice Mints a fungible type.
        @dev Mints a fungible type.
        Reverts if array lengths are unequal.
        Reverts if type id is not existing.
        Reverts if out of stock.
        Emits the `TransferSingle` event.
        @param typeId   The type which should be minted
        @param toArr    An array of receivers
    */
    function mintFungible(
        uint256 typeId,
        address[] calldata toArr,
        uint256[] calldata quantitiesArr
    ) external;

    /**
        @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        Uses Meta Transactions - transactions are signed by the owner or operator of the owner but are executed by anybody.
        Reverts if the signature is invalid.
        Reverts if array lengths are unequal.
        Reverts if the transaction expired.
        Reverts if the transaction was executed already.
        Reverts if the signer is not the asset owner or approved operator of the owner.
        Reverts if `_to` is the zero address.
        Reverts if balance of holder for token `_id` is lower than the `_value` sent.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param r            The r value of the signature
        @param s            The s value of the signature
        @param v            The v value of the signature
        @param signer       The signing account. This SHOULD be the owner of the asset or an approved operator of the owner.
        @param _to          Target address
        @param _id          ID of the token type
        @param _value       Transfer amount
        @param _data        Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
        @param nonce        Each sent meta transaction includes a nonce to prevent that a signed transaction is executed multiple times
        @param maxTimestamp The maximum point in time before the meta transaction expired, thus becoming invalid
    */
    function metaSafeTransferFrom(
        bytes32 r,
        bytes32 s,
        uint8 v,
        address signer,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data,
        uint256 nonce,
        uint256 maxTimestamp
    ) external;

    /**
        @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        Uses Meta Transactions - transactions are signed by the owner or operator of the owner but are executed by anybody.
        Reverts if the signature is invalid.
        Reverts if array lengths are unequal.
        Reverts if the transaction expired.
        Reverts if the transaction was executed already.
        Reverts if the signer is not the asset owner or approved operator of the owner.
        Reverts if `_to` is the zero address.
        Reverts if length of `_ids` is not the same as length of `_values`.
        Reverts if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
        MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
        Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
        After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param r            The r value of the signature
        @param s            The s value of the signature
        @param v            The v value of the signature
        @param signer       The signing account. This SHOULD be the owner of the asset or an approved operator of the owner.
        @param _to          Target address
        @param _ids         IDs of each token type (order and length must match _values array)
        @param _values      Transfer amounts per token type (order and length must match _ids array)
        @param _data        Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
        @param nonce        Each sent meta transaction includes a nonce to prevent that a signed transaction is executed multiple times
        @param maxTimestamp The maximum point in time before the meta transaction expired, thus becoming invalid
    */
    function metaSafeBatchTransferFrom(
        bytes32 r,
        bytes32 s,
        uint8 v,
        address signer,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data,
        uint256 nonce,
        uint256 maxTimestamp
    ) external;

    /**
        @notice Burns fungible and/or non-fungible tokens.
        @dev Sends FTs and/or NFTs to 0x0 address.
        Uses Meta Transactions - transactions are signed by the owner but are executed by anybody.
        Reverts if the signature is invalid.
        Reverts if array lengths are unequal.
        Reverts if the transaction expired.
        Reverts if the transaction was executed already.
        Reverts if the signer is not the asset owner.
        Emits the `TransferBatch` event where the `to` argument is the 0x0 address.
        @param r The r value of the signature
        @param s The s value of the signature
        @param v The v value of the signature
        @param signer The signing account. This SHOULD be the owner of the asset
        @param ids An array of token Ids which should be burned
        @param values An array of amounts which should be burned. The order matches the order in the ids array
        @param nonce Each sent meta transaction includes a nonce to prevent that a signed transaction is executed multiple times
        @param maxTimestamp The maximum point in time before the meta transaction expired, thus becoming invalid
    */
    function metaBatchBurn(
        bytes32 r,
        bytes32 s,
        uint8 v,
        address signer,
        uint256[] calldata ids,
        uint256[] calldata values,
        uint256 nonce,
        uint256 maxTimestamp
    ) external;

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        Uses Meta Transactions - transactions are signed by the owner but are executed by anybody.
        Reverts if the signature is invalid.
        Reverts if array lengths are unequal.
        Reverts if the transaction expired.
        Reverts if the transaction was executed already.
        Reverts if the signer is not the asset owner.
        @param r            The r value of the signature
        @param s            The s value of the signature
        @param v            The v value of the signature
        @param signer       The signing account. This SHOULD be the owner of the asset
        @param _operator    Address to add to the set of authorized operators
        @param _approved    True if the operator is approved, false to revoke approval
        @param nonce        Each sent meta transaction includes a nonce to prevent that a signed transaction is executed multiple times
        @param maxTimestamp The maximum point in time before the meta transaction expired, thus becoming invalid
    */
    function metaSetApprovalForAll(
        bytes32 r,
        bytes32 s,
        uint8 v,
        address signer,
        address _operator,
        bool _approved,
        uint256 nonce,
        uint256 maxTimestamp
    ) external;

    /**
        @notice Sets a release timestamp.
        @dev Sets a release timestamp.
        Reverts if `timestamp` == 0.
        Reverts if the `typeId` is released already.
        @param typeId       The type which should be set or updated
        @param timestamp    The timestamp for the release time, SHOULD be set to 1337 for releasing it right away. MUST NOT be set to 0
    */
    function setReleaseTimestamp(uint256 typeId, uint256 timestamp) external;

    /**
        @notice Get the release timestamp of a type.
        @dev Get the release timestamp of a type.
        @return The release timestamp of a type.
    */
    function getReleaseTimestamp(uint256 typeId)
        external
        view
        returns (uint256);

    /**
        @notice Get all existing type Ids.
        @dev Get all existing type Ids.
        @return An array of all existing type Ids.
    */
    function getTypeIds() external view returns (uint256[] memory);

    /**
        @notice Get a specific type Id.
        @dev Get a specific type Id.
        Reverts if `typeNonce` is 0 or if it does not exist.
        @param  typeNonce The type nonce for which the id is requested
        @return A specific type Id.
    */
    function getTypeId(uint256 typeNonce) external view returns (uint256);

    /**
        @notice Get all non-fungible assets for a specific user.
        @dev Get all non-fungible assets for a specific user.
        @param  owner The address of the requested user
        @return An array of Ids that are owned by the user
    */
    function getNonFungibleAssets(address owner)
        external
        view
        returns (uint256[] memory);

    /**
        @notice Get all fungible assets for a specific user.
        @dev Get all fungible assets for a specific user.
        @param  owner The address of the requested user
        @return An array of Ids that are owned by the user
                An array for the amount owned of each Id
    */
    function getFungibleAssets(address owner)
        external
        view
        returns (uint256[] memory, uint256[] memory);

    /**
        @notice Get the type nonce.
        @dev Get the type nonce.
        @return The type nonce.
    */
    function getTypeNonce() external view returns (uint256);

    /**
        @notice The amount of tokens that have been minted of a specific type.
        @dev    The amount of tokens that have been minted of a specific type.
                Reverts if the given typeId does not exist.
        @param  typeId The requested type
        @return The minted amount
    */
    function getMintedSupply(uint256 typeId) external view returns (uint256);

    /**
        @notice The amount of tokens that can be minted of a specific type.
        @dev    The amount of tokens that can be minted of a specific type.
                Reverts if the given typeId does not exist.
        @param  typeId The requested type
        @return The maximum mintable amount
    */
    function getMaxSupply(uint256 typeId) external view returns (uint256);

    /**
        @notice Get the burn nonce of a specific user.
        @dev    Get the burn nonce of a specific user / signer.
        @param  signer The requested signer
        @return The burn nonce of a specific user
    */
    function getMetaNonce(address signer) external view returns (uint256);
}

/**
    Note: The ERC-165 identifier for this interface is 0x0e89341c.
*/
interface IERC1155Metadata_URI {
    /**
        @notice A distinct Uniform Resource Identifier (URI) for a given token.
        @dev URIs are defined in RFC 3986.
        The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".        
        @return URI string
    */
    function uri(uint256 _id) external view returns (string memory);
}

/*
Begin solidity-cborutils
https://github.com/smartcontractkit/solidity-cborutils

MIT License

Copyright (c) 2018 SmartContract ChainLink, Ltd.
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

library Strings {
    function strConcat(string memory _a, string memory _b)
        internal
        pure
        returns (string memory _concatenatedString)
    {
        return strConcat(_a, _b, "", "", "");
    }

    function strConcat(
        string memory _a,
        string memory _b,
        string memory _c
    ) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(
        string memory _a,
        string memory _b,
        string memory _c,
        string memory _d
    ) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(
        string memory _a,
        string memory _b,
        string memory _c,
        string memory _d,
        string memory _e
    ) internal pure returns (string memory _concatenatedString) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(
            _ba.length + _bb.length + _bc.length + _bd.length + _be.length
        );
        bytes memory babcde = bytes(abcde);
        uint256 k = 0;
        uint256 i = 0;
        for (i = 0; i < _ba.length; i++) {
            babcde[k++] = _ba[i];
        }
        for (i = 0; i < _bb.length; i++) {
            babcde[k++] = _bb[i];
        }
        for (i = 0; i < _bc.length; i++) {
            babcde[k++] = _bc[i];
        }
        for (i = 0; i < _bd.length; i++) {
            babcde[k++] = _bd[i];
        }
        for (i = 0; i < _be.length; i++) {
            babcde[k++] = _be[i];
        }
        return string(babcde);
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        return string(bstr);
    }
}

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSACalystral {
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
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range
        // for r in (280): 0 < r < secp256k1n
        // for s in (281): 0 < s < secp256k1n ÷ 2 + 1,
        // for v in (282): v ∈ {27, 28}.
        // Most signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (
            uint256(r) >=
            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141
        ) {
            revert("ECDSA: invalid signature 'r' value");
        }
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
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
    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }
}

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor() internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        override
        view
        returns (bool)
    {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * Utility library of inline functions on addresses
 */
library Address {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

/**
    Note: Simple contract to use as base for const vals
*/
contract CommonConstants {
    bytes4 internal constant ERC1155_ACCEPTED = 0xf23a6e61; // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
    bytes4 internal constant ERC1155_BATCH_ACCEPTED = 0xbc197c81; // bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
}

/**
    Note: The ERC-165 identifier for this interface is 0x4e2312e0.
*/
interface ERC1155TokenReceiver {
    /**
        @notice Handle the receipt of a single ERC1155 token type.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated.
        This function MUST return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` (i.e. 0xf23a6e61) if it accepts the transfer.
        This function MUST revert if it rejects the transfer.
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _id        The ID of the token being transferred
        @param _value     The amount of tokens being transferred
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    */
    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external returns (bytes4);

    /**
        @notice Handle the receipt of multiple ERC1155 token types.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated.
        This function MUST return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` (i.e. 0xbc197c81) if it accepts the transfer(s).
        This function MUST revert if it rejects the transfer(s).
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the batch transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _ids       An array containing ids of each token being transferred (order and length must match _values array)
        @param _values    An array containing amounts of each token being transferred (order and length must match _ids array)
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    */
    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external returns (bytes4);
}

/**
    @title ERC-1155 Multi Token Standard
    @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1155.md
    Note: The ERC-165 identifier for this interface is 0xd9b67a26.
 */
interface IERC1155 {
    /* is ERC165 */
    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be msg.sender.
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_id` argument MUST be the token type being transferred.
        The `_value` argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
    */
    event TransferSingle(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256 _id,
        uint256 _value
    );

    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be msg.sender.
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_ids` argument MUST be the list of tokens being transferred.
        The `_values` argument MUST be the list of number of tokens (matching the list and order of tokens specified in _ids) the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
    */
    event TransferBatch(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256[] _ids,
        uint256[] _values
    );

    /**
        @dev MUST emit when approval for a second party/operator address to manage all tokens for an owner address is enabled or disabled (absense of an event assumes disabled).
    */
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    /**
        @dev MUST emit when the URI is updated for a token ID.
        URIs are defined in RFC 3986.
        The URI MUST point a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
    */
    event URI(string _value, uint256 indexed _id);

    /**
        @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _id      ID of the token type
        @param _value   Transfer amount
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external;

    /**
        @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if length of `_ids` is not the same as length of `_values`.
        MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
        MUST revert on any other error.
        MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
        Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
        After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _ids     IDs of each token type (order and length must match _values array)
        @param _values  Transfer amounts per token type (order and length must match _ids array)
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    */
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external;

    /**
        @notice Get the balance of an account's Tokens.
        @param _owner  The address of the token holder
        @param _id     ID of the Token
        @return        The _owner's balance of the Token type requested
     */
    function balanceOf(address _owner, uint256 _id)
        external
        view
        returns (uint256);

    /**
        @notice Get the balance of multiple account/token pairs
        @param _owners The addresses of the token holders
        @param _ids    ID of the Tokens
        @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
        external
        view
        returns (uint256[] memory);

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param _operator  Address to add to the set of authorized operators
        @param _approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param _owner     The owner of the Tokens
        @param _operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool);
}

// A sample implementation of core ERC1155 function.
contract ERC1155 is IERC1155, ERC165, CommonConstants {
    using SafeMath for uint256;
    using Address for address;

    // id => (owner => balance)
    mapping(uint256 => mapping(address => uint256)) internal balances;

    // owner => (operator => approved)
    mapping(address => mapping(address => bool)) internal operatorApproval;

    /////////////////////////////////////////// ERC1155 //////////////////////////////////////////////

    constructor() public {
        _registerInterface(type(IERC1155).interfaceId); // 0xd9b67a26
    }

    /**
        @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _id      ID of the token type
        @param _value   Transfer amount
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external virtual override {
        require(_to != address(0x0), "_to must be non-zero.");
        require(
            _from == msg.sender || operatorApproval[_from][msg.sender] == true,
            "Need operator approval for 3rd party transfers."
        );

        // SafeMath will throw with insuficient funds _from
        // or if _id is not valid (balance will be 0)
        balances[_id][_from] = balances[_id][_from].sub(_value);
        balances[_id][_to] = _value.add(balances[_id][_to]);

        // MUST emit event
        emit TransferSingle(msg.sender, _from, _to, _id, _value);

        // Now that the balance is updated and the event was emitted,
        // call onERC1155Received if the destination is a contract.
        if (_to.isContract()) {
            _doSafeTransferAcceptanceCheck(
                msg.sender,
                _from,
                _to,
                _id,
                _value,
                _data
            );
        }
    }

    /**
        @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if length of `_ids` is not the same as length of `_values`.
        MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
        MUST revert on any other error.
        MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
        Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
        After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _ids     IDs of each token type (order and length must match _values array)
        @param _values  Transfer amounts per token type (order and length must match _ids array)
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    */
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external virtual override {
        // MUST Throw on errors
        require(_to != address(0x0), "destination address must be non-zero.");
        require(
            _ids.length == _values.length,
            "_ids and _values array lenght must match."
        );
        require(
            _from == msg.sender || operatorApproval[_from][msg.sender] == true,
            "Need operator approval for 3rd party transfers."
        );

        for (uint256 i = 0; i < _ids.length; ++i) {
            uint256 id = _ids[i];
            uint256 value = _values[i];

            // SafeMath will throw with insuficient funds _from
            // or if _id is not valid (balance will be 0)
            balances[id][_from] = balances[id][_from].sub(value);
            balances[id][_to] = value.add(balances[id][_to]);
        }

        // Note: instead of the below batch versions of event and acceptance check you MAY have emitted a TransferSingle
        // event and a subsequent call to _doSafeTransferAcceptanceCheck in above loop for each balance change instead.
        // Or emitted a TransferSingle event for each in the loop and then the single _doSafeBatchTransferAcceptanceCheck below.
        // However it is implemented the balance changes and events MUST match when a check (i.e. calling an external contract) is done.

        // MUST emit event
        emit TransferBatch(msg.sender, _from, _to, _ids, _values);

        // Now that the balances are updated and the events are emitted,
        // call onERC1155BatchReceived if the destination is a contract.
        if (_to.isContract()) {
            _doSafeBatchTransferAcceptanceCheck(
                msg.sender,
                _from,
                _to,
                _ids,
                _values,
                _data
            );
        }
    }

    /**
        @notice Get the balance of an account's Tokens.
        @param _owner  The address of the token holder
        @param _id     ID of the Token
        @return        The _owner's balance of the Token type requested
     */
    function balanceOf(address _owner, uint256 _id)
        external
        virtual
        override
        view
        returns (uint256)
    {
        // The balance of any account can be calculated from the Transfer events history.
        // However, since we need to keep the balances to validate transfer request,
        // there is no extra cost to also privide a querry function.
        return balances[_id][_owner];
    }

    /**
        @notice Get the balance of multiple account/token pairs
        @param _owners The addresses of the token holders
        @param _ids    ID of the Tokens
        @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
        external
        virtual
        override
        view
        returns (uint256[] memory)
    {
        require(_owners.length == _ids.length);

        uint256[] memory balances_ = new uint256[](_owners.length);

        for (uint256 i = 0; i < _owners.length; ++i) {
            balances_[i] = balances[_ids[i]][_owners[i]];
        }

        return balances_;
    }

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param _operator  Address to add to the set of authorized operators
        @param _approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address _operator, bool _approved)
        external
        override
    {
        operatorApproval[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param _owner     The owner of the Tokens
        @param _operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address _owner, address _operator)
        external
        override
        view
        returns (bool)
    {
        return operatorApproval[_owner][_operator];
    }

    /////////////////////////////////////////// Internal //////////////////////////////////////////////

    function _doSafeTransferAcceptanceCheck(
        address _operator,
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes memory _data
    ) internal {
        // If this was a hybrid standards solution you would have to check ERC165(_to).supportsInterface(0x4e2312e0) here but as this is a pure implementation of an ERC-1155 token set as recommended by
        // the standard, it is not necessary. The below should revert in all failure cases i.e. _to isn't a receiver, or it is and either returns an unknown value or it reverts in the call to indicate non-acceptance.

        // Note: if the below reverts in the onERC1155Received function of the _to address you will have an undefined revert reason returned rather than the one in the require test.
        // If you want predictable revert reasons consider using low level _to.call() style instead so the revert does not bubble up and you can revert yourself on the ERC1155_ACCEPTED test.
        require(
            ERC1155TokenReceiver(_to).onERC1155Received(
                _operator,
                _from,
                _id,
                _value,
                _data
            ) == ERC1155_ACCEPTED,
            "contract returned an unknown value from onERC1155Received"
        );
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address _operator,
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _values,
        bytes memory _data
    ) internal {
        // If this was a hybrid standards solution you would have to check ERC165(_to).supportsInterface(0x4e2312e0) here but as this is a pure implementation of an ERC-1155 token set as recommended by
        // the standard, it is not necessary. The below should revert in all failure cases i.e. _to isn't a receiver, or it is and either returns an unknown value or it reverts in the call to indicate non-acceptance.

        // Note: if the below reverts in the onERC1155BatchReceived function of the _to address you will have an undefined revert reason returned rather than the one in the require test.
        // If you want predictable revert reasons consider using low level _to.call() style instead so the revert does not bubble up and you can revert yourself on the ERC1155_BATCH_ACCEPTED test.
        require(
            ERC1155TokenReceiver(_to).onERC1155BatchReceived(
                _operator,
                _from,
                _ids,
                _values,
                _data
            ) == ERC1155_BATCH_ACCEPTED,
            "contract returned an unknown value from onERC1155BatchReceived"
        );
    }
}

/**
    @dev Extension to ERC1155 for Mixed Fungible and Non-Fungible Items support
    The main benefit is sharing of common type information, just like you do when
    creating a fungible id.
*/
contract ERC1155MixedFungible is ERC1155 {
    // Use a split bit implementation.
    // Store the type in the upper 128 bits..
    uint256 constant TYPE_MASK = uint256(uint128(~0)) << 128;

    // ..and the non-fungible index in the lower 128
    uint256 constant NF_INDEX_MASK = uint128(~0);

    // The top bit is a flag to tell if this is a NFI.
    uint256 constant TYPE_NF_BIT = 1 << 255;

    mapping(uint256 => address) nfOwners;

    // Only to make code clearer. Should not be functions
    function isNonFungible(uint256 _id) public pure returns (bool) {
        return _id & TYPE_NF_BIT == TYPE_NF_BIT;
    }

    function isFungible(uint256 _id) public pure returns (bool) {
        return _id & TYPE_NF_BIT == 0;
    }

    function getNonFungibleIndex(uint256 _id) public pure returns (uint256) {
        return _id & NF_INDEX_MASK;
    }

    function getNonFungibleBaseType(uint256 _id) public pure returns (uint256) {
        return _id & TYPE_MASK;
    }

    function isNonFungibleBaseType(uint256 _id) public pure returns (bool) {
        // A base type has the NF bit but does not have an index.
        return (_id & TYPE_NF_BIT == TYPE_NF_BIT) && (_id & NF_INDEX_MASK == 0);
    }

    function isNonFungibleItem(uint256 _id) public pure returns (bool) {
        // A base type has the NF bit but does has an index.
        return (_id & TYPE_NF_BIT == TYPE_NF_BIT) && (_id & NF_INDEX_MASK != 0);
    }

    function ownerOf(uint256 _id) public view returns (address) {
        return nfOwners[_id];
    }

    // override
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external override {
        require(_to != address(0x0), "cannot send to zero address");
        require(
            _from == msg.sender || operatorApproval[_from][msg.sender] == true,
            "Need operator approval for 3rd party transfers."
        );

        if (isNonFungible(_id)) {
            require(nfOwners[_id] == _from);
            nfOwners[_id] = _to;
            // You could keep balance of NF type in base type id like so:
            // uint256 baseType = getNonFungibleBaseType(_id);
            // balances[baseType][_from] = balances[baseType][_from].sub(_value);
            // balances[baseType][_to]   = balances[baseType][_to].add(_value);
        } else {
            balances[_id][_from] = balances[_id][_from].sub(_value);
            balances[_id][_to] = balances[_id][_to].add(_value);
        }

        emit TransferSingle(msg.sender, _from, _to, _id, _value);

        if (_to.isContract()) {
            _doSafeTransferAcceptanceCheck(
                msg.sender,
                _from,
                _to,
                _id,
                _value,
                _data
            );
        }
    }

    // override
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external override {
        require(_to != address(0x0), "cannot send to zero address");
        require(_ids.length == _values.length, "Array length must match");

        // Only supporting a global operator approval allows us to do only 1 check and not to touch storage to handle allowances.
        require(
            _from == msg.sender || operatorApproval[_from][msg.sender] == true,
            "Need operator approval for 3rd party transfers."
        );

        for (uint256 i = 0; i < _ids.length; ++i) {
            // Cache value to local variable to reduce read costs.
            uint256 id = _ids[i];
            uint256 value = _values[i];

            if (isNonFungible(id)) {
                require(nfOwners[id] == _from);
                nfOwners[id] = _to;
            } else {
                balances[id][_from] = balances[id][_from].sub(value);
                balances[id][_to] = value.add(balances[id][_to]);
            }
        }

        emit TransferBatch(msg.sender, _from, _to, _ids, _values);

        if (_to.isContract()) {
            _doSafeBatchTransferAcceptanceCheck(
                msg.sender,
                _from,
                _to,
                _ids,
                _values,
                _data
            );
        }
    }

    function balanceOf(address _owner, uint256 _id)
        external
        override
        view
        returns (uint256)
    {
        if (isNonFungibleItem(_id)) return nfOwners[_id] == _owner ? 1 : 0;
        return balances[_id][_owner];
    }

    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
        external
        override
        view
        returns (uint256[] memory)
    {
        require(_owners.length == _ids.length);

        uint256[] memory balances_ = new uint256[](_owners.length);

        for (uint256 i = 0; i < _owners.length; ++i) {
            uint256 id = _ids[i];
            if (isNonFungibleItem(id)) {
                balances_[i] = nfOwners[id] == _owners[i] ? 1 : 0;
            } else {
                balances_[i] = balances[id][_owners[i]];
            }
        }

        return balances_;
    }
}

/**
    @author The Calystral Team
    @title A parent contract which can be used to keep track of a current contract state
*/
contract ContractState {
    /// @dev Get the current contract state enum.
    State private _currentState;
    /**
        @dev Get the current contract state enum.
        First activation == 1.
    */
    uint256 private _activatedCounter;
    /**
        @dev Get the current contract state enum.
        First inactivation == 1.
    */
    uint256 private _inactivatedCounter;
    /// @dev Includes all three possible contract states.
    enum State {CREATED, INACTIVE, ACTIVE}

    modifier isCurrentState(State _state) {
        _isCurrentState(_state);
        _;
    }

    modifier isCurrentStates(State _state1, State _state2) {
        _isCurrentStates(_state1, _state2);
        _;
    }

    modifier isAnyState() {
        _;
    }

    /**
        @notice Get the current contract state.
        @dev Get the current contract state enum.
        @return The current contract state
    */
    function getCurrentState() public view returns (State) {
        return _currentState;
    }

    /**
        @notice Get the current activated counter.
        @dev Get the current activated counter.
        @return The current activated counter.
    */
    function getActivatedCounter() public view returns (uint256) {
        return _activatedCounter;
    }

    /**
        @notice Get the current inactivated counter.
        @dev Get the current inactivated counter.
        @return The current inactivated counter.
    */
    function getInactivatedCounter() public view returns (uint256) {
        return _inactivatedCounter;
    }

    /**
        @dev Checks if the contract is in the correct state for execution.
        MUST revert if the `_currentState` does not match with the required `_state`.
    */
    function _isCurrentState(State _state) internal view {
        require(
            _currentState == _state,
            "The function call is not possible in the current contract state."
        );
    }

    /**
        @dev Checks if the contract is in one of the correct states for execution.
        MUST revert if the `_currentState` does not match with one of the required states `_state1`, `_state2`.
    */
    function _isCurrentStates(State _state1, State _state2) internal view {
        require(
            _currentState == _state1 || _currentState == _state2,
            "The function call is not possible in the current contract state."
        );
    }

    /**
        @dev Modifies the contract state from State.CREATED or State.ACTIVE into State.INACTIVE.
        Increments the `_inactivatedCounter`.
    */
    function _transitionINACTIVE()
        internal
        isCurrentStates(State.CREATED, State.ACTIVE)
    {
        _currentState = State.INACTIVE;
        _inactivatedCounter++;
        _inactivated(_inactivatedCounter);
    }

    /**
        @dev Modifies the contract state from State.INACTIVE into State.ACTIVE.
        Increments the `_activatedCounter`.
    */
    function _transitionACTIVE() internal isCurrentState(State.INACTIVE) {
        _currentState = State.ACTIVE;
        _activatedCounter++;
        _activated(_activatedCounter);
    }

    /**
        @dev Executes when the contract is set into State.ACTIVE.
        The child contract has to override this function to make use of it.
        The `activatedCouted` parameter is used to execute this function at a specific time only once.
        @param activatedCounter The `activatedCouted` for which the function should be executed once.
    */
    function _activated(uint256 activatedCounter)
        internal
        virtual
        isCurrentState(State.ACTIVE)
    {}

    /**
        @dev Executes when the contract is set into State.INACTIVE.
        The child contract has to override this function to make use of it.
        The `inactivatedCouted` parameter is used to execute this function at a specific time only once.
        @param inactivatedCounter The `inactivatedCouted` for which the function should be executed once.
    */
    function _inactivated(uint256 inactivatedCounter)
        internal
        virtual
        isCurrentState(State.INACTIVE)
    {}
}

/**
    @author The Calystral Team
    @title The Registry's Interface
*/
interface IRegistry {
    /**
        @notice Updates an incoming contract address for relevant contracts or itself. 
        @dev Updates an incoming contract address for relevant contracts or itself.
        Sets itself INACTIVE if it was updated by the registry.
        Sets itself ACTIVE if it was registered by the registry.
        @param contractAddress  The address of the contract update
        @param id               The id of the contract update
    */
    function updateContractAddress(address contractAddress, uint256 id)
        external;

    /**
        @notice Get the contract address of a specific id.
        @dev Get the contract address of a specific id.
        @param id   The contract id
        @return     The contract address of a specific id
    */
    function getContractAddress(uint256 id) external view returns (address);

    /**
        @notice Get if a specific id is relevant for this contract.
        @dev Get if a specific id is relevant for this contract.
        @param id   The contract id
        @return     If the id is relevant for this contract
    */
    function isIdRelevant(uint256 id) external view returns (bool);

    /**
        @notice Get the list of relevant contract ids.
        @dev Get the list of relevant contract ids.
        @return The list of relevant contract ids.
    */
    function getRelevantList() external view returns (uint16[] memory);

    /**
        @notice Get this contract's registry id.
        @dev Get this contract's `_registryId`.
        @return Get this contract's registry id.
    */
    function getRegistryId() external view returns (uint256);
}

/**
    @author The Calystral Team
    @title A parent contract which can be used to integrate with a global contract registry
*/
contract Registry is IRegistry, ContractState, ERC165 {
    /// @dev id => contract address
    mapping(uint256 => address) private _idToContractAddress;
    /// @dev id => a bool showing if it is relevant for updates etc.
    mapping(uint256 => bool) private _idToIsRelevant;
    /**
        @dev This list includes all Ids of contracts that are relevant for this contract listening on address updates in the future.
        This should be immutable but immutable variables cannot have a non-value type.
    */
    uint16[] private _relevantList;
    /**
        @dev The id of this contract.
        Id 0 does not exist but is just reserved.
        Whenever a contract is INACTIVE its id is set to 0.
    */
    uint256 private _registryId;

    modifier isAuthorizedRegistryManager() {
        _isAuthorizedRegistryManager();
        _;
    }

    modifier isAuthorizedAny() {
        _;
    }

    /**
        @notice Initialized and creates the contract including the address of the RegistryManager and a list of relevant contract ids. 
        @dev Creates the contract with an initialized `registryManagerAddress` and `relevantList`.
        Registers this interface for ERC-165.
        MUST revert if the `relevantList` does not include id 1 at index 0.
        @param registryManagerAddress   Address of the RegistryManager contract
        @param relevantList             Array of ids for contracts that are relevant for execution and are tracked for updates
    */
    constructor(address registryManagerAddress, uint16[] memory relevantList)
        public
    {
        require(
            relevantList[0] == 1,
            "The registry manager is required to create a registry type contract."
        );

        _idToContractAddress[1] = registryManagerAddress;
        _relevantList = relevantList;
        for (uint256 i = 0; i < relevantList.length; i++) {
            _idToIsRelevant[relevantList[i]] = true;
        }

        _registerInterface(type(IRegistry).interfaceId); // 0x7bbb2267
    }

    /**
        @notice Updates an incoming contract address for relevant contracts or itself. 
        @dev Updates an incoming contract address for relevant contracts or itself.
        Sets itself INACTIVE if it was updated by the registry.
        Sets itself ACTIVE if it was registered by the registry.
        @param contractAddress  The address of the contract update
        @param id               The id of the contract update
    */
    function updateContractAddress(address contractAddress, uint256 id)
        external
        override
        isCurrentStates(State.ACTIVE, State.INACTIVE)
        isAuthorizedRegistryManager()
    {
        // only execute if it's an relevant contract or this contract
        if (
            _idToIsRelevant[id] == true ||
            contractAddress == address(this) ||
            id == _registryId
        ) {
            // if this contract was updated, set INACTIVE
            if (id == _registryId) {
                _registryId = 0;
                _transitionINACTIVE();
            } else {
                // if this contract got registered, set ACTIVE
                if (contractAddress == address(this)) {
                    _registryId = id;
                    _transitionACTIVE();
                }
                _idToContractAddress[id] = contractAddress;
            }
        }
    }

    /**
        @notice Get the contract address of a specific id.
        @dev Get the contract address of a specific id.
        @param id   The contract id
        @return     The contract address of a specific id
    */
    function getContractAddress(uint256 id)
        public
        override
        view
        returns (address)
    {
        return _idToContractAddress[id];
    }

    /**
        @notice Get if a specific id is relevant for this contract.
        @dev Get if a specific id is relevant for this contract.
        @param id   The contract id
        @return     If the id is relevant for this contract
    */
    function isIdRelevant(uint256 id) public override view returns (bool) {
        return _idToIsRelevant[id];
    }

    /**
        @notice Get the list of relevant contract ids.
        @dev Get the list of relevant contract ids.
        @return The list of relevant contract ids.
    */
    function getRelevantList() public override view returns (uint16[] memory) {
        return _relevantList;
    }

    /**
        @notice Get this contract's registry id.
        @dev Get this contract's `_registryId`.
        @return Get this contract's registry id.
    */
    function getRegistryId() public override view returns (uint256) {
        return _registryId;
    }

    /**
        @dev Checks if the msg.sender is the RegistryManager.
        Reverts if msg.sender is not the RegistryManager.
    */
    function _isAuthorizedRegistryManager() internal view {
        require(
            msg.sender == _idToContractAddress[1],
            "Unauthorized call. Thanks for supporting the network with your ETH."
        );
    }
}

/**
    @author The Calystral Team
    @title A contract for the creation and minting of FTs and NFTS
    @dev Mintable form of ERC1155
*/
contract ERC1155CalystralMixedFungibleMintable is
    IERC1155CalystralMixedFungibleMintable,
    IERC1155Metadata_URI,
    ERC1155MixedFungible,
    Registry
{
    using Strings for string;

    /// @dev type id => minted supply
    mapping(uint256 => uint256) private _typeToMintedSupply;
    /// @dev type id => max supply
    mapping(uint256 => uint256) private _typeToMaxSupply;

    /// @dev type id => release timestamp
    mapping(uint256 => uint256) private _tokenTypeToReleaseTimestamp;
    /// @dev type nonce => type id
    mapping(uint256 => uint256) private _typeNonceToTypeId;

    /// @dev signer => burn nonce
    mapping(address => uint256) private _signerToMetaNonce;

    /// @dev A counter which is used to iterate over all existing type Ids. There is no type for _typeNonce 0.
    uint256 private _typeNonce;
    /// @dev Points to the base url of an api to receive meta data.
    string private _metadataBaseURI;

    /// @dev The maximum allowed supply for FTs and NFTs, half of uint256 is reserved for type and half for the index.
    uint256 private constant MAX_TYPE_SUPPLY = 2**128;

    modifier isAuthorizedAssetManager() {
        _isAuthorizedAssetManager();
        _;
    }

    modifier isValidTypeId(uint256 typeId) {
        _isValidTypeId(typeId);
        _;
    }

    /**
        @notice Initialized and creates the contract including the address of the RegistryManager and a list of relevant contract ids. 
        @dev Creates the contract with an initialized `registryManagerAddress` and `relevantList`.
        Registers this interface for ERC-165.
        Implements the Registry: Reverts if the `relevantList` does not include id 1 at index 0.
        @param registryManagerAddress   Address of the RegistryManager contract
        @param relevantList             Array of ids for contracts that are relevant for execution and are tracked for updates
    */
    constructor(address registryManagerAddress, uint16[] memory relevantList)
        public
        Registry(registryManagerAddress, relevantList)
        ERC1155()
    {
        _registerInterface(type(IERC1155Metadata_URI).interfaceId); // 0x0e89341c
    }

    function updateMetadataBaseURI(string calldata uri)
        external
        override
        isAnyState()
        isAuthorizedAssetManager()
    {
        _metadataBaseURI = uri;
    }

    function createNonFungibleType(uint256 maxSupply, uint256 releaseTimestamp)
        external
        override
        isCurrentState(State.ACTIVE)
        isAuthorizedAssetManager()
        returns (uint256)
    {
        uint256 result = _create(true, maxSupply);
        _setReleaseTimestamp(result, releaseTimestamp);
        return result;
    }

    function createFungibleType(uint256 maxSupply, uint256 releaseTimestamp)
        external
        override
        isCurrentState(State.ACTIVE)
        isAuthorizedAssetManager()
        returns (uint256)
    {
        uint256 result = _create(false, maxSupply);
        _setReleaseTimestamp(result, releaseTimestamp);
        return result;
    }

    function mintNonFungible(uint256 typeId, address[] calldata toArr)
        external
        override
        isCurrentState(State.ACTIVE)
        isAuthorizedAssetManager()
        isValidTypeId(typeId)
    {
        require(
            isNonFungible(typeId),
            "This typeId is not a non fungible type."
        );

        // Index are 1-based.
        uint256 index = _typeToMintedSupply[typeId] + 1;
        _typeToMintedSupply[typeId] += toArr.length;

        for (uint256 i = 0; i < toArr.length; ++i) {
            address to = toArr[i];
            uint256 id = typeId | (index + i);

            nfOwners[id] = to;

            emit TransferSingle(msg.sender, address(0x0), to, id, 1);

            if (to.isContract()) {
                _doSafeTransferAcceptanceCheck(
                    msg.sender,
                    msg.sender,
                    to,
                    id,
                    1,
                    ""
                );
            }
        }
        require(
            _typeToMintedSupply[typeId] <= _typeToMaxSupply[typeId],
            "Out of stock."
        );
    }

    function mintFungible(
        uint256 typeId,
        address[] calldata toArr,
        uint256[] calldata quantitiesArr
    )
        external
        override
        isCurrentState(State.ACTIVE)
        isAuthorizedAssetManager()
        isValidTypeId(typeId)
    {
        require(isFungible(typeId), "This typeId is not a fungible type.");
        require(
            toArr.length == quantitiesArr.length,
            "Array length must match."
        );

        for (uint256 i = 0; i < toArr.length; ++i) {
            address to = toArr[i];
            uint256 quantity = quantitiesArr[i];

            // Grant the items to the caller
            balances[typeId][to] += quantity;
            _typeToMintedSupply[typeId] += quantity;

            // the 0x0 source address implies a mint
            // It will also provide the circulating supply info.
            emit TransferSingle(msg.sender, address(0x0), to, typeId, quantity);

            if (to.isContract()) {
                _doSafeTransferAcceptanceCheck(
                    msg.sender,
                    msg.sender,
                    to,
                    typeId,
                    quantity,
                    ""
                );
            }
        }
        require(
            _typeToMintedSupply[typeId] <= _typeToMaxSupply[typeId],
            "Out of stock."
        );
    }

    function metaSafeTransferFrom(
        bytes32 r,
        bytes32 s,
        uint8 v,
        address signer,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data,
        uint256 nonce,
        uint256 maxTimestamp
    ) external virtual override isAnyState() isAuthorizedAny() {
        // Meta Transaction
        bytes32 dataHash = _getSafeTransferFromDataHash(
            signer,
            _to,
            _id,
            _value,
            _data,
            nonce,
            maxTimestamp
        );
        address signaturePublicKey = ECDSACalystral.recover(
            ECDSACalystral.toEthSignedMessageHash(dataHash),
            r,
            s,
            v
        );

        require(
            signer == signaturePublicKey ||
                operatorApproval[signer][signaturePublicKey] == true,
            "Need operator approval for 3rd party transfers."
        );
        require(
            block.timestamp < maxTimestamp,
            "This transaction is not valid anymore."
        );
        require(
            _signerToMetaNonce[signer] == nonce,
            "This transaction was executed already."
        );

        _signerToMetaNonce[signer]++;

        // Function Logic
        require(_to != address(0x0), "cannot send to zero address");

        if (isNonFungible(_id)) {
            require(nfOwners[_id] == signer);
            nfOwners[_id] = _to;
            // You could keep balance of NF type in base type id like so:
            // uint256 baseType = getNonFungibleBaseType(_id);
            // balances[baseType][signer] = balances[baseType][signer].sub(_value);
            // balances[baseType][_to]   = balances[baseType][_to].add(_value);
        } else {
            balances[_id][signer] = balances[_id][signer].sub(_value);
            balances[_id][_to] = balances[_id][_to].add(_value);
        }

        emit TransferSingle(msg.sender, signer, _to, _id, _value);

        if (_to.isContract()) {
            _doSafeTransferAcceptanceCheck(
                msg.sender,
                signer,
                _to,
                _id,
                _value,
                _data
            );
        }
    }

    function metaSafeBatchTransferFrom(
        bytes32 r,
        bytes32 s,
        uint8 v,
        address signer,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data,
        uint256 nonce,
        uint256 maxTimestamp
    ) external virtual override isAnyState() isAuthorizedAny() {
        // Meta Transaction
        address signaturePublicKey = ECDSACalystral.recover(
            ECDSACalystral.toEthSignedMessageHash(
                _getSafeBatchTransferFromDataHash(
                    signer,
                    _to,
                    _ids,
                    _values,
                    _data,
                    nonce,
                    maxTimestamp
                )
            ),
            r,
            s,
            v
        );

        require(
            signer == signaturePublicKey ||
                operatorApproval[signer][signaturePublicKey] == true,
            "Need operator approval for 3rd party transfers."
        );
        require(_ids.length == _values.length, "Array length must match.");
        require(
            block.timestamp < maxTimestamp,
            "This transaction is not valid anymore."
        );
        require(
            _signerToMetaNonce[signer] == nonce,
            "This transaction was executed already."
        );

        _signerToMetaNonce[signer]++;

        // Function Logic
        require(_to != address(0x0), "cannot send to zero address");
        require(_ids.length == _values.length, "Array length must match");

        for (uint256 i = 0; i < _ids.length; ++i) {
            if (isNonFungible(_ids[i])) {
                require(nfOwners[_ids[i]] == signer);
                nfOwners[_ids[i]] = _to;
            } else {
                balances[_ids[i]][signer] = balances[_ids[i]][signer].sub(
                    _values[i]
                );
                balances[_ids[i]][_to] = _values[i].add(balances[_ids[i]][_to]);
            }
        }

        emit TransferBatch(msg.sender, signer, _to, _ids, _values);

        if (_to.isContract()) {
            _doSafeBatchTransferAcceptanceCheck(
                msg.sender,
                signer,
                _to,
                _ids,
                _values,
                _data
            );
        }
    }

    function metaBatchBurn(
        bytes32 r,
        bytes32 s,
        uint8 v,
        address signer,
        uint256[] calldata ids,
        uint256[] calldata values,
        uint256 nonce,
        uint256 maxTimestamp
    ) external override isAnyState() isAuthorizedAssetManager() {
        // Meta Transaction
        bytes32 dataHash = _getBurnDataHash(ids, values, nonce, maxTimestamp);

        require(
            (
                ECDSACalystral.recover(
                    ECDSACalystral.toEthSignedMessageHash(dataHash),
                    r,
                    s,
                    v
                )
            ) == signer,
            "Invalid signature."
        );
        require(ids.length == values.length, "Array length must match.");
        require(
            block.timestamp < maxTimestamp,
            "This transaction is not valid anymore."
        );
        require(
            _signerToMetaNonce[signer] == nonce,
            "This transaction was executed already."
        );

        _signerToMetaNonce[signer]++;

        // Function Logic
        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];

            if (isNonFungible(id)) {
                require(nfOwners[id] == signer, "You are not the owner.");
                nfOwners[id] = address(0x0);
            } else {
                uint256 value = values[i];
                balances[id][signer] = balances[id][signer].sub(value);
            }
        }

        emit TransferBatch(msg.sender, signer, address(0x0), ids, values);
    }

    function metaSetApprovalForAll(
        bytes32 r,
        bytes32 s,
        uint8 v,
        address signer,
        address _operator,
        bool _approved,
        uint256 nonce,
        uint256 maxTimestamp
    ) external override isAnyState() isAuthorizedAny() {
        // Meta Transaction
        bytes32 dataHash = _getSetApprovalForAllHash(
            _operator,
            _approved,
            nonce,
            maxTimestamp
        );
        address signaturePublicKey = ECDSACalystral.recover(
            ECDSACalystral.toEthSignedMessageHash(dataHash),
            r,
            s,
            v
        );

        require(signaturePublicKey == signer, "Invalid signature.");
        require(
            block.timestamp < maxTimestamp,
            "This transaction is not valid anymore."
        );
        require(
            _signerToMetaNonce[signer] == nonce,
            "This transaction was executed already."
        );

        _signerToMetaNonce[signer]++;

        // Function Logic
        operatorApproval[signaturePublicKey][_operator] = _approved;
        emit ApprovalForAll(signaturePublicKey, _operator, _approved);
    }

    function setReleaseTimestamp(uint256 typeId, uint256 timestamp)
        external
        override
        isCurrentState(State.ACTIVE)
        isAuthorizedAssetManager()
        isValidTypeId(typeId)
    {
        _setReleaseTimestamp(typeId, timestamp);
    }

    function uri(uint256 _id) public override view returns (string memory) {
        return Strings.strConcat(_metadataBaseURI, Strings.uint2str(_id));
    }

    function getReleaseTimestamp(uint256 typeId)
        public
        override
        view
        isValidTypeId(typeId)
        returns (uint256)
    {
        return _tokenTypeToReleaseTimestamp[typeId];
    }

    function getTypeIds() public override view returns (uint256[] memory) {
        uint256[] memory resultIds = new uint256[](_typeNonce);
        for (uint256 i = 0; i < _typeNonce; i++) {
            resultIds[i] = getTypeId(i + 1);
        }
        return resultIds;
    }

    function getTypeId(uint256 typeNonce)
        public
        override
        view
        returns (uint256)
    {
        require(
            typeNonce <= _typeNonce && typeNonce != 0,
            "TypeNonce does not exist."
        );
        return _typeNonceToTypeId[typeNonce];
    }

    function getNonFungibleAssets(address owner)
        public
        override
        view
        returns (uint256[] memory)
    {
        uint256 counter;
        for (uint256 i = 1; i <= _typeNonce; i++) {
            uint256 typeId = (i << 128) | TYPE_NF_BIT;
            if (_typeToMaxSupply[typeId] != 0) {
                for (uint256 j = 1; j <= _typeToMintedSupply[typeId]; j++) {
                    uint256 id = typeId | j;
                    if (nfOwners[id] == owner) {
                        counter++;
                    }
                }
            }
        }

        uint256[] memory result = new uint256[](counter);
        counter = 0;
        for (uint256 i = 1; i <= _typeNonce; i++) {
            uint256 typeId = (i << 128) | TYPE_NF_BIT;
            if (_typeToMaxSupply[typeId] != 0) {
                for (uint256 j = 1; j <= _typeToMintedSupply[typeId]; j++) {
                    uint256 id = typeId | j;
                    if (nfOwners[id] == owner) {
                        result[counter] = id;
                        counter++;
                    }
                }
            }
        }
        return result;
    }

    function getFungibleAssets(address owner)
        public
        override
        view
        returns (uint256[] memory, uint256[] memory)
    {
        uint256 counter;
        for (uint256 i = 1; i <= _typeNonce; i++) {
            uint256 typeId = i << 128;
            if (_typeToMaxSupply[typeId] != 0) {
                if (balances[typeId][owner] > 0) {
                    counter++;
                }
            }
        }

        uint256[] memory resultIds = new uint256[](counter);
        uint256[] memory resultAmounts = new uint256[](counter);
        counter = 0;
        for (uint256 i = 1; i <= _typeNonce; i++) {
            uint256 typeId = i << 128;
            if (_typeToMaxSupply[typeId] != 0) {
                if (balances[typeId][owner] > 0) {
                    resultIds[counter] = typeId;
                    resultAmounts[counter] = balances[typeId][owner];
                    counter++;
                }
            }
        }
        return (resultIds, resultAmounts);
    }

    function getTypeNonce() public override view returns (uint256) {
        return _typeNonce;
    }

    function getMintedSupply(uint256 typeId)
        public
        override
        view
        isValidTypeId(typeId)
        returns (uint256)
    {
        return _typeToMintedSupply[typeId];
    }

    function getMaxSupply(uint256 typeId)
        public
        override
        view
        isValidTypeId(typeId)
        returns (uint256)
    {
        return _typeToMaxSupply[typeId];
    }

    function getMetaNonce(address signer)
        public
        override
        view
        returns (uint256)
    {
        return _signerToMetaNonce[signer];
    }

    /**
        @dev Checks if the AssetManager (from the Registry) is the msg.sender.
        Reverts if the msg.sender is not the correct AssetManager registered in the Registry.
    */
    function _isAuthorizedAssetManager() internal view {
        require(
            getContractAddress(4) == msg.sender,
            "Unauthorized call. Thanks for supporting the network with your ETH."
        );
    }

    /**
        @dev Checks if a given `typeId` exists.
        Reverts if given `typeId` does not exist.
        @param typeId The typeId which should be checked
    */
    function _isValidTypeId(uint256 typeId) internal view {
        require(_typeToMaxSupply[typeId] != 0, "TypeId does not exist.");
    }

    /**
        @dev Creates fungible and non-fungible types. This function only creates the type and is not used for minting.
        NFT types also has a maxSupply since there can be multiple tokens of the same type, e.g. 100x 'Pikachu'.
        Reverts if the `maxSupply` is 0 or exceeds the `MAX_TYPE_SUPPLY`.
        @param isNF         Flag if the creation should be a non-fungible, false for fungible tokens
        @param maxSupply    The maximum amount that can be created of this type, unlimited SHOULD be 2**128 (uint128) as the max. MUST NOT be set to 0
        @return             The `typeId`
    */
    function _create(bool isNF, uint256 maxSupply) private returns (uint256) {
        require(
            maxSupply != 0 && maxSupply <= MAX_TYPE_SUPPLY,
            "Minimum 1 and maximum 2**128 tokens of one type can exist."
        );

        // Store the type in the upper 128 bits
        uint256 typeId = (++_typeNonce << 128);

        // Set a flag if this is an NFI.
        if (isNF) typeId = typeId | TYPE_NF_BIT;

        _typeToMaxSupply[typeId] = maxSupply;
        _typeNonceToTypeId[_typeNonce] = typeId;

        // emit a Transfer event with Create semantic to help with discovery.
        emit TransferSingle(msg.sender, address(0x0), address(0x0), typeId, 0);

        return typeId;
    }

    /**
        @dev Sets a release timestamp.
        Reverts if `timestamp` == 0.
        Reverts if the `typeId` is released already.
        @param typeId       The type which should be set or updated
        @param timestamp    The timestamp for the release time, SHOULD be set to 1337 for releasing it right away. MUST NOT be set to 0
    */
    function _setReleaseTimestamp(uint256 typeId, uint256 timestamp) private {
        require(
            timestamp != 0,
            "A 0 timestamp is not allowed. For immediate release choose 1337."
        );
        require(
            _tokenTypeToReleaseTimestamp[typeId] == 0 ||
                _tokenTypeToReleaseTimestamp[typeId] > block.timestamp,
            "This token is released already."
        );
        _tokenTypeToReleaseTimestamp[typeId] = timestamp;

        emit OnReleaseTimestamp(typeId, timestamp);
    }

    /**
        @dev Get the data hash required for the meta transaction comparison of burn executions.
        @param ids          An array of token Ids which should be burned
        @param values       An array of amounts which should be burned. The order matches the order in the ids array
        @param nonce        Each sent meta transaction includes a nonce to prevent that a signed transaction is executed multiple times
        @param maxTimestamp The maximum point in time before the meta transaction expired, thus becoming invalid
        @return             The keccak256 hash of the data input
    */
    function _getBurnDataHash(
        uint256[] memory ids,
        uint256[] memory values,
        uint256 nonce,
        uint256 maxTimestamp
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(ids, values, nonce, maxTimestamp));
    }

    function _getSafeTransferFromDataHash(
        address signer,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes memory _data,
        uint256 nonce,
        uint256 maxTimestamp
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    signer,
                    _to,
                    _id,
                    _value,
                    _data,
                    nonce,
                    maxTimestamp
                )
            );
    }

    function _getSafeBatchTransferFromDataHash(
        address signer,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _values,
        bytes memory _data,
        uint256 nonce,
        uint256 maxTimestamp
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    signer,
                    _to,
                    _ids,
                    _values,
                    _data,
                    nonce,
                    maxTimestamp
                )
            );
    }

    function _getSetApprovalForAllHash(
        address _operator,
        bool _approved,
        uint256 nonce,
        uint256 maxTimestamp
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(_operator, _approved, nonce, maxTimestamp)
            );
    }
}

/**
    @author The Calystral Team
    @title The Assets' Interface
*/
interface IAssets {
    /**
        @dev MUST emit when any property type is created.
        The `propertyId` argument MUST be the id of a property.
        The `name` argument MUST be the name of this specific id.
        The `propertyType` argument MUST be the property type.
    */
    event OnCreateProperty(
        uint256 propertyId,
        string name,
        PropertyType indexed propertyType
    );
    /**
        @dev MUST emit when an int type property is updated.
        The `tokenId` argument MUST be the id of the token of which the property is updated.
        The `propertyId` argument MUST be the property id which is updated.
        The `value` argument MUST be the value to which the token's property is updated.
    */
    event OnUpdateIntProperty(
        uint256 indexed tokenId,
        uint256 indexed propertyId,
        int256 value
    );
    /**
        @dev MUST emit when an string type property is updated.
        The `tokenId` argument MUST be the id of the token of which the property is updated.
        The `propertyId` argument MUST be the property id which is updated.
        The `value` argument MUST be the value to which the token's property is updated.
    */
    event OnUpdateStringProperty(
        uint256 indexed tokenId,
        uint256 indexed propertyId,
        string value
    );
    /**
        @dev MUST emit when an address type property is updated.
        The `tokenId` argument MUST be the id of the token of which the property is updated.
        The `propertyId` argument MUST be the property id which is updated.
        The `value` argument MUST be the value to which the token's property is updated.
    */
    event OnUpdateAddressProperty(
        uint256 indexed tokenId,
        uint256 indexed propertyId,
        address value
    );
    /**
        @dev MUST emit when an byte type property is updated.
        The `tokenId` argument MUST be the id of the token of which the property is updated.
        The `propertyId` argument MUST be the property id which is updated.
        The `value` argument MUST be the value to which the token's property is updated.
    */
    event OnUpdateByteProperty(
        uint256 indexed tokenId,
        uint256 indexed propertyId,
        bytes32 value
    );
    /**
        @dev MUST emit when an int array type property is updated.
        The `tokenId` argument MUST be the id of the token of which the property is updated.
        The `propertyId` argument MUST be the property id which is updated.
        The `value` argument MUST be the value to which the token's property is updated.
    */
    event OnUpdateIntArrayProperty(
        uint256 indexed tokenId,
        uint256 indexed propertyId,
        int256[] value
    );
    /**
        @dev MUST emit when an address array type property is updated.
        The `tokenId` argument MUST be the id of the token of which the property is updated.
        The `propertyId` argument MUST be the property id which is updated.
        The `value` argument MUST be the value to which the token's property is updated.
    */
    event OnUpdateAddressArrayProperty(
        uint256 indexed tokenId,
        uint256 indexed propertyId,
        address[] value
    );

    /// @dev Enum representing all existing property types that can be used.
    enum PropertyType {INT, STRING, ADDRESS, BYTE, INTARRAY, ADDRESSARRAY}

    /**
        @notice Creates a property of type int.
        @dev Creates a property of type int.
        @param name The name for this property
        @return     The property id
    */
    function createIntProperty(string calldata name) external returns (uint256);

    /**
        @notice Creates a property of type string.
        @dev Creates a property of type string.
        @param name The name for this property
        @return     The property id
    */
    function createStringProperty(string calldata name)
        external
        returns (uint256);

    /**
        @notice Creates a property of type address.
        @dev Creates a property of type address.
        @param name The name for this property
        @return     The property id
    */
    function createAddressProperty(string calldata name)
        external
        returns (uint256);

    /**
        @notice Creates a property of type byte.
        @dev Creates a property of type byte.
        @param name The name for this property
        @return     The property id
    */
    function createByteProperty(string calldata name)
        external
        returns (uint256);

    /**
        @notice Creates a property of type int array.
        @dev Creates a property of type int array.
        @param name The name for this property
        @return     The property id
    */
    function createIntArrayProperty(string calldata name)
        external
        returns (uint256);

    /**
        @notice Creates a property of type address array.
        @dev Creates a property of type address array.
        @param name The name for this property
        @return     The property id
    */
    function createAddressArrayProperty(string calldata name)
        external
        returns (uint256);

    /**
        @notice Updates an existing int property for the passed value.
        @dev Updates an existing int property for the passed `value`.
        @param tokenId      The id of the token of which the property is updated
        @param propertyId   The property id which is updated
        @param value        The value to which the token's property is updated
    */
    function updateIntProperty(
        uint256 tokenId,
        uint256 propertyId,
        int256 value
    ) external;

    /**
        @notice Updates an existing string property for the passed value.
        @dev Updates an existing string property for the passed `value`.
        @param tokenId      The id of the token of which the property is updated
        @param propertyId   The property id which is updated
        @param value        The value to which the token's property is updated
    */
    function updateStringProperty(
        uint256 tokenId,
        uint256 propertyId,
        string calldata value
    ) external;

    /**
        @notice Updates an existing address property for the passed value.
        @dev Updates an existing address property for the passed `value`.
        @param tokenId      The id of the token of which the property is updated
        @param propertyId   The property id which is updated
        @param value        The value to which the token's property is updated
    */
    function updateAddressProperty(
        uint256 tokenId,
        uint256 propertyId,
        address value
    ) external;

    /**
        @notice Updates an existing byte property for the passed value.
        @dev Updates an existing byte property for the passed `value`.
        @param tokenId      The id of the token of which the property is updated
        @param propertyId   The property id which is updated
        @param value        The value to which the token's property is updated
    */
    function updateByteProperty(
        uint256 tokenId,
        uint256 propertyId,
        bytes32 value
    ) external;

    /**
        @notice Updates an existing int array property for the passed value.
        @dev Updates an existing int array property for the passed `value`.
        @param tokenId      The id of the token of which the property is updated
        @param propertyId   The property id which is updated
        @param value        The value to which the token's property is updated
    */
    function updateIntArrayProperty(
        uint256 tokenId,
        uint256 propertyId,
        int256[] calldata value
    ) external;

    /**
        @notice Updates an existing address array property for the passed value.
        @dev Updates an existing address array property for the passed `value`.
        @param tokenId      The id of the token of which the property is updated
        @param propertyId   The property id which is updated
        @param value        The value to which the token's property is updated
    */
    function updateAddressArrayProperty(
        uint256 tokenId,
        uint256 propertyId,
        address[] calldata value
    ) external;

    /**
        @notice Get the property type of a property.
        @dev Get the property type of a property.
        @return The property type
    */
    function getPropertyType(uint256 propertyId)
        external
        view
        returns (PropertyType);

    /**
        @notice Get the count of available properties.
        @dev Get the count of available properties.
        @return The property count
    */
    function getPropertyCounter() external view returns (uint256);
}

/**
    @author The Calystral Team
    @title A contract to manage all kind of assets (NFTs, FTs, and their arbitrary Properties)
    @dev Implements:
    IAssets
    IERC165
    IERC1155
    IERC1155Metadata_URI
    IERC1155CalystralMixedFungibleMintable
    ERC165
    ERC1155
    ERC1155MixedFungible
    ERC1155CalystralMixedFungibleMintable
    Registry
    ContractState
    CommonConstants    
*/
contract Assets is IAssets, ERC1155CalystralMixedFungibleMintable {
    /// @dev property id => property type
    mapping(uint256 => PropertyType) private _propertyIdToPropertyType;

    /// @dev A counter used to create the propertyId where propertyId 0 is not existing / reserved.
    uint256 propertyCounter;

    modifier isValidToken(uint256 tokenId) {
        _isValidToken(tokenId);
        _;
    }

    modifier isValidProperty(uint256 propertyId) {
        _isValidProperty(propertyId);
        _;
    }

    modifier isPropertyType(uint256 propertyId, PropertyType propertyType) {
        _isPropertyType(propertyId, propertyType);
        _;
    }

    /**
        @notice Initialized and creates the contract including the address of the RegistryManager and a list of relevant contract ids. 
        @dev Creates the contract with an initialized `registryManagerAddress` and `relevantList`.
        Sets the contract's state into INACTIVE.
        Implements the Registry: Reverts if the `relevantList` does not include id 1 at index 0.
        @param registryManagerAddress   Address of the RegistryManager contract
        @param relevantList             Array of ids for contracts that are relevant for execution and are tracked for updates
    */
    constructor(address registryManagerAddress, uint16[] memory relevantList)
        public
        ERC1155CalystralMixedFungibleMintable(
            registryManagerAddress,
            relevantList
        )
    {
        _transitionINACTIVE();
    }

    function createIntProperty(string calldata name)
        external
        override
        isCurrentState(State.ACTIVE)
        isAuthorizedAssetManager()
        returns (uint256)
    {
        return _createProperty(name, PropertyType.INT);
    }

    function createStringProperty(string calldata name)
        external
        override
        isCurrentState(State.ACTIVE)
        isAuthorizedAssetManager()
        returns (uint256)
    {
        return _createProperty(name, PropertyType.STRING);
    }

    function createAddressProperty(string calldata name)
        external
        override
        isCurrentState(State.ACTIVE)
        isAuthorizedAssetManager()
        returns (uint256)
    {
        return _createProperty(name, PropertyType.ADDRESS);
    }

    function createByteProperty(string calldata name)
        external
        override
        isCurrentState(State.ACTIVE)
        isAuthorizedAssetManager()
        returns (uint256)
    {
        return _createProperty(name, PropertyType.BYTE);
    }

    function createIntArrayProperty(string calldata name)
        external
        override
        isCurrentState(State.ACTIVE)
        isAuthorizedAssetManager()
        returns (uint256)
    {
        return _createProperty(name, PropertyType.INTARRAY);
    }

    function createAddressArrayProperty(string calldata name)
        external
        override
        isCurrentState(State.ACTIVE)
        isAuthorizedAssetManager()
        returns (uint256)
    {
        return _createProperty(name, PropertyType.ADDRESSARRAY);
    }

    function updateIntProperty(
        uint256 tokenId,
        uint256 propertyId,
        int256 value
    )
        external
        override
        isCurrentState(State.ACTIVE)
        isAuthorizedAssetManager()
        isValidToken(tokenId)
        isValidProperty(propertyId)
        isPropertyType(propertyId, PropertyType.INT)
    {
        emit OnUpdateIntProperty(tokenId, propertyId, value);
    }

    function updateStringProperty(
        uint256 tokenId,
        uint256 propertyId,
        string calldata value
    )
        external
        override
        isCurrentState(State.ACTIVE)
        isAuthorizedAssetManager()
        isValidToken(tokenId)
        isValidProperty(propertyId)
        isPropertyType(propertyId, PropertyType.STRING)
    {
        emit OnUpdateStringProperty(tokenId, propertyId, value);
    }

    function updateAddressProperty(
        uint256 tokenId,
        uint256 propertyId,
        address value
    )
        external
        override
        isCurrentState(State.ACTIVE)
        isAuthorizedAssetManager()
        isValidToken(tokenId)
        isValidProperty(propertyId)
        isPropertyType(propertyId, PropertyType.ADDRESS)
    {
        emit OnUpdateAddressProperty(tokenId, propertyId, value);
    }

    function updateByteProperty(
        uint256 tokenId,
        uint256 propertyId,
        bytes32 value
    )
        external
        override
        isCurrentState(State.ACTIVE)
        isAuthorizedAssetManager()
        isValidToken(tokenId)
        isValidProperty(propertyId)
        isPropertyType(propertyId, PropertyType.BYTE)
    {
        emit OnUpdateByteProperty(tokenId, propertyId, value);
    }

    function updateIntArrayProperty(
        uint256 tokenId,
        uint256 propertyId,
        int256[] calldata value
    )
        external
        override
        isCurrentState(State.ACTIVE)
        isAuthorizedAssetManager()
        isValidToken(tokenId)
        isValidProperty(propertyId)
        isPropertyType(propertyId, PropertyType.INTARRAY)
    {
        emit OnUpdateIntArrayProperty(tokenId, propertyId, value);
    }

    function updateAddressArrayProperty(
        uint256 tokenId,
        uint256 propertyId,
        address[] calldata value
    )
        external
        override
        isCurrentState(State.ACTIVE)
        isAuthorizedAssetManager()
        isValidToken(tokenId)
        isValidProperty(propertyId)
        isPropertyType(propertyId, PropertyType.ADDRESSARRAY)
    {
        emit OnUpdateAddressArrayProperty(tokenId, propertyId, value);
    }

    function getPropertyType(uint256 propertyId)
        public
        override
        view
        isValidProperty(propertyId)
        returns (PropertyType)
    {
        return _propertyIdToPropertyType[propertyId];
    }

    function getPropertyCounter() public override view returns (uint256) {
        return propertyCounter;
    }

    /**
        @dev Checks if the `tokenId` exists:
        NFs are checked via `nfOwners` mapping.
        NFTs are checked via `getMaxSupply` function.
        @param tokenId  The tokenId which should be checked
    */
    function _isValidToken(uint256 tokenId) internal view {
        if (isNonFungible(tokenId)) {
            require(
                nfOwners[tokenId] != address(0x0),
                "TokenId does not exist."
            );
        } else {
            require(getMaxSupply(tokenId) != 0, "TokenId does not exist.");
        }
    }

    /**
        @dev Checks if the `propertyId` exists.
        @param propertyId  The propertyId which should be checked
    */
    function _isValidProperty(uint256 propertyId) internal view {
        require(
            propertyId <= propertyCounter && propertyId != 0,
            "Invalid property requested."
        );
    }

    /**
        @dev Checks if a given `propertyId` matches the given `propertyType`.
        @param propertyId   The propertyId which should be checked
        @param propertyType The PropertyType which should be checked against
    */
    function _isPropertyType(uint256 propertyId, PropertyType propertyType)
        internal
        view
    {
        require(
            _propertyIdToPropertyType[propertyId] == propertyType,
            "The given property id does not match the property type."
        );
    }

    /**
        @dev Creates a new property.
        @param name         The name of the property
        @param propertyType The PropertyType of the property
        @return             The propertyId of the property
    */
    function _createProperty(string memory name, PropertyType propertyType)
        private
        returns (uint256)
    {
        propertyCounter++; // propertyCounter starts with 1 for the first attribute
        _propertyIdToPropertyType[propertyCounter] = propertyType;

        emit OnCreateProperty(propertyCounter, name, propertyType);

        return propertyCounter;
    }
}