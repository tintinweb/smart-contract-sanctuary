/**
 *Submitted for verification at polygonscan.com on 2021-11-11
*/

// Sources flattened with hardhat v2.6.1 https://hardhat.org

// File contracts/metatx/ManagedIdentity.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

/*
 * Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner.
 */
abstract contract ManagedIdentity {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        return msg.data;
    }
}


// File contracts/utils/access/IERC173.sol



pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC-173 Contract Ownership Standard
 * Note: the ERC-165 identifier for this interface is 0x7f5828d0
 */
interface IERC173 {
    /**
     * Event emited when ownership of a contract changes.
     * @param previousOwner the previous owner.
     * @param newOwner the new owner.
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * Get the address of the owner
     * @return The address of the owner.
     */
    function owner() external view returns (address);

    /**
     * Set the address of the new owner of the contract
     * Set newOwner to address(0) to renounce any ownership.
     * @dev Emits an {OwnershipTransferred} event.
     * @param newOwner The address of the new owner of the contract. Using the zero address means renouncing ownership.
     */
    function transferOwnership(address newOwner) external;
}


// File contracts/utils/access/Ownable.sol



pragma solidity >=0.7.6 <0.8.0;


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
abstract contract Ownable is ManagedIdentity, IERC173 {
    address internal _owner;

    /**
     * Initializes the contract, setting the deployer as the initial owner.
     * @dev Emits an {IERC173-OwnershipTransferred(address,address)} event.
     */
    constructor(address owner_) {
        _owner = owner_;
        emit OwnershipTransferred(address(0), owner_);
    }

    /**
     * Gets the address of the current contract owner.
     */
    function owner() public view virtual override returns (address) {
        return _owner;
    }

    /**
     * See {IERC173-transferOwnership(address)}
     * @dev Reverts if the sender is not the current contract owner.
     * @param newOwner the address of the new owner. Use the zero address to renounce the ownership.
     */
    function transferOwnership(address newOwner) public virtual override {
        _requireOwnership(_msgSender());
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
    }

    /**
     * @dev Reverts if `account` is not the contract owner.
     * @param account the account to test.
     */
    function _requireOwnership(address account) internal virtual {
        require(account == this.owner(), "Ownable: not the owner");
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
}


// File contracts/utils/Pausable.sol



pragma solidity >=0.7.6 <0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is ManagedIdentity {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

     /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


// File contracts/utils/cryptography/ECDSA.sol



pragma solidity >=0.7.6 <0.8.0;

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


// File contracts/token/ERC20/IERC20.sol



pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC20 Token Standard, basic interface.
 * @dev See https://eips.ethereum.org/EIPS/eip-20
 * @dev Note: The ERC-165 identifier for this interface is 0x36372b07.
 */
interface IERC20 {
    /**
     * @dev Emitted when tokens are transferred, including zero value transfers.
     * @param _from The account where the transferred tokens are withdrawn from.
     * @param _to The account where the transferred tokens are deposited to.
     * @param _value The amount of tokens being transferred.
     */
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    /**
     * @dev Emitted when a successful call to {IERC20-approve(address,uint256)} is made.
     * @param _owner The account granting an allowance to `_spender`.
     * @param _spender The account being granted an allowance from `_owner`.
     * @param _value The allowance amount being granted.
     */
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /**
     * @notice Returns the total token supply.
     * @return The total token supply.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Returns the account balance of another account with address `owner`.
     * @param owner The account whose balance will be returned.
     * @return The account balance of another account with address `owner`.
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * Transfers `value` amount of tokens to address `to`.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if the sender does not have enough balance.
     * @dev Emits an {IERC20-Transfer} event.
     * @dev Transfers of 0 values are treated as normal transfers and fire the {IERC20-Transfer} event.
     * @param to The receiver account.
     * @param value The amount of tokens to transfer.
     * @return True if the transfer succeeds, false otherwise.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @notice Transfers `value` amount of tokens from address `from` to address `to`.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if `from` does not have at least `value` of balance.
     * @dev Reverts if the sender is not `from` and has not been approved by `from` for at least `value`.
     * @dev Emits an {IERC20-Transfer} event.
     * @dev Transfers of 0 values are treated as normal transfers and fire the {IERC20-Transfer} event.
     * @param from The emitter account.
     * @param to The receiver account.
     * @param value The amount of tokens to transfer.
     * @return True if the transfer succeeds, false otherwise.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    /**
     * Sets `value` as the allowance from the caller to `spender`.
     *  IMPORTANT: Beware that changing an allowance with this method brings the risk
     *  that someone may use both the old and the new allowance by unfortunate
     *  transaction ordering. One possible solution to mitigate this race
     *  condition is to first reduce the spender's allowance to 0 and set the
     *  desired value afterwards: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @dev Reverts if `spender` is the zero address.
     * @dev Emits the {IERC20-Approval} event.
     * @param spender The account being granted the allowance by the message caller.
     * @param value The allowance amount to grant.
     * @return True if the approval succeeds, false otherwise.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * Returns the amount which `spender` is allowed to spend on behalf of `owner`.
     * @param owner The account that has granted an allowance to `spender`.
     * @param spender The account that was granted an allowance by `owner`.
     * @return The amount which `spender` is allowed to spend on behalf of `owner`.
     */
    function allowance(address owner, address spender) external view returns (uint256);
}


// File contracts/interfaces/IGBotInventory.sol



pragma solidity >=0.7.6 <0.8.0;

interface IGBotInventory {
    function mintGBot(address to, uint256 nftId, uint256 metadata, bytes memory data) external;
    function getMetadata(uint256 tokenId) external view returns (uint256 metadata);
    function upgradeGBot(uint256 newMetadata, uint256 tokenId) external;

    /**
     * Gets the balance of the specified address
     * @param owner address to query the balance of
     * @return balance uint256 representing the amount owned by the passed address
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * Gets the owner of the specified ID
     * @param tokenId uint256 ID to query the owner of
     * @return owner address currently marked as the owner of the given ID
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

        /**
     * Safely transfers the ownership of a given token ID to another address
     *
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     *
     * @dev Requires the msg sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}


// File contracts/interfaces/IGBotMetadataGenerator.sol



pragma solidity >=0.7.6 <0.8.0;

interface IGBotMetadataGenerator {
    function generateMetadata(uint256 packTier, uint256 seed, uint256 counter) external view returns (uint256 metadata);
    function validateMetadata(uint256 metadata) external pure returns (bool valid);
    function upgradeMetadata(uint256 metadata, uint256 position, uint256 propertyValue) external pure returns (uint256 newMetadata);
}


// File contracts/interfaces/IGBotPacksInventory.sol



pragma solidity >=0.7.6 <0.8.0;

interface IGBotPacksInventory {
    function collectionOf(uint256 nftId) external pure returns (uint256);

     /**
     * Burns some token (ERC1155-compatible).
     * @dev Reverts if the sender is not approved.
     * @dev Reverts if `id` does not represent a token.
     * @dev Reverts if `id` represents a fungible token and `value` is 0.
     * @dev Reverts if `id` represents a fungible token and `value` is higher than `from`'s balance.
     * @dev Reverts if `id` represents a non-fungible token and `value` is not 1.
     * @dev Reverts if `id` represents a non-fungible token which is not owned by `from`.
     * @dev Emits an {IERC721-Transfer} event to the zero address if `id` represents a non-fungible token.
     * @dev Emits an {IERC1155-TransferSingle} event to the zero address.
     * @param from Address of the current token owner.
     * @param id Identifier of the token to burn.
     * @param value Amount of token to burn.
     */
    function burnFrom(
        address from,
        uint256 id,
        uint256 value
    ) external;

    /**
     * Burns multiple tokens (ERC1155-compatible).
     * @dev Reverts if `ids` and `values` have different lengths.
     * @dev Reverts if the sender is not approved.
     * @dev Reverts if one of `ids` does not represent a token.
     * @dev Reverts if one of `ids` represents a fungible token and `value` is 0.
     * @dev Reverts if one of `ids` represents a fungible token and `value` is higher than `from`'s balance.
     * @dev Reverts if one of `ids` represents a non-fungible token and `value` is not 1.
     * @dev Reverts if one of `ids` represents a non-fungible token which is not owned by `from`.
     * @dev Emits an {IERC721-Transfer} event to the zero address for each burnt non-fungible token.
     * @dev Emits an {IERC1155-TransferBatch} event to the zero address.
     * @param from Address of the current tokens owner.
     * @param ids Identifiers of the tokens to burn.
     * @param values Amounts of tokens to burn.
     */
    function batchBurnFrom(
        address from,
        uint256[] calldata ids,
        uint256[] calldata values
    ) external;

    /**
     * Burns a batch of Non-Fungible Tokens (ERC721-compatible).
     * @dev Reverts if the sender is not approved.
     * @dev Reverts if one of `nftIds` does not represent a non-fungible token.
     * @dev Reverts if one of `nftIds` is not owned by `from`.
     * @dev Emits an {IERC721-Transfer} event to the zero address for each of `nftIds`.
     * @dev Emits an {IERC1155-TransferBatch} event to the zero address.
     * @param from Current token owner.
     * @param nftIds Identifiers of the tokens to transfer.
     */
    function batchBurnFrom(address from, uint256[] calldata nftIds) external;
}


// File contracts/game/GBotPackOpener/OpenerProperties.sol



pragma solidity >=0.7.6 <0.8.0;

abstract contract OpenerProps {
    
// GBots rarity
    uint internal constant GBOT_RARITY_STARTER = 0;
    uint internal constant GBOT_RARITY_COMMON = 1;
    uint internal constant GBOT_RARITY_RARE = 2;
    uint internal constant GBOT_RARITY_EPIC = 3;
    uint internal constant GBOT_RARITY_LEGENDARY = 4;
    uint internal constant GBOT_RARITY_UNIQUE = 5;
    uint internal constant GBOT_RARITY_MYTHICAL = 6;

    //============================================================================================/
    //================================== PACK RARITIES ===========================================/
    //============================================================================================/

    uint256 internal constant PACK_TIER_COMMON = 1;
    uint256 internal constant PACK_TIER_RARE = 2;
    uint256 internal constant PACK_TIER_EPIC = 3;
    uint256 internal constant PACK_TIER_LEGENDARY = 4;

    //============================================================================================/
    //================================== Rarity Drop Rates  ======================================/
    //============================================================================================/

    uint256 internal constant _COMMON_PACK_DROP_RATE_THRESH_COMMON = 84.600 * 1000;
    uint256 internal constant _COMMON_PACK_DROP_RATE_THRESH_RARE = 14 * 1000;
    uint256 internal constant _COMMON_PACK_DROP_RATE_THRESH_EPIC = 1 * 1000;
    uint256 internal constant _COMMON_PACK_DROP_RATE_THRESH_LEGENDARY = 0.400 * 1000;
    uint256 internal constant _COMMON_PACK_DROP_RATE_THRESH_UNIQUE = 0;
    uint256 internal constant _COMMON_PACK_DROP_RATE_THRESH_MYTHICAL = 0;
 
    uint256 internal constant _RARE_PACK_DROP_RATE_THRESH_COMMON = 0;
    uint256 internal constant _RARE_PACK_DROP_RATE_THRESH_RARE = 84.600 * 1000;
    uint256 internal constant _RARE_PACK_DROP_RATE_THRESH_EPIC = 14 * 1000;
    uint256 internal constant _RARE_PACK_DROP_RATE_THRESH_LEGENDARY = 1 * 1000;
    uint256 internal constant _RARE_PACK_DROP_RATE_THRESH_UNIQUE = 0.400 * 1000;
    uint256 internal constant _RARE_PACK_DROP_RATE_THRESH_MYTHICAL = 0;
 
    uint256 internal constant _EPIC_PACK_DROP_RATE_THRESH_COMMON = 0;
    uint256 internal constant _EPIC_PACK_DROP_RATE_THRESH_RARE = 0;
    uint256 internal constant _EPIC_PACK_DROP_RATE_THRESH_EPIC = 82 * 1000;
    uint256 internal constant _EPIC_PACK_DROP_RATE_THRESH_LEGENDARY = 16 * 1000;
    uint256 internal constant _EPIC_PACK_DROP_RATE_THRESH_UNIQUE = 2 * 1000;
    uint256 internal constant _EPIC_PACK_DROP_RATE_THRESH_MYTHICAL = 0;
 
    uint256 internal constant _LEGENDARY_PACK_DROP_RATE_THRESH_COMMON = 0;
    uint256 internal constant _LEGENDARY_PACK_DROP_RATE_THRESH_RARE = 0;
    uint256 internal constant _LEGENDARY_PACK_DROP_RATE_THRESH_EPIC = 0;
    uint256 internal constant _LEGENDARY_PACK_DROP_RATE_THRESH_LEGENDARY = 92 * 1000;
    uint256 internal constant _LEGENDARY_PACK_DROP_RATE_THRESH_UNIQUE = 8 * 1000;
    uint256 internal constant _LEGENDARY_PACK_DROP_RATE_THRESH_MYTHICAL = 0;
}


// File contracts/introspection/IERC165.sol



pragma solidity >=0.7.6 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165.
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


// File contracts/token/ERC1155/IERC1155TokenReceiver.sol



pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC1155 Multi Token Standard, Tokens Receiver.
 * Interface for any contract that wants to support transfers from ERC1155 asset contracts.
 * @dev See https://eips.ethereum.org/EIPS/eip-1155
 * @dev Note: The ERC-165 identifier for this interface is 0x4e2312e0.
 */
interface IERC1155TokenReceiver {
    /**
     * @notice Handle the receipt of a single ERC1155 token type.
     * An ERC1155 contract MUST call this function on a recipient contract, at the end of a `safeTransferFrom` after the balance update.
     * This function MUST return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     *  (i.e. 0xf23a6e61) to accept the transfer.
     * Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
     * @param operator  The address which initiated the transfer (i.e. msg.sender)
     * @param from      The address which previously owned the token
     * @param id        The ID of the token being transferred
     * @param value     The amount of tokens being transferred
     * @param data      Additional data with no specified format
     * @return bytes4   `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @notice Handle the receipt of multiple ERC1155 token types.
     * An ERC1155 contract MUST call this function on a recipient contract, at the end of a `safeBatchTransferFrom` after the balance updates.
     * This function MUST return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     *  (i.e. 0xbc197c81) if to accept the transfer(s).
     * Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
     * @param operator  The address which initiated the batch transfer (i.e. msg.sender)
     * @param from      The address which previously owned the token
     * @param ids       An array containing ids of each token being transferred (order and length must match _values array)
     * @param values    An array containing amounts of each token being transferred (order and length must match _ids array)
     * @param data      Additional data with no specified format
     * @return          `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}


// File contracts/token/ERC1155/ERC1155TokenReceiver.sol



pragma solidity >=0.7.6 <0.8.0;


/**
 * @title ERC1155 Transfers Receiver Contract.
 * @dev The functions `onERC1155Received(address,address,uint256,uint256,bytes)`
 *  and `onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)` need to be implemented by a child contract.
 */
abstract contract ERC1155TokenReceiver is IERC165, IERC1155TokenReceiver {
    // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
    bytes4 internal constant _ERC1155_RECEIVED = 0xf23a6e61;

    // bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
    bytes4 internal constant _ERC1155_BATCH_RECEIVED = 0xbc197c81;

    bytes4 internal constant _ERC1155_REJECTED = 0xffffffff;

    //======================================================= ERC165 ========================================================//

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(IERC1155TokenReceiver).interfaceId;
    }
}


// File contracts/game/GBotPackOpener/GBotPackOpener.sol



pragma solidity >=0.7.6 <0.8.0;









// Opens the GBot Pack and mints a GBot based on it
contract GBotPackOpener is ERC1155TokenReceiver, Ownable, Pausable, OpenerProps {
    using ECDSA for bytes32;

    // account => packTier => nonce
    mapping(address => mapping(uint256 => uint256)) public nonces;

    address public signerKey;
    uint256 counter = 1;

    IGBotInventory private gBotContract;
    IGBotMetadataGenerator private metadataGeneratorContract;
    IGBotPacksInventory private gBotPacksContract;

    event PackOpened(uint256 packTier, address to);
    
    constructor(
        address gBotInventory,
        address gBotPackInventory,
        address metadataRepository
    ) Ownable(msg.sender) {
        gBotPacksContract = IGBotPacksInventory(gBotPackInventory);
        metadataGeneratorContract = IGBotMetadataGenerator(metadataRepository);
        gBotContract = IGBotInventory(gBotInventory);
    }

    function setSignerKey(address signerKey_) external onlyOwner {
        signerKey = signerKey_;
    } 
    
    
    function openPack(bytes calldata sig, uint256 collectionId) private {
        require(signerKey != address(0), "GBot PackOpener: signer key not set");
        // Determine collection type
        uint packTier = collectionId; //determinePackTier(collectionId);
        // Check for signer key and get seed out of it
        address sender = msg.sender;
        uint256 nonce = nonces[sender][packTier];
        bytes32 hash_ = keccak256(abi.encodePacked(sender, packTier, nonce));
        require(hash_.toEthSignedMessageHash().recover(sig) == signerKey, "GBot PackOpener: invalid signature");
        uint256 seed = uint256(keccak256(sig));

        bytes memory data = "";
        // Determine bot rarity
        uint256 gBotRarity = determineRarity(packTier, seed);
        // Generate metadata
        uint256 metadata = metadataGeneratorContract.generateMetadata(gBotRarity, seed, counter);
        // Create G bot
        uint256 nftId = metadata;
        gBotContract.mintGBot(sender, nftId, metadata, data);
        
        nonces[sender][packTier] = nonce + 1;
        counter++;
        emit PackOpened(packTier, sender);
    }

    function determineRarity(uint256 packTier, uint256 seed) private pure returns (uint256 rarity) {
    require(packTier >= PACK_TIER_COMMON && packTier <= PACK_TIER_LEGENDARY, "GBotPackOpener: Rarity out of range");
    uint256 seedling = seed % 100000; // > 16 bits, reserve 32

    if (packTier == PACK_TIER_COMMON) {
            if (seedling < _COMMON_PACK_DROP_RATE_THRESH_LEGENDARY) {
                return GBOT_RARITY_LEGENDARY;
            }
            if (seedling < _COMMON_PACK_DROP_RATE_THRESH_EPIC) {
                return GBOT_RARITY_EPIC;
            }
            if (seedling < _COMMON_PACK_DROP_RATE_THRESH_RARE) {
                return GBOT_RARITY_RARE;
            }
            return GBOT_RARITY_COMMON;
        }
    if (packTier == PACK_TIER_RARE) {
            if (seedling < _RARE_PACK_DROP_RATE_THRESH_UNIQUE) {
                return GBOT_RARITY_UNIQUE;
            }
            if (seedling < _RARE_PACK_DROP_RATE_THRESH_LEGENDARY) {
                return GBOT_RARITY_LEGENDARY;
            }
            if (seedling < _RARE_PACK_DROP_RATE_THRESH_EPIC) {
                return GBOT_RARITY_EPIC;
            }
            return GBOT_RARITY_RARE;
        }
    if (packTier == PACK_TIER_EPIC) {
            if (seedling < _EPIC_PACK_DROP_RATE_THRESH_UNIQUE) {
                return GBOT_RARITY_UNIQUE;
            }
            if (seedling < _EPIC_PACK_DROP_RATE_THRESH_LEGENDARY) {
                return GBOT_RARITY_LEGENDARY;
            }
            return GBOT_RARITY_EPIC;
        }
    if (packTier == PACK_TIER_LEGENDARY) {
            if (seedling < _LEGENDARY_PACK_DROP_RATE_THRESH_UNIQUE) {
                return GBOT_RARITY_UNIQUE;
            }
            return GBOT_RARITY_LEGENDARY;
        }
    }

    function determinePackTier(uint256 id) private pure returns (uint256) {
        uint bits = 8;
        uint position = 222;
        uint ONES = uint(~0);
        return id >> position & ONES >> 256 - bits;
    }

    /**
     * @notice ERC1155 single transfer receiver which redeem a voucher.
     * @dev Reverts if the transfer was not operated through `gBotPacks contract`.
     * @dev Reverts if the `id` is zero.
     * @dev Reverts if the `value` is zero.
     * @param /operator the address which initiated the transfer (i.e. msg.sender).
     * @param from the address which previously owned the pack.
     * @param id the pack id.
     * @param value the pack value.
     * @param /data additional data with no specified format.
     * @return bytes4 `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`.
     */
    function onERC1155Received(
        address, /*operator*/
        address from,
        uint256 id, /*collectionId*/
        uint256 value,
        bytes calldata sig /*data*/
    ) external virtual override whenNotPaused returns (bytes4) {
        require(msg.sender == address(gBotPacksContract), "GBotPackOpener: wrong inventory");
        require(id != 0, "GBotPackOpener: invalid pack id");
        require(value != 0, "GBotPackOpener: invalid value");
        openPack(sig, id);
        gBotPacksContract.burnFrom(from, id, value);
        return _ERC1155_RECEIVED;
    }
         /**
     * @notice ERC1155 batch transfer receiver which redeem a batch of vouchers.
     * @dev Reverts if the transfer was not operated through `gameeVouchersContract`.
     * @dev Reverts if `ids` is an empty array.
     * @dev Reverts if `values` is an empty array.
     * @dev Reverts if `ids` and `values` have different lengths.
     * @dev Emits an ERC1155 TransferBatch event for the redeemed vouchers.
     * @dev Emits an ERC20 Transfer event for the GAMME transfer operation.
     * @dev Emits a VoucherRedeemedBatch event.
     * @param /operator the address which initiated the transfer (i.e. msg.sender).
     * @param from the address which previously owned the voucher.
     * @param ids the vouchers ids.
     * @param values the vouchers values.
     * @param /data additional data with no specified format.
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`.
     */
    function onERC1155BatchReceived(
        address, /*operator*/
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata sig /*data*/
    ) external virtual override whenNotPaused returns (bytes4) {
        require(msg.sender == address(gBotPacksContract), "GBotPackOpener: wrong inventory");
        
        for (uint256 i = 0; i < ids.length; i++) {
            openPack(sig, i);
        }

        gBotPacksContract.batchBurnFrom(from, ids, values);
        return _ERC1155_BATCH_RECEIVED;
    }
}