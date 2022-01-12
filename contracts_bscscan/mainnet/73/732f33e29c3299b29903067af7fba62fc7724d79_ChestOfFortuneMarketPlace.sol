// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./EnumerableMap.sol";
import "./Ownable.sol";
import "./IERC1155_EXT.sol";
import "./IMultiERC20Handler.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Math.sol";
import "./ERC1155Receiver.sol";

contract ChestOfFortuneMarketPlace is Ownable, ERC1155Receiver {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Address for address;

    IERC1155_EXT public nft;
    IMultiERC20Handler public ERC20Handler;

    uint256 private order;

    EnumerableSet.UintSet internal _asksMap;

    mapping(uint256 => Order) private _tokenSellers;

    address payable public feeAddr;
    // a fee of 1 equals 0.1%, 10 to 1%, 100 to 10%, 1000 to 100%
    uint256 public makerFee;
    uint256 public takerFee;
    uint256 public constant PERCENTS_DIVIDER = 1000;

    mapping(address => EnumerableSet.UintSet) private _userSellingOrder;
    mapping(uint256 => string) public orderType;

    IERC20 public priorityToken;

    struct TokenPrice {
        string symbol;
        uint256 price;
    }

    struct OrderShow {
        address owner;
        string _hash;
        uint256 quantity;
        uint256 tokenID;
        uint256 bnbPrice;
        TokenPrice[] tokenPrices;
    }

    struct Order {
        address owner;
        uint256 quantity;
        uint256 tokenID;
        uint256 bnbPrice;
        mapping(string => uint256) tokenPrices;
    }

    event Ask(
        address indexed seller,
        uint256 indexed order,
        uint256 bnbPrice,
        TokenPrice[] indexed tokenPrices,
        uint256 fee
    );
    event Trade(
        address indexed seller,
        address indexed buyer,
        uint256 tokenId,
        bool byToken,
        string symbol,
        uint256 quantity,
        uint256 price,
        uint256 fee
    );
    event CancelSellToken(address indexed seller, uint256 indexed order);
    event FeeAddressTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event SetMakerFeePercent(
        address indexed setBy,
        uint256 oldFeePercent,
        uint256 newFeePercent
    );

    event SetTakerFeeFeePercent(
        address indexed setBy,
        uint256 oldFeePercent,
        uint256 newFeePercent
    );

    event setPrices(
        address indexed seller,
        uint256 indexed order,
        uint256 bnbPrice,
        TokenPrice[] indexed tokenPrices
    );

    event SetPriorityToken(string priorityToken);

    constructor(
        address _nftAddress,
        address _tokenHandler,
        address _priorityToken,
        address _feeAddr,
        uint256 _makerFee,
        uint256 _takerFee
    ) {
        require(
            _nftAddress.isContract() &&
                _nftAddress != address(0) &&
                _nftAddress != address(this)
        );
        require(_tokenHandler.isContract() && _tokenHandler != address(this));
        require(_priorityToken.isContract());
        setPriorityToken(_priorityToken);
        nft = IERC1155_EXT(_nftAddress);
        ERC20Handler = IMultiERC20Handler(_tokenHandler);
        feeAddr = payable(_feeAddr);
        makerFee = _makerFee;
        takerFee = _takerFee;

        emit SetMakerFeePercent(_msgSender(), 0, _takerFee);
        emit SetTakerFeeFeePercent(_msgSender(), 0, _makerFee);
    }

    function setCurrentPrice(
        uint256 _order,
        uint256 bnbPrice,
        string[] memory _symbols,
        uint256[] memory _prices
    ) external {
        require(
            _userSellingOrder[_msgSender()].contains(_order),
            "Only Seller can update price"
        );
        require(
            _symbols.length == _prices.length,
            "diferent number of symbols and prices"
        );
        Order storage order_ = _tokenSellers[_order];
        order_.bnbPrice = bnbPrice;
        uint256 priceCount = bnbPrice;
        TokenPrice[] memory PriceDAta = new TokenPrice[](_prices.length);
        if (_symbols.length > 0) {
            for (uint256 i = 0; i < _prices.length; i++) {
                require(
                    ERC20Handler.isValidSymbol(_symbols[i]),
                    "token is not valid"
                );
                order_.tokenPrices[_symbols[i]] = _prices[i];
                priceCount = priceCount.add(_prices[i]);
                PriceDAta[i].price = _prices[i];
                PriceDAta[i].symbol = _symbols[i];
            }
        }
        require(bnbPrice > 0, "Price must be granter than zero");

        emit setPrices(order_.owner, _order, bnbPrice, PriceDAta);
    }

    function readyToSellToken(
        uint256 _tokenId,
        uint256 _quantity,
        uint256 bnbPrice,
        string[] memory _symbols,
        uint256[] memory _prices
    ) external payable {
        readyToSellTokenTo(
            _tokenId,
            _quantity,
            bnbPrice,
            _symbols,
            _prices,
            _msgSender()
        );
    }

    //this function is used to change the priority token.
    function setPriorityToken(address Addrs) public {
        priorityToken = IERC20(Addrs);
        emit SetPriorityToken(PRIORITY_TOKEN());
    }

    function PRIORITY_TOKEN() public view returns (string memory) {
        return priorityToken.symbol();
    }

    function readyToSellTokenTo(
        uint256 _tokenId,
        uint256 _quantity,
        uint256 bnbPrice,
        string[] memory _symbols,
        uint256[] memory _prices,
        address _from
    ) internal {
        require(
            nft.ownerOf(_from, _tokenId),
            "Only Token Owner can sell token"
        );
        require(
            _symbols.length == _prices.length,
            "diferent number of symbols and prices"
        );
        require(_quantity > 0, "insufficient quantity");

        TokenPrice[] memory PriceDAta = new TokenPrice[](_prices.length);
        order++;
        Order storage nft_ = _tokenSellers[order];
        if (_prices.length == 0) {
            require(bnbPrice > 0, "Price must be granter than zero");
        } else {
            for (uint256 i = 0; i < _prices.length; i++) {
                require(_prices[i] > 0, "Price must be granter than zero");
                require(
                    ERC20Handler.isValidSymbol(_symbols[i]),
                    "token is not valid"
                );
                PriceDAta[i].price = _prices[i];
                PriceDAta[i].symbol = _symbols[i];
                nft_.tokenPrices[_symbols[i]] = _prices[i];
            }
        }

        bool hasPriorityToken = nft_.tokenPrices[PRIORITY_TOKEN()] > 0;
        bool hasBnbPrice = bnbPrice > 0;
        uint256 feeAmt;
        if (hasBnbPrice && !hasPriorityToken) {
            feeAmt = bnbPrice.mul(makerFee).div(PERCENTS_DIVIDER);
            require(msg.value == feeAmt, "invalid pay amount");
            if (feeAmt > 0) {
                feeAddr.transfer(feeAmt);
            }
        } else {
            require(msg.value == 0, "invalid pay amount");
            string memory _symbol;
            if (!hasPriorityToken) {
                _symbol = _symbols[0];
                feeAmt = _prices[0].mul(makerFee).div(PERCENTS_DIVIDER);
            } else {
                _symbol = PRIORITY_TOKEN();
                feeAmt = nft_.tokenPrices[_symbol].mul(makerFee).div(
                    PERCENTS_DIVIDER
                );
            }

            IERC20 token = ERC20Handler.symbolToIERC20(_symbol);
            if (feeAmt > 0) {
                token.safeTransferFrom(_from, feeAddr, feeAmt);
            }
        }

        _asksMap.add(order);
        nft_.owner = _from;
        nft_.tokenID = _tokenId;
        nft_.quantity = _quantity;
        nft_.bnbPrice = bnbPrice;
        _userSellingOrder[_from].add(order);

        nft.safeTransferFrom(_from, address(this), _tokenId, _quantity, "0x");

        emit Ask(_from, order, bnbPrice, PriceDAta, feeAmt);
    }

    function buyToken(
        uint256 _order,
        string memory symbol,
        uint256 _quantity
    ) external payable {
        buyTokenTo(_order, _msgSender(), symbol, _quantity);
    }

    function buyTokenTo(
        uint256 _order,
        address _to,
        string memory symbol,
        uint256 _quantity
    ) internal {
        require(_to != address(0) && (_to != address(this)), "Wrong buyer");
        require(_asksMap.contains(_order), "Chest Key not in sell book");
        require(_quantity > 0, "insufficient quantity");
        Order storage nft_ = _tokenSellers[_order];
        uint256 quantityOrder = nft_.quantity;
        require(quantityOrder >= _quantity, "excessive quantity");
        uint256 price = nft_.tokenPrices[symbol];
        bool byToken = true;
        if (price == 0) {
            price = nft_.bnbPrice;
            require(price > 0, "Chest Key no valid");
            byToken = false;
        }
        price = price.mul(_quantity);
        uint256 feeAmount = price.mul(takerFee).div(PERCENTS_DIVIDER);
        if (!byToken) {
            require(msg.value == price, "invalid pay amount");
            if (feeAmount > 0) {
                feeAddr.transfer(feeAmount);
            }
            payable(nft_.owner).transfer(price.sub(feeAmount));
        } else {
            require(ERC20Handler.isValidSymbol(symbol), "token no valid");
            IERC20 token = ERC20Handler.symbolToIERC20(symbol);
            if (feeAmount > 0) {
                token.safeTransferFrom(_to, feeAddr, feeAmount);
            }
            token.safeTransferFrom(_to, nft_.owner, price.sub(feeAmount));
        }
        uint256 _tokenId = nft_.tokenID;
        uint256 deltaQuantity = quantityOrder.sub(_quantity);

        if (deltaQuantity == 0) {
            _asksMap.remove(_order);
            _userSellingOrder[nft_.owner].remove(_order);
            delete _tokenSellers[_order];
        } else {
            nft_.quantity = deltaQuantity;
        }

        nft.safeTransferFrom(address(this), _to, _tokenId, _quantity, "0x");
        emit Trade(
            nft_.owner,
            _to,
            _tokenId,
            byToken,
            symbol,
            _quantity,
            price,
            feeAmount
        );
    }

    function cancelSellToken(uint256 _order) external {
        require(
            _userSellingOrder[_msgSender()].contains(_order),
            "Only Seller can cancel sell token"
        );
        Order storage order_ = _tokenSellers[_order];
        nft.safeTransferFrom(
            address(this),
            _msgSender(),
            order_.tokenID,
            order_.quantity,
            "0x"
        );
        _asksMap.remove(_order);
        _userSellingOrder[_msgSender()].remove(_order);
        delete _tokenSellers[_order];
        emit CancelSellToken(_msgSender(), _order);
    }

    function convertOrderToOrderShow(Order storage _order)
        internal
        view
        returns (OrderShow memory orderShow)
    {
        orderShow.owner = _order.owner;
        uint256 _id = _order.tokenID;
        orderShow._hash = nft.getHashFromTokenID(_id);
        orderShow.quantity = _order.quantity;
        orderShow.tokenID = _id;
        orderShow.bnbPrice = _order.bnbPrice;
        string[] memory simbols = ERC20Handler.getAllSymbols();
        uint256 j;
        orderShow.tokenPrices = new TokenPrice[](simbols.length);
        for (uint256 i; i < simbols.length; i++) {
            if (_order.tokenPrices[simbols[i]] == 0) continue;
            orderShow.tokenPrices[j].symbol = simbols[i];
            orderShow.tokenPrices[j].price = _order.tokenPrices[simbols[i]];
            j++;
        }

        return orderShow;
    }

    function getAskLength() external view returns (uint256) {
        return _asksMap.length();
    }

    function getAsks() external view returns (OrderShow[] memory) {
        OrderShow[] memory asks = new OrderShow[](_asksMap.length());

        for (uint256 i; i < _asksMap.length(); i++) {
            uint256 orderNum = _asksMap.at(i);
            asks[i] = convertOrderToOrderShow(_tokenSellers[orderNum]);
        }
        return asks;
    }

    function transferFeeAddress(address _feeAddr) external onlyOwner {
        require(_feeAddr != feeAddr, "Not need update");
        feeAddr = payable(_feeAddr);
        emit FeeAddressTransferred(_msgSender(), feeAddr);
    }

    function setMakerFee(uint256 _makerPercent) external onlyOwner {
        require(makerFee != _makerPercent, "Not need update");
        emit SetMakerFeePercent(_msgSender(), makerFee, _makerPercent);
        makerFee = _makerPercent;
    }

    function setFeeTakerFee(uint256 _takerPercent) external onlyOwner {
        require(takerFee != _takerPercent, "Not need update");
        emit SetTakerFeeFeePercent(_msgSender(), takerFee, _takerPercent);
        takerFee = _takerPercent;
    }

    function getAsksByUser(address user)
        external
        view
        returns (OrderShow[] memory)
    {
        OrderShow[] memory asks = new OrderShow[](
            _userSellingOrder[user].length()
        );

        for (uint256 i; i < _userSellingOrder[user].length(); i++) {
            uint256 orderNum = _userSellingOrder[user].at(i);
            asks[i] = convertOrderToOrderShow(_tokenSellers[orderNum]);
        }
        return asks;
    }

    function getOrdersKeyFromUser(address user)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory keys = new uint256[](_userSellingOrder[user].length());
        for (uint256 i; i < keys.length; i++) {
            keys[i] = _userSellingOrder[user].at(i);
        }
        return keys;
    }

    function getOrder(uint256 _order) external view returns (OrderShow memory) {
        Order storage order_ = _tokenSellers[_order];
        if (order_.quantity == 0)
            return convertOrderToOrderShow(_tokenSellers[0]);
        return convertOrderToOrderShow(_tokenSellers[_order]);
    }

    function setOrderType(uint256 _orderId, string memory _ordertype)
        external
        onlyOwner
        returns (bool)
    {
        orderType[_orderId] = _ordertype;
        return true;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure override returns (bytes4) {
        operator;
        from;
        id;
        value;
        data;
        return (
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            )
        );
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external pure override returns (bytes4) {
        operator;
        from;
        ids;
        values;
        data;
        return (
            bytes4(
                keccak256(
                    "onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"
                )
            )
        );
    }
}