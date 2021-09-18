// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

// ============ External Imports ============
import {INounsAuctionHouse} from "../external/interfaces/INounsAuctionHouse.sol";

// ============ Internal Imports ============
import {IMarketWrapper} from "./IMarketWrapper.sol";

/**
 * @title NounsMarketWrapper
 * @author Anna Carroll + Nounders
 * @notice MarketWrapper contract implementing IMarketWrapper interface
 * according to the logic of Nouns' Auction Houses
 */
contract NounsMarketWrapper is IMarketWrapper {
    // ============ Public Immutables ============

    INounsAuctionHouse public immutable market;

    // ======== Constructor =========

    constructor(address _nounsAuctionHouse) {
        market = INounsAuctionHouse(_nounsAuctionHouse);
    }

    // ======== External Functions =========

    /**
     * @notice Determine whether there is an existing, active auction
     * for this token. In the Nouns auction house, the current auction
     * id is the token id, which increments sequentially, forever. The
     * auction is considered active while the current block timestamp
     * is less than the auction's end time.
     * @return TRUE if the auction exists
     */
    function auctionExists(uint256 auctionId)
      public
      view
      returns (bool)
    {
        (uint256 currentAuctionId, , , uint256 endTime, , ) = market.auction();
        return auctionId == currentAuctionId && block.timestamp < endTime;
    }

    /**
     * @notice Determine whether the given auctionId and tokenId is active.
     * We ignore nftContract since it is static for all nouns auctions.
     * @return TRUE if the auctionId and tokenId matches the active auction
     */
    function auctionIdMatchesToken(
        uint256 auctionId,
        address /* nftContract */,
        uint256 tokenId
    ) public view override returns (bool) {
        return auctionId == tokenId && auctionExists(auctionId);
    }

    /**
     * @notice Calculate the minimum next bid for the active auction
     * @return minimum bid amount
     */
    function getMinimumBid(uint256 auctionId)
      external
      view
      override
      returns (uint256)
    {
        require(
            auctionExists(auctionId),
            "NounsMarketWrapper::getMinimumBid: Auction not active"
        );

        (, uint256 amount, , , address payable bidder, ) = market.auction();
        if (bidder == address(0)) {
            // if there are NO bids, the minimum bid is the reserve price
            return market.reservePrice();
        }
        // if there ARE bids, the minimum bid is the current bid plus the increment buffer
        uint8 minBidIncrementPercentage = market.minBidIncrementPercentage();
        return amount + ((amount * minBidIncrementPercentage) / 100);
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
        require(
            auctionExists(auctionId),
            "NounsMarketWrapper::getCurrentHighestBidder: Auction not active"
        );

        (, , , , address payable bidder, ) = market.auction();
        return bidder;
    }

    /**
     * @notice Submit bid to Market contract
     */
    function bid(uint256 auctionId, uint256 bidAmount) external override {
        // line 104 of Nouns Auction House, createBid() function
        (bool success, bytes memory returnData) =
        address(market).call{value: bidAmount}(
            abi.encodeWithSignature(
                "createBid(uint256)",
                auctionId
            )
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
        (uint256 currentAuctionId, , , , , bool settled) = market.auction();
        bool settledNormally = auctionId != currentAuctionId;
        bool settledWhenPaused = auctionId == currentAuctionId && settled;
        return settledNormally || settledWhenPaused;
    }

    /**
     * @notice Finalize the results of the auction
     */
    function finalize(uint256 /* auctionId */) external override {
        if (market.paused()) {
            market.settleAuction();
        } else {
            market.settleCurrentAndCreateNewAuction();
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for Noun Auction Houses

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.5;

interface INounsAuctionHouse {
    struct Auction {
        // ID for the Noun (ERC721 token ID)
        uint256 nounId;
        // The current highest bid amount
        uint256 amount;
        // The time that the auction started
        uint256 startTime;
        // The time that the auction is scheduled to end
        uint256 endTime;
        // The address of the current highest bid
        address payable bidder;
        // Whether or not the auction has been settled
        bool settled;
    }

    event AuctionCreated(uint256 indexed nounId, uint256 startTime, uint256 endTime);

    event AuctionBid(uint256 indexed nounId, address sender, uint256 value, bool extended);

    event AuctionExtended(uint256 indexed nounId, uint256 endTime);

    event AuctionSettled(uint256 indexed nounId, address winner, uint256 amount);

    event AuctionTimeBufferUpdated(uint256 timeBuffer);

    event AuctionReservePriceUpdated(uint256 reservePrice);

    event AuctionMinBidIncrementPercentageUpdated(uint256 minBidIncrementPercentage);

    function reservePrice() external view returns (uint256);

    function minBidIncrementPercentage() external view returns (uint8);

    function auction() external view returns (uint256, uint256, uint256, uint256, address payable, bool);

    function settleAuction() external;

    function settleCurrentAndCreateNewAuction() external;

    function createBid(uint256 nounId) external payable;

    function pause() external;

    function unpause() external;

    function paused() external view returns (bool);

    function setTimeBuffer(uint256 timeBuffer) external;

    function setReservePrice(uint256 reservePrice) external;

    function setMinBidIncrementPercentage(uint8 minBidIncrementPercentage) external;
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
     * @notice Given the auctionId, nftContract, and tokenId, check that:
     * 1. the auction ID matches the token
     * referred to by tokenId + nftContract
     * 2. the auctionId refers to an *ACTIVE* auction
     * (e.g. an auction that will accept bids)
     * within this market contract
     * 3. any additional validation to ensure that
     * a PartyBid can bid on this auction
     * (ex: if the market allows arbitrary bidding currencies,
     * check that the auction currency is ETH)
     * Note: This function probably should have been named "isValidAuction"
     * @dev Called in PartyBid.sol in `initialize` at line 174
     * @return TRUE if the auction is valid
     */
    function auctionIdMatchesToken(
        uint256 auctionId,
        address nftContract,
        uint256 tokenId
    ) external view returns (bool);

    /**
     * @notice Calculate the minimum next bid for this auction.
     * PartyBid contracts always submit the minimum possible
     * bid that will be accepted by the Market contract.
     * usually, this is either the reserve price (if there are no bids)
     * or a certain percentage increase above the current highest bid
     * @dev Called in PartyBid.sol in `bid` at line 251
     * @return minimum bid amount
     */
    function getMinimumBid(uint256 auctionId) external view returns (uint256);

    /**
     * @notice Query the current highest bidder for this auction
     * It is assumed that there is always 1 winning highest bidder for an auction
     * This is used to ensure that PartyBid cannot outbid itself if it is already winning
     * @dev Called in PartyBid.sol in `bid` at line 241
     * @return highest bidder
     */
    function getCurrentHighestBidder(uint256 auctionId)
        external
        view
        returns (address);

    /**
     * @notice Submit bid to Market contract
     * @dev Called in PartyBid.sol in `bid` at line 259
     */
    function bid(uint256 auctionId, uint256 bidAmount) external;

    /**
     * @notice Determine whether the auction has been finalized
     * Used to check if it is still possible to bid
     * And to determine whether the PartyBid should finalize the auction
     * @dev Called in PartyBid.sol in `bid` at line 247
     * @dev and in `finalize` at line 288
     * @return TRUE if the auction has been finalized
     */
    function isFinalized(uint256 auctionId) external view returns (bool);

    /**
     * @notice Finalize the results of the auction
     * on the Market contract
     * It is assumed  that this operation is performed once for each auction,
     * that after it is done the auction is over and the NFT has been
     * transferred to the auction winner.
     * @dev Called in PartyBid.sol in `finalize` at line 289
     */
    function finalize(uint256 auctionId) external;
}

{
  "optimizer": {
    "enabled": true,
    "runs": 999999
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}