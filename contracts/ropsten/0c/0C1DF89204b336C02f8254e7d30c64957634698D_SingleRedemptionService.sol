// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "./IGenArt721CoreV2.sol";
import "./SafeMath.sol";

interface ISingleRemeption {
    function getRecipientAddress() external view returns(address payable);
    function getIsTokenRedeemed(address genArtCoreAddress, uint256 tokenId) external view returns(uint256);
    function incrementRedemptionAmount(address genArtCoreAddress, uint256 tokenId, string  calldata size, string calldata  finish) external;
    function getAmount(address genArtCoreAddress, uint256 projectId) external view returns(uint256);
    function getPriceInWei(address genArtCoreAddress, uint256 projectId) external view returns(uint256);
}

contract SingleRedemptionService {
    using SafeMath for uint256;

    IGenArt721CoreV2 public genArtCoreContract;

    event AddSingleRedemptionWhitelist(
        address indexed singleRedemptionAddress
    );
    event RemoveSingleRedemptionWhitelist(
        address indexed singleRedemptionAddress
    );
    event Redeem(
        address genArtCoreAddress,
        address indexed singleRedemptionAddress,
        uint256 indexed projectId,
        uint256 indexed tokenId,
        uint256 redemptionCount,
        string size,
        string finish
    );

    mapping(address => bool) public isSingleRedemptionWhitelisted;

    modifier onlyWhitelisted() {
        require(genArtCoreContract.isWhitelisted(msg.sender), "Only whitelisted");
        _;
    }

    constructor(address _genArtCoreAddress) public {
        genArtCoreContract = IGenArt721CoreV2(_genArtCoreAddress);
    }

    function addSingleRedemptionWhitelist(address singleRedemptionAddress) public onlyWhitelisted {
        isSingleRedemptionWhitelisted[singleRedemptionAddress] = true;
        emit AddSingleRedemptionWhitelist(singleRedemptionAddress);
    }

    function removeSingleRedemptionWhitelist(address singleRedemptionAddress) public onlyWhitelisted {
        isSingleRedemptionWhitelisted[singleRedemptionAddress] = false;
        emit RemoveSingleRedemptionWhitelist(singleRedemptionAddress);
    }

    function redeem(address genArtCoreAddress, address singleRedemptionAddress, uint256 tokenId, string memory size, string memory finish) public payable  {
        ISingleRemeption singleRedeemableProductContract = ISingleRemeption(singleRedemptionAddress);
        uint256 projectId = genArtCoreContract.tokenIdToProjectId(tokenId);
        uint256 redemptionCount = singleRedeemableProductContract.getIsTokenRedeemed(genArtCoreAddress, tokenId);
        uint256 maxAmount = singleRedeemableProductContract.getAmount(genArtCoreAddress, projectId);
        uint256 priceInWei = singleRedeemableProductContract.getPriceInWei(genArtCoreAddress, projectId);
        address payable recipientAddress =  singleRedeemableProductContract.getRecipientAddress();

        require(genArtCoreContract.ownerOf(tokenId) == msg.sender, 'user not the token owner');
        require(redemptionCount < maxAmount, 'token already redeemed');
        require(priceInWei == msg.value, 'not enough tokens transferred');

        singleRedeemableProductContract.incrementRedemptionAmount(genArtCoreAddress, tokenId, size, finish);
        recipientAddress.transfer(msg.value);
        emit Redeem(genArtCoreAddress, singleRedemptionAddress, projectId, tokenId, redemptionCount.add(1), size, finish);
    }
}