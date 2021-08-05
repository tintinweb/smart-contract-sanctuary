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

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC721LOWB is IERC721 {

    function holderOf(uint256 tokenId) external view returns (address holder);
    
    function owner() external view returns (address _owner);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWallet {

    function balanceOf(address user) external view returns (uint balance);
    function award(address user, uint amount) external;
    function use(address user, uint amount) external;

}

// contracts/LowbMarket.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721LOWB.sol";
import "./IWallet.sol";

contract LowbMarket {

    address public walletAddress;
    //address public lowbTokenAddress;

    address public owner;

    /* Inverse basis point. */
    uint public constant INVERSE_BASIS_POINT = 10000;
    uint public fee;
    
    struct Offer {
        bool isForSale;
        uint itemId;
        address seller;
        uint minValue;          // in lowb
        address onlySellTo;     // specify to sell only to a specific person
    }
    
    struct Bid {
        address prevBidder;
        address nextBidder;
        uint value;
    }
    
    //mapping (address => uint) public pendingWithdrawals;
    mapping (address => uint) public royaltyOf;
    mapping (address => mapping (uint => Offer)) public itemsOfferedForSale;
    mapping (address => mapping (uint => mapping (address => Bid))) public itemBids;
    
    event ItemNoLongerForSale(address indexed nftAddress, uint indexed itemId);
    event ItemOffered(address indexed nftAddress, uint indexed itemId, uint minValue);
    event ItemBought(address indexed nftAddress, uint indexed itemId, uint value, address fromAddress, address toAddress);
    event NewBidEntered(address indexed nftAddress, uint indexed itemId, uint value, address indexed fromAddress);
    event BidWithdrawn(address indexed nftAddress, uint indexed itemId, uint value, address indexed fromAddress);


    constructor(address wallet_) {
        walletAddress = wallet_;
        owner = msg.sender;
        fee = 250;
    }
    
    function offerItemForSale(address nftAddress, uint itemId, uint minSalePriceInWei) public {
        IERC721LOWB token = IERC721LOWB(nftAddress);
        require(token.ownerOf(itemId) == msg.sender && token.holderOf(itemId) == msg.sender, "You don't own this token.");
        require(token.getApproved(itemId) == address(this), "Approve this token first.");

        itemsOfferedForSale[nftAddress][itemId] = Offer(true, itemId, msg.sender, minSalePriceInWei, address(0));
        emit ItemOffered(nftAddress, itemId, minSalePriceInWei);
    }
    
    function itemNoLongerForSale(address nftAddress, uint itemId) public {
        IERC721LOWB token = IERC721LOWB(nftAddress);
        require(token.ownerOf(itemId) == msg.sender, "You don't own this token.");

        itemsOfferedForSale[nftAddress][itemId] = Offer(false, itemId, msg.sender, 0, address(0));
        emit ItemNoLongerForSale(nftAddress, itemId);
    }
    
    function _makeDeal(address seller, uint amount, address nftAddress) private {
        IERC721LOWB nft = IERC721LOWB(nftAddress);
        uint royalty = royaltyOf[nftAddress];
        uint fee_amount = amount / INVERSE_BASIS_POINT * fee;
        uint royalty_amount = amount / INVERSE_BASIS_POINT * royalty;
        uint actual_amount = amount - fee_amount - royalty_amount;
        address creator = nft.owner();
        require(actual_amount > 0, "Fees should less than the transaction value.");
        
        IWallet wallet = IWallet(walletAddress);
        wallet.award(creator, royalty_amount);
        wallet.award(owner, fee_amount);
        wallet.award(seller, actual_amount);
    }
    
    function buyItem(address nftAddress, uint itemId, uint amount) public {
        Offer memory offer = itemsOfferedForSale[nftAddress][itemId];
        require(offer.isForSale, "This item not actually for sale.");
        require(amount >= offer.minValue, "You didn't send enough LOWB.");
        
        IWallet wallet = IWallet(walletAddress);
        require(wallet.balanceOf(msg.sender) >= amount, "Please deposit enough lowb to buy this item!");
        
        wallet.use(msg.sender, amount);

        IERC721LOWB nft = IERC721LOWB(nftAddress);
        address seller = offer.seller;
        require(nft.ownerOf(itemId) == seller && nft.holderOf(itemId) == seller, "Seller no longer owner of this item.");
        
        nft.safeTransferFrom(seller, msg.sender, itemId);

        itemNoLongerForSale(nftAddress, itemId);

        _makeDeal(seller, amount, nftAddress);
        emit ItemBought(nftAddress, itemId, amount, seller, msg.sender);
    }
    
    function enterBid(address nftAddress, uint itemId, uint amount) public {
        IWallet wallet = IWallet(walletAddress);
        require(wallet.balanceOf(msg.sender) >= amount, "Please deposit enough lowb before bid!");
        require(amount > 0, "Please bid with some lowb!");

        IERC721LOWB nft = IERC721LOWB(nftAddress);
        require(nft.ownerOf(itemId) != address(0), "Token not created yet.");

        require(itemBids[nftAddress][itemId][msg.sender].value == 0, "You've already entered a bid!");

        // Lock the current bid
        wallet.use(msg.sender, amount);
        address latestBidder = itemBids[nftAddress][itemId][address(0)].nextBidder;
        itemBids[nftAddress][itemId][latestBidder].prevBidder = msg.sender;
        itemBids[nftAddress][itemId][msg.sender] = Bid(address(0), latestBidder, amount);
        itemBids[nftAddress][itemId][address(0)].nextBidder = msg.sender;

        emit NewBidEntered(nftAddress, itemId, amount, msg.sender);
    }
    
    function acceptBid(address nftAddress, uint itemId, address bidder) public {
        IERC721LOWB token = IERC721LOWB(nftAddress);
        require(token.ownerOf(itemId) == msg.sender && token.holderOf(itemId) == msg.sender, "You don't own this token.");
        require(token.getApproved(itemId) == address(this), "Approve this token first.");
        
        address seller = msg.sender;
        uint amount = itemBids[nftAddress][itemId][bidder].value;
        require(amount > 0, "No bid from this address for this item yet.");

        token.safeTransferFrom(seller, bidder, itemId);
        itemsOfferedForSale[nftAddress][itemId] = Offer(false, itemId, bidder, 0, address(0));

        itemBids[nftAddress][itemId][bidder].value = 0;
        address nextBidder = itemBids[nftAddress][itemId][bidder].nextBidder;
        address prevBidder = itemBids[nftAddress][itemId][bidder].prevBidder;
        itemBids[nftAddress][itemId][prevBidder].nextBidder = nextBidder;
        itemBids[nftAddress][itemId][nextBidder].prevBidder = prevBidder;
        
        _makeDeal(seller, amount, nftAddress);
        
        emit ItemBought(nftAddress, itemId, amount, seller, bidder);
    }
    
    function withdrawBid(address nftAddress, uint itemId) public {
        uint amount = itemBids[nftAddress][itemId][msg.sender].value;
        require(amount > 0, "You don't have a bid for it.");
        
        itemBids[nftAddress][itemId][msg.sender].value = 0;
        address nextBidder = itemBids[nftAddress][itemId][msg.sender].nextBidder;
        address prevBidder = itemBids[nftAddress][itemId][msg.sender].prevBidder;
        itemBids[nftAddress][itemId][prevBidder].nextBidder = nextBidder;
        itemBids[nftAddress][itemId][nextBidder].prevBidder = prevBidder;
        // Refund the bid money
        IWallet wallet = IWallet(walletAddress);
        wallet.award(msg.sender, amount);
        
        emit BidWithdrawn(nftAddress, itemId, amount, msg.sender);
    }

    
    function setRoyalty(address nftAddress, uint royalty) public {
        IERC721LOWB nft = IERC721LOWB(nftAddress);
        require(msg.sender == nft.owner(), "Only owner can set the royalty!");
        require(royalty <= 1000, "Royalty too high!");
        royaltyOf[nftAddress] = royalty;
    }
    
    function getOffers(address nftAddress, uint from, uint to) public view returns (Offer[] memory) {
        require(to >= from, "Invalid index");
        IERC721LOWB token = IERC721LOWB(nftAddress);
        Offer[] memory offers = new Offer[](to-from+1);
        for (uint i=from; i<=to; i++) {
            offers[i-from] = itemsOfferedForSale[nftAddress][i];
            if (token.ownerOf(i) != offers[i-from].seller || token.holderOf(i) != offers[i-from].seller) {
              offers[i-from].isForSale = false;
            }
        }
        return offers;
    }
    
    function getBidsOf(address nftAddress, address user, uint from, uint to) public view returns (Bid[] memory) {
        require(to >= from, "Invalid index");
        Bid[] memory bids = new Bid[](to-from+1);
        for (uint i=from; i<=to; i++) {
            bids[i-from] = itemBids[nftAddress][i][user];
        }
        return bids;
    }
    
    function getHighestBids(address nftAddress, uint from, uint to) public view returns (Bid[] memory) {
        require(to >= from, "Invalid index");

        Bid[] memory bids = new Bid[](to-from+1);
        LowbMarket.Bid memory bid;
        for (uint i=from; i<=to; i++) {
            bid = itemBids[nftAddress][i][address(0)];
            while (bid.nextBidder != address(0)) {
                bid = itemBids[nftAddress][i][bid.nextBidder];
                if (bid.value >= bids[i-from].value) {
                    bids[i-from] = bid;
                }
            }
        }
        return bids;
    }

}