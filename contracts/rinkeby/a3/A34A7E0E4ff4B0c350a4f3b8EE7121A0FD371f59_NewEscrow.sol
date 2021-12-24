// SPDX-License-Identifier: MIT

/**

                                      ....                                      
                          .                           .                         
                                                                                
                                                                                
                                                                                
           .                                                         .          
                                                                       .        
                                                                         .      
                                                                                
    .                       ((((((///////////*****                              
                            ((((((///////////*****                           .  
  .                         ((((((///////////*****                              
                                              *********                         
                                              *********                         
                                              *********                         
                          ((((((((////////////*********                         
.                      /((((((((((///////////**********                         
.                     (((((((((((.       .*//**********                         
                     .(((((((((               *********                         
                     ,(((((((((             ***********                         
                      ((((((((((((/**////////**********                         
 /*                    (((((((((((///////////**********                         
   .                     (((((((((//////////* **********,,.                     
                             .(((((////*        .*****,                         
                                                                                
       .                                                                        
                                                                       .        
           .                                                                    
                                                                                
                                                               .                
                                                           .                    
                                                                                


 */


pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

abstract contract ERC165Escrow is IERC165 {
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
interface IERC1155Escrow is IERC165 {
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
        uint256 _tokenId,
        uint256 amount
    ) external returns (bool);
}

contract NewEscrow is ERC165Escrow {
    using SafeMath for uint256;

    address payable public admin;
    uint256 public orderNonce;
    address public tokenAddress;
    IERC1155Escrow public ERC1155Interface;
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
        ERC1155Interface = IERC1155Escrow(_tokenAddress);
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
            _timeline = block.timestamp.add(_timeline.mul(30)); //Change 30 to 1 for unit testing and 3600 for production
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
            msg.value > _order.pricePerNFT, "Wrong Price"
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
            currentHolder(_tokenId, _editionNumber) == msg.sender,
            "Not owner"
        );
        ERC1155Interface.burn(_tokenId, 1);
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
                bid[_order.tokenId][_editionNumber].timeStamp.add(180),
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

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
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
    ) external returns (bytes4);

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
    ) external returns (bytes4);
}