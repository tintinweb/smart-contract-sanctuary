//// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.7.0 < 0.9.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Marketplace {
    
    struct Trade {
        address poster;
        uint256 tokenId;
        IERC721 tokenContract;
        uint256 price;
        bytes32 status; // Open, Executed, Cancelled
    }
    struct Auction {
        address poster;
        uint256 tokenId;
        IERC721 tokenContract;
        uint256 price;
        bytes32 status;
        uint256 offerCount;
    }
    struct Offer {
        address poster;
        uint256 price;
        bytes32 status;
    }

    uint public tradeCounter;
    uint public auctionCounter;
    mapping(uint256 => Trade) public trades;
    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => Offer[]) public Offers;
    
    
    
    constructor () {
        tradeCounter = 0;
    }

    function openTrade(address _tokenAddress, uint256 _tokenId, uint256 _price, bool _auction) public {

        IERC721(_tokenAddress).transferFrom(msg.sender, address(this), _tokenId);
        trades[tradeCounter] = Trade({
            poster: msg.sender,
            tokenId: _tokenId,
            tokenContract: IERC721(_tokenAddress),
            price: _price,
            status: "Open"
        });

        tradeCounter++;
    }
    
    function openAuction(address _tokenAddress, uint256 _tokenId, uint256 _price, bool _auction) public {

        IERC721(_tokenAddress).transferFrom(msg.sender, address(this), _tokenId);
        auctions[auctionCounter] = Auction({
            poster: msg.sender,
            tokenId: _tokenId,
            tokenContract: IERC721(_tokenAddress),
            price: _price,
            status: "Open",
            offerCount: 0
        });

        auctionCounter++;
    }

    function executeTrade(uint256 _trade) public payable tradeExists(_trade) {
        
        Trade memory trade = trades[_trade];
        require(trade.status == "Open", "Trade is not Open.");
        require(msg.value >= trade.price, "Did not pay enough.");
        payable(trade.poster).call{value: trade.price}("");
        trade.tokenContract.transferFrom(address(this), msg.sender, trade.tokenId);
        trades[_trade].status = "Executed";
        
        //emit TradeStatusChange(_trade, "Executed");
    }
    
    function makeOffer(uint256 _auction, uint256 _price) public payable auctionExists(_auction){
        Offer memory _offer = Offer({
            poster: msg.sender,
            price: _price,
            status: "Open"
        });
        Auction memory auction = auctions[_auction];
        require(auction.status == "Open", "Auction is not Open.");
        require(msg.value>=_offer.price, "not enough Ether");
        payable(address(this)).call{value: _offer.price}("");
        Offers[_auction][auction.offerCount] = _offer;
        auctions[_auction].offerCount++;
    }
    
    function acceptOffer(uint256 _auction, uint256 _offer) public payable auctionExists(_auction){
        Auction memory auction = auctions[_auction];
        Offer memory offer = Offers[_auction][_offer];
        require(msg.sender == auctions[_auction].poster, "You cant accept an offer, for an auction you dont host");
        require(offer.status =="Open", "Offer must be open");
        payable(auction.poster).call{value: offer.price}("");
        auction.tokenContract.transferFrom(address(this), offer.poster, auction.tokenId);
        Offers[_auction][_offer].status="Executed";
        for(uint i = 0; i<auction.offerCount;i++){
            if(Offers[_auction][i].status=="Open"){
                cancelOffer(_auction,i);
            }
        }
        auctions[_auction].status = "Executed";
    }
    
    function cancelOffer(uint256 _auction, uint256 _offer) public payable auctionExists(_auction){
        Offer memory offer = Offers[_auction][_offer];
        require(msg.sender==offer.poster," Offer can only be cancelled by poster");
        require(offer.status == "Open", "Offer is not Open");
        payable(offer.poster).call{value: offer.price}("");
        Offers[_auction][_offer].status="Cancelled";
    }
    
    function cancelAuction(uint256 _auction) public payable auctionExists(_auction){
        Auction memory auction = auctions[_auction];
        require(msg.sender == auction.poster, "Auction can be cancelled only by poster.");
        require(auction.status == "Open", "Auction is not Open.");
        auction.tokenContract.transferFrom(address(this), auction.poster,auction.tokenId);
        auctions[_auction].status="Cancelled";
        for(uint i = 0; i<auction.offerCount;i++){
            if(Offers[_auction][i].status=="Open"){
                cancelOffer(_auction,i);
            }
        }
    }
    
    function cancelTrade(uint256 _trade) public  tradeExists(_trade) {

        Trade memory trade = trades[_trade];
        require(msg.sender == trade.poster, "Trade can be cancelled only by poster.");
        require(trade.status == "Open", "Trade is not Open.");
        trade.tokenContract.transferFrom(address(this), trade.poster, trade.tokenId);
        trades[_trade].status = "Cancelled";
        //emit TradeStatusChange(_trade, "Cancelled");

    }
    
     
    
    //----------------------------------------------------------------------------------
    // modifiers
    
    modifier tradeExists(uint256 _trade) {
        require(_trade < tradeCounter, "trade does not exist");
        _;
    }
    modifier auctionExists(uint256 _auction) {
        require(_auction < auctionCounter, "auction does not exist");
        _;
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