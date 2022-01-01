//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./utils/Operator.sol";
import "./interfaces/IAztecToken.sol";

contract ERC1155Marketplace is Operator, ERC1155Holder {
    struct ListingItem {
        uint256 id;
        uint256 priceInWei;
        address token;
        uint256 typeId;
        uint256 quantity;
        address seller;
        uint256 timeCreated;
        uint256 timeLastPurchased;
        bool cancelled;
    }

    address public constant BURN_ADDRESS =
        0x687a48eba6b3A7A060D89eA63232f20D83aCBDF8;

    uint256 public _listingIdCounter;
    mapping(uint256 => ListingItem) public _listings;

    address public _colosseum;
    address public _fund;
    IAztecToken public _aztecToken;
    uint256 public _burnFeeRate;
    uint256 public _colosseumFeeRate; // 10000 = 100%
    uint256 public _fundFeeRate;

    mapping(address => uint256) private _swapAztBalances;
    mapping(address => uint256) private _swapAztWithdrews;

    event AddListing(
        uint256 indexed listingId,
        address indexed seller,
        address token,
        uint256 typeId,
        uint256 quantity,
        uint256 priceInWei,
        uint256 time
    );
    event PurchaseListing(
        uint256 indexed listingId,
        address indexed seller,
        address buyer,
        address token,
        uint256 typeId,
        uint256 quantity,
        uint256 costInWei,
        uint256 time
    );
    event CancelListing(uint256 indexed listingId, uint256 time);

    constructor(
        address aztecToken,
        address colosseum,
        address fund,
        address operator
    ) {
        _aztecToken = IAztecToken(aztecToken);
        _colosseum = colosseum;
        _fund = fund;
        _colosseumFeeRate = 200;
        _burnFeeRate = 200;
        _fundFeeRate = 100;

        setOperator(operator, true);
    }

    function addListing(
        address token,
        uint256 typeId,
        uint256 quantity,
        uint256 priceInWei
    ) public {
        IERC1155 erc1155Token = IERC1155(token);
        address seller = _msgSender();
        require(
            erc1155Token.balanceOf(seller, typeId) >= quantity,
            "ERC1155Marketplace: Not enough ERC1155 token"
        );
        require(
            erc1155Token.isApprovedForAll(seller, address(this)),
            "ERC1155Marketplace: Not approved for transfer"
        );
        require(
            priceInWei >= 1 ether,
            "ERC1155Marketplace: Price should be 1 or larger"
        );

        erc1155Token.safeTransferFrom(
            seller,
            address(this),
            typeId,
            quantity,
            ""
        );

        _listingIdCounter++;
        uint256 listingId = _listingIdCounter;
        _listings[listingId] = ListingItem({
            id: listingId,
            priceInWei: priceInWei,
            token: token,
            typeId: typeId,
            quantity: quantity,
            seller: seller,
            timeCreated: block.timestamp,
            timeLastPurchased: 0,
            cancelled: false
        });

        emit AddListing(
            listingId,
            seller,
            token,
            typeId,
            quantity,
            priceInWei,
            block.timestamp
        );
    }

    function cancelListing(uint256 listingId) public {
        ListingItem storage listingItem = _listings[listingId];
        if (listingItem.id == 0) {
            return;
        }
        require(
            listingItem.seller == _msgSender(),
            "ERC1155Marketplace: caller not seller"
        );

        if (listingItem.cancelled || listingItem.quantity == 0) {
            return;
        }
        listingItem.cancelled = true;

        IERC1155(listingItem.token).safeTransferFrom(
            address(this),
            _msgSender(),
            listingItem.typeId,
            listingItem.quantity,
            ""
        );
        emit CancelListing(listingId, block.timestamp);
    }

    function purchaseListing(uint256 listingId, uint256 quantity) public {
        ListingItem storage listingItem = _listings[listingId];
        if (listingItem.id == 0) {
            return;
        }
        require(
            listingItem.quantity > 0 && listingItem.cancelled == false,
            "ERC1155Marketplace: Listing is closed"
        );
        address buyer = _msgSender();
        address seller = listingItem.seller;
        require(seller != buyer, "ERC1155Marketplace: buyer can't be seller");
        require(quantity > 0, "ERC1155Marketplace: quantity can't be zero");
        require(
            quantity <= listingItem.quantity,
            "ERC1155Marketplace: quantity is greater than listing"
        );
        listingItem.quantity -= quantity;
        listingItem.timeLastPurchased = block.timestamp;
        uint256 amount = quantity * listingItem.priceInWei;

        // burn
        uint256 burnShare = (amount * _burnFeeRate) / 10000;
        _aztecToken.transferFrom(buyer, BURN_ADDRESS, burnShare);
        // colosseum
        uint256 colosseumShare = (amount * _colosseumFeeRate) / 10000;
        _aztecToken.transferFrom(buyer, _colosseum, colosseumShare);
        // fund
        uint256 fundShare = (amount * _fundFeeRate) / 10000;
        _aztecToken.transferFrom(buyer, _fund, fundShare);

        // deposit this address
        uint256 sellerShare = amount - burnShare - colosseumShare - fundShare;
        _aztecToken.transferFrom(buyer, address(this), sellerShare);

        // to seller
        _swapAztBalances[listingItem.seller] += sellerShare;
        IERC1155(listingItem.token).safeTransferFrom(
            address(this),
            _msgSender(),
            listingItem.typeId,
            quantity,
            ""
        );

        emit PurchaseListing(
            listingId,
            listingItem.seller,
            _msgSender(),
            listingItem.token,
            listingItem.typeId,
            quantity,
            amount,
            block.timestamp
        );
    }

    function batchCancelListing(uint256[] memory listingIds) external {
        for (uint256 index; index < listingIds.length; index++) {
            cancelListing(listingIds[index]);
        }
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _swapAztBalances[owner];
    }

    function withdrew(address owner) public view returns (uint256) {
        return _swapAztWithdrews[owner];
    }

    function withdraw() public {
        address owner = _msgSender();
        uint256 balance = _swapAztBalances[owner];
        _swapAztBalances[owner] = 0;
        _swapAztWithdrews[owner] += balance;
        _aztecToken.transfer(owner, balance);
    }

    function setRecipient(address colosseum, address fund)
        external
        onlyOperator
    {
        require(colosseum != address(0), "Zero address");
        require(fund != address(0), "Zero address");
        _colosseum = colosseum;
        _fund = fund;
    }

    function setFeeRate(
        uint256 colosseumRate,
        uint256 burnFeeRate,
        uint256 fundFeeRate
    ) external onlyOperator {
        _colosseumFeeRate = colosseumRate;
        _burnFeeRate = burnFeeRate;
        _fundFeeRate = fundFeeRate;
    }

    function setAztecToken(address aztecToken) external onlyOperator {
        _aztecToken = IAztecToken(aztecToken);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
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
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Operator is Ownable {
    mapping(address => bool) private _operators;

    event OperatorSetted(address account, bool allow);

    modifier onlyOperator() {
        require(_operators[_msgSender()], "Forbidden");
        _;
    }

    constructor() {
        setOperator(_msgSender(), true);
    }

    function operator(address account) public view returns (bool) {
        return _operators[account];
    }

    function setOperator(address account, bool allow) public onlyOwner {
        _operators[account] = allow;
        emit OperatorSetted(account, allow);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IAztecToken is IERC20 {}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155Receiver.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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