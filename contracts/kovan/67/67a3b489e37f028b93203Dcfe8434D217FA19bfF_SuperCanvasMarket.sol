// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./libraries/EnumerableMap.sol";
import "./libraries/ExchangeNFTsHelper.sol";
import "./interfaces/ISuperCanvasMarket.sol";
import "./interfaces/ISuperCanvasMarketConfig.sol";

contract SuperCanvasMarket is ISuperCanvasMarket, ERC721Holder, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using EnumerableMap for EnumerableMap.UintToUintMap;
    using EnumerableMap for EnumerableMap.AddressToUintMap;
    using EnumerableSet for EnumerableSet.UintSet;

    address constant IMPLY_ADDR = 0x0000000000000000000000000000000000000000;

    ISuperCanvasMarketConfig public config;

    // nft => tokenId
    mapping(address => EnumerableSet.UintSet) private _asksSets;

    // nft => tokenId => quoteToken/ target/ price
    mapping(address => mapping(uint256 => AskInfo)) private _asksMaps;

    // nft => tokenId => bidder => quoteToken: price
    mapping(address => mapping(uint256 => mapping(address => EnumerableMap.AddressToUintMap))) private _bidsMaps;
 
    constructor(address _config) {
        config = ISuperCanvasMarketConfig(_config);
    }

    function setConfig(address _config) public onlyOwner {
        require(address(config) != _config, "forbidden");
        config = ISuperCanvasMarketConfig(_config);
        emit SetConfig(_msgSender(), address(config), _config);
    }

    function getNftQuotes(address _nftToken) public override view returns (address[] memory) {
        return config.getNftQuotes(_nftToken);
    }

    function readyToSellToken(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price
    ) external override {
        readyToSellTokenTo(_nftToken, _tokenId, _quoteToken, _price, IMPLY_ADDR);
    }

    function readyToSellTokenTo(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price,
        address _target
    ) public override nonReentrant {
        config.whenSettings(0, 0);
        config.checkEnableTrade(_nftToken, _quoteToken);
        require(_msgSender() == IERC721(_nftToken).ownerOf(_tokenId), "Only Token Owner can sell token");
        require(
            IERC721(_nftToken).isApprovedForAll(_msgSender(), address(this)) ||
            IERC721(_nftToken).getApproved(_tokenId) == _msgSender(),
            "Approve Your Token First"
        );
        require(_price != 0, "Price must be granter than zero");
        require(_target != _msgSender(), "Cannot sell to yourself");
        require(!_asksSets[_nftToken].contains(_tokenId), "Token Already For Sale");
        _asksSets[_nftToken].add(_tokenId);
        _asksMaps[_nftToken][_tokenId] = AskInfo({quoteToken: _quoteToken, target: _target, price: _price});
        emit Ask(_nftToken, _tokenId, _quoteToken, _msgSender(), _target, _price);
    }

    function updateAskPrice(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price,
        address _target
    ) public override nonReentrant {
        config.whenSettings(1, 0);
        config.checkEnableTrade(_nftToken, _quoteToken);
        require(_msgSender() == IERC721(_nftToken).ownerOf(_tokenId), "Only Token Owner can set price");
        require(
            IERC721(_nftToken).isApprovedForAll(_msgSender(), address(this)) ||
            IERC721(_nftToken).getApproved(_tokenId) == _msgSender(),
            "Approve Your Token First"
        );
        require(!_asksSets[_nftToken].contains(_tokenId), "Token not For Sale");
        require(_price != 0, "Price must be granter than zero");
        require(_target != _msgSender(), "cannot sell to your self");
        _asksMaps[_nftToken][_tokenId] = AskInfo({quoteToken: _quoteToken, target: _target, price: _price});
        emit Ask(_nftToken, _tokenId, _quoteToken, _msgSender(), _target, _price);
    }

    function _settleTrade(SettleTrade memory settleTrade) internal {
        ISuperCanvasMarketConfig.NftSettings memory nftSettings = 
            config.nftSettings(settleTrade.nftToken, settleTrade.quoteToken);
        address transferTokenFrom = settleTrade.isMiddleman ? address(this) : _msgSender();
        uint256 feeAmount = settleTrade.price.mul(nftSettings.feeValue).div(10000); // 0.01/100
        if (feeAmount != 0) {
            ExchangeNFTsHelper.transferToken(
                settleTrade.quoteToken,
                transferTokenFrom,
                nftSettings.feeAddress,
                feeAmount
            );
        }
        // NftSettings({
        //     enable: checkNftEnables(_nftToken),
        //     nftQuoteEnable: nftQuoteEnables[_nftToken][_quoteToken],
        //     feeAddress: feeAddresses[_nftToken],
        //     feeValue: feeValues[_nftToken][_quoteToken],
        //     royaltiesAddress: royaltiesAddresses[_nftToken],
        //     royaltiesValue: royaltiesValues[_nftToken][_quoteToken]
        // });
        uint256 royaltiesAmount = settleTrade.price.mul(nftSettings.royaltiesValue).div(10000); // 0.01/100
        if (royaltiesAmount != 0) {
            ExchangeNFTsHelper.transferToken(
                settleTrade.quoteToken,
                transferTokenFrom,
                nftSettings.royaltiesAddress,
                royaltiesAmount
            );
        }
        uint256 restAmount = settleTrade.price.sub(feeAmount).sub(royaltiesAmount);
        ExchangeNFTsHelper.transferToken(settleTrade.quoteToken, transferTokenFrom, settleTrade.seller, restAmount);
        IERC721(settleTrade.nftToken).safeTransferFrom(
            settleTrade.seller,
            settleTrade.buyer,
            settleTrade.tokenId
        );
        cancelSellToken(settleTrade.nftToken, settleTrade.tokenId);
        if (_bidsMaps[settleTrade.nftToken][settleTrade.tokenId][settleTrade.buyer].contains(settleTrade.quoteToken)){
            _bidsMaps[settleTrade.nftToken][settleTrade.tokenId][settleTrade.buyer].remove(settleTrade.quoteToken);
            emit CancelBidToken(settleTrade.nftToken, settleTrade.tokenId, settleTrade.quoteToken, settleTrade.seller, settleTrade.price);
        }
        if (_bidsMaps[settleTrade.nftToken][settleTrade.tokenId][settleTrade.buyer].length() != 0) {
            for (uint256 i; i < _bidsMaps[settleTrade.nftToken][settleTrade.tokenId][settleTrade.buyer].length(); i++) {
                (address key, ) = _bidsMaps[settleTrade.nftToken][settleTrade.tokenId][settleTrade.buyer].at(i);
                cancelBidToken(settleTrade.nftToken, settleTrade.tokenId, key);
            }
        }
        emit Trade(
            settleTrade.nftToken,
            settleTrade.tokenId,
            settleTrade.quoteToken,
            settleTrade.seller,
            settleTrade.buyer,
            settleTrade.price,
            feeAmount,
            royaltiesAmount
        );
    }

    function buyToken(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price
    ) public override payable nonReentrant {
        config.whenSettings(2, 0);
        config.checkEnableTrade(_nftToken, _quoteToken);
        require(config.checkNftEnables(_nftToken), "Token not enabled");
        require(_asksSets[_nftToken].contains(_tokenId), "Token not for sale");
        require(_asksMaps[_nftToken][_tokenId].quoteToken == _quoteToken, "Quote token err");
        require(_asksMaps[_nftToken][_tokenId].price == _price, "Price err");
        require(_asksMaps[_nftToken][_tokenId].target == IMPLY_ADDR || _asksMaps[_nftToken][_tokenId].target == _msgSender(), "You are not authorised to buy it");
        require(
            (msg.value == 0 && _asksMaps[_nftToken][_tokenId].quoteToken != ExchangeNFTsHelper.ETH_ADDRESS) ||
                (_asksMaps[_nftToken][_tokenId].quoteToken == ExchangeNFTsHelper.ETH_ADDRESS && msg.value == _asksMaps[_nftToken][_tokenId].price),
            "error msg value"
        );
        _settleTrade(
            SettleTrade({
                nftToken: _nftToken,
                quoteToken: _asksMaps[_nftToken][_tokenId].quoteToken,
                buyer: _msgSender(),
                seller: IERC721(_nftToken).ownerOf(_tokenId),
                tokenId: _tokenId,
                price: _asksMaps[_nftToken][_tokenId].price,
                isMiddleman: _asksMaps[_nftToken][_tokenId].quoteToken == ExchangeNFTsHelper.ETH_ADDRESS
            })
        );
    }

    function cancelSellToken(address _nftToken, uint256 _tokenId) public override {
        require(IERC721(_nftToken).ownerOf(_tokenId) == _msgSender(), "Only Seller can cancel sell token");
        require(_asksSets[_nftToken].contains(_tokenId), "Token not for sale");
        emit CancelSellToken(
            _nftToken,
            _tokenId,
            _asksMaps[_nftToken][_tokenId].quoteToken,
            _msgSender(),
            _asksMaps[_nftToken][_tokenId].target,
            _asksMaps[_nftToken][_tokenId].price
        );
        _asksSets[_nftToken].remove(_tokenId);
        delete _asksMaps[_nftToken][_tokenId];
    }


    // bid
    function bidToken(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price
    ) public override payable nonReentrant {
        config.whenSettings(4, 0);
        config.checkEnableTrade(_nftToken, _quoteToken);
        require(_price != 0, "Price must be granter than zero");
        // require(_asksMaps[_nftToken][_quoteToken].contains(_tokenId), "Token not in sell book");
        require(IERC721(_nftToken).ownerOf(_tokenId) != _msgSender(), "Owner cannot bid");
        // nft => tokenId => quoteToken => bidder: price
        require(!_bidsMaps[_nftToken][_tokenId][_msgSender()].contains(_quoteToken), "Already bids by this token");
        // require(!_userBids[_nftToken][_quoteToken][_to].contains(_tokenId), "Bidder already exists");
        require(
            (msg.value == 0 && _quoteToken != ExchangeNFTsHelper.ETH_ADDRESS) ||
                (_quoteToken == ExchangeNFTsHelper.ETH_ADDRESS && msg.value == _price),
            "error msg value"
        );
        if (_quoteToken != ExchangeNFTsHelper.ETH_ADDRESS) {
            TransferHelper.safeTransferFrom(_quoteToken, _msgSender(), address(this), _price);
        }
        _bidsMaps[_nftToken][_tokenId][_msgSender()].set(_quoteToken, _price);
        emit Bid(_nftToken, _tokenId, _quoteToken, _msgSender(), _price);
    }

    function updateBidPrice(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price
    ) public override payable nonReentrant {
        config.whenSettings(5, 0);
        config.checkEnableTrade(_nftToken, _quoteToken);
        require(_bidsMaps[_nftToken][_tokenId][_msgSender()].contains(_quoteToken), "Yet bid");
        require(_price != 0, "Price must be granter than zero");
        uint256 currentPrice = _bidsMaps[_nftToken][_tokenId][_msgSender()].get(_quoteToken);
        require(currentPrice != _price, "The bid price cannot be the same");
        require(
            (_quoteToken != ExchangeNFTsHelper.ETH_ADDRESS && msg.value == 0) ||
                _quoteToken == ExchangeNFTsHelper.ETH_ADDRESS,
            "error msg value"
        );
        if (_price > currentPrice) {
            require(
                _quoteToken != ExchangeNFTsHelper.ETH_ADDRESS || msg.value == _price.sub(currentPrice),
                "error msg value"
            );
            ExchangeNFTsHelper.transferToken(_quoteToken, _msgSender(), address(this), _price.sub(currentPrice));
        } else {
            ExchangeNFTsHelper.transferToken(_quoteToken, address(this), _msgSender(), currentPrice.sub(_price));
        }
        _bidsMaps[_nftToken][_tokenId][_msgSender()].set(_quoteToken, _price);
        emit Bid(_nftToken, _tokenId, _quoteToken, _msgSender(), _price);
    }

    function cancelBidToken(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken
    ) public override nonReentrant {
        require(_bidsMaps[_nftToken][_tokenId][_msgSender()].contains(_quoteToken), "Yet bid");
        uint256 price = _bidsMaps[_nftToken][_tokenId][_msgSender()].get(_quoteToken);
        ExchangeNFTsHelper.transferToken(_quoteToken, address(this), _msgSender(), price);
        emit CancelBidToken(_nftToken, _tokenId, _quoteToken, _msgSender(), price);
        _bidsMaps[_nftToken][_tokenId][_msgSender()].remove(_quoteToken);
    }

    function sellTokenTo(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price,
        address _bidder
    ) public override nonReentrant {
        config.whenSettings(6, 0);
        config.checkEnableTrade(_nftToken, _quoteToken);
        address owner = IERC721(_nftToken).ownerOf(_tokenId);
        require(owner == _msgSender(), "Only owner can sell token");
        require(_bidsMaps[_nftToken][_tokenId][_bidder].contains(_quoteToken), "Quote token err");
        require(_bidsMaps[_nftToken][_tokenId][_bidder].get(_quoteToken) == _price, "Price err");
        _settleTrade(
            SettleTrade({
                nftToken: _nftToken,
                quoteToken: _quoteToken,
                buyer: _bidder,
                seller: owner,
                tokenId: _tokenId,
                price: _price,
                isMiddleman: true
            })
        );
    }

    function checkAsk(address _nftToken, uint256 _tokenId) public override view returns (bool asked) {
        asked = _asksSets[_nftToken].contains(_tokenId);
    }

    function getAskInfo(address _nftToken, uint256 _tokenId) public override view returns (AskInfo memory askInfo) {
        askInfo = _asksMaps[_nftToken][_tokenId];
    }

    function getAllAskInfo(address _nftToken) public override view returns (AskInfo[] memory asksInfo) {
        asksInfo = new AskInfo[](getAskLength(_nftToken));
        for (uint256 i; i < getAskLength(_nftToken); i++) {
            // tokenId = _asksSets[_nftToken].at(i);
            asksInfo[i] = getAskInfo(_nftToken, _asksSets[_nftToken].at(i));
        }
    }

    function getAskLength(address _nftToken) public override view returns (uint256 length) {
        length = _asksSets[_nftToken].length();
    }

    function checkBidByBidder2Token(address _nftToken, uint256 _tokenId, address _bidder, address _quoteToken) public override view returns (bool bidded) {
        bidded = _bidsMaps[_nftToken][_tokenId][_bidder].contains(_quoteToken);
    }

    function getBidPriceByQuoteToken2Bidder2NfToken(address _nftToken, uint256 _tokenId, address _bidder, address _quoteToken) public override view returns (uint256 price) {
        price = _bidsMaps[_nftToken][_tokenId][_bidder].get(_quoteToken);
    }
    
    function getAllBidInfoByBidder2NftToken(address _nftToken, uint256 _tokenId, address _bidder) public override view returns (BidInfo[] memory bidsInfo) {
        bidsInfo = new BidInfo[](getBidLengthByBidder2NftToken(_nftToken, _tokenId, _bidder));
        for (uint256 i; i < getBidLengthByBidder2NftToken(_nftToken, _tokenId, _bidder); i++) {
            // tokenId = _asksSets[_nftToken].at(i);
            (address quoteToken, uint256 price) = _bidsMaps[_nftToken][_tokenId][_bidder].at(i);
            bidsInfo[i] = BidInfo({quoteToken:  quoteToken, price: price});
        }
    }

    function getBidLengthByBidder2NftToken(address _nftToken, uint256 _tokenId, address _bidder) public override view returns (uint256 length) {
        length = _bidsMaps[_nftToken][_tokenId][_bidder].length();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import './TransferHelper.sol';

library ExchangeNFTsHelper {
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

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
                require(_from == msg.sender && _to == address(this), 'error eth');
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

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

library EnumerableMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    struct Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    function _set(
        Map storage map,
        bytes32 key,
        bytes32 value
    ) private returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    function _remove(Map storage map, bytes32 key) private returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._keys.contains(key);
    }

    function _length(Map storage map) private view returns (uint256) {
        return map._keys.length();
    }

    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (_contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || _contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    function _get(
        Map storage map,
        bytes32 key,
        string memory errorMessage
    ) private view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || _contains(map, key), errorMessage);
        return value;
    }

    // UintToUintMap

    struct UintToUintMap {
        Map _inner;
    }

    function set(
        UintToUintMap storage map,
        uint256 key,
        uint256 value
    ) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(value));
    }

    function remove(UintToUintMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    function contains(UintToUintMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    function length(UintToUintMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

    function at(UintToUintMap storage map, uint256 index) internal view returns (uint256, uint256) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), uint256(value));
    }

    function tryGet(UintToUintMap storage map, uint256 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, uint256(value));
    }

    function get(UintToUintMap storage map, uint256 key) internal view returns (uint256) {
        return uint256(_get(map._inner, bytes32(key)));
    }

    function get(
        UintToUintMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(_get(map._inner, bytes32(key), errorMessage));
    }

    // AddressToUintMap

    struct AddressToUintMap {
        Map _inner;
    }

    function set(
        AddressToUintMap storage map,
        address key,
        uint256 value
    ) internal returns (bool) {
        return _set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
    }

    function remove(AddressToUintMap storage map, address key) internal returns (bool) {
        return _remove(map._inner, bytes32(uint256(uint160(key))));
    }

    function contains(AddressToUintMap storage map, address key) internal view returns (bool) {
        return _contains(map._inner, bytes32(uint256(uint160(key))));
    }

    function length(AddressToUintMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

    function at(AddressToUintMap storage map, uint256 index) internal view returns (address, uint256) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (address(uint160(uint256(key))), uint256(value));
    }

    function tryGet(AddressToUintMap storage map, address key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(uint256(uint160(key))));
        return (success, uint256(value));
    }

    function get(AddressToUintMap storage map, address key) internal view returns (uint256) {
        return uint256(_get(map._inner, bytes32(uint256(uint160(key)))));
    }

    function get(
        AddressToUintMap storage map,
        address key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(_get(map._inner, bytes32(uint256(uint160(key))), errorMessage));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface ISuperCanvasMarketConfig {
    event FeeAddressTransferred(
        address indexed nftToken,
        address oldAddr,
        address newAddr
    );
    event SetFee(address indexed nftToken, address indexed quoteToken, uint256 oldFee, uint256 newFee);
    event SetRoyaltiesAddress(
        address indexed nftToken,
        address oldRoyaltiesAddress,
        address newRoyaltiesAddress
    );
    event SetRoyalties(
        address indexed nftToken,
        address indexed quoteToken,
        uint256 oldRoyalties,
        uint256 newRoyalties
    );
    event UpdateSettings(uint256 indexed setting, uint256 oldValue, uint256 newValue);

    struct NftSettings {
        bool enable;
        bool nftQuoteEnable;
        address feeAddress;
        uint256 feeValue;
        address royaltiesAddress;
        uint256 royaltiesValue;
    }

    function settings(uint256 _key) external view returns (uint256 value);

    function nftQuoteEnables(address _nftToken, address _quoteToken) external view returns (bool enable);

    function feeAddresses(address _nftToken) external view returns (address feeAddress);

    function feeValues(address _nftToken, address _quoteToken) external view returns (uint256 feeValue);

    function royaltiesAddresses(address _nftToken) external view returns (address royaltiesAddress);

    function royaltiesValues(address _nftToken, address _quoteToken) external view returns (uint256 royaltiesValue);

    function nftSettings(address _nftToken, address _quoteToken) external view returns (NftSettings memory);

    function whenSettings(uint256 key, uint256 value) external view;

    function setSettings(uint256[] memory keys, uint256[] memory values) external;

    function checkEnableTrade(address _nftToken, address _quoteToken) external view;

    function setNftEnables(address _nftToken, bool _enable) external;

    function getNftEnables() external view returns (address[] memory nftTokens);

    function checkNftEnables(address _nftToken) external view returns (bool enable);

    function setNftQuoteEnables(
        address _nftToken,
        address[] memory _quotes,
        bool _enable
    ) external;

    function getNftQuotes(address _nftToken) external view returns (address[] memory quotes);

    function setTransferFeeAddress(
        address _nftToken,
        address _feeAddress
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

    function setRoyaltiesAddress(
        address _nftToken,
        address _royaltiesAddress
    ) external;

    function setRoyalties(
        address _nftToken,
        address _quoteToken,
        uint256 _royaltiesValue
    ) external;

    function batchSetRoyalties(
        address _nftToken,
        address[] memory _quoteTokens,
        uint256[] memory _royaltiesValues
    ) external;

    function addNft(
        address _nftToken,
        bool _enable,
        address[] memory _quotes,
        address _feeAddress,
        uint256[] memory _feeValues,
        address _royaltiesAddress,
        uint256[] memory _royaltiesValues
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface ISuperCanvasMarket {
    event SetConfig(address opterator, address oldConfig, address newConfig);
    event Ask(
        address indexed nftToken,
        uint256 indexed tokenId,
        address indexed quoteToken,
        address seller,
        address target,
        uint256 price
    );
    event Trade(
        address indexed nftToken,
        uint256 indexed tokenId,
        address indexed quoteToken,
        address seller,
        address buyer,
        uint256 price,
        uint256 feeAmount,
        uint256 royaltiesAmount
    );
    event CancelSellToken(
        address indexed nftToken,
        uint256 indexed tokenId,
        address indexed quoteToken,
        address seller,
        address target,
        uint256 price
    );
    event Bid(
        address indexed nftToken,
        uint256 indexed tokenId,
        address indexed quoteToken,
        address bidder,
        uint256 price
    );
    event CancelBidToken(
        address indexed nftToken,
        uint256 indexed tokenId,
        address indexed quoteToken,
        address bidder,
        uint256 price
    );

    struct SettleTrade {
        address nftToken;
        address quoteToken;
        address buyer;
        address seller;
        uint256 tokenId;
        uint256 price;
        bool isMiddleman;
    }

    struct AskInfo {
        address quoteToken;
        uint256 price;
        address target;
    }

    struct BidInfo {
        address quoteToken;
        uint256 price;
    }

    function getNftQuotes(address _nftToken) external view returns (address[] memory);

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
        address _to
    ) external;

    function updateAskPrice(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price,
        address _target
    ) external;

    function buyToken(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price
    ) external payable;

    function cancelSellToken(address _nftToken, uint256 _tokenId) external;

    function bidToken(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price
    ) external payable;

    function updateBidPrice(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price
    ) external payable;

    function cancelBidToken(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken
    ) external;

    function sellTokenTo(
        address _nftToken,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price,
        address _bidder
    ) external;

    function checkAsk(address _nftToken, uint256 _tokenId) external view returns (bool asked);

    function getAskInfo(address _nftToken, uint256 _tokenId) external view returns (AskInfo memory askInfo);

    function getAllAskInfo(address _nftToken) external view returns (AskInfo[] memory asksInfo);

    function getAskLength(address _nftToken) external view returns (uint256 length);

    function checkBidByBidder2Token(address _nftToken, uint256 _tokenId, address _bidder, address _quoteToken) external view returns (bool bidded);

    function getBidPriceByQuoteToken2Bidder2NfToken(address _nftToken, uint256 _tokenId, address _bidder, address _quoteToken) external view returns (uint256 price);

    function getAllBidInfoByBidder2NftToken(address _nftToken, uint256 _tokenId, address _bidder) external view returns (BidInfo[] memory bidsInfo);

    function getBidLengthByBidder2NftToken(address _nftToken, uint256 _tokenId, address _bidder) external view returns (uint256 length);
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
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
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
        return msg.data;
    }
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
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
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
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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

import "../token/ERC721/IERC721Receiver.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

