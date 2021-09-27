/**
 *Submitted for verification at BscScan.com on 2021-09-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;



interface DogeWarriorNFTV1 {
    struct FullInfo {
        string name; // original only
        string description; // original only
        string url; // original only
        bool inSale;
        uint256 price;
        uint256 originalID;
        uint256 copyNumber;
        address owner;
    }
    function fullInfo(uint256[] calldata tokenIds) external view returns(
        string memory, // original only
        string memory, // original only
        string memory, // original only
        bool,
        uint256,
        uint256,
        uint256,
        address);
    function ownerOf(uint256 tokenId) external view  returns (address);
    function tokensOf(address account) external view returns(uint256[] memory);
}

contract DGWRTEST {

    DogeWarriorNFTV1 public V1TokenAddress;

    struct FullInfo {
        string name; // original only
        string description; // original only
        string url; // original only
        bool inSale;
        uint256 price;
        uint256 originalID;
        uint256 copyNumber;
        address owner;
    }
    constructor() {
        
        V1TokenAddress = DogeWarriorNFTV1(0x013bfa8aB1BD9A10CbD7586058fdA7E218fa1B7c);
        
    }



    // function getV1TokenInfo(uint256 _tokenId) public view returns(FullInfo memory) {
    //             uint256[] memory tokenId;
    //             tokenId[0] = _tokenId;
    //             FullInfo memory V1TokenFull = FullInfo(V1TokenAddress.fullInfo(tokenId)[0].name,
    //             V1TokenAddress.fullInfo(tokenId)[0].description, V1TokenAddress.fullInfo(tokenId)[0].url,
    //             V1TokenAddress.fullInfo(tokenId)[0].inSale, V1TokenAddress.fullInfo(tokenId)[0].price,
    //             V1TokenAddress.fullInfo(tokenId)[0].originalID, V1TokenAddress.fullInfo(tokenId)[0].copyNumber,
    //             V1TokenAddress.fullInfo(tokenId)[0].owner);
    //             return V1TokenFull;
    // }
    
    function getTokenName(uint256 _tokenId) public view returns(uint256) {
        uint256[] memory tokenId;
        tokenId[0] = _tokenId;
        (,,,,uint256 price,,,) =  V1TokenAddress.fullInfo(tokenId);
        return price;
    }
    
    
    function getOwnerOf(uint256 _tokenId) public view returns(address) {
                return V1TokenAddress.ownerOf(_tokenId);
    }
    
    function getTokensOf(address account) public view returns(uint256[] memory) {
                return V1TokenAddress.tokensOf(account);
    }
}