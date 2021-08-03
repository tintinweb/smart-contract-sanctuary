/**
 *Submitted for verification at BscScan.com on 2021-08-03
*/

// SPDX-License-Identifier: No License (None)

pragma solidity ^0.8.0;
// pragma experimental ABIEncoderV2;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface IDepository {
    function deposit() external payable returns(uint256);
    function withdraw(uint256 depositId) external returns(uint256);
}

contract ProtectedMarketplace {
    IDepository public depository;

    enum OrderType { FixedPay, AuctionType }
    enum OrderStatus { Active, Bidded, UnderDownsideProtectionPhase, Completed, Cancelled }
    enum BidStatus { NotAccepted, Pending, Refunded, Executed }

    struct Order {
        OrderStatus statusOrder;
        OrderType typeOrder;
        address tokenAddress;
        uint256 nftTokenId;
        address payable sellerAddress;
        address payable buyerAddress;
        uint256 tokenPrice; // In fix sale - token price. Auction: start price or max offer price
        // protection
        uint256 protectionAmount;
        uint256 depositId;
        uint64 protectionRate;
        uint256 protectionTime;
        //uint256 protectionExpiryTime = soldTime + protectionTime
        uint256 soldTime; // time when order sold, if equal to 0 than order unsold (so no need to use additional variable "bool saleNFT")
        //suborder
        uint256 offerClosingTime;
        uint256[] subOrderList;
    }

    struct SubOrder {
        //uint256 subOrderId;
        uint256 orderId; //original order ID
        address payable buyerAddress;
        uint256 tokenPrice;
        uint64 protectionRate;
        uint256 protectionTime;
        uint256 validUntil;
    }

    address payable public company;     // company address
    uint256 public companyFeeRate;       // company fee rate in percent (current rate 2%)

    uint256 public orderIdCount;
    uint256 public subOrderIdCount;

    mapping(uint256 => Order) public orders;                     // identify offers by offerID
    mapping(uint256 => SubOrder) public subOrders;                     // identify offers by offerID
    mapping (address => mapping(uint256 => BidStatus)) public buyerBidStatus;       // To check a buyer's bid status(can be used in frontend)                                  

    event CreateOrder(uint256 orderID, OrderType typeOrder, address indexed tokenAddress, uint256 nftTokenId, uint256 tokenPrice, uint64 protectionRate, uint256 protectionTime);
    event BuyOrder(uint256 orderID, OrderType typeOrder, address indexed buyerAddress, uint256 protectionAmount, uint256 protectionExpiryTime);
    event ClaimDownsideProtection(uint256 orderID,  OrderType typeOrder, address indexed buyerOrSeller, uint256 claimAmount);
    event CreateSubOrder(uint256 orderID, OrderType typeOrder, address indexed buyerAddress, uint256 tokenPrice, uint64 protectionRate, uint256 validUntil);
    event CreateBid(uint256 orderID, OrderType typeOrder, address indexed buyerAddress, uint256 bidAmount);
    event CompanyChanged(address indexed oldCompany, address indexed newCompany);
    event CompanyFeeRateChanged(uint256 oldRate, uint256 newRate);
    event CancelOrder(uint256 orderID);

    // Initialize a valid company and a non zero fee rate
    //constructor (address payable _company, uint256 _companyFeeRate, address payable _depository) public {
    function initialize (address payable _company, uint256 _companyFeeRate, address payable _depository) public {
        require(company == address(0), "Already initialized");
        require(_company != address(0) && _companyFeeRate > 0 && _companyFeeRate < 10000, "Invalid company and details");
        require(_depository != address(0), "Invalid depository");
        company = _company;
        companyFeeRate = _companyFeeRate;
        depository = IDepository(_depository);
    }

    // To receive BNB from depository
    receive() external payable {}

    modifier createOrderValidator(
        address _tokenAddress,
        uint256 _nftTokenId,
        uint256 _tokenPrice,
        bool _acceptOffers,
        uint256 _offerClosingTime
    )
    {
        require(IERC721(_tokenAddress).ownerOf(_nftTokenId) == msg.sender, "Invalid token owner");
        require(_tokenPrice > 0, "Invalid token price");
        if(_acceptOffers){
            require(_offerClosingTime > 0, "AuctionType orders need a closing time");
        }
        _;
    }

    modifier createSubOrderValidator(uint256 _orderId) {
        Order storage order = orders[_orderId];
        require(order.statusOrder == OrderStatus.Active, "Invalid OrderStatus");   
        require(order.typeOrder == OrderType.FixedPay, "Invalid OrderType");   // AuctionType orders are directly executed by seller
        require(order.sellerAddress == msg.sender, "Invalid Authentication");  
        _;
    }

    modifier buyFixedPayOrderValidator(uint256 _orderId) {
        Order storage order = orders[_orderId];
        require(order.statusOrder == OrderStatus.Active, "Invalid OrderStatus");   
        require(order.typeOrder == OrderType.FixedPay, "Invalid OrderType");   // AuctionType orders are directly executed by seller
        _;
    }

    modifier onlySeller(uint256 _orderId) {
        Order storage order = orders[_orderId];
        require(msg.sender == order.sellerAddress, "Invalid Authentication");
        _;
    }

    modifier onlySellerBuyer(uint256 _orderId) {
        Order storage order = orders[_orderId];
        require(msg.sender == order.sellerAddress || msg.sender == order.buyerAddress, "Invalid Authentication");
        _;
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function createOrder(
        address _tokenAddress,
        uint256 _nftTokenId,
        uint256 _tokenPrice,
        uint64 _protectionRate,
        uint256 _protectionTime,
        bool _acceptOffers,
        uint256 _offerClosingTime
    )
    external
    createOrderValidator(_tokenAddress, _nftTokenId, _tokenPrice, _acceptOffers, _offerClosingTime)
    {
        require(_protectionRate <= 10000 , "ProtectedMarketplace::createOrder: Protection rate above 100 percent");
        IERC721(_tokenAddress).safeTransferFrom(msg.sender, address(this), _nftTokenId);

        orderIdCount++;
        Order storage order = orders[orderIdCount];

        // Update the Order
        order.statusOrder = OrderStatus.Active;
        order.tokenAddress = _tokenAddress;
        order.nftTokenId = _nftTokenId;
        order.sellerAddress = payable(msg.sender);
        order.buyerAddress = payable(address(0));
        order.tokenPrice = _tokenPrice;
        order.protectionRate = _protectionRate;
        order.protectionTime = _protectionTime;
        order.typeOrder = _acceptOffers ? OrderType.AuctionType : OrderType.FixedPay;
        order.offerClosingTime = _acceptOffers ? _offerClosingTime : 0;
        
        emit CreateOrder(orderIdCount, order.typeOrder, _tokenAddress, _nftTokenId, _tokenPrice, _protectionRate, order.protectionTime);
    }

    function createSubOrder(
        uint256 _orderId, //original order ID
        address payable _buyerAddress,
        uint256 _tokenPrice,
        uint64 _protectionRate,
        uint256 _protectionTime,
        uint256 _validUntil
    )
    external
    createSubOrderValidator(_orderId) onlySeller(_orderId)
    {   
        require(_protectionRate <= 10000, "Protection rate above 100 percent");
        Order storage order = orders[_orderId];

        subOrderIdCount++;
        SubOrder memory subOrder;
        //subOrder.subOrderId = subOrderIdCount;
        subOrder.orderId = _orderId;
        subOrder.buyerAddress = _buyerAddress;
        subOrder.tokenPrice = _tokenPrice;
        subOrder.protectionRate = _protectionRate;
        subOrder.protectionTime = _protectionTime;
        subOrder.validUntil = _validUntil;

        orders[_orderId].subOrderList.push(subOrderIdCount);
        subOrders[subOrderIdCount] = subOrder;

        emit CreateSubOrder(_orderId, order.typeOrder, subOrder.buyerAddress, subOrder.tokenPrice, subOrder.protectionRate, subOrder.validUntil);
    }

    function buySubOrder(uint256 _orderId, uint256 _subOrderId) external payable {   
        Order storage order = orders[_orderId];
        SubOrder storage subOrder = subOrders[_subOrderId];

        require(_orderId == subOrder.orderId, "Invalid SubOrder");
        require(msg.sender == subOrder.buyerAddress, "Invalid Authentication");
        require(msg.value == subOrder.tokenPrice, "Insufficient token price");
        require(block.timestamp <= subOrder.validUntil, "SubOrder offer Expired");
        require(order.statusOrder == OrderStatus.Active, "Invalid OrderStatus");

        order.protectionRate = subOrder.protectionRate;
        order.protectionTime = subOrder.protectionTime;
        order.buyerAddress = payable(msg.sender);

        _proceedPayments(_orderId, subOrder.tokenPrice, subOrder.protectionRate, payable(msg.sender));
        emit BuyOrder(_orderId, order.typeOrder, order.buyerAddress, order.protectionAmount, order.soldTime + order.protectionTime);
    }

    function buyFixedPayOrder(uint256 _orderId) external payable buyFixedPayOrderValidator(_orderId) {
        Order storage order = orders[_orderId];
        require(msg.value == order.tokenPrice, "token price");
        require(order.statusOrder == OrderStatus.Active, "Invalid OrderStatus");

        _proceedPayments(_orderId, order.tokenPrice, order.protectionRate, payable(msg.sender));
        order.buyerAddress = payable(msg.sender);

        emit BuyOrder(_orderId, order.typeOrder, order.buyerAddress, order.protectionAmount, order.soldTime + order.protectionTime);
    }

    function cancelOrder(uint256 _orderId) external onlySeller(_orderId) {
        Order storage order = orders[_orderId];
        require(order.statusOrder == OrderStatus.Active, "Invalid OrderStatus");

        IERC721(order.tokenAddress).safeTransferFrom(address(this), order.sellerAddress, order.nftTokenId);     // Transfer the NFT
        order.statusOrder == OrderStatus.Cancelled;        

        emit CancelOrder(_orderId);
    }

    function claimDownsideProtectionAmount(uint256 _orderId) external onlySellerBuyer(_orderId) {        //Although receiver not a contract, adding reentrant guard for extra protection
        Order storage order = orders[_orderId];
        require(order.statusOrder == OrderStatus.UnderDownsideProtectionPhase, "Invalid OrderStatus");   

        // Fetch the token amount worth the face value of protection amount
        if(msg.sender == order.sellerAddress && sellerCheckClaimDownsideProtectionAmount(_orderId)  && order.soldTime !=0){
            order.statusOrder = OrderStatus.Completed;
            uint256 value = depository.withdraw(order.depositId);      // Withdraw from depository
            order.sellerAddress.transfer(value);   // Transfer to Seller the whole Yield Amount

            emit ClaimDownsideProtection(_orderId, order.typeOrder, order.sellerAddress, value);

        } else if(msg.sender == order.buyerAddress && buyerCheckClaimDownsideProtectionAmount(_orderId) && order.soldTime !=0){
            order.statusOrder = OrderStatus.Completed;
            uint256 value = depository.withdraw(order.depositId);      // Withdraw from depository
            IERC721(order.tokenAddress).safeTransferFrom(msg.sender, order.sellerAddress, order.nftTokenId);     // Send NFT back to seller

            order.buyerAddress.transfer(order.protectionAmount);    // Transfer to Buyer only his protection amount
            order.sellerAddress.transfer(value - order.protectionAmount);   // Transfer to Seller the Yield reward
            
            emit ClaimDownsideProtection(_orderId, order.typeOrder, order.buyerAddress, order.protectionAmount);
        }
    }

    function sellerCheckClaimDownsideProtectionAmount(uint256 _orderId) view public returns (bool) {
        Order storage order = orders[_orderId];
        address nftOwner = IERC721(order.tokenAddress).ownerOf(order.nftTokenId);

        if(nftOwner != order.buyerAddress && !isContract(nftOwner)){       // tokenOwnership changed
            return true;
        }
        
        if(block.timestamp > order.soldTime + order.protectionTime){     // protectionTime surpasses
            return true;
        }
        return false;
    }

    function buyerCheckClaimDownsideProtectionAmount(uint256 _orderId) view public returns (bool) {
        Order storage order = orders[_orderId];
        address nftOwner = IERC721(order.tokenAddress).ownerOf(order.nftTokenId);

        if(nftOwner == order.buyerAddress && block.timestamp <= order.soldTime + order.protectionTime){       // tokenOwnership & protectionTime DONT surpasses
            return true;
        }
        return false;
    }

    function createBid(uint256 _orderId) external payable {
        Order storage order = orders[_orderId];
        uint256 previousMaxOfferAmount = order.tokenPrice;
        require(msg.value > previousMaxOfferAmount, "Investment too low");
        require(order.statusOrder == OrderStatus.Active || order.statusOrder == OrderStatus.Bidded, "Invalid OrderType");
        require(order.typeOrder == OrderType.AuctionType, "Invalid OrderType");
        require(order.offerClosingTime >= block.timestamp, "Bidding beyond Closing Time");

        address payable previousBuyer =  order.buyerAddress;

        // Update the new bidder details
        order.tokenPrice = msg.value;   // maxOfferAmount
        order.buyerAddress = payable(msg.sender);
        buyerBidStatus[msg.sender][_orderId] = BidStatus.Pending;
        order.statusOrder = OrderStatus.Bidded;

        // Return the funds to the previous bidder
        if (previousBuyer != address(0)) {
            buyerBidStatus[previousBuyer][_orderId] = BidStatus.Refunded; 
            previousBuyer.transfer(previousMaxOfferAmount);
        }
        emit CreateBid(_orderId, order.typeOrder, msg.sender, msg.value);
    }

    function executeBid(uint256 _orderId) external {
        Order storage order = orders[_orderId];

        require(order.statusOrder == OrderStatus.Bidded, "Invalid OrderType");
        require(order.typeOrder == OrderType.AuctionType, "Invalid OrderType");
        require(order.offerClosingTime <= block.timestamp, "Executing Bid before Closing Time");

        _proceedPayments(_orderId, order.tokenPrice, order.protectionRate, order.buyerAddress);
        buyerBidStatus[order.buyerAddress][_orderId] = BidStatus.Executed;

        emit BuyOrder(_orderId, order.typeOrder, order.buyerAddress, order.protectionAmount, order.soldTime + order.protectionTime);
    }

    function _proceedPayments(uint256 _orderId, uint256 _price, uint256 _protectionRate, address payable buyerAddress) internal {
        Order storage order = orders[_orderId];
        order.statusOrder == OrderStatus.UnderDownsideProtectionPhase;

        uint256 companyShare = _price * companyFeeRate / 10000;
        company.transfer(companyShare);                        // Transfer the company fees
        
        uint256 netAmount = _price - companyShare;
        uint256 downsideAmount = netAmount * _protectionRate / 10000;    // downsideAmount comes after companyShare
        order.sellerAddress.transfer(netAmount - downsideAmount);        // Transfer the seller his amount

        uint256 depositId = depository.deposit{value: downsideAmount}();     // Invest the downside in Venus

        IERC721(order.tokenAddress).safeTransferFrom(address(this), buyerAddress, order.nftTokenId);     // Transfer the NFT
        order.protectionAmount = downsideAmount;
        order.depositId = depositId;
        order.soldTime = block.timestamp;
        //order.protectionExpiryTime = order.soldTime + order.protectionTime;
    }

    function setNewCompany(address payable _newCompany) external {
        require(msg.sender == company, "Invalid Authentication");
        require(_newCompany != address(0));
        address oldCompany = company;
        company = _newCompany;

        emit CompanyChanged(oldCompany, _newCompany);
    }

    function setCompanyFeeRate(uint256 _newRate) external {
        require(msg.sender == company, "Invalid Authentication");
        require(_newRate > 0 && _newRate < 10000, "Rate exceeding 100 percent");
        uint256 oldRate = companyFeeRate;
        companyFeeRate = _newRate;

        emit CompanyFeeRateChanged(oldRate, _newRate);
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}