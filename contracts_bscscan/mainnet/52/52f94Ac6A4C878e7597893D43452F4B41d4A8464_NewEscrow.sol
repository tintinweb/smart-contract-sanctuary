/**
 *Submitted for verification at BscScan.com on 2021-09-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity ^0.8.0;

interface IERC1155 is IERC165 {
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function ownerOfToken(uint256 _tokenId)
        external
        view
        returns (
            address,
            uint256,
            address,
            uint256
        );

    function burn(
        address from,
        uint256 _tokenId,
        uint256 amount
    ) external returns (bool);
}

pragma solidity 0.8.0;

interface IERC1155Receiver is IERC165 {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

pragma solidity 0.8.0;

abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

pragma solidity 0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}

pragma solidity 0.8.0;

contract NewEscrow is ERC165 {
    using SafeMath for uint256;

    address payable public admin;
    uint256 public orderNonce;
    address public tokenAddress;
    IERC1155 public ERC1155Interface;
    bool locked;

    struct Order {
        address seller;
        uint256 tokenId;
        uint256 amount;
        uint256 pricePerNFT;
        uint256 saleType;
        uint256 timeline;
        address paymentToken;
    }

    struct Bid {
        address bidder;
        uint256 bidValue;
        uint256 timeStamp;
    }

    mapping(uint256 => Order) public order;
    mapping(uint256 => mapping(uint256 => bool)) public secondHand;
    mapping(uint256 => mapping(uint256 => Bid)) public bid;
    mapping(uint256 => mapping(uint256 => address)) private holder;
    mapping(uint256 => mapping(uint256 => bool)) private burnt;
    mapping(uint256 => uint256) public tokenEditions;
    mapping(uint256 => uint256) public flexPlatFee;
    mapping(address => mapping(uint256 => uint256)) public secondHandOrder;

    constructor(address _admin) {
        require(_admin != address(0), "Zero address");
        admin = payable(_admin);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC1155Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    event OrderPlaced(
        Order order,
        uint256 timestamp,
        uint256 nonce,
        uint256 editionNumber
    );
    event OrderBought(
        Order order,
        uint256 timestamp,
        address buyer,
        uint256 nonce,
        uint256 editionNumber
    );
    event OrderCancelled(
        Order order,
        uint256 timestamp,
        uint256 nonce,
        uint256 editionNumber
    );
    event BidPlaced(
        Order order,
        uint256 timestamp,
        address buyer,
        uint256 nonce,
        uint256 editionNumber
    );

    event BidClaimed(
        Order order,
        uint256 timestamp,
        address buyer,
        uint256 nonce,
        uint256 editionNumber
    );

    event EditionTransferred(
        address from,
        address to,
        uint256 id,
        uint256 edition
    );

    function setTokenAddress(address _tokenAddress) external returns (bool) {
        require(msg.sender == admin, "Not admin");
        require(_tokenAddress != address(0), "Zero address");
        tokenAddress = _tokenAddress;
        ERC1155Interface = IERC1155(_tokenAddress);
        return true;
    }

    function changeAdmin(address _admin) external returns (bool) {
        require(msg.sender == admin, "Only admin");
        admin = payable(_admin);
        return true;
    }

    function currentHolder(uint256 _tokenId, uint256 _editionNumber)
        public
        view
        returns (address)
    {
        if (_editionNumber > tokenEditions[_tokenId] || _editionNumber == 0)
            return address(0);
        if (burnt[_tokenId][_editionNumber]) return address(0);
        if (holder[_tokenId][_editionNumber] == address(0)) {
            (address creator1, , , ) = ERC1155Interface.ownerOfToken(_tokenId);
            return creator1;
        }
        return holder[_tokenId][_editionNumber];
    }

    function placeOrder(
        address _creator,
        uint256 _tokenId,
        uint256 _editions,
        uint256 _pricePerNFT,
        uint256 _saleType,
        uint256 _timeline,
        uint256 _adminPlatformFee,
        address _paymentToken
    ) external returns (bool) {
        if (_timeline == 0) {
            _timeline = block.timestamp;
        } else {
            _timeline = block.timestamp.add(_timeline.mul(3600)); //Change 30 to 1 for unit testing and 3600 for production
        }
        require(msg.sender == tokenAddress, "Not token address");
        tokenEditions[_tokenId] = _editions;
        flexPlatFee[_tokenId] = _adminPlatformFee;
        orderNonce = orderNonce.add(1);
        order[orderNonce] = Order(
            _creator,
            _tokenId,
            _editions,
            _pricePerNFT,
            _saleType,
            _timeline,
            _paymentToken
        );

        emit OrderPlaced(
            order[orderNonce],
            block.timestamp,
            orderNonce,
            _editions
        );

        return true;
    }

    function buyNow(uint256 _orderNonce, uint256 _editionNumber)
        external
        payable
        returns (bool)
    {
        Order memory _order = order[_orderNonce];
        require(_order.seller != address(0), "Order expired");
        require(
            _order.saleType == 0 ||
                _order.saleType == 1 ||
                _order.saleType == 2,
            "Wrong saletype"
        );
        if (_order.saleType == 2) {
            require(
                secondHandOrder[_order.seller][_orderNonce] == _editionNumber,
                "Incorrect edition"
            );
        }
        if (_order.saleType == 1) {
            require(
                bid[_order.tokenId][_editionNumber].bidder == address(0),
                "Active bidding"
            );
            require(block.timestamp > _order.timeline, "Auction in progress");
        }
        require(_order.seller != msg.sender, "Seller can't buy");
        require(
            _editionNumber > 0 &&
                _editionNumber <= tokenEditions[_order.tokenId],
            "Wrong edition"
        );
        require(msg.value == (_order.pricePerNFT), "Wrong price");
        require(
            currentHolder(_order.tokenId, _editionNumber) == _order.seller ||
                currentHolder(_order.tokenId, _editionNumber) == address(this),
            "Already sold"
        );
        holder[_order.tokenId][_editionNumber] = msg.sender;
        require(
            buyNowPayment(_order, _editionNumber, msg.value),
            "Payment failed"
        );
        ERC1155Interface.safeTransferFrom(
            address(this),
            msg.sender,
            _order.tokenId,
            1,
            ""
        );

        emit OrderBought(
            _order,
            block.timestamp,
            msg.sender,
            _orderNonce,
            _editionNumber
        );

        if (_order.amount == 1) {
            delete order[_orderNonce];
        } else {
            order[_orderNonce].amount = order[_orderNonce].amount.sub(1);
        }
        return true;
    }

    function buyNowPayment(
        Order memory _order,
        uint256 _editionNumber,
        uint256 payAmount
    ) internal returns (bool) {
        uint256 platformCut;
        uint256 creatorsCut;
        uint256 finalCut;
        uint256 creatorCut;
        uint256 coCreatorsCut;
        (
            address _creator,
            uint256 _percent1,
            address _coCreator,

        ) = ERC1155Interface.ownerOfToken(_order.tokenId);

        if (!secondHand[_order.tokenId][_editionNumber]) {
            if (flexPlatFee[_order.tokenId] > 0) {
                uint256 flexFee = flexPlatFee[_order.tokenId];
                platformCut = payAmount.mul(flexFee).div(100);
            } else {
                platformCut = payAmount.mul(10).div(100);
            }
            creatorsCut = payAmount.sub(platformCut);
            creatorCut = creatorsCut.mul(_percent1).div(100);
            coCreatorsCut = creatorsCut.sub(creatorCut);
            sendValue(payable(_creator), creatorCut);
            if (coCreatorsCut > 0) {
                sendValue(payable(_coCreator), coCreatorsCut);
            }
            sendValue(admin, platformCut);
            secondHand[_order.tokenId][_editionNumber] = true;
        } else {
            platformCut = payAmount.mul(5).div(100);
            creatorsCut = payAmount.mul(10).div(100);
            creatorCut = creatorsCut.mul(_percent1).div(100);
            coCreatorsCut = creatorsCut.sub(creatorCut);
            sendValue(payable(_creator), creatorCut);
            if (coCreatorsCut > 0) {
                sendValue(payable(_coCreator), coCreatorsCut);
            }
            finalCut = payAmount.sub(
                platformCut.add(creatorCut).add(coCreatorsCut)
            );
            sendValue(payable(_order.seller), finalCut);
            sendValue(admin, platformCut);
        }

        return true;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Low balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Sending error");
    }

    function placeBid(uint256 _orderNonce, uint256 _editionNumber)
        external
        payable
        returns (bool)
    {
        Order memory _order = order[_orderNonce];
        require(!locked, "lock");
        locked = true;
        require(_order.seller != address(0), "Order expired");
        require(_order.seller != msg.sender, "Owner can't place bid");
        require(_order.saleType == 1 || _order.saleType == 3, "Wrong saletype");
        require(
            _editionNumber > 0 &&
                _editionNumber <= tokenEditions[_order.tokenId],
            "Wrong edition"
        );
        require(
            msg.value > _order.pricePerNFT &&
                msg.value >=
                (bid[_order.tokenId][_editionNumber].bidValue.mul(11).div(10)),
            "Wrong Price"
        );
        if (_order.saleType == 1) {
            require(block.timestamp <= _order.timeline, "Auction ended");
        } else {
            require(
                secondHandOrder[_order.seller][_orderNonce] == _editionNumber,
                "Wrong edition"
            );
        }
        require(checkBidStatus(_order, _editionNumber));

        bid[_order.tokenId][_editionNumber] = Bid(
            msg.sender,
            msg.value,
            block.timestamp
        );

        emit BidPlaced(
            _order,
            block.timestamp,
            msg.sender,
            _orderNonce,
            _editionNumber
        );
        locked = false;
        return true;
    }

    function claimAfterAuction(uint256 _orderNonce, uint256 _editionNumber)
        external
        returns (bool)
    {
        Order memory _order = order[_orderNonce];
        require(block.timestamp > _order.timeline, "Auction in progress");
        require(
            msg.sender == bid[_order.tokenId][_editionNumber].bidder,
            "Not highest bidder"
        );

        uint256 bidAmount = bid[_order.tokenId][_editionNumber].bidValue;

        delete bid[_order.tokenId][_editionNumber];

        require(buyNowPayment(_order, _editionNumber, bidAmount));

        ERC1155Interface.safeTransferFrom(
            address(this),
            msg.sender,
            _order.tokenId,
            1,
            ""
        );

        holder[_order.tokenId][_editionNumber] = msg.sender;

        if (_order.amount == 1) {
            delete order[_orderNonce];
        } else {
            order[_orderNonce].amount = order[_orderNonce].amount.sub(1);
        }

        _order.pricePerNFT = bidAmount;

        emit OrderBought(
            _order,
            block.timestamp,
            msg.sender,
            _orderNonce,
            _editionNumber
        );
        return true;
    }

    function putOnSaleBuy(
        uint256 _tokenId,
        uint256 _editionNumber,
        uint256 _pricePerNFT
    ) public returns (bool) {
        return placeSecondHandOrder(_tokenId, _editionNumber, _pricePerNFT, 2);
    }

    function cancelSaleOrder(uint256 _orderNonce, uint256 _editionNumber)
        external
        returns (bool)
    {
        Order memory _order = order[_orderNonce];
        require(!locked, "Re-entrant protection");
        locked = true;
        require(
            _order.saleType == 2 || _order.saleType == 3,
            "Can't cancel first hand orders"
        );
        require(_order.seller == msg.sender, "Can cancel only self orders");
        require(
            secondHandOrder[_order.seller][_orderNonce] == _editionNumber,
            "Incorrect edition"
        );
        if (_order.saleType == 3) {
            require(checkBidStatus(_order, _editionNumber));
        }

        ERC1155Interface.safeTransferFrom(
            address(this),
            msg.sender,
            _order.tokenId,
            1,
            ""
        );

        holder[_order.tokenId][_editionNumber] = msg.sender;

        emit OrderCancelled(
            _order,
            block.timestamp,
            _orderNonce,
            _editionNumber
        );

        delete secondHandOrder[msg.sender][_orderNonce];
        delete order[_orderNonce];
        locked = false;
        return true;
    }

    function checkBidStatus(Order memory _order, uint256 _editionNumber)
        internal
        returns (bool)
    {
        if (bid[_order.tokenId][_editionNumber].bidder != address(0)) {
            sendValue(
                payable(bid[_order.tokenId][_editionNumber].bidder),
                bid[_order.tokenId][_editionNumber].bidValue
            );
            delete bid[_order.tokenId][_editionNumber];
        }
        return true;
    }

    function placeSecondHandOrder(
        uint256 _tokenId,
        uint256 _editionNumber,
        uint256 _pricePerNFT,
        uint256 _saleType
    ) public returns (bool) {
        require(
            secondHand[_tokenId][_editionNumber],
            "Edition is not in second market"
        );
        require(
            currentHolder(_tokenId, _editionNumber) == msg.sender,
            "Not owner of edition"
        );
        require(_saleType == 2 || _saleType == 3, "Wrong sale type");
        ERC1155Interface.safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId,
            1,
            ""
        );
        orderNonce = orderNonce.add(1);
        secondHandOrder[msg.sender][orderNonce] = _editionNumber;
        holder[_tokenId][_editionNumber] = address(this);
        order[orderNonce] = Order(
            msg.sender,
            _tokenId,
            1,
            _pricePerNFT,
            _saleType,
            0,
            address(0)
        );

        emit OrderPlaced(
            order[orderNonce],
            block.timestamp,
            orderNonce,
            _editionNumber
        );

        return true;
    }

    function requestOffer(
        uint256 _tokenId,
        uint256 _editionNumber,
        uint256 _pricePerNFT
    ) external returns (bool) {
        return placeSecondHandOrder(_tokenId, _editionNumber, _pricePerNFT, 3);
    }

    function acceptOffer(uint256 _orderNonce, uint256 _editionNumber)
        external
        returns (bool)
    {
        Order memory _order = order[_orderNonce];
        require(_order.saleType == 3, "Wrong order type");
        require(_order.seller == msg.sender, "Only seller can accept offers");
        address buyer = bid[_order.tokenId][_editionNumber].bidder;
        require(buyer != address(0), "No bids placed");

        uint256 bidAmount = bid[_order.tokenId][_editionNumber].bidValue;

        delete bid[_order.tokenId][_editionNumber];

        require(buyNowPayment(_order, _editionNumber, bidAmount));

        ERC1155Interface.safeTransferFrom(
            address(this),
            buyer,
            _order.tokenId,
            1,
            ""
        );
        holder[_order.tokenId][_editionNumber] = buyer;
        _order.pricePerNFT = bidAmount;

        emit OrderBought(
            _order,
            block.timestamp,
            buyer,
            _orderNonce,
            _editionNumber
        );

        delete order[_orderNonce];

        return true;
    }

    function transfer(
        address from,
        address to,
        uint256 id,
        uint256 editionNumber,
        bytes memory data
    ) external returns (bool) {
        require(
            secondHand[id][editionNumber],
            "Edition is not in second market"
        );
        require(currentHolder(id, editionNumber) == msg.sender, "Not owner");
        ERC1155Interface.safeTransferFrom(from, to, id, 1, data);
        holder[id][editionNumber] = to;
        emit EditionTransferred(from, to, id, editionNumber);
        return true;
    }

    function burnTokenEdition(uint256 _tokenId, uint256 _editionNumber)
        external
        returns (bool)
    {
        require(
            secondHand[_tokenId][_editionNumber],
            "Edition is not in second market"
        );
        require(
            currentHolder(_tokenId, _editionNumber) == msg.sender,
            "Not owner"
        );
        ERC1155Interface.burn(msg.sender, _tokenId, 1);
        burnt[_tokenId][_editionNumber] = true;
        emit EditionTransferred(
            msg.sender,
            address(0),
            _tokenId,
            _editionNumber
        );
        return true;
    }

    function claimBack(uint256 _orderNonce, uint256 _editionNumber)
        external
        returns (bool)
    {
        Order memory _order = order[_orderNonce];
        require(_order.saleType == 3, "Wrong order type");
        require(
            secondHandOrder[_order.seller][_orderNonce] == _editionNumber,
            "Incorrect edition"
        );
        require(
            block.timestamp >
                bid[_order.tokenId][_editionNumber].timeStamp.add(86400), //replace 180 with 86400 in production //change this 10 for unit testing
            "Please wait 24 hours before claiming back"
        );
        require(
            msg.sender == bid[_order.tokenId][_editionNumber].bidder,
            "Not highest bidder"
        );
        uint256 bidAmount = bid[_order.tokenId][_editionNumber].bidValue;
        delete bid[_order.tokenId][_editionNumber];
        sendValue(payable(msg.sender), bidAmount);
        emit BidClaimed(
            _order,
            block.timestamp,
            msg.sender,
            _orderNonce,
            _editionNumber
        );

        return true;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure returns (bytes4) {
        return (
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            )
        );
    }
}