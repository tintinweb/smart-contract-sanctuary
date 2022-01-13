/**
 *Submitted for verification at polygonscan.com on 2022-01-12
*/

// File @openzeppelin/contracts/token/ERC20/[email protected]

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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


// File @openzeppelin/contracts/utils/introspection/[email protected]



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


// File @openzeppelin/contracts/token/ERC1155/[email protected]



pragma solidity ^0.8.0;

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
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}


// File @openzeppelin/contracts/token/ERC721/[email protected]



pragma solidity ^0.8.0;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}


// File @openzeppelin/contracts/utils/math/[email protected]



pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


// File contracts/NFT_Marketplace.sol

pragma solidity ^0.8.9;
contract ArtisLifeNFTMartketplace {
    using SafeMath for uint256;

    // ID trackers. Also sale and offer counters.
    uint256 public saleID;
    uint256 public offerID;
    uint256 public collectionOfferID;
    uint256 public auctionID;
    uint256 public auctionOfferID;

    // Admin address
    address public ADMIN;

    // Marketplace Fee Percentage (0 - 10000)
    uint256 public marketplaceFee;

    // NFT Address to NFT ID to Sale Count
    mapping(address => mapping(uint256 => uint256)) public currentSaleCount;

    // NFT Address to NFT ID to user to Sale Count
    mapping(address => mapping(uint256 => mapping(address => uint256)))
        public currentSaleCountByUser;
    // NFT ID to Offer Count
    mapping(address => mapping(uint256 => uint256)) public currentOfferCount;

    // NFT ID to Auction Count
    mapping(address => mapping(uint256 => uint256)) public currentAuctionCount;

    // Map to track bids in auction. AuctionId to user address to their top bid
    mapping(uint256 => mapping(address => uint256)) topBids;

    // map to track number of nfts up for auction from given user
    mapping(address => mapping(uint256 => mapping(address => uint256)))
        public currentAuctionCountByUser;

    // NFT Address to Collection Offer Count
    mapping(address => uint256) public currentCollectionOfferCount;
    // Payment Token to User balance
    mapping(address => mapping(address => uint256))
        public currentOfferCountByUser;

    // NFT Sale Object
    struct nftSaleInfo {
        bool created;
        bool active;
        bool completed;
        bool canceled;
        uint256 nftID;
        uint256 price;
        address owner;
        uint256 royalty;
        address settlementToken;
        address creator;
        address nftAddress;
        uint256 erc;
    }

    // NFT Auction Object
    struct nftAuctionInfo {
        bool created;
        bool active;
        bool completed;
        bool canceled;
        uint256 nftID;
        uint256 reserve;
        address owner;
        uint256 royalty;
        address settlementToken;
        address creator;
        address nftAddress;
        uint256 erc;
        uint256 createdAt;
        uint256 expirationTime;
    }

    // NFT Offer Object
    struct nftOfferInfo {
        bool created;
        bool active;
        bool completed;
        bool canceled;
        uint256 nftID;
        uint256 price;
        address owner;
        uint256 royalty;
        address settlementToken;
        address creator;
        address nftAddress;
        uint256 erc;
    }

    // Collection Offer Object
    struct collectionOfferInfo {
        bool created;
        bool active;
        bool completed;
        bool canceled;
        uint256 price;
        address owner;
        uint256 royalty;
        address settlementToken;
        address creator;
        address nftAddress;
        uint256 erc;
    }

    // All NFT Sales
    mapping(uint256 => nftSaleInfo) public nftsForSale;
    mapping(uint256 => nftAuctionInfo) public nftsForAuction;
    mapping(uint256 => nftOfferInfo) public nftsOffer;
    mapping(uint256 => collectionOfferInfo) public collectionOffers;

    //Offer events
    event OfferAccepted(
        uint256 offerId,
        address buyer,
        uint256 price,
        uint256 royaltyPaid
    );
    event OfferPriceUpdated(uint256 offerId, uint256 price);
    event OfferCanceled(uint256 offerId);
    event NewOfferCreated(
        address owner,
        uint256 offerId,
        uint256 nftID,
        uint256 royalty,
        uint256 price,
        address settlementToken,
        address nftAddress,
        uint256 erc
    );
    event OfferRoyaltyUpdated(uint256 offerId, uint256 fee, address creator);

    //Sale events
    event SaleBought(
        uint256 saleId,
        address buyer,
        uint256 price,
        uint256 royaltyPaid
    );
    event SalePriceUpdated(uint256 saleId, uint256 price);
    event SaleCanceled(uint256 saleId);
    event NewSaleCreated(
        address owner,
        uint256 saleID,
        uint256 nftID,
        uint256 royalty,
        uint256 price,
        address settlementToken,
        address nftAddress,
        uint256 erc
    );
    event SaleRoyaltyUpdated(uint256 saleId, uint256 royalty, address creator);

    //Collection Offer events
    event CollectionOfferAccepted(
        uint256 offerId,
        address buyer,
        uint256 price,
        uint256 royaltyPaid
    );
    event CollectionOfferPriceUpdated(uint256 offerId, uint256 price);
    event CollectionOfferCanceled(uint256 offerId);
    event NewCollectionOfferCreated(
        address owner,
        uint256 offerId,
        uint256 royalty,
        uint256 price,
        address settlementToken,
        address nftAddress,
        uint256 erc
    );
    event CollectionOfferRoyaltyUpdated(
        uint256 offerId,
        uint256 fee,
        address creator
    );

    //Auction events
    event AuctionFinished(
        uint256 AuctionId,
        address buyer,
        uint256 price,
        uint256 royaltyPaid
    );
    event AuctionNewBid(uint256 AuctionId, uint256 price, address bidder);
    event AuctionReserveUpdated(uint256 AuctionId, uint256 price);
    event AuctionCanceled(uint256 AuctionId);
    event NewAuctionCreated(
        address owner,
        uint256 AuctionID,
        uint256 nftID,
        uint256 royalty,
        uint256 price,
        address settlementToken,
        address nftAddress,
        uint256 erc,
        uint256 expirationTime
    );
    event AuctionRoyaltyUpdated(
        uint256 AuctionId,
        uint256 royalty,
        address creator
    );

    constructor() {
        ADMIN = msg.sender;
        marketplaceFee = 150;
    }

    /*
     *   newOffer
     *
     *   Function to set a new offer for any given NFT.
     *
     */
    function newOffer(
        uint256 id,
        address nftAddress,
        uint256 price,
        uint256 royalty,
        address paymentToken,
        address creator,
        uint256 erc
    ) external {
        require(price > 0, "Price must be greater than zero.");
        require(
            paymentToken != 0x0000000000000000000000000000000000001010,
            "Use WETH."
        );
        require(
            paymentToken != 0x0000000000000000000000000000000000000000,
            "Cannot pay with zero address."
        );
        require(erc == 721 || erc == 1155, "NFT not supported.");
        IERC20 token = IERC20(paymentToken);
        require(
            token.balanceOf(msg.sender) >=
                (price + currentOfferCountByUser[paymentToken][msg.sender]),
            "Not enough balance."
        );
        require(royalty < 9850, "Cannot set royalty higher than 98.5%");
        require(
            token.allowance(msg.sender, address(this)) >=
                price + currentOfferCountByUser[paymentToken][msg.sender],
            "Not approved for that amount."
        );
        currentOfferCount[nftAddress][id] = currentOfferCount[nftAddress][id]
            .add(1);
        currentOfferCountByUser[paymentToken][
            msg.sender
        ] = currentOfferCountByUser[paymentToken][msg.sender].add(price);
        nftsOffer[offerID] = nftOfferInfo(
            true,
            true,
            false,
            false,
            id,
            price,
            msg.sender,
            royalty,
            paymentToken,
            creator,
            nftAddress,
            erc
        );
        emit NewOfferCreated(
            msg.sender,
            offerID,
            id,
            royalty,
            price,
            paymentToken,
            nftAddress,
            erc
        );
        offerID = offerID.add(1);
    }

    /*
     *  newAuction
     *
     *  Set new Aution for given nft ID
     */
    function newAuction(
        uint256 id,
        address nftAddress,
        uint256 reserve,
        uint256 royalty,
        address paymentToken,
        address creator,
        uint256 erc
    ) external {
        require(
            paymentToken != 0x0000000000000000000000000000000000000000,
            "Cannot pay with zero address."
        );
        require(
            paymentToken != 0x0000000000000000000000000000000000001010,
            "Use WETH."
        );
        require(erc == 721 || erc == 1155, "NFT not supported.");
        require(royalty < 9850, "Cannot set royalty higher than 98.5%");
        if (erc == 1155) {
            IERC1155 nftObject = IERC1155(nftAddress);
            require(
                nftObject.balanceOf(msg.sender, id) >
                    currentSaleCountByUser[nftAddress][id][msg.sender] +
                        currentAuctionCountByUser[nftAddress][id][msg.sender],
                "Not enough balance."
            );
            require(
                nftObject.isApprovedForAll(msg.sender, address(this)),
                "Not approved."
            );
        } else {
            IERC721 nftObject = IERC721(nftAddress);
            require(nftObject.ownerOf(id) == msg.sender, "No Balance.");
            require(
                currentSaleCountByUser[nftAddress][id][msg.sender] +
                    currentAuctionCountByUser[nftAddress][id][msg.sender] ==
                    0,
                "Not enough balance."
            );
            require(
                nftObject.isApprovedForAll(msg.sender, address(this)),
                "Not approved."
            );
        }
        currentAuctionCount[nftAddress][id] = currentAuctionCount[nftAddress][
            id
        ].add(1);
        currentAuctionCountByUser[nftAddress][id][
            msg.sender
        ] = currentAuctionCountByUser[nftAddress][id][msg.sender].add(1);
        nftsForAuction[auctionID] = nftAuctionInfo(
            true,
            true,
            false,
            false,
            id,
            reserve,
            msg.sender,
            royalty,
            paymentToken,
            creator,
            nftAddress,
            erc,
            block.timestamp,
            block.timestamp + 30 days
        );
        emit NewAuctionCreated(
            msg.sender,
            auctionID,
            id,
            royalty,
            reserve,
            paymentToken,
            nftAddress,
            erc,
            block.timestamp + 30 days
        );
        auctionID = auctionID.add(1);
    }

    /*
     *   newAuctionOffer
     *
     *   Function to set a new auction offer for any given auction ID.
     *
     */
    function newAuctionBid(uint256 offer, uint256 auctionId) external 
        auctionExists(auctionId)
        auctionIsNotCanceled(auctionId)
        auctionIsNotCompleted(auctionId)
        auctionIsActive(auctionId)
    {
        address sender = msg.sender;
        address settlementToken = nftsForAuction[auctionId].settlementToken;
        require(
            block.timestamp < nftsForAuction[auctionId].expirationTime,
            "Auction has ended."
        );
        require(
            offer > nftsForAuction[auctionId].reserve,
            "Bid must be greater than reserve."
        );
        uint256 myTopBid = topBids[auctionId][sender];
        uint256 myOffers = currentOfferCountByUser[settlementToken][sender];
        require(offer > myTopBid, "Bid must be greater than previous bid.");
        IERC20 token = IERC20(settlementToken);
        require(
            token.balanceOf(sender) >= (offer + myOffers.sub(myTopBid)),
            "Not enough balance. Cancel other offers or aquire more tokens."
        );
        require(
            token.allowance(sender, address(this)) >=
                offer + myOffers.sub(myTopBid),
            "Not approved for that amount. Cancel other offers or approve more tokens."
        );
        uint256 expTime = nftsForAuction[auctionId].expirationTime;
        if (expTime > block.timestamp + 10 minutes) {
            expTime = block.timestamp + 10 minutes;
        }
        if (myTopBid == 0) {
            currentOfferCountByUser[settlementToken][sender] = myOffers.add(
                offer
            );
        } else {
            currentOfferCountByUser[settlementToken][sender] = myOffers.sub(
                myTopBid
            );
            currentOfferCountByUser[settlementToken][sender] = myOffers.add(
                offer
            );
        }
        topBids[auctionId][sender] = offer;
        emit AuctionNewBid(auctionId, offer, sender);
    }

    /*
     *   acceptAuctionOffer
     *
     *   Function to finalize an auction that has valid bids.
     *
     */
    function acceptAuctionOffer(uint256 auctionId, address offeror) external 
        auctionExists(auctionId)
        auctionIsNotCanceled(auctionId)
        auctionIsNotCompleted(auctionId)
        auctionIsActive(auctionId)
    {
        uint256 auction = auctionId;
        address nftAddress = nftsForAuction[auction].nftAddress;
        uint256 id = nftsForAuction[auction].nftID;
        address settlementToken = nftsForAuction[auction].settlementToken;
        uint256 salePrice = topBids[auction][offeror];
        address owner = nftsForAuction[auction].owner;
        address creator = nftsForAuction[auction].creator;
        uint256 erc = nftsForAuction[auction].erc;
        currentOfferCount[nftAddress][id] = currentOfferCount[nftAddress][id]
            .sub(1);
        currentOfferCountByUser[settlementToken][
            owner
        ] = currentOfferCountByUser[settlementToken][owner].sub(salePrice);
        uint256 royalty = nftsForAuction[auction].royalty;
        swapTokensForNFT(
            msg.sender,
            owner,
            id,
            nftAddress,
            settlementToken,
            1,
            salePrice,
            royalty,
            creator,
            erc
        );
        nftsForAuction[auction].active = false;
        nftsForAuction[auction].completed = true;
        emit AuctionFinished(auction, msg.sender, salePrice, royalty);
    }

    /*
     *   newCollectionOffer
     *
     *   Function to set a new colleciton offer for any given collection.
     *
     */
    function newCollectionOffer(
        address nftAddress,
        uint256 price,
        uint256 royalty,
        address paymentToken,
        address creator,
        uint256 erc
    ) external {
        require(price > 0, "Price must be greater than zero.");
        require(
            paymentToken != 0x0000000000000000000000000000000000001010,
            "Use WETH."
        );
        require(
            paymentToken != 0x0000000000000000000000000000000000000000,
            "Cannot pay with zero address."
        );
        require(erc == 721 || erc == 1155, "NFT not supported.");
        IERC20 token = IERC20(paymentToken);
        require(
            token.balanceOf(msg.sender) >=
                (price + currentOfferCountByUser[paymentToken][msg.sender]),
            "Not enough balance."
        );
        require(royalty < 9850, "Cannot set royalty higher than 98.5%");
        require(
            token.allowance(msg.sender, address(this)) >=
                price + currentOfferCountByUser[paymentToken][msg.sender],
            "Not approved for that amount."
        );
        currentCollectionOfferCount[nftAddress] = currentCollectionOfferCount[
            nftAddress
        ].add(1);
        currentOfferCountByUser[paymentToken][
            msg.sender
        ] = currentOfferCountByUser[paymentToken][msg.sender].add(price);
        collectionOffers[collectionOfferID] = collectionOfferInfo(
            true,
            true,
            false,
            false,
            price,
            msg.sender,
            royalty,
            paymentToken,
            creator,
            nftAddress,
            erc
        );
        emit NewCollectionOfferCreated(
            msg.sender,
            offerID,
            royalty,
            price,
            paymentToken,
            nftAddress,
            erc
        );
        collectionOfferID = collectionOfferID.add(1);
    }

    function acceptCollectionOffer(uint256 offerId, uint256 nftID)
        external
        collectionOfferExists(offerId)
        collectionOfferIsActive(offerId)
        collectionOfferIsNotCompleted(offerId)
        collectionOfferIsNotCanceled(offerId)
    {
        uint256 saleId = offerId;
        uint256 id = nftID;
        address nftAddress = collectionOffers[saleId].nftAddress;
        address settlementToken = collectionOffers[saleId].settlementToken;
        uint256 salePrice = collectionOffers[saleId].price;
        address owner = collectionOffers[saleId].owner;
        address creator = collectionOffers[saleId].creator;
        uint256 erc = collectionOffers[saleId].erc;

        currentCollectionOfferCount[nftAddress] = currentCollectionOfferCount[
            nftAddress
        ].sub(1);
        currentOfferCountByUser[settlementToken][
            owner
        ] = currentOfferCountByUser[settlementToken][owner].sub(salePrice);
        uint256 royalty = collectionOffers[saleId].royalty;
        swapTokensForNFT(
            msg.sender,
            owner,
            id,
            nftAddress,
            settlementToken,
            1,
            salePrice,
            royalty,
            creator,
            erc
        );
        collectionOffers[saleId].active = false;
        collectionOffers[saleId].completed = true;
        emit OfferAccepted(saleId, msg.sender, salePrice, royalty);
    }

    function swapTokensForNFT(
        address nftowner,
        address tokenowner,
        uint256 nftid,
        address nftaddress,
        address tokenAddress,
        uint256 nftamount,
        uint256 saleprice,
        uint256 royaltyPercent,
        address creator,
        uint256 erc
    ) private {
        uint256 salePrice = saleprice;
        uint256 marketFee = salePrice.mul(marketplaceFee).div(10000);
        uint256 royalty = salePrice.mul(royaltyPercent).div(10000);
        uint256 grossPrice = salePrice.sub(royalty).sub(marketFee);
        address nftOwner = nftowner;
        address tokenOwner = tokenowner;
        address nftAddress = nftaddress;
        uint256 nftId = nftid;
        uint256 nftAmount = nftamount;
        require(grossPrice > 0, "Royalty and/or Market Fee too high.");
        IERC20 token = IERC20(tokenAddress);
        token.transferFrom(tokenOwner, address(this), salePrice);
        token.transfer(nftOwner, grossPrice);
        token.transfer(creator, royalty);
        if (erc == 1155) {
            IERC1155 nftObject = IERC1155(nftAddress);
            require(nftObject.balanceOf(nftOwner, nftId) > 0, "No Balance.");
            require(
                nftObject.isApprovedForAll(nftOwner, address(this)),
                "Not approved."
            );
            nftObject.safeTransferFrom(
                nftOwner,
                tokenOwner,
                nftId,
                nftAmount,
                "0x3"
            );
        } else {
            IERC721 nftObject = IERC721(nftAddress);
            require(nftObject.ownerOf(nftId) == nftOwner, "No Balance.");
            require(
                nftObject.isApprovedForAll(nftOwner, address(this)),
                "Not approved."
            );
            nftObject.safeTransferFrom(nftOwner, tokenOwner, nftId);
        }
    }

    /*
     *  Set For
     *
     *
     */
    function setForSale(
        uint256 id,
        address nftAddress,
        uint256 price,
        uint256 royalty,
        address paymentToken,
        address creator,
        uint256 erc
    ) external {
        require(
            paymentToken != 0x0000000000000000000000000000000000000000,
            "Cannot pay with zero address."
        );
        require(
            paymentToken != 0x0000000000000000000000000000000000001010,
            "Use WETH."
        );
        require(price > 0, "Price must be greater than zero.");
        require(erc == 721 || erc == 1155, "NFT not supported.");
        require(royalty < 9850, "Cannot set royalty higher than 98.5%");
        if (erc == 1155) {
            IERC1155 nftObject = IERC1155(nftAddress);
            require(
                nftObject.balanceOf(msg.sender, id) >
                    currentSaleCountByUser[nftAddress][id][msg.sender],
                "Not enough balance."
            );
            require(
                nftObject.isApprovedForAll(msg.sender, address(this)),
                "Not approved."
            );
        } else {
            IERC721 nftObject = IERC721(nftAddress);
            require(nftObject.ownerOf(id) == msg.sender, "No Balance.");
            require(
                currentSaleCountByUser[nftAddress][id][msg.sender] == 0,
                "Not enough balance."
            );
            require(
                nftObject.isApprovedForAll(msg.sender, address(this)),
                "Not approved."
            );
        }
        currentSaleCount[nftAddress][id] = currentSaleCount[nftAddress][id].add(
            1
        );
        currentSaleCountByUser[nftAddress][id][
            msg.sender
        ] = currentSaleCountByUser[nftAddress][id][msg.sender].add(1);
        nftsForSale[saleID] = nftSaleInfo(
            true,
            true,
            false,
            false,
            id,
            price,
            msg.sender,
            royalty,
            paymentToken,
            creator,
            nftAddress,
            erc
        );
        emit NewSaleCreated(
            msg.sender,
            saleID,
            id,
            royalty,
            price,
            paymentToken,
            nftAddress,
            erc
        );
        saleID = saleID.add(1);
    }

    function acceptOffer(uint256 offerId)
        external
        offerExists(offerId)
        offerIsActive(offerId)
        offerIsNotCompleted(offerId)
        offerIsNotCanceled(offerId)
    {
        uint256 saleId = offerId;
        address nftAddress = nftsOffer[saleId].nftAddress;
        uint256 id = nftsOffer[saleId].nftID;
        address settlementToken = nftsOffer[saleId].settlementToken;
        uint256 salePrice = nftsOffer[saleId].price;
        address owner = nftsOffer[saleId].owner;
        address creator = nftsOffer[saleId].creator;
        uint256 erc = nftsOffer[saleId].erc;
        currentOfferCount[nftAddress][id] = currentOfferCount[nftAddress][id]
            .sub(1);
        currentOfferCountByUser[settlementToken][
            owner
        ] = currentOfferCountByUser[settlementToken][owner].sub(salePrice);
        uint256 royaltyPercent = nftsOffer[saleId].royalty;

        swapTokensForNFT(
            msg.sender,
            owner,
            id,
            nftAddress,
            settlementToken,
            1,
            salePrice,
            royaltyPercent,
            creator,
            erc
        );
        emit OfferAccepted(saleId, msg.sender, salePrice, royaltyPercent);
    }

    function buy(uint256 saleIdentification)
        external
        saleExists(saleIdentification)
        saleIsActive(saleIdentification)
        saleIsNotCompleted(saleIdentification)
        saleIsNotCanceled(saleIdentification)
    {
        uint256 saleId = saleIdentification;
        uint256 salePrice = nftsForSale[saleId].price;
        uint256 royalty = nftsForSale[saleId].royalty;
        uint256 nftID = nftsForSale[saleId].nftID;
        address nftAddress = nftsForSale[saleId].nftAddress;
        address owner = nftsForSale[saleId].owner;
        uint256 erc = nftsForSale[saleId].erc;
        address creator = nftsForSale[saleId].creator;
        swapTokensForNFT(
            owner,
            msg.sender,
            nftID,
            nftAddress,
            nftsForSale[saleId].settlementToken,
            1,
            salePrice,
            royalty,
            creator,
            erc
        );
        nftsForSale[saleId].active = false;
        nftsForSale[saleId].completed = true;
        currentSaleCount[nftAddress][nftID] = currentSaleCount[nftAddress][
            nftID
        ].sub(1);
        currentSaleCountByUser[nftAddress][nftID][
            owner
        ] = currentSaleCountByUser[nftAddress][nftID][owner].sub(1);
        emit SaleBought(saleId, msg.sender, salePrice, royalty);
    }

    function cancel(uint256 saleId)
        public
        onlySaleOwner(saleId)
        saleExists(saleId)
        saleIsNotCompleted(saleId)
        saleIsNotCanceled(saleId)
    {
        uint256 nftID = nftsForSale[saleId].nftID;
        address nftAddress = nftsForSale[saleId].nftAddress;
        nftsForSale[saleId].canceled = true;
        currentSaleCount[nftAddress][nftID] = currentSaleCount[nftAddress][
            nftID
        ].sub(1);
        currentSaleCountByUser[nftAddress][nftID][
            msg.sender
        ] = currentSaleCountByUser[nftAddress][nftID][msg.sender].sub(1);
        emit SaleCanceled(saleId);
    }

    function cancelADMIN(uint256 saleId, address)
        external
        onlyADMIN
        saleExists(saleId)
        saleIsNotCompleted(saleId)
        saleIsNotCanceled(saleId)
    {
        uint256 nftID = nftsForSale[saleId].nftID;
        address nftAddress = nftsForSale[saleId].nftAddress;
        address owner = nftsForSale[saleId].owner;
        nftsForSale[saleId].canceled = true;
        currentSaleCount[nftAddress][nftID] = currentSaleCount[nftAddress][
            nftID
        ].sub(1);
        currentSaleCountByUser[nftAddress][nftID][
            owner
        ] = currentSaleCountByUser[nftAddress][nftID][owner].sub(1);
        emit SaleCanceled(saleId);
    }

    function updatePrice(uint256 saleId, uint256 price)
        external
        onlySaleOwner(saleId)
        saleExists(saleId)
        saleIsNotCompleted(saleId)
        saleIsNotCanceled(saleId)
    {
        require(price > 0, "Price must be greater than zero.");
        uint256 erc = nftsForSale[saleId].erc;
        if (erc == 1155) {
            IERC1155 nftObject = IERC1155(nftsForSale[saleId].nftAddress);
            if (nftObject.balanceOf(msg.sender, nftsForSale[saleId].nftID) > 0)
                nftsForSale[saleId].price = price;
            else cancel(saleId);
        } else {
            IERC721 nftObject = IERC721(nftsForSale[saleId].nftAddress);
            if (nftObject.ownerOf(nftsForSale[saleId].nftID) == msg.sender)
                nftsForSale[saleId].price = price;
            else cancel(saleId);
        }
        emit SalePriceUpdated(saleId, price);
    }

    function updateRoyalty(
        uint256 saleId,
        uint256 royalty,
        address creator
    ) external onlyADMIN saleExists(saleId) saleIsNotCanceled(saleId) {
        require(royalty < 9850, "Royalty cannot be 98.5% or higher.");
        nftsForSale[saleId].royalty = royalty;
        nftsForSale[saleId].creator = creator;
        emit SaleRoyaltyUpdated(saleId, royalty, creator);
    }

    // Offer helper functions
    function cancelOffer(uint256 offerId)
        external
        onlyOfferOwner(offerId)
        offerExists(offerId)
        offerIsNotCompleted(offerId)
        offerIsNotCanceled(offerId)
    {
        uint256 nftID = nftsOffer[offerId].nftID;
        address owner = msg.sender;
        address nftAddress = nftsOffer[offerId].nftAddress;
        uint256 price = nftsOffer[offerId].price;
        address settlementToken = nftsOffer[offerId].settlementToken;
        nftsOffer[offerId].canceled = true;
        currentOfferCount[nftAddress][nftID] = currentOfferCount[nftAddress][
            nftID
        ].sub(1);
        currentOfferCountByUser[settlementToken][
            owner
        ] = currentOfferCountByUser[settlementToken][owner].sub(price);
        emit OfferCanceled(offerId);
    }

    function cancelOfferADMIN(uint256 offerId, address)
        external
        onlyADMIN
        offerExists(offerId)
        offerIsNotCompleted(offerId)
        offerIsNotCanceled(offerId)
    {
        uint256 nftID = nftsOffer[offerId].nftID;
        address owner = nftsOffer[offerId].owner;
        address nftAddress = nftsOffer[offerId].nftAddress;
        uint256 price = nftsOffer[offerId].price;
        address settlementToken = nftsOffer[offerId].settlementToken;
        nftsOffer[offerId].canceled = true;
        currentOfferCount[nftAddress][nftID] = currentOfferCount[nftAddress][
            nftID
        ].sub(1);
        currentOfferCountByUser[settlementToken][
            owner
        ] = currentOfferCountByUser[settlementToken][owner].sub(price);
        emit OfferCanceled(offerId);
    }

    function updateOffer(uint256 offerId, uint256 price)
        external
        onlyOfferOwner(offerId)
        offerExists(offerId)
        offerIsNotCompleted(offerId)
        offerIsNotCanceled(offerId)
    {
        require(price > 0, "Price must be greater than zero.");
        address settlementToken = nftsOffer[offerId].settlementToken;
        IERC20 token = IERC20(settlementToken);
        uint256 oldPrice = nftsOffer[offerId].price;
        uint256 newTotal = currentOfferCountByUser[settlementToken][msg.sender]
            .sub(oldPrice)
            .add(price);
        if (token.balanceOf(msg.sender) >= newTotal) {
            nftsOffer[offerId].price = price;
            currentOfferCountByUser[settlementToken][msg.sender] = newTotal;
            emit OfferPriceUpdated(offerId, price);
        } else revert("Not enough balance.");
    }

    function updateOfferRoyalty(
        uint256 offerId,
        uint256 royalty,
        address creator
    ) external onlyADMIN offerExists(offerId) offerIsNotCanceled(offerId) {
        require(royalty < 9850, "Royalty cannot be 98.5% or higher.");
        nftsOffer[offerId].royalty = royalty;
        nftsOffer[offerId].creator = creator;
        emit OfferRoyaltyUpdated(offerId, royalty, creator);
    }

    //Collection offer helper functions
    function cancelCollectionOffer(uint256 offerId)
        external
        onlyCollectionOfferOwner(offerId)
        collectionOfferExists(offerId)
        collectionOfferIsNotCompleted(offerId)
        collectionOfferIsNotCanceled(offerId)
    {
        address settlementToken = collectionOffers[offerId].settlementToken;
        address nftAddress = collectionOffers[offerId].nftAddress;
        uint256 price = collectionOffers[offerId].price;
        collectionOffers[offerId].canceled = true;
        currentCollectionOfferCount[nftAddress] = currentCollectionOfferCount[
            nftAddress
        ].sub(1);
        currentOfferCountByUser[settlementToken][
            msg.sender
        ] = currentOfferCountByUser[settlementToken][msg.sender].sub(price);
        emit CollectionOfferCanceled(offerId);
    }

    function cancelCollectionOfferADMIN(uint256 offerId, address)
        external
        onlyADMIN
        collectionOfferExists(offerId)
        collectionOfferIsNotCompleted(offerId)
        collectionOfferIsNotCanceled(offerId)
    {
        address owner = collectionOffers[offerId].owner;
        address nftAddress = collectionOffers[offerId].nftAddress;
        uint256 price = collectionOffers[offerId].price;
        address settlementToken = collectionOffers[offerId].settlementToken;
        collectionOffers[offerId].canceled = true;
        currentCollectionOfferCount[nftAddress] = currentCollectionOfferCount[
            nftAddress
        ].sub(1);
        currentOfferCountByUser[settlementToken][
            owner
        ] = currentOfferCountByUser[settlementToken][owner].sub(price);
        emit CollectionOfferCanceled(offerId);
    }

    function updateCollectionOffer(uint256 offerId, uint256 price)
        external
        onlyCollectionOfferOwner(offerId)
        collectionOfferExists(offerId)
        collectionOfferIsNotCompleted(offerId)
        collectionOfferIsNotCanceled(offerId)
    {
        require(price > 0, "Price must be greater than zero.");
        address settlementToken = collectionOffers[offerId].settlementToken;
        IERC20 token = IERC20(settlementToken);
        uint256 oldPrice = collectionOffers[offerId].price;
        uint256 newTotal = currentOfferCountByUser[settlementToken][msg.sender]
            .sub(oldPrice)
            .add(price);
        if (token.balanceOf(msg.sender) >= newTotal) {
            collectionOffers[offerId].price = price;
            currentOfferCountByUser[settlementToken][msg.sender] = newTotal;
            emit CollectionOfferPriceUpdated(offerId, price);
        } else revert("Not enough balance.");
    }

    function updateCollectionOfferRoyalty(
        uint256 offerId,
        uint256 royalty,
        address creator
    )
        external
        onlyADMIN
        collectionOfferExists(offerId)
        collectionOfferIsNotCanceled(offerId)
    {
        require(royalty < 9850, "Royalty cannot be 98.5% or higher.");
        collectionOffers[offerId].royalty = royalty;
        collectionOffers[offerId].creator = creator;
        emit CollectionOfferRoyaltyUpdated(offerId, royalty, creator);
    }

    //Auction helper functions
    function cancelAuction(uint256 auctionId)
        external
        onlyAuctionOwner(auctionId)
        auctionExists(auctionId)
        auctionIsNotCompleted(auctionId)
        auctionIsNotCanceled(auctionId)
    {
        address nftAddress = nftsForAuction[auctionId].nftAddress;
        uint256 nftId = nftsForAuction[auctionId].nftID;
        nftsForAuction[auctionId].canceled = true;
        currentAuctionCount[nftAddress][nftId] = currentAuctionCount[
            nftAddress
        ][nftId].sub(1);
        currentAuctionCountByUser[nftAddress][nftId][
            msg.sender
        ] = currentAuctionCountByUser[nftAddress][nftId][msg.sender].sub(1);
        emit AuctionCanceled(auctionId);
    }

    function updateAuctionRoyalty(
        uint256 auctionId,
        uint256 royalty,
        address creator
    )
        external
        onlyADMIN
        auctionExists(auctionId)
        auctionIsNotCanceled(auctionId)
    {
        require(royalty < 9850, "Royalty cannot be 98.5% or higher.");
        nftsForAuction[auctionId].royalty = royalty;
        nftsForAuction[auctionId].creator = creator;
        emit AuctionRoyaltyUpdated(auctionId, royalty, creator);
    }

    function updateMarketplaceFee(uint256 fee) external onlyADMIN {
        require(fee < 1000, "Fee cannot be 10% or higher.");
        marketplaceFee = fee;
    }

    function collectFees(address token) external onlyADMIN {
        IERC20 Token = IERC20(token);
        Token.transfer(msg.sender, Token.balanceOf(address(this)));
    }

    function emergencyWithdraw(address a) external onlyADMIN {
        IERC20 token = IERC20(a);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function recoverFunds() external onlyADMIN {
        payable(msg.sender).transfer(address(this).balance);
    }

    function emergencyNFTWithdraw(
        address nftAddress,
        uint256 nftID,
        uint256 erc
    ) external onlyADMIN {
        require(erc == 721 || erc == 1155, "NFT Not Supported.");
        if (erc == 1155) {
            IERC1155 token = IERC1155(nftAddress);
            token.safeTransferFrom(
                address(this),
                msg.sender,
                nftID,
                token.balanceOf(address(this), nftID),
                ""
            );
        } else {
            IERC721 token = IERC721(nftAddress);
            token.transferFrom(
                address(this),
                msg.sender,
                token.balanceOf(address(this))
            );
        }
    }

    function setNewAdmin(address newAdmin) external onlyADMIN {
        ADMIN = newAdmin;
    }

    modifier onlyADMIN() {
        require(msg.sender == ADMIN, "Not ADMIN.");
        _;
    }

    modifier onlySaleOwner(uint256 saleId) {
        require(msg.sender == nftsForSale[saleId].owner, "Not Owner.");
        _;
    }

    modifier saleIsActive(uint256 saleId) {
        require(nftsForSale[saleId].active == true, "Sale not active.");
        _;
    }

    modifier saleIsNotCanceled(uint256 saleId) {
        require(
            nftsForSale[saleId].canceled == false,
            "Sale has been canceled."
        );
        _;
    }

    modifier saleExists(uint256 saleId) {
        require(nftsForSale[saleId].created == true, "Sale ID not valid.");
        _;
    }

    modifier saleIsNotCompleted(uint256 saleId) {
        require(nftsForSale[saleId].completed == false, "Sale has concluded.");
        _;
    }

    modifier onlyOfferOwner(uint256 offerId) {
        require(msg.sender == nftsOffer[offerId].owner, "Not Offer Owner.");
        _;
    }

    modifier offerIsActive(uint256 offerId) {
        require(nftsOffer[offerId].active == true, "Offer not active.");
        _;
    }

    modifier offerIsNotCanceled(uint256 offerId) {
        require(
            nftsOffer[offerId].canceled == false,
            "Offer has been canceled."
        );
        _;
    }

    modifier offerExists(uint256 offerId) {
        require(nftsOffer[offerId].created == true, "Offer ID not valid.");
        _;
    }

    modifier offerIsNotCompleted(uint256 offerId) {
        require(nftsOffer[offerId].completed == false, "Offer has settled.");
        _;
    }

    // Collection Offer modifiers
    modifier onlyCollectionOfferOwner(uint256 offerId) {
        require(
            msg.sender == collectionOffers[offerId].owner,
            "Not Collection Offer Owner."
        );
        _;
    }

    modifier collectionOfferIsActive(uint256 offerId) {
        require(
            collectionOffers[offerId].active == true,
            "Collection Offer not active."
        );
        _;
    }

    modifier collectionOfferIsNotCanceled(uint256 offerId) {
        require(
            collectionOffers[offerId].canceled == false,
            "Collection Offer has been canceled."
        );
        _;
    }

    modifier collectionOfferExists(uint256 offerId) {
        require(
            collectionOffers[offerId].created == true,
            "Collection Offer ID not valid."
        );
        _;
    }

    modifier collectionOfferIsNotCompleted(uint256 offerId) {
        require(
            collectionOffers[offerId].completed == false,
            "Collection Offer has settled."
        );
        _;
    }

    // Auction modifiers
    modifier onlyAuctionOwner(uint256 auctionId) {
        require(
            msg.sender == nftsForAuction[auctionId].owner,
            "Not Aution Owner."
        );
        _;
    }

    modifier auctionIsActive(uint256 auctionId) {
        require(
            nftsForAuction[auctionId].active == true,
            "Auction not active."
        );
        _;
    }

    modifier auctionIsNotCanceled(uint256 auctionId) {
        require(
            nftsForAuction[auctionId].canceled == false,
            "Auction has been canceled."
        );
        _;
    }

    modifier auctionExists(uint256 auctionId) {
        require(
            nftsForAuction[auctionId].created == true,
            "Auction ID not valid."
        );
        _;
    }

    modifier auctionIsNotCompleted(uint256 auctionId) {
        require(
            nftsForAuction[auctionId].completed == false,
            "Auction has settled."
        );
        _;
    }
}