//SPDX-License-Identifier: un-licensed
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CruzoMarket is ERC1155Holder, Ownable {
    event TradeStatusChange(uint256 indexed itemId, bytes32 status);
    event PriceChange(uint256 oldPrice, uint256 newPrice);

    struct Trade {
        address payable poster;
        address tokenAddress;
        uint256 itemId;
        uint256 amount; // in  wei
        uint256 price; // in  wei
        bytes32 status; // e.g Open, Executed, Cancelled
    }

    mapping(uint256 => Trade) private trades;

    uint256 private tradeCounter;

    // Get individual trade
    function getTrade(uint256 _trade) public view returns (Trade memory) {
        Trade memory trade = trades[_trade];
        return trade;
    }

    /* 
    List item in the market place for sale
    item unique id and amount of tokens to be put on sale price of item
    and an additional data parameter if you dont wan to pass data set it to empty string 
    if your sending the transaction through Frontend 
    else if you are send the transaction using etherscan or using nodejs set it to 0x00 
    */

    function openTrade(
        address _tokenAddress,
        uint256 _itemId,
        uint256 _amount,
        uint256 _price,
        bytes calldata data
    ) public {
        IERC1155 itemToken = IERC1155(_tokenAddress);
        require(
            itemToken.balanceOf(msg.sender, _itemId) != 0,
            "Error: Only owner can list"
        );
        itemToken.safeTransferFrom(
            payable(msg.sender),
            address(this),
            _itemId,
            _amount,
            data
        );
        trades[tradeCounter] = Trade({
            tokenAddress: _tokenAddress,
            poster: payable(msg.sender),
            itemId: _itemId,
            amount: _amount,
            price: _price,
            status: "Open"
        });

        tradeCounter += 1;
        emit TradeStatusChange(tradeCounter - 1, "Open");
    }

    /*
    Buyer execute trade and pass the trade number
    and an additional data parameter if you dont want to pass data set it to empty string 
    if your sending the transaction through Frontend 
    else if you are send the transaction using etherscan or using nodejs set it to 0x00 
    */

    function executeTrade(uint256 _trade, bytes calldata data) public payable {
        Trade memory trade = trades[_trade];
        IERC1155 itemToken = IERC1155(trade.tokenAddress);
        require(trade.status == "Open", "Error: Trade is not Open");
        require(
            msg.sender != address(0) && msg.sender != trade.poster,
            "Error: msg.sender is zero address or the owner is trying to buy his own nft"
        );
        require(
            trade.price == msg.value,
            "Error: value provided is not equal to the nft price"
        );

        payable(trade.poster).transfer(msg.value);
        itemToken.safeTransferFrom(
            address(this),
            payable(msg.sender),
            trade.itemId,
            trade.amount,
            data
        );
        trades[_trade].status = "Executed";
        trades[_trade].poster = payable(msg.sender);
        emit TradeStatusChange(_trade, "Executed");
    }

    /*
    Seller can cancle trade by passing the trade number
    and an additional data parameter if you dont wan to pass data set it to empty string 
    if your sending the transaction through Frontend 
    else if you are send the transaction using etherscan or using nodejs set it to 0x00 
    */

    function cancelTrade(uint256 _trade, bytes calldata data) public {
        Trade memory trade = trades[_trade];
        IERC1155 itemToken = IERC1155(trade.tokenAddress);
        require(
            msg.sender == trade.poster,
            "Error: Trade can be cancelled only by poster"
        );
        require(trade.status == "Open", "Error: Trade is not Open");
        itemToken.safeTransferFrom(
            address(this),
            trade.poster,
            trade.itemId,
            trade.amount,
            data
        );
        trades[_trade].status = "Cancelled";
        emit TradeStatusChange(_trade, "Cancelled");
    }

    // Get all items which are on sale in the market place
    function getAllOnSale() public view virtual returns (Trade[] memory) {
        uint256 counter = 0;
        uint256 itemCounter = 0;
        for (uint256 i = 0; i < tradeCounter; i++) {
            if (trades[i].status == "Open") {
                counter++;
            }
        }

        Trade[] memory tokensOnSale = new Trade[](counter);
        if (counter != 0) {
            for (uint256 i = 0; i < tradeCounter; i++) {
                if (trades[i].status == "Open") {
                    tokensOnSale[itemCounter] = trades[i];
                    itemCounter++;
                }
            }
        }

        return tokensOnSale;
    }

    // get all items owned by a perticular address
    function getAllByOwner(address owner) public view returns (Trade[] memory) {
        uint256 counter = 0;
        uint256 itemCounter = 0;
        for (uint256 i = 0; i < tradeCounter; i++) {
            if (trades[i].poster == owner) {
                counter++;
            }
        }

        Trade[] memory tokensByOwner = new Trade[](counter);
        if (counter != 0) {
            for (uint256 i = 0; i < tradeCounter; i++) {
                if (trades[i].poster == owner) {
                    tokensByOwner[itemCounter] = trades[i];
                    itemCounter++;
                }
            }
        }

        return tokensByOwner;
    }

    /*
    Seller can lowner the price of item by specifing trade number and new price
    if he wants to increase the price of item, he can unlist the item and then specify a higher price
    */
    function lowerTokenPrice(uint256 _trade, uint256 newPrice) public {
        require(
            msg.sender == trades[_trade].poster,
            "Error: Price can only be set by poster"
        );

        require(trades[_trade].status == "Open", "Error: Trade is not Open");

        uint256 oldPrice = trades[_trade].price;
        require(
            newPrice < oldPrice,
            "Error: please specify a price value less than the old price if you want to increase the price, cancel the trade and list again  with a higher price"
        );
        trades[_trade].price = newPrice;
        emit PriceChange(oldPrice, newPrice);
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