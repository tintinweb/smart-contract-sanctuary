// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

import { ITux } from "./ITux.sol";
import { ITuxERC20 } from "./ITuxERC20.sol";
import { IAuctions } from "./IAuctions.sol";

import "./library/UintSet.sol";
import "./library/AddressSet.sol";
import "./library/OrderedSet.sol";
import "./library/RankedSet.sol";
import "./library/RankedAddressSet.sol";
import { IERC721, IERC165 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";


contract Auctions is
    IAuctions
{
    using UintSet for UintSet.Set;
    using AddressSet for AddressSet.Set;
    using OrderedSet for OrderedSet.Set;
    using RankedSet for RankedSet.Set;
    using RankedAddressSet for RankedAddressSet.Set;

    uint256 private _lastBidId;
    uint256 private _lastOfferId;
    uint256 private _lastHouseId;
    uint256 private _lastAuctionId;

    // TuxERC20 contract address
    address public tuxERC20;

    // Minimum amount of time left in seconds to an auction after a new bid is placed
    uint256 constant public timeBuffer = 900;  // 15 minutes -> 900 seconds

    // Minimum percentage difference between the last bid and the current bid
    uint16 constant public minimumIncrementPercentage = 500;  // 5%

    // Mapping from house name to house ID
    mapping(string => uint256) public houseIDs;

    // Mapping from keccak256(contract, token) to currently running auction ID
    mapping(bytes32 => uint256) public tokenAuction;

    // Mapping of token contracts
    mapping(address => IAuctions.TokenContract) public contracts;

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

    // Mapping from creator to token contracts
    mapping(address => AddressSet.Set) private _collections;

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

    // RankedSet of house IDs
    RankedSet.Set private _rankedHouses;

    // RankedAddressSet of creators
    RankedAddressSet.Set private _rankedCreators;

    // RankedAddressSet of collectors
    RankedAddressSet.Set private _rankedCollectors;

    // OrderedSet of active token contracts
    RankedAddressSet.Set private _rankedContracts;

    // OrderedSet of active houses
    OrderedSet.Set private _activeHouses;

    // OrderedSet of active auction IDs without a house ID
    OrderedSet.Set private _activeAuctions;


    bytes4 constant interfaceId = 0x80ac58cd; // ERC721 interfaceId
    bytes4 constant interfaceIdMetadata = 0x5b5e139f; // Metadata extension
    bytes4 constant interfaceIdEnumerable = 0x780e9d63; // Enumerable extension


    modifier auctionExists(uint256 auctionId) {
        require(
            auctions[auctionId].tokenOwner != address(0),
            "Does not exist");
        _;
    }

    modifier onlyHouseCurator(uint256 houseId) {
        require(
            msg.sender == houses[houseId].curator,
            "Not house curator");
        _;
    }


    /*
     * Constructor
     */
    constructor(
        address tuxERC20_
    ) {
        tuxERC20 = tuxERC20_;
    }

    function totalHouses() public view override returns (uint256) {
        return _lastHouseId;
    }

    function totalAuctions() public view override returns (uint256) {
        return _lastAuctionId;
    }

    function totalContracts() public view override returns (uint256) {
        return _rankedContracts.length();
    }

    function totalCreators() public view override returns (uint256) {
        return _rankedCreators.length();
    }

    function totalCollectors() public view override returns (uint256) {
        return _rankedCollectors.length();
    }

    function totalActiveHouses() public view override returns (uint256) {
        return _activeHouses.length();
    }

    function totalActiveAuctions() public view override returns (uint256) {
        return _activeAuctions.length();
    }

    function totalActiveHouseAuctions(uint256 houseId) public view override returns (uint256) {
        return _houseAuctions[houseId].length();
    }

    function getActiveHouses(uint256 from, uint256 n) public view override returns (uint256[] memory) {
        return _activeHouses.valuesFromN(from, n);
    }

    function getRankedHouses(uint256 from, uint256 n) public view override returns (uint256[] memory) {
        return _rankedHouses.valuesFromN(from, n);
    }

    function getRankedCreators(address from, uint256 n) public view override returns (address[] memory) {
        return _rankedCreators.valuesFromN(from, n);
    }

    function getRankedCollectors(address from, uint256 n) public view override returns (address[] memory) {
        return _rankedCollectors.valuesFromN(from, n);
    }

    function getRankedContracts(address from, uint256 n) public view override returns (address[] memory) {
        return _rankedContracts.valuesFromN(from, n);
    }

    function getCollections(address creator) external view override returns (address[] memory) {
        return _collections[creator].values();
    }

    function getAuctions(uint256 from, uint256 n) public view override returns (uint256[] memory) {
        return _activeAuctions.valuesFromN(from, n);
    }

    function getHouseAuctions(uint256 houseId, uint256 from, uint256 n) public view override returns (uint256[] memory) {
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
    {
        require(
            houseIDs[name] == 0,
            "Already exists");
        require(
            bytes(name).length > 0,
            "Name required");
        require(
            bytes(name).length <= 32,
            "Name too long");
        require(
            curator != address(0),
            "Address required");
        require(
            fee < 10000,
            "Fee too high");

        _lastHouseId += 1;
        uint256 houseId = _lastHouseId;

        houses[houseId].name = name;
        houses[houseId].curator = payable(curator);
        houses[houseId].fee = fee;
        houses[houseId].preApproved = preApproved;
        houses[houseId].metadata = metadata;

        _curatorHouses[curator].add(houseId);
        _rankedHouses.add(houseId);
        houseIDs[name] = houseId;

        ITuxERC20(tuxERC20).updateFeatured();
        ITuxERC20(tuxERC20).mint(msg.sender, 5 * 10**18);

        emit HouseCreated(
            houseId
        );
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
            "Already added");

        _houseCreators[houseId].add(creator);
        _creatorHouses[creator].add(houseId);

        ITuxERC20(tuxERC20).mint(msg.sender, 1 * 10**18);

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
            "Already removed");

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
            "Fee too high");

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
    {
        if (contracts[tokenContract].tokenContract == address(0)) {
            registerTokenContract(tokenContract);
        }

        address tokenOwner = IERC721(tokenContract).ownerOf(tokenId);
        require(
            msg.sender == tokenOwner ||
            msg.sender == IERC721(tokenContract).getApproved(tokenId),
            "Not owner or approved");

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
                "Not approved by curator");

            fee = houses[houseId].fee;
            preApproved = houses[houseId].preApproved;
            houses[houseId].activeAuctions += 1;
        }

        try ITux(tokenContract).tokenCreator(tokenId) returns (address creator) {
            if (!_rankedCreators.contains(creator)) {
                _rankedCreators.add(creator);
            }
        } catch {}

        _lastAuctionId += 1;
        uint256 auctionId = _lastAuctionId;

        tokenAuction[keccak256(abi.encode(tokenContract, tokenId))] = auctionId;

        _sellerAuctions[tokenOwner].add(auctionId);

        bool approved = (curator == address(0) || preApproved || curator == tokenOwner);

        if (houseId > 0) {
            if (approved == true) {
                _houseAuctions[houseId].add(auctionId);
                if (_activeHouses.head() != houseId) {
                    if (_activeHouses.contains(houseId)) {
                        _activeHouses.remove(houseId);
                    }
                    _activeHouses.add(houseId);
                }
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

        ITuxERC20(tuxERC20).updateFeatured();
        ITuxERC20(tuxERC20).mint(msg.sender, 10 * 10**18);

        emit AuctionCreated(
            auctionId
        );
    }

    function setAuctionApproval(uint256 auctionId, bool approved)
        public
        override
        auctionExists(auctionId)
    {
        IAuctions.Auction storage auction = auctions[auctionId];
        address curator = houses[auction.houseId].curator;

        require(
            curator == msg.sender,
            "Not auction curator");
        require(
            auction.firstBidTime == 0,
            "Already started");
        require(
            (approved == true && auction.approved == false) ||
            (approved == false && auction.approved == true),
            "Already in this state");

        auction.approved = approved;

        if (approved == true) {
            _houseAuctions[auction.houseId].add(auctionId);
            _houseQueue[auction.houseId].remove(auctionId);

            if (_activeHouses.head() != auction.houseId) {
                if (_activeHouses.contains(auction.houseId)) {
                    _activeHouses.remove(auction.houseId);
                }
                _activeHouses.add(auction.houseId);
            }
        }

        emit AuctionApprovalUpdated(
            auctionId,
            approved
        );
    }

    function setAuctionReservePrice(uint256 auctionId, uint256 reservePrice)
        public
        override
        auctionExists(auctionId)
    {
        IAuctions.Auction storage auction = auctions[auctionId];

        require(
            msg.sender == auction.tokenOwner,
            "Not token owner");
        require(
            auction.firstBidTime == 0,
            "Already started");

        auction.reservePrice = reservePrice;

        emit AuctionReservePriceUpdated(
            auctionId,
            reservePrice
        );
    }

    function createBid(uint256 auctionId)
        public
        payable
        override
        auctionExists(auctionId)
    {
        IAuctions.Auction storage auction = auctions[auctionId];

        require(
            auction.approved,
            "Not approved by curator");
        require(
            auction.firstBidTime == 0 ||
            block.timestamp < auction.firstBidTime + auction.duration,
            "Auction expired");
        require(
            msg.value >= auction.amount + (
                auction.amount * minimumIncrementPercentage / 10000),
            "Amount too low");
        require(
            msg.value >= auction.reservePrice,
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

        auction.amount = msg.value;
        auction.bidder = payable(msg.sender);

        if (auction.duration > 0) {
            _lastBidId += 1;
            uint256 bidId = _lastBidId;

            bids[bidId] = Bid({
                timestamp: block.timestamp,
                bidder: msg.sender,
                value: msg.value
            });

            _auctionBids[auctionId].add(bidId);
            _bidderAuctions[msg.sender].add(auctionId);
        }

        contracts[auction.tokenContract].bids += 1;

        try ITux(auction.tokenContract).tokenCreator(auction.tokenId) returns (address creator) {
            if (creator == auction.tokenOwner) {
                creatorStats[auction.tokenOwner].bids += 1;
            }
        } catch {}

        if (collectorStats[msg.sender].bids == 0) {
            _rankedCollectors.add(msg.sender);
        }
        collectorStats[msg.sender].bids += 1;

        if (auction.houseId > 0) {
            houses[auction.houseId].bids += 1;
            /* _rankedHouses.rankScore(auction.houseId, houses[auction.houseId].bids); // This gets too expensive... */

            _houseAuctions[auction.houseId].remove(auctionId);
            _houseAuctions[auction.houseId].add(auctionId);
        }

        bool extended = false;
        if (auction.duration > 0) {
          uint256 timeRemaining = auction.firstBidTime + auction.duration - block.timestamp;
          if (timeRemaining < timeBuffer) {
              auction.duration += timeBuffer - timeRemaining;
              extended = true;
          }
        }

        ITuxERC20(tuxERC20).updateFeatured();
        ITuxERC20(tuxERC20).mint(msg.sender, 10 * 10**18);

        emit AuctionBid(
            auctionId,
            msg.sender,
            msg.value,
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
        public
        override
        auctionExists(auctionId)
    {
        IAuctions.Auction storage auction = auctions[auctionId];

        require(
            uint256(auction.firstBidTime) != 0,
            "Not started");
        require(
            block.timestamp >=
            auction.firstBidTime + auction.duration,
            "Not ended");

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

        collectorStats[auction.bidder].bought += 1;
        collectorStats[auction.bidder].totalSpent += tokenOwnerProfit;
        contracts[auction.tokenContract].sales += 1;
        contracts[auction.tokenContract].total += tokenOwnerProfit;

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

        if (curator != address(0) && auction.fee > 0) {
            curatorFee = tokenOwnerProfit * auction.fee / 10000;
            tokenOwnerProfit = tokenOwnerProfit - curatorFee;
            _handleOutgoingBid(curator, curatorFee);
        }
        _handleOutgoingBid(auction.tokenOwner, tokenOwnerProfit);

        if (houseId > 0) {
            houses[houseId].feesTotal += curatorFee;
        }

        bytes32 auctionHash = keccak256(abi.encode(auction.tokenContract, auction.tokenId));
        _previousTokenAuctions[auctionHash].add(auctionId);
        delete tokenAuction[auctionHash];

        if (auction.duration > 0) {
            uint256 i = _auctionBids[auctionId].length();
            while (i > 0) {
                uint256 bidId = _auctionBids[auctionId].at(i - 1);
                _bidderAuctions[bids[bidId].bidder].remove(auctionId);
                i--;
            }
        }

        _sellerAuctions[auction.tokenOwner].remove(auctionId);

        ITuxERC20(tuxERC20).updateFeatured();
        ITuxERC20(tuxERC20).mint(msg.sender, 10 * 10**18);

        emit AuctionEnded(
            auctionId
        );
    }

    function buyAuction(uint256 auctionId)
        public
        payable
        override
    {
        createBid(auctionId);
        endAuction(auctionId);
    }

    function cancelAuction(uint256 auctionId)
        public
        override
        auctionExists(auctionId)
    {
        require(
            auctions[auctionId].tokenOwner == msg.sender,
            "Not auction owner");
        require(
            uint256(auctions[auctionId].firstBidTime) == 0,
            "Already started");

        _cancelAuction(auctionId);
    }

    function registerTokenContract(address tokenContract)
        public
        override
    {
        require(
            contracts[tokenContract].tokenContract == address(0),
            "Already registered");
        require(
            IERC165(tokenContract).supportsInterface(interfaceId),
            "Does not support ERC721");
        require(
            IERC165(tokenContract).supportsInterface(interfaceIdMetadata),
            "Does not support ERC721Metadata");
        require(
            IERC165(tokenContract).supportsInterface(interfaceIdEnumerable),
            "Does not support ERC721Enumerable");

        contracts[tokenContract].name = IERC721Metadata(tokenContract).name();
        contracts[tokenContract].tokenContract = tokenContract;

        try ITux(tokenContract).owner() returns(address owner) {
            if (owner != address(0)) {
                _collections[owner].add(tokenContract);
            }
        } catch {}

        _rankedContracts.add(tokenContract);

        ITuxERC20(tuxERC20).mint(msg.sender, 1 * 10**18);
    }

    function makeOffer(address tokenContract, uint256 tokenId)
        public
        payable
        override
    {
        require(
            IERC165(tokenContract).supportsInterface(interfaceId),
            "Does not support ERC721");

        bytes32 auctionHash = keccak256(abi.encode(tokenContract, tokenId));
        require(
            tokenAuction[auctionHash] == 0,
            "Auction exists");

        _lastOfferId += 1;
        uint256 offerId = _lastOfferId;

        offers[offerId] = Offer({
            tokenContract: tokenContract,
            tokenId: tokenId,
            from: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp
        });

        _tokenOffers[auctionHash].add(offerId);

        ITuxERC20(tuxERC20).mint(msg.sender, 1 * 10**18);
    }

    function acceptOffer(uint256 offerId)
        public
        override
    {
        IAuctions.Offer storage offer = offers[offerId];
        require(
            offer.tokenContract != address(0),
            "Does not exist");
        require(
            msg.sender == IERC721(offer.tokenContract).ownerOf(offer.tokenId) ||
            msg.sender == IERC721(offer.tokenContract).getApproved(offer.tokenId),
            "Not owner or approved");

        IERC721(offer.tokenContract).safeTransferFrom(msg.sender, offer.from, offer.tokenId);

        _handleOutgoingBid(msg.sender, offer.amount);

        bytes32 auctionHash = keccak256(abi.encode(offer.tokenContract, offer.tokenId));
        _tokenOffers[auctionHash].remove(offerId);

        delete offers[offerId];

        ITuxERC20(tuxERC20).mint(msg.sender, 1 * 10**18);
    }

    function cancelOffer(uint256 offerId)
        public
        override
    {
        IAuctions.Offer storage offer = offers[offerId];
        require(
            offer.from == msg.sender,
            "Not owner or missing");

        _handleOutgoingBid(msg.sender, offer.amount);

        bytes32 auctionHash = keccak256(abi.encode(offer.tokenContract, offer.tokenId));
        _tokenOffers[auctionHash].remove(offerId);

        delete offers[offerId];
    }

    function updateHouseRank(uint256 houseId)
        public
        override
    {
        require(
            _rankedHouses.scoreOf(houseId) < houses[houseId].bids,
            "Rank up to date");

        _rankedHouses.rankScore(houseId, houses[houseId].bids);

        ITuxERC20(tuxERC20).mint(msg.sender, 1 * 10**18);
    }

    function updateCreatorRank(address creator)
        public
        override
    {
        require(
            _rankedCreators.scoreOf(creator) < creatorStats[creator].bids,
            "Rank up to date");

        _rankedCreators.rankScore(creator, creatorStats[creator].bids);

        ITuxERC20(tuxERC20).mint(msg.sender, 1 * 10**18);
    }

    function updateCollectorRank(address collector)
        public
        override
    {
        require(
            _rankedCollectors.scoreOf(collector) < collectorStats[collector].bids,
            "Rank up to date");

        _rankedCollectors.rankScore(collector, collectorStats[collector].bids);

        ITuxERC20(tuxERC20).mint(msg.sender, 1 * 10**18);
    }

    function updateContractRank(address tokenContract)
        public
        override
    {
        require(
            _rankedContracts.scoreOf(tokenContract) < contracts[tokenContract].bids,
            "Rank up to date");

        _rankedContracts.rankScore(tokenContract, contracts[tokenContract].bids);

        ITuxERC20(tuxERC20).mint(msg.sender, 1 * 10**18);
    }

    function feature(uint256 auctionId, uint256 amount)
        public
        override
    {
        require(
            auctions[auctionId].tokenOwner == msg.sender,
            "Not token owner");
        ITuxERC20(tuxERC20).feature(auctionId, amount, msg.sender);
    }

    function cancelFeature(uint256 auctionId)
        public
        override
    {
        require(
            auctions[auctionId].tokenOwner == msg.sender,
            "Not token owner");
        ITuxERC20(tuxERC20).cancel(auctionId, msg.sender);
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

pragma solidity 0.8.9;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ITux is IERC721 {
    function owner() external view returns (address);
    function tokenCreator(uint256 tokenId) external view returns (address);
    function creatorTokens(address creator) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ITuxERC20 {
    function mint(address to, uint256 amount) external;

    function feature(
        uint256 auctionId,
        uint256 amount,
        address from
    ) external;

    function cancel(
        uint256 auctionId,
        address from
    ) external;

    function updateFeatured() external;
    function payouts() external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;


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
    }

    struct Account {
        string  name;
        string  bioHash;
        string  pictureHash;
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
        address from;
        uint256 amount;
        uint256 timestamp;
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
        address indexed bidder,
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

    function totalActiveHouses() external view returns (uint256);

    function totalActiveAuctions() external view returns (uint256);

    function totalActiveHouseAuctions(uint256 houseId) external view returns (uint256);

    function getActiveHouses(uint256 from, uint256 n) external view returns (uint256[] memory);

    function getRankedHouses(uint256 from, uint256 n) external view returns (uint256[] memory);

    function getRankedCreators(address from, uint256 n) external view returns (address[] memory);

    function getRankedCollectors(address from, uint256 n) external view returns (address[] memory);

    function getRankedContracts(address from, uint256 n) external view returns (address[] memory);

    function getCollections(address creator) external view returns (address[] memory);

    function getAuctions(uint256 from, uint256 n) external view returns (uint256[] memory);

    function getHouseAuctions(uint256 houseId, uint256 from, uint256 n) external view returns (uint256[] memory);

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
    ) external;

    function makeOffer(
        address tokenContract,
        uint256 tokenId
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
    ) external;

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
    ) external;

    function setAuctionApproval(
        uint256 auctionId,
        bool approved
    ) external;

    function setAuctionReservePrice(
        uint256 auctionId,
        uint256 reservePrice
    ) external;

    function createBid(
        uint256 auctionId
    ) external payable;

    function endAuction(
        uint256 auctionId
    ) external;

    function buyAuction(
      uint256 auctionId
    ) external payable;

    function cancelAuction(
        uint256 auctionId
    ) external;

    function feature(
        uint256 auctionId,
        uint256 amount
    ) external;

    function cancelFeature(
        uint256 auctionId
    ) external;

    function updateHouseRank(
        uint256 houseId
    ) external;

    function updateCreatorRank(
        address creator
    ) external;

    function updateCollectorRank(
        address collector
    ) external;

    function updateContractRank(
        address tokenContract
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

/**
 * @title OrderedSet
 * @dev Ordered data structure. It has the properties of a mapping of uint256, but members are ordered
 * and can be enumerated. Values can be inserted and removed from anywhere. Add, append, remove and
 * contains are O(1). Enumerate is O(N).
 */
library OrderedSet {

    struct Set {
        uint256 count;
        mapping (uint256 => uint256) _next;
        mapping (uint256 => uint256) _prev;
    }

    /**
     * @dev Insert a value between two values
     */
    function insert(Set storage set, uint256 prev_, uint256 value, uint256 next_) internal {
        set._next[prev_] = value;
        set._next[value] = next_;
        set._prev[next_] = value;
        set._prev[value] = prev_;
        set.count += 1;
    }

    /**
     * @dev Insert a value as the new head
     */
    function add(Set storage set, uint256 value) internal {
        insert(set, 0, value, set._next[0]);
    }

    /**
     * @dev Insert a value as the new tail
     */
    function append(Set storage set, uint256 value) internal {
        insert(set, set._prev[0], value, 0);
    }

    /**
     * @dev Remove a value
     */
    function remove(Set storage set, uint256 value) internal {
        set._next[set._prev[value]] = set._next[value];
        set._prev[set._next[value]] = set._prev[value];
        delete set._next[value];
        delete set._prev[value];
        if (set.count > 0) {
            set.count -= 1;
        }
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
        return set.count;
    }

    /**
     * @dev Returns the next value
     */
    function next(Set storage set, uint256 _value) internal view returns (uint256) {
        return set._next[_value];
    }

    /**
     * @dev Returns the previous value
     */
    function prev(Set storage set, uint256 _value) internal view returns (uint256) {
        return set._prev[_value];
    }

    /**
     * @dev Returns true if the value is in the set
     */
    function contains(Set storage set, uint256 value) internal view returns (bool) {
        return set._next[0] == value ||
               set._next[value] != 0 ||
               set._prev[value] != 0;
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
        uint256[] memory _values = new uint256[](set.count);
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
     * @dev Return an array with n values in the set, starting after "from"
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OrderedSet.sol";

/**
 * @title RankedSet
 * @dev Ranked data structure using two ordered sets, a mapping of scores to
 * boundary values and counter, a mapping of last ranked scores, and a highest
 * score.
 */
library RankedSet {
    using OrderedSet for OrderedSet.Set;

    struct RankGroup {
        uint256 count;
        uint256 start;
        uint256 end;
    }

    struct Set {
        uint256 highScore;
        mapping(uint256 => RankGroup) rankgroups;
        mapping(uint256 => uint256) scores;
        OrderedSet.Set rankedScores;
        OrderedSet.Set rankedItems;
    }

    /**
     * @dev Add an item at the end of the set
     */
    function add(Set storage set, uint256 item) internal {
        set.rankedItems.append(item);
        set.rankgroups[0].end = item;
        set.rankgroups[0].count += 1;
        if (set.rankgroups[0].start == 0) {
            set.rankgroups[0].start = item;
        }
    }

    /**
     * @dev Remove an item
     */
    function remove(Set storage set, uint256 item) internal {
        uint256 score = set.scores[item];
        delete set.scores[item];

        RankGroup storage rankgroup = set.rankgroups[score];
        if (rankgroup.count > 0) {
            rankgroup.count -= 1;
        }

        if (rankgroup.count == 0) {
            rankgroup.start = 0;
            rankgroup.end = 0;
            if (score == set.highScore) {
                set.highScore = set.rankedScores.next(score);
            }
            if (score > 0) {
                set.rankedScores.remove(score);
            }
        } else {
            if (rankgroup.start == item) {
                rankgroup.start = set.rankedItems.next(item);
            }
            if (rankgroup.end == item) {
                rankgroup.end = set.rankedItems.prev(item);
            }
        }

        set.rankedItems.remove(item);
    }

    /**
     * @dev Returns the head
     */
    function head(Set storage set) internal view returns (uint256) {
        return set.rankedItems._next[0];
    }

    /**
     * @dev Returns the tail
     */
    function tail(Set storage set) internal view returns (uint256) {
        return set.rankedItems._prev[0];
    }

    /**
     * @dev Returns the length
     */
    function length(Set storage set) internal view returns (uint256) {
        return set.rankedItems.count;
    }

    /**
     * @dev Returns the next value
     */
    function next(Set storage set, uint256 _value) internal view returns (uint256) {
        return set.rankedItems._next[_value];
    }

    /**
     * @dev Returns the previous value
     */
    function prev(Set storage set, uint256 _value) internal view returns (uint256) {
        return set.rankedItems._prev[_value];
    }

    /**
     * @dev Returns true if the value is in the set
     */
    function contains(Set storage set, uint256 value) internal view returns (bool) {
        return set.rankedItems._next[0] == value ||
               set.rankedItems._next[value] != 0 ||
               set.rankedItems._prev[value] != 0;
    }

    /**
     * @dev Returns a value's score
     */
    function scoreOf(Set storage set, uint256 value) internal view returns (uint256) {
        return set.scores[value];
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
        uint256[] memory _values = new uint256[](set.rankedItems.count);
        uint256 value = set.rankedItems._next[0];
        uint256 i = 0;
        while (value != 0) {
            _values[i] = value;
            value = set.rankedItems._next[value];
            i += 1;
        }
        return _values;
    }

    /**
     * @dev Return an array with n values in the set, starting after "from"
     */
    function valuesFromN(Set storage set, uint256 from, uint256 n) internal view returns (uint256[] memory) {
        uint256[] memory _values = new uint256[](n);
        uint256 value = set.rankedItems._next[from];
        uint256 i = 0;
        while (i < n) {
            _values[i] = value;
            value = set.rankedItems._next[value];
            i += 1;
        }
        return _values;
    }

    /**
     * @dev Rank new score
     */
    function rankScore(Set storage set, uint256 item, uint256 newScore) internal {
        RankGroup storage rankgroup = set.rankgroups[newScore];

        if (newScore > set.highScore) {
            remove(set, item);
            rankgroup.start = item;
            set.highScore = newScore;
            set.rankedItems.add(item);
            set.rankedScores.add(newScore);
        } else {
            uint256 score = set.scores[item];
            uint256 prevScore = set.rankedScores.prev(score);

            if (set.rankgroups[score].count == 1) {
                score = set.rankedScores.next(score);
            }

            remove(set, item);

            while (prevScore > 0 && newScore > prevScore) {
                prevScore = set.rankedScores.prev(prevScore);
            }

            set.rankedItems.insert(
                set.rankgroups[prevScore].end,
                item,
                set.rankgroups[set.rankedScores.next(prevScore)].start
            );

            if (rankgroup.count == 0) {
                set.rankedScores.insert(prevScore, newScore, score);
                rankgroup.start = item;
            }
        }

        rankgroup.end = item;
        rankgroup.count += 1;

        set.scores[item] = newScore;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OrderedSet.sol";
import "./OrderedAddressSet.sol";

/**
 * @title RankedSet
 * @dev Ranked data structure using two ordered sets, a mapping of scores to
 * boundary values, a mapping of last ranked scores, and a highest score.
 */
library RankedAddressSet {
    using OrderedSet for OrderedSet.Set;
    using OrderedAddressSet for OrderedAddressSet.Set;

    struct RankGroup {
        uint256 count;
        address start;
        address end;
    }

    struct Set {
        uint256 highScore;
        mapping(uint256 => RankGroup) rankgroups;
        mapping(address => uint256) scores;
        OrderedSet.Set rankedScores;
        OrderedAddressSet.Set rankedItems;
    }

    /**
     * @dev Add an item at the end of the set
     */
    function add(Set storage set, address item) internal {
        set.rankedItems.append(item);
        set.rankgroups[0].end = item;
        set.rankgroups[0].count += 1;
        if (set.rankgroups[0].start == address(0)) {
            set.rankgroups[0].start = item;
        }
    }

    /**
     * @dev Remove an item
     */
    function remove(Set storage set, address item) internal {
        uint256 score = set.scores[item];
        delete set.scores[item];

        RankGroup storage rankgroup = set.rankgroups[score];
        if (rankgroup.count > 0) {
            rankgroup.count -= 1;
        }

        if (rankgroup.count == 0) {
            rankgroup.start = address(0);
            rankgroup.end = address(0);
            if (score == set.highScore) {
                set.highScore = set.rankedScores.next(score);
            }
            if (score > 0) {
                set.rankedScores.remove(score);
            }
        } else {
            if (rankgroup.start == item) {
                rankgroup.start = set.rankedItems.next(item);
            }
            if (rankgroup.end == item) {
                rankgroup.end = set.rankedItems.prev(item);
            }
        }

        set.rankedItems.remove(item);
    }

    /**
     * @dev Returns the head
     */
    function head(Set storage set) internal view returns (address) {
        return set.rankedItems._next[address(0)];
    }

    /**
     * @dev Returns the tail
     */
    function tail(Set storage set) internal view returns (address) {
        return set.rankedItems._prev[address(0)];
    }

    /**
     * @dev Returns the length
     */
    function length(Set storage set) internal view returns (uint256) {
        return set.rankedItems.count;
    }

    /**
     * @dev Returns the next value
     */
    function next(Set storage set, address _value) internal view returns (address) {
        return set.rankedItems._next[_value];
    }

    /**
     * @dev Returns the previous value
     */
    function prev(Set storage set, address _value) internal view returns (address) {
        return set.rankedItems._prev[_value];
    }

    /**
     * @dev Returns true if the value is in the set
     */
    function contains(Set storage set, address value) internal view returns (bool) {
        return set.rankedItems._next[address(0)] == value ||
               set.rankedItems._next[value] != address(0) ||
               set.rankedItems._prev[value] != address(0);
    }

    /**
     * @dev Returns a value's score
     */
    function scoreOf(Set storage set, address value) internal view returns (uint256) {
        return set.scores[value];
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
        address[] memory _values = new address[](set.rankedItems.count);
        address value = set.rankedItems._next[address(0)];
        uint256 i = 0;
        while (value != address(0)) {
            _values[i] = value;
            value = set.rankedItems._next[value];
            i += 1;
        }
        return _values;
    }

    /**
     * @dev Return an array with n values in the set, starting after "from"
     */
    function valuesFromN(Set storage set, address from, uint256 n) internal view returns (address[] memory) {
        address[] memory _values = new address[](n);
        address value = set.rankedItems._next[from];
        uint256 i = 0;
        while (i < n) {
            _values[i] = value;
            value = set.rankedItems._next[value];
            i += 1;
        }
        return _values;
    }

    /**
     * @dev Rank new score
     */
    function rankScore(Set storage set, address item, uint256 newScore) internal {
        RankGroup storage rankgroup = set.rankgroups[newScore];

        if (newScore > set.highScore) {
            remove(set, item);
            rankgroup.start = item;
            set.highScore = newScore;
            set.rankedItems.add(item);
            set.rankedScores.add(newScore);
        } else {
            uint256 score = set.scores[item];
            uint256 prevScore = set.rankedScores.prev(score);

            if (set.rankgroups[score].count == 1) {
                score = set.rankedScores.next(score);
            }

            remove(set, item);

            while (prevScore > 0 && newScore > prevScore) {
                prevScore = set.rankedScores.prev(prevScore);
            }

            set.rankedItems.insert(
                set.rankgroups[prevScore].end,
                item,
                set.rankgroups[set.rankedScores.next(prevScore)].start
            );

            if (rankgroup.count == 0) {
                set.rankedScores.insert(prevScore, newScore, score);
                rankgroup.start = item;
            }
        }

        rankgroup.end = item;
        rankgroup.count += 1;

        set.scores[item] = newScore;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title OrderedSet
 * @dev Ordered data structure. It has the properties of a mapping of uint256, but members are ordered
 * and can be enumerated. Values can be inserted and removed from anywhere. Add, append, remove and
 * contains are O(1). Enumerate is O(N).
 */
library OrderedAddressSet {

    struct Set {
        uint256 count;
        mapping (address => address) _next;
        mapping (address => address) _prev;
    }

    /**
     * @dev Insert a value between two values
     */
    function insert(Set storage set, address prev_, address value, address next_) internal {
        set._next[prev_] = value;
        set._next[value] = next_;
        set._prev[next_] = value;
        set._prev[value] = prev_;
        set.count += 1;
    }

    /**
     * @dev Insert a value as the new head
     */
    function add(Set storage set, address value) internal {
        insert(set, address(0), value, set._next[address(0)]);
    }

    /**
     * @dev Insert a value as the new tail
     */
    function append(Set storage set, address value) internal {
        insert(set, set._prev[address(0)], value, address(0));
    }

    /**
     * @dev Remove a value
     */
    function remove(Set storage set, address value) internal {
        set._next[set._prev[value]] = set._next[value];
        set._prev[set._next[value]] = set._prev[value];
        delete set._next[value];
        delete set._prev[value];
        if (set.count > 0) {
            set.count -= 1;
        }
    }

    /**
     * @dev Returns the head
     */
    function head(Set storage set) internal view returns (address) {
        return set._next[address(0)];
    }

    /**
     * @dev Returns the tail
     */
    function tail(Set storage set) internal view returns (address) {
        return set._prev[address(0)];
    }

    /**
     * @dev Returns the length
     */
    function length(Set storage set) internal view returns (uint256) {
        return set.count;
    }

    /**
     * @dev Returns the next value
     */
    function next(Set storage set, address _value) internal view returns (address) {
        return set._next[_value];
    }

    /**
     * @dev Returns the previous value
     */
    function prev(Set storage set, address _value) internal view returns (address) {
        return set._prev[_value];
    }

    /**
     * @dev Returns true if the value is in the set
     */
    function contains(Set storage set, address value) internal view returns (bool) {
        return set._next[address(0)] == value ||
               set._next[value] != address(0) ||
               set._prev[value] != address(0);
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
        address[] memory _values = new address[](set.count);
        address value = set._next[address(0)];
        uint256 i = 0;
        while (value != address(0)) {
            _values[i] = value;
            value = set._next[value];
            i += 1;
        }
        return _values;
    }

    /**
     * @dev Return an array with n values in the set, starting after "from"
     */
    function valuesFromN(Set storage set, address from, uint256 n) internal view returns (address[] memory) {
        address[] memory _values = new address[](n);
        address value = set._next[from];
        uint256 i = 0;
        while (i < n) {
            _values[i] = value;
            value = set._next[value];
            i += 1;
        }
        return _values;
    }
}