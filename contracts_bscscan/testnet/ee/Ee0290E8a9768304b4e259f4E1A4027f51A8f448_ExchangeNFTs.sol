// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "./libraries/EnumerableMap.sol";
import "./libraries/ExchangeNFTsHelper.sol";
import "./interfaces/IExchangeNFTs.sol";
import "./interfaces/IExchangeNFTConfiguration.sol";
import "./royalties/IRoyaltiesProvider.sol";

contract ExchangeNFTs is
    IExchangeNFTs,
    ERC721HolderUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using EnumerableMap for EnumerableMap.UintToUintMap;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    struct SettleTrade {
        address nftToken;
        address quoteToken;
        address buyer;
        address seller;
        uint256 tokenId;
        uint256 originPrice;
        uint256 price;
        bool isMaker;
    }

    struct AskEntry {
        uint256 tokenId;
        uint256 price;
    }

    struct BidEntry {
        address bidder;
        uint256 price;
    }

    struct UserBidEntry {
        uint256 tokenId;
        uint256 price;
    }

    IExchangeNFTConfiguration public config;
    // nft => tokenId => seller
    mapping(address => mapping(uint256 => address)) public tokenSellers;
    // nft => tokenId => quote
    mapping(address => mapping(uint256 => address)) public tokenSelleOn;
    // nft => quote => tokenId,price
    mapping(address => mapping(address => EnumerableMap.UintToUintMap))
        private _asksMaps;
    // nft => quote => seller => tokenIds
    mapping(address => mapping(address => mapping(address => EnumerableSetUpgradeable.UintSet)))
        private _userSellingTokens;
    // nft => quote => tokenId => bid
    mapping(address => mapping(address => mapping(uint256 => BidEntry[])))
        public tokenBids;
    // nft => quote => buyer => tokenId,bid
    mapping(address => mapping(address => mapping(address => EnumerableMap.UintToUintMap)))
        private _userBids;
    // nft => tokenId => status (0 - can sell and bid, 1 - only bid)
    mapping(address => mapping(uint256 => uint256)) tokenSelleStatus;

    function initialize(address _config) public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __ERC721Holder_init_unchained();
        config = IExchangeNFTConfiguration(_config);
    }

    function setConfig(address _config) public onlyOwner {
        require(address(config) != _config, "forbidden");
        emit SetConfig(_msgSender(), address(config), _config);
        config = IExchangeNFTConfiguration(_config);
    }

    function getNftQuotes(address _nftToken)
        public
        view
        override
        returns (address[] memory)
    {
        return config.getNftQuotes(_nftToken);
    }

    function batchReadyToSellToken(
        address[] memory _nftTokens,
        uint256[] memory _tokenIds,
        address[] memory _quoteTokens,
        uint256[] memory _prices,
        uint256[] memory _selleStatus
    ) external override {
        batchReadyToSellTokenTo(
            _nftTokens,
            _tokenIds,
            _quoteTokens,
            _prices,
            _selleStatus,
            _msgSender()
        );
    }

    function batchReadyToSellTokenTo(
        address[] memory _nftTokens,
        uint256[] memory _tokenIds,
        address[] memory _quoteTokens,
        uint256[] memory _prices,
        uint256[] memory _selleStatus,
        address _to
    ) public override {
        require(
            _nftTokens.length == _tokenIds.length &&
                _tokenIds.length == _quoteTokens.length &&
                _quoteTokens.length == _prices.length &&
                _prices.length == _selleStatus.length,
            "length err"
        );
        for (uint256 i = 0; i < _nftTokens.length; i++) {
            readyToSellTokenTo(
                _nftTokens[i],
                _tokenIds[i],
                _quoteTokens[i],
                _prices[i],
                _to,
                _selleStatus[i]
            );
        }
    }

    function readyToSellToken(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price,
        uint256 _selleStatus
    ) external override {
        readyToSellTokenTo(
            _nftToken,
            _tokenId,
            _quoteToken,
            _price,
            _msgSender(),
            _selleStatus
        );
    }

    function readyToSellTokenTo(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price,
        address _to
    ) external override {
        readyToSellTokenTo(_nftToken, _tokenId, _quoteToken, _price, _to, 0);
    }

    function readyToSellToken(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price
    ) external override {
        readyToSellTokenTo(
            _nftToken,
            _tokenId,
            _quoteToken,
            _price,
            _msgSender(),
            0
        );
    }

    function readyToSellTokenTo(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price,
        address _to,
        uint256 _selleStatus
    ) public override nonReentrant {
        config.whenSettings(0, 0);
        config.checkEnableTrade(_nftToken, _quoteToken);
        require(
            _msgSender() == IERC721Upgradeable(_nftToken).ownerOf(_tokenId),
            "Only Token Owner can sell token"
        );
        require(_price != 0, "Price must be granter than zero");
        IERC721Upgradeable(_nftToken).safeTransferFrom(
            _msgSender(),
            address(this),
            _tokenId
        );
        _asksMaps[_nftToken][_quoteToken].set(_tokenId, _price);
        tokenSellers[_nftToken][_tokenId] = _to;
        tokenSelleOn[_nftToken][_tokenId] = _quoteToken;
        _userSellingTokens[_nftToken][_quoteToken][_to].add(_tokenId);
        tokenSelleStatus[_nftToken][_tokenId] = _selleStatus;
        emit Ask(_nftToken, _msgSender(), _tokenId, _quoteToken, _price);
    }

    function batchSetCurrentPrice(
        address[] memory _nftTokens,
        uint256[] memory _tokenIds,
        address[] memory _quoteTokens,
        uint256[] memory _prices
    ) external override {
        require(
            _nftTokens.length == _tokenIds.length &&
                _tokenIds.length == _quoteTokens.length &&
                _quoteTokens.length == _prices.length,
            "length err"
        );
        for (uint256 i = 0; i < _nftTokens.length; i++) {
            setCurrentPrice(
                _nftTokens[i],
                _tokenIds[i],
                _quoteTokens[i],
                _prices[i]
            );
        }
    }

    function setCurrentPrice(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price
    ) public override nonReentrant {
        config.whenSettings(1, 0);
        config.checkEnableTrade(_nftToken, _quoteToken);
        require(
            _userSellingTokens[_nftToken][_quoteToken][_msgSender()].contains(
                _tokenId
            ),
            "Only Seller can update price"
        );
        require(_price != 0, "Price must be granter than zero");
        _asksMaps[_nftToken][_quoteToken].set(_tokenId, _price);
        emit Ask(_nftToken, _msgSender(), _tokenId, _quoteToken, _price);
    }

    function batchBuyToken(
        address[] memory _nftTokens,
        uint256[] memory _tokenIds,
        address[] memory _quoteTokens,
        uint256[] memory _prices
    ) external override {
        batchBuyTokenTo(
            _nftTokens,
            _tokenIds,
            _quoteTokens,
            _prices,
            _msgSender()
        );
    }

    function batchBuyTokenTo(
        address[] memory _nftTokens,
        uint256[] memory _tokenIds,
        address[] memory _quoteTokens,
        uint256[] memory _prices,
        address _to
    ) public override {
        require(
            _nftTokens.length == _tokenIds.length &&
                _tokenIds.length == _quoteTokens.length &&
                _quoteTokens.length == _prices.length,
            "length err"
        );
        for (uint256 i = 0; i < _nftTokens.length; i++) {
            buyTokenTo(
                _nftTokens[i],
                _tokenIds[i],
                _quoteTokens[i],
                _prices[i],
                _to
            );
        }
    }

    function buyToken(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price
    ) external payable override {
        buyTokenTo(_nftToken, _tokenId, _quoteToken, _price, _msgSender());
    }

    function _settleTrade(SettleTrade memory settleTrade) internal {
        IExchangeNFTConfiguration.NftSettings memory nftSettings = config
            .nftSettings(settleTrade.nftToken, settleTrade.quoteToken);
        uint256 feeAmount = settleTrade.price.mul(nftSettings.feeValue).div(
            10000
        );
        address transferTokenFrom = settleTrade.isMaker
            ? address(this)
            : _msgSender();
        if (feeAmount != 0) {
            if (nftSettings.feeBurnAble) {
                ExchangeNFTsHelper.burnToken(
                    settleTrade.quoteToken,
                    transferTokenFrom,
                    feeAmount
                );
            } else {
                ExchangeNFTsHelper.transferToken(
                    settleTrade.quoteToken,
                    transferTokenFrom,
                    nftSettings.feeAddress,
                    feeAmount
                );
            }
        }
        uint256 restValue = settleTrade.price.sub(feeAmount);
        if (nftSettings.royaltiesProvider != address(0)) {
            LibPart.Part[] memory fees = IRoyaltiesProvider(
                nftSettings.royaltiesProvider
            ).getRoyalties(settleTrade.nftToken, settleTrade.tokenId);
            for (uint256 i = 0; i < fees.length; i++) {
                uint256 feeValue = settleTrade.price.mul(fees[i].value).div(
                    10000
                );
                if (restValue > feeValue) {
                    restValue = restValue.sub(feeValue);
                } else {
                    feeValue = restValue;
                    restValue = 0;
                }
                if (feeValue != 0) {
                    feeAmount = feeAmount.add(feeValue);
                    if (nftSettings.royaltiesBurnable) {
                        ExchangeNFTsHelper.burnToken(
                            settleTrade.quoteToken,
                            transferTokenFrom,
                            feeValue
                        );
                    } else {
                        ExchangeNFTsHelper.transferToken(
                            settleTrade.quoteToken,
                            transferTokenFrom,
                            fees[i].account,
                            feeValue
                        );
                    }
                }
            }
        }

        ExchangeNFTsHelper.transferToken(
            settleTrade.quoteToken,
            transferTokenFrom,
            settleTrade.seller,
            restValue
        );

        _asksMaps[settleTrade.nftToken][settleTrade.quoteToken].remove(
            settleTrade.tokenId
        );
        _userSellingTokens[settleTrade.nftToken][settleTrade.quoteToken][
            settleTrade.seller
        ].remove(settleTrade.tokenId);
        IERC721Upgradeable(settleTrade.nftToken).safeTransferFrom(
            address(this),
            settleTrade.buyer,
            settleTrade.tokenId
        );
        emit Trade(
            settleTrade.nftToken,
            settleTrade.quoteToken,
            settleTrade.seller,
            settleTrade.buyer,
            settleTrade.tokenId,
            settleTrade.originPrice,
            settleTrade.price,
            feeAmount
        );
        delete tokenSellers[settleTrade.nftToken][settleTrade.tokenId];
        delete tokenSelleOn[settleTrade.nftToken][settleTrade.tokenId];
        delete tokenSelleStatus[settleTrade.nftToken][settleTrade.tokenId];
    }

    function buyTokenTo(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price,
        address _to
    ) public payable override nonReentrant {
        config.whenSettings(2, 0);
        config.checkEnableTrade(_nftToken, _quoteToken);
        require(
            tokenSelleOn[_nftToken][_tokenId] == _quoteToken,
            "quote token err"
        );
        require(
            _asksMaps[_nftToken][_quoteToken].contains(_tokenId),
            "Token not in sell book"
        );
        require(
            !_userBids[_nftToken][_quoteToken][_msgSender()].contains(_tokenId),
            "You must cancel your bid first"
        );
        uint256 price = _asksMaps[_nftToken][_quoteToken].get(_tokenId);
        require(_price == price, "Wrong price");
        require(
            (msg.value == 0 && _quoteToken != ExchangeNFTsHelper.ETH_ADDRESS) ||
                (_quoteToken == ExchangeNFTsHelper.ETH_ADDRESS &&
                    msg.value == _price),
            "error msg value"
        );
        require(tokenSelleStatus[_nftToken][_tokenId] == 0, "only bid");
        _settleTrade(
            SettleTrade({
                nftToken: _nftToken,
                quoteToken: _quoteToken,
                buyer: _to,
                seller: tokenSellers[_nftToken][_tokenId],
                tokenId: _tokenId,
                originPrice: price,
                price: _price,
                isMaker: _quoteToken == ExchangeNFTsHelper.ETH_ADDRESS
            })
        );
    }

    function batchCancelSellToken(
        address[] memory _nftTokens,
        uint256[] memory _tokenIds
    ) external override {
        require(_nftTokens.length == _tokenIds.length);
        for (uint256 i = 0; i < _nftTokens.length; i++) {
            cancelSellToken(_nftTokens[i], _tokenIds[i]);
        }
    }

    function cancelSellToken(address _nftToken, uint256 _tokenId)
        public
        override
        nonReentrant
    {
        require(
            tokenSellers[_nftToken][_tokenId] == _msgSender(),
            "Only Seller can cancel sell token"
        );
        IERC721Upgradeable(_nftToken).safeTransferFrom(
            address(this),
            _msgSender(),
            _tokenId
        );
        _userSellingTokens[_nftToken][tokenSelleOn[_nftToken][_tokenId]][
            _msgSender()
        ].remove(_tokenId);
        emit CancelSellToken(
            _nftToken,
            tokenSelleOn[_nftToken][_tokenId],
            _msgSender(),
            _tokenId,
            _asksMaps[_nftToken][tokenSelleOn[_nftToken][_tokenId]].get(
                _tokenId
            )
        );
        _asksMaps[_nftToken][tokenSelleOn[_nftToken][_tokenId]].remove(
            _tokenId
        );
        delete tokenSellers[_nftToken][_tokenId];
        delete tokenSelleOn[_nftToken][_tokenId];
        delete tokenSelleStatus[_nftToken][_tokenId];
    }

    function getAskLength(address _nftToken, address _quoteToken)
        public
        view
        returns (uint256)
    {
        return _asksMaps[_nftToken][_quoteToken].length();
    }

    function getAsks(address _nftToken, address _quoteToken)
        public
        view
        returns (AskEntry[] memory)
    {
        AskEntry[] memory asks = new AskEntry[](
            _asksMaps[_nftToken][_quoteToken].length()
        );
        for (
            uint256 i = 0;
            i < _asksMaps[_nftToken][_quoteToken].length();
            ++i
        ) {
            (uint256 tokenId, uint256 price) = _asksMaps[_nftToken][_quoteToken]
                .at(i);
            asks[i] = AskEntry({tokenId: tokenId, price: price});
        }
        return asks;
    }

    function getAsksByNFT(address _nftToken)
        external
        view
        returns (
            address[] memory quotes,
            uint256[] memory lengths,
            AskEntry[] memory asks
        )
    {
        quotes = getNftQuotes(_nftToken);
        lengths = new uint256[](quotes.length);
        uint256 total = 0;
        for (uint256 i = 0; i < quotes.length; ++i) {
            lengths[i] = getAskLength(_nftToken, quotes[i]);
            total = total + lengths[i];
        }
        asks = new AskEntry[](total);
        uint256 index = 0;
        for (uint256 i = 0; i < quotes.length; ++i) {
            AskEntry[] memory tempAsks = getAsks(_nftToken, quotes[i]);
            for (uint256 j = 0; j < tempAsks.length; ++j) {
                asks[index] = tempAsks[j];
                ++index;
            }
        }
    }

    function getAsksByPage(
        address _nftToken,
        address _quoteToken,
        uint256 _page,
        uint256 _size
    ) external view returns (AskEntry[] memory) {
        if (_asksMaps[_nftToken][_quoteToken].length() > 0) {
            uint256 from = _page == 0 ? 0 : (_page - 1) * _size;
            uint256 to = MathUpgradeable.min(
                (_page == 0 ? 1 : _page) * _size,
                _asksMaps[_nftToken][_quoteToken].length()
            );
            AskEntry[] memory asks = new AskEntry[]((to - from));
            for (uint256 i = 0; from < to; ++i) {
                (uint256 tokenId, uint256 price) = _asksMaps[_nftToken][
                    _quoteToken
                ].at(from);
                asks[i] = AskEntry({tokenId: tokenId, price: price});
                ++from;
            }
            return asks;
        } else {
            return new AskEntry[](0);
        }
    }

    function getUserAsks(
        address _nftToken,
        address _quoteToken,
        address _user
    ) public view returns (AskEntry[] memory) {
        AskEntry[] memory asks = new AskEntry[](
            _userSellingTokens[_nftToken][_quoteToken][_user].length()
        );
        for (
            uint256 i = 0;
            i < _userSellingTokens[_nftToken][_quoteToken][_user].length();
            ++i
        ) {
            uint256 tokenId = _userSellingTokens[_nftToken][_quoteToken][_user]
                .at(i);
            uint256 price = _asksMaps[_nftToken][_quoteToken].get(tokenId);
            asks[i] = AskEntry({tokenId: tokenId, price: price});
        }
        return asks;
    }

    function getUserAsksByNFT(address _nftToken, address _user)
        external
        view
        returns (
            address[] memory quotes,
            uint256[] memory lengths,
            AskEntry[] memory asks
        )
    {
        quotes = getNftQuotes(_nftToken);
        lengths = new uint256[](quotes.length);
        uint256 total = 0;
        for (uint256 i = 0; i < quotes.length; ++i) {
            lengths[i] = _userSellingTokens[_nftToken][quotes[i]][_user]
                .length();
            total = total + lengths[i];
        }
        asks = new AskEntry[](total);
        uint256 index = 0;
        for (uint256 i = 0; i < quotes.length; ++i) {
            AskEntry[] memory tempAsks = getUserAsks(
                _nftToken,
                quotes[i],
                _user
            );
            for (uint256 j = 0; j < tempAsks.length; ++j) {
                asks[index] = tempAsks[j];
                ++index;
            }
        }
    }

    // bid
    function batchBidToken(
        address[] memory _nftTokens,
        uint256[] memory _tokenIds,
        address[] memory _quoteTokens,
        uint256[] memory _prices
    ) external override {
        batchBidTokenTo(
            _nftTokens,
            _tokenIds,
            _quoteTokens,
            _prices,
            _msgSender()
        );
    }

    function batchBidTokenTo(
        address[] memory _nftTokens,
        uint256[] memory _tokenIds,
        address[] memory _quoteTokens,
        uint256[] memory _prices,
        address _to
    ) public override {
        require(
            _nftTokens.length == _tokenIds.length &&
                _tokenIds.length == _quoteTokens.length &&
                _quoteTokens.length == _prices.length,
            "length err"
        );
        for (uint256 i = 0; i < _nftTokens.length; i++) {
            bidTokenTo(
                _nftTokens[i],
                _tokenIds[i],
                _quoteTokens[i],
                _prices[i],
                _to
            );
        }
    }

    function bidToken(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price
    ) external payable override {
        bidTokenTo(_nftToken, _tokenId, _quoteToken, _price, _msgSender());
    }

    function bidTokenTo(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price,
        address _to
    ) public payable override nonReentrant {
        config.whenSettings(4, 0);
        config.checkEnableTrade(_nftToken, _quoteToken);
        require(_price != 0, "Price must be granter than zero");
        require(
            _asksMaps[_nftToken][_quoteToken].contains(_tokenId),
            "Token not in sell book"
        );
        require(tokenSellers[_nftToken][_tokenId] != _to, "Owner cannot bid");
        require(
            !_userBids[_nftToken][_quoteToken][_to].contains(_tokenId),
            "Bidder already exists"
        );
        require(
            (msg.value == 0 && _quoteToken != ExchangeNFTsHelper.ETH_ADDRESS) ||
                (_quoteToken == ExchangeNFTsHelper.ETH_ADDRESS &&
                    msg.value == _price),
            "error msg value"
        );
        if (_quoteToken != ExchangeNFTsHelper.ETH_ADDRESS) {
            TransferHelper.safeTransferFrom(
                _quoteToken,
                _msgSender(),
                address(this),
                _price
            );
        }
        _userBids[_nftToken][_quoteToken][_to].set(_tokenId, _price);
        tokenBids[_nftToken][_quoteToken][_tokenId].push(
            BidEntry({bidder: _to, price: _price})
        );
        emit Bid(_nftToken, _to, _tokenId, _quoteToken, _price);
    }

    function batchUpdateBidPrice(
        address[] memory _nftTokens,
        uint256[] memory _tokenIds,
        address[] memory _quoteTokens,
        uint256[] memory _prices
    ) external override {
        require(
            _nftTokens.length == _tokenIds.length &&
                _tokenIds.length == _quoteTokens.length &&
                _quoteTokens.length == _prices.length,
            "length err"
        );
        for (uint256 i = 0; i < _nftTokens.length; i++) {
            updateBidPrice(
                _nftTokens[i],
                _tokenIds[i],
                _quoteTokens[i],
                _prices[i]
            );
        }
    }

    function updateBidPrice(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price
    ) public payable override nonReentrant {
        config.whenSettings(5, 0);
        config.checkEnableTrade(_nftToken, _quoteToken);
        require(
            _userBids[_nftToken][_quoteToken][_msgSender()].contains(_tokenId),
            "Only Bidder can update the bid price"
        );
        require(_price != 0, "Price must be granter than zero");
        address _to = _msgSender(); // find  bid and the index
        (BidEntry memory bidEntry, uint256 _index) = getBidByTokenIdAndAddress(
            _nftToken,
            _quoteToken,
            _tokenId,
            _to
        );
        require(bidEntry.price != 0, "Bidder does not exist");
        require(bidEntry.price != _price, "The bid price cannot be the same");
        require(
            (_quoteToken != ExchangeNFTsHelper.ETH_ADDRESS && msg.value == 0) ||
                _quoteToken == ExchangeNFTsHelper.ETH_ADDRESS,
            "error msg value"
        );
        if (_price > bidEntry.price) {
            require(
                _quoteToken != ExchangeNFTsHelper.ETH_ADDRESS ||
                    msg.value == _price.sub(bidEntry.price),
                "error msg value."
            );
            ExchangeNFTsHelper.transferToken(
                _quoteToken,
                _msgSender(),
                address(this),
                _price.sub(bidEntry.price)
            );
        } else {
            ExchangeNFTsHelper.transferToken(
                _quoteToken,
                address(this),
                _msgSender(),
                bidEntry.price.sub(_price)
            );
        }
        _userBids[_nftToken][_quoteToken][_to].set(_tokenId, _price);
        tokenBids[_nftToken][_quoteToken][_tokenId][_index] = BidEntry({
            bidder: _to,
            price: _price
        });
        emit Bid(_nftToken, _to, _tokenId, _quoteToken, _price);
    }

    function getBidByTokenIdAndAddress(
        address _nftToken,
        address _quoteToken,
        uint256 _tokenId,
        address _address
    ) internal view virtual returns (BidEntry memory, uint256) {
        // find the index of the bid
        BidEntry[] memory bidEntries = tokenBids[_nftToken][_quoteToken][
            _tokenId
        ];
        uint256 len = bidEntries.length;
        uint256 _index;
        BidEntry memory bidEntry;
        for (uint256 i = 0; i < len; i++) {
            if (_address == bidEntries[i].bidder) {
                _index = i;
                bidEntry = BidEntry({
                    bidder: bidEntries[i].bidder,
                    price: bidEntries[i].price
                });
                break;
            }
        }
        return (bidEntry, _index);
    }

    function delBidByTokenIdAndIndex(
        address _nftToken,
        address _quoteToken,
        uint256 _tokenId,
        uint256 _index
    ) internal virtual {
        _userBids[_nftToken][_quoteToken][
            tokenBids[_nftToken][_quoteToken][_tokenId][_index].bidder
        ].remove(_tokenId);
        // delete the bid
        uint256 len = tokenBids[_nftToken][_quoteToken][_tokenId].length;
        for (uint256 i = _index; i < len - 1; i++) {
            tokenBids[_nftToken][_quoteToken][_tokenId][i] = tokenBids[
                _nftToken
            ][_quoteToken][_tokenId][i + 1];
        }
        tokenBids[_nftToken][_quoteToken][_tokenId].pop();
    }

    function sellTokenTo(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price,
        address _to
    ) public override nonReentrant {
        config.whenSettings(6, 0);
        config.checkEnableTrade(_nftToken, _quoteToken);
        require(
            _asksMaps[_nftToken][_quoteToken].contains(_tokenId),
            "Token not in sell book"
        );
        require(
            tokenSellers[_nftToken][_tokenId] == _msgSender(),
            "Only owner can sell token"
        );
        // find  bid and the index
        (BidEntry memory bidEntry, uint256 _index) = getBidByTokenIdAndAddress(
            _nftToken,
            _quoteToken,
            _tokenId,
            _to
        );
        require(bidEntry.price != 0, "Bidder does not exist");
        require(_price == bidEntry.price, "Wrong price");
        uint256 originPrice = _asksMaps[_nftToken][_quoteToken].get(_tokenId);
        _settleTrade(
            SettleTrade({
                nftToken: _nftToken,
                quoteToken: _quoteToken,
                buyer: _to,
                seller: tokenSellers[_nftToken][_tokenId],
                tokenId: _tokenId,
                originPrice: originPrice,
                price: bidEntry.price,
                isMaker: true
            })
        );

        delBidByTokenIdAndIndex(_nftToken, _quoteToken, _tokenId, _index);
    }

    function batchCancelBidToken(
        address[] memory _nftTokens,
        address[] memory _quoteTokens,
        uint256[] memory _tokenIds
    ) external override {
        require(
            _nftTokens.length == _quoteTokens.length &&
                _quoteTokens.length == _tokenIds.length,
            "length err"
        );
        for (uint256 i = 0; i < _nftTokens.length; i++) {
            cancelBidToken(_nftTokens[i], _quoteTokens[i], _tokenIds[i]);
        }
    }

    function cancelBidToken(
        address _nftToken,
        address _quoteToken,
        uint256 _tokenId
    ) public override nonReentrant {
        require(
            _userBids[_nftToken][_quoteToken][_msgSender()].contains(_tokenId),
            "Only Bidder can cancel the bid"
        );
        // find  bid and the index
        (BidEntry memory bidEntry, uint256 _index) = getBidByTokenIdAndAddress(
            _nftToken,
            _quoteToken,
            _tokenId,
            _msgSender()
        );
        require(bidEntry.price != 0, "Bidder does not exist");
        ExchangeNFTsHelper.transferToken(
            _quoteToken,
            address(this),
            _msgSender(),
            bidEntry.price
        );
        emit CancelBidToken(
            _nftToken,
            _quoteToken,
            _msgSender(),
            _tokenId,
            bidEntry.price
        );
        delBidByTokenIdAndIndex(_nftToken, _quoteToken, _tokenId, _index);
    }

    function getBidsLength(
        address _nftToken,
        address _quoteToken,
        uint256 _tokenId
    ) external view returns (uint256) {
        return tokenBids[_nftToken][_quoteToken][_tokenId].length;
    }

    function getBids(
        address _nftToken,
        address _quoteToken,
        uint256 _tokenId
    ) external view returns (BidEntry[] memory) {
        return tokenBids[_nftToken][_quoteToken][_tokenId];
    }

    function getUserBids(
        address _nftToken,
        address _quoteToken,
        address _user
    ) public view returns (UserBidEntry[] memory) {
        uint256 length = _userBids[_nftToken][_quoteToken][_user].length();
        UserBidEntry[] memory bids = new UserBidEntry[](length);
        for (uint256 i = 0; i < length; i++) {
            (uint256 tokenId, uint256 price) = _userBids[_nftToken][
                _quoteToken
            ][_user].at(i);
            bids[i] = UserBidEntry({tokenId: tokenId, price: price});
        }
        return bids;
    }

    function getUserBidsByNFT(address _nftToken, address _user)
        external
        view
        returns (
            address[] memory quotes,
            uint256[] memory lengths,
            UserBidEntry[] memory bids
        )
    {
        quotes = getNftQuotes(_nftToken);
        lengths = new uint256[](quotes.length);
        uint256 total = 0;
        for (uint256 i = 0; i < quotes.length; ++i) {
            lengths[i] = _userBids[_nftToken][quotes[i]][_user].length();
            total = total + lengths[i];
        }
        bids = new UserBidEntry[](total);
        uint256 index = 0;
        for (uint256 i = 0; i < quotes.length; ++i) {
            UserBidEntry[] memory tempBids = getUserBids(
                _nftToken,
                quotes[i],
                _user
            );
            for (uint256 j = 0; j < tempBids.length; ++j) {
                bids[index] = tempBids[j];
                ++index;
            }
        }
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
library SafeMathUpgradeable {
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
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal initializer {
        __ERC721Holder_init_unchained();
    }

    function __ERC721Holder_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
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
library EnumerableSetUpgradeable {
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

/**
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/EnumerableMap.sol
 */
library EnumerableMap {
    struct MapEntry {
        uint256 _key;
        uint256 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;
        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping(uint256 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(
        Map storage map,
        uint256 key,
        uint256 value
    ) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) {
            // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({_key: key, _value: value}));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, uint256 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) {
            // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, uint256 key)
        private
        view
        returns (bool)
    {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Map storage map, uint256 index)
        private
        view
        returns (uint256, uint256)
    {
        require(
            map._entries.length > index,
            "EnumerableMap: index out of bounds"
        );

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, uint256 key) private view returns (uint256) {
        return _get(map, key, "EnumerableMap: nonexistent key");
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     */
    function _get(
        Map storage map,
        uint256 key,
        string memory errorMessage
    ) private view returns (uint256) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToUintMap

    struct UintToUintMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToUintMap storage map,
        uint256 key,
        uint256 value
    ) internal returns (bool) {
        return _set(map._inner, key, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToUintMap storage map, uint256 key)
        internal
        returns (bool)
    {
        return _remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToUintMap storage map, uint256 key)
        internal
        view
        returns (bool)
    {
        return _contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToUintMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToUintMap storage map, uint256 index)
        internal
        view
        returns (uint256, uint256)
    {
        return _at(map._inner, index);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToUintMap storage map, uint256 key)
        internal
        view
        returns (uint256)
    {
        return _get(map._inner, key);
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     */
    function get(
        UintToUintMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return _get(map._inner, key, errorMessage);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "./TransferHelper.sol";

library ExchangeNFTsHelper {
    address public constant ETH_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function burnToken(
        address _token,
        address _from,
        uint256 _amount
    ) internal {
        if (_from == address(this)) {
            ERC20BurnableUpgradeable(_token).burn(_amount);
        } else {
            ERC20BurnableUpgradeable(_token).burnFrom(_from, _amount);
        }
    }

    function transferToken(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        if (_amount == 0) {
            return;
        }
        if (_token == ExchangeNFTsHelper.ETH_ADDRESS) {
            if (_from == address(this)) {
                TransferHelper.safeTransferETH(_to, _amount);
            } else {
                // transfer by msg.value,  && msg.value == _amount
                require(
                    _from == msg.sender && _to == address(this),
                    "error eth"
                );
            }
        } else {
            if (_from == address(this)) {
                TransferHelper.safeTransfer(_token, _to, _amount);
            } else {
                TransferHelper.safeTransferFrom(_token, _from, _to, _amount);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IExchangeNFTs {
    event SetConfig(address opterator, address oldConfig, address newConfig);
    event Ask(
        address indexed nftToken,
        address seller,
        uint256 indexed tokenId,
        address indexed quoteToken,
        uint256 price
    );
    event Trade(
        address indexed nftToken,
        address indexed quoteToken,
        address seller,
        address buyer,
        uint256 indexed tokenId,
        uint256 originPrice,
        uint256 price,
        uint256 fee
    );
    event CancelSellToken(
        address indexed nftToken,
        address indexed quoteToken,
        address seller,
        uint256 indexed tokenId,
        uint256 price
    );
    event Bid(
        address indexed nftToken,
        address bidder,
        uint256 indexed tokenId,
        address indexed quoteToken,
        uint256 price
    );
    event CancelBidToken(
        address indexed nftToken,
        address indexed quoteToken,
        address bidder,
        uint256 indexed tokenId,
        uint256 price
    );

    function getNftQuotes(address _nftToken)
        external
        view
        returns (address[] memory);

    function batchReadyToSellToken(
        address[] memory _nftTokens,
        uint256[] memory _tokenIds,
        address[] memory _quoteTokens,
        uint256[] memory _prices,
        uint256[] memory _selleStatus
    ) external;

    function batchReadyToSellTokenTo(
        address[] memory _nftTokens,
        uint256[] memory _tokenIds,
        address[] memory _quoteTokens,
        uint256[] memory _prices,
        uint256[] memory _selleStatus,
        address _to
    ) external;

    function readyToSellToken(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price,
        uint256 _selleStatus
    ) external;

    function readyToSellToken(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price
    ) external;

    function readyToSellTokenTo(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price,
        address _to,
        uint256 _selleStatus
    ) external;

    function readyToSellTokenTo(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price,
        address _to
    ) external;

    function batchSetCurrentPrice(
        address[] memory _nftTokens,
        uint256[] memory _tokenIds,
        address[] memory _quoteTokens,
        uint256[] memory _prices
    ) external;

    function setCurrentPrice(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price
    ) external;

    function batchBuyToken(
        address[] memory _nftTokens,
        uint256[] memory _tokenIds,
        address[] memory _quoteTokens,
        uint256[] memory _prices
    ) external;

    function batchBuyTokenTo(
        address[] memory _nftTokens,
        uint256[] memory _tokenIds,
        address[] memory _quoteTokens,
        uint256[] memory _prices,
        address _to
    ) external;

    function buyToken(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price
    ) external payable;

    function buyTokenTo(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price,
        address _to
    ) external payable;

    function batchCancelSellToken(
        address[] memory _nftTokens,
        uint256[] memory _tokenIds
    ) external;

    function cancelSellToken(address _nftToken, uint256 _tokenId) external;

    function batchBidToken(
        address[] memory _nftTokens,
        uint256[] memory _tokenIds,
        address[] memory _quoteTokens,
        uint256[] memory _prices
    ) external;

    function batchBidTokenTo(
        address[] memory _nftTokens,
        uint256[] memory _tokenIds,
        address[] memory _quoteTokens,
        uint256[] memory _prices,
        address _to
    ) external;

    function bidToken(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price
    ) external payable;

    function bidTokenTo(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price,
        address _to
    ) external payable;

    function batchUpdateBidPrice(
        address[] memory _nftTokens,
        uint256[] memory _tokenIds,
        address[] memory _quoteTokens,
        uint256[] memory _prices
    ) external;

    function updateBidPrice(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price
    ) external payable;

    function sellTokenTo(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price,
        address _to
    ) external;

    function batchCancelBidToken(
        address[] memory _nftTokens,
        address[] memory _quoteTokens,
        uint256[] memory _tokenIds
    ) external;

    function cancelBidToken(
        address _nftToken,
        address _quoteToken,
        uint256 _tokenId
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IExchangeNFTConfiguration {
    event FeeAddressTransferred(
        address indexed nftToken,
        address indexed quoteToken,
        address previousOwner,
        address newOwner
    );
    event SetFee(
        address indexed nftToken,
        address indexed quoteToken,
        address seller,
        uint256 oldFee,
        uint256 newFee
    );
    event SetFeeBurnAble(
        address indexed nftToken,
        address indexed quoteToken,
        address seller,
        bool oldFeeBurnable,
        bool newFeeBurnable
    );
    event SetRoyaltiesProvider(
        address indexed nftToken,
        address indexed quoteToken,
        address seller,
        address oldRoyaltiesProvider,
        address newRoyaltiesProvider
    );
    event SetRoyaltiesBurnable(
        address indexed nftToken,
        address indexed quoteToken,
        address seller,
        bool oldRoyaltiesBurnable,
        bool newFeeRoyaltiesBurnable
    );
    event UpdateSettings(
        uint256 indexed setting,
        uint256 proviousValue,
        uint256 value
    );

    struct NftSettings {
        bool enable;
        bool nftQuoteEnable;
        address feeAddress;
        bool feeBurnAble;
        uint256 feeValue;
        address royaltiesProvider;
        bool royaltiesBurnable;
    }

    function settings(uint256 _key) external view returns (uint256 value);

    function nftEnables(address _nftToken) external view returns (bool enable);

    function nftQuoteEnables(address _nftToken, address _quoteToken)
        external
        view
        returns (bool enable);

    function feeBurnables(address _nftToken, address _quoteToken)
        external
        view
        returns (bool enable);

    function feeAddresses(address _nftToken, address _quoteToken)
        external
        view
        returns (address feeAddress);

    function feeValues(address _nftToken, address _quoteToken)
        external
        view
        returns (uint256 feeValue);

    function royaltiesProviders(address _nftToken, address _quoteToken)
        external
        view
        returns (address royaltiesProvider);

    function royaltiesBurnables(address _nftToken, address _quoteToken)
        external
        view
        returns (bool enable);

    function checkEnableTrade(address _nftToken, address _quoteToken)
        external
        view;

    function whenSettings(uint256 key, uint256 value) external view;

    function setSettings(uint256[] memory keys, uint256[] memory values)
        external;

    function nftSettings(address _nftToken, address _quoteToken)
        external
        view
        returns (NftSettings memory);

    function setNftEnables(address _nftToken, bool _enable) external;

    function setNftQuoteEnables(
        address _nftToken,
        address[] memory _quotes,
        bool _enable
    ) external;

    function getNftQuotes(address _nftToken)
        external
        view
        returns (address[] memory quotes);

    function transferFeeAddress(
        address _nftToken,
        address _quoteToken,
        address _feeAddress
    ) external;

    function batchTransferFeeAddress(
        address _nftToken,
        address[] memory _quoteTokens,
        address[] memory _feeAddresses
    ) external;

    function setFee(
        address _nftToken,
        address _quoteToken,
        uint256 _feeValue
    ) external;

    function batchSetFee(
        address _nftToken,
        address[] memory _quoteTokens,
        uint256[] memory _feeValues
    ) external;

    function setFeeBurnAble(
        address _nftToken,
        address _quoteToken,
        bool _feeBurnable
    ) external;

    function batchSetFeeBurnAble(
        address _nftToken,
        address[] memory _quoteTokens,
        bool[] memory _feeBurnables
    ) external;

    function setRoyaltiesProvider(
        address _nftToken,
        address _quoteToken,
        address _royaltiesProvider
    ) external;

    function batchSetRoyaltiesProviders(
        address _nftToken,
        address[] memory _quoteTokens,
        address[] memory _royaltiesProviders
    ) external;

    function setRoyaltiesBurnable(
        address _nftToken,
        address _quoteToken,
        bool _royaltiesBurnable
    ) external;

    function batchSetRoyaltiesBurnable(
        address _nftToken,
        address[] memory _quoteTokens,
        bool[] memory _royaltiesBurnables
    ) external;

    function addNft(
        address _nftToken,
        bool _enable,
        address[] memory _quotes,
        address[] memory _feeAddresses,
        uint256[] memory _feeValues,
        bool[] memory _feeBurnAbles,
        address[] memory _royaltiesProviders,
        bool[] memory _royaltiesBurnables
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./LibPart.sol";

interface IRoyaltiesProvider {
    function getRoyalties(address token, uint256 tokenId)
        external
        returns (LibPart.Part[] memory);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../utils/ContextUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20BurnableUpgradeable is Initializable, ContextUpgradeable, ERC20Upgradeable {
    function __ERC20Burnable_init() internal initializer {
        __Context_init_unchained();
        __ERC20Burnable_init_unchained();
    }

    function __ERC20Burnable_init_unchained() internal initializer {
    }
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library LibPart {
    bytes32 public constant TYPE_HASH =
        keccak256("Part(address account,uint96 value)");

    struct Part {
        address payable account;
        uint96 value;
    }

    function hash(Part memory part) internal pure returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, part.account, part.value));
    }
}