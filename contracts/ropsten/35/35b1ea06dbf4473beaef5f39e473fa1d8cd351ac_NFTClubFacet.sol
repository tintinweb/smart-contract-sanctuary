/**
 *Submitted for verification at Etherscan.io on 2021-08-01
*/

pragma solidity ^0.8.1;

// SPDX-License-Identifier: MIT

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

contract NFTClubFacet {
    /// @notice Get the totalSupply
    /// @return totalSupply_ The totalSupply

    function totalSupply() external view returns (uint256 totalSupply_) {
        totalSupply_ = 1;
    }

    /// @notice Get number of this NFTClub of this Model owned by the owner 
    /// @param _owner The address of the owner of the NFT
    /// @return balance_ The number of this NFTClub

    function balanceOf(address _owner) external view returns (uint256 balance_) {
        balance_ = 1;
    }

    /// @notice Get ClubInfo of _tokenId
    /// @param _tokenId The identifier for an NFT
    /// @return ClubInfo_ 

    function getNFTClub(uint256 _tokenId) external view returns (ClubInfo memory ClubInfo_) {       
        ClubInfo_.tokenId = _tokenId;
    }

    /// @notice Get list of this NFTClub of this Model owned by the owner 
    /// @param _owner The address of the owner of the NFT
    /// @return ClubInfos_ Get list of this NFTClub of this Model owned by the owner 

    function NFTClubOfOwner(address _owner) external view returns (ClubInfo[] memory ClubInfos_) {
        ClubInfos_ = new ClubInfo[](1);
    }

    /// @notice Find the owner of an NFT
    /// @param _tokenId The identifier for an NFT
    /// @return owner_ The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address owner_) {
    }

    /// @notice Get the approved address for a single NFT
    /// @param _tokenId The NFT to find the approved address for
    /// @return approved_ The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address approved_) {
    }

    /// @notice Transfer ownership of an NFT
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external {        
    }

    /// @notice Change or reaffirm the approved address for an NFT
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external {
    }

    function name() external view returns (string memory) {
        return "MU1234";
    }

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns (string memory) {
        return "M12";
    }

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external pure returns (string memory) {
        return "https://hool.football/metadata/nftclub/1234";
    }
}