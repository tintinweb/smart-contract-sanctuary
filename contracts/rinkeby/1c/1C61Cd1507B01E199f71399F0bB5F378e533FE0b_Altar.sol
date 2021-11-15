// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IVoid.sol";
import "./interfaces/IAltar.sol";
import "./interfaces/IShadowling.sol";
import "./libraries/Currency.sol";
import "./Shadowpakt.sol";

/// @notice Summons Shadowlings from the Shadowchain
contract Altar is
    IAltar,
    Shadowpakt,
    Ownable,
    ReentrancyGuard,
    IERC1155Receiver,
    IERC721Receiver
{
    using SafeERC20 for IERC20;

    /// @inheritdoc IAltar
    uint256 public constant override SHADOWLING_COST = 10000e18;
    /// @inheritdoc IAltar
    address public override void;
    /// @inheritdoc IAltar
    address public override shadowling;
    /// @inheritdoc IAltar
    mapping(address => uint256) public override cost;
    /// @inheritdoc IAltar
    mapping(uint256 => uint256) public override currencyCost;
    /// @inheritdoc IAltar
    mapping(address => mapping(uint256 => uint256)) public override premium;

    modifier onlyWhitelisted(address token) {
        if (cost[token] == 0) revert ListedError();
        _;
    }

    modifier onlyShadows(uint256 tokenId) {
        if (tokenId < Currency.START_INDEX) revert TokenError();
        _;
    }

    modifier onlyCurrency(uint256 currencyId) {
        if (currencyId > Currency.START_INDEX - 1 || currencyId < 1)
            revert CurrencyError();
        _;
    }

    // === Initialization ===

    /// @inheritdoc IAltar
    function initialize(address void_, address shadowling_)
        external
        override
        onlyOwner
    {
        if (void != address(0)) revert InitializedError();
        if (IVoid(void_).owner() == address(this)) void = void_;

        if (shadowling != address(0)) revert InitializedError();
        if (IVoid(shadowling_).owner() == address(this))
            shadowling = shadowling_;
    }

    // ===== User Actions =====

    /// @inheritdoc IAltar
    function sacrifice721(
        address token,
        uint256 tokenId,
        uint256 shadowlingId
    ) external override nonReentrant onlyWhitelisted(token) {
        address caller = _msgSender();
        uint256 value = totalCost(token, tokenId);

        if (shadowlingId > Currency.START_INDEX) {
            uint256 seed = uint256(
                keccak256(
                    abi.encodePacked(address(this), shadowlingId, tokenId)
                )
            );
            IShadowling(shadowling).claim(shadowlingId, caller, seed);
            value -= SHADOWLING_COST;
        }

        IVoid(void).mint(caller, value);

        IERC721(token).safeTransferFrom(
            caller,
            address(this),
            tokenId,
            new bytes(0)
        );
        emit Sacrificed(caller, token, tokenId, 1, value, shadowlingId);
    }

    /// @inheritdoc IAltar
    function sacrifice1155(
        address token,
        uint256 tokenId,
        uint256 amount,
        uint256 shadowlingId
    ) external override nonReentrant onlyWhitelisted(token) {
        if (amount == 0) revert ZeroError();
        address caller = _msgSender();
        uint256 value = totalCost(token, tokenId);
        if (amount > 1) value = (amount * value) / 1e18; // void token has 18 decimals

        if (shadowlingId > Currency.START_INDEX) {
            uint256 seed = uint256(
                keccak256(
                    abi.encodePacked(address(this), shadowlingId, tokenId)
                )
            );
            IShadowling(shadowling).claim(shadowlingId, caller, seed);
            value -= SHADOWLING_COST;
        }

        IVoid(void).mint(caller, value);

        IERC1155(token).safeTransferFrom(
            caller,
            address(this),
            tokenId,
            amount,
            new bytes(0)
        );
        emit Sacrificed(caller, token, tokenId, amount, value, shadowlingId);
    }

    /// @inheritdoc IAltar
    function claim(uint256 tokenId, bytes32 revealHash)
        external
        override
        nonReentrant
        onlyShadows(tokenId)
    {
        burn(SHADOWLING_COST);
        uint256 seed = revealKey(revealHash);
        address caller = _msgSender();
        IShadowling(shadowling).claim(tokenId, caller, seed);
        emit Claimed(caller, tokenId);
    }

    /// @inheritdoc IAltar
    function modify(
        uint256 tokenId,
        uint256 currencyId,
        bytes32 revealHash
    ) external override nonReentrant onlyShadows(tokenId) {
        uint256 value = currencyCost[currencyId];
        burn(value); // send the currency back to the shadowchain
        uint256 seed = revealKey(revealHash);
        IShadowling(shadowling).modify(tokenId, currencyId, seed);
        emit Modified(msg.sender, tokenId, currencyId);
    }

    function burn(uint256 value) private {
        if (value == 0) revert ZeroError();
        IVoid(void).burn(msg.sender, value);
    }

    // ===== Owner Actions =====

    /// @inheritdoc IAltar
    function setBaseCost(address token, uint256 amount)
        external
        override
        onlyOwner
    {
        cost[token] = amount;
        emit SetBaseCost(_msgSender(), token, amount);
    }

    /// @inheritdoc IAltar
    function setPremiumCost(
        address token,
        uint256 tokenId,
        uint256 amount
    ) external override onlyOwner {
        premium[token][tokenId] = amount;
        emit SetPremiumCost(_msgSender(), token, tokenId, amount);
    }

    /// @inheritdoc IAltar
    function setCurrencyCost(uint256 currencyId, uint256 newCost)
        external
        override
        onlyOwner
        onlyCurrency(currencyId)
    {
        currencyCost[currencyId] = newCost;
        emit SetCurrencyCost(currencyId, newCost);
    }

    /// @inheritdoc IAltar
    function takeMany(
        address token,
        uint256 tokenId,
        uint256 amount
    ) external override onlyOwner nonReentrant {
        if (amount == 0) revert ZeroError();
        IERC1155(token).safeTransferFrom(
            address(this),
            owner(),
            tokenId,
            amount,
            new bytes(0)
        );
        emit Taken(_msgSender(), token, tokenId, amount);
    }

    /// @inheritdoc IAltar
    function takeSingle(address token, uint256 tokenId)
        external
        override
        onlyOwner
        nonReentrant
    {
        IERC721(token).safeTransferFrom(address(this), owner(), tokenId);
        emit Taken(_msgSender(), token, tokenId, 1);
    }

    // ===== Callbacks =====

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override(IERC721Receiver) returns (bytes4) {
        return Altar.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override(IERC1155Receiver) returns (bytes4) {
        return Altar.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override(IERC1155Receiver) returns (bytes4) {
        return Altar.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC1155).interfaceId;
    }

    // ===== View =====

    /// @inheritdoc IAltar
    function totalCost(address token, uint256 tokenId)
        public
        view
        override
        returns (uint256)
    {
        return cost[token] + premium[token][tokenId];
    }

    constructor() {}
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
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

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IVoid {
    function mint(address to, uint256 value) external;

    function burn(address to, uint256 value) external;

    function owner() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IAltar {
    // ===== Events =====

    /// @notice Emitted on upating the base amount of void received from burning an nft
    event SetBaseCost(
        address indexed from,
        address indexed token,
        uint256 indexed base
    );

    /// @notice Emitted on updating the premium amount of void received from burning an nft
    event SetPremiumCost(
        address indexed from,
        address indexed token,
        uint256 indexed tokenId,
        uint256 premium
    );

    /// @notice Emitted on sacrifice and minting of VOID
    event Sacrificed(
        address indexed from,
        address indexed token,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 value,
        uint256 shadowlingId
    );

    /// @notice Emitted when an owner removes tokens
    event Taken(
        address indexed from,
        address indexed token,
        uint256 indexed tokenId,
        uint256 amount
    );

    /// @notice Emitted on modifying a Shadowling's attributes
    event Modified(
        address indexed from,
        uint256 indexed tokenId,
        uint256 indexed currencyId
    );

    /// @notice Emitted on burning void tokens to claim a Shadowling
    event Claimed(address indexed from, uint256 indexed tokenId);

    /// @notice Emitted on setting the price of a currency usage in void tokens
    event SetCurrencyCost(uint256 indexed currencyId, uint256 indexed cost);

    // ===== Errors =====

    /// @notice Thrown on attempting to burn a non-whitelisted asset
    error ListedError();
    /// @notice Thrown on passing a zero value as a parameter, you're welcome
    error ZeroError();
    /// @notice Thrown on attempting to set an already set `void`
    error InitializedError();
    /// @notice Thrown on attempting to use incorrect currencyId
    error CurrencyError();
    /// @notice Thrown on attempting to use inccorect tokenId
    error TokenError();

    // ===== User =====

    /// @notice Mints Shadowlings to `msg.sender`, cannot mint 0 tokenId
    /// @param  tokenId Token with `tokenId` to mint. Maps tokenId to individual item ids in ItemIds
    /// @param  revealHash Unhashed key used in a commit
    function claim(uint256 tokenId, bytes32 revealHash) external;

    /// @notice Modifies a Shadowling using with the `currencyId`, changing its attributes
    function modify(
        uint256 tokenId,
        uint256 currencyId,
        bytes32 revealHash
    ) external;

    /// @notice Sacrifices `token` with `tokenId` to the Shadowpakt, and receives VOID
    /// @dev    Sacrifice function for ERC721, must be approved beforehand
    /// @param  token Asset to sacrifice
    /// @param  tokenId    Specific asset to sacrifice
    /// @param  shadowlingId If greater than start index, mints shadowling
    function sacrifice721(
        address token,
        uint256 tokenId,
        uint256 shadowlingId
    ) external;

    /// @notice Sacrifices `amount` of `token` with `tokenId` to the Shadowpakt, and receives VOID
    /// @dev    Sacrifice function for ERC1155
    /// @param  token Asset to sacrifice
    /// @param  tokenId    Specific asset to sacrifice
    /// @param  shadowlingId If greater than start index, mints shadowling
    function sacrifice1155(
        address token,
        uint256 tokenId,
        uint256 amount,
        uint256 shadowlingId
    ) external;

    // ===== Owner =====

    /// @notice Sets the void token and shadowling contract addresses
    /// @dev One time use, these contracts must have their `owner` set to this address
    /// @param void_ Void token contract
    /// @param shadowling_ Shadowlings ERC721 contract
    function initialize(address void_, address shadowling_) external;

    /// @notice Sets the cost of using this currency, denominated in void tokens
    function setCurrencyCost(uint256 currencyId, uint256 newCost) external;

    /// @notice Update an `address` of an nft to be whitelisted to receive void on burn
    /// @param  token Address to update the cost value of
    /// @param  amount Amount of void minted per `token` burned
    function setBaseCost(address token, uint256 amount) external;

    /// @notice Sets an extra amount of void received from burning an nft with `tokenId`
    /// @param  token Address to update the cost value of
    /// @param  tokenId  Specific tokenId to delist
    /// @param  amount Extra amount of void tokens received
    function setPremiumCost(
        address token,
        uint256 tokenId,
        uint256 amount
    ) external;

    /// @notice Owner function to pull ERC1155 tokens from this contract for nefarious purposes
    function takeMany(
        address token,
        uint256 tokenId,
        uint256 amount
    ) external;

    /// @notice Owner function to pull ERC721 tokens from this contract for nefarious purposes
    function takeSingle(address token, uint256 tokenId) external;

    // ===== Constant =====

    /// @notice Void burned for conjuring a Shadowling
    function SHADOWLING_COST() external view returns (uint256);

    // ===== View =====

    /// @notice Void Token to mint
    function void() external view returns (address);

    /// @notice Shadowling NFT
    function shadowling() external view returns (address);

    /// @notice Cost of the NFT with `address`, denominated in VOID tokens
    function cost(address token) external view returns (uint256);

    /// @notice Maps currencyIds to their respective Void token cost
    function currencyCost(uint256 currencyId) external view returns (uint256);

    /// @notice Additional premium cost of an NFT with `tokenId`, denominated in VOID tokens
    function premium(address token, uint256 tokenId)
        external
        view
        returns (uint256);

    /// @return Amount of VOID minted from sacrificing `token` with `tokenId
    function totalCost(address token, uint256 tokenId)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IShadowling {
    function claim(
        uint256 tokenId,
        address recipient,
        uint256 seed
    ) external;

    function modify(
        uint256 tokenId,
        uint256 currencyId,
        uint256 seed
    ) external;

    function propertiesOf(uint256 tokenId)
        external
        view
        returns (
            uint256 creature,
            uint256 item,
            uint256 origin,
            uint256 bloodline,
            uint256 eyes,
            uint256 name
        );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./Random.sol";

library Currency {
    uint256 internal constant MOD_FOUR = 2;
    uint256 internal constant MOD_TWO = 3;
    uint256 internal constant ADD_TWO = 4;
    uint256 internal constant ADD_FOUR = 5;
    uint256 internal constant REMOVE = 6;
    uint256 internal constant AUGMENT_TWO = 7;
    uint256 internal constant AUGUMENT_FOUR = 8;
    uint256 internal constant MEM_COPY = 9;
    uint256 internal constant START_INDEX = 10;

    error ModifyError();

    /// @return Count of attribute Ids > 0
    function amountOf(uint256[4] memory params)
        internal
        pure
        returns (uint256)
    {
        uint256 len = params.length;
        uint256 count;
        for (uint256 i; i < len; i++) {
            uint256 value = params[i];
            if (value > 0) count++;
        }
        return count;
    }

    function slot(string memory prefix, uint256 seed)
        internal
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(prefix, seed)));
    }

    /// @notice Modifies an array of values which are the tokenIds for the attributes
    /// @param currencyId Type of currency being used
    /// @param params Values to manipulate; directly converted to attributes
    /// @param seed Pseudorandom value hopefully generated through a commit-reveal scheme
    function modify(
        uint256 currencyId,
        uint256[4] memory params,
        uint256 seed
    ) internal pure returns (uint256[4] memory) {
        seed = seed % 21;
        uint256 len = params.length;
        uint256 count = amountOf(params); // count how many properties are > 0

        // adds a property to a one property item
        if (currencyId == AUGMENT_TWO) {
            if (count != 1) revert ModifyError();
            // for each attribute, find the currently set one and modify the one above it
            for (uint256 i; i < len; i++) {
                uint256 value = params[i];
                // if its the last one, set the first slot
                if (i == len - 1) params[0] = slot("SLOT0", seed);
                if (value > 0) params[i + 1] = slot("SLOT1", seed);
            }
        }

        // adds a property to a three property item
        if (currencyId == AUGUMENT_FOUR) {
            if (count != 3) revert ModifyError();
            // for each attribute, find the one that is not set, and modify it
            for (uint256 i; i < len; i++) {
                uint256 value = params[i];
                // if its the last one, set the first slot
                if (value == 0) params[i] = slot("SLOT1", seed);
            }
        }

        // deletes all properties
        if (currencyId == REMOVE) {
            // for each attribute, find the one that is set, and set it to 0
            for (uint256 i; i < len; i++) {
                uint256 value = params[i];
                // if its not 0, set it to 0
                if (value > 0) params[i] = 0;
            }
        }

        // adds up to two properties to a zero property item
        if (currencyId == ADD_TWO) {
            if (count > 0) revert ModifyError();
            if (seed > 14) params[1] = slot("SLOT1", seed);
            else params[len - 1] = slot("SLOT2", seed);
        }

        // adds up to four properties to a zero property item
        if (currencyId == ADD_FOUR) {
            if (count > 0) revert ModifyError();
            for (uint256 i; i < len; i++) {
                // if its the last one, set the first slot
                if (seed > 19) params[i] = 0;
                else params[i] = slot("SLOT1", seed);
            }
        }

        // modifies up to four properties on a max four property item
        if (currencyId == MOD_FOUR) {
            if (seed > 19) params = update(seed, 1);
            else if (seed < 4) params = update(seed, 2);
            else if (seed < 19 && seed > 16) params = update(seed, 3);
            else params = update(seed, 4);
        }

        // modifies up to two properties on a max two property item
        if (currencyId == MOD_TWO) {
            if (count > 2) revert ModifyError();
            if (seed > 14) params = update(seed, 1);
            else params = update(seed, 2);
        }

        return params;
    }

    /// @notice Updates an array of values up to `max` using `seed`
    function update(uint256 seed, uint256 max)
        internal
        pure
        returns (uint256[4] memory)
    {
        uint256[4] memory params;
        uint256 updated = 1;
        params[0] = slot("SLOT0", seed);
        if (updated >= max) return params;
        updated++;
        params[1] = slot("SLOT1", seed);
        if (updated >= max) return params;
        updated++;
        params[2] = slot("SLOT2", seed);
        if (updated >= max) return params;
        params[3] = slot("SLOT3", seed);
        return params;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./interfaces/IShadowpakt.sol";

contract Shadowpakt is IShadowpakt {
    // @dev Storage for commits
    struct Commit {
        bytes32 commit;
        uint64 blockNumber;
        bool revealed;
    }

    /// @inheritdoc IShadowpakt
    mapping(address => Commit) public override commits;

    /// @inheritdoc IShadowpakt
    function commitKey(bytes32 hashedKey) public override {
        commits[msg.sender] = Commit({
            commit: hashedKey,
            blockNumber: uint64(block.number),
            revealed: false
        });
    }

    /// @inheritdoc IShadowpakt
    function revealKey(bytes32 revealHash) public override returns (uint256) {
        Commit storage commit = commits[msg.sender];
        if (commit.revealed) revert RevealedError();
        commit.revealed = true;
        if (getHash(revealHash) != commit.commit) revert HashError();
        if (uint64(block.number) <= commit.blockNumber) revert BlockError();
        if (uint64(block.number) > commit.blockNumber + 250)
            revert BlockError();
        bytes32 blockHash = blockhash(commit.blockNumber);
        uint256 random = uint256(
            keccak256(abi.encodePacked(blockHash, revealHash))
        );

        emit RevealHash(msg.sender, revealHash, random);
        return random;
    }

    // ===== View =====

    /// @inheritdoc IShadowpakt
    function getHash(bytes32 keyHash) public view override returns (bytes32) {
        return keccak256(abi.encodePacked(address(this), keyHash));
    }

    constructor() {}
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

/// @notice Is this really random?
library Random {
    /// @notice Uses a commit-reveal scheme to get randomness from miners and users, separately
    /// @param schemeHash Hash of the blockhash at the commit block.number, and their reveal hash
    /// @return pseudorandom uint value to use as randomness
    function random(string memory schemeHash) internal view returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encode(
                    keccak256(
                        abi.encodePacked(
                            block.timestamp,
                            block.number,
                            tx.origin,
                            msg.sender,
                            gasleft(),
                            schemeHash,
                            blockhash(block.number),
                            blockhash(block.number - 69)
                        )
                    )
                )
            )
        );
        return seed;
    }

    /// @param input Hash of roll number, tokenId
    /// @return pseudorandom number between 1 and 6
    function roll(string memory input) internal pure returns (uint256) {
        return (uint256(keccak256(abi.encodePacked(input))) % 6) + 1;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IShadowpakt {
    /// @notice Thrown if attempting to reveal in same block or 250 blocks too late
    error BlockError();
    /// @notice Thrown if a commit has already been revealed
    error CommitError();
    /// @notice Thrown if a hashed revealHash does not match the commit
    error HashError();
    /// @notice Thrown on revealing a committed hash
    error RevealedError();

    /// @notice Emitted on revealing a committed hash key
    event RevealHash(address indexed from, bytes32 revealHash, uint256 random);

    /// @notice Storage for commits
    function commits(address user)
        external
        view
        returns (
            bytes32 commit,
            uint64 blockNumber,
            bool revealed
        );

    /// @notice Commits a hashed key to be revealed later
    /// @dev    Miner cannot guess key, user cannot get block hash (thats the idea)
    function commitKey(bytes32 hashedKey) external;

    /// @notice Reveals the key by submitting `revealHash`
    /// @dev    Uses block hash and reveal hash for randomness
    function revealKey(bytes32 revealHash) external returns (uint256);

    // ===== View =====

    /// @notice Keccak256 hash of this contract's address and `keyHash`
    function getHash(bytes32 keyHash) external view returns (bytes32);
}