// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "./SafeMath.sol";
import "./IGenArt721CoreV2.sol";

contract SingleRedeemableProduct {
    using SafeMath for uint256;

    IGenArt721CoreV2 public genArtCoreContract;
    address public singleRedemptionServiceAddress;
    address payable public recipientAddress;

    event SetPriceInWei(
        address genArtCoreAddress,
        uint256 indexed projectId,
        uint256 indexed priceInWei
    );
    event SetAmount(
        address genArtCoreAddress,
        uint256 indexed projectId,
        uint256 indexed amount
    );
    event SetRecipientAddress(address recipientAddress);

    struct Order {
        string size;
        string finish;
    }

    mapping(address => mapping(uint256 => uint256)) public isTokenRedeemed;
    mapping(address => mapping(uint256 => mapping(uint256 => Order))) public orders;
    mapping(address => mapping(uint256 => uint256)) public priceInWei;
    mapping(address => mapping(uint256 => uint256)) public redemptionAmount;

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

    function setRecipientAddress(address payable _recipientAddress) public onlyGenArtWhitelist {
        recipientAddress = _recipientAddress;
        emit SetRecipientAddress(_recipientAddress);
    }

    function getIsTokenRedeemed(address genArtCoreAddress, uint256 tokenId) public view returns(uint256) {
        return isTokenRedeemed[genArtCoreAddress][tokenId];
    }

    function getOrder(address genArtCoreAddress, uint256 tokenId, uint256 redemptionId) public view returns(string memory, string memory) {
        Order memory order = orders[genArtCoreAddress][tokenId][redemptionId];
        return (order.size, order.finish);
    }

    function incrementRedemptionAmount(address genArtCoreAddress, uint256 tokenId, string memory size, string  memory finish) public {
        require(msg.sender == singleRedemptionServiceAddress, 'only merch shop contract');
        uint256 redemptionCount = isTokenRedeemed[genArtCoreAddress][tokenId].add(1);
        isTokenRedeemed[genArtCoreAddress][tokenId] = redemptionCount;
        orders[genArtCoreAddress][tokenId][redemptionCount] = Order(size, finish);
    } 

    function getPriceInWei(address genArtCoreAddress, uint256 projectId) public view returns(uint256) {
        return priceInWei[genArtCoreAddress][projectId];
    }

    function setPriceInWei(address genArtCoreAddress, uint256 projectId, uint256 _priceInWei) public onlyGenArtWhitelist {
        emit SetPriceInWei(genArtCoreAddress, projectId, _priceInWei);
        priceInWei[genArtCoreAddress][projectId] = _priceInWei;
    }

    function getAmount(address genArtCoreAddress, uint256 projectId) public view returns(uint256) {
        return redemptionAmount[genArtCoreAddress][projectId];
    }

    function setAmount(address genArtCoreAddress, uint256 projectId, uint256 amount) public onlyGenArtWhitelist {
        emit SetAmount(genArtCoreAddress, projectId, amount);
        redemptionAmount[genArtCoreAddress][projectId] = amount;
    }
}