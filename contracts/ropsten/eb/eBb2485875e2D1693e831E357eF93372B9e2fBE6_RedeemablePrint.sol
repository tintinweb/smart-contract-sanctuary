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

    event SetRecipientAddress(address indexed recipientAddress);

    event AddVariation(
        address indexed genArtCoreAddress,
        uint256 indexed projectId,
        uint256 indexed variationId,
        string name,
        uint256 priceInWei,
        bool paused
    );

    event UpdateVariation(
        address indexed genArtCoreAddress, 
        uint256 indexed projectId, 
        uint256 indexed variationId, 
        string name, 
        uint256 priceInWei, 
        bool paused
    );

    struct Order {
        address redeemer;
        string name;
        uint256 priceInWei;
    }

    struct Variation {
        string name;
        uint256 priceInWei;
        bool paused;
    }

    IGenArt721CoreV2 public genArtCoreContract;

    address public redemptionServiceAddress;
    address payable public recipientAddress;
    uint256 public nextVariationId = 0;

    mapping(address => mapping(uint256 => uint256)) public isTokenRedeemed;
    mapping(address => mapping(uint256 => mapping(uint256 => Order))) public orderInfo;
    mapping(address => mapping(uint256 => uint256)) public redemptionAmount;
    mapping(address => mapping(uint256 => mapping(uint256 => Variation))) public variationInfo;

    modifier onlyGenArtWhitelist() {
        require(genArtCoreContract.isWhitelisted(msg.sender), "only gen art whitelisted");
        _;
    }

    modifier onlyRedemptionService() {
        require(msg.sender == redemptionServiceAddress, 'only merch shop contract');
        _;
    }

    constructor(address _genArtCoreAddress, address _redemptionServiceAddress, address payable _recipientAddress) public {
        genArtCoreContract = IGenArt721CoreV2(_genArtCoreAddress);
        redemptionServiceAddress = _redemptionServiceAddress;
        recipientAddress = _recipientAddress;
    }

    function getNextVariationId() public view returns(uint256 _nextVariationId) {
        return nextVariationId;
    }

    function getRecipientAddress() public view returns(address payable _recipientAddress) {
        return recipientAddress;
    }

    function getTokenRedemptionCount(address genArtCoreAddress, uint256 tokenId) public view returns(uint256 tokenRedeemptionCount) {
        return isTokenRedeemed[genArtCoreAddress][tokenId];
    }

    function getRedemptionAmount(address genArtCoreAddress, uint256 projectId) public view returns(uint256 _redemptionAmount) {
        return redemptionAmount[genArtCoreAddress][projectId];
    }

    function getVariation(address genArtCoreAddress, uint256 projectId, uint256 variationId) public view returns(string memory name, uint256 price) {
        Variation memory variation = variationInfo[genArtCoreAddress][projectId][variationId];
        return (variation.name, variation.priceInWei);
    }

    function getVariationIsPaused(address genArtCoreAddress, uint256 projectId, uint256 variationId) public view returns(bool paused) {
        Variation memory variation = variationInfo[genArtCoreAddress][projectId][variationId];
        return variation.paused;
    }

    function getVariationPriceInWei(address genArtCoreAddress, uint256 projectId, uint256 variationId) public view returns(uint256 priceInWei) {
        Variation memory variation = variationInfo[genArtCoreAddress][projectId][variationId];
        return variation.priceInWei;
    }

    function getOrderInfo(address genArtCoreAddress, uint256 tokenId, uint256 redemptionCount) public view returns(address redeemer, string memory name, uint256 price) {
        Order memory order = orderInfo[genArtCoreAddress][tokenId][redemptionCount];
        return (order.redeemer, order.name, order.priceInWei);
    }

    function setRecipientAddress(address payable _recipientAddress) public onlyGenArtWhitelist {
        recipientAddress = _recipientAddress;
        emit SetRecipientAddress(_recipientAddress);
    }

    function setRedemptionAmount(address genArtCoreAddress, uint256 projectId, uint256 amount) public onlyGenArtWhitelist {
        emit SetRedemptionAmount(genArtCoreAddress, projectId, amount);
        redemptionAmount[genArtCoreAddress][projectId] = amount;
    }

    function addVariation(address genArtCoreAddress, uint256 projectId, string memory name, uint256 priceInWei, bool paused) public onlyGenArtWhitelist {
        uint256 variationId = nextVariationId;
        variationInfo[genArtCoreAddress][projectId][variationId].name = name;
        variationInfo[genArtCoreAddress][projectId][variationId].priceInWei = priceInWei;
        variationInfo[genArtCoreAddress][projectId][variationId].paused = paused;
        nextVariationId = nextVariationId.add(1);
        emit AddVariation(genArtCoreAddress, projectId, variationId, name, priceInWei, paused);
    }

    function updateVariation(address genArtCoreAddress, uint256 projectId, uint256 variationId, string memory name,uint256 priceInWei, bool paused) public onlyGenArtWhitelist {
        variationInfo[genArtCoreAddress][projectId][variationId].name = name;
        variationInfo[genArtCoreAddress][projectId][variationId].priceInWei = priceInWei;
        variationInfo[genArtCoreAddress][projectId][variationId].paused = paused;
        emit UpdateVariation(genArtCoreAddress, projectId, variationId, name, priceInWei, paused);
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
        Variation memory incrementedVariation = variationInfo[genArtCoreAddress][projectId][variationId];
        orderInfo[genArtCoreAddress][tokenId][redemptionCount] =
            Order(
                redeemer,
                incrementedVariation.name,
                purchasePriceInWei 
            );
    }
}