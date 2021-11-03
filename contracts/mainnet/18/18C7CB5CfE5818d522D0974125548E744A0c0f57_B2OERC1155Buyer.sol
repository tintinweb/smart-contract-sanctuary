//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
$$$$$$$\   $$$$$$\   $$$$$$\ $$$$$$$$\ $$\   $$\ 
$$  __$$\ $$  __$$\ $$  __$$\\__$$  __|$$$\  $$ |
$$ |  $$ |\__/  $$ |$$ /  $$ |  $$ |   $$$$\ $$ |
$$$$$$$\ | $$$$$$  |$$ |  $$ |  $$ |   $$ $$\$$ |
$$  __$$\ $$  ____/ $$ |  $$ |  $$ |   $$ \$$$$ |
$$ |  $$ |$$ |      $$ |  $$ |  $$ |   $$ |\$$$ |
$$$$$$$  |$$$$$$$$\  $$$$$$  |  $$ |   $$ | \$$ |
\_______/ \________| \______/   \__|   \__|  \__| 
                                                 */

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract B2OERC1155Buyer is Ownable {

    //ERC1155 contract interface
    IERC1155 private _erc1155Contract;

    //Mapping from token ID to price
    mapping(uint256 => uint256) private _prices;

    //Withdrawals balance for owner
    uint256 private _pendingWithdrawals;

    //Construct with ERC1155 contract address
    constructor(address erc1155Addr) {
        _erc1155Contract = IERC1155(erc1155Addr);
    }

    //Set prices of tokens
    function setPrice(uint256 tokenId, uint256 price) public onlyOwner {

        require(price > 0, 'B2OERC1155Buyer: price must be > 0');

        _prices[tokenId] = price;
    }

    function setPriceBatch(uint256[] memory tokenIds, uint256[] memory prices) public onlyOwner {

        require(tokenIds.length == prices.length, 'B2OERC1155Buyer: tokensIds and prices length do not match');

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(prices[i] > 0, 'B2OERC1155Buyer: price must be > 0');
            _prices[tokenIds[i]] = prices[i];
        }
    }

    function getPrice(uint256 tokenId) public view returns(uint256) {
        return _prices[tokenId];
    }

    //Buy function
    function buyToken(address to, uint256 tokenId, uint256 amount, bytes memory data) public payable {

        require(_prices[tokenId] > 0, 'B2OERC1155Buyer: wrong token id');
        require(amount <= 5, "B2OERC1155Buyer: can't buy more than 5 tokens");
        require(msg.value >= _prices[tokenId] * amount, "B2OERC1155Buyer: not enough ETH sent");

        //Transfer tokens
        _erc1155Contract.safeTransferFrom(
            owner(),
            to,
            tokenId,
            amount,
            data
        );

        //Record payment to signer's withdrawal balance
        _pendingWithdrawals += msg.value;
    }

    //BuyBatch function
    function buyTokenBatch(address to, uint256[] memory tokenIds, uint256[] memory amounts, bytes memory data) public payable {
        
        require(tokenIds.length == amounts.length, 'B2OERC1155Buyer: tokensIds and amounts length do not match');

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(_prices[tokenIds[i]] > 0, 'B2OERC1155Buyer: wrong token id');
            require(amounts[i] <= 5, "B2OERC1155Buyer: can't buy more than 5 tokens");
            totalAmount += _prices[tokenIds[i]] * amounts[i];
        }
        require(msg.value >= totalAmount, "B2OERC1155Buyer: not enough ETH sent");

        //Transfer tokens
        _erc1155Contract.safeBatchTransferFrom(
            owner(),
            to,
            tokenIds,
            amounts,
            data
        );

        //Record payment to signer's withdrawal balance
        _pendingWithdrawals += msg.value;
    }


    //Transfers all pending withdrawal balance to the owner
    function withdraw() public onlyOwner {
        
        //Owner must be a payable address.
        address payable receiver = payable(msg.sender);

        uint amount = _pendingWithdrawals;

        //Set zero before transfer to prevent re-entrancy attack
        _pendingWithdrawals = 0;
        receiver.transfer(amount);
    }

    //Retuns the amount of Ether available to withdraw.
    function availableToWithdraw() public view onlyOwner returns (uint256) {
        return _pendingWithdrawals;
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