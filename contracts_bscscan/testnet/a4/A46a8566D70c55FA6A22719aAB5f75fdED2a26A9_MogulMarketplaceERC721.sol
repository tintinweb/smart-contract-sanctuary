// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MogulMarketplaceERC721 is
    ERC721Holder,
    AccessControl,
    ReentrancyGuard
{
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    bytes32 public constant ROLE_ADMIN = keccak256("ROLE_ADMIN");
    address payable public treasuryWallet;
    IERC20 stars;
    uint256 public nextListingId;
    uint256 public nextAuctionId;
    uint256 public starsFeeBasisPoint; //4 decimals, applies to auctions and listings. Fees collected are held in contract
    uint256 public ethFeeBasisPoint; //4 decimals, applies to auctions and listings. Fees collected are held in contract
    uint256 public adminEth; //Total Ether available for withdrawal
    uint256 public adminStars; //Total Stars available for withdrawal
    uint256 private highestCommissionBasisPoint; //Used to determine what the maximum fee
    uint256 public starsAvailableForCashBack; //STARS available for cashback
    uint256 public starsCashBackBasisPoint;
    bool public starsAllowed = true;
    bool public ethAllowed = true;

    struct Listing {
        address payable seller;
        address tokenAddress;
        uint256 tokenId;
        uint256 starsPrice;
        uint256 ethPrice;
        bool isStarsListing;
        bool isEthListing;
    }

    struct Auction {
        address payable seller;
        address tokenAddress;
        uint256 tokenId;
        uint256 startingPrice;
        uint256 startTime;
        uint256 endTime;
        uint256 reservePrice;
        bool isStarsAuction;
        Bid highestBid;
    }

    struct Bid {
        address payable bidder;
        uint256 amount;
    }

    struct TokenCommissionInfo {
        address payable artistAddress;
        uint256 commissionBasisPoint; //4 decimals
    }

    EnumerableSet.AddressSet private mogulNFTs;
    EnumerableSet.UintSet private listingIds;
    EnumerableSet.UintSet private auctionIds;

    mapping(uint256 => Listing) public listings;
    mapping(uint256 => Auction) public auctions;
    mapping(address => mapping(uint256 => TokenCommissionInfo))
        public commissions; //NFT address to (token ID to TokenCommissionInfo)

    event ListingCreated(
        uint256 listingId,
        address seller,
        address tokenAddress,
        uint256 tokenId,
        uint256 tokenAmount,
        uint256 starsPrice,
        uint256 ethPrice,
        bool isStarsListing,
        bool isEthListing
    );
    event ListingCancelled(uint256 listingId);
    event ListingPriceChanged(
        uint256 listingId,
        uint256 newPrice,
        bool isStarsPrice
    );
    event AuctionCreated(
        uint256 auctionId,
        address seller,
        address tokenAddress,
        uint256 tokenId,
        uint256 tokenAmount,
        uint256 startingPrice,
        uint256 startTime,
        uint256 endTime,
        uint256 reservePrice,
        bool isStarsAuction
    );
    event SaleMade(
        address buyer,
        uint256 listingId,
        uint256 amount,
        bool isStarsPurchase
    );
    event BidPlaced(
        address bidder,
        uint256 auctionId,
        uint256 amount,
        bool isStarsBid
    );
    event AuctionClaimed(address winner, uint256 auctionId);
    event AuctionCancelled(uint256 auctionId);
    event AuctionReservePriceChanged(
        uint256 auctionId,
        uint256 newReservePrice
    );
    event TokenCommissionSingleAdded(
        address tokenAddress,
        uint256 tokenId,
        address artistAddress,
        uint256 commissionBasisPoint
    );
    event TokenCommissionBulkAdded(
        address tokenAddress,
        uint256[] tokenIds,
        address payable[] artistAddresses,
        uint256[] commissionBasisPoints
    );
    event StarsCashBackBasisPointSet(uint256 newStarsCashBackBasisPoint);
    event StarsFeeBasisPointSet(uint256 newStarsFeeBasisPoint);
    event EthFeeBasisPointSet(uint256 newEthFeeBasisPoint);

    modifier onlyAdmin {
        require(hasRole(ROLE_ADMIN, msg.sender), "Sender is not admin");
        _;
    }

    modifier sellerOrAdmin(address seller) {
        require(
            msg.sender == seller || hasRole(ROLE_ADMIN, msg.sender),
            "Sender is not seller or admin"
        );
        _;
    }

    /**
     * @dev Stores the Stars contract, and allows users with the admin role to
     * grant/revoke the admin role from other users. Stores treasury wallet.
     *
     * Params:
     * starsAddress: the address of the Stars contract
     * _admin: address of the first admin
     * _treasuryWallet: address of treasury wallet
     * _mogulNFTAddress: address of a Mogul NFT
     */
    constructor(
        address starsAddress,
        address _admin,
        address payable _treasuryWallet,
        address _mogulNFTAddress
    ) {
        require(
            _treasuryWallet != address(0),
            "Treasury wallet cannot be 0 address"
        );
        _setupRole(ROLE_ADMIN, _admin);
        _setRoleAdmin(ROLE_ADMIN, ROLE_ADMIN);

        treasuryWallet = _treasuryWallet;
        stars = IERC20(starsAddress);

        mogulNFTs.add(_mogulNFTAddress);
    }

    //Allows contract to inherit both ERC1155Receiver and AccessControl
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    //Get number of listings
    function getNumListings() external view returns (uint256) {
        return listingIds.length();
    }

    /**
     * @dev Get listing ID at index
     *
     * Params:
     * indices: indices of IDs
     */
    function getListingIds(uint256[] memory indices)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory output = new uint256[](indices.length);
        for (uint256 i = 0; i < indices.length; i++) {
            output[i] = listingIds.at(indices[i]);
        }
        return output;
    }

    /**
     * @dev Get listing correlated to index
     *
     * Params:
     * indices: indices of IDs
     */
    function getListingsAtIndices(uint256[] memory indices)
        external
        view
        returns (Listing[] memory)
    {
        Listing[] memory output = new Listing[](indices.length);
        for (uint256 i = 0; i < indices.length; i++) {
            output[i] = listings[listingIds.at(indices[i])];
        }
        return output;
    }

    //Get number of auctions
    function getNumAuctions() external view returns (uint256) {
        return auctionIds.length();
    }

    /**
     * @dev Get auction ID at index
     *
     * Params:
     * indices: indices of IDs
     */
    function getAuctionIds(uint256[] memory indices)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory output = new uint256[](indices.length);
        for (uint256 i = 0; i < indices.length; i++) {
            output[i] = auctionIds.at(indices[i]);
        }
        return output;
    }

    /**
     * @dev Get auction correlated to index
     *
     * Params:
     * indices: indices of IDs
     */
    function getAuctionsAtIndices(uint256[] memory indices)
        external
        view
        returns (Auction[] memory)
    {
        Auction[] memory output = new Auction[](indices.length);
        for (uint256 i = 0; i < indices.length; i++) {
            output[i] = auctions[auctionIds.at(indices[i])];
        }
        return output;
    }

    /**
     * @dev Get commission info for array of tokens
     *
     * Params:
     * NFTAddress: address of NFT
     * tokenIds: token IDs
     */
    function getCommissionInfoForTokens(
        address NFTAddress,
        uint256[] memory tokenIds
    ) external view returns (TokenCommissionInfo[] memory) {
        TokenCommissionInfo[] memory output =
            new TokenCommissionInfo[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            output[i] = commissions[NFTAddress][tokenIds[i]];
        }
        return output;
    }

    /**
     * @dev Create a new listing
     *
     * Params:
     * tokenAddress: address of token to list
     * tokenId: id of token
     * starsPrice: listing STARS price
     * ethPrice: listing ETH price
     * isStarsListing: whether or not the listing can be sold for STARS
     * isEthListing: whether or not the listing can be sold for ETH
     *
     * Requirements:
     * - Listings of given currencies are allowed
     * - Price of given currencies are not 0
     * - mogulNFTs contains tokenAddress
     */
    function createListing(
        address tokenAddress,
        uint256 tokenId,
        uint256 starsPrice,
        uint256 ethPrice,
        bool isStarsListing,
        bool isEthListing
    ) public nonReentrant() {
        require(
            mogulNFTs.contains(tokenAddress),
            "Only Mogul NFTs can be listed"
        );
        if (isStarsListing) {
            require(starsPrice != 0, "Price cannot be 0");
        }
        if (isEthListing) {
            require(ethPrice != 0, "Price cannot be 0");
        }

        if (isStarsListing) {
            require(starsAllowed, "STARS listings are not allowed");
        }
        if (isEthListing) {
            require(ethAllowed, "ETH listings are not allowed");
        }

        IERC721 token = IERC721(tokenAddress);
        token.safeTransferFrom(msg.sender, address(this), tokenId);
        uint256 listingId = generateListingId();
        listings[listingId] = Listing(
            payable(msg.sender),
            tokenAddress,
            tokenId,
            starsPrice,
            ethPrice,
            isStarsListing,
            isEthListing
        );
        listingIds.add(listingId);

        emit ListingCreated(
            listingId,
            msg.sender,
            tokenAddress,
            tokenId,
            1,
            starsPrice,
            ethPrice,
            isStarsListing,
            isEthListing
        );
    }

    /**
     * @dev Batch create new listings
     *
     * Params:
     * tokenAddresses: addresses of tokens to list
     * tokenIds: id of each token
     * starsPrices: STARS price of each listing
     * ethPrices: ETH price of each listing
     * areStarsListings: whether or not each listing can be sold for Stars
     * areEthListings: whether or not each listing can be sold for ETH
     *
     * Requirements:
     * - All inputs are the same length
     */
    function batchCreateListings(
        address[] calldata tokenAddresses,
        uint256[] calldata tokenIds,
        uint256[] calldata starsPrices,
        uint256[] calldata ethPrices,
        bool[] memory areStarsListings,
        bool[] memory areEthListings
    ) external onlyAdmin {
        require(
            tokenAddresses.length == tokenIds.length &&
                tokenIds.length == starsPrices.length &&
                starsPrices.length == ethPrices.length &&
                ethPrices.length == areStarsListings.length &&
                areStarsListings.length == areEthListings.length,
            "Incorrect input lengths"
        );
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            createListing(
                tokenAddresses[i],
                tokenIds[i],
                starsPrices[i],
                ethPrices[i],
                areStarsListings[i],
                areEthListings[i]
            );
        }
    }

    /**
     * @dev Cancel a listing
     *
     * Params:
     * listingId: listing ID
     */
    function cancelListing(uint256 listingId)
        public
        sellerOrAdmin(listings[listingId].seller)
        nonReentrant()
    {
        require(listingIds.contains(listingId), "Listing does not exist");
        Listing storage listing = listings[listingId];

        listingIds.remove(listingId);

        IERC721 token = IERC721(listing.tokenAddress);
        token.safeTransferFrom(address(this), listing.seller, listing.tokenId);
        emit ListingCancelled(listingId);
    }

    function batchCancelListing(uint256[] calldata _listingIds)
        external
        onlyAdmin
    {
        for (uint256 i = 0; i < _listingIds.length; i++) {
            cancelListing(_listingIds[i]);
        }
    }

    /**
     * @dev Change price of a listing
     *
     * Params:
     * listingId: listing ID
     * newPrice: price to change to
     * isStarsPrice: whether or not the price being changed is in STARS
     *
     * Requirements:
     * - newPrice is not 0
     */
    function changeListingPrice(
        uint256 listingId,
        uint256 newPrice,
        bool isStarsPrice
    ) external sellerOrAdmin(listings[listingId].seller) {
        require(listingIds.contains(listingId), "Listing does not exist.");

        require(newPrice != 0, "Price cannot be 0");
        if (isStarsPrice) {
            listings[listingId].starsPrice = newPrice;
        } else {
            listings[listingId].ethPrice = newPrice;
        }

        emit ListingPriceChanged(listingId, newPrice, isStarsPrice);
    }

    /**
     * @dev Buy a token
     *
     * Params:
     * listingId: listing ID
     * amount: amount tokens to buy
     * expectedPrice: expected price of purchase
     * isStarsPurchase: whether or not the user is buying with STARS
     */
    function buyTokens(
        uint256 listingId,
        uint256 expectedPrice,
        bool isStarsPurchase
    ) external payable nonReentrant() {
        require(listingIds.contains(listingId), "Listing does not exist.");

        Listing storage listing = listings[listingId];

        if (isStarsPurchase) {
            require(listing.isStarsListing, "Listing does not accept STARS");
            uint256 fullAmount = listing.starsPrice;
            require(fullAmount == expectedPrice, "Incorrect expected price");

            uint256 fee = (fullAmount * starsFeeBasisPoint) / 10000;
            uint256 commission =
                (fullAmount *
                    commissions[listing.tokenAddress][listing.tokenId]
                        .commissionBasisPoint) / 10000;

            if (fee != 0) {
                stars.safeTransferFrom(msg.sender, address(this), fee);
            }

            if (
                commissions[listing.tokenAddress][listing.tokenId]
                    .artistAddress != address(0)
            ) {
                stars.safeTransferFrom(
                    msg.sender,
                    commissions[listing.tokenAddress][listing.tokenId]
                        .artistAddress,
                    commission
                );
            }

            stars.safeTransferFrom(
                msg.sender,
                listing.seller,
                fullAmount - fee - commission
            );

            if (starsCashBackBasisPoint != 0) {
                uint256 totalStarsCashBack =
                    (fullAmount * starsCashBackBasisPoint) / 10000;

                if (starsAvailableForCashBack >= totalStarsCashBack) {
                    starsAvailableForCashBack -= totalStarsCashBack;
                    stars.safeTransfer(msg.sender, totalStarsCashBack);
                }
            }

            adminStars += fee;
        } else {
            require(listing.isEthListing, "Listing does not accept ETH");
            uint256 fullAmount = listing.ethPrice;
            require(fullAmount == expectedPrice, "Incorrect expected price");

            uint256 fee = (fullAmount * ethFeeBasisPoint) / 10000;
            uint256 commission =
                (fullAmount *
                    commissions[listing.tokenAddress][listing.tokenId]
                        .commissionBasisPoint) / 10000;

            require(msg.value == fullAmount, "Incorrect transaction value");

            (bool success, ) =
                listing.seller.call{value: fullAmount - fee - commission}("");
            require(success, "Payment failure");

            if (
                commissions[listing.tokenAddress][listing.tokenId]
                    .artistAddress != address(0)
            ) {
                (success, ) = commissions[listing.tokenAddress][listing.tokenId]
                    .artistAddress
                    .call{value: commission}("");

                require(success, "Payment failure");
            }

            adminEth += fee;
        }

        listingIds.remove(listingId);

        IERC721 token = IERC721(listing.tokenAddress);
        token.safeTransferFrom(address(this), msg.sender, listing.tokenId);

        emit SaleMade(msg.sender, listingId, 1, isStarsPurchase);
    }

    /**
     * @dev Create an auction
     *
     * Params:
     * tokenAddress: address of token
     * tokenId: token ID
     * startingPrice: starting price for bids
     * startTime: auction start time
     * endTime: auction end time
     * reservePrice: reserve price
     * isStarsAuction: whether or not Auction is in Stars
     */
    function createAuction(
        address tokenAddress,
        uint256 tokenId,
        uint256 startingPrice,
        uint256 startTime,
        uint256 endTime,
        uint256 reservePrice,
        bool isStarsAuction
    ) public nonReentrant() {
        require(startTime < endTime, "End time must be after start time");
        require(
            startTime > block.timestamp,
            "Auction must start in the future"
        );
        require(
            mogulNFTs.contains(tokenAddress),
            "Only Mogul NFTs can be listed"
        );
        if (isStarsAuction) {
            require(starsAllowed, "STARS auctions are not allowed");
        } else {
            require(ethAllowed, "ETH auctions are not allowed.");
        }

        IERC721 token = IERC721(tokenAddress);
        token.safeTransferFrom(msg.sender, address(this), tokenId);

        uint256 auctionId = generateAuctionId();
        auctions[auctionId] = Auction(
            payable(msg.sender),
            tokenAddress,
            tokenId,
            startingPrice,
            startTime,
            endTime,
            reservePrice,
            isStarsAuction,
            Bid(payable(msg.sender), 0)
        );
        auctionIds.add(auctionId);
        emit AuctionCreated(
            auctionId,
            payable(msg.sender),
            tokenAddress,
            tokenId,
            1,
            startingPrice,
            startTime,
            endTime,
            reservePrice,
            isStarsAuction
        );
    }

    /**
     * @dev Batch create new auctions
     *
     * Params:
     * tokenAddresses: addresses of tokens to auction
     * tokenIds: id of each token
     * startingPrices: starting price of each auction
     * startTimes: start time of each auction
     * endTimes: end time of each auction
     * reservePrices: reserve price of each auction
     * areStarsAuctions: whether or not each auction is in Stars
     *
     * Requirements:
     * - All inputs are the same length
     */
    function batchCreateAuctions(
        address[] calldata tokenAddresses,
        uint256[] calldata tokenIds,
        uint256[] calldata startingPrices,
        uint256[] memory startTimes,
        uint256[] memory endTimes,
        uint256[] memory reservePrices,
        bool[] memory areStarsAuctions
    ) external onlyAdmin {
        require(
            tokenAddresses.length == tokenIds.length &&
                tokenIds.length == startingPrices.length &&
                startingPrices.length == startTimes.length &&
                startTimes.length == endTimes.length &&
                endTimes.length == reservePrices.length &&
                reservePrices.length == areStarsAuctions.length,
            "Incorrect input lengths"
        );
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            createAuction(
                tokenAddresses[i],
                tokenIds[i],
                startingPrices[i],
                startTimes[i],
                endTimes[i],
                reservePrices[i],
                areStarsAuctions[i]
            );
        }
    }

    /**
     * @dev Place a bid and refund the previous highest bidder
     *
     * Params:
     * auctionId: auction ID
     * isStarsBid: true if bid is in Stars, false if it's in eth
     * amount: amount of bid
     *
     * Requirements:
     * Bid is higher than the previous highest bid
     */
    function placeBid(uint256 auctionId, uint256 amount)
        external
        payable
        nonReentrant()
    {
        require(auctionIds.contains(auctionId), "Auction does not exist.");

        Auction storage auction = auctions[auctionId];
        require(
            block.timestamp >= auction.startTime,
            "Auction has not started yet"
        );

        require(block.timestamp <= auction.endTime, "Auction has ended");

        require(
            amount > auction.highestBid.amount,
            "Bid is lower than highest bid"
        );

        require(
            amount > auction.startingPrice,
            "Bid must be higher than starting price"
        );

        if (auction.isStarsAuction) {
            stars.safeTransferFrom(msg.sender, address(this), amount);
            stars.safeTransfer(
                auction.highestBid.bidder,
                auction.highestBid.amount
            );
            auction.highestBid = Bid(payable(msg.sender), amount);
        } else {
            require(amount == msg.value, "Amount does not match message value");
            (bool success, ) =
                auction.highestBid.bidder.call{
                    value: auction.highestBid.amount
                }("");
            require(success, "Payment failure");
            auction.highestBid = Bid(payable(msg.sender), amount);
        }

        emit BidPlaced(msg.sender, auctionId, amount, auction.isStarsAuction);
    }

    /**
     * @dev End auctions and distributes tokens to the winner, bid to the
     * seller, and fees to the contract. If the reserve price was not met, only
     * the seller or admin can call this function.
     *
     * Params:
     * auctionId: auction ID
     */
    function claimAuction(uint256 auctionId) public nonReentrant() {
        require(auctionIds.contains(auctionId), "Auction does not exist");
        Auction memory auction = auctions[auctionId];
        require(block.timestamp >= auction.endTime, "Auction is ongoing");

        if (msg.sender != auction.seller && !hasRole(ROLE_ADMIN, msg.sender)) {
            require(
                auction.highestBid.amount >= auction.reservePrice,
                "Highest bid did not meet the reserve price."
            );
        }

        address winner;
        uint256 fee;
        if (auction.isStarsAuction) {
            fee = (auction.highestBid.amount * starsFeeBasisPoint) / 10000;
        } else {
            fee = (auction.highestBid.amount * ethFeeBasisPoint) / 10000;
        }
        uint256 commission =
            (auction.highestBid.amount *
                commissions[auction.tokenAddress][auction.tokenId]
                    .commissionBasisPoint) / 10000;

        winner = auction.highestBid.bidder;
        if (auction.isStarsAuction) {
            stars.safeTransfer(
                auction.seller,
                auction.highestBid.amount - fee - commission
            );

            if (
                commissions[auction.tokenAddress][auction.tokenId]
                    .artistAddress != address(0)
            ) {
                stars.safeTransfer(
                    commissions[auction.tokenAddress][auction.tokenId]
                        .artistAddress,
                    commission
                );
            }

            if (starsCashBackBasisPoint != 0) {
                uint256 totalStarsCashBack =
                    (auction.highestBid.amount * starsCashBackBasisPoint) /
                        10000;

                if (starsAvailableForCashBack >= totalStarsCashBack) {
                    starsAvailableForCashBack -= totalStarsCashBack;
                    stars.safeTransfer(
                        auction.highestBid.bidder,
                        totalStarsCashBack
                    );
                }
            }

            adminStars += fee;
        } else {
            (bool success, ) =
                auction.seller.call{
                    value: auction.highestBid.amount - fee - commission
                }("");

            require(success, "Payment failure");

            if (
                commissions[auction.tokenAddress][auction.tokenId]
                    .artistAddress != address(0)
            ) {
                (success, ) = commissions[auction.tokenAddress][auction.tokenId]
                    .artistAddress
                    .call{value: commission}("");

                require(success, "Payment failure");
            }

            adminEth += fee;
        }

        IERC721(auction.tokenAddress).safeTransferFrom(
            address(this),
            winner,
            auction.tokenId
        );
        auctionIds.remove(auctionId);
        emit AuctionClaimed(winner, auctionId);
    }

    function batchClaimAuction(uint256[] calldata _auctionIds)
        external
        onlyAdmin
    {
        for (uint256 i = 0; i < _auctionIds.length; i++) {
            claimAuction(_auctionIds[i]);
        }
    }

    /**
     * @dev Cancel auction and refund bidders
     *
     * Params:
     * auctionId: auction ID
     */
    function cancelAuction(uint256 auctionId)
        public
        nonReentrant()
        sellerOrAdmin(auctions[auctionId].seller)
    {
        require(auctionIds.contains(auctionId), "Auction does not exist");
        Auction memory auction = auctions[auctionId];

        require(
            block.timestamp <= auction.endTime ||
                auction.highestBid.amount < auction.reservePrice,
            "Cannot cancel auction after it has ended unless the highest bid did not meet the reserve price."
        );

        IERC721(auction.tokenAddress).safeTransferFrom(
            address(this),
            auction.seller,
            auction.tokenId
        );

        if (auction.isStarsAuction) {
            stars.safeTransfer(
                auction.highestBid.bidder,
                auction.highestBid.amount
            );
        } else {
            (bool success, ) =
                auction.highestBid.bidder.call{
                    value: auction.highestBid.amount
                }("");
            require(success, "Payment failure");
        }

        auctionIds.remove(auctionId);
        emit AuctionCancelled(auctionId);
    }

    function batchCancelAuction(uint256[] calldata _auctionIds)
        external
        onlyAdmin
    {
        for (uint256 i = 0; i < _auctionIds.length; i++) {
            cancelAuction(_auctionIds[i]);
        }
    }

    function changeReservePrice(uint256 auctionId, uint256 newReservePrice)
        external
        nonReentrant()
        sellerOrAdmin(auctions[auctionId].seller)
    {
        require(auctionIds.contains(auctionId), "Auction does not exist");
        auctions[auctionId].reservePrice = newReservePrice;

        emit AuctionReservePriceChanged(auctionId, newReservePrice);
    }

    //Generate ID for next listing
    function generateListingId() internal returns (uint256) {
        return nextListingId++;
    }

    //Generate ID for next auction
    function generateAuctionId() internal returns (uint256) {
        return nextAuctionId++;
    }

    //Withdraw ETH to treasury wallet
    function withdrawETH() external onlyAdmin {
        (bool success, ) = treasuryWallet.call{value: adminEth}("");
        require(success, "Payment failure");
        adminEth = 0;
    }

    //Withdraw Stars to treasury wallet
    function withdrawStars() external onlyAdmin {
        stars.safeTransfer(treasuryWallet, adminStars);
        adminStars = 0;
    }

    //Add to list of valid Mogul NFTs
    function addMogulNFTAddress(address _mogulNFTAddress) external onlyAdmin {
        mogulNFTs.add(_mogulNFTAddress);
    }

    //Remove from list of valid Mogul NFTs
    function removeMogulNFTAddress(address _mogulNFTAddress)
        external
        onlyAdmin
    {
        mogulNFTs.remove(_mogulNFTAddress);
    }

    //Set STARS fee (applies to listings and auctions);
    function setStarsFee(uint256 _feeBasisPoint) external onlyAdmin {
        require(
            _feeBasisPoint + highestCommissionBasisPoint < 10000,
            "Fee plus commission must be less than 100%"
        );
        starsFeeBasisPoint = _feeBasisPoint;
        emit StarsFeeBasisPointSet(_feeBasisPoint);
    }

    //Set ETH fee (applies to listings and auctions);
    function setEthFee(uint256 _feeBasisPoint) external onlyAdmin {
        require(
            _feeBasisPoint + highestCommissionBasisPoint < 10000,
            "Fee plus commission must be less than 100%"
        );
        ethFeeBasisPoint = _feeBasisPoint;
        emit EthFeeBasisPointSet(_feeBasisPoint);
    }

    function setStarsCashBack(uint256 _starsCashBackBasisPoint)
        external
        onlyAdmin
    {
        starsCashBackBasisPoint = _starsCashBackBasisPoint;
    }

    //Set commission info for one token
    function setCommission(
        address NFTAddress,
        uint256 tokenId,
        address payable artistAddress,
        uint256 commissionBasisPoint
    ) external onlyAdmin {
        if (commissionBasisPoint > highestCommissionBasisPoint) {
            require(
                commissionBasisPoint + starsFeeBasisPoint < 10000 &&
                    commissionBasisPoint + ethFeeBasisPoint < 10000,
                "Fee plus commission must be less than 100%"
            );

            highestCommissionBasisPoint = commissionBasisPoint;
        }

        commissions[NFTAddress][tokenId] = TokenCommissionInfo(
            artistAddress,
            commissionBasisPoint
        );

        emit TokenCommissionSingleAdded(
            NFTAddress,
            tokenId,
            artistAddress,
            commissionBasisPoint
        );
    }

    //Set commission info for multiple tokens
    function setCommissionBulk(
        address NFTAddress,
        uint256[] memory tokenIds,
        address payable[] memory artistAddresses,
        uint256[] memory commissionBasisPoints
    ) external onlyAdmin {
        require(
            tokenIds.length == artistAddresses.length &&
                artistAddresses.length == commissionBasisPoints.length,
            "Invalid input lengths"
        );

        uint256 higherFeeBasisPoint;
        if (starsFeeBasisPoint > ethFeeBasisPoint) {
            higherFeeBasisPoint = starsFeeBasisPoint;
        } else {
            higherFeeBasisPoint = ethFeeBasisPoint;
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (commissionBasisPoints[i] > highestCommissionBasisPoint) {
                require(
                    commissionBasisPoints[i] + higherFeeBasisPoint < 10000,
                    "Fee plus commission must be less than 100%"
                );

                highestCommissionBasisPoint = commissionBasisPoints[i];
            }
            commissions[NFTAddress][tokenIds[i]] = TokenCommissionInfo(
                artistAddresses[i],
                commissionBasisPoints[i]
            );
        }

        emit TokenCommissionBulkAdded(
            NFTAddress,
            tokenIds,
            artistAddresses,
            commissionBasisPoints
        );
    }

    //Set whether or not creating new STARS listings and Auctions are allowed
    function setStarsAllowed(bool _starsAllowed) external onlyAdmin {
        starsAllowed = _starsAllowed;
    }

    //Set whether or not creating new ETH listings and Auctions are allowed
    function setEthAllowed(bool _ethAllowed) external onlyAdmin {
        ethAllowed = _ethAllowed;
    }

    function depositStarsForCashBack(uint256 amount) public {
        stars.safeTransferFrom(msg.sender, address(this), amount);
        starsAvailableForCashBack += amount;
    }

    function withdrawStarsForCashBack(uint256 amount)
        external
        onlyAdmin
        nonReentrant()
    {
        require(
            amount <= starsAvailableForCashBack,
            "Withdraw amount exceeds available balance"
        );
        starsAvailableForCashBack -= amount;
        stars.safeTransfer(treasuryWallet, amount);
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

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

  /**
   * @dev Implementation of the {IERC721Receiver} interface.
   *
   * Accepts all token transfers.
   * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
   */
contract ERC721Holder is IERC721Receiver {

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping (address => bool) members;
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
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(account), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )));
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
    function renounceRole(bytes32 role, address account) public virtual override {
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
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

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

pragma solidity ^0.8.0;

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

    constructor () {
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

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}