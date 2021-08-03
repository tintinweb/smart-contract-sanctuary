/**
 *Submitted for verification at Etherscan.io on 2021-08-02
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

// EXPERIMENTAL: DO NOT USE!!!!
// EXPERIMENTAL: DO NOT USE!!!!
// EXPERIMENTAL: DO NOT USE!!!!
// EXPERIMENTAL: DO NOT USE!!!!
// EXPERIMENTAL: DO NOT USE!!!!
// EXPERIMENTAL: DO NOT USE!!!!

interface IFoliaMarket {
    function minBid() external view returns(uint256);
    function nftAddress() external view returns(address);
    function auctions(uint256 tokenId) external view returns(Auction memory);

    struct Auction {
        bool exists;
        bool paused;
        uint256 amount;
        uint256 tokenId;
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

interface IMarketWrapper {
    function auctionExists(uint256 auctionId) external view returns (bool);
    function auctionIdMatchesToken(
        uint256 auctionId,
        address nftContract,
        uint256 tokenId
    ) external view returns (bool);
    function getMinimumBid(uint256 auctionId) external view returns (uint256);
    function getCurrentHighestBidder(uint256 auctionId)
        external
        view
        returns (address);
    function bid(uint256 auctionId, uint256 bidAmount) external;
    function isFinalized(uint256 auctionId) external view returns (bool);
    function finalize(uint256 auctionId) external;
}

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address);
}


/**
 * @title FoliaMarketWrapper
 * @author Billy Rennekamp
 * @notice MarketWrapper contract implementing IMarketWrapper interface
 * according to the logic of Folia's NFT Market
 * Original Folia NFT Market code: https://etherscan.io/address/0xe708fffbe607def8a2be9d35a876f0ebe431dee7#code
 */
contract ExodusMarketWrapperBeta is IMarketWrapper {
    // ============ Internal Immutables ============

    IFoliaMarket internal immutable market;
    address payable public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "must be owner");
        _;
    }

    // ======== Constructor =========

    constructor(address _foliaMarket) {
        market = IFoliaMarket(_foliaMarket);
        owner = payable(msg.sender);
    }


    // ======== External Functions =========
    function emergencyExecute(
        address targetAddress,
        bytes calldata targetCallData
    ) public onlyOwner returns (bool) {
        (bool success, ) = targetAddress.call(targetCallData);
        return success;
    }
    
    function emergencyWithdrawEth() public onlyOwner {
        owner.transfer(address(this).balance);
    }
    

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
        // The auction contract can only be used with one NFT contract
        // the token ID is used as the auction ID.
        return auctionId == tokenId && IERC721(nftContract).ownerOf(tokenId) == address(market);
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