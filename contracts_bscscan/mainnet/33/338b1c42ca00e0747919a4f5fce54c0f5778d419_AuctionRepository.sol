/**
 *Submitted for verification at BscScan.com on 2021-10-21
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface INftToken {
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
    
    function lockNFT(uint id, bool locked) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

contract AuctionRepository is Ownable, IERC721Receiver {

    address public immutable NFT;
    mapping(uint => Auction) public auctions;
    
    uint public MIN_DURATION = 1 hours;
    // uint public MIN_DURATION = 30 minutes;

    constructor(address _nft) {
        NFT = _nft;
    }

    struct Bid {
        address from;
        uint price;
        uint time;
    }

    struct Auction {
        address owner;
        uint minPrice;
        uint duration;
        uint startAt;
        uint lastPrice;
        Bid[] bids;
    }

    modifier ownerOf(uint _auctionId) {
        require(msg.sender == _getAuctionOwner(_auctionId));
        _;
    }

    event AuctionCreated(address owner, uint tokenId, uint minPrice, uint duration);
    event AuctionFailed(address owner, uint tokenId);
    event AuctionSuccess(address owner, uint tokenId, uint price);
    event BidPlaced(address from, uint tokenId, uint bidPrice);
    event NFTReceived(address operator, address from, uint256 tokenId, bytes data);

    modifier isAuction(uint _tokenId) {
        require (_isAuction(_tokenId));
        _;
    }
    
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) public override returns (bytes4) {
        emit NFTReceived(operator, from, tokenId, data);
        return this.onERC721Received.selector;
    }
    
    function onSelector() public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function _isAuction(uint _id) view internal returns(bool) {
        return auctions[_id].owner != address(0);
    }

    function _getAuctionOwner(uint _id) view internal returns(address) {
        return auctions[_id].owner;
    }

    function bid(uint _tokenId) payable external isAuction(_tokenId) {
        uint ethSent = msg.value;
        require (block.timestamp <= auctions[_tokenId].startAt + auctions[_tokenId].duration, "Auction has ended already");
        require (auctions[_tokenId].owner != msg.sender, "You cannot bid on your own auction");
        require (auctions[_tokenId].lastPrice < ethSent && ethSent >= auctions[_tokenId].minPrice);

        uint numBids = auctions[_tokenId].bids.length;

        if (numBids > 0) {
            address payable lastBidder = payable(auctions[_tokenId].bids[numBids - 1].from);
            lastBidder.transfer(auctions[_tokenId].lastPrice);
        }

        auctions[_tokenId].lastPrice = ethSent;
        auctions[_tokenId].bids.push(Bid(msg.sender, ethSent, block.timestamp));

        emit BidPlaced(msg.sender, _tokenId, ethSent);
    }

    function finalizeAuction(uint _tokenId) external isAuction(_tokenId) {
        require (auctions[_tokenId].startAt + auctions[_tokenId].duration < block.timestamp, "The auction is still active");

        Auction memory auction = auctions[_tokenId];

        if (auction.bids.length > 0) {
            address payable winner = payable(auction.bids[auction.bids.length - 1].from);
            payable(auction.owner).transfer(auction.lastPrice);

            INftToken(NFT).lockNFT(_tokenId, false);
            INftToken(NFT).transferFrom(address(this), winner, _tokenId);
            
            emit AuctionSuccess(msg.sender, _tokenId, auction.lastPrice);
        } else {
            INftToken(NFT).lockNFT(_tokenId, false);
            INftToken(NFT).transferFrom(address(this), auction.owner, _tokenId);
            
            emit AuctionFailed(msg.sender, _tokenId);
        }

        delete auctions[_tokenId];
    }

    function createAuction(uint _tokenId, uint _minPrice, uint _duration) external {
        require (!_isAuction(_tokenId), "The token is already in auction");
        require (msg.sender == INftToken(NFT).ownerOf(_tokenId), "You must be owner of the token");
        require (_minPrice > 0, "Invalid price values");
        require (_duration >= MIN_DURATION, "The duration is too short");

        Auction storage a; //= Auction(_tokenId, _minPrice, _duration, block.timestamp, 0, []);
        a.owner = msg.sender;
        a.minPrice = _minPrice;
        a.duration = _duration;
        a.startAt = block.timestamp;
        a.lastPrice = 0;
        
        auctions[_tokenId] = a;

        INftToken(NFT).transferFrom(msg.sender, address(this), _tokenId);
        INftToken(NFT).lockNFT(_tokenId, true);

        emit AuctionCreated(msg.sender, _tokenId, _minPrice, _duration);
    }

    function cancelAuction(uint _tokenId) external isAuction(_tokenId) {
        require (auctions[_tokenId].startAt + auctions[_tokenId].duration < block.timestamp, "The auction is still active");
        require (msg.sender == auctions[_tokenId].owner, "You must be the auction owner");
        require (auctions[_tokenId].bids.length == 0, "There's a bid and you cannot cancel the ");

        Auction memory auction = auctions[_tokenId];

        INftToken(NFT).lockNFT(_tokenId, false);
        INftToken(NFT).transferFrom(address(this), auction.owner, _tokenId);
        delete auctions[_tokenId];

        // emit AuctionCancelled(auction.owner, _tokenId);
    }
}