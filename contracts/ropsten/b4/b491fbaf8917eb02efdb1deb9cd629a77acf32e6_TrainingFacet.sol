/**
 *Submitted for verification at Etherscan.io on 2021-08-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

struct ClubInfo {
    uint256 tokenId;
    string name;
    address owner;
    uint256 stakedAmount;
    uint256 attacking;
    uint256 defending;
    uint256 speed;
    uint256 vision;
    uint256 technical;
    uint256 aerial;
    uint256 physical;
    uint256 mental;
    uint256 stamina;
    uint256 lastTimeUsedStamina;
    WearableItemInfo[] wearableItems;
}

struct WearableItemInfo {
    string name; //The name of the wearable item
    string description;
    uint256 price;
}

struct AppStorage {
    mapping(address => uint32[]) ownerTokenIds;
    uint32[] tokenIds;
    uint32 tokenIdCounter;
    string name;
    string symbol;
    address hoolContract;
}

struct ItemInfo {
    string name; //The name of the item
    string description;
    uint256 price;
}

contract TrainingFacet {
    AppStorage internal s;

    /// @notice Train 
    /// @param _addressNFTClubModel address of NFTClubModel
    /// @param _tokenId id_token of NFTClub
    /// @param _trainingType training type:
    /// 0 Cross
    /// 1 Pass
    /// 2 Run
    /// 3 Defend
    /// 4 Attack
    /// 5 Gym
    /// 6 Technique
    /// We can get owner of NFT via function ownerOf 
    /// @param _maxFuel max amount of Fuel to be used
    /// @param _maxStamina max amount of Stamina to be used

    function train(
        address _addressNFTClubModel,
        uint256 _tokenId,
        uint16 _trainingType,
        uint256 _maxFuel,
        uint256 _maxStamina
    ) external {        
    }
}