//SourceUnit: TechNecksMarket.sol

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
        return c;
    }
}

pragma solidity >=0.6.0 <0.8.0;

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


pragma solidity >=0.6.2 <0.8.0;


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
     * - If `to` refers to a smart contract, it must implement {TRC721TokenReceiver-onTRC721Received}, which is called upon a safe transfer.
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
      * - If `to` refers to a smart contract, it must implement {TRC721TokenReceiver-onTRC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface TRC721TokenReceiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onTRC721Received.selector`.
     */
    function onTRC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

contract TechNecksMarket is TRC721TokenReceiver {
    struct Offer {
        bool isForSale;
        uint tokenId;
        address seller;
        uint value; // in trx
        address onlySellTo; // specify to sell only to a specific person
    }

    struct Bid {
        bool hasBid;
        uint tokenId;
        address bidder;
        uint value;
    }

    uint public dexFeePercent = 2;
    uint public minimumMarketPrice = 2000000000; // 2000 trx
    bool public marketPaused = true;

    address payable internal deployer;
    address payable internal feeReceiver;

    IERC721 private tnContract;

    // A record of items that are offered for sale at a specific minimum value, and perhaps to a specific person
    mapping (uint => Offer) public itemsForSale;

    // A record of the bids
    mapping (uint => Bid) public itemBids;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event OfferedForSale(uint indexed tokenId, uint value, address indexed from, address indexed to);
    event BidEntered(uint indexed tokenId, uint value, address indexed from);
    event BidWithdrawn(uint indexed tokenId, uint value, address indexed from);
    event ItemPurchased(uint indexed tokenId, uint value, address indexed from, address indexed to);
    event NoLongerForSale(uint indexed tokenId);
    event TRC721Received(address operator, address _from, uint256 tokenId);

    modifier onlyDeployer() {
        require(msg.sender == deployer, "Only deployer.");
        _;
    }

    bool private reentrancyLock = false;

    // Prevent a contract function from being reentrant-called.
    modifier reentrancyGuard {
        if (reentrancyLock) {
            revert("reentrancyLocked");
        }
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

    constructor(address _tnContract, address payable _feeReceiver) {
        deployer = msg.sender;
        tnContract = IERC721(_tnContract);
        feeReceiver = _feeReceiver;
    }

    function pauseMarket(bool _paused) external onlyDeployer {
        marketPaused = _paused;
    }

    function setFeeReceiver(address payable _feeReceiver) external onlyDeployer {
        feeReceiver = _feeReceiver;
    }

    function setMinimumMarketPrice(uint newPrice) external onlyDeployer {
        require(newPrice > 0, "Price must be greater than zero");
        minimumMarketPrice = newPrice;
    }

    function setMarketFee(uint newFee) external onlyDeployer {
        require(newFee > 0, "Price must be greater than zero");
        dexFeePercent = newFee;
    }

    function withdraw() external onlyDeployer {
        uint balance = address(this).balance;
        feeReceiver.transfer(balance);
    }

    function offerItemForSale(uint tokenId, uint minSalePriceInTrx) public reentrancyGuard {
        require(marketPaused == false, 'Market Paused');
        require(tnContract.ownerOf(tokenId) == msg.sender, 'Only owner');
        require(minSalePriceInTrx >= minimumMarketPrice, 'Minimum price not met');
        require((tnContract.getApproved(tokenId) == address(this) || tnContract.isApprovedForAll(msg.sender, address(this))), 'Not Approved');
        // don't send item to dex
        // tnContract.safeTransferFrom(msg.sender, address(this), tokenId);
        itemsForSale[tokenId] = Offer(true, tokenId, msg.sender, minSalePriceInTrx, address(0));
        emit OfferedForSale(tokenId, minSalePriceInTrx, msg.sender, address(0));
    }

    function offerItemForSaleToAddress(uint tokenId, uint minSalePriceInTrx, address toAddress) public reentrancyGuard {
        require(marketPaused == false, 'Market Paused');
        require(tnContract.ownerOf(tokenId) == msg.sender, 'Only owner');
        require((tnContract.getApproved(tokenId) == address(this) || tnContract.isApprovedForAll(msg.sender, address(this))), 'Not Approved');
        // don't send item to dex
        // tnContract.safeTransferFrom(msg.sender, address(this), tokenId);
        itemsForSale[tokenId] = Offer(true, tokenId, msg.sender, minSalePriceInTrx, toAddress);
        emit OfferedForSale(tokenId, minSalePriceInTrx, msg.sender, toAddress);
    }

    function buyItem(uint tokenId) public payable reentrancyGuard {
        require(marketPaused == false, 'Market Paused');

        Offer memory offer = itemsForSale[tokenId];
        require(offer.isForSale == true, 'Item is not for sale');

        if (offer.onlySellTo != address(0) && offer.onlySellTo != msg.sender){
            revert("Not eligible to buy this item");
        }

        require(msg.sender != offer.seller, 'You can not buy your item');
        require(msg.value >= offer.value, "Didn't send enough TRX");
        // require(address(this) == tnContract.ownerOf(tokenId), 'Seller no longer owner of item');
        require(offer.seller == tnContract.ownerOf(tokenId), 'Seller no longer owner of item');

        address seller = offer.seller;
        // tnContract.safeTransferFrom(address(this), msg.sender, tokenId);
        // no longer transfering from dex, transfer directly from seller
        tnContract.safeTransferFrom(seller, msg.sender, tokenId);
        emit Transfer(seller, msg.sender, 1);
        itemsForSale[tokenId] = Offer(false, tokenId, msg.sender, 0, address(0));
        // don't emit when item sells
        // emit NoLongerForSale(tokenId);
        // Transfer TRX to seller and fee
        uint fee = msg.value * dexFeePercent / 100;
        uint sellerAmount = msg.value - fee;
        (bool success, ) = address(uint160(seller)).call{value: sellerAmount}("");
        require(success, "Address: unable to send value, recipient may have reverted");

        feeReceiver.transfer(fee);
        emit ItemPurchased(tokenId, msg.value, seller, msg.sender);
        Bid memory bid = itemBids[tokenId];
        // refund bids if exists
        if (bid.hasBid) {
            itemBids[tokenId] = Bid(false, tokenId, address(0), 0);
            (bool hasBidSuccess, ) = address(uint160(bid.bidder)).call{value: bid.value}("");
            require(hasBidSuccess, "Address: unable to send value, recipient may have reverted");
        }
    }

    function enterBidForItem(uint tokenId) public payable reentrancyGuard {
        require(marketPaused == false, 'Market Paused');
        // Offer memory offer = itemsForSale[tokenId];
        // require(offer.isForSale == true, 'item is not for sale');
        // item no longer need to be for sale to be bid on

        // require(offer.seller != msg.sender, 'owner can not bid');
        // use ownerOf to check if owner is bidding
        require(tnContract.ownerOf(tokenId) != msg.sender, 'owner can not bid');

        require(msg.value > 0, 'bid can not be zero');
        Bid memory existing = itemBids[tokenId];
        require(msg.value > existing.value, 'you can not bid lower than last bid');
        if (existing.value > 0) {
            // Refund the failing bid
            (bool success, ) = address(uint160(existing.bidder)).call{value: existing.value}("");
            require(success, "Address: unable to send value, recipient may have reverted");
        }
        itemBids[tokenId] = Bid(true, tokenId, msg.sender, msg.value);
        emit BidEntered(tokenId, msg.value, msg.sender);
    }

    function acceptBidForItem(uint tokenId, uint minPrice) public reentrancyGuard {
        Bid memory bid = itemBids[tokenId];

        require(marketPaused == false, 'Market Paused');
        require(tnContract.ownerOf(tokenId) == msg.sender, 'Only owner can accept bid');
        require(bid.value > 0, 'there is not any bid');
        require(bid.value >= minPrice, 'bid is lower than min price');
        require((tnContract.getApproved(tokenId) == address(this) || tnContract.isApprovedForAll(msg.sender, address(this))), 'Cannot accept bid, not Approved');

        // Offer memory offer = itemsForSale[tokenId];
        // address seller = offer.seller;
        address seller = tnContract.ownerOf(tokenId);

        // tnContract.safeTransferFrom(address(this), bid.bidder, tokenId);
        tnContract.safeTransferFrom(seller, bid.bidder, tokenId);

        emit Transfer(seller, bid.bidder, 1);
        // we don't need to mark an item no longer for sale after bid was accepted
        // since item never needed to be for sale for bids
        // itemsForSale[tokenId] = Offer(false, tokenId, bid.bidder, 0, address(0));
        itemBids[tokenId] = Bid(false, tokenId, address(0), 0);

        // Transfer TRX to seller and fee
        uint fee = bid.value * dexFeePercent / 100;
        uint sellerAmount = bid.value - fee;

        // pay seller
        (bool success, ) = address(uint160(seller)).call{value: sellerAmount}("");
        require(success, "Address: unable to send value, recipient may have reverted");

        feeReceiver.transfer(fee);
        emit ItemPurchased(tokenId, bid.value, seller, bid.bidder);
    }

    function withdrawBidForItem(uint tokenId) public reentrancyGuard {
        Bid memory bid = itemBids[tokenId];
        require(bid.hasBid == true, 'There is no bid');
        require(bid.bidder == msg.sender, 'Only bidder can withdraw');
        uint amount = bid.value;
        itemBids[tokenId] = Bid(false, tokenId, address(0), 0);
        // Refund the bid money
        (bool success, ) = address(uint160(msg.sender)).call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
        emit BidWithdrawn(tokenId, bid.value, msg.sender);
    }

    function removeForSale(uint tokenId) public reentrancyGuard {
        Offer memory offer = itemsForSale[tokenId];
        require(offer.isForSale == true, 'item is not for sale');
        address seller = offer.seller;
        require(seller == msg.sender, 'Only Owner');
        // no longer need to transfer from dex
        // tnContract.safeTransferFrom(address(this), msg.sender, tokenId);
        itemsForSale[tokenId] = Offer(false, tokenId, msg.sender, 0, address(0));
        Bid memory bid = itemBids[tokenId];
        if(bid.hasBid){
            itemBids[tokenId] = Bid(false, tokenId, address(0), 0);
            // Refund the bid money
            (bool success, ) = address(uint160(bid.bidder)).call{value: bid.value}("");
            require(success, "Address: unable to send value, recipient may have reverted");
        }
        emit NoLongerForSale(tokenId);
    }

    function onTRC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external override returns(bytes4){
        _data;
        emit TRC721Received(_operator, _from, _tokenId);
        return 0x5175f878;
    }
}