/**
 *Submitted for verification at Etherscan.io on 2021-02-17
*/

pragma solidity 0.6.0;

interface IERC721 {
    function burn(uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function mint( address _to, uint256 _tokenId, string calldata _uri, string calldata _payload) external;
    function ownerOf(uint256 _tokenId) external returns (address _owner);
    function getApproved(uint256 _tokenId) external returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
}

contract Swap {
    
    struct Order {
        uint tokenId;
        address nftAddress;
        address buyer;
        address payable seller;
        uint256 price;
    }
    address public owner;
    address payable benefactor;
   
    uint public orderFee;
    uint orderCount;

    mapping(uint => Order) public pendingOrders;
    mapping(uint => Order) public completedOrders;
    mapping(uint => Order) public cancelledOrders;
    
    event OrderAdded(uint orderNumber, uint tokenId,  address nftAddress,  address buyer,address seller, uint256 price);
    event OrderCanceled(uint orderNumber);
    event OrderPurchased(uint orderNumber, uint tokenId,  address nftAddress,  address buyer,address seller, uint256 price, uint orderFee);

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor(uint fee) public {
        orderFee = fee;
        benefactor = msg.sender;
        owner = msg.sender;

    }
    
    function changeFee(uint fee) isOwner() public {
        orderFee = fee;
    }
    
    function changeBenefactor(address payable newBenefactor) isOwner() public {
        benefactor = newBenefactor;
    }
    
    function purchaseOrder(uint orderNumber) public payable {
        Order memory order = pendingOrders[orderNumber];
        require(order.price == msg.value, 'Not enough payment included');
        
        require(IERC721(order.nftAddress).getApproved(order.tokenId) == address(this), 'Needs to be approved');
        IERC721(order.nftAddress).safeTransferFrom(order.seller, msg.sender, order.tokenId);
        order.seller.transfer(order.price - orderFee); 
        benefactor.transfer(orderFee);
        
        order.buyer = msg.sender;
        completedOrders[orderNumber] = order;
        delete pendingOrders[orderNumber];
        
        emit OrderPurchased(orderNumber, order.tokenId, order.nftAddress, order.buyer, order.seller, order.price, orderFee);
    }
    
    function cancelOrder(uint orderNumber) public {
        Order memory order = pendingOrders[orderNumber];
        require(order.seller == msg.sender, 'Only order placer can cancel');
        cancelledOrders[orderNumber] = order;
        delete pendingOrders[orderNumber];
        
        emit OrderCanceled(orderNumber);
    }
    
    function addOrder(address nftAddress, uint tokenId, uint256 price) public {
        require(IERC721(nftAddress).getApproved(tokenId) == address(this), 'Needs to be approved');
        orderCount +=1;
        pendingOrders[orderCount] = Order(tokenId, nftAddress, address(this), msg.sender, price);
        emit OrderAdded(orderCount, tokenId, nftAddress, address(this), msg.sender, price);
    }
  
    
}