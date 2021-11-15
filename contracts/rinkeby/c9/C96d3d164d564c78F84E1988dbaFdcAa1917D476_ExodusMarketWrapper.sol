// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

// ============ External Imports ============
import {IFoliaMarket} from "../external/interfaces/IFoliaMarket.sol";

// ============ Internal Imports ============
import {IMarketWrapper} from "./IMarketWrapper.sol";

/**
 * @title FoliaMarketWrapper
 * @author Billy Rennekamp
 * @notice MarketWrapper contract implementing IMarketWrapper interface
 * according to the logic of Folia's NFT Market
 * Original Folia NFT Market code: https://etherscan.io/address/0xe708fffbe607def8a2be9d35a876f0ebe431dee7#code
 */
contract ExodusMarketWrapper is IMarketWrapper {
    // ============ Internal Immutables ============

    IFoliaMarket internal immutable market;

    // ======== Constructor =========

    constructor(address _foliaMarket) {
        market = IFoliaMarket(_foliaMarket);
    }

    // ======== External Functions =========

    /**
     * @notice Determine whether there is an existing auction
     * for this token on the market
     * @return TRUE if the auction exists
     */
    function auctionExists(uint256 auctionId)
        public
        view
        override
        returns (bool)
    {
        // line 23 of ReserveAuction, implicit getter for public mapping of auctions
        IFoliaMarket.Auction memory _auction =
            market.auctions(auctionId);
        return _auction.exists;
    }

    /**
     * @notice Determine whether the given auctionId is
     * an auction for the tokenId + nftContract
     * @return TRUE if the auctionId matches the tokenId + nftContract
     */
    function auctionIdMatchesToken(
        uint256 auctionId,
        address nftContract,
        uint256 tokenId
    ) public view override returns (bool) {
        return false;
    }

    /**
     * @notice Query the current highest bidder for this auction
     * @return highest bidder
     */
    function getCurrentHighestBidder(uint256 auctionId)
        external
        view
        override
        returns (address)
    {
        // line 23 of ReserveAuction, implicit getter for public mapping of auctions
        IFoliaMarket.Auction memory _auction =
            market.auctions(auctionId);
        return _auction.bidder;
    }

    /**
     * @notice Calculate the minimum next bid for this auction
     * @return minimum bid amount
     */
    function getMinimumBid(uint256 auctionId)
        external
        view
        override
        returns (uint256)
    {
        // line 23 of ReserveAuction, implicit getter for public mapping of auctions
        IFoliaMarket.Auction memory _auction =
            market.auctions(auctionId);

        if (_auction.amount == 0) {
            return _auction.reservePrice;
        } else {
            uint256 _minBid = market.minBid();
            return _auction.amount + _minBid;
        }
    }

    /**
     * @notice Submit bid to Market contract
     */
    function bid(uint256 auctionId, uint256 bidAmount) external override {
        // line 136 of ReserveAuction, createBid() function
        (bool success, bytes memory returnData) =
            address(market).call{value: bidAmount}(
                abi.encodeWithSignature("createBid(uint256)", auctionId)
            );
        require(success, string(returnData));
    }

    /**
     * @notice Determine whether the auction has been finalized
     * @return TRUE if the auction has been finalized
     */
    function isFinalized(uint256 auctionId)
        external
        view
        override
        returns (bool)
    {
        
        // line 23 of ReserveAuction, implicit getter for public mapping of auctions
        // the auction is deleted at the end of the endAuction() function
        // since we checked that the auction DID exist when we deployed the partyBid,
        // if it no longer exists that means the auction has been finalized.
        IFoliaMarket.Auction memory _auction =
            market.auctions(auctionId);
        return !_auction.exists;
    }

    /**
     * @notice Finalize the results of the auction
     */
    function finalize(uint256 auctionId) external override {
        // line 214 of ReserveAuction, endAuction() function
        // will revert if auction has not started or still in progress
        market.endAuction(auctionId);
    }
}

pragma solidity 0.8.5;

interface IFoliaMarket {

    function minBid() external view returns(uint256);
    function nftAddress() external view returns(address);
    function auctions(uint256 tokenId) external view returns(Auction memory);

    struct Auction {
        bool exists;
        bool paused;
        uint256 amount;
        uint256 duration;
        uint256 firstBidTime;
        uint256 reservePrice;
        uint256 adminSplit; // percentage of 100
        address creator;
        address payable proceedsRecipient;
        address payable bidder;
    }
    function createBid(uint256 tokenId) external payable;
    function endAuction(uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

/**
 * @title IMarketWrapper
 * @author Anna Carroll
 * @notice IMarketWrapper provides a common interface for
 * interacting with NFT auction markets.
 * Contracts can abstract their interactions with
 * different NFT markets using IMarketWrapper.
 * NFT markets can become compatible with any contract
 * using IMarketWrapper by deploying a MarketWrapper contract
 * that implements this interface using the logic of their Market.
 *
 * WARNING: MarketWrapper contracts should NEVER write to storage!
 * When implementing a MarketWrapper, exercise caution; a poorly implemented
 * MarketWrapper contract could permanently lose access to the NFT or user funds.
 */
interface IMarketWrapper {
    /**
     * @notice Determine whether there is an existing auction
     * for this token on the underlying market
     * @return TRUE if the auction exists
     */
    function auctionExists(uint256 auctionId) external view returns (bool);

    /**
     * @notice Determine whether the given auctionId is
     * an auction for the tokenId + nftContract
     * @return TRUE if the auctionId matches the tokenId + nftContract
     */
    function auctionIdMatchesToken(
        uint256 auctionId,
        address nftContract,
        uint256 tokenId
    ) external view returns (bool);

    /**
     * @notice Calculate the minimum next bid for this auction
     * @return minimum bid amount
     */
    function getMinimumBid(uint256 auctionId) external view returns (uint256);

    /**
     * @notice Query the current highest bidder for this auction
     * @return highest bidder
     */
    function getCurrentHighestBidder(uint256 auctionId)
        external
        view
        returns (address);

    /**
     * @notice Submit bid to Market contract
     */
    function bid(uint256 auctionId, uint256 bidAmount) external;

    /**
     * @notice Determine whether the auction has been finalized
     * @return TRUE if the auction has been finalized
     */
    function isFinalized(uint256 auctionId) external view returns (bool);

    /**
     * @notice Finalize the results of the auction
     */
    function finalize(uint256 auctionId) external;
}

