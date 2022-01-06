// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "./IGenArt721CoreV2.sol";
import "./SafeMath.sol";

interface IRedeemableProduct {
    function getRecipientAddress() external view returns(address payable);
    function getTokenRedemptionCount(address genArtCoreAddress, uint256 tokenId) external view returns(uint256);
    function incrementRedemptionAmount(address redeemer, address genArtCoreAddress, uint256 tokenId, uint256 variationId) external;
    function getRedemptionAmount(address genArtCoreAddress, uint256 projectId) external view returns(uint256);
    function getVariationPriceInWei(address genArtCoreAddress, uint256 projectId, uint256 variationId) external view returns(uint256);
    function getVariationIsPaused(address genArtCoreAddress, uint256 projectId, uint256 variationId) external view returns(bool);
}

contract RedemptionService {
    using SafeMath for uint256;

    event AddRedemptionWhitelist(
        address indexed redeemableProductAddress
    );

    event RemoveRedemptionWhitelist(
        address indexed redeemableProductAddress
    );

    event Redeem(
        address genArtCoreAddress,
        address indexed redeemableProductAddress,
        uint256 projectId,
        uint256 indexed tokenId,
        uint256 redemptionCount,
        uint256 indexed variationId
    );

    IGenArt721CoreV2 public genArtCoreContract;

    mapping(address => bool) public isRedemptionWhitelisted;

    modifier onlyWhitelisted() {
        require(genArtCoreContract.isWhitelisted(msg.sender), "Only whitelisted");
        _;
    }

    constructor(address _genArtCoreAddress) public {
        genArtCoreContract = IGenArt721CoreV2(_genArtCoreAddress);
    }

    function addRedemptionWhitelist(address redeemableProductAddress) public onlyWhitelisted {
        isRedemptionWhitelisted[redeemableProductAddress] = true;
        emit AddRedemptionWhitelist(redeemableProductAddress);
    }

    function removeRedemptionWhitelist(address redeemableProductAddress) public onlyWhitelisted {
        isRedemptionWhitelisted[redeemableProductAddress] = false;
        emit RemoveRedemptionWhitelist(redeemableProductAddress);
    }

    function redeem(address genArtCoreAddress, address redeemableProductAddress, uint256 tokenId, uint256 variationId) public payable  {
        IRedeemableProduct redeemableProductContract = IRedeemableProduct(redeemableProductAddress);
        uint256 projectId = genArtCoreContract.tokenIdToProjectId(tokenId);
        uint256 redemptionCount = redeemableProductContract.getTokenRedemptionCount(genArtCoreAddress, tokenId);
        uint256 maxAmount = redeemableProductContract.getRedemptionAmount(genArtCoreAddress, projectId);
        uint256 priceInWei = redeemableProductContract.getVariationPriceInWei(genArtCoreAddress, projectId, variationId);
        address payable recipientAddress =  redeemableProductContract.getRecipientAddress();

        require(genArtCoreContract.ownerOf(tokenId) == msg.sender, 'user not the token owner');
        require(redemptionCount < maxAmount, 'token already redeemed');
        require(priceInWei == msg.value, 'not enough tokens transferred');
        require(redeemableProductContract.getVariationIsPaused(genArtCoreAddress, projectId, variationId) == false, 'product sale is paused');

        redeemableProductContract.incrementRedemptionAmount(msg.sender, genArtCoreAddress, tokenId, variationId);
        recipientAddress.transfer(msg.value);
        emit Redeem(genArtCoreAddress, redeemableProductAddress, projectId, tokenId, redemptionCount.add(1), variationId);
    }
}