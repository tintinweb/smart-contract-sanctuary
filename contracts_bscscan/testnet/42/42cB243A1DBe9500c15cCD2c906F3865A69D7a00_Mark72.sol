/**
 *Submitted for verification at BscScan.com on 2021-08-06
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.5;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

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

interface IYoloERC721 {
    function ownerOf(uint _tokenId) external view returns (address);

    function balanceOf(address _addr) external view returns (uint256);
    //TODO:: Implement in child contract
    function getMinter(uint _tokenId) external view returns (address);

    function marketTransfer(address _from, address _to, uint _nftId) external returns (bool);
}

interface IYoloDivSpotNFT {
    function getLastMintBlock() external view returns (uint);

    function getIdForAccount(address _acc) external view returns (uint);

    function receiveRewards(uint256 _dividendRewards) external;

    function burnToClaim() external;

    function create(address _account, uint256 _minReq) external returns (uint256);

    function getUnclaimed(address _account) external returns (uint256);

    function canMint(address _account) external view returns (bool);

    function getMinReq(uint256 _tokenId) external returns (uint256);

    function getIds() external view returns (uint[] memory);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function totalSupply() external view returns (uint);

    function getOpenDivSpotsCount() external view returns (uint);

    function getDivSpotAt(uint256 _tokenId) external view returns (uint256, uint, address, uint256, uint256);

    function myInfo() external view returns (
        uint rank,
        uint256 rewards,
        uint256 startMinReq,
        uint256 id,
        uint256 mintBlock
    );

    function getInfo(address _account) external view returns (uint rank, uint level, uint id);
}

interface IYoloLoyaltySpotNFT {
    function handleBuy(address _account, uint256 _amountBnb, uint256 _tokenAmount) external;

    function getInfo(address _account) external view returns (uint rank, uint level, uint id);

    function handleSold(address _account) external;

    function claim() external;

    function balanceOf(address owner) external view returns (uint256 balance);

    function totalSupply() external view returns (uint);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function receiveRewards(uint256 _reward) external;

    function myInfoFull() external view returns (
        uint rank, uint level,
        uint possibleClaimAmount, uint blocksLeftToClaim,
        uint buyVolumeBnb, uint sellVolumeBnb, uint lastLevelUpVolume,
        uint claimedRewards
    );

    function getIdForAccount(address _acc) external view returns (uint);

    function getBlocksUntilClaim(address _account) external returns (uint);

    function getRights(uint _tokenId) external view returns (uint, uint, uint);

    function getNextRankRights(uint _tokenId) external view returns (uint, uint, uint);

    function canEvolve(address _account) external returns (bool);

    function getClaimBlock(address _account) external returns (uint);

    function canMint(address _account) external view returns (bool);

    function create(address _account, uint256 _buyVolume, uint _yoloAmount) external returns (uint256 tokenId);

    function getMintPriceBnb() external view returns (uint);

    function getNextMintPriceBnb() external view returns (uint);

    function syncFund() external;
}


interface IArtifact {
    function create(address _account, uint _loyaltyId) external;

    function getRarity(uint256 _tokenId) external view returns (uint);
}

interface IYoloSpeedsterNFT {
    function create(address _account, uint _divSpotId) external;

    function balanceOf(address account) external view returns (uint256);
}


//TODO:: Protocol Fee Setters
//TODO:: Super Calls _transferFrom, ownerOf()
contract Mark72 is Ownable {
    //TODO:: Struct var stores mintAddress in each NFT contract
    uint public PROTOCOL_LISTING_FEE; // 0.1 BNB of each listing Service Cost
    uint public PROTOCOL_BUYING_FEE; // 2% of each Sell Service Cost
    uint public MIN_PRICE; // 1.0 BNB min Sell Price
    uint public ROYALTY_FEE;// 3% to mintAddress [ NFT initial creator ]

    uint public BID_WITHDRAW_CD;
    uint public MAX_OFFER_BLOCKS;

    struct Offer {
        uint nftId;
        IYoloERC721 nftContract;
        address seller;
        uint startPrice;
        uint instantBuyPrice;
        uint rarity;
        uint madeBlock;
        uint expiryBlock;
    }

    struct Bid {
        Offer offer;
        address bidder;
        uint amount;
        uint madeBlock;
    }

    // nftContract -> nftId
    mapping(IYoloERC721 => mapping(uint => Offer)) public offers;
    mapping(IYoloERC721 => mapping(uint => Bid)) public bids;

    mapping(address => uint) public pendingWithdrawals;

    IYoloERC721[] public whitelist;
    mapping(IYoloERC721 => uint[]) public contractToIds;

    IYoloLoyaltySpotNFT public Loyalty_Address;
    IYoloDivSpotNFT public Div_Address;
    IYoloSpeedsterNFT public Speedster_Address;
    IArtifact public Artefacts_Address;

    // Events
    event NFTOffered(IYoloERC721 nftContract, uint nftId, address seller, uint startPrice, uint instantBuyPrice);
    event NewBid(IYoloERC721 nftContract, uint nftId, address oldBidder, address newBidder, uint oldAmount, uint newAmount);
    event NftBought(IYoloERC721 nftContract, uint nftId, address seller, address buyer, uint amount);
    event NftBoughtInstant(IYoloERC721 nftContract, uint nftId, address seller, address buyer, uint amount);

    event NoLongerForSale(IYoloERC721 nftContract, uint nftId, address seller, uint startPrice, address bidder, uint bidAmount);
    event BidWithdrawn(IYoloERC721 nftContract, uint nftId, address bidder, uint amount);

    event WithdrawnBNB(address _to, uint _amount, uint timestamp);

    event ProtocolFeeDistributed(IYoloERC721 fromNftContract, uint _fromNftId, uint _amount);
    event RoyaltySent(address _toMinter, uint _amount);

    constructor(
        address _loyaltyAddr,
        address _divAddr,
        address _speedsterAddr,
        address _artefactsAddr
    ) {

        Loyalty_Address = IYoloLoyaltySpotNFT(_loyaltyAddr);
        Div_Address = IYoloDivSpotNFT(_divAddr);
        Speedster_Address = IYoloSpeedsterNFT(_speedsterAddr);
        Artefacts_Address = IArtifact(_artefactsAddr);

        // TODO: 1e17, floorPrice 1e18 [Mainnet values]

        PROTOCOL_LISTING_FEE = 1e14;
        // 1e17
        PROTOCOL_BUYING_FEE = 200;
        MIN_PRICE = 1e14;
        // 1e17
        ROYALTY_FEE = 300;
        // 6h
        BID_WITHDRAW_CD = 300;
        // 1200 * 6
        // 2 months
        MAX_OFFER_BLOCKS = 28800;
        // 28800 * 7

        // TODO: think about this !
        //        renounceOwnership();
    }

    /* --------- MODIFIERS --------- */
    uint private unlocked = 1;
    modifier antiReentrant() {
        require(unlocked == 1, 'ERROR: Anti-Reentrant');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    modifier onlyWhitelisted(IYoloERC721 _nftContract) {
        require(address(_nftContract) != address(0), 'ERROR: Zero address');
        require(this.inWhitelist(_nftContract), 'ERROR: Not Whitelisted');
        _;
    }

    function inWhitelist(IYoloERC721 _nftContract) public view returns (bool){
        uint l = whitelist.length;
        if (l == 0) {
            return false;
        }
        for (uint i = 0; i < l; i++) {
            if (address(whitelist[i]) == address(_nftContract)) {
                return true;
            }
        }
        return false;
    }


    /* --------- CREATE --------- */
    function offerNftForSale(IYoloERC721 _nftContract, uint _nftId, uint _startPrice, uint _instantBuyPrice) external payable antiReentrant onlyWhitelisted(_nftContract) {
        require(msg.sender == tx.origin, "EOA");
        // EXACT FEE not more otherwise STUCK
        require(msg.value == PROTOCOL_LISTING_FEE, "Not correct listing fee.");
        require(offers[_nftContract][_nftId].seller == address(0), "Already listed !");

        require(_startPrice < 1e24 && _instantBuyPrice < 1e24, "Don't Troll");

        address ownerOfNftId = _nftContract.ownerOf(_nftId);
        require(msg.sender == ownerOfNftId, "Not NFT Owner");
        require(ownerOfNftId != address(0), "0 address");

        require(_startPrice >= MIN_PRICE, "Min. Price");
        require(_instantBuyPrice >= _startPrice, "Instant Buy Should be bigger than bid start price");

        uint rarity = getRarity(_nftContract, _nftId, msg.sender);

        // Listing Fee Used to Buy Back Yolo Draw
        payable(this.owner()).transfer(PROTOCOL_LISTING_FEE);

        offers[_nftContract][_nftId] = Offer({
        nftId : _nftId,
        nftContract : _nftContract,
        seller : msg.sender,
        startPrice : _startPrice,
        instantBuyPrice : _instantBuyPrice,
        madeBlock : block.number,
        expiryBlock : block.number + MAX_OFFER_BLOCKS,
        rarity : rarity
        });

        contractToIds[_nftContract].push(_nftId);

        emit NFTOffered(_nftContract, _nftId, msg.sender, _startPrice, _instantBuyPrice);
        emit ProtocolFeeDistributed(_nftContract, _nftId, PROTOCOL_LISTING_FEE);
    }

    function getRarity(IYoloERC721 _nftContract, uint _nftId, address _account) public view returns (uint){
        if (address(_nftContract) == address(Loyalty_Address)) {
            (uint rank, uint level, uint id) = IYoloLoyaltySpotNFT(address(_nftContract)).getInfo(_account);
            return rank;
        } else if (address(_nftContract) == address(Div_Address)) {
            (uint rank, uint level, uint id) = IYoloDivSpotNFT(address(_nftContract)).getInfo(_account);
            return rank;
        } else if (address(_nftContract) == address(Speedster_Address)) {
            return 42;
        } else if (address(_nftContract) == address(Artefacts_Address)) {
            return IArtifact(address(_nftContract)).getRarity(_nftId);
        }

        return 0;
    }

    /* --------- DELETE --------- */

    function removeOffer(IYoloERC721 _nftContract, uint _nftId) external antiReentrant onlyWhitelisted(_nftContract) {
        require(msg.sender == tx.origin, "EOA");

        address ownerOfNftId = _nftContract.ownerOf(_nftId);
        require(ownerOfNftId != address(0), "0 address");
        require(msg.sender == ownerOfNftId, "Not NFT Owner");

        deleteOffer(_nftContract, _nftId);
    }

    function deleteOffer(IYoloERC721 _nftContract, uint _nftId) internal {
        Offer memory offer = offers[_nftContract][_nftId];

        Bid memory bid = bids[_nftContract][_nftId];
        if (bid.amount > 0) {
            //            pendingWithdrawals[bid.bidder] += bid.amount;
            payable(bid.bidder).transfer(bid.amount);

            delete bids[_nftContract][_nftId];
        }

        delete contractToIds[_nftContract];
        delete offers[_nftContract][_nftId];

        uint l = contractToIds[_nftContract].length;
        for (uint i = 0; i < l; i++) {
            if (contractToIds[_nftContract][i] == _nftId) {
                delete contractToIds[_nftContract][i];
                break;
            }
        }

        emit NoLongerForSale(_nftContract, _nftId, offer.seller, offer.startPrice, bid.bidder, bid.amount);
    }

    /* --------- BUY & BID --------- */
    function buyNft(IYoloERC721 _nftContract, uint _nftId) external payable antiReentrant {
        require(msg.sender == tx.origin, "EOA");

        Offer memory offer = offers[_nftContract][_nftId];

        (uint amountToSeller, uint amountFromBuyer,
        uint serviceFee, uint royaltyFee) = this.getFinalBuyPrice(_nftContract, _nftId);

        require(msg.value == amountFromBuyer, "Not exact sell price plus service fee");

        deleteOffer(_nftContract, _nftId);
        handleBuy(_nftContract, _nftId, serviceFee, royaltyFee, offer.seller, msg.sender);

        //        pendingWithdrawals[offer.seller] += finalAmountToSeller;
        payable(offer.seller).transfer(amountToSeller);

        emit NftBoughtInstant(_nftContract, _nftId, offer.seller, msg.sender, msg.value);
    }

    function enterBid(IYoloERC721 _nftContract, uint _nftId) external payable antiReentrant {
        require(msg.value > MIN_PRICE, "No value");
        require(msg.value < 1e24, "ERROR_TOO_MUCH_FOMO: FOMO IS REAL!");

        Offer memory offer = offers[_nftContract][_nftId];
        Bid memory existingBid = bids[_nftContract][_nftId];

        // Get Minimum Bid For NFT
        // if no bid, existing is 0
        require(msg.value > this.getMinimumBidAmount(_nftContract, _nftId), "Less than current bid");

        // Refund the PREVIOUS bid
        //            pendingWithdrawals[existingBid.bidder] += existingBid.amount;
        payable(existingBid.bidder).transfer(existingBid.amount);
        bids[_nftContract][_nftId].offer = offer;
        bids[_nftContract][_nftId].bidder = msg.sender;
        bids[_nftContract][_nftId].amount = msg.value;
        bids[_nftContract][_nftId].madeBlock = block.number;

        //protocol fee is included in msg.value
        emit NewBid(_nftContract, _nftId, existingBid.bidder, msg.sender, existingBid.amount, msg.value);

        // If bid price >= Instant Buy Price => Make Buy Automatically
        uint instBuyPrice = offer.instantBuyPrice;
        if (msg.value >= instBuyPrice) {
            handleAccept(_nftContract, _nftId, instBuyPrice, offer.seller, msg.sender);
            payable(offer.seller).transfer(instBuyPrice);
            emit NftBought(_nftContract, _nftId, offer.seller, msg.sender, instBuyPrice);

            // return;
            uint toRefundIfAny = msg.value - instBuyPrice;
            if (toRefundIfAny > 10000 wei) {
                payable(msg.sender).transfer(toRefundIfAny);
            }
        }

        // If you make a bid with more than the
        uint maxExtendedToBlock = offer.madeBlock + MAX_OFFER_BLOCKS + 7200;

        uint extendBlocks = 200;
        //If Bid is made in last 200blocks before expiry
        //And is before max extend period
        //Increase offer expiry by 10 minutes
        //Untill Max Extend Block Reached
        if (block.number >= offer.expiryBlock - extendBlocks
            && offer.expiryBlock + extendBlocks <= maxExtendedToBlock) {
            offers[_nftContract][_nftId].expiryBlock = offer.expiryBlock + extendBlocks;
        }
    }

    /* Sends NFT & Distributes fees */
    function handleBuy(IYoloERC721 _nftContract, uint _nftId, uint _serviceFee, uint _royaltyFee, address _from, address _to) internal {
        IYoloERC721 NftContract = _nftContract;

        // Royalty Payout
        address minter = NftContract.getMinter(_nftId);
        payable(minter).transfer(_royaltyFee);

        // Service Fee
        payable(this.owner()).transfer(_serviceFee);

        // Send Nft to msg.sender [ buyer ]
        NftContract.marketTransfer(_from, _to, _nftId);

        // Ensure transfer from worked
        // Ensure ownership is changed
        address newOwner = NftContract.ownerOf(_nftId);
        require(newOwner == msg.sender && NftContract.balanceOf(_from) == 0, "Buyer didn't receive his NFT");

        emit ProtocolFeeDistributed(_nftContract, _nftId, _serviceFee);
        emit RoyaltySent(minter, _royaltyFee);
    }

    function acceptBid(IYoloERC721 _nftContract, uint _nftId) external antiReentrant {
        Offer memory offer = offers[_nftContract][_nftId];
        require(msg.sender == offer.seller, "Not your offer !");

        address nftOwner = _nftContract.ownerOf(_nftId);
        require(msg.sender == nftOwner, "Not NFT Owner");
        require(nftOwner != address(0), "0 address");

        Bid memory bid = bids[_nftContract][_nftId];

        require(bid.amount > 0, "No bids");
        handleAccept(_nftContract, _nftId, bid.amount, offer.seller, bid.bidder);
    }

    function autoAcceptBid(IYoloERC721 _nftContract, uint _nftId) external antiReentrant {
        Offer memory offer = offers[_nftContract][_nftId];
        Bid memory bid = bids[_nftContract][_nftId];

        require(bid.amount > 0, "No bids");
        require(block.number >= offer.expiryBlock, "Not time yet !");

        handleAccept(_nftContract, _nftId, bid.amount, offer.seller, bid.bidder);
    }

    function handleAccept(IYoloERC721 _nftContract, uint _nftId, uint amount, address seller, address buyer) internal {
        uint serviceFee = amount * PROTOCOL_BUYING_FEE / 10000;
        uint royaltyFee = amount * ROYALTY_FEE / 10000;

        uint amountToSeller = amount - royaltyFee - serviceFee;

        deleteOffer(_nftContract, _nftId);

        handleBuy(_nftContract, _nftId, serviceFee, royaltyFee, seller, buyer);
        payable(seller).transfer(amountToSeller);

        emit NftBought(_nftContract, _nftId, seller, buyer, amount);
    }

    function withdrawBid(IYoloERC721 _nftContract, uint _nftId) external antiReentrant {
        Bid memory bid = bids[_nftContract][_nftId];

        require(bid.bidder == msg.sender, "You're not the bidder !");
        require(block.number >= bid.madeBlock + BID_WITHDRAW_CD, "Can't withdraw yet !");
        delete bids[_nftContract][_nftId];

        // Refund the bid
        payable(msg.sender).transfer(bid.amount);

        emit BidWithdrawn(_nftContract, _nftId, msg.sender, bid.amount);
    }

    /* Ensures the safety of the marketplace */
    function purgeOffers() external onlyOwner {
        bool didPurge = false;
        for (uint c = 0; c < whitelist.length; c++) {
            IYoloERC721 contr = whitelist[c];
            uint l = contractToIds[contr].length;
            for (uint i = 0; i < l; i++) {
                uint id = contractToIds[contr][i];
                Offer memory offer = offers[contr][id];
                if (offer.seller != IYoloERC721(offer.nftContract).ownerOf(id)
                    || offer.rarity != getRarity(offer.nftContract, offer.nftId, offer.seller) // TODO: div & loyalty only
                ) {
                    deleteOffer(offer.nftContract, id);
                    didPurge = true;
                    // TODO: event
                }
            }
        }

        require(didPurge, "Nothing to purge !");
    }

    //    function withdraw() external antiReentrant {
    //        uint amount = pendingWithdrawals[msg.sender];
    //        pendingWithdrawals[msg.sender] = 0;
    //        payable(msg.sender).transfer(amount);
    //
    //        emit WithdrawnBNB(msg.sender, amount, block.timestamp);
    //    }

    function getOfferMadeBlockAndExpiry(IYoloERC721 _nftContract, uint _nftId) external view returns (uint _madeBlock, uint _expiryBlock) {
        return (offers[_nftContract][_nftId].madeBlock, offers[_nftContract][_nftId].expiryBlock);
    }

    // Gets the amount of the minimum bid per Nft id
    function getMinimumBidAmount(IYoloERC721 _nftContract, uint _nftId) external view returns (uint _nextPossibleAmt) {
        Offer memory offer = offers[_nftContract][_nftId];
        Bid memory existingBid = bids[_nftContract][_nftId];

        if (existingBid.amount == 0) {
            // No Bid
            return offer.startPrice;
        }
        return existingBid.amount;
    }

    function getFinalBuyPrice(IYoloERC721 _nftContract, uint _nftId) external view returns (uint amountToSeller, uint amountFromBuyer, uint serviceFee, uint royaltyFee) {
        uint buyPrice = offers[_nftContract][_nftId].instantBuyPrice;
        serviceFee = buyPrice * PROTOCOL_BUYING_FEE / 10000;
        royaltyFee = buyPrice * ROYALTY_FEE / 10000;

        amountToSeller = buyPrice - royaltyFee - serviceFee;

        return (amountToSeller, buyPrice, serviceFee, royaltyFee);
    }

    function getAllContracts() public view returns (address[] memory){
        uint l = whitelist.length;
        address[] memory contracts = new address[](l);

        for (uint i = 0; i < l; i++) {
            contracts[i] = address(whitelist[i]);
        }
        return contracts;
    }

    function getIds(IYoloERC721 _nftContract) public view returns (uint[] memory ids){
        ids = contractToIds[_nftContract];
        return ids;
    }

    function getOffersCount() public view returns (uint count){
        uint l = whitelist.length;

        for (uint i = 0; i < l; i++) {
            count += contractToIds[whitelist[i]].length;
        }

        return count;
    }

    struct OfferPreview {
        uint nftId;
        IYoloERC721 nftContract;
        uint madeBlock;
        uint bidPrice;
        uint instantBuyPrice;
        uint rarity;
    }

    function getOffers(uint sortBy, uint start, uint count) public view returns (address[] memory contracts, uint[] memory ids){
        // Always with full length. If filters are passed --> replaces the first X items and overrides the "l" --> everything after l is ignored
        IYoloERC721[] memory contractList = whitelist;
        uint totalL;
        uint l;

        //        if (_nftContracts.length != 0) {
        //            for (uint i = 0; i < contractList.length; i++) {
        //                contractList[i] = IYoloERC721(_nftContracts[i]);
        //            }
        //            l = _nftContracts.length;
        //        } else {
        l = contractList.length;
        //        }

        for (uint i = 0; i < l; i++) {
            totalL += contractToIds[contractList[i]].length;
        }

        if (start == 0 && count == 0) {
            // Client wants all.
            count = totalL;
        } else {
            require(start < totalL, "No items");
        }

        OfferPreview[] memory preview = new OfferPreview[](totalL);

        {
            uint currL;
            for (uint i = 0; i < l; i++) {
                IYoloERC721 contr = contractList[i];
                uint idL = contractToIds[contr].length;
                for (uint j = 0; j < idL; j++) {
                    uint nftId = contractToIds[contr][j];

                    uint bidPrice = bids[contr][nftId].amount;
                    if (bidPrice == 0) {
                        bidPrice = offers[contr][nftId].startPrice;
                    }
                    preview[currL] = OfferPreview({
                    nftId : nftId,
                    nftContract : contr,
                    madeBlock : offers[contr][nftId].madeBlock,
                    rarity : offers[contr][nftId].rarity,
                    instantBuyPrice : offers[contr][nftId].instantBuyPrice,
                    bidPrice : bidPrice
                    });
                    currL++;
                }
            }
        }
        // Sorts by mutating the preview[]
        if (sortBy == 1) {
            quickSortBlock(preview);
        } else if (sortBy == 2) {
            quickSortBid(preview);
        } else if (sortBy == 3) {
            quickSortBuyPrice(preview);
        } else if (sortBy == 4) {
            quickSortRarity(preview);
        }

        uint returnL = count;
        uint end = start + count;
        if (end > totalL) {
            end = totalL;
            count = totalL - start;
        }

        address[] memory addresses = new address[](returnL);
        uint[] memory ids = new uint[](returnL);

        uint cl;
        for (uint i = start; i < end; i++) {
            addresses[cl] = address(preview[i].nftContract);
            ids[cl] = preview[i].nftId;
            cl++;
        }

        return (addresses, ids);
    }

    /* --------- SORT --------- */

    function quickSortBlock(OfferPreview[] memory preview) internal pure {
        if (preview.length > 1) {
            quickByBlock(preview, 0, preview.length - 1);
        }
    }

    function quickSortBid(OfferPreview[] memory preview) internal pure {
        if (preview.length > 1) {
            quickByBid(preview, 0, preview.length - 1);
        }
    }

    function quickSortBuyPrice(OfferPreview[] memory preview) internal pure {
        if (preview.length > 1) {
            quickByBuyPrice(preview, 0, preview.length - 1);
        }
    }

    function quickSortRarity(OfferPreview[] memory preview) internal pure {
        if (preview.length > 1) {
            quickByRarity(preview, 0, preview.length - 1);
        }
    }


    function quickByBlock(OfferPreview[] memory preview, uint _low, uint _high) internal pure {
        if (_low < _high) {
            uint pivotVal = preview[(_low + _high) / 2].madeBlock;

            uint low1 = _low;
            uint high1 = _high;
            for (;;) {
                while (preview[low1].madeBlock < pivotVal) low1++;
                while (preview[high1].madeBlock > pivotVal) high1--;
                if (low1 >= high1) {
                    break;
                }
                (preview[low1], preview[high1]) = (preview[high1], preview[low1]);
                low1++;
                high1--;
            }
            if (_low < high1) {
                quickByBlock(preview, _low, high1);
            }
            high1++;
            if (high1 < _high) {
                quickByBlock(preview, high1, _high);
            }
        }
    }

    function quickByBid(OfferPreview[] memory preview, uint _low, uint _high) internal pure {
        if (_low < _high) {
            uint pivotVal = preview[(_low + _high) / 2].bidPrice;

            uint low1 = _low;
            uint high1 = _high;
            for (;;) {
                while (preview[low1].bidPrice < pivotVal) low1++;
                while (preview[high1].bidPrice > pivotVal) high1--;
                if (low1 >= high1) {
                    break;
                }
                (preview[low1], preview[high1]) = (preview[high1], preview[low1]);
                low1++;
                high1--;
            }
            if (_low < high1) {
                quickByBlock(preview, _low, high1);
            }
            high1++;
            if (high1 < _high) {
                quickByBlock(preview, high1, _high);
            }
        }
    }

    function quickByBuyPrice(OfferPreview[] memory preview, uint _low, uint _high) internal pure {
        if (_low < _high) {
            uint pivotVal = preview[(_low + _high) / 2].instantBuyPrice;

            uint low1 = _low;
            uint high1 = _high;
            for (;;) {
                while (preview[low1].instantBuyPrice < pivotVal) low1++;
                while (preview[high1].instantBuyPrice > pivotVal) high1--;
                if (low1 >= high1) {
                    break;
                }
                (preview[low1], preview[high1]) = (preview[high1], preview[low1]);
                low1++;
                high1--;
            }
            if (_low < high1) {
                quickByBlock(preview, _low, high1);
            }
            high1++;
            if (high1 < _high) {
                quickByBlock(preview, high1, _high);
            }
        }
    }

    function quickByRarity(OfferPreview[] memory preview, uint _low, uint _high) internal pure {
        if (_low < _high) {
            uint pivotVal = preview[(_low + _high) / 2].rarity;

            uint low1 = _low;
            uint high1 = _high;
            for (;;) {
                while (preview[low1].rarity < pivotVal) low1++;
                while (preview[high1].rarity > pivotVal) high1--;
                if (low1 >= high1) {
                    break;
                }
                (preview[low1], preview[high1]) = (preview[high1], preview[low1]);
                low1++;
                high1--;
            }
            if (_low < high1) {
                quickByBlock(preview, _low, high1);
            }
            high1++;
            if (high1 < _high) {
                quickByBlock(preview, high1, _high);
            }
        }
    }


    /* --------- SETTERS --------- */

    function setProtocolValues(uint _listingFee, uint _buyingFee, uint _floor, uint _royalty) external onlyOwner {
        PROTOCOL_LISTING_FEE = _listingFee;
        PROTOCOL_BUYING_FEE = _buyingFee;
        MIN_PRICE = _floor;
        ROYALTY_FEE = _royalty;
    }

    function addToWhitelist(IYoloERC721 _nftContract) external onlyOwner {
        require(inWhitelist(_nftContract) == false, "Already in whitelist");
        uint l = whitelist.length;
        bool replaced = false;
        for (uint i = 0; i < l; i++) {
            if (address(whitelist[i]) == address(0)) {
                whitelist[i] = _nftContract;
                replaced = true;
            }
        }
        if (!replaced) {
            whitelist.push(_nftContract);
        }
    }

    // TODO: getWhitelist returns(address[])

    function removeFromWhite(IYoloERC721 _nftContract) external onlyOwner onlyWhitelisted(_nftContract) {
        uint l = whitelist.length;
        for (uint i = 0; i < l; i++) {
            if (address(whitelist[l]) == address(_nftContract)) {
                delete whitelist[l];
            }
        }
    }


    function setCoreContracts(
        address _loyaltyAddr,
        address _divAddr,
        address _speedsterAddr,
        address _artefactsAddr
    ) external onlyOwner {
        if (_loyaltyAddr != address(0)) {
            Loyalty_Address = IYoloLoyaltySpotNFT(_loyaltyAddr);
        }
        if (_divAddr != address(0)) {
            Div_Address = IYoloDivSpotNFT(_divAddr);
        }
        if (_speedsterAddr != address(0)) {
            Speedster_Address = IYoloSpeedsterNFT(_speedsterAddr);
        }
        if (_artefactsAddr != address(0)) {
            Artefacts_Address = IArtifact(_artefactsAddr);
        }
    }

    // TODO: prevent tokens getting locked somehow ?

    // TODO: how are we going to migrate if needed ?
}