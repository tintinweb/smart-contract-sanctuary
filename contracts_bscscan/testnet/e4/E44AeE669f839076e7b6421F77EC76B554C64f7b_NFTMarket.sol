// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC721Ownable is IERC721 {
    function owner() external view returns (address);
}

struct Collection {
    IERC721Ownable token;
    bool active;
    uint256 fee;
    uint256 supply;
    mapping(uint256 => Listing) listings;
}

struct Listing {
    address owner;
    uint256 askPrice;
}

contract NFTMarket is Ownable {
    Collection[] public collections;
    mapping(address => uint256) public collectionIds;

    uint256 public fee = 400;
    address feeCollector;

    modifier onlyTokenOwner(IERC721Ownable token) {
        require(token.owner() == msg.sender, 'Not token owner.');
        _;
    }

    modifier tokenActive(IERC721Ownable token) {
        require(_active(token), 'Token not active.');
        _;
    }

    constructor() {
        feeCollector = msg.sender;
    }

    function listForSale(IERC721Ownable _token, uint256 _tokenId, uint256 _askPrice) public tokenActive(_token) {
        require(_askPrice > 0, 'Cannot list for free.');
        require(_token.ownerOf(_tokenId) == msg.sender, "You don't own this token.");

        Collection storage collection = _collection(_token);
        collection.listings[_tokenId] = Listing({
            owner: msg.sender,
            askPrice: _askPrice
        });

        _token.safeTransferFrom(msg.sender, address(this), _tokenId);
    }

    function cancelListing(IERC721Ownable _token, uint256 _tokenId) public tokenActive(_token) {
        Collection storage collection = _collection(_token);
        require(collection.listings[_tokenId].owner == msg.sender, "You don't own this token.");
        collection.listings[_tokenId].askPrice = 0;
        _token.safeTransferFrom(address(this), msg.sender, _tokenId);
    }

    function updateListing(IERC721Ownable _token, uint256 _tokenId, uint256 _askPrice) public tokenActive(_token) {
        require(_askPrice > 0, 'Cannot list for free.');
        Collection storage collection = _collection(_token);
        require(collection.listings[_tokenId].owner == msg.sender, "You don't own this token.");
        collection.listings[_tokenId].askPrice = _askPrice;
    }

    function buy(IERC721Ownable _token, uint256 _tokenId) public payable tokenActive(_token) {
        require(_isListed(_token, _tokenId), 'Token is not listed for sale.');

        Collection storage collection = _collection(_token);
        uint256 askPrice = collection.listings[_tokenId].askPrice;
        require(msg.value >= askPrice, 'Not enough funds sent.');

        uint256 marketFee = askPrice * fee / 10000;
        uint256 collectionFee = askPrice * collection.fee / 10000;
        payable(feeCollector).transfer(marketFee);
        payable(collection.token.owner()).transfer(collectionFee);

        payable(collection.listings[_tokenId].owner).transfer(msg.value-marketFee-collectionFee);

        _token.safeTransferFrom(address(this), msg.sender, _tokenId);

        collection.listings[_tokenId].owner = address(0);
        collection.listings[_tokenId].askPrice = 0;
    }

    function _active(IERC721Ownable _token) internal view returns (bool) {
        if (address(_collection(_token).token) == address(_token)) {
            return _collection(_token).active;
        }
        return false;
    }

    function _isListed(IERC721Ownable _token, uint256 _tokenId) internal view returns (bool) {
        return _collection(_token).listings[_tokenId].askPrice > 0;
    }

    function _collection(IERC721Ownable _token) internal view returns (Collection storage) {
        return collections[collectionIds[address(_token)]];
    }

    function addCollection(IERC721Ownable _token, uint256 _fee, uint256 _supply) public onlyTokenOwner(_token) {
        require(_fee <= 1000);
        require(_supply > 0);

        collectionIds[address(_token)] = collections.length;

        collections.push();
        Collection storage collection = collections[collections.length-1];
        collection.token = _token;
        collection.active = true;
        collection.fee = fee;
        collection.supply = _supply;
    }

    function setCollectionFee(IERC721Ownable _token, uint256 _fee) public onlyTokenOwner(_token) {
        _collection(_token).fee = _fee;
    }

    function setCollectionSupply(IERC721Ownable _token, uint256 _supply) public onlyOwner {
        _collection(_token).supply = _supply;
    }

    function setCollectionStatus(IERC721Ownable _token, bool _statusActive) public onlyOwner {
        _collection(_token).active = _statusActive;
    }

    function setFee(uint256 _fee) public onlyOwner {
        require(_fee <= 1000);
        fee = _fee;
    }

    function setFeeCollector(address account) public onlyOwner {
        require(account != address(0));
        feeCollector = account;
    }

    function collectionAdresses() external view returns (address[] memory) {
        address[] memory addresses;
        uint256 activeCount;
        for(uint256 i; i < collections.length; i++) {
            if (collections[i].active) {
                addresses[activeCount] = address(collections[i].token);
                activeCount++;
            }
        }
        return addresses;
    }

    function collectionCount() external view returns (uint256 activeCount) {
        for(uint256 i; i < collections.length; i++) {
            if (collections[i].active) {
                activeCount++;
            }
        }
    }

    function listings(uint256 collectionId) external view returns (Listing[] memory listing) {
        Collection storage collection = collections[collectionId];
        for(uint256 i; i <= collection.supply; i++) {
            listing[i] = collection.listings[i];
        }
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