// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// ============ Internal Imports ============

import {IManager} from "./interfaces/IManager.sol";
import {IArtAuction} from "./interfaces/IArtAuction.sol";

import {IBidDb} from "./interfaces/IBidDb.sol";
import {IBidDbV1} from "./interfaces/IBidDbV1.sol";
import {IBidDbV2} from "./interfaces/IBidDbV2.sol";

import {IAuctionHouse} from "./interfaces/IAuctionHouse.sol";
import {IAuctionHouseV1} from "./interfaces/IAuctionHouseV1.sol";
import {IAuctionHouseV2} from "./interfaces/IAuctionHouseV2.sol";

/**
 * @title ManagerProxy
 * @author Matrix
 */
contract ManagerProxy {
    // ============ Variables ============

    IManager public immutable _manager;
    address public immutable _nftToken;
    IAuctionHouseV1 public immutable _zoraMarket1;
    IAuctionHouseV2 public immutable _zoraMarket2;

    // ============ Constructor function ============

    constructor(
        address manager,
        address nftToken,
        address zoraMarket1,
        address zoraMarket2
    ) {
        _manager = IManager(manager);
        _nftToken = nftToken;
        _zoraMarket1 = IAuctionHouseV1(zoraMarket1);
        _zoraMarket2 = IAuctionHouseV2(zoraMarket2);
    }

    // ============ External functions ============

    function endArtAuction(uint256 nftId) external {
        _manager.endArtAuction(nftId);
    }

    function getAuctionByTokenId(uint256 tokenId)
        external
        view
        returns (
            uint256 auctionId,
            IAuctionHouse.Auction memory auction,
            IBidDb.Status memory status,
            IBidDb.Bid[] memory bids
        )
    {
        // try to get result from second market at first
        IBidDbV2 bidDbV2 = IBidDbV2(_zoraMarket2.getBidDb());
        auctionId = bidDbV2.getAuctionId(_nftToken, tokenId);
        if (auctionId != 0) {
            (auction, status, bids) = bidDbV2.getAuction(auctionId);
        } else {
            // try to get auctionId from CanvasManager
            address artAuction = _manager.getArtAuctionAddress(tokenId);
            auctionId = IArtAuction(artAuction).getArtAuctionId();
            require(auctionId != type(uint256).max, "no auction record");

            // then get result from first market
            address bidDbV1 = _zoraMarket1.bidDb();
            auction = IBidDbV1(bidDbV1).auctions(auctionId);
            status = IBidDbV1(bidDbV1).getBidStatus(auctionId);
            bids = IBidDbV1(bidDbV1).getBidHistory(auctionId);
        }
    }
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

// ============ External Imports ============

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IManager
 * @author Matrix
 */
interface IManager {
    // ========== External functions ==========

    function pause() external;
    function unpause() external;

    function getZoraMarketAddress() external view returns (address);
    function setZoraMarketAddress(address zoraMarket) external;

    function getMoment(uint256 uMomentId) external view returns (uint24[1024] memory colors, uint256 momentIndex, uint256 artId);
    function getMomentColors(uint256 uMomentId) external view returns (uint24[1024] memory);

    /// @return default duration, currency, price of auction
    function getDefaultAuctionInfo() external view returns (uint256, address, uint256);

    /// @notice set default duration, currency, price used when create auction
    function setDefaultAuctionInfo(uint256 duration, address currency, uint256 price) external;

    /// @return address of auction contract which tokenId is nftId
    function getArtAuctionAddress(uint256 nftId) external view returns (address);

    function withdrawAdminFee(uint256 tokenIndex, address to, uint256 amount) external;

    function withdrawCuratorFee(uint256 nftId, address to, uint256 amount) external;

    function setAuctionCurrency(uint256 nftId, address auctionCurrency) external;

    function createArtAuctionAndApproval(uint256 nftId, uint256 duration, uint256 reservePrice) external returns (uint256);

    /// @return auctionId auction ID
    /// @return reservePrice The minimum price of the first bid
    /// @return beginTime The begin time of auction
    /// @return duration The duration of auction
    /// @return owner The owner of auction
    /// @return auctionCurrency The currency of auction
    /// @return state 0: nft in this contract; 1: nft is market; 2: other
    /// @return approved Whether or not the auction curator has approved the auction to start
    function getArtAuctionInfo(uint256 nftId) external view returns (
        uint256 auctionId, uint256 reservePrice, uint256 beginTime, uint256 duration, address owner, address auctionCurrency, uint8 state, bool approved);

    /// @dev  calculates contribution for a single contributor
    /// @param nftId token id of pixel nft
    /// @param contributor any contributor
    /// @return contributorShareOfThisNft The shares of contributor in this PixNft
    /// @return contributorShareOfAllNft The total shares of contributor from first PixNft to this PixNft(include this PixNft)
    /// @return totalSharesOfThisNft The total shares of this PixNft
    /// @return totalSharesOfAllNft The total shares from first PixNft to this PixNft(include this PixNft)
    /// @return amount The all received tokens of art auction contract
    function getNftPorfitInfo(uint256 nftId, address contributor) external view returns (
        uint256 contributorShareOfThisNft, uint256 contributorShareOfAllNft, uint256 totalSharesOfThisNft, uint256 totalSharesOfAllNft, uint256 amount);

    function setArtAuctionApproval(uint256 nftId, bool approved) external;
    function setArtAuctionReservePrice(uint256 nftId, uint256 reservePrice) external;
    function cancelArtAuction(uint256 nftId) external;
    function endArtAuction(uint256 nftId) external;

    /**
     * @notice Claim ERC20 tokens to a single contributor after the auction has ended,
     * @dev Anyone can call claim for any contributor, and can be called for multi times
     * @param nftId id of PixNFT
     * @param contributor the address of receiver
     */
    function claimeArtAuctionFee(uint256 nftId, address contributor) external;

    function getConsumeToken(uint256 index) external view returns (address token, uint256 basePrice);
    function setOrAddConsumeToken(uint256 index, IERC20 token, uint256 basePrice) external;

    function startNewArt(uint256 endTime) external returns (uint256 nftId);
    function setEndTime(uint256 nftId, uint256 endTime) external;

    // every one can call end, if reach the end time
    function endArt(uint256 nftId) external;

    function getArt(uint256 nftId) external view returns (
        uint256 consumToken, uint32 momentIndex, uint24[1024] memory colors, uint256[1024] memory price, uint8 state, uint256[] memory moments, uint256 startTime, uint256 endTime);

    function getOpenArts() external view returns (uint256[] memory nftIds);
    function getEndArts() external view returns (uint256[] memory);
    function getAllArts() external view returns (uint256[] memory nftIds);

    function getDrawPrice(uint256 nftId, uint256 pixelIndex, uint256 tokenIndex) external view returns (uint256);
    function drawPixel(uint256 tokenIndex, uint256 nftId, uint256 index, uint24 color, uint256 bidPrice) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.8;
pragma experimental ABIEncoderV2;

import { IAuctionHouse } from "./IAuctionHouse.sol";
import { IBidDb } from "./IBidDb.sol";

/**
 * @title Interface for IBidDb V2.0
 */
interface IBidDbV2 is IBidDb {
    // ========== External functions ==========

    function getMaxAuctionId() external view returns(uint256);

    function getTokens() external view returns(address[] memory);
    function getTokens(uint256 offset, uint256 limit) external view returns(address[] memory);

    function getTokenIds(address token) external view returns(uint256[] memory tokenIds, uint256[] memory auctionIds);
    function getTokenIds(address token, uint256 offset, uint256 limit) external view returns(uint256[] memory tokenIds, uint256[] memory auctionIds);

    function getAuctionId(address token, uint256 tokenId) external view returns(uint256);
    function getAuction(uint256 auctionId) external view returns(IAuctionHouse.Auction memory, IBidDb.Status memory, IBidDb.Bid[] memory);
    function getAuctionByTokenId(address token, uint256 tokenId) external view returns(
        uint256 auctionId, IAuctionHouse.Auction memory auction, IBidDb.Status memory status, IBidDb.Bid[] memory bids);

    function createAuction(
        uint256 auctionId, 
        uint256 tokenId, 
        address tokenContract, 
        uint256 duration, 
        uint256 reservePrice, 
        uint8 curatorFeePercentage, 
        address tokenOwner, 
        address payable curator, 
        address auctionCurrency) external;

    function setAuctionApproval(uint256 auctionId, bool approved) external;

    function setAuctionReservePrice(uint256 auctionId, uint256 reservePrice) external ;
    
    function createBid(uint256 auctionId, address bidder, uint256 amount, uint256 duration) external;

    function cancelAuction(uint256 auctionId) external;

    function endAuction(uint256 auctionId, uint256 curatorFee, uint256 tokenOwnerProfit) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.8;
pragma experimental ABIEncoderV2;

import {IAuctionHouse} from "./IAuctionHouse.sol";
import {IBidDb} from "./IBidDb.sol";

/**
 * @title Interface for IBidDb V1.0
 * @author Matrix
 */
interface IBidDbV1 is IBidDb {
    // ========== Structs ==========
    
    struct BidStatus {
        Status status;
        Bid[] bids;
    }

    // ========== External functions ==========

    function auctions(uint256 auctionId) external view returns (IAuctionHouse.Auction memory);

    function getBidStatus(uint256 auctionId) external view returns (IBidDb.Status memory);

    function getBidHistory(uint256 auctionId) external view returns (IBidDb.Bid[] memory);

    function getBidRecord(uint256 auctionId, uint256 start, uint256 end) external view returns (IBidDb.Bid[] memory);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.8;
pragma experimental ABIEncoderV2;

/**
 * @title Interface for IBidDb
 * @author Matrix
 */
interface IBidDb {
    // ============ Enums ============

    enum State {
        Create, // not approved
        Approval, // approved
        InBid, // has bid
        Cancel, // canceled when has no bid
        End // ended when has bid
    }

    // ========== Structs ==========

    struct Status {
        uint256 beginTime;
        uint256 curatorFee;
        uint256 tokenOwnerProfit;
        address winner; // 20 bytes
        uint88 count;   // 11 bytes, size of bid array
        State state;    // 1 byte
    }

    struct Bid {
        uint256 time;
        uint256 amount;
        address bidder; 
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.8;
pragma experimental ABIEncoderV2;

import { IAuctionHouse } from "./IAuctionHouse.sol";
import { IBidDb } from "./IBidDb.sol";

/**
 * @title Interface for Auction Houses v2.0
 */
interface IAuctionHouseV2 is IAuctionHouse {
    // ========== External functions ==========

    function createAndApproveAuction(
        uint256 tokenId,
        address tokenContract,
        uint256 duration,
        uint256 reservePrice,
        address payable curator,
        uint8 curatorFeePercentage,
        address auctionCurrency
    ) external returns (uint256);

    function getBidDb() external view returns(address);
    function getCurrentAuctionId() external view returns(uint256);

    function getAuctionIds() external view returns(uint256[] memory);
    function getAllNft() external view returns(address[] memory tokens, uint256[] memory tokenIds, uint256[] memory auctionIds);
    function getNftByToken(address token) external view returns(uint256[] memory tokenIds, uint256[] memory auctionIds);
    function getNftByOwner(address token, address owner) external view returns(uint256[] memory tokenIds, uint256[] memory auctionIds);

    function getAuction(uint256 auctionId) external view returns(IAuctionHouse.Auction memory);
    function getAuctions() external view returns(uint256[] memory auctionIds, IAuctionHouse.Auction[] memory auctions_);
    function getAuctionsByAccount(address account) external view returns(uint256[] memory auctionIds, IAuctionHouse.Auction[] memory auctions_);
    function getAuctionByTokenId(address token, uint256 tokenId) external view returns(uint256 auctionId, IAuctionHouse.Auction memory auction, IBidDb.Bid[] memory bids);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.8;
pragma experimental ABIEncoderV2;

import {IAuctionHouse} from "./IAuctionHouse.sol";

/**
 * @title Interface for Auction Houses v1.0
 */
interface IAuctionHouseV1 is IAuctionHouse {
    function auctions(uint256 auctionId) external view returns(Auction memory);
    function bidDb() external view returns(address);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.8;
pragma experimental ABIEncoderV2;

/**
 * @title Interface for Auction Houses
 */
interface IAuctionHouse {
    // ========== Structs ==========

    struct Auction {
        // ID for the ERC721 token
        uint256 tokenId;
        // Address for the ERC721 contract
        address tokenContract;
        // Whether or not the auction curator has approved the auction to start
        bool approved;
        // The current highest bid amount
        uint256 amount;
        // The length of time to run the auction for, after the first bid was made
        uint256 duration;
        // The time of the first bid
        uint256 firstBidTime;
        // The minimum price of the first bid
        uint256 reservePrice;
        // The sale percentage to send to the curator
        uint8 curatorFeePercentage;
        // The address that should receive the funds once the NFT is sold.
        address tokenOwner;
        // The address of the current highest bid
        address payable bidder;
        // The address of the auction's curator.
        // The curator can reject or approve an auction
        address payable curator;
        // The address of the ERC-20 currency to run the auction with.
        // If set to 0x0, the auction will be run in ETH
        address auctionCurrency;
    }

    // ========== Events ==========

    event AuctionCreated(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        uint256 duration,
        uint256 reservePrice,
        address tokenOwner,
        address curator,
        uint8 curatorFeePercentage,
        address auctionCurrency
    );

    event AuctionApprovalUpdated(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        bool approved
    );

    event AuctionReservePriceUpdated(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        uint256 reservePrice
    );

    event AuctionBid(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        address sender,
        uint256 value,
        bool firstBid,
        bool extended
    );

    event AuctionDurationExtended(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        uint256 duration
    );

    event AuctionEnded(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        address tokenOwner,
        address curator,
        address winner,
        uint256 amount,
        uint256 curatorFee,
        address auctionCurrency
    );

    event AuctionCanceled(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        address tokenOwner
    );

    // ========== External functions ==========

    function createAuction(
        uint256 tokenId,
        address tokenContract,
        uint256 duration,
        uint256 reservePrice,
        address payable curator,
        uint8 curatorFeePercentages,
        address auctionCurrency
    ) external returns (uint256);

    function setAuctionApproval(uint256 auctionId, bool approved) external;

    function setAuctionReservePrice(uint256 auctionId, uint256 reservePrice) external;

    function createBid(uint256 auctionId, uint256 amount) external payable;

    function endAuction(uint256 auctionId) external;

    function cancelAuction(uint256 auctionId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IArtAuction {
    // ============ Enums ============

    enum MarketType {
        Unknown,
        Zora
    }

    // ============ Events ============

    event NewArtAuctionContract(
        address indexed me,
        uint256 allNftShares,
        uint256 thisNftShares,
        uint256 indexed nftId,
        address indexed market,
        address auctionCurrency,
        MarketType marketType
    );

    event OnERC721Receive(address indexed me, address operator, address from, uint256 indexed tokenId);

    event CreateArtAuction(
        address indexed me,
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        uint256 duration,
        uint256 reservePrice,
        address auctionCurrency
    );

    event SetArtAuctionApproval(address indexed me, uint256 indexed tokenId, uint256 indexed auctionId, bool approved);

    event SetArtAuctionReservePrice(address indexed me, uint256 indexed auctionId, uint256 indexed tokenId, uint256 reservePrice);

    event CancelArtAuction(address indexed me, uint256 indexed auctionId, uint256 indexed tokenId);

    event EndArtAuction(address indexed me, uint256 indexed auctionId, uint256 indexed tokenId);

    event ClaimeArtAuctionFee(
        address indexed me,
        address indexed who,
        address indexed contributor,
        uint256 thisNftShare,
        uint256 allNftShare,
        uint256 totalPayment,
        uint256 pendingPayment
    );

    event ClaimeCuratorFee(address indexed me, address indexed who, address indexed to, uint256 totalPayment, uint256 pendingPayment);

    // ============ Functions ============

    function marketType() external pure returns (MarketType);

    function getArtAuctionId() external view returns (uint256);

    function getAuctionCurrency() external view returns (address);

    function setAuctionCurrency(address newCurrency) external;

    function createArtAuction(uint256 duration, uint256 reservePrice) external returns (uint256);

    function getArtAuctionInfo()
        external
        view
        returns (
            uint256 auctionId,
            uint256 reservePrice,
            uint256 beginTime,
            uint256 duration,
            address owner,
            address auctionCurrency,
            uint8 state,
            bool approved
        );

    function getProfitInfo()
        external
        view
        returns (
            uint256 totalSharesOfThisNft,
            uint256 totalSharesOfAllNft,
            uint256 amount
        );

    function getArtAuctionApproval() external view returns (bool);

    function setArtAuctionApproval(bool approved) external;

    function getArtAuctionReservePrice() external view returns (uint256);

    function setArtAuctionReservePrice(uint256 reservePrice) external;

    function cancelArtAuction() external;

    function endArtAuction() external;

    function claimeArtAuctionFee(
        address contributor,
        uint256 thisNftShare,
        uint256 allNftShare
    ) external;

    function claimeCuratorFee(address to, uint256 amount) external;
}