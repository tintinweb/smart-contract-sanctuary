// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "./SafeMath.sol";
import "./IGenArt721CoreV2.sol";

contract SingleRedeemableProduct {
    using SafeMath for uint256;

    IGenArt721CoreV2 public genArtCoreContract;
    address public singleRedemptionServiceAddress;
    address payable public recipientAddress;
    uint256 public nextVariationId = 0;

    event SetAmount(
        address genArtCoreAddress,
        uint256 indexed projectId,
        uint256 indexed amount
    );
    event SetRecipientAddress(address recipientAddress);

    event AddVariation(
        address genArtCoreAddress, 
        uint256 projectId, 
        uint256 variationId, 
        string name, 
        uint256 priceInWei, 
        string size, 
        string frame, 
        string material
    );

    event UpdateVariation(
        address genArtCoreAddress, 
        uint256 projectId, 
        uint256 variationId, 
        string name, 
        uint256 priceInWei, 
        string size, 
        string frame, 
        string material
    );

    struct Order {
        address redeemer;
        string name;
        uint256 priceInWei;
        string size;
        string frame;
        string material;
    }

    struct Variation {
        string name;
        uint256 priceInWei;
        string size;
        string frame;
        string material;
    }

    mapping(address => mapping(uint256 => uint256)) public isTokenRedeemed;
    mapping(address => mapping(uint256 => mapping(uint256 => Order))) public orders;
    mapping(address => mapping(uint256 => uint256)) public basePriceInWei;
    mapping(address => mapping(uint256 => uint256)) public redemptionAmount;
    mapping(address => mapping(uint256 => mapping(uint256 => Variation))) public variations;

    constructor(address _genArtCoreAddress, address _singleRedemptionServiceAddress, address payable _recipientAddress) public {
        genArtCoreContract = IGenArt721CoreV2(_genArtCoreAddress);
        singleRedemptionServiceAddress = _singleRedemptionServiceAddress;
        recipientAddress = _recipientAddress;
    }

    modifier onlyGenArtWhitelist() {
        require(genArtCoreContract.isWhitelisted(msg.sender), "only gen art whitelisted");
        _;
    }

    function getRecipientAddress() public view returns(address payable) {
        return recipientAddress;
    }

    function getNextVariationId() public view returns(uint256) {
        return nextVariationId;
    }

    function setRecipientAddress(address payable _recipientAddress) public onlyGenArtWhitelist {
        recipientAddress = _recipientAddress;
        emit SetRecipientAddress(_recipientAddress);
    }

    function getTokenRedemptionCount(address genArtCoreAddress, uint256 tokenId) public view returns(uint256) {
        return isTokenRedeemed[genArtCoreAddress][tokenId];
    }

    function getOrder(address genArtCoreAddress, uint256 tokenId, uint256 redemptionId) public view returns(address, string memory, uint256, string memory, string memory, string memory) {
        Order memory order = orders[genArtCoreAddress][tokenId][redemptionId];
        return (order.redeemer, order.name, order.priceInWei, order.size, order.frame, order.material);
    }

    function incrementRedemptionAmount(address redeemer, address genArtCoreAddress, uint256 tokenId, uint256 variationId) public {
        require(msg.sender == singleRedemptionServiceAddress, 'only merch shop contract');
        uint256 redemptionCount = isTokenRedeemed[genArtCoreAddress][tokenId].add(1);
        uint256 projectId = genArtCoreContract.tokenIdToProjectId(tokenId);
        uint256 purchasePriceInWei = getVariationPriceInWei(genArtCoreAddress, projectId, variationId);
        isTokenRedeemed[genArtCoreAddress][tokenId] = redemptionCount;
        Variation memory variation = variations[genArtCoreAddress][projectId][variationId];
        orders[genArtCoreAddress][tokenId][redemptionCount] =
            Order(
                redeemer,
                variation.name,
                purchasePriceInWei,
                variation.size,
                variation.frame,
                variation.material
            );
    } 

    function addVariation(
        address genArtCoreAddress,
        uint256 projectId,
        string memory name,
        uint256 priceInWei,
        string memory size,
        string memory frame,
        string memory material
    ) public onlyGenArtWhitelist {
        uint256 variationId = nextVariationId;
        variations[genArtCoreAddress][projectId][variationId].name = name;
        variations[genArtCoreAddress][projectId][variationId].priceInWei = priceInWei;
        variations[genArtCoreAddress][projectId][variationId].size = size;
        variations[genArtCoreAddress][projectId][variationId].frame = frame;
        variations[genArtCoreAddress][projectId][variationId].material = material;
        nextVariationId = nextVariationId.add(1);
        emit AddVariation(genArtCoreAddress, projectId, variationId, name, priceInWei, size, frame, material);
    }

    function getVariation(address genArtCoreAddress, uint256 projectId, uint256 variationId) public view returns(
        string memory,
        uint256,
        string memory,
        string memory,
        string memory
    ) {
        Variation memory variation = variations[genArtCoreAddress][projectId][variationId];
        return (variation.name, variation.priceInWei, variation.size, variation.frame, variation.material);
    }

    function getVariationPriceInWei(address genArtCoreAddress, uint256 projectId, uint256 variationId) public view returns(uint256) {
        Variation memory variation = variations[genArtCoreAddress][projectId][variationId];
        return variation.priceInWei;
    }

    function removeVariation(address genArtCoreAddress, uint256 projectId, uint256 variationId) public onlyGenArtWhitelist{
        delete variations[genArtCoreAddress][projectId][variationId];
    }

    function updateVariation(
        address genArtCoreAddress, 
        uint256 projectId, 
        uint256 variationId, 
        string memory name,
        uint256 priceInWei,
        string memory size,
        string memory frame,
        string memory material
    ) public onlyGenArtWhitelist {
        variations[genArtCoreAddress][projectId][variationId].name = name;
        variations[genArtCoreAddress][projectId][variationId].priceInWei = priceInWei;
        variations[genArtCoreAddress][projectId][variationId].size = size;
        variations[genArtCoreAddress][projectId][variationId].frame = frame;
        variations[genArtCoreAddress][projectId][variationId].material = material;
        emit UpdateVariation(genArtCoreAddress, projectId, variationId, name, priceInWei, size, frame, material);
    }

    function getAmount(address genArtCoreAddress, uint256 projectId) public view returns(uint256) {
        return redemptionAmount[genArtCoreAddress][projectId];
    }

    function setAmount(address genArtCoreAddress, uint256 projectId, uint256 amount) public onlyGenArtWhitelist {
        emit SetAmount(genArtCoreAddress, projectId, amount);
        redemptionAmount[genArtCoreAddress][projectId] = amount;
    }
}