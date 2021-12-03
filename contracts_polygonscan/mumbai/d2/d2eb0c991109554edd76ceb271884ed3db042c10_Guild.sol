/**
 *Submitted for verification at polygonscan.com on 2021-12-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

interface IShopFactory {
    function createShop(
        address owner,
        string memory _shopName,
        string memory _detailsCId
    ) external;

    function getLatestShopAddress() external view returns (address);
}

interface IShop {
    struct Product {
        uint256 productId;
        string contentCId;
        string detailsCId;
        string licenseHash;
        string lockedLicense;
        uint256 price;
        uint256 stock;
        uint256 ratingsCount;
        uint256 ratingsSum; // [0] = number of ratings, [1] = sum of ratings
        uint256 salesCount;
        bool isAvailable;
    }

    struct Sale {
        uint256 saleId;
        address buyer;
        string publicKey;
        uint256 productId;
        uint256 amount;
        uint256 saleDeadline;
        bytes32 unlockedLicense0;
        bytes32 unlockedLicense1;
        uint256 rating;
        SaleStatus status;
    }

    struct ShopInfo {
        address guild;
        address owner;
        uint256 shopBalance;
        string detailsCId;
        string shopName;
        uint256 productsCount;
        uint256 salesCount;
    }
    enum SaleStatus {
        Requested,
        Refunded,
        Completed,
        Rated
    }

    function getOwner() external view returns (address);

    function getSalesCount() external view returns (uint256);

    function getSale(uint256 _saleId) external view returns (Sale memory);

    function getProduct(uint256 _productId)
        external
        view
        returns (Product memory);

    function getShopInfo() external view returns (ShopInfo memory);

    function getOpenSaleIds() external view returns (uint256[] memory);

    function getClosedSaleIds() external view returns (uint256[] memory);

    function addProduct(
        string memory _contentCId,
        string memory _detailsCId,
        string memory _licenseHash,
        string memory _lockedLicense,
        uint256 _price,
        uint256 _stock
    ) external;

    function requestSale(
        address _buyer,
        uint256 _productId,
        string memory _publicKey
    ) external payable;

    function getRefund(uint256 _saleId) external payable;

    function closeSale(uint256 _saleId, bytes32[2] memory _unlockedLicense)
        external;

    function addRating(uint256 _saleId, uint256 _rating) external;

    function shelfProduct(uint256 _productId) external;

    function changePrice(uint256 _productId, uint256 _price) external;

    function changeStock(uint256 _productId, uint256 _stock) external;

    function withdraw(uint256 _amount) external payable;
}

interface IUnlockOracleClient {
    function addRequest(string memory _lockedLicense, string memory _publicKey)
        external;

    function requestsCount() external view returns (uint256);
}

contract Guild {
    struct UnlockRequest {
        uint256 requestId;
        uint256 shopId;
        uint256 saleId;
    }

    address owner;
    address oracleClient;
    address public shopFactory;
    address[] public shops;
    uint256 ratingReward = 0.001 ether;
    uint256 serviceTax = 0.2 ether;
    uint256 constant MAX_UINT = 2**256 - 1;
    IShopFactory FactoryInterface;

    mapping(uint256 => UnlockRequest) unlockRequests;
    uint256[] pendingRequests;
    mapping(uint256 => uint256) public requestIdToRequestIndex;

    // get shopId before making any function calls
    mapping(string => uint256) public shopNameToShopId;
    mapping(string => bool) public isShopNameTaken;

    mapping(address => uint256) buyerCredits;
    // list of buyers with credits..
    // ..close credits periodically

    // Events, indexed can be decided based on UI functionality choice
    event IShopCreated(string indexed shopName, string detailsCId);
    event RequestedSale(uint256 shopId, uint256 productId, uint256 saleId);
    event Refunded(uint256 shopId, uint256 saleId);
    event PriceChanged(uint256 shopId, uint256 productId, uint256 newPrice);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call the function!");
        _;
    }

    modifier onlyShopOwner(uint256 _shopId) {
        require(
            msg.sender == IShop(shops[_shopId]).getOwner(),
            "only shop owner can call the function!"
        );
        _;
    }

    modifier onlyBuyer(uint256 _shopId, uint256 _saleId) {
        IShop.Sale memory sale = IShop(shops[_shopId]).getSale(_saleId);
        require(msg.sender == sale.buyer, "Only buyer can call the function!");
        _;
    }

    modifier onlyOracleClient() {
        require(
            msg.sender == oracleClient,
            "Only oracle client can call the function!"
        );
        _;
    }

    constructor(address _oracleClient, address _shopFactory) {
        owner = msg.sender;
        oracleClient = _oracleClient;
        shopFactory = _shopFactory;
        FactoryInterface = IShopFactory(shopFactory);
    }

    function changeOracle(address _oracle) external onlyOwner {
        oracleClient = _oracle;
    }

    function createShop(string memory _shopName, string memory _detailsCId)
        external
    {
        require(!isShopNameTaken[_shopName], "Shop name already taken");

        FactoryInterface.createShop(msg.sender, _shopName, _detailsCId);

        shops.push(FactoryInterface.getLatestShopAddress());
        shopNameToShopId[_shopName] = shops.length - 1;
        isShopNameTaken[_shopName] = true;
        emit IShopCreated(_shopName, _detailsCId);
    }

    function addProduct(
        uint256 _shopId,
        string memory _contentCId,
        string memory _detailsCId,
        string memory _licenseHash,
        string memory _lockedLicense,
        uint256 _price,
        uint256 _stock
    ) external onlyShopOwner(_shopId) {
        IShop(shops[_shopId]).addProduct(
            _contentCId,
            _detailsCId,
            _licenseHash,
            _lockedLicense,
            _price,
            _stock == 0 ? MAX_UINT : _stock // if stock is given, use it else use max uint.
        );
    }

    function requestSale(
        uint256 _shopId,
        uint256 _productId,
        string memory _publicKey,
        uint256 _redeemCredits
    ) external payable {
        require(msg.sender != IShop(shops[_shopId]).getOwner());

        require(buyerCredits[msg.sender] >= _redeemCredits);
        buyerCredits[msg.sender] -= _redeemCredits;

        IShop(shops[_shopId]).requestSale{
            value: msg.value + _redeemCredits - ratingReward - serviceTax
        }(msg.sender, _productId, _publicKey);

        IShop.Sale memory sale = IShop(shops[_shopId]).getSale(
            IShop(shops[_shopId]).getSalesCount() - 1
        );

        IShop.Product memory product = IShop(shops[_shopId]).getProduct(
            _productId
        );

        IUnlockOracleClient(oracleClient).addRequest(
            product.lockedLicense,
            _publicKey
        );

        uint256 unlockRequestId = IUnlockOracleClient(oracleClient)
            .requestsCount() - 1;

        unlockRequests[unlockRequestId] = UnlockRequest({
            requestId: unlockRequestId,
            shopId: _shopId,
            saleId: sale.saleId
        });

        pendingRequests.push(unlockRequestId);
        requestIdToRequestIndex[unlockRequestId] = pendingRequests.length - 1;

        emit RequestedSale(_shopId, _productId, sale.saleId);
    }

    function getRefund(uint256 _shopId, uint256 _saleId)
        external
        payable
        onlyBuyer(_shopId, _saleId)
    {
        // increment buyerCredit of the buyer with the rating reward
        buyerCredits[msg.sender] += ratingReward;

        IShop(shops[_shopId]).getRefund(_saleId);

        emit Refunded(_shopId, _saleId);
    }

    function addRating(
        uint256 _shopId,
        uint256 _saleId,
        uint256 _rating
    ) public onlyBuyer(_shopId, _saleId) {
        IShop(shops[_shopId]).addRating(_saleId, _rating);
        buyerCredits[msg.sender] += ratingReward;
    }

    function shelfProduct(uint256 _shopId, uint256 _productId)
        external
        onlyShopOwner(_shopId)
    {
        IShop(shops[_shopId]).shelfProduct(_productId);
    }

    function changePrice(
        uint256 _shopId,
        uint256 _productId,
        uint256 _price
    ) external onlyShopOwner(_shopId) {
        IShop(shops[_shopId]).changePrice(_productId, _price);
        emit PriceChanged(_shopId, _productId, _price);
    }

    function changeStock(
        uint256 _shopId,
        uint256 _productId,
        uint256 _stock
    ) external onlyShopOwner(_shopId) {
        IShop(shops[_shopId]).changeStock(_productId, _stock);
    }

    function withdrawFromShop(uint256 _shopId, uint256 _amount)
        external
        payable
        onlyShopOwner(_shopId)
    {
        IShop(shops[_shopId]).withdraw(_amount);
    }

    function completeUnlock(
        uint256 _requestId,
        bytes32[2] memory _unlockedLicense
    ) external onlyOracleClient {
        IShop(shops[unlockRequests[_requestId].shopId]).closeSale(
            unlockRequests[_requestId].saleId,
            _unlockedLicense
        );

        pendingRequests[requestIdToRequestIndex[_requestId]] = pendingRequests[
            pendingRequests.length - 1
        ];
        requestIdToRequestIndex[
            pendingRequests[pendingRequests.length - 1]
        ] = requestIdToRequestIndex[_requestId];

        pendingRequests.pop();
        delete requestIdToRequestIndex[_requestId];
        delete unlockRequests[_requestId];
    }

    // getter functions
    function getSale(uint256 _shopId, uint256 _saleId)
        external
        view
        returns (IShop.Sale memory)
    {
        return IShop(shops[_shopId]).getSale(_saleId);
    }

    function getProduct(uint256 _shopId, uint256 _productId)
        external
        view
        returns (IShop.Product memory)
    {
        return IShop(shops[_shopId]).getProduct(_productId);
    }

    function getShopInfo(uint256 _shopId)
        external
        view
        returns (IShop.ShopInfo memory)
    {
        return IShop(shops[_shopId]).getShopInfo();
    }

    function getOpenSaleIds(uint256 _shopId)
        external
        view
        returns (uint256[] memory)
    {
        return IShop(shops[_shopId]).getOpenSaleIds();
    }

    function getClosedSaleIds(uint256 _shopId)
        external
        view
        returns (uint256[] memory)
    {
        return IShop(shops[_shopId]).getClosedSaleIds();
    }

    function setServiceTax(uint256 newServiceTax) external onlyOwner {
        serviceTax = newServiceTax;
    }

    function setRatingReward(uint256 newRatingReward) external onlyOwner {
        ratingReward = newRatingReward;
    }
}