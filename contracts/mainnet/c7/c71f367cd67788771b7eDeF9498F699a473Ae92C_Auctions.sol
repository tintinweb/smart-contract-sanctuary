// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

import { ITux } from "./ITux.sol";
import { IAuctions } from "./IAuctions.sol";

import "./library/UintSet.sol";
import "./library/AddressSet.sol";
import "./library/OrderedSet.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC721, IERC165 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";


contract Auctions is
    IAuctions,
    ReentrancyGuard
{
    using SafeMath for uint256;
    using UintSet for UintSet.Set;
    using AddressSet for AddressSet.Set;
    using OrderedSet for OrderedSet.Set;
    using Counters for Counters.Counter;

    Counters.Counter private _bidIdTracker;
    Counters.Counter private _houseIdTracker;
    Counters.Counter private _auctionIdTracker;
    Counters.Counter private _contractIdTracker;
    Counters.Counter private _offerIdTracker;
    Counters.Counter private _creatorsTracker;
    Counters.Counter private _collectorsTracker;

    // Minimum amount of time left in seconds to an auction after a new bid is placed
    uint256 constant public timeBuffer = 900;  // 15 minutes -> 900 seconds

    // Minimum percentage difference between the last bid and the current bid
    uint16 constant public minimumIncrementPercentage = 500;  // 5%

    // Mapping from house name to house ID
    mapping(string => uint256) public houseIDs;

    // Mapping from token contract to contract ID
    mapping(address => uint256) public contractIDs;

    // Mapping from keccak256(contract, token) to currently running auction ID
    mapping(bytes32 => uint256) public tokenAuction;

    // Mapping from rank to house ID
    mapping(uint256 => uint256) public ranking;

    // Mapping from rank to creator
    mapping(uint256 => address) public creatorRanking;

    // Mapping from rank to collector
    mapping(uint256 => address) public collectorRanking;

    // Mapping from rank to token contract ID
    mapping(uint256 => uint256) public contractRanking;

    // Mapping of token contracts
    mapping(uint256 => IAuctions.TokenContract) public contracts;

    // Mapping of auctions
    mapping(uint256 => IAuctions.Auction) public auctions;

    // Mapping of houses
    mapping(uint256 => IAuctions.House) public houses;

    // Mapping of bids
    mapping(uint256 => IAuctions.Bid) public bids;

    // Mapping of offers
    mapping(uint256 => IAuctions.Offer) public offers;

    // Mapping of accounts
    mapping(address => IAuctions.Account) public accounts;

    // Mapping from creator to stats
    mapping(address => IAuctions.CreatorStats) public creatorStats;

    // Mapping from collector to stats
    mapping(address => IAuctions.CollectorStats) public collectorStats;

    // Mapping from house ID to token IDs requiring approval
    mapping(uint256 => UintSet.Set) private _houseQueue;

    // Mapping from auction ID to bids
    mapping(uint256 => UintSet.Set) private _auctionBids;

    // Mapping from house ID to active auction IDs
    mapping(uint256 => OrderedSet.Set) private _houseAuctions;

    // Mapping from curator to enumerable house IDs
    mapping(address => UintSet.Set) private _curatorHouses;

    // Mapping from creator to enumerable house IDs
    mapping(address => UintSet.Set) private _creatorHouses;

    // Mapping from house id to enumerable creators
    mapping(uint256 => AddressSet.Set) private _houseCreators;

    // Mapping from seller to active auction IDs
    mapping(address => UintSet.Set) private _sellerAuctions;

    // Mapping from bidder to active auction IDs
    mapping(address => UintSet.Set) private _bidderAuctions;

    // Mapping from keccak256(contract, token) to previous auction IDs
    mapping(bytes32 => UintSet.Set) private _previousTokenAuctions;

    // Mapping from keccak256(contract, token) to offer IDs
    mapping(bytes32 => UintSet.Set) private _tokenOffers;

    // OrderedSet of active auction IDs without a house ID
    OrderedSet.Set private _activeAuctions;


    bytes4 constant interfaceId = 0x5b5e139f; // ERC721 interfaceId


    modifier auctionExists(uint256 auctionId) {
        require(
            auctions[auctionId].tokenOwner != address(0),
            "Auction does not exist");
        _;
    }

    modifier onlyHouseCurator(uint256 houseId) {
        require(
            msg.sender == houses[houseId].curator,
            "Must be house curator");
        _;
    }


    /*
     * Constructor
     */
    /* constructor() {} */

    function totalHouses() public view override returns (uint256) {
        return _houseIdTracker.current();
    }

    function totalAuctions() public view override returns (uint256) {
        return _auctionIdTracker.current();
    }

    function totalContracts() public view override returns (uint256) {
        return _contractIdTracker.current();
    }

    function totalCreators() public view override returns (uint256) {
        return _creatorsTracker.current();
    }

    function totalCollectors() public view override returns (uint256) {
        return _collectorsTracker.current();
    }

    function totalActiveAuctions() public view override returns (uint256) {
        return _activeAuctions.length();
    }

    function totalActiveHouseAuctions(uint256 houseId) public view override returns (uint256) {
        return _houseAuctions[houseId].length();
    }

    function getAuctions() public view override returns (uint256[] memory) {
        return _activeAuctions.values();
    }

    function getAuctionsFromN(uint256 from, uint256 n) public view override returns (uint256[] memory) {
        return _activeAuctions.valuesFromN(from, n);
    }

    function getHouseAuctions(uint256 houseId) public view override returns (uint256[] memory) {
        return _houseAuctions[houseId].values();
    }

    function getHouseAuctionsFromN(uint256 houseId, uint256 from, uint256 n) public view override returns (uint256[] memory) {
        return _houseAuctions[houseId].valuesFromN(from, n);
    }

    function getHouseQueue(uint256 houseId) public view override returns (uint256[] memory) {
        return _houseQueue[houseId].values();
    }

    function getAuctionBids(uint256 auctionId) public view override returns (uint256[] memory) {
        return _auctionBids[auctionId].values();
    }

    function getCuratorHouses(address curator) public view override returns (uint256[] memory) {
        return _curatorHouses[curator].values();
    }

    function getCreatorHouses(address creator) public view override returns (uint256[] memory) {
        return _creatorHouses[creator].values();
    }

    function getHouseCreators(uint256 houseId) public view override returns (address[] memory) {
        return _houseCreators[houseId].values();
    }

    function getSellerAuctions(address seller) public view override returns (uint256[] memory) {
        return _sellerAuctions[seller].values();
    }

    function getBidderAuctions(address bidder) public view override returns (uint256[] memory) {
        return _bidderAuctions[bidder].values();
    }

    function getPreviousAuctions(bytes32 tokenHash) public view override returns (uint256[] memory) {
        return _previousTokenAuctions[tokenHash].values();
    }

    function getTokenOffers(bytes32 tokenHash) public view override returns (uint256[] memory) {
        return _tokenOffers[tokenHash].values();
    }


    function createHouse(
        string  memory name,
        address curator,
        uint16  fee,
        bool    preApproved,
        string  memory metadata
    )
        public
        override
        nonReentrant
        returns (uint256)
    {
        require(
            houseIDs[name] == 0,
            "House name already exists");
        require(
            bytes(name).length > 0,
            "House name is required");
        require(
            bytes(name).length <= 32,
            "House name must be less than 32 characters");
        require(
            curator != address(0),
            "Curator address is required");
        require(
            fee < 10000,
            "Curator fee percentage must be less than 100%");

        _houseIdTracker.increment();
        uint256 houseId = _houseIdTracker.current();

        houses[houseId] = House({
            name: name,
            curator: payable(curator),
            fee: fee,
            preApproved: preApproved,
            metadata: metadata,
            bids: 0,
            sales: 0,
            total: 0,
            feesTotal: 0,
            activeAuctions: 0,
            rank: houseId
        });

        _curatorHouses[curator].add(houseId);
        ranking[houseId] = houseId;
        houseIDs[name] = houseId;

        emit HouseCreated(
            houseId
        );

        return houseId;
    }

    function addCreator(
        uint256 houseId,
        address creator
    )
        public
        override
        onlyHouseCurator(houseId)
    {
        require(
            _houseCreators[houseId].contains(creator) == false,
            "Creator already added");

        _houseCreators[houseId].add(creator);
        _creatorHouses[creator].add(houseId);

        emit CreatorAdded(
            houseId,
            creator
        );
    }

    function removeCreator(
        uint256 houseId,
        address creator
    )
        public
        override
        onlyHouseCurator(houseId)
    {
        require(
            _houseCreators[houseId].contains(creator) == true,
            "Creator already removed");

        _houseCreators[houseId].remove(creator);
        _creatorHouses[creator].remove(houseId);

        emit CreatorRemoved(
            houseId,
            creator
        );
    }

    function updateFee(
        uint256 houseId,
        uint16  fee
    )
        public
        override
        onlyHouseCurator(houseId)
    {
        require(
            fee < 10000,
            "Curator fee percentage must be less than 100%");

        houses[houseId].fee = fee;

        emit FeeUpdated(
            houseId,
            fee
        );
    }

    function updateMetadata(
        uint256 houseId,
        string memory metadata
    )
        public
        override
        onlyHouseCurator(houseId)
    {
        houses[houseId].metadata = metadata;

        emit MetadataUpdated(
            houseId,
            metadata
        );
    }

    function updateName(
        string  memory name
    )
        public
        override
    {
        accounts[msg.sender].name = name;

        emit AccountUpdated(
            msg.sender
        );
    }

    function updateBio(
        string  memory bioHash
    )
        public
        override
    {
        accounts[msg.sender].bioHash = bioHash;

        emit AccountUpdated(
            msg.sender
        );
    }

    function updatePicture(
        string  memory pictureHash
    )
        public
        override
    {
        accounts[msg.sender].pictureHash = pictureHash;

        emit AccountUpdated(
            msg.sender
        );
    }

    function createAuction(
        address tokenContract,
        uint256 tokenId,
        uint256 duration,
        uint256 reservePrice,
        uint256 houseId
    )
        public
        override
        nonReentrant
        returns (uint256)
    {
        require(
            IERC165(tokenContract).supportsInterface(interfaceId),
            "Token contract does not support ERC721 interface");

        address tokenOwner = IERC721(tokenContract).ownerOf(tokenId);
        require(
            msg.sender == tokenOwner ||
            msg.sender == IERC721(tokenContract).getApproved(tokenId),
            "Must be token owner or approved");

        uint16  fee = 0;
        bool    preApproved = true;
        address curator = address(0);

        if (houseId > 0) {
            curator = houses[houseId].curator;

            require(
                curator != address(0),
                "House does not exist");
            require(
                _houseCreators[houseId].contains(tokenOwner) || msg.sender == curator,
                "Must be approved by the house");

            fee = houses[houseId].fee;
            preApproved = houses[houseId].preApproved;
            houses[houseId].activeAuctions += 1;
        }

        if (contractIDs[tokenContract] == 0) {
          registerTokenContract(tokenContract);
        }

        try ITux(tokenContract).tokenCreator(tokenId) returns (address creator) {
          if (accounts[creator].creatorRank == 0) {
              _creatorsTracker.increment();
              uint256 creatorRank = _creatorsTracker.current();
              creatorRanking[creatorRank] = creator;
              accounts[creator].creatorRank = creatorRank;
              creatorStats[creator] = CreatorStats({
                  bids: 0,
                  sales: 0,
                  total: 0
              });
          }
        } catch {}

        _auctionIdTracker.increment();
        uint256 auctionId = _auctionIdTracker.current();

        tokenAuction[keccak256(abi.encode(tokenContract, tokenId))] = auctionId;

        _sellerAuctions[tokenOwner].add(auctionId);

        bool approved = (curator == address(0) || preApproved || curator == tokenOwner);

        if (houseId > 0) {
            if (approved == true) {
                _houseAuctions[houseId].add(auctionId);
            }
            else {
                _houseQueue[houseId].add(auctionId);
            }
        }
        else {
            _activeAuctions.add(auctionId);
        }

        auctions[auctionId] = Auction({
            tokenContract: tokenContract,
            tokenId: tokenId,
            tokenOwner: tokenOwner,
            duration: duration,
            reservePrice: reservePrice,
            houseId: houseId,
            fee: fee,
            approved: approved,
            firstBidTime: 0,
            amount: 0,
            bidder: payable(0),
            created: block.timestamp
        });

        IERC721(tokenContract).transferFrom(tokenOwner, address(this), tokenId);

        emit AuctionCreated(
            auctionId
        );

        return auctionId;
    }

    function setAuctionApproval(uint256 auctionId, bool approved)
        external
        override
        auctionExists(auctionId)
    {
        IAuctions.Auction storage auction = auctions[auctionId];
        address curator = houses[auction.houseId].curator;

        require(
            curator != address(0) && curator == msg.sender,
            "Must be auction curator");
        require(
            auction.firstBidTime == 0,
            "Auction has already started");
        require(
            (approved == true && auction.approved == false) ||
            (approved == false && auction.approved == true),
            "Auction already in this approved state");

        auction.approved = approved;

        if (approved == true) {
            _houseAuctions[auction.houseId].add(auctionId);
            _houseQueue[auction.houseId].remove(auctionId);
        }

        emit AuctionApprovalUpdated(
            auctionId,
            approved
        );
    }

    function setAuctionReservePrice(uint256 auctionId, uint256 reservePrice)
        external
        override
        auctionExists(auctionId)
    {
        IAuctions.Auction storage auction = auctions[auctionId];

        require(
            msg.sender == auction.tokenOwner,
            "Must be token owner");
        require(
            auction.firstBidTime == 0,
            "Auction has already started");

        auction.reservePrice = reservePrice;

        emit AuctionReservePriceUpdated(
            auctionId,
            reservePrice
        );
    }

    function createBid(uint256 auctionId, uint256 amount)
        external
        override
        payable
        auctionExists(auctionId)
        nonReentrant
    {
        IAuctions.Auction storage auction = auctions[auctionId];

        require(
            auction.approved,
            "Auction must be approved by curator");
        require(
            msg.value == amount,
            "Sent ETH does not match specified bid amount");
        require(
            auction.firstBidTime == 0 ||
            block.timestamp < auction.firstBidTime.add(auction.duration),
            "Auction expired");
        require(
            amount >= auction.amount.add(
                auction.amount.mul(minimumIncrementPercentage).div(10000)),
            "Must send more than last bid by 5%");
        require(
            amount >= auction.reservePrice,
            "Bid below reserve price");

        address payable lastBidder = auction.bidder;
        bool isFirstBid = true;
        if (lastBidder != payable(0)) {
            isFirstBid = false;
        }

        if (auction.firstBidTime == 0) {
            auction.firstBidTime = block.timestamp;
        } else if (isFirstBid == false) {
            _handleOutgoingBid(lastBidder, auction.amount);
        }

        _handleIncomingBid(amount);

        auction.amount = amount;
        auction.bidder = payable(msg.sender);

        _bidIdTracker.increment();
        uint256 bidId = _bidIdTracker.current();

        bids[bidId] = Bid({
            timestamp: block.timestamp,
            bidder: msg.sender,
            value: amount
        });

        _auctionBids[auctionId].add(bidId);
        _bidderAuctions[msg.sender].add(auctionId);

        contracts[contractIDs[auction.tokenContract]].bids += 1;

        try ITux(auction.tokenContract).tokenCreator(auction.tokenId) returns (address creator) {
            if (creator == auction.tokenOwner) {
                creatorStats[auction.tokenOwner].bids += 1;
            }

            uint256 creatorRank = accounts[creator].creatorRank;
            if (creatorRank > 1) {
                address rankedUp = creatorRanking[creatorRank - 1];
                if (creatorStats[creator].bids > creatorStats[rankedUp].bids) {
                    accounts[creator].creatorRank -= 1;
                    accounts[rankedUp].creatorRank += 1;
                    creatorRanking[creatorRank - 1] = creator;
                    creatorRanking[creatorRank] = rankedUp;
                }
            }
        } catch {}

        uint256 collectorRank = accounts[msg.sender].collectorRank;
        if (collectorRank == 0) {
            _collectorsTracker.increment();
            collectorRank = _collectorsTracker.current();
            collectorRanking[collectorRank] = msg.sender;
            accounts[msg.sender].collectorRank = collectorRank;
            collectorStats[msg.sender] = CollectorStats({
                bids: 0,
                sales: 0,
                bought: 0,
                totalSold: 0,
                totalSpent: 0
            });
        }
        collectorStats[msg.sender].bids += 1;
        if (collectorRank > 1) {
            address rankedUp = collectorRanking[collectorRank - 1];
            if (collectorStats[msg.sender].bids > collectorStats[rankedUp].bids) {
                accounts[msg.sender].collectorRank -= 1;
                accounts[rankedUp].collectorRank += 1;
                collectorRanking[collectorRank - 1] = msg.sender;
                collectorRanking[collectorRank] = rankedUp;
            }
        }

        uint256 houseId = auction.houseId;
        if (houseId > 0) {
            houses[houseId].bids += 1;

            uint256 rank = houses[houseId].rank;
            if (rank > 1) {
                uint256 rankedUpId = ranking[rank - 1];
                if (houses[houseId].bids > houses[rankedUpId].bids) {
                    houses[houseId].rank -= 1;
                    houses[rankedUpId].rank += 1;
                    ranking[rank - 1] = houseId;
                    ranking[rank] = rankedUpId;
                }
            }
        }

        bool extended = false;
        if (auction.duration > 0) {
          uint256 timeRemaining = auction.firstBidTime.add(auction.duration).sub(block.timestamp);
          if (timeRemaining < timeBuffer) {
              auction.duration += timeBuffer.sub(timeRemaining);
              extended = true;
          }
        }

        emit AuctionBid(
            auctionId,
            msg.sender,
            amount,
            isFirstBid,
            extended
        );

        if (extended) {
            emit AuctionDurationExtended(
                auctionId,
                auction.duration
            );
        }
    }

    function endAuction(uint256 auctionId)
        external
        override
        auctionExists(auctionId)
        nonReentrant
    {
        IAuctions.Auction storage auction = auctions[auctionId];

        require(
            uint256(auction.firstBidTime) != 0,
            "Auction not started");
        require(
            block.timestamp >=
            auction.firstBidTime.add(auction.duration),
            "Auction not completed");

        try IERC721(auction.tokenContract).safeTransferFrom(
            address(this), auction.bidder, auction.tokenId
        ) {} catch {
            _handleOutgoingBid(auction.bidder, auction.amount);
            _cancelAuction(auctionId);
            return;
        }

        uint256 houseId = auction.houseId;
        address curator = address(0);
        uint256 curatorFee = 0;
        uint256 tokenOwnerProfit = auction.amount;

        uint256 contractId = contractIDs[auction.tokenContract];
        collectorStats[auction.bidder].bought += 1;
        collectorStats[auction.bidder].totalSpent += tokenOwnerProfit;
        contracts[contractId].sales += 1;
        contracts[contractId].total += tokenOwnerProfit;

        try ITux(auction.tokenContract).tokenCreator(auction.tokenId) returns (address creator) {
            if (creator == auction.tokenOwner) {
                creatorStats[creator].sales += 1;
                creatorStats[creator].total += tokenOwnerProfit;
            } else {
                collectorStats[auction.tokenOwner].sales += 1;
                collectorStats[auction.tokenOwner].totalSold += tokenOwnerProfit;
            }
        } catch {
            collectorStats[auction.tokenOwner].sales += 1;
            collectorStats[auction.tokenOwner].totalSold += tokenOwnerProfit;
        }

        if (houseId > 0) {
            curator = houses[houseId].curator;
            houses[houseId].sales += 1;
            houses[houseId].total += tokenOwnerProfit;
            if (houses[houseId].activeAuctions > 0) {
                houses[houseId].activeAuctions -= 1;
            }
            _houseAuctions[houseId].remove(auctionId);
        }
        else {
            _activeAuctions.remove(auctionId);
        }

        uint256 contractRank = contracts[contractId].rank;
        if (contractRank > 1) {
            uint256 rankedUpContract = contractRanking[contractRank - 1];
            if (contracts[contractId].bids > contracts[rankedUpContract].bids) {
                contracts[contractId].rank -= 1;
                contracts[rankedUpContract].rank += 1;
                contractRanking[contractRank - 1] = contractId;
                contractRanking[contractRank] = rankedUpContract;
            }
        }

        if (curator != address(0)) {
            curatorFee = tokenOwnerProfit.mul(auction.fee).div(10000);
            tokenOwnerProfit = tokenOwnerProfit.sub(curatorFee);
            _handleOutgoingBid(curator, curatorFee);
        }
        _handleOutgoingBid(auction.tokenOwner, tokenOwnerProfit);

        if (houseId > 0) {
            houses[houseId].feesTotal += curatorFee;
        }

        bytes32 auctionHash = keccak256(abi.encode(auction.tokenContract, auction.tokenId));
        _previousTokenAuctions[auctionHash].add(auctionId);
        delete tokenAuction[auctionHash];

        uint256 i = _auctionBids[auctionId].length();
        while (i > 0) {
            uint256 bidId = _auctionBids[auctionId].at(i - 1);
            _bidderAuctions[bids[bidId].bidder].remove(auctionId);
            i--;
        }
        _sellerAuctions[auction.tokenOwner].remove(auctionId);

        emit AuctionEnded(
            auctionId
        );
    }

    function cancelAuction(uint256 auctionId) external override nonReentrant auctionExists(auctionId) {
        require(
            auctions[auctionId].tokenOwner == msg.sender,
            "Can only be called by auction creator");
        require(
            uint256(auctions[auctionId].firstBidTime) == 0,
            "Cannot cancel an auction once it has begun");
        _cancelAuction(auctionId);
    }

    function registerTokenContract(address tokenContract)
        public
        override
        returns (uint256)
    {
        require(contractIDs[tokenContract] == 0, "Token contract already registered");

        _contractIdTracker.increment();
        uint256 contractId = _contractIdTracker.current();
        contractIDs[tokenContract] = contractId;
        contractRanking[contractId] = contractId;
        contracts[contractId] = TokenContract({
            name: IERC721Metadata(tokenContract).name(),
            tokenContract: tokenContract,
            bids: 0,
            sales: 0,
            total: 0,
            rank: contractId
        });

        return contractId;
    }

    function makeOffer(address tokenContract, uint256 tokenId, uint256 amount)
        public
        override
        payable
        nonReentrant
    {
        require(
            IERC165(tokenContract).supportsInterface(interfaceId),
            "Token contract does not support ERC721 interface");

        bytes32 auctionHash = keccak256(abi.encode(tokenContract, tokenId));
        require(
            tokenAuction[auctionHash] == 0,
            'Auction exists for this token');

        require(
            msg.value == amount,
            "Sent ETH does not match specified offer amount");

        _offerIdTracker.increment();
        uint256 offerId = _offerIdTracker.current();

        offers[offerId] = Offer({
            tokenContract: tokenContract,
            tokenId: tokenId,
            from: msg.sender,
            amount: amount
        });

        _tokenOffers[auctionHash].add(offerId);
    }

    function acceptOffer(uint256 offerId)
        public
        override
    {
        IAuctions.Offer storage offer = offers[offerId];
        require(
            offer.tokenContract != address(0),
            'Offer does not exist');

        address tokenOwner = IERC721(offer.tokenContract).ownerOf(offer.tokenId);
        require(
            msg.sender == tokenOwner ||
            msg.sender == IERC721(offer.tokenContract).getApproved(offer.tokenId),
            "Must be token owner or approved");

        IERC721(offer.tokenContract).safeTransferFrom(msg.sender, offer.from, offer.tokenId);

        _handleOutgoingBid(msg.sender, offer.amount);

        bytes32 auctionHash = keccak256(abi.encode(offer.tokenContract, offer.tokenId));
        _tokenOffers[auctionHash].remove(offerId);

        delete offers[offerId];
    }

    function cancelOffer(uint256 offerId)
        public
        override
    {
        IAuctions.Offer storage offer = offers[offerId];
        require(
            offer.from == msg.sender,
            'Not offer owner or does not exist');

        _handleOutgoingBid(msg.sender, offer.amount);

        bytes32 auctionHash = keccak256(abi.encode(offer.tokenContract, offer.tokenId));
        _tokenOffers[auctionHash].remove(offerId);

        delete offers[offerId];
    }

    function _handleIncomingBid(uint256 amount) internal {
        require(
            msg.value == amount,
            "Sent ETH does not match specified bid amount");
    }

    function _handleOutgoingBid(address to, uint256 amount) internal {
        require(
            _safeTransferETH(to, amount),
            "ETH transfer failed");
    }

    function _safeTransferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{value: value}(new bytes(0));
        return success;
    }

    function _cancelAuction(uint256 auctionId) internal {
        IAuctions.Auction storage auction = auctions[auctionId];

        IERC721(auction.tokenContract).safeTransferFrom(address(this), auction.tokenOwner, auction.tokenId);

        uint256 houseId = auction.houseId;
        if (houseId > 0) {
            _houseAuctions[houseId].remove(auctionId);
            if (houses[houseId].activeAuctions > 0) {
                houses[houseId].activeAuctions -= 1;
            }
        }
        else {
            _activeAuctions.remove(auctionId);
        }

        auction.approved = false;
        bytes32 auctionHash = keccak256(abi.encode(auction.tokenContract, auction.tokenId));
        _previousTokenAuctions[auctionHash].add(auctionId);
        delete tokenAuction[auctionHash];

        emit AuctionCanceled(
            auctionId
        );
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ITux is IERC721 {
    function tokenCreator(uint256 tokenId) external view returns (address);
    function getCreatorTokens(address creator) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;


interface IAuctions {

    struct House {
        // House name
        string  name;

        // House curator
        address payable curator;

        // House percentage fee
        uint16  fee;

        // Pre-approve added creators
        bool    preApproved;

        // IPFS hash for metadata (logo, featured creators, pieces, links)
        string  metadata;

        // Total bids
        uint256 bids;

        // Total sales number
        uint256 sales;

        // Total sales amount
        uint256 total;

        // Total fees amount
        uint256 feesTotal;

        // Counter of active autions
        uint256 activeAuctions;

        // Rank
        uint256 rank;
    }

    struct Auction {
        // Address of the ERC721 contract
        address tokenContract;

        // ERC721 tokenId
        uint256 tokenId;

        // Address of the token owner
        address tokenOwner;

        // Length of time in seconds to run the auction for, after the first bid was made
        uint256 duration;

        // Minimum price of the first bid
        uint256 reservePrice;

        // House ID for curator address
        uint256 houseId;

        // Curator fee for this auction
        uint16  fee;

        // Whether or not the auction curator has approved the auction to start
        bool    approved;

        // The time of the first bid
        uint256 firstBidTime;

        // The current highest bid amount
        uint256 amount;

        // The address of the current highest bidder
        address payable bidder;

        // The timestamp when this auction was created
        uint256 created;
    }

    struct TokenContract {
        string  name;
        address tokenContract;
        uint256 bids;
        uint256 sales;
        uint256 total;
        uint256 rank;
    }

    struct Account {
        string  name;
        string  bioHash;
        string  pictureHash;
        uint256 creatorRank;
        uint256 collectorRank;
    }

    struct CreatorStats {
        uint256 bids;
        uint256 sales;
        uint256 total;
    }

    struct CollectorStats {
        uint256 bids;
        uint256 sales;
        uint256 bought;
        uint256 totalSold;
        uint256 totalSpent;
    }

    struct Bid {
        uint256 timestamp;
        address bidder;
        uint256 value;
    }

    struct Offer {
        address tokenContract;
        uint256 tokenId;
        uint256 amount;
        address from;
    }

    event HouseCreated(
        uint256 indexed houseId
    );

    event CreatorAdded(
        uint256 indexed houseId,
        address indexed creator
    );

    event CreatorRemoved(
        uint256 indexed houseId,
        address indexed creator
    );

    event FeeUpdated(
        uint256 indexed houseId,
        uint16  fee
    );

    event MetadataUpdated(
        uint256 indexed houseId,
        string  metadata
    );

    event AccountUpdated(
        address indexed owner
    );

    event AuctionCreated(
        uint256 indexed auctionId
    );

    event AuctionApprovalUpdated(
        uint256 indexed auctionId,
        bool    approved
    );

    event AuctionReservePriceUpdated(
        uint256 indexed auctionId,
        uint256 reservePrice
    );

    event AuctionBid(
        uint256 indexed auctionId,
        address bidder,
        uint256 value,
        bool    firstBid,
        bool    extended
    );

    event AuctionDurationExtended(
        uint256 indexed auctionId,
        uint256 duration
    );

    event AuctionEnded(
        uint256 indexed auctionId
    );

    event AuctionCanceled(
        uint256 indexed auctionId
    );

    function totalHouses() external view returns (uint256);

    function totalAuctions() external view returns (uint256);

    function totalContracts() external view returns (uint256);

    function totalCreators() external view returns (uint256);

    function totalCollectors() external view returns (uint256);

    function totalActiveAuctions() external view returns (uint256);

    function totalActiveHouseAuctions(uint256 houseId) external view returns (uint256);

    function getAuctions() external view returns (uint256[] memory);

    function getAuctionsFromN(uint256 from, uint256 n) external view returns (uint256[] memory);

    function getHouseAuctions(uint256 houseId) external view returns (uint256[] memory);

    function getHouseAuctionsFromN(uint256 houseId, uint256 from, uint256 n) external view returns (uint256[] memory);

    function getHouseQueue(uint256 houseId) external view returns (uint256[] memory);

    function getCuratorHouses(address curator) external view returns (uint256[] memory);

    function getCreatorHouses(address creator) external view returns (uint256[] memory);

    function getHouseCreators(uint256 houseId) external view returns (address[] memory);

    function getSellerAuctions(address seller) external view returns (uint256[] memory);

    function getBidderAuctions(address bidder) external view returns (uint256[] memory);

    function getAuctionBids(uint256 auctionId) external view returns (uint256[] memory);

    function getPreviousAuctions(bytes32 tokenHash) external view returns (uint256[] memory);

    function getTokenOffers(bytes32 tokenHash) external view returns (uint256[] memory);

    function registerTokenContract(
        address tokenContract
    ) external returns (uint256);

    function makeOffer(
        address tokenContract,
        uint256 tokenId,
        uint256 amount
    ) external payable;

    function acceptOffer(
        uint256 offerId
    ) external;

    function cancelOffer(
        uint256 offerId
    ) external;

    function createHouse(
        string  memory name,
        address curator,
        uint16  fee,
        bool    preApproved,
        string  memory metadata
    ) external returns (uint256);

    function addCreator(
        uint256 houseId,
        address creator
    ) external;

    function removeCreator(
        uint256 houseId,
        address creator
    ) external;

    function updateMetadata(
        uint256 houseId,
        string  memory metadata
    ) external;

    function updateFee(
        uint256 houseId,
        uint16  fee
    ) external;

    function updateName(
        string  memory name
    ) external;

    function updateBio(
        string  memory bioHash
    ) external;

    function updatePicture(
        string  memory pictureHash
    ) external;

    function createAuction(
        address tokenContract,
        uint256 tokenId,
        uint256 duration,
        uint256 reservePrice,
        uint256 houseId
    ) external returns (uint256);

    function setAuctionApproval(
        uint256 auctionId,
        bool approved
    ) external;

    function setAuctionReservePrice(
        uint256 auctionId,
        uint256 reservePrice
    ) external;

    function createBid(
        uint256 auctionId,
        uint256 amount
    ) external payable;

    function endAuction(
        uint256 auctionId
    ) external;

    function cancelAuction(
        uint256 auctionId
    ) external;
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
library UintSet {

    struct Set {
        // Storage of set values
        uint256[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(uint256 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Set storage set, uint256 value) internal returns (bool) {
        if (!contains(set, value)) {
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
    function remove(Set storage set, uint256 value) internal returns (bool) {
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
                uint256 lastvalue = set._values[lastIndex];

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
    function contains(Set storage set, uint256 value) internal view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(Set storage set) internal view returns (uint256) {
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
    function at(Set storage set, uint256 index) internal view returns (uint256) {
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
    function values(Set storage set) internal view returns (uint256[] memory) {
        return set._values;
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
 * As of v3.3.0, sets of type `address` (`addressSet`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library AddressSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // address values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in address.

    struct Set {
        // Storage of set values
        address[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(address => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Set storage set, address value) internal returns (bool) {
        if (!contains(set, value)) {
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
    function remove(Set storage set, address value) internal returns (bool) {
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
                address lastvalue = set._values[lastIndex];

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
    function contains(Set storage set, address value) internal view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(Set storage set) internal view returns (uint256) {
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
    function at(Set storage set, uint256 index) internal view returns (address) {
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
    function values(Set storage set) internal view returns (address[] memory) {
        return set._values;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title OrderedSet
 * @dev Ordered data structure. It has the properties of a mapping of uint256, but members are ordered
 * and can be enumerated. Values can only be inserted at the head or tail, but can be removed
 * from anywhere. Add, append, remove and contains are O(1). Enumerate is O(N).
 */
library OrderedSet {
    using Counters for Counters.Counter;

    struct Set {
        Counters.Counter counter;
        mapping (uint256 => uint256) _next;
        mapping (uint256 => uint256) _prev;
    }

    /**
     * @dev Insert an value as the new head.
     */
    function add(Set storage set, uint256 value) internal {
        _insert(set, 0, value, set._next[0]);
        set.counter.increment();
    }

    /**
     * @dev Insert an value as the new tail.
     */
    function append(Set storage set, uint256 value) internal {
        _insert(set, set._prev[0], value, 0);
        set.counter.increment();
    }

    /**
     * @dev Remove an value.
     */
    function remove(Set storage set, uint256 value) internal {
        set._next[set._prev[value]] = set._next[value];
        set._prev[set._next[value]] = set._prev[value];
        delete set._next[value];
        delete set._prev[value];
        set.counter.decrement();
    }

    /**
     * @dev Returns the head
     */
    function head(Set storage set) internal view returns (uint256) {
        return set._next[0];
    }

    /**
     * @dev Returns the tail
     */
    function tail(Set storage set) internal view returns (uint256) {
        return set._prev[0];
    }

    /**
     * @dev Returns the length
     */
    function length(Set storage set) internal view returns (uint256) {
        return set.counter.current();
    }

    /**
     * @dev Returns the next value.
     */
    function next(Set storage set, uint256 _value) internal view returns (uint256) {
        return set._next[_value];
    }

    /**
     * @dev Returns the previous value.
     */
    function prev(Set storage set, uint256 _value) internal view returns (uint256) {
        return set._prev[_value];
    }

    /**
     * @dev Returns true if the value is in the set.
     */
    function contains(Set storage set, uint256 value) internal view returns (bool) {
        return set._next[0] == value || set._next[value] != 0 || set._prev[value] != 0;
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Set storage set) internal view returns (uint256[] memory) {
        /*
        uint256[] memory result;

        assembly {
            result := set._values
        }

        return result;
        */
        uint256[] memory _values = new uint256[](set.counter.current());
        uint256 value = set._next[0];
        uint256 i = 0;
        while (value != 0) {
            _values[i] = value;
            value = set._next[value];
            i += 1;
        }
        return _values;
    }

    /**
     * @dev Return an array with n values in the set, starting after from
     */
    function valuesFromN(Set storage set, uint256 from, uint256 n) internal view returns (uint256[] memory) {
        uint256[] memory _values = new uint256[](n);
        uint256 value = set._next[from];
        uint256 i = 0;
        while (i < n) {
            _values[i] = value;
            value = set._next[value];
            i += 1;
        }
        return _values;
    }

    /**
     * @dev Insert a value between two values
     */
    function _insert(Set storage set, uint256 prev_, uint256 value, uint256 next_) private {
        set._next[prev_] = value;
        set._next[value] = next_;
        set._prev[next_] = value;
        set._prev[value] = prev_;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
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

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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

