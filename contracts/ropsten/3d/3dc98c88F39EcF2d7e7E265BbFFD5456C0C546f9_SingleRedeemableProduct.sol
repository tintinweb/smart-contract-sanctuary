// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./IGenArt721CoreV2.sol";

contract SingleRedeemableProduct {
    using SafeMath for uint256;

    IGenArt721CoreV2 public genArtCoreContract;
    address public singleRedemptionServiceAddress;
    address payable public recipientAddress;

    event SetBasePriceInWei(
        address genArtCoreAddress,
        uint256 indexed projectId,
        uint256 indexed basePriceInWei
    );
    event SetAmount(
        address genArtCoreAddress,
        uint256 indexed projectId,
        uint256 indexed amount
    );
    event SetRecipientAddress(address recipientAddress);
    event CreateAttributeGroup(
        address genArtCoreAddress,
        uint256 indexed projectId,
        string group,
        bool required
    );

    struct Order {
        address redeemer;
        uint256 basePriceInWei;
        string attributes;
    }

    mapping(address => mapping(uint256 => uint256)) public isTokenRedeemed;
    mapping(address => mapping(uint256 => mapping(uint256 => Order))) public orders;
    mapping(address => mapping(uint256 => uint256)) public basePriceInWei;
    mapping(address => mapping(uint256 => uint256)) public redemptionAmount;
    mapping(address => mapping(uint256 => string[])) public attributeGroups;

    constructor(address _genArtCoreAddress, address _singleRedemptionServiceAddress, address payable _recipientAddress) public {
        genArtCoreContract = IGenArt721CoreV2(_genArtCoreAddress);
        singleRedemptionServiceAddress = _singleRedemptionServiceAddress;
        recipientAddress = _recipientAddress;
    }

    modifier onlyGenArtWhitelist() {
        require(genArtCoreContract.isWhitelisted(msg.sender), "only gen art whitelisted");
        _;
    }

    function createAttributeGroup(address genArtCoreAddress, uint256 projectId, string memory group, bool required) public onlyGenArtWhitelist {
        // TODO: do the thing
        attributeGroups[genArtCoreAddress][projectId].push(group);
        emit CreateAttributeGroup(genArtCoreAddress, projectId, group, required);
    }

    function getAttributeGroups(address genArtCoreAddress, uint256 projectId) public view returns(string[] memory) {
        return attributeGroups[genArtCoreAddress][projectId];
    }

    function getRecipientAddress() public view returns(address payable) {
        return recipientAddress;
    }

    function setRecipientAddress(address payable _recipientAddress) public onlyGenArtWhitelist {
        recipientAddress = _recipientAddress;
        emit SetRecipientAddress(_recipientAddress);
    }

    function getTokenRedemptionCount(address genArtCoreAddress, uint256 tokenId) public view returns(uint256) {
        return isTokenRedeemed[genArtCoreAddress][tokenId];
    }

    function getOrder(address genArtCoreAddress, uint256 tokenId, uint256 redemptionId) public view returns(address, uint256, string memory) {
        Order memory order = orders[genArtCoreAddress][tokenId][redemptionId];
        return (order.redeemer, order.basePriceInWei, order.attributes);
    }

    function incrementRedemptionAmount(address redeemer, address genArtCoreAddress, uint256 tokenId, string memory attributes) public {
        require(msg.sender == singleRedemptionServiceAddress, 'only merch shop contract');
        uint256 redemptionCount = isTokenRedeemed[genArtCoreAddress][tokenId].add(1);
        uint256 purchasePriceInWei = getBasePriceInWei(genArtCoreAddress, genArtCoreContract.tokenIdToProjectId(tokenId));
        isTokenRedeemed[genArtCoreAddress][tokenId] = redemptionCount;
        orders[genArtCoreAddress][tokenId][redemptionCount] = Order(redeemer, purchasePriceInWei, attributes);
    } 

    function getBasePriceInWei(address genArtCoreAddress, uint  projectId) public view returns(uint256) {
        return basePriceInWei[genArtCoreAddress][projectId];
    }

    function setBasePriceInWei(address genArtCoreAddress, uint256 projectId, uint256 _priceInWei) public onlyGenArtWhitelist {
        emit SetBasePriceInWei(genArtCoreAddress, projectId, _priceInWei);
        basePriceInWei[genArtCoreAddress][projectId] = _priceInWei;
    }

    function getAmount(address genArtCoreAddress, uint256 projectId) public view returns(uint256) {
        return redemptionAmount[genArtCoreAddress][projectId];
    }

    function setAmount(address genArtCoreAddress, uint256 projectId, uint256 amount) public onlyGenArtWhitelist {
        emit SetAmount(genArtCoreAddress, projectId, amount);
        redemptionAmount[genArtCoreAddress][projectId] = amount;
    }
}