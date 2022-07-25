/**
 *Submitted for verification at hecoinfo.com on 2022-05-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    //function ownerOf(uint256 tokenId) external view returns (address owner);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}



contract MassGetNftToken {
    
    struct NftTokenInfoItem {
        uint256 num;
        string name;
        string symbol;
        uint256[] tokenIdList;
        string[] tokenURIList;
    }
    
    function getNftToken(IERC721 _nftToken,address _user,bool ifGetTokenURI) public view returns (NftTokenInfoItem memory NftTokenInfo) {
        uint256 num = _nftToken.balanceOf(_user);
        NftTokenInfo.num = num;
        NftTokenInfo.name = _nftToken.name();
        NftTokenInfo.symbol = _nftToken.symbol();
        uint256[] memory tokenIdList = new uint256[](num);
        string[] memory tokenURIList = new string[](num);
        for (uint256 i=0;i<num;i++) {
            uint256 tokenID = _nftToken.tokenOfOwnerByIndex(_user,i);
            tokenIdList[i] = tokenID;
            if (ifGetTokenURI) {
            tokenURIList[i] = _nftToken.tokenURI(tokenID);
            }
        }
        NftTokenInfo.tokenIdList = tokenIdList;
    }
    
    function massGetNftToken(IERC721[] memory _nftTokenList,address _user,bool ifGetTokenURI) external view returns (NftTokenInfoItem[] memory NftTokenInfoList) {
        NftTokenInfoList = new NftTokenInfoItem[](_nftTokenList.length);
        for (uint256 i=0;i<_nftTokenList.length;i++) {
            NftTokenInfoList[i] = getNftToken(_nftTokenList[i],_user,ifGetTokenURI);
        }
    }
}