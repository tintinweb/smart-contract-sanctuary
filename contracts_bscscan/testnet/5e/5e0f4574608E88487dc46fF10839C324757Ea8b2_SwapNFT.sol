pragma solidity ^0.6.8;

// pragma experimental ABIEncoderV2;

interface IERC721 {
    function burn(uint256 tokenId) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function mint(
        address _to,
        uint256 _tokenId,
        string calldata _uri,
        string calldata _payload
    ) external;

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool);

    function ownerOf(uint256 _tokenId) external returns (address _owner);

    function getApproved(uint256 _tokenId) external returns (address);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;
}

contract SwapNFT {
    struct Order {
        uint256 tokenId;
        address nftAddress;
        address buyer;
        address payable seller;
        uint256 price;
        uint256 fee;
        uint256 royalityPercent;
        address payable royalityAddress;
    }
    address public owner;
    uint256 public orderFee;
    address payable benefactor;
    
    mapping(uint256 => Order) public pendingOrders;
    mapping(uint256 => Order) public completedOrders;
    mapping(uint256 => Order) public cancelledOrders;
    
    event AddOrder(uint256 _orderNumber, uint256 _tokenId, address _nftAddress, address _seller, uint256 _price, uint256 _fee, address _royalityAddress, uint256 _royalityPercent);
    event CancelOrder(uint256 _orderNumber,  address _seller);
    event PurchaseOrder(uint256 _orderNumber, uint256 _tokenId, address _nftAddress, address _seller, address _buyer, uint256 _price,  uint256 _fee,  address _royalityAddress, uint256 _royalityAmount);
    
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor() public { //uint256 fee
        // require(fee <= 10000);

        // orderFee = fee;
        benefactor = msg.sender;
        owner = msg.sender;
    }

    function _computeFee(uint256 _price) public view returns (uint256) {
        return (_price * orderFee) / 10000;
    }

    function computeRoyality(uint256 _price, uint256 _royality)
        public
        pure
        returns (uint256)
    {
        return (_price * _royality) / 10000;
    }

    function changeFee(uint256 fee) public isOwner() {
        require(fee <= 10000);
        orderFee = fee;
    }

    function changeBenefactor(address payable newBenefactor) public isOwner() {
        benefactor = newBenefactor;
    }

    function purchaseOrder(uint256 orderNumber) public payable {
        Order memory order = pendingOrders[orderNumber];
        require(msg.value == order.price, "Not enough payment included");
      
        require(
            IERC721(order.nftAddress).isApprovedForAll(
                order.seller,
                address(this)
            ) == true,
            "Needs to be approved"
        );
        IERC721(order.nftAddress).safeTransferFrom(
            order.seller,
            msg.sender,
            order.tokenId
        );
        uint256 _fee = _computeFee(order.price);
        uint256 _royality = computeRoyality(order.price, order.royalityPercent);

        order.seller.transfer(order.price - (_fee + _royality));
        benefactor.transfer(_fee);
        order.royalityAddress.transfer(_royality);

        order.buyer = msg.sender;
        order.fee = _fee;
        completedOrders[orderNumber] = order;
        delete pendingOrders[orderNumber];
        
        emit PurchaseOrder(orderNumber,  order.tokenId, order.nftAddress,  order.seller, order.buyer, order.price, order.fee,  order.royalityAddress,_royality );
    }

    function cancelOrder(uint256 orderNumber) public {
        Order memory order = pendingOrders[orderNumber];
        require(order.seller == msg.sender, "Only order placer can cancel");
        cancelledOrders[orderNumber] = order;
        delete pendingOrders[orderNumber];
        emit CancelOrder(orderNumber, msg.sender);
    }

    // Client side, should first call [NFTADDRESS].approve(Swap.sol.address, tokenId)
    // in order to authorize this contract to transfer nft to buyer
    function addOrder(
        address nftAddress,
        uint256 tokenId,
        uint256 price,
        uint256 orderNumber,
        uint256 royalityPercent,
        address payable royalityAddress
    ) public {
        require(
            IERC721(nftAddress).isApprovedForAll(msg.sender, address(this)) ==
                true,
            "Needs to be approved"
        );
        pendingOrders[orderNumber] = Order(
            tokenId,
            nftAddress,
            address(this),
            msg.sender,
            price,
            0,
            royalityPercent,
            royalityAddress
        );
        emit AddOrder(orderNumber,  tokenId, nftAddress,  msg.sender, price, 0,  royalityAddress, royalityPercent );

    }

    // Client side, should first call [NFTADDRESS].approve(Swap.sol.address, tokenId)
    // in order to authorize this contract to transfer nft to buyer
    function addMultiOrder(
        address nftAddress,
        uint256[] memory tokenId,
        uint256 price,
        uint256[] memory orderNumber,
        uint256 royalityPercent,
        address payable royalityAddress
    ) public {
        require(
            IERC721(nftAddress).isApprovedForAll(msg.sender, address(this)) ==
                true,
            "Needs to be approved"
        );

        for (uint256 i = 0; i < tokenId.length; i++) {
            pendingOrders[orderNumber[i]].tokenId = tokenId[i];
            pendingOrders[orderNumber[i]].nftAddress = nftAddress;
            pendingOrders[orderNumber[i]].buyer = address(this);
            pendingOrders[orderNumber[i]].seller = msg.sender;
            pendingOrders[orderNumber[i]].price = price;
            pendingOrders[orderNumber[i]].royalityPercent = royalityPercent;
            pendingOrders[orderNumber[i]].royalityAddress = royalityAddress;
            emit AddOrder(orderNumber[i],  tokenId[i], nftAddress,  msg.sender, price, 0,  royalityAddress, royalityPercent );

        }
        
    }
}