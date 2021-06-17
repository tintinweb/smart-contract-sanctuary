// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface V1 {
    function ownerOf(uint256 tokenId) external returns (address, address);
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

pragma solidity 0.8.0;

import "./ERC1155.sol";

contract NewStore {
    using SafeMath for uint256;

    address payable public admin;

    enum Type {Instant, Auction}

    struct Order {
        address owner;
        uint256 tokenId;
        // uint256 nonce;
        uint256 amount;
        uint256 startingPrice;
        Type saleType;
        uint256 timeLimit;
    }

    struct Bid {
        Order order;
        address bidder;
        uint256 amount;
    }

    IERC1155 public ERC1155Interface;
    V1 public V1Interface;

    mapping(address => mapping(uint256 => bytes32)) public userOrder;
    mapping(address => mapping(uint256 => Order)) public orderListed;
    mapping(address => mapping(uint256 => bool)) public orderApproved;
    mapping(address => uint256) public userNonce;
    mapping(address => mapping(uint256 => Bid)) public highBid;

    event OrderApproved(Order order, uint256 nonce);
    event OrderPlaced(Order order, uint256 nonce);
    event OrderCancelled(Order order, uint256 nonce);
    event OrderBought(Order order, uint256 nonce, address buyer);
    event BidPlaced(Order order, uint256 nonce, address bidPlacer);

    constructor(address _admin, address _token) {
        require(_token != address(0), "Zero token address");
        ERC1155Interface = IERC1155(_token);
        V1Interface = V1(_token);
        require(_admin != address(0), "Zero admin address");
        admin = payable(_admin);
    }

    modifier onlyAdmin {
        require(msg.sender == admin, "Only Admin");
        _;
    }

    function approveOrder(Order memory _order)
        external
        onlyAdmin
        returns (bool)
    {
        address from = _order.owner;
        // uint256 nonce = _order.nonce;
        // require(nonce > userNonce[from]);
        userNonce[_order.owner]++;
        userOrder[from][userNonce[_order.owner]] = hashOrder(_order);
        orderApproved[from][userNonce[_order.owner]] = true;
        emit OrderApproved(_order, userNonce[_order.owner]);
        return true;
    }

    function hashOrder(Order memory _order) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _order.owner,
                    _order.tokenId,
                    /*_order.nonce, */
                    _order.amount,
                    _order.startingPrice,
                    _order.saleType
                )
            );
    }

    function placeOrder(Order memory _order, uint256 nonce)
        external
        returns (bool)
    {
        require(msg.sender == _order.owner, "Not the owner of order");
        require(
            orderApproved[msg.sender][nonce],
            "Order not approved by admin"
        );
        require(
            userOrder[msg.sender][nonce] == hashOrder(_order),
            "Approved order is edited"
        );
        if (_order.saleType == Type.Auction && msg.sender != admin) {
            require(
                _order.timeLimit > block.timestamp + 5 minutes &&
                    _order.timeLimit < block.timestamp + 2 days,
                "Incorrect Time"
            );
        } else if (_order.saleType == Type.Instant) {
            require(_order.timeLimit == 0, "Incorrect time");
        }
        require(
            ERC1155Interface.balanceOf(msg.sender, _order.tokenId) >=
                _order.amount,
            "Not enough balance"
        );
        ERC1155Interface.safeTransferFrom(
            msg.sender,
            address(this),
            _order.tokenId,
            _order.amount,
            ""
        );
        if (_order.saleType == Type.Auction) {
            highBid[msg.sender][nonce] = Bid(
                _order,
                address(0),
                _order.startingPrice
            );
        }
        orderListed[msg.sender][nonce] = _order;
        emit OrderPlaced(_order, nonce);
        return true;
    }

    // function cancelOrder(uint256 nonce) external returns (bool) {
    //     Order memory _order = orderListed[msg.sender][nonce];
    //     require(
    //         orderApproved[msg.sender][nonce],
    //         "Order not approved by admin"
    //     );
    //     require(msg.sender == _order.owner, "Not the owner");
    //     if (
    //         _order.saleType == Type.Auction &&
    //         highBid[_order.owner][nonce].bidder != address(0)
    //     ) {
    //         payable(highBid[_order.owner][nonce].bidder).transfer(
    //             highBid[_order.owner][nonce].amount
    //         );
    //     }
    //     ERC1155Interface.safeTransferFrom(
    //         address(this),
    //         msg.sender,
    //         _order.tokenId,
    //         _order.amount,
    //         ""
    //     );
    //     emit OrderCancelled(_order, nonce);
    //     delete orderListed[msg.sender][nonce];
    //     return true;
    // }

    // function buyNow(Order memory _order, uint256 nonce)
    //     external
    //     payable
    //     returns (bool)
    // {
    //     require(
    //         orderApproved[_order.owner][nonce],
    //         "Order not approved by admin"
    //     );
    //     require(_order.saleType == Type.Instant);
    //     require(_order.owner != msg.sender, "Owner can't buy");
    //     require(msg.value >= _order.startingPrice, "Wrong price");
    //     (address creator, address coCreator) =
    //         V1Interface.ownerOf(_order.tokenId);

    //     uint256 finalAmount;

    //     if (_order.owner != creator) {
    //         uint256 ownersCut = msg.value.mul(10).div(100);
    //         payable(creator).transfer(ownersCut.div(2));
    //         payable(coCreator).transfer(ownersCut.div(2));
    //         uint256 platformCut = msg.value.mul(5).div(100);
    //         admin.transfer(platformCut);
    //         finalAmount = msg.value.sub(ownersCut).sub(platformCut);
    //         payable(_order.owner).transfer(finalAmount);
    //     } else {
    //         uint256 platformCut = msg.value.mul(10).div(100);
    //         admin.transfer(platformCut);
    //         finalAmount = msg.value.sub(platformCut);
    //         payable(_order.owner).transfer(finalAmount);
    //     }
    //     ERC1155Interface.safeTransferFrom(
    //         address(this),
    //         msg.sender,
    //         _order.tokenId,
    //         _order.amount,
    //         ""
    //     );
    //     emit OrderBought(_order, nonce, msg.sender);
    //     delete orderListed[msg.sender][nonce];
    //     return true;
    // }

    // function placeBid(Order memory _order, uint256 nonce)
    //     external
    //     payable
    //     returns (bool)
    // {
    //     require(
    //         orderApproved[_order.owner][nonce],
    //         "Order not approved by admin"
    //     );
    //     require(_order.saleType == Type.Auction);
    //     require(_order.owner != msg.sender, "Owner can't place bid");
    //     require(
    //         msg.value > highBid[_order.owner][nonce].amount,
    //         "Less than previous bid"
    //     );
    //     require(block.timestamp <= _order.timeLimit, "Auction ended");
    //     // payable(address(this)).transfer(msg.value);
    //     if (highBid[_order.owner][nonce].bidder != address(0)) {
    //         payable(highBid[_order.owner][nonce].bidder).transfer(
    //             highBid[_order.owner][nonce].amount
    //         );
    //     }
    //     highBid[_order.owner][nonce].bidder = msg.sender;
    //     highBid[_order.owner][nonce].amount = msg.value;
    //     emit BidPlaced(_order, nonce, msg.sender);
    //     return true;
    // }

    // function claimAfterAuction(Order memory _order, uint256 nonce)
    //     external
    //     returns (bool)
    // {
    //     require(
    //         orderApproved[_order.owner][nonce],
    //         "Order not approved by admin"
    //     );
    //     require(
    //         block.timestamp > _order.timeLimit,
    //         "Auction is still in progress"
    //     );
    //     require(
    //         highBid[_order.owner][nonce].bidder == msg.sender,
    //         "Not the highest bidder"
    //     );
    //     uint256 value = highBid[_order.owner][nonce].amount;
    //     (address creator, address coCreator) =
    //         V1Interface.ownerOf(_order.tokenId);

    //     uint256 finalAmount;

    //     if (_order.owner != creator) {
    //         uint256 ownersCut = value.mul(10).div(100);
    //         payable(creator).transfer(ownersCut.div(2));
    //         payable(coCreator).transfer(ownersCut.div(2));
    //         uint256 platformCut = value.mul(5).div(100);
    //         admin.transfer(platformCut);
    //         finalAmount = value.sub(ownersCut).sub(platformCut);
    //         payable(_order.owner).transfer(finalAmount);
    //     } else {
    //         uint256 platformCut = value.mul(10).div(100);
    //         admin.transfer(platformCut);
    //         finalAmount = value.sub(platformCut);
    //         payable(_order.owner).transfer(finalAmount);
    //     }
    //     ERC1155Interface.safeTransferFrom(
    //         address(this),
    //         msg.sender,
    //         _order.tokenId,
    //         _order.amount,
    //         ""
    //     );
    //     emit OrderBought(_order, nonce, msg.sender);
    //     delete orderListed[_order.owner][nonce];
    //     return true;
    // }

    // function onERC1155Received(
    //     address operator,
    //     address from,
    //     uint256 id,
    //     uint256 value,
    //     bytes calldata data
    // ) external returns (bytes4) {
    //     return (
    //         bytes4(
    //             keccak256(
    //                 "onERC1155Received(address,address,uint256,uint256,bytes)"
    //             )
    //         )
    //     );
    // }
}