/**
 *Submitted for verification at Etherscan.io on 2021-03-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
}

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IMasks {
    function ownerOf(uint256 tokenId) external returns (address);
}


contract CosmoSwapBonus {
    using SafeMath for uint256;

    uint256 private constant CosmoTokenRewardAmount = 1e22;
    address public CosmoToken;
    address public CosmoMasks;
    address public CosmoMasksLimitedPack;
    string public url = "https://CosmoSwap.space/";

    mapping(address => mapping(uint256 => bool)) private _tokenRewarded;

    event Rewarded(address indexed tokenOwner, uint256 indexed tokenId, uint256 indexed amount);


    constructor(address cosmoToken, address cosmoMasks, address cosmoMasksLimitedPack) public {
        CosmoToken = cosmoToken;
        CosmoMasks = cosmoMasks;
        CosmoMasksLimitedPack = cosmoMasksLimitedPack;
    }

    function isRewarded(address tokenAdress, uint256 tokenId) public view returns (bool) {
        return _tokenRewarded[tokenAdress][tokenId];
    }

    function isTokenAddressRewarded(address tokenAdress) public view returns (bool) {
        if (tokenAdress == CosmoMasks)
            return true;
        if (tokenAdress == CosmoMasksLimitedPack)
            return true;
        return false;
    }

    function claim(address tokenAdress, uint256 tokenId) public returns (uint256) {
        address tokenOwner = _msgSender();
        require(isTokenAddressRewarded(tokenAdress), "Unknown tokenAddress");
        require(isRewarded(tokenAdress, tokenId) == false, "The reward has already been claimed");
        require(IMasks(tokenAdress).ownerOf(tokenId) == tokenOwner, "Only the owner can claim the reward");

        emit Rewarded(tokenOwner, tokenId, CosmoTokenRewardAmount);
        _sendReward(tokenOwner, CosmoTokenRewardAmount);
        _tokenRewarded[tokenAdress][tokenId] = true;
        return CosmoTokenRewardAmount;
    }

    function claimMany(address tokenAdress, uint256[] memory tokenIds) public returns (uint256) {
        address tokenOwner = _msgSender();
        require(isTokenAddressRewarded(tokenAdress), "Unknown tokenAddress");

        uint256 totalClaimed = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            // Duplicate token index check
            for (uint256 j = i + 1; j < tokenIds.length; j++) {
                require(tokenIds[i] != tokenIds[j], "Duplicate tokenId");
            }

            uint256 tokenId = tokenIds[i];
            require(IMasks(tokenAdress).ownerOf(tokenId) == tokenOwner, "Only the token owner can claim the reward");

            if (isRewarded(tokenAdress, tokenId) == false) {
                totalClaimed = totalClaimed.add(CosmoTokenRewardAmount);
                _tokenRewarded[tokenAdress][tokenId] = true;
                emit Rewarded(tokenOwner, tokenId, CosmoTokenRewardAmount);
            }
        }

        require(totalClaimed != 0, "No rewards");
        _sendReward(tokenOwner, totalClaimed);
        return totalClaimed;
    }

    function _sendReward(address tokenOwner, uint256 totalClaimed) internal {
        require(IERC20(CosmoToken).transfer(tokenOwner, totalClaimed), "Reward transfer failed");
    }

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
}