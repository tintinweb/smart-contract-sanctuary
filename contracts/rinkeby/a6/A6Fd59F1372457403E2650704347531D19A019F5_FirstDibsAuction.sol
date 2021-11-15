//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.6.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/payment/PullPayment.sol';
import { ReentrancyGuard } from '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import './IERC721TokenCreator.sol';
import './IFirstDibsMarketSettings.sol';
import './IFirstDibsEscrow.sol';

contract FirstDibsAuction is Ownable, AccessControl, ReentrancyGuard, PullPayment {
    using SafeMath for uint256;

    bytes32 public constant VERIFIED_BIDDER_ROLE = keccak256('VERIFIED_BIDDER_ROLE');
    bool public requireBidderVerification = false; // flag for requiring bidder to have been approved to participate in this auction

    bool public globalPaused; // flag for pausing all auctions

    IERC721TokenCreator public iERC721TokenCreatorRegistry;
    IFirstDibsMarketSettings public iFirstDibsMarketSettings;
    IFirstDibsEscrow public iFirstDibsEscrow;

    /**
     * @dev FirstDibsToken contract address + token ID = mapping from NFT => Auction
     */
    mapping(address => mapping(uint256 => Auction)) public auctions;

    struct Auction {
        address payable payee; // address of auction proceeds recipient. NFT creator until secondary market is introduced.
        address auctionCreator; // address of the creator of the auction (whoever called the createAuction method)
        uint256 reservePrice; // minimum bid threshold for auction to begin
        uint64 startTime; // auction start timestamp
        uint256 currentBid; // current winning bid of the auction
        address payable currentBidder; // current winning bidder of the auction
        bool paused; // is individual auction paused
        uint64 pausedTime; // when was the auction paused
        // market settings
        uint16 timeBuffer; // defaults to globalTimeBuffer
        uint8 minimumBidIncrement; // defaults to globalMinimumBidIncrement
        uint32 duration; // defaults to globalDuration
        uint8 commissionRate; // defaults to globalMarketCommission
        uint8 creatorRoyaltyRate; // defaults to globalCreatorRoyaltyRate
    }

    struct MarketSettings {
        uint16 timeBuffer;
        uint8 minimumBidIncrement;
        uint32 duration;
        uint8 commissionRate;
        uint8 creatorRoyaltyRate;
    }

    modifier notPaused(address nftAddress, uint256 tokenId) {
        require(!globalPaused, 'Auctions are globally paused at the moment.');
        require(!auctions[nftAddress][tokenId].paused, 'Auction is paused.');
        _;
    }
    modifier auctionExists(address nftAddress, uint256 tokenId) {
        require(auctions[nftAddress][tokenId].payee != address(0), "Auction doesn't exist");
        _;
    }
    modifier noAuctionExists(address nftAddress, uint256 tokenId) {
        require(auctions[nftAddress][tokenId].payee == address(0), 'Auction already exists');
        _;
    }
    modifier auctionNotExpired(address nftAddress, uint256 tokenId) {
        require(
            auctions[nftAddress][tokenId].payee != address(0) && // auction must exist
                (auctions[nftAddress][tokenId].startTime == 0 || //  if auction hasn't started yet
                    block.timestamp < _getAuctionEndTime(nftAddress, tokenId)), // if auction hasn't ended yet,
            'Auction expired'
        );
        _;
    }
    modifier auctionComplete(address nftAddress, uint256 tokenId) {
        require(
            auctions[nftAddress][tokenId].startTime > 0 && //  auction has started
                block.timestamp >= _getAuctionEndTime(nftAddress, tokenId), // we are past the endtime of the auction,
            'Auction is not complete'
        );
        _;
    }

    modifier senderIsVerifiedBidder() {
        if (requireBidderVerification) {
            require(
                hasRole(VERIFIED_BIDDER_ROLE, _msgSender()),
                'Message sender must be a verified bidder'
            );
        }
        _;
    }

    modifier senderIsAuctionCreatorOrAdmin(address nftAddress, uint256 tokenId) {
        require(
            _msgSender() == auctions[nftAddress][tokenId].auctionCreator ||
                hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            'Sender must be auction creator or admin'
        );
        _;
    }
    modifier senderIsPayeeOrAdmin(address nftAddress, uint256 tokenId) {
        require(
            _msgSender() == auctions[nftAddress][tokenId].payee ||
                hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            'Sender must be payee or admin'
        );
        _;
    }

    event AuctionCreated(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed tokenSeller,
        address auctionCreator,
        uint256 reservePrice,
        uint32 duration,
        uint8 bidIncrement,
        bool isPaused
    );

    event AuctionBid(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed tokenSeller,
        address bidder,
        uint256 bidAmount,
        uint32 duration,
        uint256 startTime
    );

    event AuctionEnded(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed tokenSeller,
        address winningBidder,
        uint256 winningBid
    );

    event AuctionPaused(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed tokenSeller,
        address toggledBy,
        bool isPaused,
        uint32 duration
    );

    event AuctionCanceled(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed tokenSeller,
        address canceledBy
    );

    constructor(address _iFirstDibsMarketSettings, address _iERC721TokenCreatorRegistry, address _iFirstDibsEscrow) public {
        require(
            _iFirstDibsMarketSettings != address(0),
            'Cannot have null address for _iFirstDibsMarketSettings'
        );
        require(
            _iERC721TokenCreatorRegistry != address(0),
            'Cannot have null address for _iERC721TokenCreatorRegistry'
        );
        require(
            _iFirstDibsEscrow != address(0),
            'Cannot have null address for _iFirstDibsEscrow'
        );
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender()); // deployer of the contract (1stDibs) gets admin permissions
        iERC721TokenCreatorRegistry = IERC721TokenCreator(_iERC721TokenCreatorRegistry);
        iFirstDibsMarketSettings = IFirstDibsMarketSettings(_iFirstDibsMarketSettings);
        iFirstDibsEscrow = IFirstDibsEscrow(_iFirstDibsEscrow);
    }

    /**
     * @dev add an address as a verified bidder on this contract
     * @param account address to add to the verified bidder list
     */
    function setVerifiedBidder(address account) external onlyOwner {
        grantRole(VERIFIED_BIDDER_ROLE, account);
    }

    /**
     * @dev setter for creator registry address
     * @param _iERC721TokenCreatorRegistry address of the IERC721TokenCreator contract to set for the auction
     */
    function setIERC721TokenCreatorRegistry(address _iERC721TokenCreatorRegistry) external onlyOwner {
        require(
            _iERC721TokenCreatorRegistry != address(0),
            'Cannot have null address for _iERC721TokenCreatorRegistry'
        );
        iERC721TokenCreatorRegistry = IERC721TokenCreator(_iERC721TokenCreatorRegistry);
    }
    /**
     * @dev setter for market settings address
     * @param _iFirstDibsMarketSettings address of the FirstDibsMarketSettings contract to set for the auction
     */
     function setIFirstDibsMarketSettings(address _iFirstDibsMarketSettings) external onlyOwner {
         require(
            _iFirstDibsMarketSettings != address(0),
            'Cannot have null address for _iFirstDibsMarketSettings'
        );
        iFirstDibsMarketSettings = IFirstDibsMarketSettings(_iFirstDibsMarketSettings);
     }
     /**
     * @dev setter for market settings address
     * @param _iFirstDibsEscrow address of the FirstDibsMarketSettings contract to set for the auction
     */
     function setIFirstDibsEscrow(address _iFirstDibsEscrow) external onlyOwner {
         require(
            _iFirstDibsEscrow != address(0),
            'Cannot have null address for _iFirstDibsEscrow'
        );
        iFirstDibsEscrow = IFirstDibsEscrow(_iFirstDibsEscrow);
     }

    /**
     * @dev toggle whether or not one must be a verified bidder to participate in an auction
     * @param bidderVerificationRequired bool which is true if you want to require bidder verification, false if not
     */
    function toggleBidderVerificationRequired(bool bidderVerificationRequired) external onlyOwner {
        requireBidderVerification = bidderVerificationRequired;
    }

    /**
     * @dev setter for global pause state
     * @param isPaused true to pause all auctions, false to unpause all auctions
     */
    function setGlobalPaused(bool isPaused) external onlyOwner {
        globalPaused = isPaused;
    }

    /**
     * @dev overload method for calling createAuction without commissionRate and creatorRoyaltyRate args
     */
    function createAuction(
        address nftAddress,
        uint256 tokenId,
        uint256 reservePrice,
        uint32 auctionDurationArg,
        uint8 minimumBidIncrementArg,
        bool pausedArg
    ) external noAuctionExists(nftAddress, tokenId) {
        createAuction(
            nftAddress,
            tokenId,
            reservePrice,
            auctionDurationArg,
            minimumBidIncrementArg,
            pausedArg,
            101, // base method throws out values > 100
            101
        );
    }

    /**
     * @dev external function which creates an auction with a reserve price
     * @param nftAddress address of ERC-721 contract (latest FirstDibsToken address)
     * @param tokenId uint256
     * @param reservePrice reserve price in ETH
     * @param auctionDurationArg (optional) auction duration in seconds
     * @param minimumBidIncrementArg (optional) minimum bid increment in percentage points
     * @param pausedArg (optional) create the auction in a paused state
     * @param commissionRateArg (optional) pass in a custom marketplace commission rate
     * @param creatorRoyaltyRateArg (optional) pass in a custom creator royalty rate
     */
    function createAuction(
        address nftAddress,
        uint256 tokenId,
        uint256 reservePrice,
        uint32 auctionDurationArg,
        uint8 minimumBidIncrementArg,
        bool pausedArg,
        uint8 commissionRateArg,
        uint8 creatorRoyaltyRateArg
    ) public nonReentrant noAuctionExists(nftAddress, tokenId) {
        _senderIsOwnerOrAdmin(nftAddress, tokenId);
        require(
            reservePrice >= 0,
            'createAuction::Reserve price must be greater than or equal to 0'
        );

        bool isPaused = true;

        MarketSettings memory marketSettings =
            MarketSettings({
                timeBuffer: iFirstDibsMarketSettings.globalTimeBuffer(),
                minimumBidIncrement: iFirstDibsMarketSettings.globalMinimumBidIncrement(),
                duration: iFirstDibsMarketSettings.globalAuctionDuration(),
                commissionRate: iFirstDibsMarketSettings.globalMarketCommission(),
                creatorRoyaltyRate: iFirstDibsMarketSettings.globalCreatorRoyaltyRate()
            });

        if (hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            isPaused = pausedArg;
            if (auctionDurationArg > 0) {
                marketSettings.duration = auctionDurationArg;
            }
            if (minimumBidIncrementArg > 0) {
                marketSettings.minimumBidIncrement = minimumBidIncrementArg;
            }
            if (commissionRateArg <= 100) {
                marketSettings.commissionRate = commissionRateArg;
            }
            if (creatorRoyaltyRateArg <= 100) {
                marketSettings.creatorRoyaltyRate = creatorRoyaltyRateArg;
            }
        }

        address owner = IERC721(nftAddress).ownerOf(tokenId);
        auctions[nftAddress][tokenId] = Auction({
            payee: payable(owner), // payee is the token owner
            auctionCreator: _msgSender(),
            reservePrice: reservePrice, // minimum bid threshold for auction to begin
            startTime: 0,
            currentBid: 0, // current winning bid of the auction
            currentBidder: address(0), // set currentBidder to 0 address
            paused: isPaused, // is individual auction paused
            pausedTime: 0, // when was the auction paused
            timeBuffer: marketSettings.timeBuffer,
            minimumBidIncrement: marketSettings.minimumBidIncrement,
            duration: marketSettings.duration,
            commissionRate: marketSettings.commissionRate,
            creatorRoyaltyRate: marketSettings.creatorRoyaltyRate
        });

        // transfer the NFT to the auction contract to hold in escrow for the duration of the auction
        IERC721(nftAddress).transferFrom(owner, address(this), tokenId);

        emit AuctionCreated(
            nftAddress,
            tokenId,
            owner,
            _msgSender(),
            reservePrice,
            marketSettings.duration,
            marketSettings.minimumBidIncrement,
            isPaused
        );
    }

    /**
     * @dev external function that can be called by any address which submits a bid to an auction
     * @param nftAddress ERC-721 contract address
     * @param tokenId uint256 id of the token
     * @param amount uint256 bid in WEI
     */
    function bid(
        address nftAddress,
        uint256 tokenId,
        uint256 amount
    )
        external
        payable
        nonReentrant
        auctionNotExpired(nftAddress, tokenId)
        notPaused(nftAddress, tokenId)
    {
        require(amount == msg.value, 'Bid amount does not match ETH deposit');
        require(amount > 0, 'Bid must be greater than 0');
        require(
            amount >= auctions[nftAddress][tokenId].reservePrice,
            'Bid must be greater than or equal to the reserve price'
        );

        if (auctions[nftAddress][tokenId].startTime == 0) {
            auctions[nftAddress][tokenId].startTime = uint64(block.timestamp);
        } else {
            uint256 priorBidAmount = auctions[nftAddress][tokenId].currentBid;
            address priorBidder = auctions[nftAddress][tokenId].currentBidder;
            // make sure bid meets minimum bid increment
            require(
                amount >=
                    priorBidAmount.add(
                        priorBidAmount.mul(auctions[nftAddress][tokenId].minimumBidIncrement).div(
                            100
                        )
                    ),
                'Must be more than last bid by the configured amount'
            );
            _tryETHThenEscrow(priorBidder, priorBidAmount);
        }
        // upon successul bid, transfer the funds & update the new bidder on the contract
        auctions[nftAddress][tokenId].currentBid = amount;
        auctions[nftAddress][tokenId].currentBidder = _msgSender();

        // extend countdown for bids within the time buffer of the auction
        if (
            // if auction ends less than globalTimeBuffer from now
            _getAuctionEndTime(nftAddress, tokenId) <
            block.timestamp.add(auctions[nftAddress][tokenId].timeBuffer)
        ) {
            // increment the duration by the difference between the new end time and the old end time
            auctions[nftAddress][tokenId].duration += uint32(
                block.timestamp.add(auctions[nftAddress][tokenId].timeBuffer).sub(
                    _getAuctionEndTime(nftAddress, tokenId)
                )
            );
        }

        emit AuctionBid(
            nftAddress,
            tokenId,
            auctions[nftAddress][tokenId].payee,
            _msgSender(),
            msg.value,
            auctions[nftAddress][tokenId].duration,
            auctions[nftAddress][tokenId].startTime
        );
    }

    /**
     * @dev method for ending an auction which has expired. Distrubutes payment to all parties & send token to winning bidder (or returns it to the auction creator if there was no winner)
     * @param nftAddress ERC-721 contract address
     * @param tokenId uint256 id of the token
     */
    function endAuction(address nftAddress, uint256 tokenId)
        external
        nonReentrant
        auctionComplete(nftAddress, tokenId)
        notPaused(nftAddress, tokenId)
    {
        Auction memory auction = auctions[nftAddress][tokenId];

        delete auctions[nftAddress][tokenId];
        // send the NFT to the winning bidder
        IERC721(nftAddress).transferFrom(address(this), auction.currentBidder, tokenId);

        uint256 commissionFee = 0;
        if (auction.commissionRate > 0) {
            // send commission to 1stdibs
            commissionFee = auction.currentBid.mul(auction.commissionRate).div(100);
            _tryETHThenEscrow(
                iFirstDibsMarketSettings.commissionAddress(),
                commissionFee
            );
        }
        address nftCreator = iERC721TokenCreatorRegistry.tokenCreator(nftAddress, tokenId);
        // send payout to token owner & token creator (they might be the same)
        if (nftCreator == auction.payee) {
            _sendToEscrow(auction.payee, auction.currentBid.sub(commissionFee));
        } else {
            // calculate & send creator royalty to escrow
            uint256 creatorRoyaltyFee = auction.currentBid.mul(auction.creatorRoyaltyRate).div(100);
            _sendToEscrow(nftCreator, creatorRoyaltyFee);
            // send remaining funds to the seller in escrow
            _sendToEscrow(auction.payee, auction.currentBid.sub(creatorRoyaltyFee).sub(commissionFee));
        }
        emit AuctionEnded(
            nftAddress,
            tokenId,
            auction.payee,
            auction.currentBidder,
            auction.currentBid
        );
    }

    /**
     * @dev external function to cancel an auction & return the NFT to the creator of the auction
     * @param nftAddress ERC-721 contract address
     * @param tokenId uint256 token id
     */
    function cancelAuction(address nftAddress, uint256 tokenId)
        external
        nonReentrant
        auctionExists(nftAddress, tokenId)
        senderIsAuctionCreatorOrAdmin(nftAddress, tokenId)
    {
        // can't cancel a started auction
        require(
            uint256(auctions[nftAddress][tokenId].startTime) == 0,
            'The auction has already begun'
        );

        // delete the auction and return the token back to the original owner
        address owner = auctions[nftAddress][tokenId].payee;
        delete auctions[nftAddress][tokenId];
        IERC721(nftAddress).transferFrom(address(this), owner, tokenId);
        emit AuctionCanceled(nftAddress, tokenId, owner, _msgSender());
    }

    /**
     * @dev external function for pausing / unpausing an auction
     * @param nftAddress ERC-721 address
     * @param tokenId uint256 token id
     * @param paused true to pause the auction, false to unpause the auction
     */
    function setAuctionPause(
        address nftAddress,
        uint256 tokenId,
        bool paused
    )
        external
        auctionExists(nftAddress, tokenId)
        senderIsAuctionCreatorOrAdmin(nftAddress, tokenId)
    {
        if (paused) {
            auctions[nftAddress][tokenId].pausedTime = uint64(block.timestamp);
        } else if (
            !paused &&
            auctions[nftAddress][tokenId].pausedTime > 0 &&
            auctions[nftAddress][tokenId].startTime > 0
        ) {
            // if the auction has started, increment duration by difference between current time and paused time
            auctions[nftAddress][tokenId].duration += uint32(
                block.timestamp.sub(auctions[nftAddress][tokenId].pausedTime)
            );
            auctions[nftAddress][tokenId].pausedTime = 0;
        }
        auctions[nftAddress][tokenId].paused = paused;
        emit AuctionPaused(
            nftAddress,
            tokenId,
            auctions[nftAddress][tokenId].payee,
            _msgSender(),
            paused,
            auctions[nftAddress][tokenId].duration
        );
    }

    /**
     * @dev utility function for calculating an auctions end time
     */
    function _getAuctionEndTime(address nftAddress, uint256 tokenId) private view returns (uint64) {
        return auctions[nftAddress][tokenId].startTime + auctions[nftAddress][tokenId].duration;
    }
    function _senderIsOwnerOrAdmin(address nftAddress, uint256 tokenId) private view {
        // require _msgSender() to be token owner or have admin role for token
        IERC721 erc721 = IERC721(nftAddress);
        address owner = erc721.ownerOf(tokenId);
        require(
            _msgSender() == owner || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            'Message sender must be token owner or admin'
        );
    }
    /**
     * @dev tries to transfers ETH to an account, but sends to escrow if the transfer fails
     * @param to address to transfer ETH to
     * @param amount uint256 WEI amount to transfer
     */
    function _tryETHThenEscrow(address to, uint256 amount) private {
        iFirstDibsEscrow.tryETHThenEscrow{value: amount}(to, amount);
    }

    /**
     * @dev Send funds to escrow
     * @param to address to transfer ETH to
     * @param amount uint256 WEI amount to transfer
     */
    function _sendToEscrow(address to, uint256 amount) private {
        iFirstDibsEscrow.sendToEscrow{value: amount}(to, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        require(b > 0, errorMessage);
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./escrow/Escrow.sol";

/**
 * @dev Simple implementation of a
 * https://consensys.github.io/smart-contract-best-practices/recommendations/#favor-pull-over-push-for-external-calls[pull-payment]
 * strategy, where the paying contract doesn't interact directly with the
 * receiver account, which must withdraw its payments itself.
 *
 * Pull-payments are often considered the best practice when it comes to sending
 * Ether, security-wise. It prevents recipients from blocking execution, and
 * eliminates reentrancy concerns.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * To use, derive from the `PullPayment` contract, and use {_asyncTransfer}
 * instead of Solidity's `transfer` function. Payees can query their due
 * payments with {payments}, and retrieve them with {withdrawPayments}.
 */
abstract contract PullPayment {
    Escrow private _escrow;

    constructor () internal {
        _escrow = new Escrow();
    }

    /**
     * @dev Withdraw accumulated payments, forwarding all gas to the recipient.
     *
     * Note that _any_ account can call this function, not just the `payee`.
     * This means that contracts unaware of the `PullPayment` protocol can still
     * receive funds this way, by having a separate account call
     * {withdrawPayments}.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee Whose payments will be withdrawn.
     */
    function withdrawPayments(address payable payee) public virtual {
        _escrow.withdraw(payee);
    }

    /**
     * @dev Returns the payments owed to an address.
     * @param dest The creditor's address.
     */
    function payments(address dest) public view returns (uint256) {
        return _escrow.depositsOf(dest);
    }

    /**
     * @dev Called by the payer to store the sent amount as credit to be pulled.
     * Funds sent in this way are stored in an intermediate {Escrow} contract, so
     * there is no danger of them being spent before withdrawal.
     *
     * @param dest The destination address of the funds.
     * @param amount The amount to transfer.
     */
    function _asyncTransfer(address dest, uint256 amount) internal virtual {
        _escrow.deposit{ value: amount }(dest);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

//SPDX-License-Identifier: BSD 3-Clause
pragma solidity 0.6.12;

/**
 * @title IERC721 Non-Fungible Token Creator basic interface
 * @dev Interop with other systems supporting this interface
 * @notice Original license and source here: https://github.com/Pixura/pixura-contracts
 */
interface IERC721TokenCreator {
    /**
     * @dev Gets the creator of the _tokenId on _nftAddress
     * @param _nftAddress address of the ERC721 contract
     * @param _tokenId uint256 ID of the token
     * @return address of the creator
     */
    function tokenCreator(address _nftAddress, uint256 _tokenId)
        external
        view
        returns (address payable);
}

//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.6.0;

interface IFirstDibsMarketSettings {
    function globalTimeBuffer() external view returns (uint16);

    function globalAuctionDuration() external view returns (uint32);

    function globalMarketCommission() external view returns (uint8);

    function globalCreatorRoyaltyRate() external view returns (uint8);

    function globalMinimumBidIncrement() external view returns (uint8);

    function commissionAddress() external view returns (address);
}

//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.6.0;

interface IFirstDibsEscrow {
    function tryETHThenEscrow(address to, uint256 amount) payable external;
    function sendToEscrow(address to, uint256 amount) payable external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../math/SafeMath.sol";
import "../../access/Ownable.sol";
import "../../utils/Address.sol";

 /**
  * @title Escrow
  * @dev Base escrow contract, holds funds designated for a payee until they
  * withdraw them.
  *
  * Intended usage: This contract (and derived escrow contracts) should be a
  * standalone contract, that only interacts with the contract that instantiated
  * it. That way, it is guaranteed that all Ether will be handled according to
  * the `Escrow` rules, and there is no need to check for payable functions or
  * transfers in the inheritance tree. The contract that uses the escrow as its
  * payment method should be its owner, and provide public methods redirecting
  * to the escrow's deposit and withdraw.
  */
contract Escrow is Ownable {
    using SafeMath for uint256;
    using Address for address payable;

    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);

    mapping(address => uint256) private _deposits;

    function depositsOf(address payee) public view returns (uint256) {
        return _deposits[payee];
    }

    /**
     * @dev Stores the sent amount as credit to be withdrawn.
     * @param payee The destination address of the funds.
     */
    function deposit(address payee) public payable virtual onlyOwner {
        uint256 amount = msg.value;
        _deposits[payee] = _deposits[payee].add(amount);

        emit Deposited(payee, amount);
    }

    /**
     * @dev Withdraw accumulated balance for a payee, forwarding all gas to the
     * recipient.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee The address whose funds will be withdrawn and transferred to.
     */
    function withdraw(address payable payee) public virtual onlyOwner {
        uint256 payment = _deposits[payee];

        _deposits[payee] = 0;

        payee.sendValue(payment);

        emit Withdrawn(payee, payment);
    }
}

