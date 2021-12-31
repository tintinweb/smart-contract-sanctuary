// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

interface IProfitEstimator {
    function profitToCreator(
        address _nft,
        address _paymentToken,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _price,
        uint256 _lastBuyPriceInUSD
    ) external payable returns (uint256);
}

interface IReferral {
    function getReferral(address user) external view returns (address payable);
}

import "@openzeppelin/contracts/token/ERC721/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./Manager.sol";

import "./interfaces/IWAYNFT.sol";
import "./interfaces/IWAYExchange.sol";
import "./interfaces/IWAYMarket.sol";

contract WAYMarket is Manager, ERC1155Holder, ERC721Holder, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address payable;

    uint256 public constant ZOOM_FEE = 10**4;
    uint256 public totalOrders;
    uint256 public totalBids;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    struct Order {
        address owner;
        address tokenAddress;
        address paymentToken;
        address retailer;
        uint256 tokenId;
        uint256 quantity;
        uint256 price; // price of 1 NFT in paymentToken
        uint256 retailFee;
        bool isOnsale; // true: on sale, false: cancel
        bool isERC721;
    }

    struct Bid {
        address bidder;
        address paymentToken;
        address tokenAddress;
        uint256 tokenId;
        uint256 bidPrice;
        uint256 quantity;
        uint256 expTime;
        bool status; // 1: available | 2: done | 3: reject
    }

    mapping(uint256 => Order) public orders;
    mapping(bytes32 => uint256) private orderID;
    mapping(uint256 => Bid) public bids;
    mapping(address => mapping(bytes32 => uint256)) lastBuyPriceInUSDT; // lastbuy price of NFT with id = keccak256(address, id) from user in USD
    mapping(address => mapping(uint256 => uint256)) public amountFirstSale;
    mapping(address => mapping(bytes32 => uint256)) public farmingAmount;

    event OrderCreated(
        uint256 indexed _orderId,
        address _tokenAddress,
        uint256 indexed _tokenId,
        uint256 indexed _quantity,
        uint256 _price,
        address _paymentToken
    );
    event Buy(
        uint256 _itemId,
        uint256 _quantity,
        address _paymentToken,
        uint256 _paymentAmount
    );
    event OrderCancelled(uint256 indexed _orderId);
    event OrderUpdated(uint256 indexed _orderId);
    event BidCreated(
        uint256 indexed _bidId,
        address _tokenAddress,
        uint256 indexed _tokenId,
        uint256 indexed _quantity,
        uint256 _price,
        address _paymentToken
    );
    event AcceptBid(uint256 indexed _bidId);
    event BidUpdated(uint256 indexed _bidId);
    event BidCancelled(uint256 indexed _bidId);
    event Paid(address indexed _token, address indexed _to, uint256 _amount);

    function _validAmount(
        uint256 _orderId,
        uint256 _quantity,
        uint256 _paymentAmount,
        address _paymentToken
    ) private view returns (bool) {
        Order memory order = orders[_orderId];

        uint256 buyAmount = (_paymentToken == order.paymentToken)
            ? order.price.mul(_quantity)
            : estimateToken(_paymentToken, order.price.mul(_quantity)); // total purchase amount for quantity*price
        return
            (_paymentAmount >= buyAmount.mul(ZOOM_FEE + xUser).div(ZOOM_FEE))
                ? true
                : false; //102.5%
    }

    modifier validAmount(
        uint256 _orderId,
        uint256 _quantity,
        uint256 _paymentAmount,
        address _paymentToken
    ) {
        require(
            _validAmount(_orderId, _quantity, _paymentAmount, _paymentToken)
        );
        _;
    }

    constructor(address _oldMarket) public Manager(_oldMarket) {}

    function getRefData(address _user) private view returns (address payable) {
        address payable userRef = IReferral(referralContract).getReferral(
            _user
        );
        return userRef;
    }

    function estimateUSDT(address _paymentToken, uint256 _paymentAmount)
        private
        view
        returns (uint256)
    {
        return
            IWAYExchange(WAYExchangeContract).estimateToUSDT(
                _paymentToken,
                _paymentAmount
            );
    }

    function estimateToken(address _paymentToken, uint256 _usdtAmount)
        private
        view
        returns (uint256)
    {
        return
            IWAYExchange(WAYExchangeContract).estimateFromUSDT(
                _paymentToken,
                _usdtAmount
            );
    }

    function _paid(
        address _token,
        address _to,
        uint256 _amount
    ) private {
        require(_to != address(0), "Invalid-address");
        if (_token == address(0)) {
            payable(_to).sendValue(_amount);
        } else {
            IERC20(_token).safeTransfer(_to, _amount);
        }

        emit Paid(_token, _to, _amount);
    }

    function _updateBid(uint256 _bidId, uint256 _quantity)
        private
        returns (bool)
    {
        Bid memory bid = bids[_bidId];
        bid.quantity = bid.quantity.sub(_quantity);
        bids[_bidId] = bid;
        return true;
    }

    function _updateOrder(
        address _buyer,
        address _paymentToken,
        uint256 _orderId,
        uint256 _quantity,
        uint256 _price,
        bytes32 _id
    ) private returns (bool) {
        Order memory order = orders[_orderId];
        if (order.isERC721) {
            IERC721(order.tokenAddress).safeTransferFrom(
                address(this),
                _buyer,
                order.tokenId
            );
        } else {
            IERC1155(order.tokenAddress).safeTransferFrom(
                address(this),
                _buyer,
                order.tokenId,
                _quantity,
                abi.encodePacked(
                    keccak256(
                        "onERC1155Received(address,address,uint256,uint256,bytes)"
                    )
                )
            );
        }
        order.quantity = order.quantity.sub(_quantity);
        orders[_orderId].quantity = order.quantity;
        lastBuyPriceInUSDT[_buyer][_id] = estimateUSDT(_paymentToken, _price);
        return true;
    }

    /**
     * @dev Matching order mechanism
     */

    function _match(address[4] memory _addr, uint256[4] memory _data)
        private
        returns (bool)
    {
        Order memory order = orders[_data[0]];
        uint256 amountToSeller = _data[3]; // amount = price * quantity;

        // If the buyer was referred
        if (_addr[3] != address(0)) {
            // amountToBuyerRef = orderAmount * xUser * yRefRate / ZOOM_FEE ** 2
            uint256 amountToBuyerRef = _data[3].mul(xUser).mul(yRefRate).div(
                ZOOM_FEE**2
            ); // 1.025
            _paid(_addr[1], _addr[3], amountToBuyerRef);

            if (discountForBuyer > 0) {
                // amountToBuyer = orderAmount * xUser * discountForBuyer / ZOOM_FEE ** 2
                _paid(
                    _addr[1],
                    _addr[0],
                    _data[3].mul(xUser).mul(discountForBuyer).div(ZOOM_FEE**2)
                );
            }
        }

        // If the order have the retailer
        if (order.retailer != address(0)) {
            uint256 amountToRetailer = _data[3].mul(order.retailFee).div(
                ZOOM_FEE
            );
            // amountToRetailer = orderAmount * retailFee / ZOOM_FEE
            _paid(_addr[1], order.retailer, amountToRetailer);
            // amountToSeller = amountToSeller - orderAmoun
            amountToSeller = amountToSeller.sub(amountToRetailer);
        }

        // If the collection was created in our market
        if (isWAYNFTs[order.tokenAddress]) {
            address payable creator = payable(
                IWAYNFT(order.tokenAddress).getCreator(order.tokenId)
            );

            // If the supply is greator than zero and the order's owner is the NFT's creator
            if (
                amountFirstSale[order.tokenAddress][order.tokenId] > 0 &&
                (creator == order.owner)
            ) {
                // If the seller was referred
                if (_addr[2] != address(0)) {
                    uint256 amountToSellerRef;

                    if (
                        amountFirstSale[order.tokenAddress][order.tokenId] >=
                        _data[1]
                    ) {
                        // amountToSellerRef = orderAmount * xCreator * yRefRate / ZOOM_FEE ** 2
                        amountToSellerRef = _data[3]
                            .mul(xCreator)
                            .mul(yRefRate)
                            .div(ZOOM_FEE**2);
                        // amountToSeller =
                        amountToSeller = amountToSeller.sub(
                            _data[3].mul(xCreator).div(ZOOM_FEE)
                        );
                        amountFirstSale[order.tokenAddress][
                            order.tokenId
                        ] = amountFirstSale[order.tokenAddress][order.tokenId]
                            .sub(_data[1]);
                    } else {
                        uint256 remainedQuantity = _data[1].sub(
                            amountFirstSale[order.tokenAddress][order.tokenId]
                        );
                        uint256 paybackAmount = remainedQuantity.mul(_data[2]);
                        amountToSeller = amountToSeller.sub(paybackAmount);
                        paybackAmount = paybackAmount.add(
                            remainedQuantity.mul(_data[2]).mul(xCreator).div(
                                ZOOM_FEE
                            )
                        );

                        amountToSellerRef = amountToSeller
                            .mul(xCreator)
                            .mul(yRefRate)
                            .div(ZOOM_FEE**2);
                        amountToSeller = amountToSeller.sub(
                            amountToSeller.mul(xCreator).div(ZOOM_FEE)
                        );

                        _paid(_addr[1], _addr[0], paybackAmount);
                    }

                    _paid(_addr[1], _addr[2], amountToSellerRef);
                } else {
                    if (
                        amountFirstSale[order.tokenAddress][order.tokenId] >=
                        _data[1]
                    ) {
                        amountToSeller = amountToSeller.sub(
                            _data[3].mul(xCreator).div(ZOOM_FEE)
                        );
                        amountFirstSale[order.tokenAddress][
                            order.tokenId
                        ] = amountFirstSale[order.tokenAddress][order.tokenId]
                            .sub(_data[1]);
                    } else {
                        uint256 remainedQuantity = _data[1].sub(
                            amountFirstSale[order.tokenAddress][order.tokenId]
                        );
                        uint256 paybackAmount = remainedQuantity.mul(_data[2]);

                        amountToSeller = amountToSeller.sub(paybackAmount);
                        paybackAmount = paybackAmount.add(
                            remainedQuantity.mul(_data[2]).mul(xCreator).div(
                                ZOOM_FEE
                            )
                        );

                        amountToSeller = amountToSeller.sub(
                            amountToSeller.mul(xCreator).div(ZOOM_FEE)
                        );

                        _paid(_addr[1], _addr[0], paybackAmount);
                    }
                }

                _paid(_addr[1], order.owner, amountToSeller);
            } else {
                if (
                    isFarmingNFTs[order.tokenAddress] &&
                    (order.owner != creator) &&
                    farmingAmount[order.owner][
                        keccak256(
                            abi.encodePacked(order.tokenAddress, order.tokenId)
                        )
                    ] >
                    0
                ) {
                    uint256 a = farmingAmount[order.owner][
                        keccak256(
                            abi.encodePacked(order.tokenAddress, order.tokenId)
                        )
                    ];
                    if (a >= _data[1]) {
                        // If the supply is greater than _quantity

                        _paid(
                            _addr[1],
                            creator,
                            _data[3].mul(zProfitToCreator).div(ZOOM_FEE)
                        );
                        // amountToSeller = amountToSeller.sub(orderAmount.mul(ZOOM_FEE - zProfitToCreator).div(ZOOM_FEE));
                        _paid(
                            _addr[1],
                            order.owner,
                            _data[3].mul(ZOOM_FEE - zProfitToCreator).div(
                                ZOOM_FEE
                            )
                        );
                        farmingAmount[order.owner][
                            keccak256(
                                abi.encodePacked(
                                    order.tokenAddress,
                                    order.tokenId
                                )
                            )
                        ] = a.sub(_data[1]);
                    } else {
                        {
                            // uint256 amountToCreator = a.mul(_price).mul(zProfitToCreator).div(ZOOM_FEE);
                            // amountToSeller = amountToSeller.sub(amountToCreator);
                            // a = _quantity.sub(a);
                            // amountToCreator =
                            // 	amountToCreator +
                            // 	IProfitEstimator(profitEstimatorContract).profitToCreator(
                            // 		order.tokenAddress,
                            // 		_paymentToken,
                            // 		order.tokenId,
                            // 		a,
                            // 		_price,
                            // 		lastBuyPriceInUSDT[order.owner][keccak256(abi.encodePacked(order.tokenAddress, order.tokenId))]
                            // 	);
                            _paid(
                                _addr[1],
                                creator,
                                a.mul(_data[2]).mul(zProfitToCreator).div(
                                    ZOOM_FEE
                                )
                            );
                            _paid(
                                _addr[1],
                                order.owner,
                                a
                                    .mul(_data[2])
                                    .mul(ZOOM_FEE.sub(zProfitToCreator))
                                    .div(ZOOM_FEE)
                            );
                            farmingAmount[order.owner][
                                keccak256(
                                    abi.encodePacked(
                                        order.tokenAddress,
                                        order.tokenId
                                    )
                                )
                            ] = 0;
                        }
                    }
                } else {
                    // amountToSeller = amountToSeller - (amount * xUser / ZOOM_FEE)
                    amountToSeller = amountToSeller.sub(
                        _data[3].mul(xUser).div(ZOOM_FEE)
                    );
                    if (_addr[2] != address(0)) {
                        // If the seller has referred
                        // -> amountToSellerRef = amount * xUser * refRate / ZOOM_FEE ** 2
                        _paid(
                            _addr[1],
                            _addr[2],
                            _data[3].mul(xUser).mul(yRefRate).div(ZOOM_FEE**2)
                        );
                    }

                    // If
                    if (order.owner == creator) {
                        // -> no royalty fee
                        _paid(_addr[1], order.owner, amountToSeller);
                    } else {
                        // -> have to calculate the royalty fee
                        uint256 amountToCreator = IProfitEstimator(
                            profitEstimatorContract
                        ).profitToCreator(
                                order.tokenAddress,
                                _addr[1],
                                order.tokenId,
                                _data[1],
                                _data[2],
                                lastBuyPriceInUSDT[order.owner][
                                    keccak256(
                                        abi.encodePacked(
                                            order.tokenAddress,
                                            order.tokenId
                                        )
                                    )
                                ]
                            );
                        if (amountToCreator > 0) {
                            _paid(_addr[1], creator, amountToCreator);
                        }
                        _paid(
                            _addr[1],
                            order.owner,
                            amountToSeller.sub(amountToCreator)
                        );
                    }
                }
            }
        } else {
            amountToSeller = amountToSeller.sub(
                _data[3].mul(xUser).div(ZOOM_FEE)
            );
            if (_addr[2] != address(0)) {
                _paid(
                    _addr[1],
                    _addr[2],
                    _data[3].mul(xUser).mul(yRefRate).div(ZOOM_FEE**2)
                );
            }
            _paid(_addr[1], order.owner, amountToSeller);
        }
        // 		return _updateOrder(_buyer, _paymentToken, _orderId, _quantity, _price, keccak256(abi.encodePacked(order.tokenAddress, order.tokenId)));

        return
            _updateOrder(
                _addr[0],
                _addr[1],
                _data[0],
                _data[1],
                _data[2],
                keccak256(abi.encodePacked(order.tokenAddress, order.tokenId))
            );
    }

    /**
     * @dev Allow user create order on market
     * @param _tokenAddress is address of NFTs
     * @param _tokenId is id of NFTs
     * @param _quantity is total amount for sale
     * @param _price is price per item in payment method (example 50 USDT)
     * @param _paymentToken is payment method (USDT, WAY, ETH, ...)
     */
    function createOrder(
        address _tokenAddress,
        address _retailer,
        address _paymentToken, // payment method
        uint256 _tokenId,
        uint256 _quantity, // total amount for sale
        uint256 _price, // price of 1 nft
        uint256 _retailFee
    ) public whenNotPaused returns (uint256 _orderId) {
        require(_quantity > 0, "Invalid-quantity");
        bool isERC721 = IERC721(_tokenAddress).supportsInterface(
            _INTERFACE_ID_ERC721
        );
        uint256 balance;
        if (isERC721) {
            balance = (IERC721(_tokenAddress).ownerOf(_tokenId) == msg.sender)
                ? 1
                : 0;
            require(balance >= _quantity, "Insufficient-token-balance");
            IERC721(_tokenAddress).safeTransferFrom(
                msg.sender,
                address(this),
                _tokenId
            );
        } else {
            balance = IERC1155(_tokenAddress).balanceOf(msg.sender, _tokenId);
            require(balance >= _quantity, "Insufficient-token-balance");
            IERC1155(_tokenAddress).safeTransferFrom(
                msg.sender,
                address(this),
                _tokenId,
                _quantity,
                "0x"
            );
        }
        require(
            paymentMethod[_paymentToken],
            "Payment-method-does-not-support"
        );
        Order memory newOrder;
        newOrder.isOnsale = true;
        newOrder.owner = msg.sender;
        newOrder.price = _price;
        newOrder.quantity = _quantity;
        if (isRetailer[_retailer]) {
            newOrder.retailer = _retailer;
            newOrder.retailFee = _retailFee;
        }
        newOrder.tokenId = _tokenId;
        newOrder.isERC721 = isERC721;
        newOrder.tokenAddress = _tokenAddress;
        newOrder.paymentToken = _paymentToken;
        if (
            isWAYNFTs[_tokenAddress] &&
            IWAYNFT(_tokenAddress).getCreator(_tokenId) == msg.sender &&
            amountFirstSale[_tokenAddress][_tokenId] == 0 &&
            lastBuyPriceInUSDT[msg.sender][
                keccak256(abi.encodePacked(_tokenAddress, _tokenId))
            ] ==
            0
        ) {
            amountFirstSale[_tokenAddress][_tokenId] = balance;
        }
        if (
            isFarmingNFTs[_tokenAddress] &&
            (msg.sender != IWAYNFT(_tokenAddress).getCreator(_tokenId)) &&
            (lastBuyPriceInUSDT[msg.sender][
                keccak256(abi.encodePacked(_tokenAddress, _tokenId))
            ] == 0)
        ) {
            farmingAmount[msg.sender][
                keccak256(abi.encodePacked(_tokenAddress, _tokenId))
            ] = balance;
        }
        orders[totalOrders] = newOrder;
        _orderId = totalOrders;
        totalOrders = totalOrders.add(1);
        emit OrderCreated(
            _orderId,
            _tokenAddress,
            _tokenId,
            _quantity,
            _price,
            _paymentToken
        );
        bytes32 _id = keccak256(
            abi.encodePacked(_tokenAddress, _tokenId, msg.sender)
        );
        orderID[_id] = _orderId;
        return _orderId;
    }

    function buy(
        uint256 _orderId,
        uint256 _quantity,
        address _paymentToken
    ) external payable whenNotPaused returns (bool) {
        Order memory order = orders[_orderId];
        require(order.owner != address(0), "Invalid-order-id");
        require(
            paymentMethod[_paymentToken],
            "Payment-method-does-not-support"
        );
        require(
            order.isOnsale && order.quantity >= _quantity,
            "Not-available-to-buy"
        );
        uint256 orderAmount = order.price.mul(_quantity);

        // order_amount = price * quantity

        uint256 exactPaymentAmount;

        if (_paymentToken != order.paymentToken) {
            // If user doesn't use USDT to pay
            orderAmount = estimateToken(_paymentToken, orderAmount);
        }

        exactPaymentAmount = orderAmount.mul(ZOOM_FEE + xUser).div(ZOOM_FEE); // exact payment amount = order_amount * 1.025 --> 2.5% system fee
        // if (_paymentToken == order.paymentToken) {
        // 	// exactAmount = orderAmount * 1.025
        // 	exactPaymentAmount = orderAmount.mul(ZOOM_FEE + xUser).div(ZOOM_FEE);
        // } else {

        // 	orderAmount = estimateToken(_paymentToken, orderAmount);
        // 	exactPaymentAmount = orderAmount.mul(ZOOM_FEE + xUser).div(ZOOM_FEE);
        // }
        if (_paymentToken == WAY && discountForWAY > 0) {
            // If user pay with WAY token -> discount 50% system fee -> 1.25% system fee

            // exact_amount = exact_amount - (order_amount * (xUser * discountForSota) / ZOOM_FEE ** 2)
            exactPaymentAmount = exactPaymentAmount.sub(
                orderAmount.mul(discountForWAY).mul(xUser).div(ZOOM_FEE**2)
            );
        }

        if (_paymentToken == address(0) && msg.value > 0) {
            // If use pay with ETh
            require(
                msg.value >= exactPaymentAmount,
                "The value should be greater than the exact payment amount"
            );
        } else {
            // transfer the token to the contract
            IERC20(_paymentToken).safeTransferFrom(
                msg.sender,
                address(this),
                exactPaymentAmount
            );
        }
        emit Buy(_orderId, _quantity, _paymentToken, exactPaymentAmount);
        // return _match(msg.sender, _paymentToken, _orderId, _quantity, estimateToken(_paymentToken, order.price), orderAmount, getRefData(order.owner), getRefData(msg.sender));
        return
            _match(
                [
                    msg.sender,
                    _paymentToken,
                    payable(getRefData(order.owner)),
                    payable(getRefData(msg.sender))
                ],
                [
                    _orderId,
                    _quantity,
                    estimateToken(_paymentToken, order.price),
                    orderAmount
                ]
            );
    }

    function createBid(
        address _tokenAddress,
        address _paymentToken, // payment method
        uint256 _tokenId,
        uint256 _quantity, // total amount want to buy
        uint256 _price, // price of 1 nft
        uint256 _expTime
    ) external payable whenNotPaused returns (uint256 _bidId) {
        require(_quantity > 0, "Invalid-quantity");
        require(
            paymentMethod[_paymentToken],
            "Payment-method-does-not-support"
        );
        Bid memory newBid;
        newBid.bidder = msg.sender;
        newBid.bidPrice = _price;
        newBid.quantity = _quantity;
        newBid.tokenId = _tokenId;
        newBid.tokenAddress = _tokenAddress;
        if (msg.value > 0) {
            require(msg.value >= _quantity.mul(_price), "Invalid-amount");
            newBid.paymentToken = address(0);
        } else {
            newBid.paymentToken = _paymentToken;
        }
        newBid.status = true;
        newBid.expTime = _expTime;
        bids[totalBids] = newBid;
        _bidId = totalBids;
        totalBids = totalBids.add(1);
        emit BidCreated(
            _bidId,
            _tokenAddress,
            _tokenId,
            _quantity,
            _price,
            _paymentToken
        );
        return _bidId;
    }

    function acceptBid(uint256 _bidId, uint256 _quantity)
        external
        whenNotPaused
        returns (bool)
    {
        Bid memory bid = bids[_bidId];
        bytes32 _id = keccak256(
            abi.encodePacked(bid.tokenAddress, bid.tokenId, msg.sender)
        );
        uint256 _orderId = orderID[_id];
        Order memory order;
        if (_orderId == 0) {
            uint256 orderId = createOrder(
                bid.tokenAddress,
                address(0),
                bid.paymentToken,
                bid.tokenId,
                _quantity,
                bid.bidPrice,
                0
            );
            order = orders[orderId];
        } else {
            order = orders[_orderId];
        }
        require(
            order.owner == msg.sender && order.isOnsale,
            "Oops!Wrong-order-owner-or-cancelled"
        );
        require(
            order.quantity >= _quantity &&
                _quantity <= bid.quantity &&
                bid.status,
            "Invalid-quantity-or-bid-cancelled"
        );
        uint256 orderAmount = bid.bidPrice.mul(_quantity);
        uint256 exactPaymentAmount = orderAmount.mul(ZOOM_FEE + xUser).div(
            ZOOM_FEE
        ); // 1.025
        if (bid.paymentToken == WAY) {
            exactPaymentAmount = exactPaymentAmount.sub(
                orderAmount.mul(discountForWAY).div(ZOOM_FEE)
            );
        }
        if (bid.paymentToken != address(0)) {
            IERC20(bid.paymentToken).safeTransferFrom(
                bid.bidder,
                address(this),
                exactPaymentAmount
            );
        }
        // _match(bid.bidder, bid.paymentToken, _orderId, _quantity, bid.bidPrice, orderAmount, getRefData(msg.sender), getRefData(bid.bidder));
        _match(
            [
                bid.bidder,
                bid.paymentToken,
                payable(getRefData(msg.sender)),
                payable(getRefData(bid.bidder))
            ],
            [_orderId, _quantity, bid.bidPrice, orderAmount]
        );
        emit AcceptBid(_bidId);
        return _updateBid(_bidId, _quantity);
    }

    function cancelOrder(uint256 _orderId) external whenNotPaused {
        Order memory order = orders[_orderId];
        require(
            order.owner == msg.sender && order.isOnsale,
            "Oops!Wrong-order-owner-or-cancelled"
        );
        if (order.isERC721) {
            IERC721(order.tokenAddress).safeTransferFrom(
                address(this),
                order.owner,
                order.tokenId
            );
        } else {
            IERC1155(order.tokenAddress).safeTransferFrom(
                address(this),
                order.owner,
                order.tokenId,
                order.quantity,
                abi.encodePacked(
                    keccak256(
                        "onERC1155Received(address,address,uint256,uint256,bytes)"
                    )
                )
            );
        }
        order.quantity = 0;
        order.isOnsale = false;
        orders[_orderId] = order;
        emit OrderCancelled(_orderId);
    }

    function cancelBid(uint256 _bidId) external whenNotPaused nonReentrant {
        Bid memory bid = bids[_bidId];
        require(bid.bidder == msg.sender, "Invalid-bidder");
        if (bid.paymentToken == address(0)) {
            uint256 payBackAmount = bid.quantity.mul(bid.bidPrice);
            // payable(msg.sender).sendValue(payBackAmount);
            _paid(bid.paymentToken, bid.bidder, payBackAmount);
        }
        bid.status = false;
        bid.quantity = 0;
        bids[_bidId] = bid;
        emit BidCancelled(_bidId);
    }

    function updateOrder(
        uint256 _orderId,
        uint256 _quantity,
        uint256 _price,
        uint256 _retailFee,
        address _retailer
    ) external whenNotPaused {
        Order memory order = orders[_orderId];
        require(
            order.owner == msg.sender && order.isOnsale,
            "Oops!Wrong-order-owner-or-cancelled"
        );
        if (_quantity > order.quantity && !order.isERC721) {
            IERC1155(order.tokenAddress).safeTransferFrom(
                msg.sender,
                address(this),
                order.tokenId,
                _quantity.sub(order.quantity),
                "0x"
            );
            order.quantity = _quantity;
        } else if (_quantity < order.quantity) {
            IERC1155(order.tokenAddress).safeTransferFrom(
                address(this),
                msg.sender,
                order.tokenId,
                order.quantity.sub(_quantity),
                abi.encodePacked(
                    keccak256(
                        "onERC1155Received(address,address,uint256,uint256,bytes)"
                    )
                )
            );
            order.quantity = _quantity;
        }
        order.price = _price;
        orders[_orderId] = order;
        order.retailer = _retailer;
        order.retailFee = _retailFee;
        emit OrderUpdated(_orderId);
    }

    function updateBid(
        uint256 _bidId,
        uint256 _quantity,
        uint256 _bidPrice
    ) external payable whenNotPaused {
        Bid memory bid = bids[_bidId];
        require(bid.bidder == msg.sender, "Invalid-bidder");

        if (bid.paymentToken == address(0) && msg.value > 0) {
            require(msg.value >= _quantity.mul(_bidPrice), "Invalid-amount");
            uint256 paybackAmount = bid
                .quantity
                .mul(bid.bidPrice)
                .mul(xUser)
                .div(ZOOM_FEE);
            _paid(bid.paymentToken, bid.bidder, paybackAmount);
        }

        bid.quantity = _quantity;
        bid.bidPrice = _bidPrice;
        bids[_bidId] = bid;
        emit BidUpdated(_bidId);
    }

    function adminMigrateData(uint256 _fromOrderId, uint256 _toOrderId)
        external
        onlyOwner
    {
        for (uint256 i = _fromOrderId; i <= _toOrderId; i++) {
            (
                address owner,
                address tokenAddress,
                address paymentToken,
                ,
                uint256 tokenId,
                uint256 quantity,
                uint256 price,
                ,
                ,

            ) = IWAYMarket(oldMarket).orders(i);
            if (quantity > 0) {
                IERC1155(tokenAddress).safeTransferFrom(
                    oldMarket,
                    address(this),
                    tokenId,
                    quantity,
                    "0x"
                );
                Order memory newOrder;
                newOrder.isOnsale = true;
                newOrder.owner = owner;
                newOrder.price = price.div(quantity).mul(10000).div(10250);
                newOrder.quantity = quantity;
                newOrder.tokenId = tokenId;
                newOrder.tokenAddress = tokenAddress;
                newOrder.paymentToken = paymentToken;
                orders[totalOrders] = newOrder;
                uint256 _orderId = totalOrders;
                bytes32 _id = keccak256(
                    abi.encodePacked(tokenAddress, tokenId, owner)
                );
                orderID[_id] = _orderId;
            }
            totalOrders = totalOrders.add(1);
        }
    }

    function setApproveForAll(address _token, address _spender)
        external
        onlyOwner
    {
        IERC1155(_token).setApprovalForAll(_spender, true);
    }

    function setApproveForAllERC721(address _token, address _spender)
        external
        onlyOwner
    {
        IERC721(_token).setApprovalForAll(_spender, true);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC721Receiver.sol";

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
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
contract ReentrancyGuard {
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

    constructor () internal {
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
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Pausable.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';

contract Manager is Ownable, Pausable {
	using SafeERC20 for IERC20;
	address public immutable oldMarket;
	address public WAY;
	address public referralContract;
	address public WAYExchangeContract;
	address public profitEstimatorContract;

	// FEE
	uint256 public xUser = 250; // 2.5%
	uint256 public xCreator = 1500;
	uint256 public yRefRate = 5000; // 50%
	uint256 public zProfitToCreator = 5000; // 10% profit
	uint256 public discountForBuyer = 5000;
	uint256 public discountForWAY = 100; // discount for user who made payment in WAY
	mapping(address => bool) public paymentMethod;
	mapping(address => bool) public isWAYNFTs;
	mapping(address => bool) public isFarmingNFTs;
	mapping(address => bool) public isOperator;
	mapping(address => bool) public isRetailer;

	modifier onlyOperator() {
		require(isOperator[msg.sender], 'Only-operator');
		_;
	}

	constructor(address _oldMarket) public {
		isOperator[msg.sender] = true;
		oldMarket = _oldMarket;
	}

	function whiteListOperator(address _operator, bool _whitelist) external onlyOwner {
		isOperator[_operator] = _whitelist;
	}

	function whiteListRetailer(address _retailer, bool _whitelist) external onlyOwner {
		isRetailer[_retailer] = _whitelist;
	}

	function pause() public onlyOwner {
		_pause();
	}

	function unPause() public onlyOwner {
		_unpause();
	}

	function setSystemFee(
		uint256 _xUser,
		uint256 _xCreator,
		uint256 _yRefRate,
		uint256 _zProfitToCreator,
		uint256 _discountForBuyer,
		uint256 _discountForWAY
	) external onlyOwner {
		_setSystemFee(_xUser, _xCreator, _yRefRate, _zProfitToCreator, _discountForBuyer, _discountForWAY);
	}

	function _setSystemFee(
		uint256 _xUser,
		uint256 _xCreator,
		uint256 _yRefRate,
		uint256 _zProfitToCreator,
		uint256 _discountForBuyer,
		uint256 _discountForWAY
	) internal {
		xUser = _xUser;
		xCreator = _xCreator;
		yRefRate = _yRefRate;
		zProfitToCreator = _zProfitToCreator;
		discountForBuyer = _discountForBuyer;
		discountForWAY = _discountForWAY;
	}

	function setWAYContract(address _way) public onlyOwner returns (bool) {
		WAY = _way;
		return true;
	}

	function addWAYNFTs(
		address _wayNFT,
		bool _isWAYNFT,
		bool _isFarming
	) external onlyOperator returns (bool) {
		isWAYNFTs[_wayNFT] = _isWAYNFT;
		if (_isFarming) {
			isFarmingNFTs[_wayNFT] = true;
		}
		return true;
	}

	function setReferralContract(address _referralContract) public onlyOwner returns (bool) {
		referralContract = _referralContract;
		return true;
	}

	function setWAYExchangeContract(address _wayExchangeContract) public onlyOwner returns (bool) {
		WAYExchangeContract = _wayExchangeContract;
		return true;
	}

	function setProfitSenderContract(address _profitEstimatorContract) public onlyOwner returns (bool) {
		profitEstimatorContract = _profitEstimatorContract;
		return true;
	}

	function setPaymentMethod(address _token, bool _status) public onlyOwner returns (bool) {
		paymentMethod[_token] = _status;
		if (_token != address(0)) {
			IERC20(_token).safeApprove(msg.sender, uint256(-1));
			IERC20(_token).safeApprove(address(this), uint256(-1));
		}
		return true;
	}

	/**
	 * @notice withdrawFunds
	 */
	function withdrawFunds(address payable _beneficiary, address _tokenAddress) external onlyOwner whenPaused {
		uint256 _withdrawAmount;
		if (_tokenAddress == address(0)) {
			_beneficiary.transfer(address(this).balance);
			_withdrawAmount = address(this).balance;
		} else {
			_withdrawAmount = IERC20(_tokenAddress).balanceOf(address(this));
			IERC20(_tokenAddress).transfer(_beneficiary, _withdrawAmount);
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

interface IWAYNFT {
	function getCreator(uint256 _id) external view returns (address);

	function getLoyaltyFee(uint256 _id) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

interface IWAYExchange {
	function estimateToUSDT(address _paymentToken, uint256 _paymentAmount) external view returns (uint256);

	function estimateFromUSDT(address _paymentToken, uint256 _usdtAmount) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

interface IWAYMarket {
    function orders(uint256 id)
        external
        view
        returns (
            address,
            address,
            address,
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            bool
        );

    function xUser() external view returns (uint256);

    function ZOOM_FEE() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
    external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC1155Receiver.sol";
import "../../introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    constructor() public {
        _registerInterface(
            ERC1155Receiver(0).onERC1155Received.selector ^
            ERC1155Receiver(0).onERC1155BatchReceived.selector
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165 is IERC165 {
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
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
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

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.2;

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

pragma solidity ^0.6.2;

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

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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
contract Ownable is Context {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

pragma solidity ^0.6.0;

import "../GSN/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
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
    function paused() public view returns (bool) {
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
        require(!_paused, "Pausable: paused");
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
        require(_paused, "Pausable: not paused");
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

pragma solidity ^0.6.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

pragma solidity ^0.6.0;

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