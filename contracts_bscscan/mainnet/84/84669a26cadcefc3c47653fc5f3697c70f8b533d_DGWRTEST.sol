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
    function fullInfo(uint256[] calldata tokenIds) external view returns(FullInfo[] memory);
}

contract DGWRTEST {

    DogeWarriorNFTV1 public V1TokenAddress = DogeWarriorNFTV1(0x7B07078791f0E892d7Fd261655763DAF8aB6D962);

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



    function getV1TokenInfo(uint256 _tokenId) public view returns(FullInfo memory) {
                uint256[] memory tokenId;
                tokenId[0] = _tokenId;
                FullInfo memory V1TokenFull = FullInfo(V1TokenAddress.fullInfo(tokenId)[0].name,
                V1TokenAddress.fullInfo(tokenId)[0].description, V1TokenAddress.fullInfo(tokenId)[0].url,
                V1TokenAddress.fullInfo(tokenId)[0].inSale, V1TokenAddress.fullInfo(tokenId)[0].price,
                V1TokenAddress.fullInfo(tokenId)[0].originalID, V1TokenAddress.fullInfo(tokenId)[0].copyNumber,
                V1TokenAddress.fullInfo(tokenId)[0].owner);
                return V1TokenFull;
    }
    
    function getTokenName(uint256 _tokenId) public view returns(string memory) {
                uint256[] memory tokenId;
                tokenId[0] = _tokenId;
                return V1TokenAddress.fullInfo(tokenId)[0].name;
    }
    
    function getTokenInSale(uint256 _tokenId) public view returns(bool) {
                uint256[] memory tokenId;
                tokenId[0] = _tokenId;
                return V1TokenAddress.fullInfo(tokenId)[0].inSale;
    }
    
    function getTokenPrice(uint256 _tokenId) public view returns(uint256) {
                uint256[] memory tokenId;
                tokenId[0] = _tokenId;
                return V1TokenAddress.fullInfo(tokenId)[0].price;
    }
    
    function getTokenOwner(uint256 _tokenId) public view returns(address) {
                uint256[] memory tokenId;
                tokenId[0] = _tokenId;
                return V1TokenAddress.fullInfo(tokenId)[0].owner;
    }

}