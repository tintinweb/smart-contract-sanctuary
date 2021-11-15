// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

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

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

    constructor () {
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
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./SporesRegistry.sol";
import "./Utils/Signature.sol";

/**
   @title SporesNFTMarket contract
   @dev This contract is used to handle buy/sell NFT tokens/items
   Note: 
    - The supporting NFT standards:
        + ERC-721 (https://eips.ethereum.org/EIPS/eip-721)
    - For payment, the supporting coins/tokens:
        + ETH/WETH
        + ERC-20 (https://ethereum.org/en/developers/docs/standards/tokens/erc-20/)
*/
contract SporesNFTMarket is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Signature for Signature.TradeType;

    //  Market version
    bytes32 public constant VERSION = keccak256("MARKET_721_v1");

    // FEE_DENOMINATOR = 10^6 should be good for lower fee ratio, e.g. 0.1%
    uint256 private constant FEE_DENOMINATOR = 10**6;

    // SporesRegistry contract
    SporesRegistry public registry;

    event SporesNFTMarketTransaction(
        address indexed _buyer,
        address indexed _seller,
        address _paymentReceiver,
        address _contractNFT,
        address _paymentToken,
        uint256 indexed _tokenId,
        uint256 _price,
        uint256 _amount,
        uint256 _fee,
        uint256 _sellId,
        Signature.TradeType _tradeType
    );

    event NativeCoinPayment(address indexed _to, uint256 _amount);

    /**
       @notice Initialize SporesRegistry contract 
       @param _registry        Address of SporesRegistry contract
    */
    constructor(address _registry) Ownable() {
        registry = SporesRegistry(_registry);
    }

    /**
       @notice Update new address of SporesRegistry contract
       @dev Caller must be Owner
           SporesRegistry contract is upgradeable smart contract
           Thus, the address remains unchanged in upgrading
           However, this functions is a back up in the worse case 
           that requires to deploy a new SporesRegistry contract
       @param _newRegistry          Address of new SporesRegistry contract
    */
    function updateRegistry(address _newRegistry) external onlyOwner {
        require(
            _newRegistry != address(0),
            "SporesNFTMarket: Set zero address"
        );
        registry = SporesRegistry(_newRegistry);
    }

    /**
       @notice Handle transaction of trading Spores NFT721 item with Native Coin
       @dev Caller can be ANY
           Buyer must use his/her account to send this request
       @param _info                 Trading Information     
        + _seller               Seller Address
        + _paymentReceiver      Address to receive payment
        + _contractNFT          Address of NFT721 contract
        + _paymentToken         Address(0) - Native coin
        + _tokenId              NFT721 Token ID
        + _feeRate              Numerator of commission fee
        + _price                Selling price
        + _amount               SINGLE_UNIT = 1
        + _sellId               A number of selling information (BE requirement)
       @param _signature            Signature of Verifier
    */
    function buyNFT721NativeCoin(
        Signature.TradeInfo calldata _info,
        bytes calldata _signature
    ) external payable nonReentrant {
        // @dev Avoid the case: Seller authorizes SporesNFTMarket to proceed Buy/Sell by setting 'setApproveForAll'
        // Buyer purchases the NFT721 item, but specify the receiving of payment is its own account.
        // Solution: check NFT721 TokenId and address of Seller
        // The owner of '_tokenId' must match the address of Seller
        require(
            msg.value == _info._price,
            "SporesNFTMarket: Insufficient payment"
        );
        require(
            registry.supportedNFT721(_info._contractNFT) ||
                registry.collections(_info._contractNFT),
            "SporesNFTMarket: NFT721 Contract not supported"
        );
        require(
            IERC721Upgradeable(_info._contractNFT).ownerOf(_info._tokenId) ==
                _info._seller,
            "SporesNFTMarket: Seller is not owner"
        );

        // In addition, Verifier provides a signature
        // Sig = sign(
        //    [_seller, _paymentReceiver, _contractNFT, _tokenId, _paymentToken, _feeRate, _price, _amount, _sellId, PURCHASE_TYPE]
        // )
        _checkAuthorization(
            Signature.TradeType.NATIVE_COIN_NFT_721,
            _info,
            _signature
        );

        //  Calculate charging fee, and paying amount to Seller
        (uint256 _fee, uint256 _payToSeller) =
            _calcPayment(_info._price, _info._amount, _info._feeRate);

        //  transfer a payment to '_paymentReceiver' and Fee Collector
        _paymentTransfer(payable(_info._paymentReceiver), _payToSeller);
        _paymentTransfer(payable(registry.treasury()), _fee);

        //  transfer NFT721 item to Buyer
        //  If Seller has not yet setApproveForAll to allow SporesNFTMarket contract
        //  transfer NFT721 item, this transaction is likely reverted
        IERC721Upgradeable(_info._contractNFT).safeTransferFrom(
            _info._seller,
            _msgSender(),
            _info._tokenId
        );

        emit SporesNFTMarketTransaction(
            _msgSender(),
            _info._seller,
            _info._paymentReceiver,
            _info._contractNFT,
            _info._paymentToken,
            _info._tokenId,
            _info._price,
            _info._amount,
            _fee,
            _info._sellId,
            Signature.TradeType.NATIVE_COIN_NFT_721
        );
    }

    function _paymentTransfer(address payable _to, uint256 _amount) private {
        (bool sent, ) = _to.call{ value: _amount }("");
        require(sent, "SporesNFTMarket: Payment transfer failed");
        emit NativeCoinPayment(_to, _amount);
    }

    /**
       @notice Handle transaction of trading Spores NFT721 item with ERC-20 Token
       @dev Caller can be ANY
           Buyer must use his/her account to send this request
       @param _info                 Trading Information     
        + _seller               Seller Address
        + _paymentReceiver      Address to receive payment
        + _contractNFT          Address of NFT721 contract
        + _paymentToken         Addres of payment token contract
        + _tokenId              NFT721 Token ID
        + _feeRate              Numerator of commission fee
        + _price                Selling price
        + _amount               SINGLE_UNIT = 1
        + _sellId               A number of selling information (BE requirement)
       @param _signature            Signature of Verifier
    */
    function buyNFT721ERC20(
        Signature.TradeInfo calldata _info,
        bytes calldata _signature
    ) external {
        require(
            registry.supportedTokens(_info._paymentToken),
            "SporesNFTMarket: Invalid payment"
        );
        require(
            registry.supportedNFT721(_info._contractNFT) ||
                registry.collections(_info._contractNFT),
            "SporesNFTMarket: NFT721 Contract not supported"
        );
        require(
            IERC721Upgradeable(_info._contractNFT).ownerOf(_info._tokenId) ==
                _info._seller,
            "SporesNFTMarket: Seller is not owner"
        );

        // Verifier provides a signature
        // Sig = sign(
        //    [_seller, _paymentReceiver, _contractNFT, _tokenId, _paymentToken, _feeRate, _price, _amount, _sellId, PURCHASE_TYPE]
        // )
        _checkAuthorization(
            Signature.TradeType.ERC_20_NFT_721,
            _info,
            _signature
        );

        // Calculate charging fee, and paying amount to Seller
        (uint256 _fee, uint256 _payToSeller) =
            _calcPayment(_info._price, _info._amount, _info._feeRate);

        // transfer payment Tokens to '_paymentReceiver' and Fee Collector
        // If Buyer has not yet set allowance[buyer][operator]
        // or Buyer has insufficient balances, these transactions are likely reverted
        IERC20(_info._paymentToken).safeTransferFrom(
            _msgSender(),
            _info._paymentReceiver,
            _payToSeller
        );
        IERC20(_info._paymentToken).safeTransferFrom(
            _msgSender(),
            registry.treasury(),
            _fee
        );

        // transfer NFT721 item to Buyer
        // If Seller has not yet setApproveForAll to allow SporesNFTMarket contract
        // transfer NFT721 item, this transaction is likely reverted
        IERC721Upgradeable(_info._contractNFT).safeTransferFrom(
            _info._seller,
            _msgSender(),
            _info._tokenId
        );

        emit SporesNFTMarketTransaction(
            _msgSender(),
            _info._seller,
            _info._paymentReceiver,
            _info._contractNFT,
            _info._paymentToken,
            _info._tokenId,
            _info._price,
            _info._amount,
            _fee,
            _info._sellId,
            Signature.TradeType.ERC_20_NFT_721
        );
    }

    function _checkAuthorization(
        Signature.TradeType _type,
        Signature.TradeInfo calldata _info,
        bytes calldata _signature
    ) private {
        registry.checkAuthorization(
            _type.getTradingSignature(_info, _signature),
            keccak256(_signature)
        );
    }

    function _calcPayment(
        uint256 _price,
        uint256 _amount,
        uint256 _feeRate
    ) private pure returns (uint256 _fee, uint256 _payToSeller) {
        //  @dev Solidity 0.8.0 has integrated overflow and underflow checking
        //  Please check it out https://docs.soliditylang.org/en/v0.8.7/080-breaking-changes.html
        // _fee = _feeRate * Price * Amount / FEE_DENOMINATOR
        // _payToSeller = Price * Amount - fee
        _fee = (_feeRate * _price * _amount) / FEE_DENOMINATOR;
        _payToSeller = _price * _amount - _fee;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
   @title SporesRegistry contract
   @dev This contract is used to handle Registry Service
       + Register address (Treasury) to receive Commission Fee 
       + Register address of Verifier who provides authentication signatures
       + Register SporesNFT721 and SporesNFT1155 contracts
       + Register another NFT721 and NFT1155 contracts that are not owned by Spores
       + Manage Collection contract (ERC-721) - created and followed Spores's requirements
*/
contract SporesRegistry is Initializable, OwnableUpgradeable {
    // Spores Fee Collector address to receive commission fee
    address public treasury;
    // Address of Verifier to authorize Buy/Sell Spores NFT Token
    address public verifier;
    // SporesNFT721 contract address
    address public erc721;
    // SporesNFT1155 contract address
    address public erc1155;
    // SporesNFTMinter contract (SporesNFTMinter/SporesNFTMinterBatch)
    address public minter;
    // SporesNFTMartket contract
    address public market;

    //  Registry version
    bytes32 public constant VERSION = keccak256("REGISTRY_v1");

    // Define constant of NFT721 and NFT1155 opcode
    uint256 private constant NFT721_OPCODE = 721;
    uint256 private constant NFT1155_OPCODE = 1155;

    // Supported payment token WETH & list of authorized ERC20
    mapping(address => bool) public supportedTokens;

    // A map of supported NFT721 and NFT11555 contracts
    mapping(address => bool) public supportedNFT721;
    mapping(address => bool) public supportedNFT1155;
    // A map of Collections that was created by Spores Network
    // For any other collections that was created outside the network
    // use above mapping
    mapping(address => bool) public collections;

    // A map list of used signatures - keccak256(signature) => bytes32
    mapping(bytes32 => bool) public prevSigns;

    event TokenRegister(
        address indexed _token,
        bool _isRegistered // true = Registered, false = Removed
    );

    event NFTContractRegister(
        address indexed _contractNFT,
        uint256 _opcode, // _opcode = 721 => NFT721, _opcode = 1155 => NFT1155
        bool _isRegistered // true = Registered, false = Removed
    );

    event CollectionRegister(
        address indexed _collection,
        bool _isRegistered // true = Registered, false = Removed
    );

    event Treasury(address indexed _oldTreasury, address indexed _newTreasury);
    event Verifier(address indexed _oldVerifier, address indexed _newVerifier);
    event Minter(address indexed _oldMinter, address indexed _newMinter);
    event Market(address indexed _oldMarket, address indexed _newMarket);

    modifier onlyAuthorizer() {
        require(
            _msgSender() == minter ||
            _msgSender() == market ||
            collections[_msgSender()],
            "SporesRegistry: Unauthorized"
        );
        _;
    }

    function init(
        address _treasury,
        address _verifier,
        address _nft721,
        address _nft1155,
        address[] memory _tokens
    ) external initializer {
        __Ownable_init();

        treasury = _treasury;
        verifier = _verifier;
        erc721 = _nft721;
        erc1155 = _nft1155;
        supportedNFT721[_nft721] = true;
        supportedNFT1155[_nft1155] = true;
        for (uint256 i = 0; i < _tokens.length; i++) {
            supportedTokens[_tokens[i]] = true;
        }
    }

    /**
       @notice Update a new Verifier address
       @dev Caller must be Owner
            Address of new Verifier should not be address(0)
       @param _newVerifier       Address of a new Verifier
    */
    function updateVerifier(address _newVerifier) external onlyOwner {
        require(_newVerifier != address(0), "SporesRegistry: Set zero address");
        emit Verifier(verifier, _newVerifier);
        verifier = _newVerifier;
    }

    /**
       @notice Update new address of Treasury
       @dev Caller must be Owner
       @param _newTreasury        Address of a new Treasury
    */
    function updateTreasury(address _newTreasury) external onlyOwner {
        require(_newTreasury != address(0), "SporesRegistry: Set zero address");
        emit Treasury(treasury, _newTreasury);
        treasury = _newTreasury;
    }

    /**
       @notice Update new address of Minter contract
       @dev Caller must be Owner
       @param _newMinter        Address of a new Minter
    */
    function updateMinter(address _newMinter) external onlyOwner {
        require(_newMinter != address(0), "SporesRegistry: Set zero address");
        emit Minter(minter, _newMinter);
        minter = _newMinter;
    }

    /**
       @notice Update new address of Market contract
       @dev Caller must be Owner
       @param _newMarket        Address of a new Market
    */
    function updateMarket(address _newMarket) external onlyOwner {
        require(_newMarket != address(0), "SporesRegistry: Set zero address");
        emit Market(market, _newMarket);
        market = _newMarket;
    }

    /**
       @notice Register a new supporting payment Coins/Tokens
            Onwer calls this function to register new ERC-20 Token
       @dev Caller must be Owner
       @param _token           Address of ERC-20 Token contract
    */
    function registerToken(address _token) external onlyOwner {
        require(!supportedTokens[_token], "SporesRegistry: Token registered");
        require(_token != address(0), "SporesRegistry: Set zero address");
        supportedTokens[_token] = true;
        emit TokenRegister(_token, true);
    }

    /**
       @notice Unregister a supported payment Coins/Tokens
            Onwer calls this function to unregister existing ERC-20 Token
       @dev Caller must be Owner
       @param _token           Address of ERC-20 Token contract to be removed
    */
    function unregisterToken(address _token) external onlyOwner {
        require(
            supportedTokens[_token],
            "SporesRegistry: Token not registered"
        );
        delete supportedTokens[_token];
        emit TokenRegister(_token, false);
    }

    /**
       @notice Add Collection to Spores Registry (By constructor)
            The adding Collection should be created by Spores Network
                in order to use this function to register
            For other Collections, not created by Spores, should be registered
                by below methods
            When Collection is created, it automatically calls this function to register Collection
            This solution saves manually steps of registering Collection.
            In the long run, this function should be removed        
       @dev Caller is Collection's constructor, but require a signature from Verifier
       @param _collection           Address of Collection contract to be registered
       @param _admin                Address of Admin (could be owner of SporesRegistry contract)
       @param _collectionId         An integer number of Collection identification
       @param _maxEdition           A max number of copies for the first sub-collection
       @param _requestId            An integer number of request given by BE
       @param _signature            A signature that is signed by Verifier
    */
    function addCollectionByConstructor(
        address _collection,
        address _admin,
        uint256 _collectionId,
        uint256 _maxEdition,
        uint256 _requestId,
        bytes calldata _signature
    ) external {
        //  Not neccessary to check validity of `_admin`
        //  Signature is provided by Verifier
        bytes32 _data = 
            keccak256(
                abi.encodePacked(
                    _collectionId, _maxEdition, _requestId, _admin, address(this)
                )
            );
        bytes32 _msgHash = ECDSA.toEthSignedMessageHash(_data);  
        address _verifier = ECDSA.recover(_msgHash, _signature);
        _checkAuthorization(_verifier, keccak256(_signature));
        collections[_collection] = true;
    }

    /**
       @notice Add Collection to Spores Registry
            The adding Collection should be created by Spores Network
                in order to use this function to register
            For other Collections, not created by Spores, should be registered
                by below methods    
       @dev Caller must be Owner
       @param _collection           Address of Collection contract to be registered
    */
    function addCollection(address _collection) external onlyOwner {
        require(_collection != address(0), "SporesRegistry: Set zero address");
        require(!collections[_collection], "SporesRegistry: Collection exist");
        collections[_collection] = true;
        emit CollectionRegister(_collection, true);
    }

    /**
       @notice Remove Collection out of Spores Registry
       @dev Caller must be Owner
       @param _collection           Address of Collection contract to be removed
    */
    function removeCollection(address _collection) external onlyOwner {
        require(
            collections[_collection],
            "SporesRegistry: Collection not exist"
        );
        delete collections[_collection];
        emit CollectionRegister(_collection, false);
    }

    /**
       @notice Register a new supporting NFT721/NFT1155 contract
            Onwer calls this function to register new NFT721/NFT1155 contract
       @dev Caller must be Owner
            `_skip` should be `false` by default to check interface
       @param _contractNFT        Address of NFT721/1155 contract
       @param _opcode             Option Code (721 = NFT721, 1155 = NFT1155)
       @param _skip               A flag to skip checking interface ERC-165
    */
    function registerNFTContract(address _contractNFT, uint256 _opcode, bool _skip)
        external
        onlyOwner
    {
        require(_contractNFT != address(0), "SporesRegistry: Set zero address");
        require(
            _opcode == NFT721_OPCODE || _opcode == NFT1155_OPCODE,
            "SporesRegistry: Invalid opcode"
        );

        // @dev In case a registering contract does not implement `supportInterface()`
        // Should verify a contract carefully before registering with a disable checking flag (_skip = true)
        if (_opcode == NFT721_OPCODE) {
            require(
                !supportedNFT721[_contractNFT],
                "SporesRegistry: NFT721 Contract registered"
            );
            // @dev    IERC721 and IERC721Upgradeable returns the same interface ID
            // Should restrict IERC721Upgradeable cause unknown contract can upgrade
            // and integrate malicious implementation
            require(
                _skip || IERC721(_contractNFT).supportsInterface(
                    type(IERC721).interfaceId
                ),
                "SporesRegistry: Invalid interface"
            );
            supportedNFT721[_contractNFT] = true;
        } else {
            require(
                !supportedNFT1155[_contractNFT],
                "SporesRegistry: NFT1155 Contract registered"
            );
            // @dev    IERC1155 and IERC1155Upgradeable returns the same interface ID
            // Should restrict IERC1155Upgradeable cause unknown contract can upgrade
            // and integrate malicious implementation
            require(
                _skip || IERC1155(_contractNFT).supportsInterface(
                    type(IERC1155).interfaceId
                ),
                "SporesRegistry: Invalid interface"
            );
            supportedNFT1155[_contractNFT] = true;
        }
        emit NFTContractRegister(_contractNFT, _opcode, true);
    }

    /**
       @notice Unregister a supported NFT721/NFT1155 contract
            Onwer calls this function to unregister existing NFT721/NFT1155 contract
       @dev Caller must be Owner
       @param _contractNFT        Address of NFT721/NFT1155 contract to be removed
       @param _opcode             Option Code (721 = NFT721, 1155 = NFT1155)
    */
    function unregisterNFTContract(address _contractNFT, uint256 _opcode)
        external
        onlyOwner
    {
        require(
            _opcode == NFT721_OPCODE || _opcode == NFT1155_OPCODE,
            "SporesRegistry: Invalid opcode"
        );
        if (_opcode == NFT721_OPCODE) {
            require(
                supportedNFT721[_contractNFT],
                "SporesRegistry: NFT721 Contract not registered"
            );
            delete supportedNFT721[_contractNFT];
        } else {
            require(
                supportedNFT1155[_contractNFT],
                "SporesRegistry: NFT1155 Contract not registered"
            );
            delete supportedNFT1155[_contractNFT];
        }
        emit NFTContractRegister(_contractNFT, _opcode, false);
    }

    /**
       @notice This function handles multiple task per request:
            + Check whether `_verifier`, who gave a signature, is authorized
            + Check whether a signature has been used before
            + Save `_sigHash`
       @dev Caller must be in the authorizing list - Minter, Market, and Collection contract
       @param _verifier        Address of `_verifier` that was used to sign a request
       @param _sigHash         A hash of signature that was given by `_verifier`
    */
    function checkAuthorization(address _verifier, bytes32 _sigHash)
        external
        onlyAuthorizer
    {
        _checkAuthorization(_verifier, _sigHash);
    }

    function _checkAuthorization(address _verifier, bytes32 _sigHash) private {
        require(_verifier == verifier, "SporesRegistry: Invalid verifier");
        require(!prevSigns[_sigHash], "SporesRegistry: Signature was used");
        prevSigns[_sigHash] = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
   @title Signature library
        This library provides methods to recover a signer of one signature
    + Two types of Minting: ERC721_Minting and ERC1155_Minting (single and batch minting)
    + Four types of trading: NativeCoin_NFT721, NativeCoin_NFT1155, ERC20_NFT721, ERC20_NFT1155   
    + Collection Creation
    + Add sub-collection in one collection 
*/
library Signature {
    enum MintType { 
        ERC721_MINTING,
        ERC1155_MINTING 
    }

    enum TradeType {
        NATIVE_COIN_NFT_721,
        NATIVE_COIN_NFT_1155,
        ERC_20_NFT_721,
        ERC_20_NFT_1155
    }

    struct TradeInfo {
        address _seller;
        address _paymentReceiver;
        address _contractNFT;
        address _paymentToken;
        uint256 _tokenId;
        uint256 _feeRate;
        uint256 _price;
        uint256 _amount;
        uint256 _sellId;
    }

    function getTradingSignature(
        TradeType _type,
        TradeInfo calldata _info,
        bytes calldata _signature
    ) internal pure returns (address verifier) {
        // Generate message hash to verify signature
        // Sig = sign(
        //    [
        //     _seller, _paymentReceiver, _contractNFT, _tokenId, _paymentToken,
        //     _feeRate, _price, _amount, _sellId, PURCHASE_TYPE
        //    ]
        // )
        bytes32 _data =
            keccak256(
                abi.encodePacked(
                    _info._seller, _info._paymentReceiver, _info._contractNFT, _info._tokenId,
                    _info._paymentToken, _info._feeRate, _info._price, _info._amount, _info._sellId, uint256(_type)
                )
            );
        verifier = getSigner(_data, _signature);  
    }

    function getAddSubCollectionSignature(
        uint256 _collectionId,
        uint256 _subcollectionId,
        uint256 _maxEdition,
        uint256 _requestId,
        bytes calldata _signature
    ) internal pure returns (address verifier) {
        //  Generate message hash to verify `_signature`
        //  Add Sub-collection request should be signed by Verifier
        bytes32 _data =
            keccak256(
                abi.encodePacked(
                    _collectionId, _subcollectionId, _maxEdition, _requestId
                )
            );
        verifier = getSigner(_data, _signature);  
    }

    function getSingleMintingSignature(
        MintType _type,
        address _to,
        uint256 _tokenId,
        string calldata _uri,
        bytes calldata _signature
    ) internal pure returns (address verifier) {
        //  Generate message hash to verify `_signature`
        //  Minting request should be signed by Verifier
        bytes32 _data =
            keccak256(
                abi.encodePacked(
                    _to, _tokenId, _uri, uint256(_type)
                )
            );
        verifier = getSigner(_data, _signature);  
    }

    function getBatchMintingSignature(
        MintType _type,
        address _to,
        uint256[] calldata _tokenIds,
        string[] calldata _uris,
        bytes calldata _signature
    ) internal pure returns (address verifier) {
        //  Generate message hash to verify `_signature`
        //  Minting request should be signed by Verifier
        bytes memory _encodeURIs;
        for (uint256 i; i < _uris.length; i++) {
            _encodeURIs = abi.encodePacked(_encodeURIs, _uris[i]);
        }
        bytes32 _data =
            keccak256(
                abi.encodePacked(
                    _to, _tokenIds, _encodeURIs, uint256(_type)
                )
            );
        verifier = getSigner(_data, _signature);    
    }

    function getSigner(bytes32 _data, bytes calldata _signature) private pure returns (address) {
        bytes32 _msgHash = ECDSA.toEthSignedMessageHash(_data);
        return ECDSA.recover(_msgHash, _signature);
    }
}

