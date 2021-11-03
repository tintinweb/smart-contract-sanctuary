pragma solidity >=0.6.2 <0.8.0;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';

import '@openzeppelin/contracts/proxy/Initializable.sol';
import './Locker.sol';
import './BaseMarket.sol';

contract AuctionMarket is Initializable, BaseMarket {
    using SafeMath for uint256;
    uint256 private _auctionId;
    uint256 private _minDuration;

    //[nft -> [tokenId -> auction]]
    address payable _locker;
    mapping(address => mapping(uint256 => Auction)) private _auctionsByNFTAndTokenID;
    mapping(uint256 => Auction) private _auctions;
    mapping(uint256 => Bid) private _bids;
    mapping(address => mapping(address => mapping(uint256 => uint256))) private _lockingCurrencyBalance;

    struct Bid {
        uint256 auctionId;
        uint256 bidTime;
        address bidder;
        uint256 price;
        bool isClaimed;
        bool isExist;
    }
    struct Auction {
        uint256 auctionId;
        address payable seller;
        address nftAddr;
        uint256 tokenId;
        uint256 initPrice;
        uint256 startTime;
        uint256 duration;
        address currency;
        uint256 nftType;
        uint256 amount;
        bool isExist;
        bool isClaimed;
        address payable royaltyReceiver;
        uint256 royaltyFee;
    }

    /// @notice New auction has been made
    /// @dev New auction has been made
    /// @param tokenId - tokenId which will be sold
    /// @param seller - address of seller who make the auction
    /// @param nftAddr - address of NFT contract which will be sold
    /// @param initPrice - amount of initial price which is starting point of the auction
    /// @param currency - type of payment token which will be used in the auction
    /// @param startTime - when the auction will be started, buyers can bid
    /// @param duration - in which the auction is valid
    event AuctionEvt(
        uint256 auctionId,
        address seller,
        address nftAddr,
        uint256 tokenId,
        uint256 initPrice,
        uint256 startTime,
        uint256 duration,
        address currency
    );
    /// @notice New claim has been done (eg. claimer received currency or nft)
    /// @dev New claim has been done (eg. claimer received currency or nft)
    /// @param auctionId is auction which event is emitted
    /// @param sender is claimer
    /// @param value is amount of currency or tokenId of nft
    /// @param typeOfValue type of value (0: NFT, 1: Klay, 2: KIP7)
    event Claim(uint256 auctionId, address sender, uint256 value, uint256 typeOfValue);

    event TransferFee(uint256 auctionId, uint256 commissionFee, uint256 royaltyFee);

    /// @notice Event when new bid is successful
    /// @dev Event when new bid is successful
    /// @param auctionId is id of auction which bidder want bid
    /// @param bidder is the owner of bidding order
    /// @param price is the price of owner who made the bid
    /// @param biddingTime is the timestamp when the bid has been made
    event BidEvt(uint256 auctionId, address bidder, uint256 price, uint256 biddingTime);

    /// @notice Emitted when sale or auction has been canceled
    /// @dev Emitted when sale or auction has been canceled
    /// @param id id of fixed price sale or auction which has been canceled
    event AuctionCanceled(uint256 id);

    event AuctionUpdated(uint256 auctionId, uint256 initPrice, uint256 startTime, uint256 duration, address currency);

    /// @dev Initialize data when want use the nft market for trading. Should be called in proxy when upgrading the nft marketing
    /// @param startAuctionId - it is the first of id of sale when user make the sale order
    /// @param minDuration - it is min of duration in which the buying or bidding order is valid
    function initialize(
        uint256 startAuctionId,
        uint256 minDuration,
        address payable lockerAddr,
        address payable feeWallet,
        address owner
    ) public initializer {
        require(minDuration > 0, 'Min duration must be zero');
        require(startAuctionId >= 0, 'Start sale id must be greater than zero');
        _minDuration = minDuration;
        _auctionId = startAuctionId;
        _locker = lockerAddr;
        _commissionFee = 0;
        // _commissionFee = 50000; //precision is 6 decimals, 50000 = 5% = 0.05
        _feePrecision = 1e6;
        _feeWallet = feeWallet;
        _transferOwnership(owner);
    }

    /// @dev This function allows make a new auction.
    /// @notice Make an new auction
    /// @param tokenId - tokenId which will be sold
    /// @param nftAddr - address of NFT contract which will be sold
    /// @param initPrice - amount of initial price which is starting point of the auction
    /// @param currency - type of payment token which will be used in the auction
    /// @param startTime - when the auction will be started, buyers can bid
    function makeAuction721(
        uint256 tokenId,
        address nftAddr,
        uint256 initPrice,
        address currency,
        uint256 startTime,
        uint256 duration,
        address payable royaltyReceiver,
        uint256 royaltyFee,
        uint256 salt,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256) {
        Auction memory newAuction;
        newAuction.tokenId = tokenId;
        newAuction.nftAddr = nftAddr;
        newAuction.seller = msg.sender;
        newAuction.initPrice = initPrice;
        newAuction.startTime = startTime;
        newAuction.duration = duration;
        newAuction.currency = currency;
        newAuction.isClaimed = false;
        newAuction.isExist = true;
        newAuction.nftType = 0;
        newAuction.amount = 1;
        newAuction.royaltyReceiver = royaltyReceiver;
        newAuction.royaltyFee = royaltyFee;

        RoyaltySignature memory saleSign;
        saleSign.nftAddr = nftAddr;
        saleSign.r = r;
        saleSign.v = v;
        saleSign.s = s;
        saleSign.royaltyFee = royaltyFee;
        saleSign.royaltyReceiver = royaltyReceiver;
        saleSign.tokenId = tokenId;
        saleSign.salt = salt;
        return _makeAuction(newAuction, saleSign);
    }

    /// @dev This function allows make a new auction.
    /// @notice Make an new auction
    /// @param tokenId - tokenId which will be sold
    /// @param nftAddr - address of NFT contract which will be sold
    /// @param initPrice - amount of initial price which is starting point of the auction
    /// @param currency - type of payment token which will be used in the auction
    /// @param startTime - when the auction will be started, buyers can bid
    function makeAuction1155(
        uint256 tokenId,
        address nftAddr,
        uint256 initPrice,
        address currency,
        uint256 startTime,
        uint256 duration,
        uint256 amount,
        address payable royaltyReceiver,
        uint256 royaltyFee,
        uint256 salt,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256) {
        Auction memory newAuction;
        newAuction.tokenId = tokenId;
        newAuction.nftAddr = nftAddr;
        newAuction.seller = msg.sender;
        newAuction.initPrice = initPrice;
        newAuction.startTime = startTime;
        newAuction.duration = duration;
        newAuction.currency = currency;
        newAuction.isClaimed = false;
        newAuction.isExist = true;
        newAuction.nftType = 1;
        newAuction.amount = amount;
        newAuction.royaltyReceiver = royaltyReceiver;
        newAuction.royaltyFee = royaltyFee;

        RoyaltySignature memory saleSign;
        saleSign.nftAddr = nftAddr;
        saleSign.r = r;
        saleSign.v = v;
        saleSign.s = s;
        saleSign.royaltyFee = royaltyFee;
        saleSign.royaltyReceiver = royaltyReceiver;
        saleSign.tokenId = tokenId;
        saleSign.salt = salt;
        return _makeAuction(newAuction, saleSign);
    }

    function _makeAuction(Auction memory auctionInfo, RoyaltySignature memory saleSign) internal returns (uint256) {
        require(_checkRoyaltyFeeSignature(saleSign) == true, 'Invalid Signature');

        //make sure the owner of tokenId is sender
        require(auctionInfo.nftAddr != address(0x0), 'Invalid nft address');
        require(auctionInfo.nftType == 0 || auctionInfo.nftType == 1, 'Invalid nft type');
        if (auctionInfo.nftType == 0) {
            IERC721 nft = IERC721(auctionInfo.nftAddr);
            require(nft.ownerOf(auctionInfo.tokenId) == msg.sender, 'Not permission or Invalid token Id');
            require(nft.getApproved(auctionInfo.tokenId) == address(this), 'Need to be approved');
            nft.safeTransferFrom(msg.sender, _locker, auctionInfo.tokenId);
        } else {
            IERC1155 nft = IERC1155(auctionInfo.nftAddr);
            require(nft.balanceOf(msg.sender, auctionInfo.tokenId) >= auctionInfo.amount, 'Invalid amount');
            require(nft.isApprovedForAll(msg.sender, address(this)), 'Market need permission on NFTs');
            nft.safeTransferFrom(msg.sender, _locker, auctionInfo.tokenId, auctionInfo.amount, '');
        }

        //validates price, currency, startTime, endTime
        require(auctionInfo.initPrice > 0, 'Price must be greater then zero');
        // require(currency != address(0x0), 'Invalid currency');
        require(auctionInfo.startTime > block.timestamp, 'Starttime must be after now');
        require(auctionInfo.duration > _minDuration, 'Duration must be equal or greater than min duration');
        //make sure the NFT is not in any sale
        require(
            _auctionsByNFTAndTokenID[auctionInfo.nftAddr][auctionInfo.tokenId].isExist == false,
            'Item is in sold already'
        );

        require(auctionInfo.amount > 0, 'Invalid amount');

        //make new auction
        _auctionId++;
        uint256 auctionId = _auctionId;

        auctionInfo.auctionId = auctionId;

        //store auction data
        _auctionsByNFTAndTokenID[auctionInfo.nftAddr][auctionInfo.tokenId] = auctionInfo;
        _auctions[auctionId] = auctionInfo;

        //emit event
        emit AuctionEvt(
            auctionInfo.auctionId,
            auctionInfo.seller,
            auctionInfo.nftAddr,
            auctionInfo.tokenId,
            auctionInfo.initPrice,
            auctionInfo.startTime,
            auctionInfo.duration,
            auctionInfo.currency
        );
        return auctionInfo.auctionId;
    }

    /// @dev Make a bid to auction when want to buy the item
    /// @param auctionId - id of auction in which wanted item is listed
    /// @param price - amount of payment token which allowed in the auction, you can pay to buy the item. this is amount of locked amount.
    /// @return true - bid order is successful, bid order is failed
    function bid(uint256 auctionId, uint256 price) external payable returns (bool) {
        //Make sure update klay of sender
        if (msg.value > 0) {
            //update klay sent to contract
            _lockingCurrencyBalance[address(0x0)][msg.sender][auctionId] = _lockingCurrencyBalance[address(0x0)][
                msg.sender
            ][auctionId].add(msg.value);
        }
        //check the auctionId is existed
        require(_auctions[auctionId].isExist == true, 'Not found auction');
        Auction memory auction;
        auction = _auctions[auctionId];

        require(msg.sender != auction.seller, 'Buyer/Seller must be different');
        //make sure it is in duration of auction
        require(block.timestamp >= auction.startTime, 'Auction is not started');
        require(block.timestamp <= auction.startTime.add(auction.duration), 'Bid must be in auction time');

        //must be equal or greater than init price
        require(auction.initPrice <= price, 'Bid must be equal or greater than init price');
        //make sure the price of current bid is greater than the previous highest bid
        uint256 hightestPrice = _bids[auctionId].price;
        require(hightestPrice < price, 'New bid must be greater than previous highest bids');

        //make sure the locking amount of the currency of buyer (msg.sender) is equal to price of the bid
        uint256 lockingAmount = _lockingCurrencyBalance[auction.currency][msg.sender][auctionId];

        if (lockingAmount < price) {
            //need to lock more amount of currency to make sure the bid become valid
            uint256 lockingAmountDelta = price.sub(lockingAmount);
            //auction by KIP7
            IERC20 currency = IERC20(auction.currency);
            //check msg.owner (bidder) has allow the NFT market contract permission to lock the price in the bid
            require(
                currency.allowance(msg.sender, address(this)) >= lockingAmountDelta,
                'Buyer need allow the contract lock their bid price'
            );
            //check msg.owner have enough balance of auction currency
            require(currency.balanceOf(msg.sender) >= lockingAmountDelta, 'Not enough price');
            currency.transferFrom(msg.sender, _locker, lockingAmountDelta);
            _lockingCurrencyBalance[auction.currency][msg.sender][auctionId] = price;
        }

        //update new hightest bid
        Bid memory newHightestBid;
        newHightestBid.auctionId = auctionId;
        newHightestBid.bidder = msg.sender;
        newHightestBid.bidTime = block.timestamp;
        newHightestBid.price = price;
        newHightestBid.isClaimed = false;
        newHightestBid.isExist = true;
        _bids[auctionId] = newHightestBid;
        emit BidEvt(newHightestBid.auctionId, newHightestBid.bidder, newHightestBid.price, newHightestBid.bidTime);

        return true;
    }

    /// @dev Require transfer the item to `msg.sender` if the `msg.sender` is the winner of `auctionId`.
    /// @param auctionId - id of auction which contains the item `msg.sender` win
    /// @return true - claim is successful, false - claim is failed
    function claimAuction(uint256 auctionId) external returns (bool) {
        // Locker locker = Locker(_locker);
        //make sure the auctionId is valid
        require(_auctions[auctionId].isExist == true, 'Not found auction');
        Auction memory auction;
        auction = _auctions[auctionId];
        //make sure the auction is stop
        require(auction.startTime.add(auction.duration) < block.timestamp, 'Auction had been not stopped yet');
        //check the claimer whether is buyer or seller
        if (auction.seller == msg.sender) {
            _claimForSeller(auction);
        } else {
            _claimForBidder(auction);
        }

        return true;
    }

    /// @dev Call it when claimer is seller (only for auction)
    /// @param auction contains information of auction
    function _claimForSeller(Auction memory auction) private {
        Locker locker = Locker(_locker);
        uint256 auctionId = auction.auctionId;
        require(auction.isClaimed == false, 'Duplicate claim');
        //check there is bid for the auction
        if (_bids[auctionId].isExist == false) {
            //transfer the nft back to seller if there is no bid
            locker.transferNFT(msg.sender, auction.nftAddr, auction.tokenId, auction.nftType, auction.amount);
            emit Claim(auction.auctionId, msg.sender, auction.tokenId, 0);
        } else {
            //transfer the currency to seller if there is a bid

            Bid memory highestBid = _bids[auctionId];

            (uint256 returnAmount, uint256 commissionAmount, uint256 royaltyAmount) = _computeFee(
                highestBid.price,
                auction.royaltyFee
            );

            if (commissionAmount > 0) {
                if (auction.currency == address(0x0)) {
                    _feeWallet.transfer(commissionAmount);
                } else {
                    locker.transferCurrency(_feeWallet, auction.currency, commissionAmount);
                }
            }

            if (royaltyAmount > 0) {
                if (auction.currency == address(0x0)) {
                    auction.royaltyReceiver.transfer(royaltyAmount);
                } else {
                    locker.transferCurrency(auction.royaltyReceiver, auction.currency, royaltyAmount);
                }
            }
            emit TransferFee(auctionId, commissionAmount, royaltyAmount);
            _claimCurrency(auctionId, msg.sender, auction.currency, returnAmount);
        }
        _auctions[auctionId].isClaimed = true;
    }

    /// @dev Call it when the claimer of auction is bidder
    /// @param auction contains information of auction
    function _claimForBidder(Auction memory auction) private {
        Locker locker = Locker(_locker);
        uint256 auctionId = auction.auctionId;
        //check msg.sender is winner or not
        require(_bids[auctionId].isExist == true, 'No bid for auction, can not claim as buyer');
        Bid memory highestBid = _bids[auctionId];
        if (highestBid.bidder == msg.sender) {
            //check duplicate claim
            require(highestBid.isClaimed == false, 'Duplicated claim');
            //msg.sender is winner

            locker.transferNFT(highestBid.bidder, auction.nftAddr, auction.tokenId, auction.nftType, auction.amount);

            _bids[auctionId].isClaimed = true;
            emit Claim(auction.auctionId, msg.sender, auction.tokenId, 0);

            //stake more currency than highest price. should return the reminding amount.
            //happend only when auction by Klay
            if (auction.currency == address(0x0)) {
                if (_lockingCurrencyBalance[auction.currency][msg.sender][auctionId] > highestBid.price) {
                    uint256 returnAmount = _lockingCurrencyBalance[auction.currency][msg.sender][auctionId] -
                        highestBid.price;
                    _claimCurrency(auctionId, msg.sender, auction.currency, returnAmount);
                }
            }
        } else {
            //not winner, try to check the msg.sender whether is bidder
            //return locking amount
            uint256 lockAmount = _lockingCurrencyBalance[auction.currency][msg.sender][auctionId];
            require(lockAmount > 0, 'No bid');
            _claimCurrency(auction.auctionId, msg.sender, auction.currency, lockAmount);
            delete _lockingCurrencyBalance[auction.currency][msg.sender][auctionId];
        }
    }

    /// @dev Call when return the amount of currency to `to` who are bidder or seller of the auction
    /// @param auctionId Id of auction which the `to` want to claim. Which will be used to emit the event
    /// @param to address which will receive the currency
    /// @param currency is type of currency will need to send to `to`
    /// @param amount is amount of currency transferred to `to`
    function _claimCurrency(
        uint256 auctionId,
        address payable to,
        address currency,
        uint256 amount
    ) private {
        uint256 t = 1;
        if (currency == address(0x0)) {
            to.transfer(amount);
        } else {
            t = 2;
            Locker locker = Locker(_locker);
            locker.transferCurrency(msg.sender, currency, amount);
        }
        emit Claim(auctionId, to, amount, t);
    }

    /// @notice Emitted when sale or auction has been canceled
    /// @dev Emitted when sale or auction has been canceled
    /// @param auctionId auctionId of auction which has been canceled
    function cancel(uint256 auctionId) external returns (bool) {
        require(_auctions[auctionId].isExist == true, 'Aucton is not existed');
        require(_auctions[auctionId].seller == msg.sender, 'No permission');
        require(_bids[auctionId].isExist == false, 'Can not cancel when there are bids');

        Locker locker = Locker(_locker);
        locker.transferNFT(
            _auctions[auctionId].seller,
            _auctions[auctionId].nftAddr,
            _auctions[auctionId].tokenId,
            _auctions[auctionId].nftType,
            _auctions[auctionId].amount
        );

        delete _auctions[auctionId];

        emit AuctionCanceled(auctionId);
        return true;
    }

    function _updateAuction(
        uint256 auctionId,
        uint256 initPrice,
        address currency,
        uint256 startTime,
        uint256 duration,
        uint256 sellAmount
    ) private returns (bool) {
        require(_auctions[auctionId].isExist == true, 'Aucton is not existed');
        Auction memory auction = _auctions[auctionId];
        require(auction.seller == msg.sender, 'Sender is not permission');
        require(_bids[auctionId].isExist == false, 'Can not update when there are bids');
        require(auction.initPrice > 0, 'Price must be greater than zero');
        require(startTime > block.timestamp, 'Starttime must be after now');
        require(duration > _minDuration, 'Duration must be equal or greater than min duration');
        require(sellAmount > 0, 'Invalid amount');
        if (auction.nftType == 1 && sellAmount != auction.amount) {
            if (sellAmount > auction.amount) {
                uint256 delta = sellAmount - auction.amount;
                IERC1155 nft = IERC1155(auction.nftAddr);
                require(nft.balanceOf(msg.sender, auction.tokenId) >= delta, 'Invalid amount');
                require(nft.isApprovedForAll(msg.sender, address(this)), 'Market need permission on NFTs');
                nft.safeTransferFrom(msg.sender, _locker, auction.tokenId, delta, '');
            } else {
                uint256 delta = auction.amount - sellAmount;
                Locker locker = Locker(_locker);
                locker.transferNFT(auction.seller, auction.nftAddr, auction.tokenId, auction.nftType, delta);
            }
        }
        auction.currency = currency;
        auction.initPrice = initPrice;
        auction.duration = duration;
        auction.startTime = startTime;
        auction.amount = sellAmount;
        _auctionsByNFTAndTokenID[auction.nftAddr][auction.tokenId] = auction;
        _auctions[auctionId] = auction;

        emit AuctionUpdated(auctionId, auction.initPrice, auction.startTime, auction.duration, auction.currency);
        return true;
    }

    function updateAuction721(
        uint256 auctionId,
        uint256 initPrice,
        address currency,
        uint256 startTime,
        uint256 duration
    ) external returns (bool) {
        return _updateAuction(auctionId, initPrice, currency, startTime, duration, 1);
    }

    function updateAuction1155(
        uint256 auctionId,
        uint256 initPrice,
        address currency,
        uint256 startTime,
        uint256 duration,
        uint256 sellAmount
    ) external returns (bool) {
        return _updateAuction(auctionId, initPrice, currency, startTime, duration, sellAmount);
    }

    function getAuction(uint256 auctionId)
        external
        view
        returns (
            uint256 id,
            address seller,
            address nftAddr,
            uint256 tokenId,
            uint256 initPrice,
            uint256 startTime,
            uint256 duration,
            address currency,
            uint256 nftType,
            uint256 amount,
            address royaltyReceiver,
            uint256 royaltyFee,
            bool isClaimed
        )
    {
        id = _auctions[auctionId].auctionId;
        seller = _auctions[auctionId].seller;
        nftAddr = _auctions[auctionId].nftAddr;
        tokenId = _auctions[auctionId].tokenId;
        initPrice = _auctions[auctionId].initPrice;
        startTime = _auctions[auctionId].startTime;
        duration = _auctions[auctionId].duration;
        currency = _auctions[auctionId].currency;
        nftType = _auctions[auctionId].nftType;
        amount = _auctions[auctionId].amount;
        royaltyReceiver = _auctions[auctionId].royaltyReceiver;
        royaltyFee = _auctions[auctionId].royaltyFee;
        isClaimed = _auctions[auctionId].isClaimed;
    }

    function getHighestBid(uint256 auctionId)
        external
        view
        returns (
            uint256 id,
            uint256 price,
            address bidder,
            uint256 bidTime
        )
    {
        id = auctionId;
        price = _bids[auctionId].price;
        bidder = _bids[auctionId].bidder;
        bidTime = _bids[auctionId].bidTime;
    }
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

pragma solidity >=0.6.0 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC1155Receiver.sol";
import "../../introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    constructor() internal {
        _registerInterface(
            ERC1155Receiver(address(0)).onERC1155Received.selector ^
            ERC1155Receiver(address(0)).onERC1155BatchReceived.selector
        );
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
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

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

pragma solidity >=0.6.2 <0.8.0;

import '@openzeppelin/contracts/utils/Context.sol';

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() public {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity >=0.6.2 <0.8.0;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC1155/ERC1155Receiver.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';

import './lib/Ownable.sol';

contract Locker is IERC721Receiver, ERC1155Receiver, Ownable {
    bytes4 private constant _KIP17_RECEIVED = 0x6745782b;
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    bytes4 private constant _KIP7_RECEIVED = 0x9d188c22;
    bytes4 private constant _ERC1155_RECEIVED =
        bytes4(keccak256('onERC1155Received(address,address,uint256,uint256,bytes)'));

    event NFTReceived(address operator, address from, uint256 tokenId, bytes data);
    event KIP7Received(address operator, address from, uint256 tokenId, bytes data);
    event ERC1155Received(address operator, address from, uint256 tokenId, uint256 amount, bytes data);

    constructor(address owner) public {
        _transferOwnership(owner);
    }

    function transferCurrency(
        address to,
        address currencyAddr,
        uint256 amount
    ) external onlyOwner returns (bool) {
        IERC20 currency = IERC20(currencyAddr);
        currency.transfer(to, amount);
        return true;
    }

    function transferNFT(
        address to,
        address nftAddr,
        uint256 tokenId
    ) external onlyOwner returns (bool) {
        IERC721 nft = IERC721(nftAddr);
        nft.safeTransferFrom(address(this), to, tokenId);
        return true;
    }

    function transferNFT(
        address to,
        address nftAddr,
        uint256 tokenId,
        uint256 nftType,
        uint256 amount
    ) external onlyOwner returns (bool) {
        if (nftType == 0) {
            IERC721 nft = IERC721(nftAddr);
            nft.safeTransferFrom(address(this), to, tokenId);
        } else {
            IERC1155 nft = IERC1155(nftAddr);
            nft.safeTransferFrom(address(this), to, tokenId, amount, '');
        }

        return true;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public override returns (bytes4) {
        emit NFTReceived(operator, from, tokenId, data);
        return _ERC721_RECEIVED;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) public override returns (bytes4) {
        emit ERC1155Received(operator, from, id, value, data);
        return _ERC1155_RECEIVED;
    }

    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) public override returns (bytes4) {
        return bytes4(keccak256('onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)'));
    }
}

pragma solidity >=0.6.2 <0.8.0;
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/proxy/Initializable.sol';
import '@openzeppelin/contracts/cryptography/ECDSA.sol';
import './lib/Ownable.sol';

contract BaseMarket is Ownable {
    using SafeMath for uint256;

    uint256 internal _commissionFee;
    uint256 internal _feePrecision;
    address payable internal _feeWallet;

    mapping(uint256 => bool) private _royaltySalt;

    struct RoyaltySignature {
        address nftAddr;
        uint256 tokenId;
        address payable royaltyReceiver;
        uint256 royaltyFee;
        uint256 salt;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
    event UpdatedCommissionFee(uint256 newCommissionFee);

    event UpdatedFeeWallet(address feeWallet);

    function updateFeeWallet(address payable feeWallet) external onlyOwner {
        require(feeWallet != address(0), 'Fee wallet is the zero address');
        _feeWallet = feeWallet;
        emit UpdatedFeeWallet(_feeWallet);
    }

    /// @notice Update the commission fee
    /// @dev Update the commission fee
    /// @param newCommissionFee new commission fee
    function updateCommissionFee(uint256 newCommissionFee) public onlyOwner {
        require(newCommissionFee < _feePrecision, 'Invalid commission fee');
        _commissionFee = newCommissionFee;
        emit UpdatedCommissionFee(_commissionFee);
    }

    /// @dev Compute the fee based on the transaction price
    /// @param price total transaction price
    /// @return returnAmount amount which would be return the seller
    /// @return commissionAmount fee paid to the platform
    function _computeFee(uint256 price, uint256 royaltyFee)
        internal
        view
        returns (
            uint256 returnAmount,
            uint256 commissionAmount,
            uint256 royaltyFeeAmount
        )
    {
        commissionAmount = price.mul(_commissionFee).div(_feePrecision);
        royaltyFeeAmount = price.mul(royaltyFee).div(_feePrecision);
        returnAmount = price.sub(commissionAmount).sub(royaltyFeeAmount);
    }

    function _checkRoyaltyFeeSignature(RoyaltySignature memory sign) internal returns (bool) {
        bool isValid = false;
        if (sign.royaltyFee >= _feePrecision) return false;
        address signer = ECDSA.recover(
            ECDSA.toEthSignedMessageHash(
                keccak256(
                    abi.encodePacked(
                        sign.nftAddr,
                        sign.tokenId,
                        sign.royaltyReceiver,
                        sign.royaltyFee,
                        sign.salt,
                        address(this)
                    )
                )
            ),
            sign.v,
            sign.r,
            sign.s
        );
        isValid = signer != address(0) && signer == owner() && _royaltySalt[sign.salt] == false;
        if (isValid) {
            _royaltySalt[sign.salt] = true;
        }

        return isValid;
    }
}