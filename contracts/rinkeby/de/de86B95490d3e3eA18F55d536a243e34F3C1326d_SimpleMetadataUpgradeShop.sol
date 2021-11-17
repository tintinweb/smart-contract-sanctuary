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

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface ISimpleToken {
	function balanceOf(address user) external returns(uint);

	function spend(address user, uint256 amount) external;

	function mint(address to, uint256 amount) external;
}

interface ISimpleton is IERC721Enumerable {
	// function ownerOf(uint256 tokenId) external view returns(address owner);
}

interface ISimpletonette is IERC721Enumerable {
	// function ownerOf(uint256 tokenId) external view returns(address owner);
}

// interface ISimpleton {
// 	// function ownerOf(uint256 tokenId) external view returns(address owner);
// }

// interface ISimpletonette {
// 	// function ownerOf(uint256 tokenId) external view returns(address owner);
// }

contract SimpleMetadataUpgradeShop is Ownable {
	event MetadataUpgrade(address indexed user, uint256 indexed tokenId, uint256 indexed itemId, string itemType, string itemName);

	ISimpleToken public SimpleToken;
	ISimpleton public Simpleton;
	ISimpletonette public Simpletonette;

	address public constant SIMPLETOKEN_ADDRESS = 0x9500f6DFe279749b35b279903DB0F43012B6E0E6;
	address public constant SIMPLETON_ADDRESS = 0x02bba39690a01853FF0cb825db93581C0338Ef7c;
	address public SIMPLETONETTE_ADDRESS = 0x8d6B949F0eF2ab2e4eC6d73146C5168eB70010eE;

	uint256 public numTypes = 0;
	bool public shopIsOpen = false;

	mapping(uint256 => string) public itemCategories;
	mapping(uint256 => string) public itemNames;
	mapping(uint256 => uint256) public itemPrices;
	mapping(uint256 => uint256) public itemTotalSupplies;
	mapping(uint256 => uint256) public itemMaxSupplies;

	mapping(uint256 => uint256[]) internal simpletonUpgradableItemsIds;
	mapping(uint256 => uint256[]) internal simpletonetteUpgradableItemsIds;

	function upgradeSimpletonMetadata(uint256 itemId, uint256 tokenId) external {
		require(shopIsOpen, "SHOP_CLOSED");
		require(tokenId >= 1 && tokenId <= 3000, "INVALID_TOKEN_ID");
		require(itemTotalSupplies[itemId] + 1 <= itemMaxSupplies[itemId], "NO_SUPPLY");
		require(ISimpleton(SIMPLETON_ADDRESS).ownerOf(tokenId) == msg.sender, "NOT_OWNER");
		require(ISimpleToken(SIMPLETOKEN_ADDRESS).balanceOf(msg.sender) >= itemPrices[itemId], "NOT_ENOUGH_BALANCE");

		upgradeMetadata(simpletonetteUpgradableItemsIds[tokenId], itemId, tokenId);
	}

	function upgradeSimpletonetteMetadata(uint256 itemId, uint256 tokenId) external {
		require(shopIsOpen, "SHOP_CLOSED");
		require(tokenId >= 1 && tokenId <= 3000, "INVALID_TOKEN_ID");
		require(itemTotalSupplies[itemId] + 1 <= itemMaxSupplies[itemId], "NO_SUPPLY");
		require(ISimpletonette(SIMPLETONETTE_ADDRESS).ownerOf(tokenId) == msg.sender, "NOT_OWNER");
		require(ISimpleToken(SIMPLETOKEN_ADDRESS).balanceOf(msg.sender) >= itemPrices[itemId], "NOT_ENOUGH_BALANCE");

		upgradeMetadata(simpletonetteUpgradableItemsIds[tokenId], itemId, tokenId);
	}

	function upgradeMetadata(uint256[] storage array, uint256 itemId, uint256 tokenId) internal {
		bool found = false;
		for (uint256 i = array.length; i > 0; i--) {
			uint256 _itemId = array[i - 1];
			if (_itemId == itemId) {
				found = true;
				break;
			}
		}
		if (!found) {
			ISimpleToken(SIMPLETOKEN_ADDRESS).spend(msg.sender, itemPrices[itemId]);
			ISimpleToken(SIMPLETOKEN_ADDRESS).mint(owner(), itemPrices[itemId] / 20);
			itemTotalSupplies[itemId] += 1;
			array.push(itemId);
			emit MetadataUpgrade(msg.sender, tokenId, itemId, itemCategories[itemId], itemNames[itemId]);
		}
	}

	function addItem(uint256 itemId, string memory itemCategory, string memory itemName, uint256 itemPrice, uint256 supply) external onlyOwner {
		itemPrices[itemId] = itemPrice;
		itemCategories[itemId] = itemCategory;
		itemNames[itemId] = itemName;
		itemMaxSupplies[itemId] = supply;
		if (itemTotalSupplies[itemId] == 0) {
			numTypes++;
		}
	}

	function getSimpletonUpgradableItemsIds(uint tokenId) public view returns(uint256[] memory) {
		require(simpletonUpgradableItemsIds[tokenId].length > 0, "No upgrades for this simpleton");
		return simpletonUpgradableItemsIds[tokenId];
	}

	function getSimpletonetteUpgradableItemsIds(uint tokenId) public view returns(uint256[] memory) {
		require(simpletonetteUpgradableItemsIds[tokenId].length > 0, "No upgrades for this simpleton");
		return simpletonetteUpgradableItemsIds[tokenId];
	}

	function totalSupply(uint256 typeId) public view returns(uint256) {
		require(itemPrices[typeId] > 0, "Invalid item type");
		return itemTotalSupplies[typeId];
	}

	function toggleShopIsOpen() external {
		shopIsOpen = !shopIsOpen;
	}
}