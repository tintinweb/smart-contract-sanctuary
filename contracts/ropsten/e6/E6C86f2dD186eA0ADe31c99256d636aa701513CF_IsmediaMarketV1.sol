// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./zeppelin/Pausable.sol";
import "./zeppelin/Ownable.sol";
import "./zeppelin/IERC721.sol";
import "./zeppelin/IERC1155.sol";

contract IsmediaMarketV1 is Pausable, Ownable {

    event Purchase(
        address indexed buyer,
        address indexed seller,
        uint256 indexed tokenId,
        uint256 saleId,
        address tokenContract,
        uint8 tokenType
    );

    event SaleCreated(
        address indexed seller,
        uint256 indexed tokenId,
        uint256 saleId,
        address tokenContract,
        uint8 tokenType
    );

    event SaleCancelled(
        address indexed seller,
        uint256 indexed tokenId,
        address tokenContract,
        uint8 tokenType
    );

    enum SaleStatus {
        Pending,
        Active,
        Complete,
        Canceled,
        Timeout
    }

    enum TokenType {
        ERC721,
        ERC1155
    }

    struct TokenSale {
        address seller;
        uint256 tokenId;
        uint256 unitPrice;
        uint256 quantity;
        uint256 start;
        uint256 end;
        TokenType tokenType;
        bool cancelled;
    }

    IERC721 public erc721;
    IERC1155 public erc1155;
    mapping(uint256 => TokenSale) public sales;
    uint256 public saleCounter = 0;

    constructor(address erc721Address, address erc1155Address) {
        erc721 = IERC721(erc721Address);
        erc1155 = IERC1155(erc1155Address);
        require(erc721.supportsInterface(type(IERC721).interfaceId), "Invalid ERC721");
        require(erc1155.supportsInterface(type(IERC1155).interfaceId), "Invalid ERC1155");
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function tokenFromType(uint8 tokenType) public view returns(address) {
        if(tokenType == uint8(TokenType.ERC1155)) {
            return address(erc1155);
        } else if(tokenType == uint8(TokenType.ERC721)) {
            return address(erc721);
        }
        revert("Invalid token type");
    }

    function buy(uint256 saleId, uint256 quantity) public payable whenNotPaused() {
        TokenSale storage sale = sales[saleId];
        uint256 totalPrice = sale.unitPrice * quantity;
        require(msg.value >= totalPrice, "Payment low");
        require(quantity <= sale.quantity, "Quantity high");
        require(saleStatus(saleId) == uint8(SaleStatus.Active), "Sale inactive");

        sale.quantity -= quantity;
        address tokenAddress = tokenFromType(uint8(sale.tokenType));

        if(sale.tokenType == TokenType.ERC721) {
            erc721.safeTransferFrom(sale.seller, msg.sender, sale.tokenId);
        } else {
            erc1155.safeTransferFrom(sale.seller, msg.sender, sale.tokenId, quantity, "");
        }
        payable(sale.seller).transfer(totalPrice);
        if(msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }
        emit Purchase(
            msg.sender,
            sale.seller,
            sale.tokenId,
            saleId,
            tokenAddress,
            uint8(sale.tokenType)
        );
    }

    function _post(
        uint256 tokenId,
        uint256 unitPrice,
        uint256 quantity,
        uint256 start,
        uint256 end,
        TokenType tokenType
    ) private {
        uint256 saleId = saleCounter;
        TokenSale storage sale = sales[saleId];
        address tokenAddress = tokenFromType(uint8(tokenType));

        if(tokenType == TokenType.ERC721) {
            require(msg.sender == erc721.ownerOf(tokenId), "Not token owner");
            require(erc721.getApproved(tokenId) == address(this), "Not approved");
        } else {
            require(erc1155.balanceOf(msg.sender, tokenId) >= quantity, "Not enough tokens");
            require(erc1155.isApprovedForAll(msg.sender, address(this)), "Not approved");
        }
        sale.seller = msg.sender;
        sale.tokenId = tokenId;
        sale.unitPrice = unitPrice;
        sale.quantity = quantity;
        sale.tokenType = tokenType;
        sale.start = start;
        sale.end = end;
        sale.cancelled = false;

        saleCounter += 1;

        emit SaleCreated(
            msg.sender,
            tokenId,
            saleId,
            tokenAddress,
            uint8(tokenType)
        );
    }

    function postERC1155(uint256 tokenId, uint256 unitPrice, uint256 quantity, uint256 start, uint256 end) public whenNotPaused() {
        _post(tokenId, unitPrice, quantity, start, end, TokenType.ERC1155);
    }

    function postERC721(uint256 tokenId, uint256 unitPrice, uint256 start, uint256 end) public whenNotPaused() {
        _post(tokenId, unitPrice, 1, start, end, TokenType.ERC721);
    }

    function cancel(uint256 saleId) public whenNotPaused() {
        TokenSale storage sale = sales[saleId];
        require(sale.seller == msg.sender, "Only sale owner");
        require(saleStatus(saleId) == uint8(SaleStatus.Active), "Sale inactive");

        address tokenAddress = tokenFromType(uint8(sale.tokenType));

        sale.cancelled = true;

        emit SaleCancelled(
            sale.seller,
            sale.tokenId,
            tokenAddress,
            uint8(sale.tokenType)
        );
    }

    function saleStatus(uint256 saleId) public view returns(uint8) {
        TokenSale storage sale = sales[saleId];
        if(sale.cancelled) {
            return uint8(SaleStatus.Canceled);
        }
        if(sale.quantity == 0) {
            return uint8(SaleStatus.Complete);
        }
        if(sale.end != 0 && block.timestamp > sale.end) {
            return uint8(SaleStatus.Timeout);
        }
        if(sale.start != 0 && block.timestamp < sale.start) {
            return uint8(SaleStatus.Pending);
        }
        return uint8(SaleStatus.Active);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
        require(!paused(), "Paused");
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
        require(paused(), "Not paused");
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    function isOwner(address account) public view returns (bool) {
        if( account == owner ){
            return true;
        }
        else {
            return false;
        }
    }
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "No transfer to 0");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

import "./IERC165.sol";

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

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}