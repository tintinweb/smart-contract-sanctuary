// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @title Marketplace.
/// @author Team SarahRo (SRO).
/// @notice Create a NFT SRO Collection contract for the marketplace.
/// @dev This Marketplace connects to a ERC20 and ERC721 contracts by import OpenZeppelin.

contract Marketplace {
    using Counters for Counters.Counter;

    // Enums
    enum Status {
        Inactive,
        OnSale,
        Sold,
        Cancelled
    }

    // Structure
    struct MarketNft {
        Status status;
        uint256 nftId;
        uint256 price;
        address seller;
        address collection;
    }

    // State variables
    IERC20 private _token;
    Counters.Counter private _saleIds;
    mapping(uint256 => MarketNft) private _sales; // struc des vente
    mapping(address => mapping(uint256 => uint256)) private _saleByCollectionId; // retrouver la vente via l'adresse et l'id

    // Events
    event Registered(address indexed seller, uint256 indexed saleId); // Vente créé
    event PriceChanged(uint256 indexed saleId, uint256 price); // Prix MAJ
    event Cancelled(address indexed seller, uint256 indexed saleId); // Cancel
    event Sold(address indexed buyer, uint256 indexed saleId); // Sold

    // Constructor
    constructor(address xsroAddress) {
        _token = IERC20(xsroAddress);
    }

    // Modifiers

    /// @notice Check that the NFT is on sale.
    /// @param saleId Id of sale.

    modifier onSale(uint256 saleId) {
        require(_sales[saleId].status == Status.OnSale, "Marketplace: this nft is not on sale");
        _;
    }

    /// @notice Check that it is the seller of the nft.
    /// @param saleId Id of sale.

    modifier onlySeller(uint256 saleId) {
        address seller = _sales[saleId].seller;
        require(msg.sender == seller, "Markerplace: you must be the seller of this nft");
        _;
    }

    // TODO Only authorize collection address from our NFT collection factory.

    /// @notice Create a sale with SRO collection.
    /// @dev The createSale function is public.
    /// @param collectionAddress Address of collection.
    /// @param nftId Id of nft.
    /// @param price Price to defined for sale.
    /// @return Bool.

    function createSale(
        address collectionAddress,
        uint256 nftId,
        uint256 price
    ) public returns (bool) {
        require(!isOnSale(collectionAddress, nftId), "Marketplace: This nft is already on sale");
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

    /// @notice Set the price of the NFT currently on the marketplace.
    /// @dev The setPrice function is public with modifier(onSale and onlySeller).
    /// @param saleId Id of sale.
    /// @param newPrice New price to defined.
    /// @return Bool.

    // Todo : Ajouter event pour récuperer l'ancien prix.

    function setPrice(uint256 saleId, uint256 newPrice) public onSale(saleId) onlySeller(saleId) returns (bool) {
        _sales[saleId].price = newPrice;
        emit PriceChanged(saleId, newPrice);
        return true;
    }

    /// @notice This function allows to remove the NFT on the marketplace.
    /// @dev The removeSale function is public with modifier(onSale and onlySeller).
    /// @param saleId Id of sale.
    /// @return Bool.

    function removeSale(uint256 saleId) public onSale(saleId) onlySeller(saleId) returns (bool) {
        MarketNft memory item = _sales[saleId];
        _sales[saleId].status = Status.Cancelled;
        delete _saleByCollectionId[item.collection][item.nftId];
        emit Cancelled(msg.sender, saleId);
        return true;
    }

    /// @notice This function allows to buy the NFT on the marketplace.
    /// @dev The buyNft function is public with modifier(onSale).
    /// @param saleId Id of sale.
    /// @return Bool.

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

    /// @notice Check token address.
    /// @dev The token function is public view.
    /// @return Address of token.

    function token() public view returns (address) {
        return address(_token);
    }

    /// @notice Check status of the sale.
    /// @dev The getSale function is public view.
    /// @param saleId Id of sale.
    /// @return Status of the sale (on sale, address, seller ...).

    function getSale(uint256 saleId) public view returns (MarketNft memory) {
        return _sales[saleId];
    }

    /// @notice Check id of status of the sale.
    /// @dev The getSaleId function is public view.
    /// @param collection Address of collection.
    /// @param nftId Id of NFT.
    /// @return Id of sale.

    function getSaleId(address collection, uint256 nftId) public view returns (uint256) {
        return _saleByCollectionId[collection][nftId];
    }

    /// @notice Check if NFT is on sale.
    /// @dev The isOnSale function is public view.
    /// @param collection Address of collection.
    /// @param nftId Id of NFT.
    /// @return Bool.

    function isOnSale(address collection, uint256 nftId) public view returns (bool) {
        uint256 saleId = getSaleId(collection, nftId);
        return _sales[saleId].status == Status.OnSale;
    }

    /// @notice Number of times the CreateSale function is validated (done).
    /// @dev The isOnSale function is public view.
    /// @return Number of created sale validated.

    function totalSale() public view returns (uint256) {
        return _saleIds.current();
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

