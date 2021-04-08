/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

pragma solidity >=0.4.22 <0.7.2;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


library Objects {
    struct Product {
        uint256 price;
        bool delivered;
        bool received;
        uint256 productID;
        address buyer;
        address payable seller;
    }
}

contract MerchantSalesApplication {
    using SafeMath for uint256;

    mapping(uint256 => Objects.Product) public orders;
    uint256 public totalOrders;

    constructor() public payable {
        totalOrders = 0;
    }

    event PurchaseConfirmed(address indexed buyer, address  seller, uint256 indexed productID, uint256 price, uint256 indexed orderID);
    event ProductReceived(address indexed buyer, address  seller, uint256 indexed orderID, uint256 indexed productID);
    event ProductDelivered(address indexed buyer, address  seller, uint256 indexed orderID, uint256 indexed productID);


    function getProductId(uint256 orderID) public view returns (uint256) {
        return orders[orderID].productID;
    }

    function purchase(uint256 productID, address payable seller, uint256 price) public payable {
        require(msg.value == price, "Invalid purchase price");

        orders[totalOrders].price = price;
        orders[totalOrders].delivered = false;
        orders[totalOrders].received = false;
        orders[totalOrders].productID = productID;
        orders[totalOrders].buyer = msg.sender;
        orders[totalOrders].seller = seller;

        totalOrders = totalOrders.add(1);
        emit PurchaseConfirmed(msg.sender, seller, productID, price, totalOrders);
    }

    function confirmReceived(uint256 orderID) public {
        require(msg.sender == orders[orderID].buyer, "Invalid buyer confirmation");
        require(orders[orderID].delivered == true && orders[orderID].received == false, "Already confirmed or not delivered");

        orders[orderID].received = true;
        orders[orderID].seller.transfer(orders[orderID].price);

        emit ProductReceived(orders[orderID].buyer, orders[orderID].seller, orderID, orders[orderID].productID);
    }

    function deliverProduct(uint256 orderID) public {
        require(msg.sender == orders[orderID].seller, "Invalid seller confirmation");
        require(orders[orderID].delivered == false, "Already delivered");

        orders[orderID].delivered = true;
        emit ProductDelivered(orders[orderID].buyer, orders[orderID].seller, orderID, orders[orderID].productID);
    }
}