// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal initializer {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
        __ERC1155Holder_init_unchained();
    }

    function __ERC1155Holder_init_unchained() internal initializer {
    }
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal initializer {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
    }

    function __ERC1155Receiver_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal initializer {
        __ERC721Holder_init_unchained();
    }

    function __ERC721Holder_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface IBounty {
    function redeemBounty(
        IBountyRedeemer redeemer,
        uint256 amount,
        bytes calldata data
    ) external;
}

interface IBountyRedeemer {
    function onRedeemBounty(address initiator, bytes calldata data)
        external
        payable
        returns (bytes32);
}

enum BountyType {
    ERC20,
    ERC1155
}

abstract contract AbstractBounty is
    ReentrancyGuardUpgradeable,
    ERC721HolderUpgradeable,
    IBounty
{
    using Counters for Counters.Counter;

    enum BountyStatus {
        ACTIVE,
        ACQUIRED,
        EXPIRED
    }

    struct Contribution {
        uint256 priorTotalContributed;
        uint256 amount;
    }

    // immutable (across clones)
    address public immutable gov;

    // immutable (at clone level)
    IERC721 public nftContract;
    uint256 public nftTokenID;
    string public name;
    uint256 public contributionCap;
    uint256 public expiryTimestamp;

    // mutables
    mapping(address => Contribution[]) public contributions;
    mapping(address => uint256) public totalContributedByAddress;
    mapping(address => bool) public claimed;
    uint256 public totalContributed;
    uint256 public totalSpent;
    Counters.Counter public contributors;

    event Contributed(
        address indexed contributor,
        uint256 amount,
        uint256 totalContributedByAddress,
        uint256 totalContributed
    );

    event Acquired(uint256 amount);

    event Claimed(
        address indexed contributor,
        uint256 tokenAmount,
        uint256 ethAmount
    );

    modifier onlyGov() {
        require(msg.sender == gov, "Bounty:: only callable by gov");
        _;
    }

    constructor(address _gov) {
        gov = _gov;
    }

    function __AbstractBounty_init(
        IERC721 _nftContract,
        uint256 _nftTokenID,
        string memory _name,
        uint256 _contributionCap,
        uint256 _duration
    ) internal initializer {
        __ReentrancyGuard_init();
        __ERC721Holder_init();

        nftContract = _nftContract;
        nftTokenID = _nftTokenID;
        name = _name;
        contributionCap = _contributionCap;
        expiryTimestamp = block.timestamp + _duration;

        require(
            IERC721(_nftContract).ownerOf(_nftTokenID) != address(0),
            "Bounty::initialize: Token does not exist"
        );
    }

    // @notice contribute (via msg.value) to active bounty as long as the contribution cap has not been reached
    function contribute() public payable virtual nonReentrant {
        require(
            status() == BountyStatus.ACTIVE,
            "Bounty::contribute: bounty not active"
        );
        address _contributor = msg.sender;
        uint256 _amount = msg.value;
        require(_amount > 0, "Bounty::contribute: must contribute more than 0");
        require(
            totalContributed < contributionCap,
            "Bounty::contribute: at max contributions"
        );

        if (contributions[_contributor].length == 0) {
            contributors.increment();
        }

        Contribution memory _contribution = Contribution({
            amount: _amount,
            priorTotalContributed: totalContributed
        });
        contributions[_contributor].push(_contribution);
        totalContributedByAddress[_contributor] =
            totalContributedByAddress[_contributor] +
            _amount;
        totalContributed = totalContributed + _amount;
        emit Contributed(
            _contributor,
            _amount,
            totalContributedByAddress[_contributor],
            totalContributed
        );
    }

    // @notice uses the redeemer to swap `_amount` ETH for the NFT
    // @param _redeemer The callback to acquire the NFT
    // @param _amount The amount of the bounty to redeem. Must be <= MIN(totalContributed, contributionCap)
    // @param _data Arbitrary calldata for the callback
    function redeemBounty(
        IBountyRedeemer _redeemer,
        uint256 _amount,
        bytes calldata _data
    ) public override nonReentrant {
        require(
            status() == BountyStatus.ACTIVE,
            "Bounty::redeemBounty: bounty isn't active"
        );
        require(totalSpent == 0, "Bounty::redeemBounty: already acquired");
        require(_amount > 0, "Bounty::redeemBounty: cannot redeem for free");
        require(
            _amount <= totalContributed && _amount <= contributionCap,
            "Bounty::redeemBounty: not enough funds"
        );
        uint256 fee = computeFee(_amount);
        totalSpent = _amount + fee;
        require(
            _redeemer.onRedeemBounty{value: _amount}(msg.sender, _data) ==
                keccak256("IBountyRedeemer.onRedeemBounty"),
            "Bounty::redeemBounty: callback failed"
        );
        require(
            IERC721(nftContract).ownerOf(nftTokenID) == address(this),
            "Bounty::redeemBounty: NFT not delivered"
        );
        emit Acquired(_amount);
    }

    // @notice Kicks off fractionalization once the NFT is acquired
    // @dev Also triggered by the first claim()
    function fractionalize() external nonReentrant {
        require(
            status() == BountyStatus.ACQUIRED,
            "Bounty::fractionalize: NFT not yet acquired"
        );
        _fractionalizeNFTIfNeeded();
    }

    // @notice Claims any tokens or eth for `_contributor` from active or expired bounties
    // @dev msg.sender does not necessarily match `_contributor`
    // @dev O(N) where N = number of contributions by `_contributor`
    // @param _contributor The address of the contributor to claim tokens for
    function claim(address _contributor) external nonReentrant {
        BountyStatus _status = status();
        require(
            _status != BountyStatus.ACTIVE,
            "Bounty::claim: bounty still active"
        );
        require(
            totalContributedByAddress[_contributor] != 0,
            "Bounty::claim: not a contributor"
        );
        require(
            !claimed[_contributor],
            "Bounty::claim: bounty already claimed"
        );
        claimed[_contributor] = true;

        if (_status == BountyStatus.ACQUIRED) {
            _fractionalizeNFTIfNeeded();
        }

        (uint256 _tokenAmount, uint256 _ethAmount) = claimAmounts(_contributor);

        if (_ethAmount > 0) {
            _transferETH(_contributor, _ethAmount);
        }
        if (_tokenAmount > 0) {
            _transferTokens(_contributor, _tokenAmount);
        }
        emit Claimed(_contributor, _tokenAmount, _ethAmount);
    }

    // @notice (GOV ONLY) emergency: withdraw stuck ETH
    function emergencyWithdrawETH(uint256 _value) external onlyGov {
        _transferETH(gov, _value);
    }

    // @notice (GOV ONLY) emergency: execute arbitrary calls from contract
    function emergencyCall(address _contract, bytes memory _calldata)
        external
        onlyGov
        returns (bool _success, bytes memory _returnData)
    {
        (_success, _returnData) = _contract.call(_calldata);
        require(_success, string(_returnData));
    }

    // @notice (GOV ONLY) emergency: immediately expires bounty
    function emergencyExpire() external onlyGov {
        expiryTimestamp = block.timestamp;
    }

    // @notice The amount of tokens and ETH that can or have been claimed by `_contributor`
    // @dev Check `claimed(address)` to see if already claimed
    // @param _contributor The address of the contributor to compute amounts for.
    function claimAmounts(address _contributor)
        public
        view
        returns (uint256 _tokenAmount, uint256 _ethAmount)
    {
        require(
            status() != BountyStatus.ACTIVE,
            "Bounty::claimAmounts: bounty still active"
        );
        if (totalSpent > 0) {
            uint256 _ethUsed = ethUsedForAcquisition(_contributor);
            if (_ethUsed > 0) {
                _tokenAmount = valueToTokens(_ethUsed);
            }
            _ethAmount = totalContributedByAddress[_contributor] - _ethUsed;
        } else {
            _ethAmount = totalContributedByAddress[_contributor];
        }
    }

    // @notice The amount of the contributor's ETH used to acquire the NFT
    // @notice Tokens owed will be proportional to eth used.
    // @notice ETH contributed = ETH used in acq + ETH left to be claimed
    // @param _contributor The address of the contributor to compute eth usd
    function ethUsedForAcquisition(address _contributor)
        public
        view
        returns (uint256 _total)
    {
        require(
            totalSpent > 0,
            "Bounty::ethUsedForAcquisition: NFT not acquired yet"
        );
        // load from storage once and reuse
        uint256 _totalSpent = totalSpent;
        Contribution[] memory _contributions = contributions[_contributor];
        for (uint256 _i = 0; _i < _contributions.length; _i++) {
            Contribution memory _contribution = _contributions[_i];
            if (
                _contribution.priorTotalContributed + _contribution.amount <=
                _totalSpent
            ) {
                _total = _total + _contribution.amount;
            } else if (_contribution.priorTotalContributed < _totalSpent) {
                uint256 _amountUsed = _totalSpent -
                    _contribution.priorTotalContributed;
                _total = _total + _amountUsed;
                break;
            } else {
                break;
            }
        }
    }

    // @notice Computes the status of the bounty
    // Valid state transitions:
    // EXPIRED
    // ACTIVE -> EXPIRED
    // ACTIVE -> ACQUIRED
    function status() public view returns (BountyStatus) {
        if (totalSpent > 0) {
            return BountyStatus.ACQUIRED;
        } else if (block.timestamp >= expiryTimestamp) {
            return BountyStatus.EXPIRED;
        } else {
            return BountyStatus.ACTIVE;
        }
    }

    function symbol() external view virtual returns (string memory);

    function BOUNTY_TYPE() external pure virtual returns (BountyType);

    function _transferETH(address _to, uint256 _value) internal {
        // guard against rounding errors
        uint256 _balance = address(this).balance;
        if (_value > _balance) {
            _value = _balance;
        }
        payable(_to).transfer(_value);
    }

    function valueToTokens(uint256 _value)
        public
        pure
        virtual
        returns (uint256 _tokens);

    function _fractionalizeNFTIfNeeded() internal virtual;

    function _transferTokens(address _to, uint256 _value) internal virtual;

    function computeFee(
        uint256 /*_amount*/
    ) public pure virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "./AbstractBounty.sol";
import "./external/interfaces/IERC1155VaultFactory.sol";

contract ERC1155Bounty is AbstractBounty, ERC1155HolderUpgradeable {
    uint256 public constant FRACTION_BASIS = 1e12; // 1 szabo
    BountyType public constant override BOUNTY_TYPE = BountyType.ERC1155;

    // immutable (across clones)
    IERC1155VaultFactory public immutable tokenVaultFactory;

    // mutables
    uint256 public vaultNumber;

    event Fractionalized(address _tokenVaultFactory, uint256 _vaultNumber);

    constructor(address _gov, IERC1155VaultFactory _tokenVaultFactory)
        AbstractBounty(_gov)
    {
        tokenVaultFactory = _tokenVaultFactory;
    }

    function initialize(
        IERC721 _nftContract,
        uint256 _nftTokenID,
        string memory _name,
        uint256 _contributionCap,
        uint256 _duration
    ) external initializer {
        require(
            _contributionCap % FRACTION_BASIS == 0,
            "ERC1155Bounty::initialize: Contribution cap must be a mulitple of FRACTION_BASIS"
        );
        __AbstractBounty_init(
            _nftContract,
            _nftTokenID,
            _name,
            _contributionCap,
            _duration
        );
    }

    function contribute() public payable override {
        require(
            msg.value % FRACTION_BASIS == 0,
            "ERC1155Bounty::contribute: Contributions must be in multiples of FRACTION_BASIS"
        );
        super.contribute();
    }

    function computeFee(uint256 _amount)
        public
        pure
        override
        returns (uint256)
    {
        uint256 _rem = _amount % FRACTION_BASIS;
        if (_rem == 0) {
            return 0;
        } else {
            return FRACTION_BASIS - _rem;
        }
    }

    // @dev Helper function for translating ETH contributions into token amounts
    function valueToTokens(uint256 _value)
        public
        pure
        override
        returns (uint256 _tokens)
    {
        _tokens = _value / FRACTION_BASIS;
    }

    function symbol() external pure override returns (string memory) {
        return "";
    }

    function _transferTokens(address _to, uint256 _value) internal override {
        // guard against rounding errors
        IERC1155 _fractionalToken = IERC1155(tokenVaultFactory.fnft());
        uint256 _balance = _fractionalToken.balanceOf(
            address(this),
            vaultNumber
        );
        if (_value > _balance) {
            _value = _balance;
        }
        _fractionalToken.safeTransferFrom(
            address(this),
            _to,
            vaultNumber,
            _value,
            new bytes(0)
        );
    }

    function _fractionalizeNFTIfNeeded() internal override {
        // FIXME: ensure vaults start at 1
        if (vaultNumber != 0) {
            return;
        }
        IERC721(nftContract).approve(address(tokenVaultFactory), nftTokenID);
        vaultNumber = tokenVaultFactory.mint(
            address(nftContract),
            nftTokenID,
            valueToTokens(totalSpent)
        );
        emit Fractionalized(address(tokenVaultFactory), vaultNumber);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {ERC1155Bounty} from "./ERC1155Bounty.sol";
import {IERC1155VaultFactory} from "./external/interfaces/IERC1155VaultFactory.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

contract ERC1155BountyFactory {
    event BountyDeployed(
        address indexed addressDeployed,
        address indexed creator,
        address nftContract,
        uint256 nftTokenID,
        string name,
        uint256 contributionCap,
        uint256 duration,
        bool indexed isPrivate
    );

    address public immutable gov;
    address public immutable erc1155;

    bool public paused;

    modifier onlyGov() {
        require(msg.sender == gov, "BountyFactory:: only callable by gov");
        _;
    }

    constructor(
        address _gov,
        IERC1155VaultFactory _tokenVaultFactoryERC1155,
        IERC721 _logicNftContract,
        uint256 _logicTokenID
    ) {
        gov = _gov;
        ERC1155Bounty _erc1155 = new ERC1155Bounty(
            _gov,
            _tokenVaultFactoryERC1155
        );
        // initialize as expired bounty
        _erc1155.initialize(
            _logicNftContract,
            _logicTokenID,
            "BOUNTY",
            0, // contribution cap
            0 // duration (expires immediately)
        );
        erc1155 = address(_erc1155);
    }

    function startBounty(
        IERC721 _nftContract,
        uint256 _nftTokenID,
        string memory _name,
        uint256 _contributionCap,
        uint256 _duration,
        bool _isPrivate
    ) external returns (address _bountyAddress) {
        require(
            !paused,
            "BountyFactory::startBountyERC1155: ERC1155 bounties are paused"
        );
        _bountyAddress = Clones.clone(erc1155);
        ERC1155Bounty(_bountyAddress).initialize(
            _nftContract,
            _nftTokenID,
            _name,
            _contributionCap,
            _duration
        );
        emit BountyDeployed(
            _bountyAddress,
            msg.sender,
            address(_nftContract),
            _nftTokenID,
            _name,
            _contributionCap,
            _duration,
            _isPrivate
        );
    }

    function setPaused(bool _value) external onlyGov {
        paused = _value;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface IERC1155VaultFactory {
    function fnft() external view returns (address);

    function vaults(uint256) external view returns (address);

    function mint(
        address _token,
        uint256 _id,
        uint256 _amount
    ) external returns (uint256);
}