// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.9;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./BadassMarketplace.sol";


contract BabyBadassMarket is
    BadassMarketplace,
    Initializable,
    AccessControlUpgradeable,
    ReentrancyGuard
{
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    // ############
    // Initializer
    // ############

    function initialize(IBEP20 _purchaseToken,  BabyBadasses _badAssToken, address _taxRecipient, address _admin)
        public
        initializer
    {
        defaultTax = 2;
        defaultRewardPercent = 5;
        defaultMinterPercent = 5;

        purchaseToken = _purchaseToken;
        badAssToken = _badAssToken;

        taxRecipient = _taxRecipient;
        admin = _admin;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // ############
    // State
    // ############
    address public taxRecipient; //fees collection
    address private admin;
    IBEP20 public purchaseToken;
    BabyBadasses public badAssToken;

    uint256 public defaultTax;
    uint256 public defaultRewardPercent;
    uint256 public defaultMinterPercent;
    uint256 public totalVolume;

    bool private _isMarketLive;
    uint256 private _actionTimeOutRangeMin = 1800; // 30 mins
    uint256 private _actionTimeOutRangeMax = 31536000; // One year - This can extend by owner is contract is working smoothly

    mapping(address => ERC721Market) private listedTokenIDs;

    // UNUSED; KEPT FOR UPGRADEABILITY PROXY COMPATIBILITY
    mapping(address => bool) public isUserBanned;

    // keeps redeemed rewards
    EnumerableSet.AddressSet allowedPaymentTokens;
    uint256 public rewardsBalance;
    mapping(address => uint256) public rewardsWBalance;

    uint256 public totalDividend;
    mapping(address => uint256) public totalWDividend;

    mapping(uint256 => uint256) totalReceivedReward;
    mapping(uint256 => mapping(address => uint256)) totalReceivedWReward;

    // ############
    // Modifiers
    // ############
    modifier isMarketLive() {
        require(_isMarketLive, "BabyBadasses: MarketPlace is not active");
        _;
    }

    modifier isValidTimestamp(uint256 expireTimestamp) {
        require(
            expireTimestamp - block.timestamp >= _actionTimeOutRangeMin,
            "Please enter a longer period of time"
        );
        require(
            expireTimestamp - block.timestamp <= _actionTimeOutRangeMax,
            "Please enter a shorter period of time"
        );
        _;
    }


    modifier restricted() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "BabyBadasses: must have admin role");
        _;
    }

    modifier isListed(IERC721 _tokenAddress, uint256 id) {
        require(
            listedTokenIDs[address(_tokenAddress)].tokenIdWithListing.contains(id),
            "BabyBadasses: Error, token ID is not listed"
        );
        _;
    }

    modifier isBadAssOwnerOrAdmin(uint256 id) {
        require(
            badAssToken.ownerOf(id) == msg.sender || 
                hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "BabyBadasses: Error, Is not owner of token ID"
        );
        _;
    }

    modifier isSeller(IERC721 _tokenAddress, uint256 id) {
        require(
            listedTokenIDs[address(_tokenAddress)].listings[id].seller == msg.sender,
            "BabyBadasses: Error, Access denied"
        );
        _;
    }

    modifier isSellerOrAdmin(IERC721 _tokenAddress, uint256 id) {
        require(
            listedTokenIDs[address(_tokenAddress)].listings[id].seller == msg.sender ||
                hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Access denied"
        );
        _;
    }

    modifier userNotBanned() {
        require(isUserBanned[msg.sender] == false, "BabyBadasses: Forbidden access");
        _;
    }

    modifier isAllowedToken(IERC721 _tokenAddress) {
        require (
            listedTokenIDs[address(_tokenAddress)].isNotBanned,
            "BabyBadasses: This type of NFT may not be traded here."
        );
        _;
    }

    // ############
    // Views
    // ############

    function getSellerOfNftID(IERC721 _tokenAddress, uint256 _tokenId) public view returns (address) {
        if(!listedTokenIDs[address(_tokenAddress)].tokenIdWithListing.contains(_tokenId)) {
            return address(0);
        }

        return listedTokenIDs[address(_tokenAddress)].listings[_tokenId].seller;
    }

    function getListingIDs(IERC721 _tokenAddress)
        public
        view
        returns (uint256[] memory)
    {
        EnumerableSet.UintSet storage set = listedTokenIDs[address(_tokenAddress)].tokenIdWithListing;
        uint256[] memory tokens = new uint256[](set.length());

        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i] = set.at(i);
        }
        return tokens;
    }

    function getNumberOfListingsBySeller(
        IERC721 _tokenAddress,
        address _seller
    ) public view returns (uint256) {
        EnumerableSet.UintSet storage listedTokens = listedTokenIDs[address(_tokenAddress)].tokenIdWithListing;

        uint256 amount = 0;
        for (uint256 i = 0; i < listedTokens.length(); i++) {
            if (
                listedTokenIDs[address(_tokenAddress)].listings[i].seller == _seller
            ) amount++;
        }

        return amount;
    }

    function getListingIDsBySeller(IERC721 _tokenAddress, address _seller)
        public
        view
        returns (uint256[] memory tokens)
    {
        // NOTE: listedTokens is enumerated twice (once for length calc, once for getting token IDs)
        uint256 amount = getNumberOfListingsBySeller(_tokenAddress, _seller);
        tokens = new uint256[](amount);

        EnumerableSet.UintSet storage listedTokens = listedTokenIDs[address(_tokenAddress)].tokenIdWithListing;

        uint256 index = 0;
        for (uint256 i = 0; i < listedTokens.length(); i++) {
            uint256 id = listedTokens.at(i);
            if (listedTokenIDs[address(_tokenAddress)].listings[id].seller == _seller)
                tokens[index++] = id;
        }
    }


    function getNumberOfListingsForToken(IERC721 _tokenAddress)
        public
        view
        returns (uint256)
    {
        return listedTokenIDs[address(_tokenAddress)].tokenIdWithListing.length();
    }

    function getSellerPrice(IERC721 _tokenAddress, uint256 _id)
        public
        view
        returns (uint256)
    {
        return listedTokenIDs[address(_tokenAddress)].listings[_id].price;
    }

    function getListing(IERC721 _tokenAddress, uint256 _id)
        public
        view
        isListed(_tokenAddress, _id)
        returns (address seller,  uint256 price, uint256 endTimestamp)
    {
        Listing memory listing = listedTokenIDs[address(_tokenAddress)].listings[_id];
        return (listing.seller, listing.price, listing.endTimestamp);
    }

    function getListingSlice(IERC721 _tokenAddress, uint256 start, uint256 length)
        public
        view
        returns (Listing[] memory listings)
    {
        uint256 listingsCount = getNumberOfListingsForToken(_tokenAddress);

        if (start < listingsCount && length > 0) {
            uint256 querySize = length;
            if ((start + length) > listingsCount) {
                querySize = listingsCount - start;
            }
            listings = new Listing[](querySize);
            for (uint256 i = 0; i < querySize; i++) {
                uint256 tokenId = listedTokenIDs[address(_tokenAddress)]
                    .tokenIdWithListing
                    .at(i + start);
                Listing memory listing = listedTokenIDs[address(_tokenAddress)].listings[
                    tokenId
                ];
                if (_isListingValid(_tokenAddress, listing)) {
                    listings[i] = listing;
                }
            }
        }
    }

    function computePrice(IERC721 _tokenAddress, uint256 _id) 
      public
      view
      userNotBanned
      isListed(_tokenAddress, _id)
      returns (uint256 rewardsFee, uint256 minterFee, uint256 marketFee, uint256 netSale) 
    {
        Listing memory listing = listedTokenIDs[address(_tokenAddress)].listings[_id];
        require(isUserBanned[listing.seller] == false, "Banned seller");
        address minter = _getMinter(_tokenAddress, _id);
        return _computePrice(_tokenAddress, listing.price, minter);
    }

    function getBidderTokenBid(
        IERC721 _tokenAddress,
        uint256 _id,
        address _bidder
    ) public view returns (Bid memory validBid) {
        Bid memory bid = listedTokenIDs[address(_tokenAddress)].bids[_id].bids[_bidder];
        if (_isBidValid(_tokenAddress, bid)) {
            validBid = bid;
        }
    }

    function getTokenTypeDetail(
        IERC721 _tokenAddress
    ) public view returns (
        uint256 badassPercent,
        uint256 minterPercent,
        uint256 taxPercent,
        bool isFreeTax,
        bool isFreeRewards,
        IBEP20 payToken
    ){
        ERC721Market storage tokenType = listedTokenIDs[address(_tokenAddress)];

        badassPercent = tokenType.badassPercent;
        minterPercent = tokenType.minterPercent;
        taxPercent = tokenType.taxPercent;
        isFreeTax = tokenType.isFreeTax;
        isFreeRewards = tokenType.isFreeRewards;
        payToken = tokenType.purchaseToken;
        
        return (badassPercent, minterPercent, taxPercent, isFreeTax, isFreeRewards, payToken);
    }


    // ############
    // Mutative
    // ############
    function setMarketStatus(bool _isLive) public restricted {
        _isMarketLive = _isLive;
    }

    function addListing(
        IERC721 _tokenAddress,
        uint256 _id,
        uint256 _price,
        uint256 _endTimestamp,
        address _minter
    )
        public
        isMarketLive
        isAllowedToken(_tokenAddress)
    {
        Listing memory listing = Listing(_id,
                                msg.sender,
                                _minter,
                                _price,
                                _endTimestamp);
        require(
            _isListingValid(_tokenAddress, listing),
            "BabyBadasses: Listing is not valid"
        );

        listedTokenIDs[address(_tokenAddress)].listings[_id] = listing;
        listedTokenIDs[address(_tokenAddress)].tokenIdWithListing.add(_id);

        emit ListingAdded(_tokenAddress, _id, listing);
    }

    function cancelListing(IERC721 _tokenAddress, uint256 _id)
        public
        isMarketLive
        userNotBanned
        isSellerOrAdmin(_tokenAddress, _id)
    {
        Listing memory listing = listedTokenIDs[address(_tokenAddress)].listings[_id];

        _removeListing(_tokenAddress, _id);

        emit ListingRemoved(_tokenAddress, _id, listing);
    }

    function changeListingPrice(
        IERC721 _tokenAddress,
        uint256 _id,
        uint256 _newPrice
    )
        public
        isMarketLive
        userNotBanned
        isSeller(_tokenAddress, _id)
    {
        listedTokenIDs[address(_tokenAddress)].listings[_id].price = _newPrice;
        emit ListingPriceChange(
            _tokenAddress,
            _id,
            _newPrice
        );
    }

    function purchaseListing(
        IERC721 _tokenAddress,
        uint256 _id
    ) public 
      isMarketLive
      userNotBanned
      payable
      nonReentrant
    {
        Listing memory listing = listedTokenIDs[address(_tokenAddress)].listings[_id];
        IBEP20 payToken = listedTokenIDs[address(_tokenAddress)].purchaseToken;
        require(address(payToken) == address(0));
        require(_isListingValid(_tokenAddress, listing),  "Token is not for sale");
        require(isUserBanned[listing.seller] == false, "Banned seller");
        require(msg.value == listing.price, "Please submit the asking price in order to complete the purchase");
        require(
            !_isTokenOwner(_tokenAddress, _id, msg.sender),
            "Token owner can't buy their own token"
        );

        totalVolume += msg.value;
        _removeListing(_tokenAddress, _id);
        _removeBidOfBidder(_tokenAddress, _id, msg.sender);
        
        address minter = _getMinter(_tokenAddress, _id);
        _processPayment(_tokenAddress, minter, listing.seller, listing.price);
        _tokenAddress.safeTransferFrom(listing.seller, msg.sender, _id);

        emit ListingBought(
            _tokenAddress,
            _id,
            msg.sender,
            listing.price,
            listing
        );
    }

    function purchaseListingToken(
        IERC721 _tokenAddress,
        uint256 _id
    ) public 
      isMarketLive
      userNotBanned
      nonReentrant
    {
        Listing memory listing = listedTokenIDs[address(_tokenAddress)].listings[_id];
        IBEP20 payToken = listedTokenIDs[address(_tokenAddress)].purchaseToken;
        require(address(payToken) != address(0));
        require(_isListingValid(_tokenAddress, listing),  "Token is not for sale");
        require(isUserBanned[listing.seller] == false, "Banned seller");
        require(
            !_isTokenOwner(_tokenAddress, _id, msg.sender),
            "Token owner can't buy their own token"
        );
        _removeListing(_tokenAddress, _id);
        _removeBidOfBidder(_tokenAddress, _id, msg.sender);

        address minter = _getMinter(_tokenAddress, _id);
        _processPaymentToken(_tokenAddress, minter, listing.seller, listing.price, msg.sender);
        _tokenAddress.safeTransferFrom(listing.seller, msg.sender, _id);

        emit ListingBought(
            _tokenAddress,
            _id,
            msg.sender,
            listing.price,
            listing
        );
    }

    function bidOffer(
        IERC721 _tokenAddress,
        uint256 _id,
        uint256 _offer,
        uint256 _expireTimestamp
    ) public
      isMarketLive
      userNotBanned
      isValidTimestamp(_expireTimestamp)
    {
        Bid memory bid = Bid(_id, _offer, msg.sender, _expireTimestamp);

        require(_isBidValid(_tokenAddress, bid), "Bid is not valid");

        listedTokenIDs[address(_tokenAddress)].tokenIdWithBid.add(_id);
        listedTokenIDs[address(_tokenAddress)].bids[_id].bidders.add(msg.sender);
        listedTokenIDs[address(_tokenAddress)].bids[_id].bids[msg.sender] = bid;

        emit ListingBidOffered(
            _tokenAddress,
            _id,
            bid
        );
    }

    function bidOfferCancel(
        IERC721 _tokenAddress,
        uint256 _id
    ) public
      isMarketLive
      userNotBanned
    {
        Bid memory bid = listedTokenIDs[address(_tokenAddress)].bids[_id].bids[msg.sender];
        require(
            bid.bidder == msg.sender,
            "This address doesn't have bid on this token"
        );

        emit ListingBidCancelled(_tokenAddress, _id, bid);
        _removeBidOfBidder(_tokenAddress, _id, msg.sender);
    }

    function acceptBidForListing(
        IERC721 _tokenAddress,
        uint256 _id,
        address _bidder,
        uint256 _price
    ) public
      isMarketLive
      userNotBanned
      isSellerOrAdmin(_tokenAddress, _id)
      payable
      nonReentrant
    {
        require(
            _isTokenApproved(_tokenAddress, _id) ||
                _isAllTokenApproved(_tokenAddress, msg.sender),
            "The token is not approved to transfer by the contract"
        );

        Bid memory existingBid = getBidderTokenBid(
            _tokenAddress,
            _id,
            _bidder
        );
        require(
            existingBid.tokenId == _id &&
                existingBid.value == _price &&
                existingBid.bidder == _bidder,
            "This token doesn't have a matching bid"
        );

        Listing memory listing = listedTokenIDs[address(_tokenAddress)].listings[_id];

        _processBiddingPayment(_tokenAddress, _id, existingBid, listing);

        _tokenAddress.safeTransferFrom(listing.seller, existingBid.bidder, _id);

        emit ListingBought(
            _tokenAddress,
            _id,
            existingBid.bidder,
            _price,
            listing
        );
        _removeListing(_tokenAddress, _id);
        _removeBidOfBidder(_tokenAddress, _id, existingBid.bidder);
    }

    function unlistItem(IERC721 _tokenAddress, uint256 _id) external restricted {
        _removeListing(_tokenAddress, _id);
    }

    function unlistItems(IERC721 _tokenAddress, uint256[] calldata _ids) external restricted {
        for(uint i = 0; i < _ids.length; i++) {
            _removeListing(_tokenAddress, _ids[i]);
        }
    }

    function recoverBalance(uint256 amount) public restricted payable nonReentrant  {
        payable(msg.sender).transfer(amount);
    }

    function recoverToken(IBEP20 _token, uint256 amount) public restricted nonReentrant {
        _token.approve(msg.sender, amount);
        _token.transferFrom(address(this), msg.sender, amount);
    }

    function setAdditionalAdmin(address newAdmin) external restricted {
        _setupRole(DEFAULT_ADMIN_ROLE, newAdmin);
    }


    // Tax Management
    function allowToken(
        IERC721 _tokenAddress,
        uint256 _badassPercent,
        uint256 _minterPercent,
        uint256 _taxPercent,
        bool _isFreeTax,
        bool _isFreeRewards,
        IBEP20 _purchaseToken
    ) public
        restricted
    {
        listedTokenIDs[address(_tokenAddress)].badassPercent = _badassPercent;
        listedTokenIDs[address(_tokenAddress)].minterPercent = _minterPercent;
        listedTokenIDs[address(_tokenAddress)].taxPercent = _taxPercent;
        listedTokenIDs[address(_tokenAddress)].isFreeTax = _isFreeTax;
        listedTokenIDs[address(_tokenAddress)].isFreeRewards = _isFreeRewards;
        listedTokenIDs[address(_tokenAddress)].purchaseToken = _purchaseToken;
        listedTokenIDs[address(_tokenAddress)].isNotBanned = true;

        allowedPaymentTokens.add(address(_purchaseToken));
    }

    function disallowToken(IERC721 _tokenAddress) public restricted {
        listedTokenIDs[address(_tokenAddress)].isNotBanned = false;
    }

    function setTaxRecipient(address _taxRecipient) public restricted {
        taxRecipient = _taxRecipient;
    }

    function setDefaultTax(uint256 _defaultTax) public restricted {
        defaultTax = _defaultTax;
    }

    function setDefaultRewardPercent(uint256 _percent) public restricted {
        defaultRewardPercent = _percent;
    }

    function setDefaultMinterPercent(uint256 _percent) public restricted {
        defaultMinterPercent = _percent;
    }

    // Purchase Config
    function setPurchaseToken(IBEP20 _purchaseToken) public restricted {
        purchaseToken = _purchaseToken;
    }

    function setBadAssAddress(BabyBadasses _badAssToken) public restricted {
        badAssToken = _badAssToken;
    }


    // Rewards Pool
    function getRewardBalances() public view returns (uint256 balanceReward, uint256[] memory balanceWReward, address[] memory paymentTokens){
        uint count = badAssToken.balanceOf(msg.sender);
        balanceWReward = new uint256[](allowedPaymentTokens.length());
        paymentTokens = new address[](allowedPaymentTokens.length());
        for (uint i=0; i < count; i++){
            uint tokenId = badAssToken.tokenOfOwnerByIndex(msg.sender, i);
            (uint256 bal, uint256[] memory balW, address[] memory tokens) = getRewardBalance(tokenId);
            balanceReward += bal;
            for (uint256 token = 0; token < allowedPaymentTokens.length(); token++) {
                balanceWReward[token] += balW[token];
                paymentTokens[token] = tokens[token];
            }
        }
        return (balanceReward, balanceWReward, paymentTokens);
    }

    function getRewardBalance(uint256 _id) public view returns (uint256 balanceReward, uint256[] memory balanceWReward, address[] memory paymentTokens){
        uint256 claimedReward;
        if(totalReceivedReward[_id] > 0) {
            claimedReward = totalReceivedReward[_id];
        } else {
            claimedReward = 0;
        }

        balanceWReward = new uint256[](allowedPaymentTokens.length());
        paymentTokens = new address[](allowedPaymentTokens.length());
        for (uint256 i = 0; i < allowedPaymentTokens.length(); i++) {
            address token = allowedPaymentTokens.at(i);
            uint256 claimedWReward;
            if (totalReceivedWReward[_id][token] > 0){
                claimedWReward = totalReceivedWReward[_id][token];
            } else {
                claimedWReward = 0;
            }
            balanceWReward[i] = totalWDividend[token] - claimedWReward;
            paymentTokens[i] = token;
        }

        balanceReward = totalDividend - claimedReward;
        return (balanceReward, balanceWReward, paymentTokens);
    }

    function claimRewards() public {
        uint count = badAssToken.balanceOf(msg.sender);
        uint256 total;
        uint256[] memory totalW = new uint256[](allowedPaymentTokens.length());
        for (uint i=0; i < count; i++){
            uint tokenId = badAssToken.tokenOfOwnerByIndex(msg.sender, i);
            (uint256 bal, uint256[] memory balW, address[] memory tokens) = getRewardBalance(tokenId);
            totalReceivedReward[tokenId] += bal;
            total += bal;
            for (uint256 idx = 0; idx < allowedPaymentTokens.length(); idx++) {
                address token = tokens[idx];
                totalW[idx] += balW[idx];
                totalReceivedWReward[tokenId][token] += balW[idx];
            }
        }

        payable(msg.sender).transfer(total);

        for (uint256 i = 0; i < allowedPaymentTokens.length(); i++) {
            IBEP20(allowedPaymentTokens.at(i)).transfer(
                msg.sender,
                totalW[i]
            );
        }
    }

    function claimReward(uint256 _id) public isBadAssOwnerOrAdmin(_id) {
        address owner = badAssToken.ownerOf(_id);
        (uint256 rewardsShare, uint256[] memory rewardsWShare, address[] memory tokens) = getRewardBalance(_id);
        totalReceivedReward[_id] += rewardsShare;
        payable(owner).transfer(rewardsShare);

        for (uint256 i = 0; i < allowedPaymentTokens.length(); i++) {
            address token = tokens[i];
            totalReceivedWReward[_id][token] += rewardsWShare[i];
            IBEP20(token).transfer(
                owner,
                rewardsWShare[i]
            );
        }
    }

    
    function requestReward(uint256 _id) public isBadAssOwnerOrAdmin(_id) {
        (, uint256[] memory rewardsWShare, address[] memory tokens) = getRewardBalance(_id);
        
        for (uint256 i = 0; i < allowedPaymentTokens.length(); i++) {
            address token = tokens[i];
            
            IBEP20(token).approve(
                msg.sender,
                rewardsWShare[i]
            );
        }
    }

    function reflectDividend(uint256 amount, uint256 wamount, address payToken) private {
        rewardsBalance += amount;
        totalDividend += (amount/5000);
        rewardsWBalance[payToken] += wamount;
        totalWDividend[payToken] += (wamount/5000);
    }
    
    function addDividend(uint256 amount, uint256 wamount, address payToken) public restricted {
        rewardsBalance += amount;
        totalDividend += (amount/5000);
        rewardsWBalance[payToken] += wamount;
        totalWDividend[payToken] += (wamount/5000);
    }
    
    function setDividend(uint256 amount, uint256 wamount, address payToken) public restricted {
        totalDividend = amount;
        totalWDividend[payToken] = wamount;
    }
    
    function setRewardsBalance(uint256 amount, uint256 wamount, address payToken) public restricted {
        rewardsBalance = amount;
        rewardsWBalance[payToken] = wamount;
    }
    
    function setRewards(uint256 _id, uint256 amount, uint256 wamount, address payToken) public restricted {
        totalReceivedReward[_id] = amount;
        totalReceivedWReward[_id][payToken] = wamount;
    }

    function actionTimeOutRangeMin() public view returns (uint256) {
        return _actionTimeOutRangeMin;
    }

    function actionTimeOutRangeMax() public view returns (uint256) {
        return _actionTimeOutRangeMax;
    }
    
    function changeMinActionTimeLimit(uint256 timeInSec) public restricted {
        _actionTimeOutRangeMin = timeInSec;
    }

    function changeMaxActionTimeLimit(uint256 timeInSec) public restricted {
        _actionTimeOutRangeMax = timeInSec;
    }

    // ############
    // Internal helpers
    // ############
    function _isTokenOwner(
        IERC721 _tokenAddress,
        uint256 _id,
        address _account
    ) private view returns (bool) {
        try _tokenAddress.ownerOf(_id) returns (address tokenOwner) {
            return tokenOwner == _account;
        } catch {
            return false;
        }
    }

    function _isTokenApproved(IERC721 _tokenAddress, uint256 _id)
        private
        view
        returns (bool)
    {
        try _tokenAddress.ownerOf(_id) returns (address tokenOperator) {
            return tokenOperator == address(this);
        } catch {
            return false;
        }
    }

    function _isAllTokenApproved(IERC721 _tokenAddress, address owner)
        private
        view
        returns (bool)
    {
        return _tokenAddress.isApprovedForAll(owner, address(this));
    }

    function _isListingValid(IERC721 _tokenAddress, Listing memory listing)
        private
        view
        returns (bool isValid)
    {
        if (
            _isTokenOwner(_tokenAddress, listing.tokenId, listing.seller) &&
            (_isTokenApproved(_tokenAddress, listing.tokenId) ||
                _isAllTokenApproved(_tokenAddress, listing.seller)) &&
            listing.price > 0 &&
            listing.endTimestamp > block.timestamp
        ) {
            isValid = true;
        }
    }

    function _isBidValid(IERC721 _tokenAddress, Bid memory bid)
        private
        view
        returns (bool isValid)
    {
        if (
            !_isTokenOwner(_tokenAddress, bid.tokenId, bid.bidder) &&
            purchaseToken.allowance(bid.bidder, address(this)) >= bid.value &&
            purchaseToken.balanceOf(bid.bidder) >= bid.value &&
            bid.value > 0 &&
            bid.expireTimestamp > block.timestamp
        ) {
            isValid = true;
        }
    }

    function _getMinter(IERC721 _tokenAddress, uint256 _id) private view returns (address) {
        address minter = address(0);
        if (address(_tokenAddress) == address(badAssToken)){
            minter = badAssToken.BadassCreator(_id);
        } else {
            minter = listedTokenIDs[address(_tokenAddress)].listings[_id].minter;
        }

        return minter;
    }

    function _removeListing(IERC721 _tokenAddress, uint256 _id) private {
        delete listedTokenIDs[address(_tokenAddress)].listings[_id];
        listedTokenIDs[address(_tokenAddress)].tokenIdWithListing.remove(_id);
    }

    function _removeBidOfBidder(
        IERC721 _tokenAddress,
        uint256 _id,
        address _bidder
    ) private {
        if (
            listedTokenIDs[address(_tokenAddress)].bids[_id].bidders.contains(_bidder)
        ) {
            // Step 1: delete the bid and the address
            delete listedTokenIDs[address(_tokenAddress)].bids[_id].bids[_bidder];
            listedTokenIDs[address(_tokenAddress)].bids[_id].bidders.remove(_bidder);

            // Step 2: if no bid left
            if (
                listedTokenIDs[address(_tokenAddress)].bids[_id].bidders.length() == 0
            ) {
                listedTokenIDs[address(_tokenAddress)].tokenIdWithBid.remove(_id);
            }
        }
    }


    function _computePrice(IERC721 _tokenAddress, uint256 _amount, address _minter
    ) private view isAllowedToken(_tokenAddress)
        returns (uint256 rewardsFee, uint256 minterFee, uint256 marketFee, uint256 netSale) 
    {
        uint256 rewardPercent = defaultRewardPercent;
        uint256 minterPercent = defaultMinterPercent;
        uint256 taxPercent = defaultTax;

        if (listedTokenIDs[address(_tokenAddress)].isFreeTax) {
            taxPercent = 0;
        } else if (listedTokenIDs[address(_tokenAddress)].taxPercent != 0){
            taxPercent = listedTokenIDs[address(_tokenAddress)].taxPercent;
        }

        if (listedTokenIDs[address(_tokenAddress)].isFreeRewards) {
            rewardPercent = 0;
        } else if (!listedTokenIDs[address(_tokenAddress)].isFreeRewards && listedTokenIDs[address(_tokenAddress)].badassPercent != 0){
            rewardPercent = listedTokenIDs[address(_tokenAddress)].badassPercent;
        }

        if (listedTokenIDs[address(_tokenAddress)].minterPercent != 0) {
            minterPercent = listedTokenIDs[address(_tokenAddress)].minterPercent;
        }

        rewardsFee = _amount * rewardPercent / 100;
        minterFee = 0;
        if (_minter != address(0)){
            minterFee = _amount * minterPercent / 100;
        } else {
            minterFee = 0;
        }
        marketFee = _amount * taxPercent / 100;
        netSale = _amount - rewardsFee - minterFee - marketFee;
        
        return (rewardsFee,  minterFee, marketFee, netSale);
    }

    function _processPayment(IERC721 _tokenAddress, address _minter, address _seller, uint256 _amount) private {
        uint256 rewardsFee;
        uint256 minterFee;
        uint256 marketFee;
        uint256 netSale;

        (rewardsFee,  minterFee, marketFee, netSale) = _computePrice(_tokenAddress, _amount, _minter);

        reflectDividend(rewardsFee, 0, address(0));
        if (minterFee != 0){
            payable(_minter).transfer(minterFee);
        }
        payable(taxRecipient).transfer(marketFee);
        payable(_seller).transfer(netSale);
    }

    function _processPaymentToken(IERC721 _tokenAddress, address _minter, address _seller, uint256 _amount, address _buyer) private {
        uint256 rewardsFee;
        uint256 minterFee;
        uint256 marketFee;
        uint256 netSale;
        IBEP20 payToken = listedTokenIDs[address(_tokenAddress)].purchaseToken;
        (rewardsFee,  minterFee, marketFee, netSale) = _computePrice(_tokenAddress, _amount, _minter);
        
        payToken.transferFrom(
            _buyer,
            address(this),
            rewardsFee
        );
        reflectDividend(0, rewardsFee, address(payToken));
        if (minterFee != 0){
             payToken.transferFrom(
                _buyer,
                _minter,
                minterFee
            );
        }
        payToken.transferFrom(
            _buyer,
            taxRecipient,
            marketFee
        );
        payToken.transferFrom(
            _buyer,
            _seller,
            netSale
        );
    }
    
    function _processBiddingPayment(IERC721 _tokenAddress, uint256 _id, Bid memory _bid, Listing memory _listing) private {
        address minter = _getMinter(_tokenAddress, _id);
        (uint256 rewardsFee, uint256 minterFee, uint256 marketFee, uint256 netSale) = _computePrice(_tokenAddress, _bid.value, minter);
        IBEP20 payToken;

        payToken = listedTokenIDs[address(_tokenAddress)].purchaseToken;
        if (address(payToken) == address(0)){
            payToken = purchaseToken;
        }

        totalVolume += _bid.value;
        payToken.transferFrom(
            _bid.bidder,
            address(this),
            rewardsFee
        );
        reflectDividend(0, rewardsFee, address(payToken));
        if (minterFee != 0){
            payToken.transferFrom(
                _bid.bidder,
                minter,
                minterFee
            );
        }
        payToken.transferFrom(
            _bid.bidder,
            taxRecipient,
            marketFee
        );
        payToken.transferFrom(
            _bid.bidder,
            _listing.seller,
            netSale
        );
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}



