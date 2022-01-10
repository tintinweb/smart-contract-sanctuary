// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "./SafeMath.sol";
import "./IGenArt721CoreV2.sol";

contract RedeemablePrint {
    using SafeMath for uint256;

    event SetRedemptionAmount(
        address indexed genArtCoreAddress,
        uint256 indexed projectId,
        uint256 indexed amount
    );

    event AddProductName(
        address indexed genArtCoreAddress,
        uint256 indexed projectId,
        string name
    );

    event RemoveProductName(
        address indexed genArtCoreAddress,
        uint256 indexed projectId,
        string name
    );

    event SetRecipientAddress(address indexed recipientAddress);

    event AddVariation(
        address indexed genArtCoreAddress,
        uint256 indexed projectId,
        uint256 indexed variationId,
        string variant,
        uint256 priceInWei,
        bool paused
    );

    event UpdateVariation(
        address indexed genArtCoreAddress,
        uint256 indexed projectId,
        uint256 indexed variationId,
        string variant,
        uint256 priceInWei,
        bool paused
    );

    struct Order {
        address redeemer;
        string productName;
        string variant;
        uint256 priceInWei;
    }

    struct Variation {
        string variant;
        uint256 priceInWei;
        bool paused;
    }

    IGenArt721CoreV2 public genArtCoreContract;

    address private _redemptionServiceAddress;
    address payable private _recipientAddress;

    mapping(address => mapping(uint256 => uint256)) private redemptionAmount;
    mapping(address => mapping(uint256 => uint256)) private isTokenRedeemed;
    mapping(address => mapping(uint256 => string)) private productName;
    mapping(address => mapping(uint256 => mapping(uint256 => Order))) private orderInfo;
    mapping(address => mapping(uint256 => mapping(uint256 => Variation))) private variationInfo;
    mapping(address => mapping(uint256 => uint256)) private _nextVariationId;

    modifier onlyGenArtWhitelist() {
        require(genArtCoreContract.isWhitelisted(msg.sender), "only gen art whitelisted");
        _;
    }

    modifier onlyRedemptionService() {
        require(msg.sender == _redemptionServiceAddress, 'only merch shop contract');
        _;
    }

    constructor(address genArtCoreAddress, address redemptionServiceAddress, address payable recipientAddress) public {
        genArtCoreContract = IGenArt721CoreV2(genArtCoreAddress);
        _redemptionServiceAddress = redemptionServiceAddress;
        _recipientAddress = recipientAddress;
    }

    function getNextVariationId(address genArtCoreAddress, uint256 projectId) public view returns(uint256 nextVariationId) {
        return _nextVariationId[genArtCoreAddress][projectId];
    }

    function getRecipientAddress() public view returns(address payable recipientAddress) {
        return _recipientAddress;
    }

    function getTokenRedemptionCount(address genArtCoreAddress, uint256 tokenId) public view returns(uint256 tokenRedeemptionCount) {
        return isTokenRedeemed[genArtCoreAddress][tokenId];
    }

    function getRedemptionAmount(address genArtCoreAddress, uint256 projectId) public view returns(uint256 amount) {
        return redemptionAmount[genArtCoreAddress][projectId];
    }

    function getProductName(address genArtCoreAddress, uint256 projectId) public view returns(string memory name) {
        return productName[genArtCoreAddress][projectId];
    }

    function getVariationInfo(address genArtCoreAddress, uint256 projectId, uint256 variationId) public view returns(string memory variant, uint256 priceInWei, bool paused) {
        Variation memory variation = variationInfo[genArtCoreAddress][projectId][variationId];
        return (variation.variant, variation.priceInWei, variation.paused);
    }

    function getVariationIsPaused(address genArtCoreAddress, uint256 projectId, uint256 variationId) public view returns(bool paused) {
        Variation memory variation = variationInfo[genArtCoreAddress][projectId][variationId];
        return variation.paused;
    }

    function getVariationPriceInWei(address genArtCoreAddress, uint256 projectId, uint256 variationId) public view returns(uint256 priceInWei) {
        Variation memory variation = variationInfo[genArtCoreAddress][projectId][variationId];
        return variation.priceInWei;
    }

    function getOrderInfo(address genArtCoreAddress, uint256 tokenId, uint256 redemptionCount) public view returns(address redeemer, string memory name, string memory variant, uint256 priceInWei) {
        Order memory order = orderInfo[genArtCoreAddress][tokenId][redemptionCount];
        return (order.redeemer, order.productName, order.variant, order.priceInWei);
    }

    function setRecipientAddress(address payable recipientAddress) public onlyGenArtWhitelist {
        _recipientAddress = recipientAddress;
        emit SetRecipientAddress(_recipientAddress);
    }

    function setRedemptionAmount(address genArtCoreAddress, uint256 projectId, uint256 amount) public onlyGenArtWhitelist {
        emit SetRedemptionAmount(genArtCoreAddress, projectId, amount);
        redemptionAmount[genArtCoreAddress][projectId] = amount;
    }

    function addProductName(address genArtCoreAddress, uint256 projectId, string memory name) public onlyGenArtWhitelist {
        productName[genArtCoreAddress][projectId] = name;
        emit AddProductName(genArtCoreAddress, projectId, name);
    }

    function removeProductName(address genArtCoreAddress, uint256 projectId, string memory name) public onlyGenArtWhitelist {
        delete productName[genArtCoreAddress][projectId];
        emit RemoveProductName(genArtCoreAddress, projectId, name);
    }

    function addVariation(address genArtCoreAddress, uint256 projectId, string memory variant, uint256 priceInWei, bool paused) public onlyGenArtWhitelist {
        uint256 variationId = _nextVariationId[genArtCoreAddress][projectId];
        variationInfo[genArtCoreAddress][projectId][variationId].variant = variant;
        variationInfo[genArtCoreAddress][projectId][variationId].priceInWei = priceInWei;
        variationInfo[genArtCoreAddress][projectId][variationId].paused = paused;
        _nextVariationId[genArtCoreAddress][projectId] = variationId.add(1);
        emit AddVariation(genArtCoreAddress, projectId, variationId, variant, priceInWei, paused);
    }

    function updateVariation(address genArtCoreAddress, uint256 projectId, uint256 variationId, string memory variant, uint256 priceInWei, bool paused) public onlyGenArtWhitelist {
        variationInfo[genArtCoreAddress][projectId][variationId].variant = variant;
        variationInfo[genArtCoreAddress][projectId][variationId].priceInWei = priceInWei;
        variationInfo[genArtCoreAddress][projectId][variationId].paused = paused;
        emit UpdateVariation(genArtCoreAddress, projectId, variationId, variant, priceInWei, paused);
    }

    function toggleVariationIsPaused(address genArtCoreAddress, uint256 projectId, uint256 variationId) public onlyGenArtWhitelist {
        variationInfo[genArtCoreAddress][projectId][variationId].paused = !variationInfo[genArtCoreAddress][projectId][variationId].paused;
    }

    function removeVariation(address genArtCoreAddress, uint256 projectId, uint256 variationId) public onlyGenArtWhitelist {
        delete variationInfo[genArtCoreAddress][projectId][variationId];
    }

    function incrementRedemptionAmount(address redeemer, address genArtCoreAddress, uint256 tokenId, uint256 variationId) public onlyRedemptionService {
        uint256 redemptionCount = isTokenRedeemed[genArtCoreAddress][tokenId].add(1);
        uint256 projectId = genArtCoreContract.tokenIdToProjectId(tokenId);
        uint256 purchasePriceInWei = getVariationPriceInWei(genArtCoreAddress, projectId, variationId);
        isTokenRedeemed[genArtCoreAddress][tokenId] = redemptionCount;
        string memory product = productName[genArtCoreAddress][projectId];
        Variation memory incrementedVariation = variationInfo[genArtCoreAddress][projectId][variationId];
        orderInfo[genArtCoreAddress][tokenId][redemptionCount] =
            Order(
                redeemer,
                product,
                incrementedVariation.variant,
                purchasePriceInWei
            );
    }
}