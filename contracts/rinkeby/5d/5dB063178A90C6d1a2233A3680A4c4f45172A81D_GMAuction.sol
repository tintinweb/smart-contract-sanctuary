/**
 *Submitted for verification at Etherscan.io on 2021-06-18
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;



// Part: OpenZeppelin/[email protected]/Context

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// Part: OpenZeppelin/[email protected]/IERC165

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

// Part: OpenZeppelin/[email protected]/IERC20

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

// Part: OpenZeppelin/[email protected]/IERC721

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

// Part: OpenZeppelin/[email protected]/Ownable

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

// File: GMAuction.sol

/**
    @title Auction for GreatMasters NFTs
    @author Gene A. Tsvigun
  */
contract GMAuction is Ownable {
    event Bid(uint256 artId, uint256 price, address bidder, uint256 minNextBid);
    event AuctionScheduled(uint256 artId, address beneficiary, uint256 startPrice);
    event AuctionStart(uint256 artId, uint256 startPrice, uint256 startTime, uint256 endTime);
    event AuctionEndTimeChanged(uint256 artId, uint256 endTime);
    event AuctionComplete(uint256 artId, uint256 price, address winner, uint256 endTime);

    uint256 constant DEFAULT_DURATION = 1 days; //TODO make it 7 days for prod
    uint256 constant MAX_START_PRICE = 1000 * 10 ** 6; //USDT has 6 decimals
    uint256 constant BID_STEP_PERCENT_MULTIPLIER = 110;

    IERC721 public nft;
    IERC20 public stablecoin;
    address public minter;

    struct Auction {
        address beneficiary;
        uint256 startTime;
        uint256 endTime;
        uint256 startPrice;
        address highestBidder;
        uint256 highestBid;
    }

    mapping(uint256 => Auction) public auctions;

    /**
        @notice Same instance for multiple auctions within the same NFT contract using the same stablecoin
        @param nft_ nft contract defining items traded
        @param stablecoin_ address of an ERC20-compliant stablecoin to be used in the auction, BUSD, USDT etc.
      */
    constructor(
        IERC721 nft_,
        IERC20 stablecoin_
    ){
        nft = nft_;
        stablecoin = stablecoin_;
        minter = msg.sender;
    }

    /**
        @notice schedule an auction by grabbing the NFT
        @param artId_ ID of the item sold
        @param startPrice_ starting/reserve price
    */
    function scheduleAuction(
        uint256 artId_,
        uint256 startPrice_
    ) public whenNotScheduled(artId_) {
        checkAuctionParams(
            artId_,
            startPrice_
        );
        address beneficiary = nft.ownerOf(artId_);
        auctions[artId_] = Auction(
            nft.ownerOf(artId_),
            0,
            0,
            startPrice_,
            address(0),
            0
        );
        nft.transferFrom(beneficiary, address(this), artId_);
        logAuctionScheduled(artId_, auctions[artId_]);
    }

    /**
        @notice schedule an auction by grabbing the NFT
        @param artId_ ID of the item sold
        @param startPrice_ starting/reserve price
    */
    function scheduleInitialAuction(
        address beneficiary_,
        uint256 artId_,
        uint256 startPrice_
    ) public whenNotScheduled(artId_) onlyMinter {
        checkAuctionParams(
            artId_,
            startPrice_
        );
        auctions[artId_] = Auction(
            beneficiary_,
            0,
            0,
            startPrice_,
            address(0),
            0
        );
        require(nft.ownerOf(artId_) == address(this));
        logAuctionScheduled(artId_, auctions[artId_]);
    }

    function checkAuctionParams(
        uint256 artId_,
        uint256 startPrice_
    ) private {
        require(nft.ownerOf(artId_) != address(0), "GMAuction constructor: the token must exist");
        require(startPrice_ <= MAX_START_PRICE, "GMAuction constructor: start price too high");
    }

    function logAuctionScheduled(uint256 artId, Auction storage a) private {
        emit AuctionScheduled(artId, a.beneficiary, a.startPrice);
    }

    /**
        @notice mark the start of an auction
        @param artId ID of the item sold
    */
    function startAuction(uint256 artId) private {
        if (!started(artId)) {
            auctions[artId].startTime = block.timestamp;
            auctions[artId].endTime = block.timestamp + DEFAULT_DURATION;
            emit AuctionStart(artId, auctions[artId].startPrice, auctions[artId].startTime, auctions[artId].endTime);
        }
    }

    /**
        @notice Bid on the auction, stablecoin contract approval required, the value refunded on overbid
        @param amount bid amount - has to be higher than the current highest bid plus bid step
      */
    function bid(uint256 artId, uint256 amount) public onlyTrader whenActive(artId) {
        startAuction(artId);
        Auction storage a = auctions[artId];
        require(amount >= minimumBid(artId), "GMAuction: bid amount must >= 110% of the current hightest bid");
        require(a.highestBidder != msg.sender, "GMAuction: you're the highest bidder already");
        stablecoin.transferFrom(msg.sender, address(this), amount);
        _refundBid(artId);
        a.highestBidder = msg.sender;
        a.highestBid = amount;
        //TODO check and update end time
        emit Bid(artId, a.highestBid, msg.sender, minimumBid(artId));
    }

    /**
        @notice End the auction, send the highest bid to the beneficiary, send NFT to the highest bidder.
        @dev Process auction completion by sending NFT to the highest bidder and stablecoin to its beneficiary
        @param artId ID of the item sold
      */
    function completeAuction(uint256 artId) public whenEnded(artId) {
        Auction storage a = auctions[artId];

        address highestBidder = auctions[artId].highestBidder;
        uint256 highestBid = auctions[artId].highestBid;
        //TODO consider safeTransferFrom
        nft.transferFrom(address(this), highestBidder, artId);
        stablecoin.transfer(auctions[artId].beneficiary, highestBid);
        emit AuctionComplete(artId, highestBid, highestBidder, auctions[artId].endTime);

        markNotScheduled(artId);
    }

    function _refundBid(uint256 artId) private {
        address highestBidder = auctions[artId].highestBidder;
        if (highestBidder != address(0))
            stablecoin.transfer(highestBidder, auctions[artId].highestBid);
    }

    function setMinter(address minter_) public onlyOwner {
        minter = minter_;
    }


    modifier onlyTrader {
        _;
        //TODO implement Trader status check, secondary sales only
    }

    modifier onlyMinter {
        require(msg.sender == minter, "GMAuction: action is allowed only to the minter");
        _;
    }

    modifier whenEnded(uint256 artId) {
        require(started(artId), "GMAuction: action is allowed only for auction that actually happened");
        require(auctions[artId].endTime <= block.timestamp, "GMAuction: action is allowed after the auction end time");
        _;
    }

    modifier whenActive(uint256 artId) {
        require(isActive(artId), "GMAuction: action is allowed when the auction for the item is active");
        _;
    }

    modifier whenNotActive(uint256 artId) {
        require(!isActive(artId), "GMAuction: action is allowed when there is no active auction for the item");
        _;
    }

    modifier whenNotScheduled(uint256 artId) {
        require(!isScheduled(artId), "GMAuction: action is allowed when there is no scheduled auction for the item");
        _;
    }

    /**
        @return Whether the auction is active or not
    */
    function isActive(uint256 artId) public view returns (bool){
        //        return startTime < block.timestamp && endTime > block.timestamp;
        uint256 startTime = auctions[artId].startTime;
        return startTime > 0 && startTime < block.timestamp && auctions[artId].endTime > block.timestamp;
    }

    function isScheduled(uint256 artId) public view returns (bool){
        return auctions[artId].startPrice != 0;
    }

    function started(uint256 artId) public view returns (bool) {
        return auctions[artId].highestBid != 0;
    }

    function minimumBid(uint256 artId) public view returns (uint256){
        return auctions[artId].highestBid * BID_STEP_PERCENT_MULTIPLIER / 100;
    }

    function markNotScheduled(uint256 artId) private {
        auctions[artId].startPrice = 0;
    }
}