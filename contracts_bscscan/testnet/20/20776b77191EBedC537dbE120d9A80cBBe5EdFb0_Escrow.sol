/**
 *Submitted for verification at BscScan.com on 2021-07-22
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

// pragma solidity ^0.8.0;

// interface IERC1155Receiver is IERC165 {
//     function onERC1155Received(
//         address operator,
//         address from,
//         uint256 id,
//         uint256 value,
//         bytes calldata data
//     ) external returns (bytes4);

//     function onERC1155BatchReceived(
//         address operator,
//         address from,
//         uint256[] calldata ids,
//         uint256[] calldata values,
//         bytes calldata data
//     ) external returns (bytes4);
// }
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

contract Escrow {
    using SafeMath for uint256;

    address payable public admin;
    uint256 public orderNonce;
    address public tokenAddress;
    IERC1155 public ERC1155Interface;

    struct Order {
        address seller;
        uint256 tokenId;
        uint256 amount;
        uint256 pricePerNFT;
        uint256 saleType;
        uint256 timeline;
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

    // mapping(uint256 => mapping(uint256 => address)) public accept;

    constructor(address _admin) {
        //ERC1155()
        admin = payable(_admin);
    }

    event OrderPlaced(
        Order order,
        uint256 timestamp,
        // string tokenURI,
        uint256 nonce
    );
    event OrderBought(
        Order order,
        address buyer,
        uint256 nonce,
        uint256 amount
    );
    event OrderCancelled(Order order, uint256 timestamp, uint256 nonce);
    event BidPlaced(
        Order order,
        address buyer,
        uint256 nonce,
        uint256 editionNumber
    );

    event BidClaimed(
        Order order,
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
        require(msg.sender == admin, "Only admin");
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
        uint256 _adminPlatformFee
    ) external returns (bool) {
        uint256 timeline;
        if (_timeline == 0) {
            timeline = block.timestamp;
        } else {
            timeline = block.timestamp.add(_timeline.mul(30));
        }
        require(msg.sender == tokenAddress, "Not allowed");
        tokenEditions[_tokenId] = _editions;
        flexPlatFee[_tokenId] = _adminPlatformFee;
        order[orderNonce] = Order(
            _creator,
            _tokenId,
            _editions,
            _pricePerNFT,
            _saleType,
            timeline
        );

        emit OrderPlaced(
            order[orderNonce],
            block.timestamp,
            // _tokenURI,
            orderNonce
        );
        orderNonce++;

        return true;
    }

    function buyNow(uint256 _orderNonce, uint256 _editionNumber)
        external
        payable
        returns (bool)
    {
        Order memory _order = order[_orderNonce];
        require(
            _order.saleType == 0 ||
                _order.saleType == 1 ||
                _order.saleType == 2,
            "Wrong order type"
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
                "There's an active bid on this edition"
            );
            require(block.timestamp > _order.timeline, "Auction in progress");
        }
        require(_order.seller != msg.sender, "Seller can't buy");
        require(
            _editionNumber > 0 &&
                _editionNumber <= tokenEditions[_order.tokenId],
            "Edition doesn't exist"
        );
        require(msg.value == (_order.pricePerNFT), "Insufficient price");
        require(
            currentHolder(_order.tokenId, _editionNumber) == _order.seller ||
                currentHolder(_order.tokenId, _editionNumber) == address(this),
            "Edition already sold"
        );
        holder[_order.tokenId][_editionNumber] = msg.sender; //Re-entrancy check
        uint256 platformCut;
        uint256 finalCut;
        if (!secondHand[_order.tokenId][_editionNumber]) {
            //add custom platformFee for token by admin and creator, co creator cut for first hand sales - done
            if (flexPlatFee[_order.tokenId] > 0) {
                platformCut = msg.value.mul(flexPlatFee[_order.tokenId]).div(
                    100
                );
            } else {
                platformCut = msg.value.mul(10).div(100);
            }
            (
                address _creator,
                uint256 _percent1,
                address _coCreator,

            ) = ERC1155Interface.ownerOfToken(_order.tokenId);
            uint256 finalcreatorsCut = msg.value.sub(platformCut);
            uint256 creatorCut = finalcreatorsCut.mul(_percent1).div(100);
            uint256 coCreatorsCut = finalcreatorsCut.sub(creatorCut);
            // payable(_creator).transfer(creatorCut);
            sendValue(payable(_creator), creatorCut);
            if (coCreatorsCut > 0) {
                // payable(_coCreator).transfer(coCreatorsCut);
                sendValue(payable(_coCreator), coCreatorsCut);
            }
            secondHand[_order.tokenId][_editionNumber] = true;
            // payable(_order.seller).transfer(msg.value.sub(platformCut));
            // admin.transfer(platformCut);
            sendValue(admin, platformCut);
        } else {
            platformCut = msg.value.mul(5).div(100);
            // admin.transfer(platformCut);
            sendValue(admin, platformCut);
            (
                address _creator,
                uint256 _percent1,
                address _coCreator,

            ) = ERC1155Interface.ownerOfToken(_order.tokenId);
            uint256 finalcreatorsCut = msg.value.mul(10).div(100);
            uint256 creatorCut = finalcreatorsCut.mul(_percent1).div(100);
            uint256 coCreatorsCut = finalcreatorsCut.sub(creatorCut);
            // payable(_creator).transfer(creatorCut);
            sendValue(payable(_creator), creatorCut);
            if (coCreatorsCut > 0) {
                // payable(_coCreator).transfer(coCreatorsCut);
                sendValue(payable(_coCreator), coCreatorsCut);
            }
            // admin.transfer(platformCut);
            finalCut = msg.value.sub(
                platformCut.add(creatorCut).add(coCreatorsCut)
            );
            // payable(_order.seller).transfer(finalCut);
            sendValue(payable(_order.seller), finalCut);
        }

        ERC1155Interface.safeTransferFrom(
            address(this),
            msg.sender,
            _order.tokenId,
            1,
            ""
        );

        // holder[_order.tokenId][_editionNumber] = msg.sender;
        emit OrderBought(_order, msg.sender, _orderNonce, _editionNumber);

        if (_order.amount == 1) {
            delete order[_orderNonce];
        } else {
            order[_orderNonce].amount = order[_orderNonce].amount.sub(1);
        }
        return true;
    }

    function placeBid(uint256 _orderNonce, uint256 _editionNumber)
        external
        payable
        returns (bool)
    {
        Order memory _order = order[_orderNonce];
        require(_order.seller != msg.sender, "Owner can't place");
        require(
            _order.saleType == 1 || _order.saleType == 3,
            "Wrong order type"
        );
        require(
            _editionNumber > 0 &&
                _editionNumber <= tokenEditions[_order.tokenId],
            "Wrong edition number"
        );
        require(
            msg.value > _order.pricePerNFT &&
                msg.value > bid[_order.tokenId][_editionNumber].bidValue,
            "Incorrect Price"
        );
        if (_order.saleType == 1) {
            require(block.timestamp <= _order.timeline, "Auction ended");
        } else {
            require(
                secondHandOrder[_order.seller][_orderNonce] == _editionNumber,
                "Incorrect edition"
            );
        }
        if (bid[_order.tokenId][_editionNumber].bidder != address(0)) {
            // payable(bid[_order.tokenId][_editionNumber].bidder).transfer(
            //     bid[_order.tokenId][_editionNumber].bidValue
            // );
            sendValue(
                payable(bid[_order.tokenId][_editionNumber].bidder),
                bid[_order.tokenId][_editionNumber].bidValue
            );
        }
        bid[_order.tokenId][_editionNumber].bidValue = msg.value;
        bid[_order.tokenId][_editionNumber].bidder = msg.sender;
        bid[_order.tokenId][_editionNumber].timeStamp = block.timestamp;
        emit BidPlaced(_order, msg.sender, _orderNonce, _editionNumber);
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
        uint256 platformCut;

        if (!secondHand[_order.tokenId][_editionNumber]) {
            //add custom platformFee for token by admin and creator, co creator cut for first hand sales -- Done
            if (flexPlatFee[_order.tokenId] > 0) {
                platformCut = bidAmount.mul(flexPlatFee[_order.tokenId]).div(
                    100
                );
            } else {
                platformCut = bidAmount.mul(10).div(100);
            }
            (
                address _creator,
                uint256 _percent1,
                address _coCreator,

            ) = ERC1155Interface.ownerOfToken(_order.tokenId);
            uint256 finalcreatorsCut = bidAmount.sub(platformCut);
            uint256 creatorCut = finalcreatorsCut.mul(_percent1).div(100);
            uint256 coCreatorsCut = finalcreatorsCut.sub(creatorCut);
            // payable(_creator).transfer(creatorCut);
            sendValue(payable(_creator), creatorCut);
            if (coCreatorsCut > 0) {
                // payable(_coCreator).transfer(coCreatorsCut);
                sendValue(payable(_coCreator), coCreatorsCut);
            }
            secondHand[_order.tokenId][_editionNumber] = true;
            // payable(_order.seller).transfer(msg.value.sub(platformCut));
            // admin.transfer(platformCut);
            sendValue(admin, platformCut);
        }
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
        delete bid[_order.tokenId][_editionNumber];
        emit OrderBought(_order, msg.sender, _orderNonce, _editionNumber);
        return true;
    }

    function putOnSaleBuy(
        uint256 _tokenId,
        uint256 _editionNumber,
        uint256 _pricePerNFT
    ) public returns (bool) {
        require(
            secondHand[_tokenId][_editionNumber],
            "Edition is not in second market"
        );
        require(
            currentHolder(_tokenId, _editionNumber) == msg.sender,
            "Not owner of edition"
        );
        // require(_saleType == Type.secondHandBuy, "Incorrect sales type");
        ERC1155Interface.safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId,
            1,
            ""
        );
        secondHandOrder[msg.sender][orderNonce] = _editionNumber;
        holder[_tokenId][_editionNumber] = address(this);
        order[orderNonce] = Order(msg.sender, _tokenId, 1, _pricePerNFT, 2, 0);
        // string memory _tokenURI = ERC1155Interface.TokenURI(_tokenId);
        emit OrderPlaced(
            order[orderNonce],
            block.timestamp,
            // _tokenURI,
            orderNonce
        );
        orderNonce++;
        return true;
    }

    function cancelSaleOrder(uint256 _orderNonce, uint256 _editionNumber)
        external
        returns (bool)
    {
        Order memory _order = order[_orderNonce];
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
            if (bid[_order.tokenId][_editionNumber].bidder != address(0)) {
                sendValue(
                    payable(bid[_order.tokenId][_editionNumber].bidder),
                    bid[_order.tokenId][_editionNumber].bidValue
                );
                delete bid[_order.tokenId][_editionNumber];
            }
        }
        ERC1155Interface.safeTransferFrom(
            address(this),
            msg.sender,
            _order.tokenId,
            1,
            ""
        );
        holder[_order.tokenId][_editionNumber] = msg.sender;
        emit OrderCancelled(_order, block.timestamp, _orderNonce);
        delete secondHandOrder[msg.sender][_orderNonce];
        delete order[_orderNonce];
        return true;
    }

    // function acceptOffer(
    //     uint256 _tokenId,
    //     uint256 _editionNumber,
    //     uint256 _pricePerNFT,
    //     address _buyer
    // ) external returns (bool) {
    //     require(_buyer != address(0), "Zero buyer address");
    //     accept[_tokenId][_editionNumber] = _buyer;
    //     return putOnSaleBuy(_tokenId, _editionNumber, _pricePerNFT);
    // }

    // function cancelFirstHandOrder(uint256 _ordernonce) external returns (bool) {
    //     Order memory _order = order[_orderNonce];
    //     require(
    //         _order.saleType == 0 || _order.saleType == 1,
    //         "Can't cancel second hand orders"
    //     );
    //     (address creator1, , , ) =
    //         ERC1155Interface.ownerOfToken(_order.tokenId);
    //     require(
    //         _order.seller == msg.sender && _order.seller == creator1,
    //         "Can cancel only self orders"
    //     );
    //     require(
    //         block.timestamp > _order.timeline.add(300),
    //         "Can cancel only after 5 mins after sale starts/ends"
    //     );
    //     ERC1155Interface.safeTransferFrom(
    //         address(this),
    //         msg.sender,
    //         _order.tokenId,
    //         _order.amount,
    //         ""
    //     );
    //     delete order[_orderNonce];
    //     return true;
    // }

    // function resetPrice(
    //     uint256 _orderNonce,
    //     uint256 _pricePerNFT,
    //     uint256 _timeline
    // ) external returns (bool) {
    //     Order memory _order = order[_orderNonce];
    //     require(_order.amount > 0, "Zero amount");
    //     require(
    //         _order.saleType == 0 || _order.saleType == 1,
    //         "Only allowed for first hand orders"
    //     );
    //     (address creator1, , , ) =
    //         ERC1155Interface.ownerOfToken(_order.tokenId);
    //     require(
    //         msg.sender == _order.seller && msg.sender == creator1,
    //         "Only owner can change first hand sales"
    //     );
    //     uint256 timeline;
    //     if (_order.saleType == 0) {
    //         require(
    //             block.timestamp > _order.timeline.add(300),
    //             "Can't edit order for at least 5 mins of sale"
    //         );
    //         require(_timeline == 0, "Incorrect time");
    //         timeline = block.timestamp;
    //     }

    //     if (_order.saleType == 1) {
    //         require(
    //             block.timestamp > _order.timeline.add(300),
    //             "Can't edit order for at least 5 mins of sale"
    //         );
    //         require(
    //             _timeline == 12 || _timeline == 24 || _timeline == 48,
    //             // _timeline > block.timestamp.add(5 minutes) &&
    //             //     _timeline <= block.timestamp.add(2 days),
    //             "Incorrect time"
    //         );
    //         timeline = block.timestamp.add(_timeline.mul(60));
    //     }
    //     order[orderNonce] = Order(
    //         _order.seller,
    //         _order.tokenId,
    //         _order.amount,
    //         _pricePerNFT,
    //         _order.saleType,
    //         timeline
    //     );
    //     delete order[_orderNonce];
    // string memory _tokenURI = ERC1155Interface.TokenURI(_order.tokenId); - commented
    //     emit OrderPlaced(
    //         order[orderNonce],
    //         block.timestamp,
    // _tokenURI,
    //         orderNonce
    //     );
    //     orderNonce++;
    //     return true;
    // }

    function requestOffer(
        uint256 _tokenId,
        uint256 _editionNumber,
        uint256 _pricePerNFT
    ) public returns (bool) {
        require(
            secondHand[_tokenId][_editionNumber],
            "Edition is not in second market"
        );
        require(
            currentHolder(_tokenId, _editionNumber) == msg.sender,
            "Not owner of edition"
        );
        ERC1155Interface.safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId,
            1,
            ""
        );
        secondHandOrder[msg.sender][orderNonce] = _editionNumber;
        holder[_tokenId][_editionNumber] = address(this);
        order[orderNonce] = Order(msg.sender, _tokenId, 1, _pricePerNFT, 3, 0);
        emit OrderPlaced(
            order[orderNonce],
            block.timestamp,
            // _tokenURI,
            orderNonce
        );
        orderNonce++;
        return true;
    }

    function acceptOffer(uint256 _orderNonce, uint256 _editionNumber)
        external
        returns (bool)
    {
        Order memory _order = order[_orderNonce];
        require(_order.saleType == 3, "Wrong order type");
        require(_order.seller == msg.sender, "Only owner can accept offers");
        address buyer = bid[_order.tokenId][_editionNumber].bidder;
        require(buyer != address(0), "No bids placed");

        uint256 bidAmount = bid[_order.tokenId][_editionNumber].bidValue;
        uint256 platformCut;

        {
            platformCut = bidAmount.mul(5).div(100);
            // admin.transfer(platformCut);
            sendValue(admin, platformCut);
            (
                address _creator,
                uint256 _percent1,
                address _coCreator,

            ) = ERC1155Interface.ownerOfToken(_order.tokenId);
            uint256 finalcreatorsCut = bidAmount.mul(10).div(100);
            uint256 creatorCut = finalcreatorsCut.mul(_percent1).div(100);
            uint256 coCreatorsCut = finalcreatorsCut.sub(creatorCut);
            // payable(_creator).transfer(creatorCut);
            sendValue(payable(_creator), creatorCut);
            if (coCreatorsCut > 0) {
                // payable(_coCreator).transfer(coCreatorsCut);
                sendValue(payable(_coCreator), coCreatorsCut);
            }
            // admin.transfer(platformCut);
            uint256 finalCut = bidAmount.sub(
                platformCut.add(creatorCut).add(coCreatorsCut)
            );
            // payable(_order.seller).transfer(finalCut);
            sendValue(payable(_order.seller), finalCut);
        }

        ERC1155Interface.safeTransferFrom(
            address(this),
            buyer,
            _order.tokenId,
            1,
            ""
        );
        holder[_order.tokenId][_editionNumber] = buyer;

        emit OrderBought(_order, buyer, _orderNonce, _editionNumber);

        delete order[_orderNonce];
        delete bid[_order.tokenId][_editionNumber];
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
        holder[_tokenId][_editionNumber] = address(0);
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
                bid[_order.tokenId][_editionNumber].timeStamp.add(180), //replace with 86400
            "Please wait 24 hours before claiming back"
        );
        require(
            msg.sender == bid[_order.tokenId][_editionNumber].bidder,
            "Not highest bidder"
        );
        sendValue(
            payable(msg.sender),
            bid[_order.tokenId][_editionNumber].bidValue
        );
        emit BidClaimed(_order, msg.sender, _orderNonce, _editionNumber);
        delete bid[_order.tokenId][_editionNumber];
        return true;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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