interface BabyBadasses {
  function BadassCreator ( uint256 tokenId ) external view returns ( address );
  function DEFAULT_ADMIN_ROLE (  ) external view returns ( bytes32 );
  function _rewardPercent (  ) external view returns ( uint256 );
  function _tokenIdTracker (  ) external view returns ( uint256 _value );
  function approve ( address to, uint256 tokenId ) external;
  function balanceOf ( address owner ) external view returns ( uint256 );
  function canMint (  ) external view returns ( bool );
  function claimReward ( uint256 tokenId ) external;
  function claimRewards (  ) external;
  function copyOtherToken ( address tokToCP ) external;
  function creator ( uint256 ) external view returns ( address );
  function currentRate (  ) external view returns ( uint256 );
  function getApproved ( uint256 tokenId ) external view returns ( address );
  function getReflectionBalance ( uint256 tokenId ) external view returns ( uint256 );
  function getReflectionBalances (  ) external view returns ( uint256 );
  function getRoleAdmin ( bytes32 role ) external view returns ( bytes32 );
  function getRoleMember ( bytes32 role, uint256 index ) external view returns ( address );
  function getRoleMemberCount ( bytes32 role ) external view returns ( uint256 );
  function grantRole ( bytes32 role, address account ) external;
  function hasRole ( bytes32 role, address account ) external view returns ( bool );
  function isApprovedForAll ( address owner, address operator ) external view returns ( bool );
  function mint (  ) external;
  function ownerOf ( uint256 tokenId ) external view returns ( address );
  function price (  ) external view returns ( uint256 );
  function reflectionBalance (  ) external view returns ( uint256 );
  function renounceRole ( bytes32 role, address account ) external;
  function revokeRole ( bytes32 role, address account ) external;
  function rewardToken (  ) external view returns ( address );
  function router (  ) external view returns ( address );
  function safeTransferFrom ( address from, address to, uint256 tokenId ) external;
  function setApprovalForAll ( address operator, bool approved ) external;
  function setMintingEnabled ( bool Allowed ) external;
  function setMultipleMint ( uint256 amount ) external;
  function setPrice ( uint256 mintPrice ) external;
  function setRewardPercent ( uint256 pcnt ) external;
  function setRewardToken ( address tokenToReward ) external;
  function supportsInterface ( bytes4 interfaceId ) external view returns ( bool );
  function tokenByIndex ( uint256 index ) external view returns ( uint256 );
  function tokenOfOwnerByIndex ( address owner, uint256 index ) external view returns ( uint256 );
  function totalDividend (  ) external view returns ( uint256 );
  function totalSupply (  ) external view returns ( uint256 );
  function transferFrom ( address from, address to, uint256 tokenId ) external;
}


