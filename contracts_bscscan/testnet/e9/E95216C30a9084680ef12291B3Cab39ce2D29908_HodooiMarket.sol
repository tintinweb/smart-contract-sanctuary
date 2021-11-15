// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IERC1155.sol";
import "./interfaces/IBSCswapRouter.sol";
import "./interfaces/IReferral.sol";
import "./interfaces/IExchange.sol";
import "./interfaces/IMarket.sol";

import "./token/ERC1155Holder.sol";
import "./dependencies/VerifySign.sol";

contract HodooiMarket is Ownable, Pausable, ERC1155Holder, VerifySign {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    address public farmingContract;
    address public referralContract;
    address public exchangeContract;
    address public immutable oldMarket;

    uint256 public constant ZOOM_USDT = 10 ** 6;
    uint256 public constant ZOOM_FEE = 10 ** 4;

    uint256 public marketFee;
    uint256 public firstSellFee;
    uint256 public artistLoyaltyFee;
    uint256 public referralFee;

    uint256 public numberItems;
    uint256 public numberBidOrders;
    //A record of bidding status
    bool public biddingStatus;

    struct Item {
        address owner;
        address tokenAddress;
        address paymentToken;
        uint256 tokenId;
        uint256 quantity;
        uint256 expired;
        uint256 status; // 1: available| 2: sold out| 3: cancel list
        uint256 minBid;
        uint256 price;
        uint256 mask; // 1: for sale | 2: for bid
    }

    struct Fee {
        uint256 itemFee;
        uint256 buyerFee;
        uint256 sellerFee;
        uint256 loyaltyFee;
    }
    struct ReferralAddress {
        address payable buyerRef;
        address payable sellerRef;
    }
    struct BidOrder {
        address fromAddress;
        address bidToken;
        uint256 bidAmount;
        uint256 itemId;
        uint256 quantity;
        uint256 expired;
        uint256 status; // 1: available | 2: done | 3: reject
    }

    mapping(uint256 => Item) public items;
    mapping(address => mapping(uint256 => uint256)) lastSalePrice;
    mapping(uint256 => BidOrder) bidOrders;
    mapping(address => uint256) whitelistPayableToken;

    event Withdraw(address indexed beneficiary, uint256 withdrawAmount);
    event FailedWithdraw(address indexed beneficiary, uint256 withdrawAmount);
    event Buy(uint256 _itemId, uint256 _quantity, address _paymentToken, uint256 _paymentAmount);
    event AcceptSale(address _buyer, uint256 _itemId, uint256 _quantity, address _paymentToken, uint256 _paymentAmount);
    event UpdateItem(uint256 _itemId, uint256 _mask, uint256 _price, address _paymentToken, uint256 _expiration);
    event CancelListed(uint256 _itemId, address _receiver);
    event Bid(uint _bidId, uint256 _itemId, uint256 _quantity, address _bidToken, uint256 _bidAmount, uint256 _expiration);
    event List(uint _orderId, address _tokenAddress, uint256 tokenId, uint256 _quantity, uint256 _mask, uint256 _price, address _paymentToken, uint256 _expiration);
    event AcceptBid(uint256 _bidOrderId, bool _result);
    event UpdateBid(uint256 _bidId, uint256 _quantity, address _bidToken, uint256 _bidAmount, uint256 _expiration, uint _status);
    event AdminMigrateData(uint256 _itemId, address _owner, address _toContract);
    event BiddingStatus(address _account, bool _status);
    event PayBack(address _account, uint256 _repay);

    constructor(address _oldMarket) public {
        oldMarket = _oldMarket;
    }
    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function pause() onlyOwner public {
        _pause();
    }
    function unPause() onlyOwner public {
        _unpause();
    }

    function enableBidding() onlyOwner public {
        biddingStatus = true;
        emit BiddingStatus(msg.sender, biddingStatus);
    }

    function disableBidding() onlyOwner public {
        biddingStatus = false;
        emit BiddingStatus(msg.sender, biddingStatus);
    }

    function setSystemFee(uint256 _marketFee, uint256 _firstSellFee, uint256 _artistLoyaltyFee, uint256 _referralFee) onlyOwner
    public returns (bool) {
        marketFee = _marketFee;
        firstSellFee = _firstSellFee;
        artistLoyaltyFee = _artistLoyaltyFee;
        referralFee = _referralFee;
        return true;
    }

    function setFarmingContract(address _farmingContract) onlyOwner public returns (bool) {
        farmingContract = _farmingContract;
        return true;
    }

    function setReferralContract(address _referralContract) onlyOwner public returns (bool) {
        referralContract = _referralContract;
        return true;
    }

    function setExchangeContract(address _exchangeContract) onlyOwner public returns (bool) {
        exchangeContract = _exchangeContract;
        return true;
    }

    function setWhiteListPayableToken(address _token, uint256 _status) onlyOwner public returns (bool){
        whitelistPayableToken[_token] = _status;
        if (_token != address (0)) {
            IERC20(_token).approve(msg.sender, uint(-1));
            IERC20(_token).approve(address (this), uint(-1));
        }
        return true;
    }


    function getReferralAddress(address _user) private returns(address payable) {
        return payable(IReferral(referralContract).getReferral(_user));
    }

    Fee fee;
    ReferralAddress ref;

    function estimateUSDT(address _paymentToken, uint256 _paymentAmount) private returns (uint256) {
        return IExchange(exchangeContract).estimateToUSDT(_paymentToken, _paymentAmount);
    }

    function estimateToken(address _paymentToken, uint256 _usdtAmount) private returns (uint256) {
        return IExchange(exchangeContract).estimateFromUSDT(_paymentToken, _usdtAmount);
    }

    function executeOrder(address _buyer, uint256 _itemId, uint256 _quantity, address _paymentToken, uint256 _paymentAmount)
    private returns(bool) {
        Item storage item = items[_itemId];
        address payable creator = payable(IERC1155(item.tokenAddress).getCreator(item.tokenId));
        uint256 loyalty = IERC1155(item.tokenAddress).getLoyaltyFee(item.tokenId);

        uint256 itemPrice = estimateToken(_paymentToken, item.price.div(item.quantity).mul(_quantity));
        uint256 priceInUsdt = item.price.div(item.quantity).mul(_quantity);

        if(_paymentToken == address(0)){
            require (msg.value >= _paymentAmount, 'Invalid price (BNB)');
        }

        // for sale
        if(item.mask == 1){
            require (_paymentAmount >= itemPrice.mul(ZOOM_FEE + marketFee).div(ZOOM_FEE), 'Invalid price');
            if(_paymentToken == address(0)){
                // excess cash (BNB)
                uint256 _repay = _paymentAmount.sub(itemPrice.mul(ZOOM_FEE + marketFee).div(ZOOM_FEE));
                if(_repay > 0){
                    address payable _payee = payable(_buyer);
                    _payee.transfer(_repay);
                    emit PayBack(_buyer, _repay);
                }
            }else{
                // erc20
                _paymentAmount = itemPrice.mul(ZOOM_FEE + marketFee).div(ZOOM_FEE);
            }
        }else{
            // for acceptSale
            require (_paymentAmount >= itemPrice, 'Invalid min price');
            itemPrice = estimateToken(_paymentToken, _paymentAmount.div(ZOOM_FEE + marketFee).mul(ZOOM_FEE));
            priceInUsdt = itemPrice;
        }

        ref.buyerRef = getReferralAddress(_buyer);
        ref.sellerRef = getReferralAddress(item.owner);
        if (lastSalePrice[item.tokenAddress][item.tokenId] == 0) { // first sale
            if (msg.value == 0) {
                if (item.tokenAddress == farmingContract) {
                    /**
                        * buyer pay itemPrice + marketFee
                        * seller receive artistLoyaltyFee * itemPrice / 100
                        * artist receive itemPrice * (100 - artistLoyaltyFee)
                        * referral of buyer receive (marketFee * itemPrice / 100) * (referralFee / 100)
                    */
                    fee.itemFee = itemPrice.mul(marketFee).div(ZOOM_FEE);
                    ERC20(_paymentToken).safeTransferFrom(_buyer, address(this), _paymentAmount);
                    IERC20(_paymentToken).transfer(creator, itemPrice.mul(artistLoyaltyFee).div(ZOOM_FEE));
                    IERC20(_paymentToken).transfer(item.owner, itemPrice.mul(ZOOM_FEE - artistLoyaltyFee).div(ZOOM_FEE));
                    if (ref.buyerRef != address(0)) {
                        IERC20(_paymentToken).transfer(ref.buyerRef, fee.itemFee.mul(referralFee).div(ZOOM_FEE));
                    }
                } else {
                    /**
                       * buyer pay itemPrice + marketFee
                       * seller receive itemPrice - itemPrice * firstSellFee / 100
                       * referral of seller receive itemPrice * firstSellFee / 100 * (referralFee / 100)
                       * referral of buyer receive itemPrice * marketFee / 100 * (referralFee / 100)
                   */
                    fee.buyerFee = itemPrice.mul(marketFee).div(ZOOM_FEE);
                    fee.sellerFee = itemPrice.mul(firstSellFee).div(ZOOM_FEE);
                    ERC20(_paymentToken).safeTransferFrom(_buyer, address(this), _paymentAmount);
                    IERC20(_paymentToken).transfer(item.owner, itemPrice.mul(ZOOM_FEE - firstSellFee).div(ZOOM_FEE));
                    if (ref.buyerRef != address(0)) {
                        IERC20(_paymentToken).transfer(ref.buyerRef, fee.buyerFee.mul(referralFee).div(ZOOM_FEE));
                    }
                    if (ref.sellerRef != address(0)) {
                        IERC20(_paymentToken).transfer(ref.sellerRef, fee.sellerFee.mul(referralFee).div(ZOOM_FEE));
                    }
                }
            } else {
                if (item.tokenAddress == farmingContract) {
                    /**
                        * buyer pay itemPrice + marketFee
                        * seller receive artistLoyaltyFee * itemPrice / 100
                        * artist receive itemPrice * (100 - artistLoyaltyFee)
                        * referral of buyer receive (marketFee * itemPrice / 100) * (referralFee / 100)
                    */
                    fee.itemFee = itemPrice.mul(marketFee).div(ZOOM_FEE);
                    creator.transfer(itemPrice.mul(artistLoyaltyFee).div(ZOOM_FEE));
                    payable(item.owner).transfer(itemPrice.mul(ZOOM_FEE - artistLoyaltyFee).div(ZOOM_FEE));
                    if (ref.buyerRef != address(0)) {
                        ref.buyerRef.transfer(fee.itemFee.mul(referralFee).div(ZOOM_FEE));
                    }
                } else {
                    /**
                       * buyer pay itemPrice + marketFee
                       * seller receive itemPrice - itemPrice * firstSellFee / 100
                       * referral of seller receive itemPrice * firstSellFee / 100 * (referralFee / 100)
                       * referral of buyer receive itemPrice * marketFee / 100 * (referralFee / 100)
                   */
                    fee.buyerFee = itemPrice.mul(marketFee).div(ZOOM_FEE);
                    fee.sellerFee = itemPrice.mul(firstSellFee).div(ZOOM_FEE);
                    payable(item.owner).transfer(itemPrice.mul(ZOOM_FEE - firstSellFee).div(ZOOM_FEE));
                    if (ref.buyerRef != address(0)) {
                        ref.buyerRef.transfer(fee.buyerFee.mul(referralFee).div(ZOOM_FEE));
                    }
                    if (ref.sellerRef != address(0)) {
                        ref.sellerRef.transfer(fee.sellerFee.mul(referralFee).div(ZOOM_FEE));
                    }
                }
            }
        } else {
            if (lastSalePrice[item.tokenAddress][item.tokenId] < priceInUsdt) {
                uint256 revenue = (priceInUsdt - lastSalePrice[item.tokenAddress][item.tokenId]).mul(ZOOM_FEE).div(priceInUsdt);
                /**
                       * buyer pay itemPrice + marketFee
                       * seller receive itemPrice - itemPrice * marketFee / 100 - revenue * lastSalePrice[tokenAddress][tokenId] * item.loyalty
                       * referral of seller receive  itemPrice * marketFee / 100 * (referralFee / 100)
                       * referral of buyer receive itemPrice * marketFee / 100 * (referralFee / 100)
                       * creator receive revenue * lastSalePrice[tokenAddress][tokenId] * loyalty
                   */
                if (msg.value > 0) {
                    fee.loyaltyFee = itemPrice.mul(revenue).div(ZOOM_FEE).mul(loyalty).div(ZOOM_FEE);
                    fee.buyerFee = itemPrice.mul(marketFee).div(ZOOM_FEE);
                    fee.sellerFee = itemPrice.mul(marketFee).div(ZOOM_FEE);
                    payable(item.owner).transfer(itemPrice.mul(ZOOM_FEE - marketFee).div(ZOOM_FEE).sub(fee.loyaltyFee));
                    creator.transfer(fee.loyaltyFee);
                    if (ref.buyerRef != address(0)) {
                        ref.buyerRef.transfer(fee.buyerFee.mul(referralFee).div(ZOOM_FEE));
                    }
                    if (ref.sellerRef != address(0)) {
                        ref.sellerRef.transfer(fee.sellerFee.mul(referralFee).div(ZOOM_FEE));
                    }
                } else {
                    fee.loyaltyFee = itemPrice.mul(revenue).div(ZOOM_FEE).mul(loyalty).div(ZOOM_FEE);
                    fee.buyerFee = itemPrice.mul(marketFee).div(ZOOM_FEE);
                    fee.sellerFee = itemPrice.mul(marketFee).div(ZOOM_FEE);
                    ERC20(_paymentToken).safeTransferFrom(_buyer, address(this), _paymentAmount);
                    IERC20(_paymentToken).transfer(item.owner, itemPrice.mul(ZOOM_FEE - marketFee).div(ZOOM_FEE).sub(fee.loyaltyFee));
                    IERC20(_paymentToken).transfer(creator, fee.loyaltyFee);
                    if (ref.buyerRef != address(0)) {
                        IERC20(_paymentToken).transfer(ref.buyerRef, fee.buyerFee.mul(referralFee).div(ZOOM_FEE));
                    }
                    if (ref.sellerRef != address(0)) {
                        IERC20(_paymentToken).transfer(ref.sellerRef, fee.sellerFee.mul(referralFee).div(ZOOM_FEE));
                    }

                }
            } else {
                fee.buyerFee = itemPrice.mul(marketFee).div(ZOOM_FEE);
                fee.sellerFee = itemPrice.mul(marketFee).div(ZOOM_FEE);
                if (msg.value == 0) {
                    ERC20(_paymentToken).safeTransferFrom(_buyer, address(this), _paymentAmount);
                    IERC20(_paymentToken).transfer(item.owner, itemPrice.mul(ZOOM_FEE - marketFee).div(ZOOM_FEE));
                    if (ref.buyerRef != address(0)) {
                        IERC20(_paymentToken).transfer(ref.buyerRef, fee.buyerFee.mul(referralFee).div(ZOOM_FEE));
                    }
                    if (ref.sellerRef != address(0)) {
                        IERC20(_paymentToken).transfer(ref.sellerRef, fee.sellerFee.mul(referralFee).div(ZOOM_FEE));
                    }
                } else {
                    payable(item.owner).transfer(itemPrice.mul(ZOOM_FEE - marketFee).div(ZOOM_FEE));
                    if (ref.buyerRef != address(0)) {
                        ref.buyerRef.transfer(fee.buyerFee.mul(referralFee).div(ZOOM_FEE));
                    }
                    if (ref.sellerRef != address(0)) {
                        ref.sellerRef.transfer(fee.sellerFee.mul(referralFee).div(ZOOM_FEE));
                    }
                }
            }
        }
        IERC1155(item.tokenAddress).safeTransferFrom(address(this), _buyer, item.tokenId, _quantity,
            abi.encodePacked(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")));
        lastSalePrice[item.tokenAddress][item.tokenId] = priceInUsdt.mul(ZOOM_FEE + marketFee).div(ZOOM_FEE);

        // for sale
        if(item.mask == 1){
            item.price = item.price.sub(priceInUsdt);
        }

        item.quantity = item.quantity.sub(_quantity);
        if (item.quantity == 0) {
            item.price = 0;
            item.status = 2; // sold out
        }
        return true;
    }

    function list(address _tokenAddress, uint256 _tokenId, uint256 _quantity, uint256 _mask, uint256 _price, address _paymentToken, uint256 _expiration)
    public whenNotPaused returns (uint256 _idx){
        uint balance = IERC1155(_tokenAddress).balanceOf(msg.sender, _tokenId);
        require(balance >= _quantity, 'Not enough token for sale');
        if(_paymentToken != address(0)){
            require(whitelistPayableToken[_paymentToken] == 1, 'Payment token not support');
        }

        IERC1155(_tokenAddress).safeTransferFrom(msg.sender, address(this), _tokenId, _quantity, abi.encodePacked(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")));

        _idx = numberItems;
        Item storage item = items[_idx];
        item.tokenId = _tokenId;
        item.owner = msg.sender;
        item.tokenAddress = _tokenAddress;
        item.quantity = _quantity;
        item.expired = block.timestamp.add(_expiration);
        item.status = 1;
        item.price = _price;
        if (_mask == 2) {
            item.minBid = _price;
        }
        item.mask = _mask;
        item.paymentToken = _paymentToken;
        emit List(_idx, _tokenAddress, _tokenId, _quantity, _mask, _price, _paymentToken, _expiration);
        ++numberItems;
        return _idx;
    }

    function bid(uint256 _itemId, uint256 _quantity, address _bidToken, uint256 _bidAmount, uint256 _expiration)
    public returns (uint256 _idx){
        require(biddingStatus,'Bidding is disabled');

        _idx = numberBidOrders;
        Item memory item = items[_itemId];

        require(item.owner != address(0), 'Item not exist');
        require(item.status == 1, 'Item unavailable');
        require(item.quantity >= _quantity, 'Quantity invalid');
        require(item.owner != msg.sender, 'Owner cannot bid');
        require(item.mask == 2, 'Not for bid');
        require(item.expired >= block.timestamp, 'Item expired');

        if(_bidToken != address(0)){
            require(whitelistPayableToken[_bidToken] == 1, 'Payment token not support');

            uint256 estimateBidUSDT = estimateUSDT(_bidToken, _bidAmount);
            estimateBidUSDT = estimateBidUSDT.div(marketFee + ZOOM_FEE).mul(ZOOM_FEE);
            require(estimateBidUSDT >= item.minBid, 'Bid amount must greater than min bid');
            require(IERC20(_bidToken).approve(address(this), _bidAmount) == true, 'Approve token for bid fail');
        }

        BidOrder storage bidOrder = bidOrders[_idx];
        bidOrder.fromAddress = msg.sender;
        bidOrder.bidToken = _bidToken;
        bidOrder.bidAmount = _bidAmount;
        bidOrder.quantity = _quantity;
        bidOrder.expired = block.timestamp.add(_expiration);
        bidOrder.status = 1;

        numberBidOrders++;
        emit Bid(_idx, _itemId, _quantity, _bidToken, _bidAmount, _expiration);
        return _idx;
    }

    function buy(uint256 _itemId, uint256 _quantity, address _paymentToken, uint256 _paymentAmount)
    external payable whenNotPaused returns (bool) {
        Item storage item = items[_itemId];

        require(item.owner != address(0), 'Item not exist');
        require(msg.sender != item.owner, 'You are the owner');
        if(_paymentToken != address(0)){
            require(whitelistPayableToken[_paymentToken] == 1, 'Payment token not support');
        }

        require(item.status == 1, 'Item unavailable');
        require(item.quantity >= _quantity, 'Invalid quantity');
        //        require(item.expired >= block.timestamp, 'Item expired');
        require(item.mask == 1, 'Not for sale');

        if (executeOrder(msg.sender, _itemId, _quantity, _paymentToken, _paymentAmount)) {
            emit Buy(_itemId, _quantity, _paymentToken, _paymentAmount);
            return true;
        }
        return false;
    }

    function acceptSale( bytes memory _buyerSignature, address _buyer, uint256 _itemId, uint256 _quantity, address _paymentToken, uint256 _paymentAmount)
    external whenNotPaused returns (bool) {
        Item storage item = items[_itemId];

        require(item.owner != address(0), 'Item not exist');
        require(_buyer != address(0), 'Buyer not exist');
        require(msg.sender == item.owner, 'You are not owner');
        require(_buyer != item.owner, 'You are the owner');
        require(_verifyBuyer(_buyerSignature, _buyer, _itemId, _quantity, _paymentAmount, _paymentToken));

        if(_paymentToken != address(0)){
            require(whitelistPayableToken[_paymentToken] == 1, 'Payment token not support');
        }

        require(item.status == 1, 'Item unavailable');
        require(item.quantity >= _quantity, 'Invalid quantity');
        //        require(item.expired >= block.timestamp, 'Item expired');
        require(item.mask == 2, 'Not for bid');

        if (executeOrder(_buyer, _itemId, _quantity, _paymentToken, _paymentAmount)) {
            emit AcceptSale(_buyer, _itemId, _quantity, _paymentToken, _paymentAmount);
            return true;
        }
        return false;
    }

    function acceptBid(uint256 _bidOrderId) public whenNotPaused returns (bool) {
        require(biddingStatus,'Bidding is disabled');

        BidOrder storage bidOrder = bidOrders[_bidOrderId];
        require(bidOrder.status == 1, 'Bid order unavailable');
        require(bidOrder.expired <= block.timestamp, 'Bid order has expired');

        if (executeOrder(bidOrder.fromAddress, bidOrder.itemId, bidOrder.quantity, bidOrder.bidToken, bidOrder.bidAmount)) {
            bidOrder.status = 2;
            emit AcceptBid(_bidOrderId, true);
            return true;
        }
        emit AcceptBid(_bidOrderId, false);
        return false;
    }

    function updateItem(uint256 _itemId, uint256 _mask, uint256 _price, address _paymentToken, uint256 _expiration)
    public returns (bool) {
        Item storage item = items[_itemId];
        require(item.owner == msg.sender, 'Not the owner of this item');
        //        require(item.expired < block.timestamp, 'Already on sale');
        if(_paymentToken != address(0)){
            require(whitelistPayableToken[_paymentToken] == 1, 'Payment token not support');
        }
        item.mask = _mask;
        if (_mask == 1) {
            item.price = _price;
        } else {
            item.minBid = _price;
        }
        item.paymentToken = _paymentToken;
        item.expired = block.timestamp.add(_expiration);
        emit UpdateItem(_itemId, _mask, _price, _paymentToken, _expiration);
        return true;
    }

    function updateBid(uint256 _bidId, uint256 _quantity, address _bidToken, uint256 _bidAmount, uint256 _expiration, uint _status)
    public returns (bool) {
        require(biddingStatus,'Bidding is disabled');

        BidOrder storage bidOrder = bidOrders[_bidId];
        require(bidOrder.fromAddress == msg.sender, 'Not owner');
        require(IERC20(_bidToken).approve(address(this), _bidAmount) == true, 'Approve token for bid fail');
        bidOrder.bidToken = _bidToken;
        bidOrder.bidAmount = _bidAmount;
        bidOrder.quantity = _quantity;
        bidOrder.expired = block.timestamp.add(_expiration);
        bidOrder.status = _status;
        emit UpdateBid(_bidId, _quantity, _bidToken, _bidAmount, _expiration, _status);
        return true;
    }

    function cancelListed(uint256 _itemId) public returns (bool) {
        Item storage item = items[_itemId];
        require(item.owner == msg.sender, 'Not the owner of this item');
        // require(item.expired < block.timestamp, 'Already on sale');

        IERC1155(item.tokenAddress).safeTransferFrom(address(this), msg.sender,  item.tokenId, item.quantity,
            abi.encodePacked(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")));

        item.status = 3;
        item.quantity = 0;
        item.price = 0;
        emit CancelListed(_itemId, item.owner);
        return true;
    }

    /// withdraw allows the owner to transfer out the balance of the contract.
    function withdrawFunds(address payable _beneficiary, address _tokenAddress) external onlyOwner {
        uint _withdrawAmount;
        if (_tokenAddress == address(0)) {
            _beneficiary.transfer(address(this).balance);
            _withdrawAmount = address(this).balance;
        } else {
            _withdrawAmount = IERC20(_tokenAddress).balanceOf(address(this));
            IERC20(_tokenAddress).transfer( _beneficiary, _withdrawAmount);
        }
        emit Withdraw(_beneficiary, _withdrawAmount);
    }

    function adminCancelList(uint256 _itemId, address _receiver) external onlyOwner {
        Item storage item = items[_itemId];
        //        require(item.expired < block.timestamp, 'Already on sale');

        IERC1155(item.tokenAddress).safeTransferFrom(address(this), _receiver,  item.tokenId, item.quantity,
            abi.encodePacked(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")));

        item.status = 3;
        item.quantity = 0;
        item.price = 0;
        emit CancelListed(_itemId, _receiver);
    }

    function adminMigrateDataAll(uint256 _fromOrderId, uint256 _toOrderId) external onlyOwner() {
        for (uint256 _itemId = _fromOrderId; _itemId <= _toOrderId; _itemId++) {
            ( address _owner,
            address _tokenAddress,
            address _paymentToken,
            uint256 _tokenId,
            uint256 _quantity,
            uint256 _expired,
            uint256 _status,
            uint256 _minBid,
            uint256 _price,
            uint256 _mask ) = IMarket(oldMarket).items(_itemId);
            uint256 _lastSalePrice = IMarket(oldMarket).lastSalePrice(_tokenAddress, _tokenId);

            numberItems = _itemId;
            if (_lastSalePrice > 0) {
                lastSalePrice[_tokenAddress][_tokenId] = _lastSalePrice;
            }

            if (_quantity > 0) {
                IERC1155(_tokenAddress).safeTransferFrom(oldMarket, address(this), _tokenId, _quantity, abi.encodePacked(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")));
                Item memory newOrder;

                newOrder.tokenId = _tokenId;
                newOrder.owner = _owner;
                newOrder.tokenAddress = _tokenAddress;
                newOrder.quantity = _quantity;
                newOrder.expired = _expired;
                newOrder.status = _status;
                newOrder.price = _price;
                newOrder.minBid = _minBid;
                newOrder.mask = _mask;
                newOrder.paymentToken = _paymentToken;

                items[_itemId] = newOrder;
            }
        }
    }

    function _verifyBuyer(bytes memory _buyerSignature, address _buyer, uint256 _orderId, uint256 _quantity, uint256 _price, address _paymentToken)
    private view returns (bool) {
        return (verify(_buyerSignature, _buyer, _orderId, _quantity, _price, _paymentToken));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
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
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.2 <0.8.0;

import "./IERC165.sol";

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

  function getCreator(uint256 _id) external view returns(address);

  function getLoyaltyFee(uint256 _id) external view returns(uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

interface IBSCswapRouter {
    function getAmountsOut(
        uint amountIn,
        address[] calldata path)
    external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

interface IReferral {
    function getReferral(
        address user)
    external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

interface IExchange {
    function estimateToUSDT(
        address _paymentToken,
        uint256 _paymentAmount)
    external view returns (uint256);

    function estimateFromUSDT(
        address _paymentToken,
        uint256 _usdtAmount)
    external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

interface IMarket {
    function items(uint256 _itemId)
    external
    view
    returns (
        address,
        address,
        address,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    );

    function lastSalePrice(address _tokenAddress, uint256 _tokenId)
    external
    view
    returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0 <0.8.0;

import { ERC1155Receiver } from "@openzeppelin/contracts/token/ERC1155/ERC1155Receiver.sol";

contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns(bytes4) {
        return ERC1155Receiver(address(0)).onERC1155Received.selector;
    }

    function check() public view returns (bytes4) {
        return ERC1155Receiver(address(0)).onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns(bytes4) {
        return ERC1155Receiver(address(0)).onERC1155Received.selector;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "openzeppelin-solidity/contracts/cryptography/ECDSA.sol";

contract VerifySign {
    // Using Openzeppelin ECDSA cryptography library
    function getMessageHash(
        address _buyer,
        uint256 _itemId,
        uint256 _quantity,
        uint256 _paymentAmount,
        address _paymentToken
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_buyer, _itemId, _quantity, _paymentAmount, _paymentToken));
    }

    // Verify signature function
    function verify(bytes memory _buyerSignature, address _buyer, uint256 _orderId, uint256 _quantity, uint256 _paymentAmount, address _paymentToken) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(_buyer, _orderId, _quantity, _paymentAmount, _paymentToken);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return getSignerAddress(ethSignedMessageHash, _buyerSignature) == _buyer;
    }

    function getSignerAddress(bytes32 _messageHash, bytes memory _signature) public pure returns (address signer) {
        return ECDSA.recover(_messageHash, _signature);
    }

    // Split signature to r, s, v
    function splitSignature(bytes memory _signature)
    public
    pure
    returns (
        bytes32 r,
        bytes32 s,
        uint8 v
    ) {
        require(_signature.length == 65, "invalid signature length");

        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
    public
    pure
    returns (bytes32)
    {
        return ECDSA.toEthSignedMessageHash(_messageHash);
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

// SPDX-License-Identifier: UNLICENSED

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

