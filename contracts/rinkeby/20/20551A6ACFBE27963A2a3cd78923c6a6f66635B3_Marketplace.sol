// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Marketplace {
    using Counters for Counters.Counter;

    IERC20 private _token;

    enum Status {
        Inactive,
        OnSale,
        Sold,
        Cancelled
    }

    struct MarketNft {
        Status status;
        uint256 nftId;
        uint256 price;
        address seller;
        address collection;
    }

    Counters.Counter private _saleIds;
    mapping(uint256 => MarketNft) private _sales;
    mapping(address => mapping(uint256 => uint256)) private _saleByCollectionId;

    event Registered(address indexed seller, uint256 indexed saleId);
    event PriceChanged(uint256 indexed saleId, uint256 price);
    event Cancelled(address indexed seller, uint256 indexed saleId);
    event Sold(address indexed buyer, uint256 indexed saleId);

    constructor(address xsroAddress) {
        _token = IERC20(xsroAddress);
    }

    modifier onSale(uint256 saleId) {
        require(_sales[saleId].status == Status.OnSale, "Marketplace: this nft is not on sale");
        _;
    }

    modifier onlySeller(uint256 saleId) {
        address seller = _sales[saleId].seller;
        require(msg.sender == seller, "Markerplace: you must be the seller of this nft");
        _;
    }

    /**
     * TODO Only authorize collection address from our NFT collection factory
     * check collection address isContract() ?
     */
    function createSale(
        address collectionAddress,
        uint256 nftId,
        uint256 price
    ) public returns (bool) {
        require(_isContract(collectionAddress), "Marketplace: collection address is not a contract");
        IERC721 collection = IERC721(collectionAddress);
        address owner = collection.ownerOf(nftId);
        require(msg.sender == owner, "Markerplace: you must be the owner of this nft");
        require(
            collection.getApproved(nftId) == address(this) || collection.isApprovedForAll(msg.sender, address(this)),
            "Marketplace: you need to approve this contract"
        );
        _saleIds.increment();
        uint256 currentId = _saleIds.current();
        _sales[currentId] = MarketNft(Status.OnSale, nftId, price, msg.sender, collectionAddress);
        _saleByCollectionId[collectionAddress][nftId] = currentId;
        emit Registered(msg.sender, currentId);
        return true;
    }

    // function change price
    function setPrice(uint256 saleId, uint256 newPrice) public onSale(saleId) onlySeller(saleId) returns (bool) {
        _sales[saleId].price = newPrice;
        emit PriceChanged(saleId, newPrice);
        return true;
    }

    // function remove sale
    function removeSale(uint256 saleId) public onSale(saleId) onlySeller(saleId) returns (bool) {
        MarketNft memory item = _sales[saleId];
        item.status = Status.Cancelled;
        delete _saleByCollectionId[item.collection][item.nftId];
        emit Cancelled(msg.sender, saleId);
        return true;
    }

    // buy function
    function buyNft(uint256 saleId) public onSale(saleId) returns (bool) {
        MarketNft memory item = _sales[saleId];
        require(_token.balanceOf(msg.sender) >= item.price, "Marketplace: not enough xSRO");
        require(
            _token.allowance(msg.sender, address(this)) >= item.price,
            "Marketplace: you need to approve this contract to buy"
        );
        _sales[saleId].status = Status.Sold;
        delete _saleByCollectionId[item.collection][item.nftId];
        _token.transferFrom(msg.sender, item.seller, item.price);
        IERC721(item.collection).safeTransferFrom(item.seller, msg.sender, item.nftId);
        emit Sold(msg.sender, saleId);
        return true;
    }

    function token() public view returns (address) {
        return address(_token);
    }

    function getSale(uint256 saleId) public view returns (MarketNft memory) {
        return _sales[saleId];
    }

    function getSaleId(address collection, uint256 nftId) public view returns (uint256) {
        return _saleByCollectionId[collection][nftId];
    }

    function isOnSale(address collection, uint256 nftId) public view returns (bool) {
        uint256 saleId = getSaleId(collection, nftId);
        return _sales[saleId].status == Status.OnSale;
    }

    function totalSale() public view returns (uint256) {
        return _saleIds.current();
    }

    function _isContract(address collection) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(collection)
        }
        return size > 0;
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

