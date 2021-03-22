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


contract MaskForMuskBonus {
    using SafeMath for uint256;

    uint256 public constant CosmoTokenRewardAmount = 1e24;
    //address public constant CosmoToken = 0x27cd7375478F189bdcF55616b088BE03d9c4339c;
    address public CosmoToken;
    address public MaskForMusk;
    string public url = "https://CosmoSwap.space/";

    mapping(uint256 => bool) private _tokenRewarded;

    event Rewarded(address indexed tokenOwner, uint256 indexed tokenId, uint256 indexed amount);


    constructor(address cosmoToken, address maskForMusk) public {
        CosmoToken = cosmoToken;
        MaskForMusk = maskForMusk;
    }

    function isRewarded(uint256 tokenId) public view returns (bool) {
        return _tokenRewarded[tokenId];
    }

    function claim(uint256 tokenId) public returns (uint256) {
        address tokenOwner = _msgSender();
        require(isRewarded(tokenId) == false, "The reward has already been claimed");
        require(IMasks(MaskForMusk).ownerOf(tokenId) == tokenOwner, "Only the owner can claim the reward");

        _sendReward(tokenOwner, CosmoTokenRewardAmount);
        _tokenRewarded[tokenId] = true;
        emit Rewarded(tokenOwner, tokenId, CosmoTokenRewardAmount);
        return CosmoTokenRewardAmount;
    }

    function claimMany(uint256[] memory tokenIds) public returns (uint256) {
        address tokenOwner = _msgSender();
        uint256 totalClaimed = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            // Duplicate token index check
            for (uint256 j = i + 1; j < tokenIds.length; j++) {
                require(tokenIds[i] != tokenIds[j], "Duplicate tokenId");
            }

            uint256 tokenId = tokenIds[i];
            require(IMasks(MaskForMusk).ownerOf(tokenId) == tokenOwner, "Only the token owner can claim the reward");

            if (isRewarded(tokenId) == false) {
                totalClaimed = totalClaimed.add(CosmoTokenRewardAmount);
                _tokenRewarded[tokenId] = true;
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