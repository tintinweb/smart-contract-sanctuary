// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract NFTMarketplace is Ownable {
	string public constant name = "Avaware NFT Marketplace";

	struct Listing {
		uint256 id;
		address user;
		address tokenContract;
		uint256 tokenId;
		uint256 amount;
		address buyToken;
		uint256 price;
		bool isERC721;
	}

	event ListingCreated(Listing listing);
	event ListingUpdated(Listing listing);
	event ListingFulfilled(Listing listing);
	event ListingCancelled(Listing listing);
	event TokenAdded(address token);
	event TokenRemoved(address token);

	Listing[] public listings;
	mapping(address => bool) public tokens;
	uint256 public feePercent = 0;

	constructor() {
		tokens[address(0)] = true;
	}

	function addToken(address token) external onlyOwner {
		require(!tokens[token], "Token Already Listed");
		tokens[token] = true;
		emit TokenAdded(token);
	}

	function removeToken(address token) external onlyOwner {
		require(tokens[token], "Token Not Listed");
		delete tokens[token];
		emit TokenRemoved(token);
	}

	function totalListing() external view returns (uint256) {
		return listings.length;
	}

	function createListing(
		address user,
		address tokenContract,
		uint256 tokenId,
		uint256 amount,
		address buyToken,
		uint256 price,
		bool isERC721
	) internal {
		require(tokens[buyToken], "Invalid Token");
		uint256 id = listings.length;
		Listing memory listing = Listing(id, user, tokenContract, tokenId, amount, buyToken, price, isERC721);
		listings.push(listing);
		emit ListingCreated(listing);
	}

	function listERC721(
		address tokenContract,
		uint256 tokenId,
		address buyToken,
		uint256 price
	) external {
		IERC721(tokenContract).transferFrom(msg.sender, address(this), tokenId);
		createListing(msg.sender, tokenContract, tokenId, 1, buyToken, price, true);
	}

	function listERC1155(
		address tokenContract,
		uint256 tokenId,
		uint256 amount,
		address buyToken,
		uint256 price
	) external {
		IERC1155(tokenContract).safeTransferFrom(msg.sender, address(this), tokenId, amount, "0x00");
		createListing(msg.sender, tokenContract, tokenId, amount, buyToken, price, false);
	}

	function updateListing(
		uint256 id,
		address buyToken,
		uint256 price
	) external {
		require(id < listings.length, "Invalid Listing");
		require(listings[id].user == msg.sender, "Invalid User");
		require(tokens[buyToken], "Invalid Token");
		listings[id].buyToken = buyToken;
		listings[id].price = price;
		emit ListingUpdated(listings[id]);
	}

	function fulfillListing(uint256 id, uint256 amount) internal {
		listings[id].amount -= amount;
		if (listings[id].amount == 0) {
			emit ListingFulfilled(listings[id]);
		} else {
			emit ListingUpdated(listings[id]);
		}
	}

	function getListingPrice(uint256 id, uint256 amount) internal view returns (uint256) {
		if (feePercent > 0) {
			return listings[id].price * amount * (100 - feePercent);
		} else {
			return listings[id].price * amount;
		}
	}

	function fulfillERC721(uint256 id) external payable {
		require(id < listings.length, "Invalid Listing");
		require(listings[id].amount > 0, "Amount Insufficient");
		uint256 price = getListingPrice(id, 1);
		if (listings[id].buyToken == address(0)) {
			require(msg.value >= price, "Value Insufficient");
			payable(listings[id].user).transfer(price);
		} else {
			IERC20(listings[id].buyToken).transferFrom(msg.sender, listings[id].user, price);
		}
		IERC721(listings[id].tokenContract).transferFrom(address(this), msg.sender, listings[id].tokenId);
		fulfillListing(id, 1);
	}

	function fulfillERC1155(uint256 id, uint256 amount) external payable {
		require(id < listings.length, "Invalid Listing");
		require(listings[id].amount >= amount, "Amount Insufficient");
		uint256 price = getListingPrice(id, amount);
		if (listings[id].buyToken == address(0)) {
			require(msg.value >= price, "Value Insufficient");
			payable(listings[id].user).transfer(price);
		} else {
			IERC20(listings[id].buyToken).transferFrom(msg.sender, listings[id].user, price);
		}
		IERC1155(listings[id].tokenContract).safeTransferFrom(
			address(this),
			msg.sender,
			listings[id].tokenId,
			amount,
			"0x01"
		);
		fulfillListing(id, amount);
	}

	function cancelListing(uint256 id) external {
		require(id < listings.length, "Invalid Listing");
		require(listings[id].user == msg.sender, "Invalid User");
		require(listings[id].amount > 0, "Listing Fulfilled");
		if (listings[id].isERC721) {
			listings[id].amount = 0;
			IERC721(listings[id].tokenContract).transferFrom(address(this), msg.sender, listings[id].tokenId);
		} else {
			uint256 amount = listings[id].amount;
			listings[id].amount = 0;
			IERC1155(listings[id].tokenContract).safeTransferFrom(
				address(this),
				msg.sender,
				listings[id].tokenId,
				amount,
				"0x02"
			);
		}
		emit ListingCancelled(listings[id]);
	}

	function withdraw() public onlyOwner {
		require(address(this).balance > 0, "Amount Insufficient");
		payable(owner()).transfer(address(this).balance);
	}

	// receive() external payable

	function escapeERC20(address token) public onlyOwner {
		uint256 amount = IERC20(token).balanceOf(address(this));
		require(amount > 0, "Amount Insufficient");
		IERC20(token).transfer(msg.sender, amount);
	}

	function escapeERC721(address token, uint256 tokenId) public onlyOwner {
		require(IERC721(token).ownerOf(tokenId) == address(this), "Invalid Token");
		IERC721(token).transferFrom(address(this), msg.sender, tokenId);
	}

	function escapeERC1155(
		address token,
		uint256 tokenId,
		uint256 amount
	) public onlyOwner {
		require(IERC1155(token).balanceOf(address(this), tokenId) >= amount, "Invalid Token");
		require(amount > 0, "Amount Insufficient");
		IERC1155(token).safeTransferFrom(address(this), msg.sender, tokenId, amount, "0x03");
	}

	function onERC1155Received(
		address,
		address,
		uint256,
		uint256,
		bytes calldata
	) external pure returns (bytes4) {
		return 0xf23a6e61;
	}

	function onERC1155BatchReceived(
		address,
		address,
		uint256[] memory,
		uint256[] memory,
		bytes memory
	) public virtual returns (bytes4) {
		return 0xf23a6e61;
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