interface BadassMarketplace {
  // basic listing; we can easily offer other types (auction / buy it now)
  // if the struct can be extended, that's one way, otherwise different mapping per type.
  struct Listing {
      uint256 tokenId;
      address seller;
      address minter;
      uint256 price;
      uint256 endTimestamp;
  }

  struct Bid {
      uint256 tokenId;
      uint256 value;
      address bidder;
      uint256 expireTimestamp;
  }

  struct TokenBids {
      EnumerableSet.AddressSet bidders;
      mapping(address => Bid) bids;
  }

  struct ERC721Market {
      EnumerableSet.UintSet tokenIdWithListing;
      mapping(uint256 => Listing) listings;
      EnumerableSet.UintSet tokenIdWithBid;
      mapping(uint256 => TokenBids) bids;
      uint256 badassPercent;
      uint256 minterPercent;
      uint256 taxPercent;
      bool isFreeTax;
      bool isFreeRewards;
      bool isNotBanned;
      uint256 totalVolume;
      IBEP20 purchaseToken;
  }


  // ############
  // Events
  // ############
  event ListingAdded(
      IERC721 indexed nftAddress,
      uint256 indexed nftID,
      Listing listing
  );
  event ListingRemoved(
      IERC721 indexed nftAddress,
      uint256 indexed nftID,
      Listing listing
  );
  event ListingPriceChange(
      IERC721 indexed nftAddress,
      uint256 indexed nftID,
      uint256 newPrice
  );
  event ListingBought(
      IERC721 indexed nftAddress,
      uint256 indexed nftID,
      address indexed buyer,
      uint256 price,
      Listing listing
  );
  event ListingBidOffered(
      IERC721 indexed nftAddress,
      uint256 indexed nftID,
      Bid bid
  );
  event ListingBidCancelled(
      IERC721 indexed nftAddress,
      uint256 indexed nftID,
      Bid bid
  );
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

    constructor() {
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

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
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
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

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
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
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
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
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

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
     * bearer except when using {AccessControl-_setupRole}.
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
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

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
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

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
    function renounceRole(bytes32 role, address account) external;
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
interface IERC165Upgradeable {
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