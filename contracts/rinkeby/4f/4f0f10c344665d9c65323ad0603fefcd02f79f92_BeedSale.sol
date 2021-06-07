// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./IERC20.sol";
import "./Counters.sol";

contract BeedSale is ERC721URIStorage {
    using Counters for Counters.Counter;

    // nft ids
    Counters.Counter private _tokenIds;

    // auction ids
    Counters.Counter private _auctionIds;

    event LogAuctionCreated(
        uint256 auctionId,
        uint256 tokenId,
        address owner,
        uint256 startBlock,
        uint256 blocksRun,
        uint256 minPrice,
        uint256 maxPrice
    );

    event LogBid(
        uint256 auctionId,
        address bidder,
        uint256 bid,
        address highestBidder,
        uint256 highestBindingBid
    );
    event LogFinishSale(
        uint256 auctionId,
        address withdrawer,
        address withdrawalAccount,
        uint256 amount
    );
    event LogWithdrawal(
        uint256 auctionId,
        uint256 tokenId,
        address withdrawer,
        address withdrawalAccount,
        uint256 amount
    );
    event LogCanceled(uint256 auctionId);

    struct BeeditWinParams {
        // percentage in base points (10000 = 100%) for 1st bidder - beedit Win
        uint256 beeditWinPercentage;
        // fixed win for 1st bidder - beedit Win
        uint256 beeditWinFixed;
    }

    struct AuctionPriceData {
        // time of auction start by block
        uint256 startBlock;
        // time of auction ended by block
        uint256 endBlock;
        // time of auction in blocks
        uint256 blocksRun;
        // item hash value
        // string itemURI;
        // item min price
        uint256 minPrice;
        // item max price
        uint256 maxPrice;
    }

    struct Auction {
        // STATIC
        // item token id
        uint256 tokenId;
        // auction owner
        address owner;
        // payment allowed token
        address paymentToken;
        // creator royalty percentage in base points (10000 = 100%)
        BeeditWinParams beeditWinParams;
        AuctionPriceData auctionPriceData;
        // STATE
        // if auction canceled
        bool canceled;
        // if auction started
        bool started;
        // if sale finished
        // bool saleFinished;
        // top bidder
        address highestBidder;
        // bidders
        mapping(address => uint256) bidders;
        // highest bid
        uint256 highestBindingBid;
        // is sale finished - owner withdrawn money
        bool ownerHasWithdrawn;
        // first bidder
        address firstBidder;
    }

    // base uri / uri type
    string private _baseTokenURI;
    // fee percentage in base points (10000 = 100%)
    uint256 public _feePercentage;
    // fee address
    address payable public _feeAddress;

    struct TokenMeta {
        address creator;
        uint256 royalty;
        uint256 activeTokenAuction;
    }

    // mapping token id to token metadata
    mapping(uint256 => TokenMeta) private _tokenMetas;

    // allowed erc20 to payment
    mapping(address => bool) private allowedTokens;

    // auctions
    mapping(uint256 => Auction) private auctions;

    // remember user owned tokens
    // mapping(address => uint256[]) public userOwnedTokens;
    // mapping(uint256 => int256) public tokenIsAtIndex;

    // remember user participated auctions
    mapping(address => uint256[]) public userParticipatedAuction;
    mapping(uint256 => int256) public userParticipatedAuctionAtIndex;

    struct ContractBalance {
        mapping(address => uint256) amounts;
    }

    // royaltiesToPay
    mapping(address => ContractBalance) private _royaltiesToPay;

    // service fees mapping from payment token to value
    ContractBalance private serviceFees;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        address payable feeAddress,
        uint256 feePercentage,
        address[] memory _addresses
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
        _feeAddress = feeAddress;
        _feePercentage = feePercentage;
        for (uint256 index = 0; index < _addresses.length; index++) {
            allowedTokens[_addresses[index]] = true;
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // Total supply of nft tokens
    function totalSupply() public view virtual returns (uint256) {
        return _tokenIds.current();
    }

    // set allowed tokens for payments
    // function setAllowedTokens(address[] memory _addresses) public {
    //     allowedTokens = _addresses;
    // }

    // Mint item without put on sale
    function mintItem(string memory _itemURI, uint256 _royalty)
        public
        returns (uint256)
    {
        // Bump token number ID
        _tokenIds.increment();

        // Get current token ID
        uint256 newItemId = _tokenIds.current();

        // Add token to user owned list
        // userOwnedTokens[msg.sender].push(newItemId);
        // uint256 arrayLength = userOwnedTokens[msg.sender].length;
        // tokenIsAtIndex[newItemId] = int256(arrayLength);

        // Mint item to sender
        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, _itemURI);

        // Set ownership and royalty
        _setOwnershipAndRoyalty(newItemId, _royalty);

        return newItemId;
    }

    // Mint item with starting auction
    function mintAuction(
        address _paymentToken,
        uint256 _minPrice,
        uint256 _maxPrice,
        uint256 _startBlock,
        uint256 _blocksRun,
        uint256 _royalty,
        uint256 _beeditWinPercentage,
        uint256 _beeditWinFixed,
        string memory _itemURI
    ) public returns (uint256) {
        // Get current token ID
        uint256 newItemId = mintItem(_itemURI, _royalty);

        // Start auction
        _listAuction(
            newItemId,
            _paymentToken,
            _minPrice,
            _maxPrice,
            _startBlock,
            _blocksRun,
            _beeditWinPercentage,
            _beeditWinFixed
        );

        return newItemId;
    }

    function _setOwnershipAndRoyalty(uint256 _tokenId, uint256 _royalty)
        internal
        returns (bool)
    {
        TokenMeta storage tm = _tokenMetas[_tokenId];
        tm.creator = msg.sender;
        require(
            _royalty <= 100000,
            "Royalty percentage should be less then 100000"
        );
        tm.royalty = _royalty;
        return true;
    }

    function listAuction(
        uint256 _tokenId,
        address _paymentToken,
        uint256 _minPrice,
        uint256 _maxPrice,
        uint256 _startBlock,
        uint256 _blocksRun,
        uint256 _beeditWinPercentage,
        uint256 _beeditWinFixed
    ) public returns (uint256) {
        require(
            ownerOf(_tokenId) == msg.sender,
            "Owner should be token holder"
        );
        // Start auction
        return
            _listAuction(
                _tokenId,
                _paymentToken,
                _minPrice,
                _maxPrice,
                _startBlock,
                _blocksRun,
                _beeditWinPercentage,
                _beeditWinFixed
            );
    }

    function _listAuction(
        uint256 _tokenId,
        address _paymentToken,
        uint256 _minPrice,
        uint256 _maxPrice,
        uint256 _startBlock,
        uint256 _blocksRun,
        uint256 _beeditWinPercentage,
        uint256 _beeditWinFixed
    ) internal returns (uint256 auctionId) {
        require(_exists(_tokenId), "Token id should exist");
        require(
            _tokenMetas[_tokenId].activeTokenAuction == 0,
            "Token auction shouldn't be active"
        );

        // Bump auction number ID
        _auctionIds.increment();

        // Get current token ID
        uint256 newAuctionId = _auctionIds.current();

        // Create auction object
        Auction storage a = auctions[newAuctionId];
        a.tokenId = _tokenId;
        a.owner = msg.sender;
        a.auctionPriceData.minPrice = _minPrice;
        a.auctionPriceData.maxPrice = _maxPrice;

        if (_paymentToken != address(0)) {
            // check if token allowed to use
            require(
                allowedTokens[_paymentToken],
                "Payment token should be allowed"
            );
            a.paymentToken = _paymentToken;
        }

        if (_beeditWinFixed > 0) {
            require(
                _beeditWinFixed < _minPrice,
                "beediT Win fixed should be less then min price"
            );
            a.beeditWinParams.beeditWinFixed = _beeditWinFixed;
        } else if (_beeditWinPercentage > 0) {
            require(
                _beeditWinPercentage < 10000,
                "beediT Win percentage should be between 1 and 10000"
            );
            a.beeditWinParams.beeditWinPercentage = _beeditWinPercentage;
        }

        if (_startBlock < block.number) {
            a.auctionPriceData.startBlock = block.number;
        } else {
            a.auctionPriceData.startBlock = _startBlock;
        }
        a.auctionPriceData.blocksRun = _blocksRun;

        TokenMeta storage tm = _tokenMetas[a.tokenId];
        tm.activeTokenAuction = newAuctionId;

        emit LogAuctionCreated(
            newAuctionId,
            a.tokenId,
            a.owner,
            a.auctionPriceData.startBlock,
            a.auctionPriceData.blocksRun,
            a.auctionPriceData.minPrice,
            a.auctionPriceData.maxPrice
        );

        return newAuctionId;
    }

    function getAuctionTokenId(uint256 _auctionId)
        public
        view
        returns (uint256)
    {
        return auctions[_auctionId].tokenId;
    }

    function getTokenCreatorRoyalty(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        return _tokenMetas[_tokenId].royalty;
    }

    function getActiveTokenAuction(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        return _tokenMetas[_tokenId].activeTokenAuction;
    }

    function getAuctionStarted(uint256 _auctionId)
        public
        view
        onlyExistedAuction(_auctionId)
        returns (bool)
    {
        if (auctions[_auctionId].started)
            return
                block.number < auctions[_auctionId].auctionPriceData.endBlock;
        return false;
    }

    function getAuctionBidderLockedAmount(uint256 _auctionId, address bidder)
        public
        view
        onlyExistedAuction(_auctionId)
        returns (uint256)
    {
        return auctions[_auctionId].bidders[bidder];
    }

    function getAuctionOwner(uint256 _auctionId)
        public
        view
        onlyExistedAuction(_auctionId)
        returns (address)
    {
        return auctions[_auctionId].owner;
    }

    function getAuctionMinPrice(uint256 _auctionId)
        public
        view
        onlyExistedAuction(_auctionId)
        returns (uint256)
    {
        return auctions[_auctionId].auctionPriceData.minPrice;
    }

    function getAuctionMaxPrice(uint256 _auctionId)
        public
        view
        onlyExistedAuction(_auctionId)
        returns (uint256)
    {
        return auctions[_auctionId].auctionPriceData.maxPrice;
    }

    function getAuctionStartBlock(uint256 _auctionId)
        public
        view
        onlyExistedAuction(_auctionId)
        returns (uint256)
    {
        return auctions[_auctionId].auctionPriceData.startBlock;
    }

    function getAuctionBlocksRun(uint256 _auctionId)
        public
        view
        onlyExistedAuction(_auctionId)
        returns (uint256)
    {
        return auctions[_auctionId].auctionPriceData.blocksRun;
    }

    function getAuctionEndBlock(uint256 _auctionId)
        public
        view
        onlyExistedAuction(_auctionId)
        onlyAfterStart(_auctionId)
        returns (uint256)
    {
        return auctions[_auctionId].auctionPriceData.endBlock;
    }

    function getBlocksLeftToEnd(uint256 _auctionId)
        public
        view
        onlyExistedAuction(_auctionId)
        onlyAfterStart(_auctionId)
        returns (uint256)
    {
        return auctions[_auctionId].auctionPriceData.endBlock - block.number;
    }

    function getAuctionCurrentPrice(uint256 _auctionId)
        public
        view
        onlyExistedAuction(_auctionId)
        returns (uint256)
    {
        return calculateCurrentPrice(_auctionId);
    }

    function getRoyaltyForAddress(address _address, address _paymentToken)
        public
        view
        returns (uint256)
    {
        return _royaltiesToPay[_address].amounts[_paymentToken];
    }

    function getServiceFees(address _paymentToken)
        public
        view
        returns (uint256)
    {
        return serviceFees.amounts[_paymentToken];
    }

    function makeBid(uint256 _auctionId)
        public
        payable
        onlyExistedAuction(_auctionId)
        onlyAfterStart(_auctionId)
        // onlyBeforeEnd
        onlyNotCanceled(_auctionId)
        onlyNotOwner(_auctionId)
        returns (bool success)
    {
        Auction storage a = auctions[_auctionId];
        uint256 newBid;
        if (a.paymentToken == address(0)) {
            // reject payments of 0 ETH
            require(msg.value > 0, "Bid should be more then 0 ETH");
            newBid = msg.value;
        }
        // check if first bid not yet made
        if (!a.started) {
            // check if bid is same as min price
            if (newBid == 0) {
                newBid = _receiveTokenMoney(
                    a.paymentToken,
                    a.auctionPriceData.minPrice
                );
            } else
                newBid = _keepMoneyOrRefund(
                    newBid,
                    a.auctionPriceData.minPrice
                );
            // store bid of bidder
            a.bidders[msg.sender] = newBid;
            a.firstBidder = msg.sender;
            a.highestBindingBid = newBid;
            a.highestBidder = msg.sender;
            // mark that sale is started
            a.started = true;
            // set finish block
            a.auctionPriceData.endBlock =
                block.number +
                a.auctionPriceData.blocksRun;
        } else {
            uint256 currentPrice = calculateCurrentPrice(_auctionId);
            // when same bidder makes second bid
            if (a.bidders[msg.sender] > 0) {
                uint256 amountToPay = currentPrice - a.bidders[msg.sender];
                uint256 paidAmount;

                if (newBid == 0) {
                    paidAmount = _receiveTokenMoney(
                        a.paymentToken,
                        amountToPay
                    );
                } else paidAmount = _keepMoneyOrRefund(newBid, amountToPay);

                newBid = a.bidders[msg.sender] + paidAmount;
                require(
                    newBid == currentPrice,
                    "Received amount should match for second bid from single buyer"
                );
            } else {
                if (newBid == 0) {
                    newBid = _receiveTokenMoney(a.paymentToken, currentPrice);
                } else newBid = _keepMoneyOrRefund(newBid, currentPrice);
            }

            // finish sale
            a.bidders[msg.sender] = newBid;
            a.highestBindingBid = newBid;
            a.highestBidder = msg.sender;

            a.auctionPriceData.endBlock = block.number;
        }
        // Add auction to user participated auction list
        userParticipatedAuction[msg.sender].push(_auctionId);
        uint256 arrayLength = userParticipatedAuction[msg.sender].length;
        userParticipatedAuctionAtIndex[_auctionId] = int256(arrayLength);

        emit LogBid(
            _auctionId,
            msg.sender,
            newBid,
            a.highestBidder,
            a.highestBindingBid
        );
        return true;
    }

    /**
     * Calculate price timer
     */
    function calculateCurrentPrice(uint256 _tokenId)
        public
        view
        onlyExistedAuction(_tokenId)
        onlyNotCanceled(_tokenId)
        returns (uint256 price)
    {
        Auction storage a = auctions[_tokenId];
        require(a.owner != address(0), "Auction not found");

        if (
            !a.started ||
            (a.started && (block.number >= a.auctionPriceData.endBlock))
        ) return a.auctionPriceData.minPrice;
        uint256 totalTicks =
            a.auctionPriceData.maxPrice - a.auctionPriceData.minPrice;
        uint256 ticksPerBlock = totalTicks / a.auctionPriceData.blocksRun;
        uint256 deltaPrice =
            (a.auctionPriceData.endBlock - block.number) * ticksPerBlock;
        return deltaPrice + a.auctionPriceData.minPrice;
    }

    function _receiveTokenMoney(address paymentToken, uint256 neededMoney)
        internal
        returns (uint256 keepedMoney)
    {
        require(
            IERC20(paymentToken).transferFrom(
                msg.sender,
                address(this),
                neededMoney
            ),
            "Token transfer not allowed"
        );
        return neededMoney;
    }

    /**
     * Keep only needed money, other refund back
     */
    function _keepMoneyOrRefund(uint256 sentMoney, uint256 neededMoney)
        internal
        returns (uint256 keepedMoney)
    {
        require(
            sentMoney >= neededMoney,
            "Should sent same or more money then required"
        );
        if (sentMoney == neededMoney) return sentMoney;
        uint256 toSendBack = sentMoney - neededMoney;
        assert(payable(msg.sender).send(toSendBack));
        return neededMoney;
    }

    function withdraw(uint256 _auctionId)
        public
        onlyExistedAuction(_auctionId)
        onlyEndedOrCanceled(_auctionId)
        returns (bool success)
    {
        address withdrawalAccount;
        uint256 withdrawalAmount;

        Auction storage a = auctions[_auctionId];

        if (a.canceled) {
            // if auction canceled, everyone can withdraw money
            withdrawalAccount = a.highestBidder;
            withdrawalAmount = a.bidders[withdrawalAccount];
        } else {
            // if auction finished without being canceled
            if (msg.sender == a.owner) {
                // the auction owner should be allowed to withdraw all money except fee
                withdrawalAccount = a.highestBidder;
                withdrawalAmount = a.bidders[a.highestBidder];

                // service fee
                if (_feePercentage > 0) {
                    uint256 serviceFeeAmount =
                        _percentageCalculate(
                            a.highestBindingBid,
                            _feePercentage
                        );
                    ContractBalance storage sF = serviceFees;
                    sF.amounts[a.paymentToken] += serviceFeeAmount;
                    withdrawalAmount -= serviceFeeAmount;
                }

                // royalty fee only if creator not owner
                if (
                    _tokenMetas[a.tokenId].royalty > 0 &&
                    _tokenMetas[a.tokenId].creator != a.owner
                ) {
                    uint256 royaltyAmount =
                        _percentageCalculate(
                            a.highestBindingBid,
                            _tokenMetas[a.tokenId].royalty
                        );

                    ContractBalance storage roy =
                        _royaltiesToPay[_tokenMetas[a.tokenId].creator];
                    roy.amounts[a.paymentToken] += royaltyAmount;
                    withdrawalAmount -= royaltyAmount;
                }

                // withdraw if first bidder not withdrawed yet
                if (
                    a.firstBidder != a.highestBidder &&
                    a.bidders[a.firstBidder] > 0
                ) {
                    uint256 toFirstBidderWithdraw = a.bidders[a.firstBidder];
                    // beedit win
                    uint256 beeditWinAmount = _calculateBeeditWin(_auctionId);
                    withdrawalAmount -= beeditWinAmount;
                    toFirstBidderWithdraw += beeditWinAmount;
                    if (toFirstBidderWithdraw > 0) {
                        require(
                            _sendMoney(
                                a.paymentToken,
                                a.firstBidder,
                                toFirstBidderWithdraw
                            ),
                            "Error in sending withdraw to 1st bidder"
                        );
                        a.bidders[a.firstBidder] = 0;
                    }
                }

                a.ownerHasWithdrawn = true;
                _tokenMetas[a.tokenId].activeTokenAuction = 0;
                // Remove from user owned list
                // uint256 tokenIndex = uint256(tokenIsAtIndex[a.tokenId]);
                // userOwnedTokens[msg.sender][tokenIndex] = 0;

                // Add to another user owned list
                // userOwnedTokens[withdrawalAccount].push(a.tokenId);
                // uint256 arrayLength = userOwnedTokens[withdrawalAccount].length;
                // tokenIsAtIndex[a.tokenId] = int256(arrayLength);

                transferFrom(msg.sender, withdrawalAccount, a.tokenId);
            } else if (msg.sender != a.highestBidder) {
                // if first bidder want to withdraw money
                withdrawalAccount = msg.sender;
                withdrawalAmount = a.bidders[withdrawalAccount];

                // beedit win
                if (withdrawalAccount == a.firstBidder) {
                    uint256 beeditWinAmount = _calculateBeeditWin(_auctionId);
                    withdrawalAmount += beeditWinAmount;
                    a.bidders[a.highestBidder] -= beeditWinAmount;
                }
            }
        }

        require(withdrawalAmount > 0, "Nothing to withdraw");
        a.bidders[withdrawalAccount] = 0;

        require(
            _sendMoney(a.paymentToken, msg.sender, withdrawalAmount),
            "Error in sending withdraw"
        );

        emit LogWithdrawal(
            _auctionId,
            a.tokenId,
            msg.sender,
            withdrawalAccount,
            withdrawalAmount
        );

        return true;
    }

    function _calculateBeeditWin(uint256 _auctionId)
        internal
        view
        onlyExistedAuction(_auctionId)
        returns (uint256)
    {
        // if beedit win already withdrawn
        if (auctions[_auctionId].bidders[auctions[_auctionId].firstBidder] == 0)
            return 0;
        if (
            (auctions[_auctionId].firstBidder !=
                auctions[_auctionId].highestBidder) &&
            (auctions[_auctionId].beeditWinParams.beeditWinFixed > 0 ||
                auctions[_auctionId].beeditWinParams.beeditWinPercentage > 0)
        ) {
            uint256 beeditWinAmount =
                auctions[_auctionId].beeditWinParams.beeditWinFixed;
            if (beeditWinAmount == 0)
                beeditWinAmount = _percentageCalculate(
                    auctions[_auctionId].highestBindingBid,
                    auctions[_auctionId].beeditWinParams.beeditWinPercentage
                );

            return beeditWinAmount;
        }
        return 0;
    }

    function cancelAuction(uint256 _auctionId)
        public
        onlyExistedAuction(_auctionId)
        onlyOwner(_auctionId)
        onlyNotCanceled(_auctionId)
        returns (bool success)
    {
        Auction storage a = auctions[_auctionId];
        a.canceled = true;
        _tokenMetas[a.tokenId].activeTokenAuction = 0;
        emit LogCanceled(_auctionId);
        return true;
    }

    function withdrawServiceFee(address paymentToken) public {
        require(
            serviceFees.amounts[paymentToken] > 0 && msg.sender == _feeAddress,
            "Fee address should be allowed and service fees should be more then 0"
        );
        _sendMoney(
            paymentToken,
            _feeAddress,
            serviceFees.amounts[paymentToken]
        );
        // payable(_feeAddress).transfer(serviceFees);
    }

    function withdrawRoyalty(address paymentToken) public {
        require(
            _royaltiesToPay[msg.sender].amounts[paymentToken] > 0,
            "_royaltiesToPay should be more then 0"
        );
        // payable(msg.sender).transfer(_royaltiesToPay[msg.sender]);
        _sendMoney(
            paymentToken,
            msg.sender,
            _royaltiesToPay[msg.sender].amounts[paymentToken]
        );
    }

    function _sendMoney(
        address paymentToken,
        address to,
        uint256 amount
    ) internal returns (bool) {
        if (paymentToken == address(0)) payable(to).transfer(amount);
        else IERC20(paymentToken).transfer(to, amount);
        return true;
    }

    function _percentageCalculate(uint256 _number, uint256 _percentage)
        internal
        pure
        returns (uint256)
    {
        return (_number * _percentage) / 10000;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);

        // do stuff before every transfer
        // Should revert transfer if item is currently on sale
        require(
            _tokenMetas[tokenId].activeTokenAuction == 0,
            "Can't transfer token while Auction is running"
        );
    }

    /* MODIFIERS */

    modifier onlyOwner(uint256 _auctionId) {
        require(
            msg.sender == auctions[_auctionId].owner,
            "Only owner can call this function."
        );
        _;
    }

    modifier onlyNotOwner(uint256 _auctionId) {
        require(
            msg.sender != auctions[_auctionId].owner,
            "Only not owner can call this function."
        );
        _;
    }

    modifier onlyAfterStart(uint256 _auctionId) {
        require(
            block.number >= auctions[_auctionId].auctionPriceData.startBlock,
            "This function can be called only after sale start."
        );
        _;
    }

    modifier onlyNotCanceled(uint256 _auctionId) {
        require(
            !auctions[_auctionId].canceled,
            "This function can be called only if sale not canceled."
        );
        _;
    }

    modifier onlyEndedOrCanceled(uint256 _auctionId) {
        require(
            auctions[_auctionId].canceled ||
                (auctions[_auctionId].started &&
                    (block.number >=
                        auctions[_auctionId].auctionPriceData.endBlock)),
            "This function can be called only if sale ended or canceled."
        );
        _;
    }

    modifier onlyExistedAuction(uint256 _auctionId) {
        require(auctions[_auctionId].owner != address(0), "Auction not found");
        _;
    }
}